{ config, pkgs, ... }:
{
  home.stateVersion = "25.11";
  home.username = "henrik";
  home.homeDirectory = "/home/henrik";
  home.enableNixpkgsReleaseCheck = false;

  # Sett miljøvariabler globalt for alle programmer
  home.sessionVariables = {
    QT_QPA_PLATFORM = "xcb";
    NIXOS_OZONE_WL = "1";
    EDITOR = "nvim";
  };

  programs.tmux = {
    enable = true;
    shell = "${pkgs.zsh}/bin/zsh";
  };
  
  home.packages = with pkgs; [
    htop
    neovim
    brave
    element-desktop
    proton-pass
    protonvpn-gui
    fd
    bat
    eza
    ripgrep
    delta
    nerd-fonts.jetbrains-mono
    waybar
    rofi
    fuzzel
    hyprlock
    swaylock
    swayidle
    networkmanagerapplet
    volumeicon
    variety
    obsidian
    thunderbird
    remmina
    discord
    kdePackages.polkit-kde-agent-1
    signal-desktop
    redshift
    chromium
    python3
    nodejs
    rustup
    birdtray
    direnv
    aphorme
    slack
    seahorse
    # Secrets-verktøy
    chezmoi
    age
    sops
    evolution
    evolution-ews
    protonvpn-gui
    protonmail-bridge-gui
    protonmail-bridge
    viu
    chafa
    kitty
    broot
    zoom-us
    hyprshot
    satty
    onlyoffice-desktopeditors
  ];

  # Script for broot preview (placed in ~/bin by home-manager)
  home.file."bin/broot-preview".text = ''
#!/usr/bin/env bash
set -euo pipefail

file="$1"
if [ -z "$file" ]; then
  exit 0
fi

if command -v kitty >/dev/null 2>&1; then
  kitty +kitten icat --silent "$file"
elif command -v viu >/dev/null 2>&1; then
  viu "$file"
else
  chafa --symbols braille --size=80x40 "$file"
fi
'';
  home.file."bin/broot-preview".executable = true;

  # broot config: add action 'p' to preview files via the script
  xdg.configFile."broot/conf.toml".text = ''
[[actions]]
invocation = "p"
name = "preview"
command = "sh -lc '/home/henrik/bin/broot-preview \"{path}\"'"
silent = false
'';

# Install zsh-chezmoi plugin from GitHub and place it under ~/.zsh/plugins
home.file.".zsh/plugins/chezmoi.plugin.zsh".source = "${builtins.fetchTarball {
  url = "https://github.com/mass8326/zsh-chezmoi/archive/refs/heads/main.tar.gz";
  sha256 = "0bi8r2p2md98v8l8f506rkmh3nbv8532va4nx64szsc19pdw84x6";
}}/chezmoi.plugin.zsh";
home.file.".zsh/plugins/chezmoi.plugin.zsh".executable = false;
  # alias.awk used by the zsh-chezmoi plugin to map git aliases
  home.file.".zsh/plugins/alias.awk".text = ''
# Alias starts with "g" and command starts with "git"
$1 ~ /^g/ && $2 ~ /^git /
{
  # Find first occurence of single quote
  i = index($0, "'");
  # Get index after "git "
  start = i + 5;
  # Get length to extract, careful of trailing single quote
  len = length($0) - i - 5;
  # Extract git subcommand
  rest = substr($0, start, len);
  # Build chezmoi git command, escaping options with "--"
  print "alias ch" $1 "='chezmoi git -- " rest "'"
}
'';


  programs.workstyle.enable = true;

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
        # Synk miljøet med systemd --user slik at Electron-apper ser DBus-tenester
        dbus-update-activation-environment --systemd --all >/dev/null 2>&1 || true

        if ! pgrep -u "$USER" -f "polkit-kde-authentication-agent-1" >/dev/null; then
          ${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1 >/dev/null 2>&1 &
        fi
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
      # Source local chezmoi zsh plugin if present
      if [ -f "$HOME/.zsh/plugins/chezmoi.plugin.zsh" ]; then
        source "$HOME/.zsh/plugins/chezmoi.plugin.zsh"
      fi
    '';

    shellAliases = {
      ls   = "eza --icons --group-directories-first";
      ll   = "eza -la --icons --group-directories-first";
      lt   = "eza --tree --icons --level=2";
      cat  = "bat";
      grep = "rg";
      ".." = "cd ..";
      "..." = "cd ../..";
      g     = "git";
      gpull = "git pull --rebase --autostash";
      gpush = "git push";
      gsw   = "git switch";
      gco   = "git checkout";
      gcm   = "git commit -am";
      byobu = "byobu-tmux";
    };

    history = {
      size = 10000;
      save = 10000;
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
    };
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    # Note: configuration is managed outside Nix in ~/.config/starship.toml
    # To use a preset, place your config at that path or use the starship CLI.
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

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

  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
  };

  # Ensure VS Code uses the patched Nerd Font for editor and integrated terminal.
  # This file is managed by Home Manager; adjust if you keep local settings elsewhere.
  home.file.".config/Code/User/settings.json".text = ''{
  "editor.fontFamily": "JetBrainsMono Nerd Font Mono, JetBrainsMono Nerd Font, FiraCode Nerd Font, Fira Code, monospace",
  "editor.fontLigatures": true,
  "terminal.integrated.fontFamily": "JetBrainsMono Nerd Font Mono, FiraCode Nerd Font, monospace"
}
'';

  # Inaktivitet: dim skjermen gradvis i 30 sekunder før lås.
  systemd.user.services.swayidle = {
    Unit = {
      Description = "Swayidle with gradual dim before lock";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = ''
        ${pkgs.swayidle}/bin/swayidle -w \
          timeout 270 'runtime="''${XDG_RUNTIME_DIR:-/tmp}"; orig="$(${pkgs.brightnessctl}/bin/brightnessctl g)"; max="$(${pkgs.brightnessctl}/bin/brightnessctl m)"; echo "$orig" > "$runtime/swayidle-brightness"; (i=1; while [ "$i" -le 30 ]; do cur="$(${pkgs.brightnessctl}/bin/brightnessctl g)"; step=$(( max / 300 )); [ "$step" -lt 1 ] && step=1; target=$(( cur - step )); [ "$target" -lt 1 ] && target=1; ${pkgs.brightnessctl}/bin/brightnessctl set "$target" >/dev/null; sleep 1; i=$((i + 1)); done) & echo "$!" > "$runtime/swayidle-dim.pid"' \
          timeout 300 '${pkgs.hyprlock}/bin/hyprlock' \
          resume 'runtime="''${XDG_RUNTIME_DIR:-/tmp}"; if [ -f "$runtime/swayidle-dim.pid" ]; then kill "$(cat "$runtime/swayidle-dim.pid")" >/dev/null 2>&1 || true; rm -f "$runtime/swayidle-dim.pid"; fi; if [ -f "$runtime/swayidle-brightness" ]; then ${pkgs.brightnessctl}/bin/brightnessctl set "$(cat "$runtime/swayidle-brightness")" >/dev/null; rm -f "$runtime/swayidle-brightness"; fi' \
          before-sleep '${pkgs.hyprlock}/bin/hyprlock'
      '';
      Restart = "on-failure";
      RestartSec = 2;
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  xdg.configFile."code-flags.conf".text = ''
    --enable-features=WaylandWindowDecorations
    --ozone-platform-hint=auto
    --password-store=gnome-libsecret
  '';


  # Gjør at standalone home-manager/nix kommandoer tillater unfree pakker.
  xdg.configFile."nixpkgs/config.nix".text = ''
    {
      allowUnfree = true;
    }
  '';

  dconf.settings = {
    "org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9" = {
      font = "JetBrainsMono Nerd Font 13";
      use-system-font = false;
      use-custom-command = false;
      audible-bell = false;
    };
  };

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
