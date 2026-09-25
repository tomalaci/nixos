# Out-of-store links to AI agent configuration in the ai-config repo.
{
  config,
  lib,
  ...
}: let
  aiConfigDir = "${config.home.homeDirectory}/src/ai-config";
  aiConfig = path: config.lib.file.mkOutOfStoreSymlink "${aiConfigDir}/${path}";
in {
  home = {
    file = {
      ".claude/CLAUDE.md".source = aiConfig "common/AGENTS.md";
      ".claude/settings.json".source = aiConfig "claude/settings.json";
      ".claude/agents".source = aiConfig "claude/agents";
      ".codex/AGENTS.md".source = aiConfig "common/AGENTS.md";
      # Per-device user layer, gitignored in ai-config; the shared config is the
      # system layer at /etc/codex/config.toml (modules/system/programs.nix).
      ".codex/config.toml".source = aiConfig "codex/config.local.toml";
      ".codex/rules/default.rules".source = aiConfig "codex/rules/default.rules";
      ".dsh/AGENTS.md".source = aiConfig "common/AGENTS.md";
      ".dsh/cordis.patch.yml".source = aiConfig "deepseek/cordis.patch.yml";
    };

    # Create the per-device Codex user layer on a fresh device, so the link above
    # is not dangling. Codex adds project trust entries to it.
    activation.codexLocalConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ ! -e "${aiConfigDir}/codex/config.local.toml" ]; then
        run touch "${aiConfigDir}/codex/config.local.toml"
      fi
    '';

    # ai-* scripts (bin/ holds symlinks into scripts/).
    sessionPath = ["${aiConfigDir}/bin"];
  };
}
