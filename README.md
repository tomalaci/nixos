# My NixOS Configuration

Personal NixOS configuration flake for Tomalaci's hosts.

## Overview

This flake defines:

- `nixosConfigurations.desktop`, the NixOS system for host `azepc-main`.
- `homeConfigurations.tomalaci`, a standalone Home Manager profile for the same
  user.
- an embedded Home Manager profile inside the `desktop` NixOS configuration.
- `overlays.default`, the local overlay hook.
- opt-in development shells for language and project toolchains.
- `formatter.x86_64-linux`, an Alejandra-backed formatter for `nix fmt`.

Core inputs are `nixpkgs/nixos-unstable` and `home-manager`. `mkPkgs` enables
unfree packages and applies the local overlay; `mkNixos` builds the system and
embeds Home Manager for `tomalaci`.

## Host

- Host: `desktop`
- Hostname: `azepc-main`
- Platform: `x86_64-linux`
- User: `tomalaci`
- System state version: `26.05`
- Home Manager state version: `26.05`
- Desktop: KDE Plasma 6 through SDDM on Wayland
- Boot: systemd-boot
- Shell: zsh with Starship and zoxide
- Timezone: `Europe/Stockholm`
- Locale: `en_US.UTF-8`

Hardware and storage are described in `modules/hosts/desktop.nix`. The machine
is an AMD/NVIDIA desktop with AMD microcode, the NVIDIA production driver,
modesetting, NVIDIA power management, 32-bit graphics support, Bluetooth on
boot, and Nouveau blacklisted.

Storage uses three NVMe LUKS devices that form one Btrfs RAID1 pool. Btrfs
subvolumes are mounted for `/`, `/home`, `/nix`, `/.snapshots`, and `/persist`.
The EFI system partition is mounted at `/boot`, and optional ext4 SATA mounts
live under `/mnt/sata-a`, `/mnt/sata-b`, and `/mnt/sata-c`.

## Layout

```text
.
├── CODEX.md
├── README.md
├── flake.lock
├── flake.nix
└── modules/
    ├── home/
    │   ├── development.nix
    │   ├── dotfiles.nix
    │   ├── home.nix
    │   ├── programs.nix
    │   └── shell.nix
    ├── hosts/
    │   └── desktop.nix
    ├── overlays/
    │   └── default.nix
    └── system/
        ├── boot.nix
        ├── fonts.nix
        ├── gaming.nix
        ├── kde.nix
        ├── locale.nix
        ├── programs.nix
        ├── services.nix
        ├── system.nix
        └── user.nix
```

Important entry points:

- `flake.nix` wires inputs, overlays, package instantiation, NixOS configs,
  standalone Home Manager configs, and formatting.
- `modules/hosts/desktop.nix` contains machine-specific hardware, storage,
  graphics, Bluetooth, hostname, and platform settings.
- `modules/system/system.nix` contains shared NixOS basics and imports
  boot, fonts, gaming, KDE, locale, programs, services, and user modules.
- `modules/home/home.nix` contains shared Home Manager basics and imports
  dotfiles, shell, programs, and development modules.

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
- Steam, GameMode, Proton GE, Wine, Winetricks, Bottles, Lutris, Gamescope,
  Vulkan utilities, Mesa demos, and MangoHud
- common system packages such as Home Manager, `nh`, Age and SOPS CLIs, Git,
  `bat`, `curl`, `doggo`, `dua`, `eza`, `fd`, `file`, `fzf`, `jq`, `ripgrep`,
  `wget`, `yq`, GParted, PCI/USB utilities, PC/SC tools, YubiKey Manager, and
  archive tools

## Home Profile

Home Manager configures XDG base directories, session variables, user
`tomalaci`, home directory `/home/tomalaci`, and state version `26.05`.

Application configuration is intentionally kept out of this repo and linked
from `${HOME}/src/dotfiles/home` with out-of-store symlinks. Current links cover
VS Code settings, Zed settings, zsh startup files, Codex config and rules, mpv
config, and `~/.local/bin/context7-mcp`.

Home modules install or configure:

- Git defaults and identity
- zsh support packages, Starship, zoxide, and mutable
  dotfiles-owned zsh startup files
- Konsole terminal configuration
- Slack, qBittorrent, Firefox, Krita, Jellyfin Desktop, Vesktop, and mpv
- utility packages including `ffmpeg-full`, `btop`, `gh`, `htop`, and
  `fastfetch`
- Codex CLI, Bubblewrap, and the Dev Containers CLI
- VS Code and Zed through Home Manager with mutable in-editor
  settings and extensions
- Nix tooling: Alejandra, deadnix, nix-output-monitor, nix-tree, nixd, nvd, and
  statix

Language runtimes, project language servers, formatters, linters, and build
tools are intentionally kept out of the global Home profile. Use per-project
flakes or this flake's opt-in development shells instead:

```sh
nix develop .#go
nix develop .#k8s
nix develop .#python
nix develop .#rust
nix develop .#typst
nix develop .#web
nix develop .#full
```

For VS Code editor integration, prefer the official Dev Containers workflow.
Each project should own a `.devcontainer/devcontainer.json` that installs or
enters the project's toolchain inside the container. Because the VS Code
extension host runs in the container, language servers, formatters, and checkers
are available to the editor without installing them globally on the host.

A project should install editor-facing tools directly into its container image
or container profile so they are on the container `PATH` when the VS Code server
starts. Running `nix develop` manually inside an integrated terminal is still
useful for ad hoc commands, but it does not by itself make language servers
available to the VS Code extension host.

For terminal-only use inside or outside a container, enter a flake shell:

```sh
nix develop
```

This flake's shared shells remain useful for ad hoc local terminals and as
building blocks for project containers:

```sh
nix develop /home/tomalaci/src/tomalaci/nixos#web
```

## Commands

Prefer build and evaluation checks before switching the live machine.

```sh
nix fmt
nix flake check
nix build .#nixosConfigurations.desktop.config.system.build.toplevel --no-link
nix build .#homeConfigurations.tomalaci.activationPackage --no-link
```

Runtime switch commands:

```sh
sudo nixos-rebuild switch --flake /home/tomalaci/src/tomalaci/nixos#desktop
home-manager switch -b hm-backup --flake /home/tomalaci/src/tomalaci/nixos#tomalaci
```

After `nh` has been activated, the dotfiles zsh environment exports `NH_FLAKE`
so the path can be omitted:

```sh
nh os switch -H desktop
nh home switch -c tomalaci
```

## Working Notes

- Use `rg` or `rg --files` for searches.
- Use `apply_patch` for manual edits.
- Keep changes scoped to the requested area.
- Do not revert user changes unless explicitly asked.
- Stage changed files when a ready-to-commit change set is being accumulated.
- For system-level changes, verify with the NixOS toplevel build when possible.
- For home-only changes, verify with the Home Manager activation package when
  possible.
- For formatting-only or broad Nix edits, run `nix fmt` when possible.
- Do not run `sudo nixos-rebuild switch` or `home-manager switch` unless the
  user explicitly asks to apply the configuration.
