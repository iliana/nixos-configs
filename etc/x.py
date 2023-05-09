#!/usr/bin/env python3
# pylint: disable=missing-function-docstring,missing-module-docstring

import argparse
import functools
import json
import socket
import subprocess


def main():
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers()

    status = subparsers.add_parser("status")
    status.set_defaults(func=command_status)
    status.add_argument("hosts", nargs="*")

    args = parser.parse_args()
    if "func" in args:
        args.func(args)
    else:
        raise Exception("a subcommand is required")


def command_status(args):
    local_rev = run("git", "rev-parse", "HEAD")
    hosts = sorted(args.hosts or all_hosts())
    format_string = f"{{:<{max(len(host) for host in hosts) + 2}}}{{}}"
    for host in hosts:
        remote_rev = run_on(host, "cat", "/run/current-system/iliana-rev")
        if not remote_rev:
            status = color("unknown revision", "red")
        elif local_rev != remote_rev:
            status = color(remote_rev[:7], "red")
        else:
            booted, current = run_on(
                host,
                "readlink",
                "/run/booted-system/kernel",
                "/run/current-system/kernel",
            ).splitlines()
            if booted != current:
                status = color("needs reboot", "yellow")
            else:
                status = color(remote_rev[:7], "green")
        print(format_string.format(host, status))


def color(text, color_name):
    color_id = {
        "red": 31,
        "green": 32,
        "yellow": 33,
    }[color_name]
    return f"\033[{color_id}m{text}\033[0m"


def run(*args):
    stdout = subprocess.run(args, stdout=subprocess.PIPE, check=True).stdout
    return stdout.decode("utf-8").strip()


def run_on(host, *args):
    if host == socket.gethostname().split(".")[0]:
        return run(*args)
    return run("ssh", host, *args)


@functools.cache
def nix_eval(installable, apply=None):
    args = ["nix", "eval", installable, "--json"]
    if apply:
        args.extend(["--apply", apply])
    return json.loads(run(*args))


def all_hosts():
    return nix_eval(".#nixosConfigurations", "builtins.attrNames")


if __name__ == "__main__":
    main()
