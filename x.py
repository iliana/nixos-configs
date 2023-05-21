#!/usr/bin/env python3
# pylint: disable=missing-function-docstring,missing-module-docstring

import argparse
import functools
import json
import os
import socket
import subprocess
import tempfile

GIT_FLAKE = f"git+file:{os.path.dirname(__file__)}"
subcommands = {}


def subcommand(*args, **kwargs):
    def decorator(func):
        subcommands[func.__name__] = dict(**kwargs, func=func)
        return func

    if len(args) == 1 and callable(args[0]):
        return decorator(args[0])
    return decorator


########################################################################################


@subcommand(
    parser=lambda parser: (
        parser.add_argument("--host"),
        parser.add_argument("old", nargs="?"),
        parser.add_argument("new", nargs="?"),
    )
)
def diff(args):
    for host in sorted([args.host] if args.host else all_hosts()):
        output = f'nixosConfigurations."{host}".config.system.build.toplevel'
        old_rev = rev_parse(args.old or "HEAD")
        old_flake = f"{GIT_FLAKE}?rev={old_rev}"
        new_rev = rev_parse(args.new) if args.new else None
        new_flake = f"{GIT_FLAKE}?rev={new_rev}" if new_rev else "."
        old, new = (
            run(
                [
                    "nix",
                    "build",
                    "--no-link",
                    "--print-out-paths",
                    f"{flake}#{output}",
                ]
            )
            for flake in (old_flake, new_flake)
        )
        run(["nix", "run", "nixpkgs#nvd", "--", "diff", old, new], capture=False)


########################################################################################


@subcommand(parser=lambda parser: parser.add_argument("hosts", nargs="*"))
def status(args):
    local_rev = rev_parse("HEAD")
    hosts = sorted(args.hosts or all_hosts())
    format_string = f"{{:<{max(len(host) for host in hosts) + 2}}}{{}}"
    for host in hosts:
        remote_rev = run_on(host, ["cat", "/run/current-system/iliana-rev"])
        if not remote_rev:
            result = color("unknown", "red")
        elif local_rev != remote_rev:
            result = color(remote_rev[:7], "red")
        else:
            booted, current = run_on(
                host,
                [
                    "readlink",
                    "/run/booted-system/kernel",
                    "/run/current-system/kernel",
                ],
            ).splitlines()
            if booted != current:
                result = color("needs reboot", "yellow")
            else:
                result = color(remote_rev[:7], "green")
        print(format_string.format(host, result))


########################################################################################


@subcommand(
    parser=lambda parser: (
        parser.add_argument("--from-substituter", action="store_true"),
        parser.add_argument("host"),
        parser.add_argument("rev", nargs="?"),
    )
)
def deploy(args):
    if args.rev:
        flake = f"{GIT_FLAKE}?rev={rev_parse(args.rev)}"
    else:
        flake = "."

    if args.from_substituter:
        result = run(
            [
                "nix",
                "eval",
                "--raw",
                f"{flake}#nixosConfigurations.{args.host}.config.system.build.toplevel",
            ]
        )
        run_on(args.host, ["nix-store", "--realise", result], capture=False)
        run_on(
            args.host,
            ["sudo", "nix-env", "-p", "/nix/var/nix/profiles/system", "--set", result],
            capture=False,
        )
        run_on(
            args.host,
            ["nohup", "sudo", f"{result}/bin/switch-to-configuration", "switch"],
            capture=False,
        )
    elif is_local_host(args.host):
        run(["sudo", "nixos-rebuild", "switch", "--flake", flake], capture=False)
    else:
        run(
            [
                "nixos-rebuild",
                "switch",
                "--build-host",
                args.host,
                "--target-host",
                args.host,
                "--use-remote-sudo",
                "--flake",
                f"{flake}#{args.host}",
            ],
            capture=False,
        )


########################################################################################


@subcommand(
    parser=lambda parser: (
        parser.add_argument("host"),
        parser.add_argument("file"),
    )
)
def encrypt(args):
    if not args.file.endswith(".enc"):
        raise ValueError("file must end in .enc")

    editor = os.environ["EDITOR"]

    try:
        with open(args.file, encoding="utf-8") as file:
            current_encrypted = file.read()
    except FileNotFoundError:
        current_encrypted = None
    with tempfile.NamedTemporaryFile(
        mode="w+",
        suffix=os.path.splitext(os.path.basename(args.file))[0],
        encoding="utf-8",
    ) as file:
        if current_encrypted:
            file.write(
                run_on(
                    args.host,
                    ["sudo", "systemd-creds", "decrypt", "-", "-"],
                    input=current_encrypted,
                )
            )
            file.seek(0)
        run([editor, file.name], capture=False)
        cleartext = file.read()
    with open(args.file, mode="w", encoding="utf-8") as file:
        file.write(
            run_on(
                args.host,
                ["sudo", "systemd-creds", "encrypt", "-", "-"],
                input=cleartext,
            )
        )


########################################################################################


@subcommand
# pylint: disable-next=invalid-name
def ci(_args):
    with tempfile.TemporaryDirectory() as tempdir:
        drvs = filter(
            lambda drv: drv["isCached"] is False,
            (
                json.loads(line)
                for line in run(
                    [
                        "nix",
                        "run",
                        ".#nix-eval-jobs",
                        "--",
                        "--gc-roots-dir",
                        tempdir,
                        "--flake",
                        ".#hydraJobs",
                        "--force-recurse",
                        "--check-cache-status",
                        "--workers",
                        "2",
                        "--max-memory-size",
                        "2048",
                    ]
                ).splitlines()
            ),
        )
    run(["nix", "build", "--no-link", *(drv["drvPath"] for drv in drvs)])


########################################################################################


def color(text, color_name):
    value = {
        "red": 31,
        "green": 32,
        "yellow": 33,
    }[color_name]
    return f"\033[{value}m{text}\033[0m"


def is_local_host(host):
    return host == socket.gethostname().split(".")[0]


# pylint: disable-next=redefined-builtin
def run(args, capture=True, input=None):
    result = subprocess.run(
        args,
        input=input,
        encoding="utf-8",
        stdout=subprocess.PIPE if capture else None,
        check=True,
    )
    if capture:
        return result.stdout.strip()
    return None


def run_on(host, args, **kwargs):
    if is_local_host(host):
        return run(args, **kwargs)
    return run(["ssh", host, *args], **kwargs)


def rev_parse(rev):
    return run(["git", "rev-parse", rev])


@functools.cache
def nix_eval(installable, apply=None):
    args = ["nix", "eval", installable, "--json"]
    if apply:
        args.extend(["--apply", apply])
    return json.loads(run(args))


def all_hosts():
    return nix_eval(".#nixosConfigurations", "builtins.attrNames")


def main():
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers()
    for name, kwargs in subcommands.items():
        subparser = subparsers.add_parser(name)
        subparser.set_defaults(func=kwargs["func"])
        if "parser" in kwargs:
            kwargs["parser"](subparser)
    args = parser.parse_args()
    if "func" in args:
        args.func(args)
    else:
        raise Exception("a subcommand is required")


if __name__ == "__main__":
    main()
