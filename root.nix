{ config, pkgs, ... }:
{
  home.stateVersion = "25.11";
  home.username = "root";
  home.homeDirectory = "/root";

  home.packages = with pkgs; [
    zsh
    starship
    fzf
    fd
    viu
    chafa
    kitty
    broot
    eza
  ];

  programs.zsh = {
    enable = true;
    autocd = true;
    initContent = ''
      # Basic setup copied from henrik's config
      eval "$(zoxide init zsh --cmd cd)"

      source ${pkgs.fzf}/share/fzf/key-bindings.zsh
      source ${pkgs.fzf}/share/fzf/completion.zsh

      export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
      export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
      export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

      export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --inline-info'

      # Handy aliases (fallback to system ls if eza isn't installed for root)
      if command -v eza >/dev/null 2>&1; then
        alias ls='eza --icons --group-directories-first'
      else
        alias ls='command ls'
      fi
      alias cat='bat'
      alias grep='rg'

      # Use store path directly to avoid depending on ~/.nix-profile.
      eval "$(${pkgs.starship}/bin/starship init zsh)"

      # Upgrade helper:
      # - system update via nixos-rebuild --upgrade (channel-based system config)
      # - Home Manager updates via flake in REPO when available
      upgrade-os() {
        REPO=/home/henrik/nixos-config

        SEARCH="$REPO"
        FOUND=""
        while [ -n "$SEARCH" ] && [ "$SEARCH" != "/" ]; do
          if [ -f "$SEARCH/flake.nix" ]; then
            FOUND="$SEARCH"
            break
          fi
          SEARCH=$(dirname "$SEARCH")
        done

        echo "Updating NixOS system (channel workflow)..."
        nixos-rebuild switch --upgrade || { echo "nixos-rebuild --upgrade failed"; return 1; }

        if [ -z "$FOUND" ]; then
          echo "No flake.nix found under $REPO or its parents; skipping flake-based Home Manager updates"
          home-manager switch || true
          return 0
        fi

        # Resolve symlinked flake.nix to its real repo directory so we don't
        # accidentally treat /home/henrik (or other parent dirs) as the flake root.
        CANON=$(readlink -f "$FOUND/flake.nix" 2>/dev/null || true)
        if [ -n "$CANON" ]; then
          REPO=$(dirname "$CANON")
        else
          REPO="$FOUND"
        fi

        echo "Updating flake inputs for Home Manager in $REPO..."
        nix flake update --flake "$REPO" || { echo "flake update failed"; return 1; }

        echo "Switching Home Manager for root and henrik (flake)..."
        home-manager switch --flake "$REPO#root" || true
        runuser -u henrik -- home-manager switch --flake "$REPO#henrik" || true
      }
    '';
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = false;
    settings = {
      username = {
        show_always = false;
        style_user = "bold red";
        format = "[$user]($style) ";
      };
      directory = {
        truncate_to_repo = true;
        style = "bold cyan";
        home_symbol = " ~";
      };
    };
  };

  programs.fzf = { enable = true; enableZshIntegration = true; };
  programs.zoxide = { enable = true; enableZshIntegration = true; };

  # No manual .zshrc or separate starship config here; programs.starship
  # handles the generated starship configuration.
}
