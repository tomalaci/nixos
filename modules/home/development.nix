# Global development basics. Project-specific toolchains live in flake dev shells.
{pkgs, ...}: {
  # Git configuration
  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";
      pull.rebase = true;
      user = {
        email = "tomass.lacis@pm.me";
        name = "Tomass Lacis";
      };
    };
  };

  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    mutableExtensionsDir = true;
  };

  home.packages = with pkgs; [
    # Agent and AI command-line tools
    bubblewrap
    codex
    devcontainer

    # Nix language tooling
    alejandra
    deadnix
    nix-output-monitor
    nix-tree
    nixd
    nvd
    statix

    # Cloud services tooling
    gh
    awscli2
    hcloud
    cloudflared
    gdrive
  ];
}
