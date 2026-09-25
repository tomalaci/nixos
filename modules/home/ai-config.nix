# Out-of-store links to AI agent configuration in the ai-config repo.
{config, ...}: let
  aiConfigDir = "${config.home.homeDirectory}/src/ai-config";
  aiConfig = path: config.lib.file.mkOutOfStoreSymlink "${aiConfigDir}/${path}";
in {
  home.file = {
    ".claude/CLAUDE.md".source = aiConfig "common/AGENTS.md";
    ".claude/settings.json".source = aiConfig "claude/settings.json";
    ".claude/agents".source = aiConfig "claude/agents";
    ".codex/AGENTS.md".source = aiConfig "common/AGENTS.md";
    ".codex/config.toml".source = aiConfig "codex/config.toml";
    ".codex/rules/default.rules".source = aiConfig "codex/rules/default.rules";
    ".dsh/AGENTS.md".source = aiConfig "common/AGENTS.md";
    ".dsh/cordis.patch.yml".source = aiConfig "deepseek/cordis.patch.yml";
  };

  # ai-* scripts (bin/ holds symlinks into scripts/).
  home.sessionPath = ["${aiConfigDir}/bin"];
}
