#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = []
# ///
"""Daily flake update check, run by the flake-update-check systemd user timer.

In a fresh worktree of this repository (never the main checkout):

1. `nix flake update`; stop quietly when nothing changed.
2. Build the desktop system with at most 6 cores (one build at a time), so
   packages missing from the binary cache compile without taking over the PC.
3. Diff against the running system with `nvd`.
4. Commit the new flake.lock on a local `flake-update-<date>` branch.
5. Ask Claude (no tools, read-only prompt) for a short summary and verdict.
6. Write a report to ~/.local/state/ai-jobs/flake-update/<date>.md and send one
   desktop notification.

Nothing is switched, merged, or pushed: applying an update stays the user's
decision. Only the previous branches and worktrees this job created are
cleaned up, and only when they contain nothing but this job's commit.
"""

import argparse
import datetime
import os
import shutil
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
BRANCH_PREFIX = "flake-update-"
COMMIT_PREFIX = "flake.lock: update"
BUILD_LIMITS = ["--max-jobs", "1", "--cores", "6"]
TOPLEVEL = "nixosConfigurations.desktop.config.system.build.toplevel"
STATE = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state"))
REPORTS = STATE / "ai-jobs" / "flake-update"
SUMMARY_PROMPT = """You are summarizing an automated NixOS flake update for the system's owner.
Below are the flake input changes, the build result, and the package diff
against the running system (nvd). Write a short Markdown summary:

- Verdict on the first line: **Apply**, **Review first**, or **Hold**, with one reason.
- Notable updates: kernel, NVIDIA driver, systemd, KDE Plasma, Nix, desktop apps,
  development tools, and AI clients (codex, claude-code, dsh). Mention major
  version jumps explicitly.
- Risks: failed build, driver or kernel changes, removed packages, or anything
  that usually needs a reboot.

Keep it under 25 lines. Do not invent information that is not in the input.
"""


def run(
    *command: str, cwd: Path = REPO, timeout: int | None = None
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command, cwd=cwd, capture_output=True, text=True, timeout=timeout, check=False
    )


def tail(text: str, lines: int = 60) -> str:
    return "\n".join(text.strip().splitlines()[-lines:])


def notify(title: str, body: str) -> None:
    if shutil.which("notify-send"):
        run("notify-send", "--app-name=flake-update", title, body)


def job_branches() -> list[str]:
    result = run("git", "for-each-ref", "--format=%(refname:short)", "refs/heads")
    return [b for b in result.stdout.split() if b.startswith(BRANCH_PREFIX)]


def cleanup_previous(today_branch: str) -> list[str]:
    """Remove earlier job worktrees/branches that hold only this job's commit."""
    kept = []
    for branch in job_branches():
        if branch == today_branch:
            continue
        subjects = run("git", "log", "--format=%s", f"main..{branch}").stdout.split(
            "\n"
        )
        worktree = REPO / ".worktrees" / branch
        clean = all(not s or s.startswith(COMMIT_PREFIX) for s in subjects)
        if worktree.exists():
            clean = (
                clean and not run("git", "status", "--porcelain", cwd=worktree).stdout
            )
        if not clean:
            kept.append(branch)
            continue
        if worktree.exists():
            run("git", "worktree", "remove", str(worktree))
        run("git", "branch", "-D", branch)
    return kept


def claude_summary(context: str) -> str | None:
    if not shutil.which("claude"):
        return None
    try:
        result = run(
            "claude",
            "-p",
            "--model",
            "sonnet",
            "--tools",
            "",
            "--no-session-persistence",
            SUMMARY_PROMPT + "\n\n" + context,
            timeout=300,
        )
    except subprocess.TimeoutExpired:
        return None
    return result.stdout.strip() if result.returncode == 0 else None


def write_report(date: str, text: str) -> Path:
    REPORTS.mkdir(parents=True, exist_ok=True)
    report = REPORTS / f"{date}.md"
    report.write_text(text)
    latest = REPORTS / "latest.md"
    latest.unlink(missing_ok=True)
    latest.symlink_to(report.name)
    return report


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    parser.add_argument(
        "--no-summary", action="store_true", help="skip the Claude summary"
    )
    args = parser.parse_args()

    date = datetime.datetime.now().astimezone().date().isoformat()
    branch = f"{BRANCH_PREFIX}{date}"
    kept = cleanup_previous(branch)
    if branch in job_branches():
        print(f"{branch} already exists; nothing to do today", file=sys.stderr)
        return

    created = run(
        "ai-worktree",
        "new",
        branch,
        "--repo",
        str(REPO),
        "--base",
        "main",
        "--branch",
        branch,
    )
    if created.returncode != 0:
        report = write_report(
            date,
            f"# Flake update {date}\n\nCould not create worktree:\n\n```\n{created.stderr}\n```\n",
        )
        notify("Flake update failed", f"Could not create a worktree. See {report}")
        sys.exit(1)
    worktree = REPO / ".worktrees" / branch

    update = run("nix", "flake", "update", cwd=worktree, timeout=900)
    if (
        update.returncode != 0
        or not run("git", "status", "--porcelain", "flake.lock", cwd=worktree).stdout
    ):
        run("git", "worktree", "remove", "--force", str(worktree))
        run("git", "branch", "-D", branch)
        status = (
            "no input changes"
            if update.returncode == 0
            else "`nix flake update` failed"
        )
        write_report(
            date,
            f"# Flake update {date}\n\n{status}\n\n```\n{tail(update.stderr)}\n```\n",
        )
        if update.returncode != 0:
            notify("Flake update failed", "`nix flake update` failed; see the report.")
        return

    build = run(
        "nix",
        "build",
        "--no-link",
        "--print-out-paths",
        *BUILD_LIMITS,
        f".#{TOPLEVEL}",
        cwd=worktree,
        timeout=4 * 3600,
    )
    built = build.returncode == 0
    new_system = build.stdout.strip().splitlines()[-1] if built else None
    diff = (
        run("nvd", "diff", "/run/current-system", new_system).stdout
        if new_system
        else ""
    )

    run(
        "git",
        "-c",
        "commit.gpgsign=false",
        "commit",
        "--quiet",
        "-m",
        f"{COMMIT_PREFIX} {date}",
        "flake.lock",
        cwd=worktree,
    )

    inputs = tail(update.stderr, 80)
    build_status = "succeeded" if built else "FAILED"
    context = (
        f"## Flake input changes\n\n{inputs}\n\n"
        f"## Build\n\n{build_status} (limits: {' '.join(BUILD_LIMITS)})\n"
        + ("" if built else f"\n```\n{tail(build.stderr, 80)}\n```\n")
        + f"\n## nvd diff\n\n{tail(diff, 300)}\n"
    )
    summary = None if args.no_summary else claude_summary(context)

    apply_steps = (
        f"cd {REPO} && git cherry-pick {branch}\n"
        f"sudo nixos-rebuild switch --flake {REPO}#desktop"
    )
    kept_note = (
        f"\nKept earlier job branches with other changes: {', '.join(kept)}\n"
        if kept
        else ""
    )
    report = write_report(
        date,
        f"# Flake update {date}\n\n"
        f"Branch `{branch}` (worktree `{worktree}`), build {build_status}.\n\n"
        + (f"## Summary\n\n{summary}\n\n" if summary else "")
        + (f"## Apply\n\n```sh\n{apply_steps}\n```\n\n" if built else "")
        + kept_note
        + f"\n{context}",
    )

    first = (summary or "").splitlines()[0] if summary else f"build {build_status}"
    notify(
        f"Flake update {date}: build {build_status}",
        f"{first}\nReport: {report}",
    )
    sys.exit(0 if built else 1)


if __name__ == "__main__":
    main()
