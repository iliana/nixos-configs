#!/usr/bin/env python3
# pylint: disable=missing-function-docstring,missing-module-docstring

import argparse
import functools
import json
import os
import secrets
import socket
import string
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
    fetch_notes()
    for host in sorted([args.host] if args.host else all_hosts()):
        flake_attr = f"nixosConfigurations.{host}"
        old = realise(flake_attr, args.old or "HEAD")
        new = realise(flake_attr, args.new)
        run(["nix", "run", ".#nvd", "--", "diff", old, new], capture=False)


########################################################################################


@subcommand(parser=lambda parser: parser.add_argument("hosts", nargs="*"))
def status(args):
    fetch_notes()
    local_rev = rev_parse("HEAD")
    hosts = sorted(args.hosts or all_hosts())
    format_string = f"{{:<{max(len(host) for host in hosts) + 2}}}{{}}"
    for host in hosts:
        remote_system = run_on(host, ["readlink", "/run/current-system"])
        remote_rev = commit_for_output(remote_system)
        if not remote_rev:
            result = color("unknown", "red")
        elif local_rev != remote_rev:
            result = color(remote_rev[:7], "red")
        else:
            result = color(remote_rev[:7], "green")
        booted, current = run_on(
            host,
            [
                "readlink",
                "/run/booted-system/kernel",
                "/run/current-system/kernel",
            ],
        ).splitlines()
        if booted != current:
            result += " " + color("(needs reboot)", "yellow")
        print(format_string.format(host, result))


########################################################################################


@subcommand(
    parser=lambda parser: (
        parser.add_argument("--boot", action="store_true"),
        parser.add_argument("host"),
        parser.add_argument("rev", nargs="?"),
    )
)
def deploy(args):
    fetch_notes()
    result = realise(f"nixosConfigurations.{args.host}", args.rev, host=args.host)
    run_on(
        args.host,
        ["sudo", "nix-env", "-p", "/nix/var/nix/profiles/system", "--set", result],
        capture=False,
    )
    cmd = [f"{result}/bin/switch-to-configuration", "boot" if args.boot else "switch"]
    if is_local_host(args.host):
        run(["sudo", *cmd], capture=False)
    else:
        run_on(args.host, ["nohup", "sudo", *cmd], capture=False)


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
    fetch_notes()

    with tempfile.TemporaryDirectory() as tempdir:
        jobs = run(
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
        )

    built_outputs = {}
    cached_outputs = {}
    drvs = []

    for job in jobs.splitlines():
        job = json.loads(job)
        if job["isCached"]:
            if output := job["outputs"].get("out"):
                cached_outputs[job["attr"]] = output
        else:
            if output := job["outputs"].get("out"):
                built_outputs[job["attr"]] = output
            drvs.append(job["drvPath"])
    note_outputs(cached_outputs)
    run(["nix-store", "--realise", *drvs], capture=False)
    note_outputs(built_outputs)


########################################################################################


@subcommand(
    parser=lambda parser: (
        parser.add_argument("host"),
        parser.add_argument("creds_dir"),
    )
)
def backup_setup(args):
    data = {
        "password": "".join(
            secrets.choice(string.ascii_letters + string.digits + string.punctuation)
            for i in range(69)
        ),
        "repo": input("repository: "),
        "s3": (
            "[default]\n"
            f"aws_access_key_id = {input('S3 access key: ')}\n"
            f"aws_secret_access_key = {input('S3 secret: ')}\n"
        ),
    }
    for name, value in data.items():
        path = os.path.join(args.creds_dir, f"{name}.enc")
        with open(path, mode="w", encoding="utf-8") as file:
            file.write(
                run_on(
                    args.host,
                    ["sudo", "systemd-creds", "encrypt", "-", "-"],
                    input=value,
                )
            )

    with tempfile.TemporaryDirectory(dir="/dev/shm") as tempdir:
        restic = ["nix", "run", ".#restic", "--", "-r", data["repo"]]
        env = os.environ | {
            "AWS_SHARED_CREDENTIALS_FILE": os.path.join(tempdir, "s3"),
        }
        new_password_file = os.path.join(tempdir, "password")
        with open(env["AWS_SHARED_CREDENTIALS_FILE"], "w", encoding="utf-8") as file:
            file.write(data["s3"])
        with open(new_password_file, "w", encoding="utf-8") as file:
            file.write(data["password"])

        run([*restic, "init"], capture=False, env=env)
        run(
            [
                *restic,
                "key",
                "add",
                "--new-password-file",
                new_password_file,
                "--host",
                args.host,
            ],
            capture=False,
            env=env,
        )


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
def run(args, capture=True, check=True, env=None, input=None):
    result = subprocess.run(
        args,
        check=check,
        encoding="utf-8",
        env=env,
        input=input,
        stdout=subprocess.PIPE if capture else None,
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


def is_tree_clean():
    return run(["git", "status", "--porcelain=v1", "--untracked-files=no"]) == ""


def fetch_notes():
    run(["git", "fetch", "-q", "origin", "refs/notes/nix-store"], capture=False)
    run(
        [
            "git",
            "notes",
            "--ref",
            "nix-store",
            "merge",
            "-q",
            "-s",
            "cat_sort_uniq",
            "FETCH_HEAD",
        ],
        capture=False,
    )


def read_notes(rev=None):
    if not rev:
        if is_tree_clean():
            rev = rev_parse("HEAD")
        else:
            return {}
    return dict(
        line.strip().rsplit(None, 1)
        for line in run(
            ["git", "notes", "--ref", "nix-store", "show", rev], check=False
        ).splitlines()
        if line
    )


def note_outputs(outputs):
    if not is_tree_clean():
        return

    notes = read_notes()
    original = dict(notes)
    notes.update(outputs)
    if notes != original:
        run(
            ["git", "notes", "--ref", "nix-store", "add", "-f", "-F", "-"],
            capture=False,
            input=(
                "\n".join(
                    f"{attr} {output}" for (attr, output) in sorted(notes.items())
                )
                + "\n"
            ),
        )


def commit_for_output(output):
    commit = run(
        [
            "git",
            "log",
            "--notes=nix-store",
            f"--grep={output}",
            "--fixed-strings",
            "--max-count=1",
            "--format=%H",
        ]
    )
    if commit:
        return commit
    return None


def realise(flake_attr, rev, host=None):
    def do_realise(drv):
        args = ["nix-store", "--realise", drv]
        if host:
            return run_on(host, args)
        return run(args)

    if rev:
        rev = rev_parse(rev)

    # First, see if we have a note for our current commit.
    notes = read_notes(rev)
    result = notes.get(flake_attr)
    # If we do, try to fetch it from a substituter.
    if result:
        try:
            return do_realise(result)
        except subprocess.CalledProcessError:
            pass

    # If we didn't find a note, or if we couldn't realise the noted path, we
    # need to evaluate the configuration and build it on the host.
    if rev:
        flake = f"{GIT_FLAKE}?rev={rev}"
    else:
        flake = "."
    drv = run(
        [
            "nix",
            "eval",
            "--raw",
            f"{flake}#{flake_attr}.config.system.build.toplevel.drvPath",
        ]
    )
    if host and not is_local_host(host):
        run(
            ["nix", "copy", "--derivation", "--to", f"ssh://{host}", drv],
            capture=False,
        )
    return do_realise(drv)


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
        subparser = subparsers.add_parser(name.replace("_", "-"))
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
