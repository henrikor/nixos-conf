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

      # Upgrade helper - IMPROVED VERSION
      # - system update via nixos-rebuild --upgrade (channel-based system config)
      # - Home Manager updates via flake in REPO with explicit rebuild and feedback
      upgrade-os() {
        local REPO=/home/henrik/nixos-config
        local SEARCH="$REPO"
        local FOUND=""
        
        # Find flake.nix in repo or parents
        while [ -n "$SEARCH" ] && [ "$SEARCH" != "/" ]; do
          if [ -f "$SEARCH/flake.nix" ]; then
            FOUND="$SEARCH"
            break
          fi
          SEARCH=$(dirname "$SEARCH")
        done

        # ========== SYSTEM UPGRADE ==========
        echo "🔄 Updating NixOS system (channel workflow)..."
        if nixos-rebuild switch --upgrade; then
          echo "✅ NixOS system updated successfully"
        else
          echo "❌ nixos-rebuild --upgrade failed"
          return 1
        fi

        # ========== FLAKE DISCOVERY ==========
        if [ -z "$FOUND" ]; then
          echo "⚠️  No flake.nix found under $REPO or its parents; using standard home-manager"
          home-manager switch || { echo "❌ home-manager switch failed"; return 1; }
          return 0
        fi

        # Resolve symlinked flake.nix to its real repo directory
        local CANON=$(readlink -f "$FOUND/flake.nix" 2>/dev/null || true)
        if [ -n "$CANON" ]; then
          REPO=$(dirname "$CANON")
        else
          REPO="$FOUND"
        fi

        # ========== SHOW CURRENT REVISIONS ==========
        echo ""
        echo "📋 Current flake revisions in $REPO:"
        nix flake metadata --flake "$REPO" 2>/dev/null | grep -E "^  (nixpkgs|home-manager):" | head -2
        echo ""

        # ========== UPDATE FLAKE ==========
        echo "🔄 Updating flake inputs (Home Manager)..."
        if nix flake update --flake "$REPO"; then
          echo "✅ Flake inputs updated successfully"
        else
          echo "❌ nix flake update failed - HOME MANAGER MAY NOT BE UPDATED!"
          return 1
        fi

        # ========== SHOW NEW REVISIONS ==========
        echo ""
        echo "📋 Updated flake revisions:"
        nix flake metadata --flake "$REPO" 2>/dev/null | grep -E "^  (nixpkgs|home-manager):" | head -2
        echo ""

        # ========== REBUILD HOME MANAGERS ==========
        echo "🔄 Rebuilding Home Manager for root..."
        if home-manager switch --flake "$REPO#root"; then
          echo "✅ Root Home Manager updated"
        else
          echo "❌ Root Home Manager update failed"
          return 1
        fi

        echo "🔄 Rebuilding Home Manager for henrik..."
        if runuser -u henrik -- home-manager switch --flake "$REPO#henrik"; then
          echo "✅ Henrik's Home Manager updated"
        else
          echo "❌ Henrik's Home Manager update failed"
          return 1
        fi

        echo ""
        echo "✨ All upgrades completed successfully!"
        return 0
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
