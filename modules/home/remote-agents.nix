# Remote access to agents from a phone or browser (claude.ai/code, Claude app).
#
# claude-remote runs Claude Code's Remote Control server in ~/src, so new
# sessions can be started from afar and run here with local repos and tools.
# It runs inside a private tmux server (server mode draws a terminal UI); see it
# with `tmux -L claude-remote attach`, detach with C-b d. Attached clients are
# made read-only: a writable attach makes `claude remote-control` quit (seen on
# 2.1.281). Show the QR code with `tmux -L claude-remote send-keys -t remote
# Space`. The server exits after about 10 minutes without network, so systemd
# restarts it; the last screen before any exit is kept in
# ~/.local/state/claude-remote/last-exit.txt.
#
# claude-presence keeps $XDG_RUNTIME_DIR/claude-present in step with the screen
# lock; Claude Code skips mobile push notifications while that file exists.
{
  config,
  pkgs,
  ...
}: let
  home = config.home.homeDirectory;
  tmuxBin = "${pkgs.tmux}/bin/tmux";
  state = "${home}/.local/state/claude-remote";
  tmuxConf = pkgs.writeText "claude-remote-tmux.conf" ''
    # Clients attach read-only (a writable attach makes the server quit).
    set-hook -g client-attached 'switch-client -r'
    # On exit, keep the last screen for diagnosis, then end the server so
    # systemd restarts it.
    set -g remain-on-exit on
    set-hook -g pane-died 'run-shell "mkdir -p ${state} && ${tmuxBin} -L claude-remote capture-pane -p -S - -t remote > ${state}/last-exit.txt; ${tmuxBin} -L claude-remote kill-server"'
  '';
  tmux = "${tmuxBin} -L claude-remote";
in {
  home.sessionVariables.CLAUDE_CLIENT_PRESENCE_FILE = "\${XDG_RUNTIME_DIR}/claude-present";

  systemd.user.services = {
    claude-remote = {
      Unit.Description = "Claude Code Remote Control server in ~/src";
      Service = {
        Type = "forking";
        Environment = ["CLAUDE_CLIENT_PRESENCE_FILE=%t/claude-present"];
        # A login shell, so sessions get the same PATH and variables as a terminal.
        ExecStart = "${tmux} -f ${tmuxConf} new-session -d -s remote -x 160 -y 48 -c ${home}/src ${pkgs.zsh}/bin/zsh -lc 'exec claude remote-control --spawn same-dir --no-create-session-in-dir'";
        # "-": the server is already gone when claude exited on its own.
        ExecStop = "-${tmux} kill-server";
        Restart = "always";
        RestartSec = "30s";
      };
      # Starts at login in the background: no downloads, only a connection.
      Install.WantedBy = ["default.target"];
    };

    claude-presence = {
      Unit = {
        Description = "Claude Code presence marker from the screen lock";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${home}/src/ai-config/bin/ai-presence --file %t/claude-present";
        Restart = "on-failure";
        RestartSec = "10s";
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
