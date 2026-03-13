{ config, pkgs, ... }:
{
  # Home Manager version
  home.stateVersion = "25.11";

  # Deaktiver versjonsjekk for Home Manager
  home.enableNixpkgsReleaseCheck = false;

  # Byobu/tmux – bruk zsh som shell
  programs.tmux = {
    enable = true;
    shell = "${pkgs.zsh}/bin/zsh";
  };

  # Nerd Font (nødvendig for Starship-ikoner)
  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    htop
    neovim
    brave
    element-desktop
    proton-pass
    protonvpn-gui
    fd          # rask filsøk (brukes av fzf)
    bat         # bedre cat med syntaks-highlighting
    eza         # bedre ls
    ripgrep     # bedre grep
    delta       # bedre git diff
    # Nerd Font
    nerd-fonts.jetbrains-mono
    # Hyprland-økosystem
    waybar                   # statuslinje
    rofi                     # app-launcher (inkluderer wayland-støtte)
    flameshot                # skjermbilder
    hyprlock                 # skjermlås
    swaylock                 # alternativ skjermlås
    swayidle                 # idle/timeout
    networkmanagerapplet     # nm-applet nettverksikon
    volumeicon               # volum-ikon i tray
    variety                  # bakgrunnsbilde-rotasjon
    # Produktivitet
    obsidian                 # notater (workspace 7)
    thunderbird              # e-post (workspace 3)
    joplin-desktop           # notater (workspace 7)
    remmina                  # remote desktop (workspace 6)
    discord                  # chat (workspace 10)
    kdePackages.polkit-kde-agent-1  # auth-agent for Wayland
    signal-desktop            # chat (workspace 10)
    redshift                   # nattmodus
  ];

  # Zsh-konfigurasjon
  programs.zsh = {
    enable = true;
    autocd = true;

    plugins = [
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
    ];

    initContent = ''
      # Start polkit-agent hvis vi er i Hyprland
      if [[ "$XDG_CURRENT_DESKTOP" == "Hyprland" ]]; then
        ${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1 &
      fi

      # zoxide (smart cd)
      eval "$(zoxide init zsh --cmd cd)"

      # fzf-keybindings og completion
      source ${pkgs.fzf}/share/fzf/key-bindings.zsh
      source ${pkgs.fzf}/share/fzf/completion.zsh

      # fzf bruker fd for filsøk om tilgjengelig
      export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
      export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
      export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

      # Bedre fzf-utseende
      export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --inline-info'

      export EDITOR=nvim

      # Wayland-støtte for Electron/Chromium-apper (Brave, VSCode, Discord osv.)
      export NIXOS_OZONE_WL=1
    '';

    shellAliases = {
      ls   = "eza --icons --group-directories-first";
      ll   = "eza -la --icons --group-directories-first";
      lt   = "eza --tree --icons --level=2";
      cat  = "bat";
      grep = "rg";
      ".." = "cd ..";
      "..." = "cd ../..";
      # Git aliases
      g     = "git";
      gpull = "git pull --rebase --autostash";
      gpush = "git push";
    };

    history = {
      size = 10000;
      save = 10000;
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
    };
  };

  # Starship prompt
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = true;

      format = "$username$hostname$directory$git_branch$git_status$nix_shell$python$nodejs$rust$cmd_duration$line_break$character";

      character = {
        success_symbol = "[❯](bold green)";
        error_symbol   = "[❯](bold red)";
        vimcmd_symbol  = "[❮](bold yellow)";
      };

      username = {
        show_always = false;
        style_user  = "bold yellow";
        format      = "[$user]($style) ";
      };

      directory = {
        truncate_to_repo    = true;
        style               = "bold cyan";
        read_only           = " 🔒";
        home_symbol         = " ~";
        truncation_symbol   = "…/";
      };

      git_branch = {
        symbol = " ";
        style  = "bold purple";
        format = "[$symbol$branch]($style) ";
      };

      git_status = {
        style      = "bold yellow";
        format     = ''([$all_status$ahead_behind]($style) )'';
        conflicted = "⚡";
        ahead      = ''⇡''${count}'';
        behind     = ''⇣''${count}'';
        diverged   = ''⇕⇡''${ahead_count}⇣''${behind_count}'';
        untracked  = ''?''${count}'';
        stashed    = " ";
        modified   = ''!''${count}'';
        staged     = ''+''${count}'';
        deleted    = ''✘''${count}'';
      };

      cmd_duration = {
        min_time = 2000;
        format   = "[ $duration](bold yellow) ";
      };

      nix_shell = {
        symbol = "❄️ ";
        style  = "bold blue";
        format = "[$symbol$state]($style) ";
      };

      python = {
        symbol = " ";
        style  = "bold yellow";
      };

      nodejs = {
        symbol = " ";
        style  = "bold green";
      };

      rust = {
        symbol = " ";
        style  = "bold red";
      };
    };
  };

  # fzf
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # zoxide (smart cd som husker kataloger)
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # Alacritty terminal
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        padding = { x = 10; y = 10; };
        decorations = "full";
        opacity = 0.95;
        dynamic_title = true;
      };
      font = {
        normal = {
          family = "JetBrainsMono Nerd Font";
          style = "Regular";
        };
        bold = {
          family = "JetBrainsMono Nerd Font";
          style = "Bold";
        };
        italic = {
          family = "JetBrainsMono Nerd Font";
          style = "Italic";
        };
        size = 13.0;
      };
      colors = {
        # Catppuccin Mocha
        primary = {
          background = "0x1e1e2e";
          foreground = "0xcdd6f4";
        };
        cursor = {
          text   = "0x1e1e2e";
          cursor = "0xf5e0dc";
        };
        normal = {
          black   = "0x45475a";
          red     = "0xf38ba8";
          green   = "0xa6e3a1";
          yellow  = "0xf9e2af";
          blue    = "0x89b4fa";
          magenta = "0xf5c2e7";
          cyan    = "0x94e2d5";
          white   = "0xbac2de";
        };
        bright = {
          black   = "0x585b70";
          red     = "0xf38ba8";
          green   = "0xa6e3a1";
          yellow  = "0xf9e2af";
          blue    = "0x89b4fa";
          magenta = "0xf5c2e7";
          cyan    = "0x94e2d5";
          white   = "0xa6adc8";
        };
      };
      cursor = {
        style = {
          shape    = "Block";
          blinking = "On";
        };
      };
      terminal = {
        shell = {
          program = "zsh";
        };
      };
    };
  };

  # VSCode – forhindre frysing av filvelger på Wayland
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
  };

  # VSCode Wayland-flagg via argv.json
  xdg.configFile."code-flags.conf".text = ''
    --enable-features=WaylandWindowDecorations
    --ozone-platform-hint=auto
    --password-store=gnome-libsecret
  '';

  # GNOME Terminal – sett JetBrains Mono Nerd Font
  dconf.settings = {
    "org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9" = {
      font = "JetBrainsMono Nerd Font 13";
      use-system-font = false;
      use-custom-command = false;
      audible-bell = false;
    };
  };

  # Git-konfigurasjon
  programs.git = {
    enable = true;
    settings = {
      user.name = "Henrik Ormåsen";
      user.email = "henrik@example.com";
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      delta = {
        navigate = true;
        side-by-side = true;
      };
      merge.conflictstyle = "zdiff3";
    };
  };
}
