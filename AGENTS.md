# nixos repository

NixOS and Home Manager configuration for Tomalaci's workstation (`azepc-main`,
flake output `desktop`). The shared workstation guidance every agent loads is
`~/src/ai-config/common/AGENTS.md`; this file only covers this repository.
`README.md` describes the host, layout, and profiles.

## Where this host is managed

| Repository | Owns |
|---|---|
| `~/src/nixos` (this repository) | NixOS and Home Manager: hardware, boot, services, installed packages, and the out-of-store links into the other two repositories |
| `~/src/dotfiles` | Mutable application and shell configuration under `home/`, linked by `modules/home/dotfiles.nix` |
| `~/src/ai-config` | AI agent configuration and the `ai-*` commands, linked by `modules/home/ai-config.nix` (and `/etc/codex/config.toml` from `modules/system/programs.nix`) |

Change application or agent configuration in its own repository. Change this
repository for packages, services, hardware, and for adding, moving, or removing
a link.

## Rules

- Home Manager runs as a NixOS module, so `nixos-rebuild switch` applies home
  changes too. The standalone `homeConfigurations.tomalaci` output exists for
  home-only switches.
- Never run `sudo nixos-rebuild switch`, `nh os switch`, or `home-manager switch`
  yourself: build and validate, then tell the user the switch command.
- Install system-wide tools in `modules/system/programs.nix` and desktop
  applications in `modules/home/programs.nix`. Keep one package per line in the
  existing groups, with a comment when the reason is not obvious.
- Do not put downloads (`npx`, `uvx`, `curl | sh`) into anything that runs at
  boot or login; package tools with Nix instead.
- Keep changes scoped to the request, preserve unrelated edits, and do not
  revert user changes unless asked.
- Scheduled jobs live in `modules/home/scheduled-jobs.nix` (systemd user
  timers) with their scripts in `scripts/` as uv Python scripts. Jobs run at
  idle priority, cap builds with `--max-jobs 1 --cores 6`, report to
  `~/.local/state/ai-jobs/<job>/`, and never switch, merge, or push. A job that
  downloads or builds must not catch up at login (`Persistent = false`).
- `flake-update-<date>` branches and their `.worktrees/` are created by the
  daily flake job; leave them to it unless the user asks.

## Validation

- Run `.ai/check` (Alejandra formatting and `git diff --check`); the Claude Stop
  hook also runs it after edits.
- System changes: `nix build --no-link /home/tomalaci/src/nixos#nixosConfigurations.desktop.config.system.build.toplevel`
- Home-only changes: `nix build --no-link /home/tomalaci/src/nixos#homeConfigurations.tomalaci.activationPackage`
- Broad Nix edits: `nix fmt`. `statix check` and `deadnix` on the files you
  changed; some older files still carry warnings.
- The user applies changes with
  `sudo nixos-rebuild switch --flake /home/tomalaci/src/nixos#desktop`.
