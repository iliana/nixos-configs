#!/usr/bin/env python3
# pylint: disable=missing-function-docstring,missing-module-docstring

import argparse
import functools
import glob
import ipaddress
import json
import os
import secrets
import site
import socket
import string
import subprocess
import sys
import tempfile
from pathlib import Path

TOP = Path(__file__).parent

subcommands = {}


def subcommand(*args, **kwargs):
    def decorator(func):
        subcommands[func.__name__] = {"func": func, **kwargs}
        return func

    if len(args) == 1 and callable(args[0]):
        return decorator(args[0])
    return decorator


########################################################################################


@subcommand
def hosts(_args):
    print("\n".join(all_hosts()))


########################################################################################


@subcommand(parser=lambda parser: parser.add_argument("hosts", nargs="*"))
def status(args):
    fetch_notes()
    local_rev = rev_parse("HEAD")
    the_hosts = sorted(args.hosts or all_hosts())
    format_string = f"{{:<{max(len(host) for host in the_hosts) + 2}}}{{}}"
    for host in the_hosts:
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
            vercmp = " => ".join(
                os.path.basename(os.path.dirname(x)).split("-", maxsplit=1)[1]
                for x in (booted, current)
            )
            result += " " + color(f"(needs reboot, {vercmp})", "yellow")
        print(format_string.format(host, result))


########################################################################################


@subcommand
def fmt(_args):
    run([tool_bin("alejandra"), "."])


########################################################################################


@subcommand(
    parser=lambda parser: (
        parser.add_argument("--bin-name"),
        parser.add_argument("tool"),
        parser.add_argument("args", nargs="*"),
    )
)
def tool(args):
    done = subprocess.run(
        [tool_bin(args.tool, args.bin_name), *args.args],
        check=False,
        stdin=sys.stdin,
        stdout=sys.stdout,
        stderr=sys.stderr,
    )
    sys.exit(done.returncode)


########################################################################################


@subcommand(
    parser=lambda parser: (
        parser.add_argument("--boot", action="store_true"),
        parser.add_argument("-n", "--dry-run", action="store_true"),
        parser.add_argument("host"),
        parser.add_argument("rev", nargs="?"),
    )
)
def deploy(args):
    # First, see if we have a note for our current commit.
    fetch_notes()
    result = next(
        (x for x in read_notes(args.rev) if f"nixos-system-{args.host}" in x), None
    )
    if result is not None:
        try:
            run_on(args.host, ["nix-store", "--realise", result])
        except subprocess.CalledProcessError:
            result = None

    # If we didn't find a note, or if we couldn't realise the noted path, we
    # need to evaluate the configuration and build it on the host.
    if result is None:
        if args.rev is not None:
            raise ValueError("cannot evaluate configuration for another revision")
        drv = run(
            [
                "nix",
                "eval",
                "-f",
                "default.nix",
                "--raw",
                f"hosts.{args.host}.config.system.build.toplevel.drvPath",
            ],
            env={"NIX_PATH": ""},
        )
        if not is_local_host(args.host):
            run(
                ["nix", "copy", "--derivation", "--to", f"ssh-ng://{args.host}", drv],
                capture=False,
            )
        result = run_on(args.host, ["nix-store", "--realise", drv])

    if args.dry_run:
        action = "dry-activate"
    else:
        run_on(
            args.host,
            ["sudo", "nix-env", "-p", "/nix/var/nix/profiles/system", "--set", result],
            capture=False,
        )
        action = "boot" if args.boot else "switch"
    cmd = [f"{result}/bin/switch-to-configuration", action]
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


@subcommand(parser=lambda parser: parser.add_argument("sources", nargs="*"))
def update(args):
    with open(TOP / "sources.json", encoding="utf-8") as file:
        sources = json.load(file)

    for name, source in sources.items():
        if args.sources and name not in args.sources:
            continue

        opts = ["--heads", "--tags", "--refs", "--quiet", "--exit-code"]
        refs = dict(
            line.split()[::-1]
            for line in run(["git", "ls-remote", *opts, source["repo"]]).splitlines()
        )

        if "branch" in source:
            field = "rev"
            new = refs[f"refs/heads/{source['branch']}"]
        elif "version" in source:
            add_tool_env()
            # pylint: disable-next=import-error,import-outside-toplevel
            from packaging import version

            field = "version"
            new = source["version"]
            current = version.parse(source["version"])
            for ref in refs:
                if not ref.startswith("refs/tags/"):
                    continue
                tag = ref.removeprefix("refs/tags/")
                try:
                    parsed = version.parse(tag)
                except ValueError:
                    continue
                if parsed > current:
                    current = parsed
                    new = tag
        else:
            raise ValueError(f"not sure how to update {name}")

        if source[field] != new:
            print(f"{name}:")
            print(color(f"  - {source[field]}", "red"))
            print(color(f"  + {new}", "green"))
            if source.get("submodules"):
                source["sha256"] = json.loads(
                    run(
                        [
                            tool_bin("nix-prefetch-git"),
                            "--quiet",
                            "--fetch-submodules",
                            source["repo"],
                            new,
                        ]
                    )
                )["sha256"]
            else:
                source["url"] = source["url"].replace(source[field], new)
                source["sha256"] = run(
                    ["nix-prefetch-url", "--name", "source", "--unpack", source["url"]]
                )
            source[field] = new

    with open(TOP / "sources.json", "w", encoding="utf-8") as file:
        json.dump(sources, file, indent=2)
        file.write("\n")


########################################################################################


@subcommand
# pylint: disable-next=invalid-name
def ci(_args):
    with tempfile.TemporaryDirectory() as tempdir:
        jobs = run(
            [
                tool_bin("nix-eval-jobs"),
                "--gc-roots-dir",
                tempdir,
                "--check-cache-status",
                "--workers",
                "2",
                "--max-memory-size",
                "2048",
                "default.nix",
            ],
            env={"NIX_PATH": ""},
        )
    jobs = [json.loads(job) for job in jobs.splitlines()]

    # 1. Note cached jobs
    note_outputs(
        job["outputs"]["out"]
        for job in jobs
        if job["isCached"] and "out" in job["outputs"]
    )

    def filter_jobs(system):
        drvs = [
            job["drvPath"]
            for job in jobs
            if job["system"] == system and not job["isCached"]
        ]
        outputs = [
            job["outputs"]["out"]
            for job in jobs
            if job["drvPath"] in drvs and "out" in job["outputs"]
        ]
        return drvs, outputs

    # 2. Perform x86_64-linux jobs locally
    drvs, x86_outputs = filter_jobs("x86_64-linux")
    if drvs:
        run(["nix-store", "--realise", *drvs], capture=False)
        note_outputs(x86_outputs)

    # 3. Perform aarch64-linux jobs remotely
    drvs, arm_outputs = filter_jobs("aarch64-linux")
    if drvs:
        run(
            ["nix", "copy", "--derivation", "--to", "ssh-ng://build@tisiphone", *drvs],
            capture=False,
        )
        run_on("build@tisiphone", ["nix-store", "--realise", *drvs], capture=False)

        # Before running nix3-copy(1), try to substitute as much as possible.
        # It would be nice if `--substitute-on-destination` worked if the
        # destination was the local store, but alas.
        closure = run_on(
            "build@tisiphone",
            ["nix-store", "--query", "--requisites", *arm_outputs],
        ).splitlines()
        run(["nix-store", "--realise", "--ignore-unknown", *closure], capture=False)

        run(
            [
                "nix",
                "copy",
                "--no-check-sigs",
                "--substitute-on-destination",
                "--from",
                "ssh-ng://build@tisiphone",
                *arm_outputs,
            ],
            capture=False,
        )
        note_outputs(arm_outputs)

    outputs = sorted((*x86_outputs, *arm_outputs))
    if "GITHUB_OUTPUT" in os.environ:
        with open(os.environ["GITHUB_OUTPUT"], "w", encoding="utf-8") as file:
            file.write(f"built={' '.join(outputs)}\n")


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
        restic = [tool_bin("restic"), "-r", data["repo"]]
        env = {
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


@subcommand
def update_hosts_file(_args):
    def is_ipv4(address):
        return ipaddress.ip_address(address).version == 4

    path = TOP / "modules" / "base" / "hosts.json"
    peers = json.loads(run(["tailscale", "status", "--json"]))["Peer"].values()
    output = sorted(
        (peer["HostName"], next(filter(is_ipv4, peer["TailscaleIPs"])))
        for peer in peers
        if peer["HostName"] in all_hosts()
    )
    with open(path, "w", encoding="utf-8") as file:
        json.dump(dict(output), file, indent=2)
        file.write("\n")


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
    if env is None:
        env = {}
    result = subprocess.run(
        args,
        check=check,
        encoding="utf-8",
        env=os.environ | env,
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


def nix_build(attr):
    return run(
        [
            "nix",
            "build",
            "--no-link",
            "--print-out-paths",
            "-f",
            "default.nix",
            attr,
        ],
        env={"NIX_PATH": ""},
    )


def tool_bin(name, bin_name=None):
    if bin_name is None:
        bin_name = name
    pkg = nix_build(f"pkgs.{name}")
    return f"{pkg}/bin/{bin_name}"


def rev_parse(rev):
    return run(["git", "rev-parse", rev])


def is_tree_clean():
    return run(["git", "status", "--porcelain=v1", "--untracked-files=no"]) == ""


@subcommand
def fetch_notes(_args=None):
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
            return set()
    return set(
        run(
            ["git", "notes", "--ref", "nix-store", "show", rev], check=False
        ).splitlines()
    )


def note_outputs(outputs):
    if not is_tree_clean():
        return

    notes = read_notes()
    original = len(notes)
    notes.update(outputs)
    if len(notes) != original:
        run(
            ["git", "notes", "--ref", "nix-store", "add", "-f", "-F", "-"],
            capture=False,
            input="\n".join(sorted(notes)) + "\n",
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


@functools.cache
def all_hosts():
    return json.loads(
        run(
            [
                "nix",
                "eval",
                "-f",
                "default.nix",
                "hosts",
                "--json",
                "--apply",
                "builtins.attrNames",
            ],
            env={"NIX_PATH": ""},
        )
    )


@functools.cache
def add_tool_env():
    result = nix_build("misc.tool-env")
    site.addsitedir(glob.glob(result + "/lib/python*/site-packages")[0])


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
        raise ValueError("a subcommand is required")


if __name__ == "__main__":
    main()
