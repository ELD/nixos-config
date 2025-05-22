{ config, pkgs, lib, ... }:

let name = "Eric Dattore";
    user = "edattore";
    email = "eric@dattore.me";
    fd = lib.getExe pkgs.fd;
    aliases = {
      cd = "z";
      gst = "git status";
      gap = "git add -p";
      gcia = "git commit --amend --no-edit";
      npm = "pnpm";
      npx = "pnmp dlx";
    };
    atuinZshExtras =
      if config.programs.atuin.enable
        then
        ''
          export ATUIN_NOBIND="true"
          bindkey '^r' _atuin_search_widget
          bindkey '^[[A' _atuin_search_widget
          bindkey '^[OA' _atuin_search_widget
        ''
      else "";
    functions = builtins.readFile ./config/functions.sh; in
{
  atuin = {
    enable = true;
    enableZshIntegration = true;
  };
  bat = {
    enable = true;
    config = {
      theme = "nord";
      color = "always";
    };
  };
  dircolors.enable = true;
  direnv = {
    enable = true;
    enableZshIntegration = true;
  };
  eza = {
    enable = true;
    enableZshIntegration = true;
    icons = "auto";
  };
  fzf = rec {
    enable = true;
    defaultCommand = "${fd} -H --type f";
    defaultOptions = ["--height 50%"];
    fileWidgetCommand = "${defaultCommand}";
    fileWidgetOptions = [
      "--preview '${lib.getExe pkgs.bat} --color=always --plain --line-range=:200 {}'"
    ];
    changeDirWidgetCommand = "${fd} -H --type d";
    changeDirWidgetOptions = [
      "--preview '${pkgs.tree}/bin/tree -C {} | head -200'"
    ];
    historyWidgetOptions = [];
  };
  go = {
    enable = true;
    goPath = "workspace/go";
    goBin = "workspace/go/bin";
  };
  htop.enable = true;
  jq.enable = true;
  man.enable = true;
  nix-index = {
    enable = true;
    enableZshIntegration = true;
  };
  yt-dlp.enable = true;
  zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # Shared shell configuration
  zsh = {
    enable = true;
    autocd = true;
    cdpath = [ "~/.local/share/src" ];
    dotDir = ".config/zsh";
    localVariables = {
      LANG = "en_US.UTF-8";
      GPG_TTY = "/dev/ttys000";
      DEFAULT_USER = "${config.home.username}";
      CLICOLOR = 1;
      LS_COLORS = "ExFxBxDxCxegedabagacad";
      # TERM = "xterm-256color";
      EDITOR = "vim";
      VISUAL = "vim";
      PAGER = "bat";
    };
    shellAliases = aliases;
    initContent = ''
      ${functions}
      ${atuinZshExtras}
      # if [[ -f "$HOME/.config/zsh/.p10k.zsh" ]]; then
      #   source "$HOME/.config/zsh/.p10k.zsh"
      # fi
    '';

    prezto = {
      enable = true;
      caseSensitive = true;
      color = true;
      extraModules = [ "attr" "stat" ];
      extraFunctions = [ "zargs" "zmv" ];
      pmodules = [
          "environment"
          "terminal"
          "editor"
          "history"
          "directory"
          "spectrum"
          "utility"
          "completion"
          "archive"
          "docker"
          "git"
          "homebrew"
          "osx"
          "autosuggestions"
          "syntax-highlighting"
          "history-substring-search"
          "command-not-found"
          "gpg"
          "prompt"
      ];
      editor = {
        keymap = "vi";
        dotExpansion = true;
        promptContext = true;
      };
      gnuUtility.prefix = "g";
      macOS.dashKeyword = "mand";
      terminal = {
        autoTitle = true;
        windowTitleFormat = "%n@%m: %s %d";
        tabTitleFormat = "%m: %s %d";
      };
      # prompt = { theme = "powerlevel10k"; };
    };
  };

  git = {
    enable = true;
    ignores = [ "*.swp" "target/*" ".dccache" ".idea/*" ".vscode/" ];
    userName = name;
    userEmail = email;
    signing = {
      key = "0x26CCB5CE8AE20CE0";
      signByDefault = true;
    };
    lfs = {
      enable = true;
    };
    difftastic = {
      enable = true;
      display = "inline";
    };
    extraConfig = {
      init.defaultBranch = "main";
      core = {
	    editor = "vim";
        autocrlf = "input";
      };
      commit.gpgsign = true;
      commit.verbose = true;
      pull.rebase = true;
      rebase.autoStash = true;
      push.default = "current";
    };
    aliases = {
      ci = "commit";
      co = "checkout";
      fix = "commit --amend --no-edit";
      ignore = "!gi() { curl -sL https://www.toptal.com/developers/gitignore/api/$@ ;}; gi";
      oops = "reset HEAD~1";
      please = "push --force-with-lease";
    };
  };

  gpg = {
    enable = true;
    scdaemonSettings = {} // lib.optionalAttrs pkgs.stdenvNoCC.isDarwin {
      disable-ccid = true;
    };
  };

  neovim = {
    package = pkgs.neovim;
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    withNodeJs = true;
    withRuby = true;
    withPython3 = true;
  };

  ssh = {
    enable = true;
    forwardAgent = true;
    includes = [
      (lib.mkIf pkgs.stdenv.hostPlatform.isLinux
        "/home/${user}/.ssh/config_external"
      )
      (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin
        "/Users/${user}/.ssh/config_external"
      )
    ];
  };

  starship = {
    enable = true;
    enableZshIntegration = true;
  };
}
