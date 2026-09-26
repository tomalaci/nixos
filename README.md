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
system settings take effect after `sudo nixos-rebuild switch --flake
/home/tomalaci/src/nixos#desktop`.

## Overview

This flake defines:

- `nixosConfigurations.desktop`, the NixOS system for host `azepc-main`.
- `homeConfigurations.tomalaci`, a standalone Home Manager profile for the same
  user.
- an embedded Home Manager profile inside the `desktop` NixOS configuration.
- `overlays.default`, the local overlay hook.
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
├── .ai/check          # fast repository check (run by agents after edits)
├── AGENTS.md          # instructions for AI agents working in this repository
├── README.md
├── flake.lock
├── flake.nix
└── modules/
    ├── home/
    │   ├── ai-config.nix
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

## Commands

Prefer build and evaluation checks before switching the live machine.

```sh
.ai/check
nix fmt
nix flake check
nix build .#nixosConfigurations.desktop.config.system.build.toplevel --no-link
nix build .#homeConfigurations.tomalaci.activationPackage --no-link
```

Runtime switch commands. Home Manager also runs as a NixOS module, so the
system switch applies home changes too; use the standalone Home Manager switch
only for home-only changes:

```sh
sudo nixos-rebuild switch --flake /home/tomalaci/src/nixos#desktop
home-manager switch -b hm-backup --flake /home/tomalaci/src/nixos#tomalaci
```

After `nh` has been activated, the dotfiles zsh environment exports `NH_FLAKE`
so the path can be omitted:

```sh
nh os switch -H desktop
nh home switch -c tomalaci
```

## Working with agents

AI agents follow [AGENTS.md](AGENTS.md) in this repository, on top of the shared
workstation guidance in `~/src/ai-config/common/AGENTS.md`.
