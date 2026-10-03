# My NixOS Configuration

Personal NixOS configuration flake for Tomalaci's hosts.

## Where this host is managed

This workstation is managed from three repositories under `~/src/`, all with a
direct-to-`main` workflow:

| Repository | Owns |
|---|---|
| `~/src/nixos` (this repository) | NixOS and Home Manager: hardware, boot, services, installed packages, and the links that put the other two repositories' files into place |
| `~/src/dotfiles` | Mutable application and shell configuration under `home/`: zsh, Starship, VS Code, mpv, Plasma, Dolphin, and `~/.local/bin` scripts |
| `~/src/ai-config` | AI agent configuration (Claude Code, Codex, DeepSeek Harness): shared agent guidance, subagents, skills, hooks, and the `ai-*` commands |

Files from `dotfiles` and `ai-config` are linked with out-of-store symlinks, so
editing them takes effect immediately. New packages, new or moved links, and
system settings take effect after `nh os switch` (or `sudo nixos-rebuild switch
--flake /home/tomalaci/src/nixos#<host>`).

## Overview

This flake defines:

- `nixosConfigurations.<host>`, one NixOS system per host, named after its
  hostname (see Hosts).
- `homeConfigurations.tomalaci`, a standalone Home Manager profile for the same
  user, shared by all hosts.
- an embedded Home Manager profile inside every NixOS configuration.
- `overlays.default`, the local overlay hook.
- `formatter.x86_64-linux`, an Alejandra-backed formatter for `nix fmt`.

Core inputs are `nixpkgs/nixos-unstable`, `home-manager`, `disko` (declarative
partitioning for the laptops), and `nixos-hardware` (laptop model profiles).
`mkPkgs` enables unfree packages and applies the local overlay; `mkHost` builds
a host from `modules/hosts/<host>/` plus the shared system modules, sets its
hostname, and embeds Home Manager for `tomalaci`.

## Hosts

| Host | Machine | Storage | Optional modules |
|---|---|---|---|
| `azepc-main` | AMD Ryzen desktop, NVIDIA RTX | hand-made: 3 LUKS NVMe in Btrfs RAID1, ext4 SATA drives | gaming, peripherals, usenet; backups on |
| `azelap-x1g9` | ThinkPad X1 Carbon Gen 9, Intel graphics only | disko `laptop.nix` | laptop |
| `azelap-p16g5` | ThinkPad P16s Gen 5 Intel, RTX PRO 500 Blackwell (company laptop) | disko `laptop.nix` | laptop; NVIDIA PRIME offload |
| `azelap-ga502` | ASUS ROG Zephyrus G15 GA502IV, Ryzen 4000, RTX 2060 | disko `laptop.nix` | laptop, gaming; NVIDIA PRIME offload, asusd |

Each machine names its host in `~/.nix-host` (never committed), which the
dotfiles `.zshenv` exports:

```sh
NIX_HOST=azelap-x1g9
```

The dotfiles `nh` wrapper passes `-H "$NIX_HOST"` to `nh os switch/boot/test/build`
and refuses to run when `NIX_HOST` is unset or names another machine (a fresh
install, still called `nixos`, is allowed; an explicit `-H` overrides). The
daily flake update job also builds the `NIX_HOST` system.

Common to all hosts:

- Platform: `x86_64-linux`
- User: `tomalaci`
- System state version: `26.05`
- Home Manager state version: `26.05`
- Desktop: KDE Plasma 6 through SDDM on Wayland
- Boot: systemd-boot
- Shell: zsh with Starship and zoxide
- Timezone: `Europe/Stockholm`
- Locale: `en_US.UTF-8`

Hardware and storage of the desktop are described in
`modules/hosts/azepc-main/default.nix`. The machine is an AMD/NVIDIA desktop with AMD microcode, the NVIDIA production driver,
modesetting, NVIDIA power management, 32-bit graphics support, Bluetooth on
boot, and Nouveau blacklisted.

Storage uses three NVMe LUKS devices that form one Btrfs RAID1 pool. Btrfs
subvolumes are mounted for `/`, `/home`, `/nix`, `/.snapshots`, and `/persist`.
The EFI system partition is mounted at `/boot`, and optional ext4 SATA mounts
live under `/mnt/sata-a`, `/mnt/sata-b`, and `/mnt/sata-c`. This layout predates
disko and is not managed by it.

Laptops use `modules/disko/laptop.nix` on their single disk: a 1 GiB EFI
partition and one LUKS container (`cryptroot`) with a Btrfs filesystem holding
the same subvolumes as the desktop. disko formats the disk at install time and
generates `fileSystems` and `boot.initrd.luks`, so laptop host files define
neither. Swap is zram. Hardware tuning comes from `nixos-hardware`; check the
PRIME bus IDs in the host file against `lspci -D` on the machine.

## Layout

```text
.
├── .ai/check          # fast repository check (run by agents after edits)
├── scripts/
│   └── flake-update-check.py  # daily flake update job (see Scheduled jobs)
├── AGENTS.md          # instructions for AI agents working in this repository
├── README.md
├── flake.lock
├── flake.nix
└── modules/
    ├── home/
    │   ├── ai-config.nix
    │   ├── claude-presence.nix
    │   ├── dotfiles.nix
    │   ├── home.nix
    │   ├── programs.nix
    │   ├── scheduled-jobs.nix
    │   └── shell.nix
    ├── disko/
    │   └── laptop.nix     # single-disk LUKS + Btrfs layout
    ├── hosts/
    │   ├── azepc-main/default.nix
    │   ├── azelap-x1g9/   # default.nix + hardware.nix (generated at install)
    │   ├── azelap-p16g5/
    │   └── azelap-ga502/
    ├── overlays/
    │   └── default.nix
    └── system/
        ├── backup.nix
        ├── boot.nix
        ├── fonts.nix
        ├── gaming.nix       # optional
        ├── kde.nix
        ├── laptop.nix       # optional
        ├── locale.nix
        ├── peripherals.nix  # optional
        ├── programs.nix
        ├── services.nix
        ├── system.nix
        ├── usenet.nix       # optional
        └── user.nix
```

Important entry points:

- `flake.nix` wires inputs, overlays, package instantiation, NixOS configs,
  standalone Home Manager configs, and formatting.
- `modules/hosts/<host>/default.nix` contains machine-specific hardware,
  storage, graphics, and backup settings, and imports the optional system
  modules that host wants. The hostname is the directory name.
- `modules/system/system.nix` contains shared NixOS basics and imports the
  backup, boot, fonts, KDE, locale, programs, services, and user modules that
  every host gets. `gaming.nix` (Steam, Wine, Proton), `laptop.nix` (zram,
  fwupd, backups only on AC), `peripherals.nix` (OpenRGB, SteelSeries, Arctis,
  input-remapper), and `usenet.nix` (NZBGet, NZBHydra2) are imported per host.
- `modules/home/home.nix` contains shared Home Manager basics and imports
  the dotfiles, ai-config, shell, and programs modules.

## System Profile

System modules configure:

- Nix flakes, automatic store optimisation, and `nh` with weekly `nh clean`
  garbage collection retaining generations from the last 14 days
- systemd-boot with Plymouth and quiet boot defaults
- redistributable firmware
- the `tomalaci` user with `wheel`, `networkmanager`, `audio`, `video`,
  `input`, and `docker` groups
- zsh as the system shell
- OpenSSH agent startup for forwarding Git SSH credentials into development
  containers
- locale and timezone settings
- system fonts including Noto, Meslo LG, JetBrains Mono, Fira Code, Liberation,
  DejaVu, corefonts, Inter, Source Sans, and Source Serif
- KDE Plasma 6 through SDDM Wayland, KDE Connect, and KDE portal defaults
- NetworkManager, firewall, hardened OpenSSH defaults, Docker on Btrfs, CUPS,
  PC/SC smartcard support, and PipeWire
- on gaming hosts: Steam, GameMode, Proton GE, Wine, Winetricks, Bottles,
  Lutris, Gamescope, Vulkan utilities, Mesa demos, and MangoHud
- common system packages such as Home Manager, `nh`, Age and SOPS CLIs, Git,
  `bat`, `curl`, `doggo`, `dua`, `eza`, `fd`, `file`, `fzf`, `jq`, `ripgrep`,
  `wget`, `yq`, GParted, PCI/USB utilities, PC/SC tools, YubiKey Manager, and
  archive tools

## Home Profile

Home Manager configures XDG base directories, session variables, user
`tomalaci`, home directory `/home/tomalaci`, and state version `26.05`.

Application configuration is intentionally kept out of this repo and linked
with out-of-store symlinks:

- `modules/home/dotfiles.nix` links from `${HOME}/src/dotfiles/home`: VS Code
  settings, zsh startup files, Starship, mpv, Plasma and Dolphin files, and
  scripts in `~/.local/bin`.
- `modules/home/ai-config.nix` links from `${HOME}/src/ai-config`: Claude Code
  settings, subagents, and skills (one link per skill, because
  `~/.claude/skills` also holds skills synced from claude.ai), the per-device
  Codex user config (`codex/config.local.toml`, gitignored) and rules, DeepSeek
  Harness settings, and the shared agent instructions. It also puts
  `~/src/ai-config/bin` (`ai-codex-run`, `ai-deepseek-run`, `ai-worktree`, and
  `ai-context7-mcp`) on `PATH`. The shared Codex config is linked as the system
  layer `/etc/codex/config.toml` by `modules/system/programs.nix`. See that
  repository's README for the multi-model delegation setup.

Codex, Claude Code, and DeepSeek Harness instructions all link
directly to `~/src/ai-config/common/AGENTS.md`. It describes the host
tools, configuration ownership, and service CLI authentication expectations.
Edit that source to update guidance for new sessions. An existing
`~/.codex/AGENTS.override.md` takes precedence for Codex; a custom `CODEX_HOME`
needs its own link.

Home modules install or configure:

- Git defaults and identity
- zsh support packages, Starship, zoxide, and mutable
  dotfiles-owned zsh startup files
- Konsole terminal configuration
- desktop applications: Firefox, Slack, Vesktop, qBittorrent, Jellyfin Media
  Player, Krita, Upscayl, Blender, Godot, LibreOffice, KCalc, and KDialog
- VS Code through Home Manager with mutable settings and extensions

The system profile installs common development tools globally: Git, Make, GCC,
Node.js, Python with uv and Ruff, Go, Rust with Cargo, OpenTofu, Docker, Dev
Containers, Nix tooling, code-search and shell tools (`ast-grep`, `shellcheck`,
`shfmt`), and network debugging tools (`grpcurl`, `websocat`, `lsof`). It also
installs Codex, Claude Code, DeepSeek Harness, and the Playwright and Context7
MCP servers; mpv is a system package. The full inventory that agents rely on is
in `~/src/ai-config/common/AGENTS.md`. Use a project's own flake or Dev
Container when the project defines one; use `nix shell` for a one-off missing
package.

For VS Code editor integration, prefer the official Dev Containers workflow.
Each project should own a `.devcontainer/devcontainer.json` that installs or
enters the project's toolchain inside the container. Because the VS Code
extension host runs in the container, language servers, formatters, and checkers
are available to the editor without installing them globally on the host.

A project should install editor-facing tools directly into its container image
or container profile so they are on the container `PATH` when the VS Code server
starts. Entering a project flake's shell in an integrated terminal does not by
itself make language servers available to the VS Code extension host.

## Scheduled jobs

`modules/home/scheduled-jobs.nix` defines systemd user timers. They run in the
background with no window, at idle CPU and IO priority, and write a report to
`~/.local/state/ai-jobs/<job>/<date>.md` (plus `latest.md`) with one desktop
notification.

| Job | When | Missed runs | What it does |
|---|---|---|---|
| `flake-update-check` | daily 11:00 | skipped (next day) | `scripts/flake-update-check.py`: in a worktree, `nix flake update`, build with at most 6 cores (`--max-jobs 1 --cores 6`), `nvd diff` against the running system, commit `flake.lock` on a local `flake-update-<date>` branch, and a Claude summary with a verdict. Never switches, merges, or pushes. |
| `ai-health` | Sundays 10:50 | caught up at next login | `ai-health --notify`: smoke-tests the Codex, DeepSeek, and Claude CLIs and both MCP servers; notifies only on failure |
| `ai-stats-report` | Sundays 11:00 | caught up at next login | `ai-stats report`: agent statistics for the last 7 and 30 days |

Apply a flake update from its report: `git cherry-pick flake-update-<date>` in
this repository (the branch holds one `flake.lock` commit), then switch. Earlier job branches are removed automatically
unless they contain other commits. Inspect timers with
`systemctl --user list-timers` and logs with
`journalctl --user -u flake-update-check`.

## Backups

`modules/system/backup.nix` defines `local.backup`, which each host turns on in
`modules/hosts/<host>/default.nix` (the desktop's disks are already RAID1; this covers
deletion and losing a machine):

- `restic-backups-storagebox`: daily at 12:30 (caught up after boot; with
  `onlyOnAC`, skipped on battery), an encrypted restic backup of the
  irreplaceable parts of the home directory (`src`, `.ssh`, `.secrets`, agent
  state, documents, plus host `extraPaths`) to the Hetzner Storage Box, then a
  2% data check. Keeps 7 daily, 4 weekly, and 6 monthly snapshots. A failure
  sends a desktop notification.
- One repository per host, each under its own Storage Box sub-account
  (`boxUser`) whose home directory is `backups/<hostname>`: a lost or
  compromised device reaches only its own backups. The main account's
  credentials stay in Proton Pass, on no machine. The box's automatic snapshots
  protect against anything holding a host's key.
- `btrbk-home` (`snapshots = true`, needs `/home` and `/.snapshots` Btrfs
  subvolumes): hourly read-only snapshots in `/.snapshots/home` (48 hourly, 14
  daily, 4 weekly). Restore a file by copying it back out.

Adding a host: create a sub-account in the Hetzner Console (SSH on, external
reachability on, home directory `backups/<hostname>`), set `local.backup` in
the host file, then as root create `/etc/restic/storagebox` (SSH key, installed
with `ssh-copy-id -p 23 -s -i /etc/restic/storagebox <sub-account>@<sub-account>.your-storagebox.de`)
and `/etc/restic/password` (also saved in Proton Pass). Inspect or restore with
`sudo restic-storagebox snapshots` and
`sudo restic-storagebox restore <id> --target <dir>`; logs with
`journalctl -u restic-backups-storagebox`.

## Remote agent access

Start `claude remote-control` (or `/remote-control` in a session) by hand to
drive sessions on this PC from claude.ai/code or the Claude app.
`modules/home/claude-presence.nix` runs `claude-presence` (`ai-presence`), which
keeps `$XDG_RUNTIME_DIR/claude-present` in step with the screen lock; Claude
Code skips mobile push notifications while that file exists
(`CLAUDE_CLIENT_PRESENCE_FILE`), so they arrive only while the screen is locked.
`tmux` is installed for SSH over Tailscale.

## Commands

Prefer build and evaluation checks before switching the live machine.

```sh
.ai/check
nix fmt
nix flake check
nix build .#nixosConfigurations.azepc-main.config.system.build.toplevel --no-link
nix build .#homeConfigurations.tomalaci.activationPackage --no-link
# Every host evaluates (cheap; catches errors in hosts you are not on):
for h in azepc-main azelap-x1g9 azelap-p16g5 azelap-ga502; do
  nix eval --raw .#nixosConfigurations.$h.config.system.build.toplevel.drvPath; echo
done
```

Runtime switch commands. Home Manager also runs as a NixOS module, so the
system switch applies home changes too; use the standalone Home Manager switch
only for home-only changes. The dotfiles zsh environment exports `NH_FLAKE` and
`NIX_HOST`, so `nh` needs neither a path nor `-H`:

```sh
nh os switch          # os-rebuild alias: with --cores 8
nh home switch -c tomalaci
sudo nixos-rebuild switch --flake /home/tomalaci/src/nixos#$NIX_HOST
home-manager switch -b hm-backup --flake /home/tomalaci/src/nixos#tomalaci
```

## Installing a host

The laptops are installed in one step with
[nixos-anywhere](https://github.com/nix-community/nixos-anywhere), driven from
another machine that has this repository: it partitions the disk with disko,
writes `hardware.nix`, and installs the host's full configuration, so there is
no intermediate basic NixOS to rebuild from.

1. On the laptop, in the firmware setup, disable Secure Boot (systemd-boot is
   unsigned) and, on the P16s, set storage to AHCI if it offers Intel VMD/RST.
   Boot the NixOS minimal ISO from USB, connect to the network (`nmtui`), run
   `passwd` to give the `nixos` user a password, and note the address
   (`ip -br a`) and the disk (`ls -l /dev/disk/by-id`).
2. In `modules/hosts/<host>/default.nix`, set `local.disko.device` to that
   `/dev/disk/by-id/...` path.
3. From the other machine, in `~/src/nixos` (the passphrase file is only read
   while formatting; the passphrase is typed at every boot):

   ```sh
   host=azelap-x1g9
   read -rs 'pw?LUKS passphrase: ' && printf %s "$pw" > /tmp/luks.key && unset pw
   nix run github:nix-community/nixos-anywhere -- \
     --flake .#$host \
     --generate-hardware-config nixos-generate-config ./modules/hosts/$host/hardware.nix \
     --disk-encryption-keys /tmp/secret.key /tmp/luks.key \
     --no-reboot \
     --target-host nixos@<address>
   rm /tmp/luks.key
   ssh -t nixos@<address> sudo nixos-enter --root /mnt -c "'passwd tomalaci'"
   ssh nixos@<address> sudo reboot
   ```

   Commit the generated `hardware.nix`.
4. On the laptop, log in and clone the repositories into the paths the
   out-of-store links expect, then name the host:

   ```sh
   mkdir -p ~/src && cd ~/src
   git clone https://github.com/tomalaci/nixos.git
   git clone --recurse-submodules https://github.com/tomalaci/dotfiles.git
   git clone https://github.com/tomalaci/ai-config.git
   echo 'NIX_HOST=azelap-x1g9' > ~/.nix-host
   ```

   Open a new shell (the dotfiles and `ai-*` links now resolve), set up SSH
   keys and `gh auth login`, switch the remotes to SSH, and run `nh os switch`
   once so Home Manager finishes the per-device setup.
5. Optionally set up backups for the host (see Backups).

Without a second machine, the same configuration installs from the USB
installer itself: clone this repository there, write the passphrase to
`/tmp/secret.key`, then run
`sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko/latest#disko-install -- --flake .#<host> --disk main /dev/disk/by-id/<disk>`,
and commit a `hardware.nix` from
`nixos-generate-config --no-filesystems --show-hardware-config` afterwards.

Adding another host: create `modules/hosts/<hostname>/default.nix` (copy a
laptop's), add the name to `hosts` in `flake.nix`, and follow the steps above.

## Working with agents

AI agents follow [AGENTS.md](AGENTS.md) in this repository, on top of the shared
workstation guidance in `~/src/ai-config/common/AGENTS.md`.
