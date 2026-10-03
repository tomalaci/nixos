#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = []
# ///
"""Install a host from this flake onto a machine booted from the NixOS installer.

Run from this repository on another machine, after booting the target from the
NixOS minimal ISO, connecting it to the network, and authorizing the key there
(README.md, "Installing a host"):

    scripts/install-host.py azelap-x1g9 nixos@192.168.1.50

Steps (README.md, "Installing a host"):

1. Log in with the SSH key (curled onto the installer from keys/tomalaci.pub),
   or copy it there with the `nixos` password; then check that the target is
   running the installer, not an installed system.
2. Pick the internal disk, write its /dev/disk/by-id/ path into the host's
   disko.nix, and ask for the host name as confirmation: the disk is erased.
3. Ask for the LUKS passphrase.
4. Run nixos-anywhere: partition with disko, generate hardware.nix, install.
   Clones of ~/src/{nixos,dotfiles,ai-config} (committed state only) and
   ~/.nix-host are copied into the new home directory, so the out-of-store
   links work at first login without GitHub credentials.
5. Set the password of `tomalaci` and reboot.

Afterwards commit the changed disko.nix and hardware.nix.
"""

import argparse
import getpass
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SRC = Path.home() / "src"
REPOS = ["nixos", "dotfiles", "ai-config"]
USER = "tomalaci"
# First normal user and the users group on a fresh NixOS.
OWNER = "1000:100"
# The installer gets a new host key on every boot.
SSH_OPTIONS = [
    "StrictHostKeyChecking=no",
    "UserKnownHostsFile=/dev/null",
    "LogLevel=ERROR",
]
NIXOS_ANYWHERE = "github:nix-community/nixos-anywhere"
LIST_DISKS = r"""
lsblk -Jdpo NAME,SIZE,TRAN,RM,MODEL
for link in /dev/disk/by-id/*; do
  case "$link" in *-part*) continue ;; esac
  echo "$link $(readlink -f "$link")"
done
"""


def fail(message: str) -> None:
    print(f"error: {message}", file=sys.stderr)
    sys.exit(1)


def ssh_args(key: Path) -> list[str]:
    args = ["-i", str(key)]
    for option in SSH_OPTIONS:
        args += ["-o", option]
    return args


def remote(
    target: str, key: Path, command: str, tty: bool = False, check: bool = True
) -> str:
    result = subprocess.run(
        ["ssh", *(["-t"] if tty else []), *ssh_args(key), target, command],
        stdout=None if tty else subprocess.PIPE,
        text=True,
        check=False,
    )
    if check and result.returncode != 0:
        fail(f"remote command failed ({result.returncode}): {command}")
    return result.stdout or ""


def pick_disk(target: str, key: Path, wanted: str | None) -> str:
    """Return the /dev/disk/by-id/ path of the internal disk to install to."""
    output = remote(target, key, LIST_DISKS)
    json_end = output.index("\n}") + 2
    disks = {d["name"]: d for d in json.loads(output[:json_end])["blockdevices"]}
    ids: dict[str, list[str]] = {}
    for line in output[json_end:].split("\n"):
        if line.strip():
            link, device = line.split()
            ids.setdefault(device, []).append(link)

    candidates = []
    for name, info in sorted(disks.items()):
        if info.get("tran") == "usb" or info.get("rm") in (True, "1") or "loop" in name:
            continue
        # Prefer model_serial names over eui./wwn-, which are harder to recognise.
        links = sorted(ids.get(name, []), key=lambda l: ("eui." in l or "wwn-" in l, l))
        if links:
            candidates.append((links[0], name, info))
    if not candidates:
        fail("no internal disk found on the target")

    if wanted:
        for link, name, _ in candidates:
            if wanted in (link, name):
                return link
        fail(f"{wanted} is not one of the internal disks: {[c[0] for c in candidates]}")

    print("Internal disks on the target:")
    for number, (link, name, info) in enumerate(candidates, 1):
        print(
            f"  {number}. {link}\n     {name}, {info.get('size')}, {(info.get('model') or '').strip()}"
        )
    if len(candidates) == 1:
        return candidates[0][0]
    choice = input("Install to disk number: ").strip()
    if not choice.isdigit() or not 1 <= int(choice) <= len(candidates):
        fail("no disk chosen")
    return candidates[int(choice) - 1][0]


def set_disk(disko: Path, disk: str) -> None:
    text = disko.read_text()
    new, count = re.subn(r'device = "[^"]*";', f'device = "{disk}";', text)
    if count != 1:
        fail(f"expected one `device = ...;` in {disko}, found {count}")
    disko.write_text(new)


def stage_home(staging: Path, host: str) -> None:
    """Clone the three repositories and write ~/.nix-host under staging/home/<user>."""
    home = staging / "home" / USER
    (home / "src").mkdir(parents=True)
    for name in REPOS:
        source = SRC / name
        destination = home / "src" / name
        subprocess.run(
            [
                "git",
                "clone",
                "--quiet",
                "--recurse-submodules",
                str(source),
                str(destination),
            ],
            check=True,
        )
        # Use the source repository's remotes instead of the local path.
        subprocess.run(
            ["git", "-C", str(destination), "remote", "remove", "origin"], check=True
        )
        remotes = subprocess.run(
            ["git", "-C", str(source), "remote"],
            capture_output=True,
            text=True,
            check=True,
        ).stdout.split()
        for remote_name in remotes:
            url = subprocess.run(
                ["git", "-C", str(source), "remote", "get-url", remote_name],
                capture_output=True,
                text=True,
                check=True,
            ).stdout.strip()
            subprocess.run(
                ["git", "-C", str(destination), "remote", "add", remote_name, url],
                check=True,
            )
    (home / ".nix-host").write_text(f"NIX_HOST={host}\n")


def ask_passphrase() -> str:
    while True:
        first = getpass.getpass("LUKS passphrase (typed at every boot): ")
        if not first:
            continue
        if getpass.getpass("Again: ") == first:
            return first
        print("Passphrases differ; try again.")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    parser.add_argument("host", help="nixosConfigurations output, e.g. azelap-x1g9")
    parser.add_argument("target", help="installer login, e.g. nixos@192.168.1.50")
    parser.add_argument(
        "--disk", help="disk to install to (by-id path or /dev/nvme0n1)"
    )
    parser.add_argument(
        "--key",
        type=Path,
        default=Path.home() / ".ssh" / "id_ed25519",
        help="SSH private key",
    )
    args = parser.parse_args()

    host_dir = REPO / "modules" / "hosts" / args.host
    disko = host_dir / "disko.nix"
    if args.host.endswith("-example") or not disko.is_file():
        fail(f"{args.host} is not an installable host (needs {disko})")
    if not args.key.is_file() or not args.key.with_suffix(".pub").is_file():
        fail(f"SSH key {args.key} (and .pub) not found; pass --key")
    for name in REPOS:
        if not (SRC / name / ".git").exists():
            fail(f"{SRC / name} is not a git repository")

    # Key login works when keys/tomalaci.pub was curled onto the installer;
    # otherwise copy the key with the installer password.
    probe = ["ssh", *ssh_args(args.key), "-o", "BatchMode=yes", args.target, "true"]
    if subprocess.run(probe, capture_output=True, check=False).returncode != 0:
        print(
            f"Copying {args.key}.pub to {args.target} (asks for the installer password)"
        )
        copy = ["ssh-copy-id", "-i", f"{args.key}.pub"]
        for option in SSH_OPTIONS:
            copy += ["-o", option]
        subprocess.run([*copy, args.target], check=True)

    root_fs = remote(args.target, args.key, "findmnt -no FSTYPE /").strip()
    if root_fs != "tmpfs":
        fail(
            f"{args.target} runs from {root_fs or 'unknown'}, not the installer; refusing"
        )

    disk = pick_disk(args.target, args.key, args.disk)
    set_disk(disko, disk)
    print(f"Wrote {disk} to {disko.relative_to(REPO)}")

    answer = input(
        f"ERASE {disk} on {args.target} and install {args.host}? Type the host name: "
    )
    if answer.strip() != args.host:
        fail("not confirmed")
    passphrase = ask_passphrase()

    runtime = Path(os.environ.get("XDG_RUNTIME_DIR") or tempfile.gettempdir())
    with tempfile.TemporaryDirectory(prefix="install-host-", dir=runtime) as work:
        work_dir = Path(work)
        key_file = work_dir / "luks.key"
        key_file.touch(mode=0o600)
        key_file.write_text(passphrase)
        staging = work_dir / "files"
        stage_home(staging, args.host)

        command = [
            "nix",
            "run",
            NIXOS_ANYWHERE,
            "--",
            "--flake",
            f"{REPO}#{args.host}",
            "--generate-hardware-config",
            "nixos-generate-config",
            str(host_dir / "hardware.nix"),
            "--disk-encryption-keys",
            "/tmp/secret.key",
            str(key_file),
            "--extra-files",
            str(staging),
            "--chown",
            f"/home/{USER}",
            OWNER,
            # No reboot yet: the user password is set first.
            "--phases",
            "kexec,disko,install",
            "-i",
            str(args.key),
            "--target-host",
            args.target,
        ]
        for option in SSH_OPTIONS:
            command += ["--ssh-option", option]
        if subprocess.run(command, check=False).returncode != 0:
            fail(
                "nixos-anywhere failed; the target is still in the installer, so rerun"
            )

    print(f"Set the login password of {USER} on the new system:")
    while (
        subprocess.run(
            [
                "ssh",
                "-t",
                *ssh_args(args.key),
                args.target,
                f"sudo nixos-enter --root /mnt -c 'passwd {USER}'",
            ],
            check=False,
        ).returncode
        != 0
    ):
        print("passwd failed; try again.")

    if input("Reboot into the new system now? [Y/n] ").strip().lower() in (
        "",
        "y",
        "yes",
    ):
        remote(args.target, args.key, "sudo reboot", check=False)

    print(
        f"\nInstalled {args.host}. Next:\n"
        f"  - Commit and push {disko.relative_to(REPO)} and "
        f"{(host_dir / 'hardware.nix').relative_to(REPO)}; then `git pull` in ~/src/nixos on the laptop.\n"
        "  - On the laptop: set up SSH keys and `gh auth login`, then `nh os switch`."
    )


if __name__ == "__main__":
    main()
