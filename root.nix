{ config, pkgs, ... }:
{
  home.stateVersion = "25.11";
  home.username = "root";
  home.homeDirectory = "/root";
  home.enableNixpkgsReleaseCheck = false;

  home.packages = with pkgs; [
    zsh
    starship
    fzf
    fd
    ripgrep
    bat
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
      if command -v bat >/dev/null 2>&1; then
        alias cat='bat'
      fi
      if command -v rg >/dev/null 2>&1; then
        alias grep='rg'
      fi

      # Use store path directly to avoid depending on ~/.nix-profile.
      eval "$(${pkgs.starship}/bin/starship init zsh)"

      # Upgrade helper (flake workflow)
      # - updates flake inputs
      # - rebuilds NixOS via nixos-rebuild --flake
      # - auto-recovers from stale empty boot.json in /nix/store
      upgrade-os() {
        local REPO=/home/henrik/nixos-config
        local CANON
        CANON=$(readlink -f "$REPO/flake.nix" 2>/dev/null || true)
        if [ -n "$CANON" ]; then
          REPO=$(dirname "$CANON")
        fi

        if [ ! -f "$REPO/flake.nix" ]; then
          echo "❌ No flake.nix found at $REPO"
          return 1
        fi

        echo "🧹 Preflight: removing broken system generations (empty boot.json)..."
        local BROKEN_GENS
        local target
        local gen
        BROKEN_GENS=$(for link in /nix/var/nix/profiles/system-*-link; do
          [ -e "$link" ] || continue
          target=$(readlink -f "$link" 2>/dev/null || true)
          gen=$(basename "$link" | sed -E 's/^system-([0-9]+)-link$/\1/')
          [ -n "$target" ] || continue
          if [ -s "$target/boot.json" ]; then
            continue
          fi
          if [ -f "$target/boot.json" ]; then
            echo "$gen"
          fi
        done | sort -n | uniq)

        if [ -n "$BROKEN_GENS" ]; then
          echo "⚠️ Removing broken generations: $BROKEN_GENS"
          for gen in $BROKEN_GENS; do
            nix-env -p /nix/var/nix/profiles/system --delete-generations "$gen" || true
          done
        else
          echo "✅ No broken system generations found"
        fi

        echo "🔄 Updating flake inputs..."
        if ! nix flake update --flake "$REPO"; then
          echo "❌ nix flake update failed"
          return 1
        fi

        echo ""
        echo "📋 Updated flake revisions in $REPO:"
        nix flake metadata --flake "$REPO" 2>/dev/null | command grep -E "^  (nixpkgs|home-manager|sops-nix):" | head -3
        echo ""

        echo "🔄 Rebuilding NixOS (flake workflow)..."
        if nixos-rebuild switch --flake "path:$REPO#nixos" --impure; then
          echo "🧹 Running garbage collection (older than 30 days)..."
          nix-collect-garbage --delete-older-than 30d || true
          echo "✅ Upgrade complete"
          return 0
        fi

        local BROKEN_BOOT_JSON
        BROKEN_BOOT_JSON=$(find /nix/store -maxdepth 2 -type f -name boot.json -size 0c 2>/dev/null | head -n1 || true)
        if [ -z "$BROKEN_BOOT_JSON" ]; then
          echo "❌ nixos-rebuild failed"
          return 1
        fi

        echo "⚠️ Detected empty boot.json at $BROKEN_BOOT_JSON"
        local TOPLEVEL
        local INIT
        local KERNEL
        local INITRD
        local LABEL
        local TMP_JSON

        TOPLEVEL=$(dirname "$BROKEN_BOOT_JSON")
        INIT="$TOPLEVEL/init"
        KERNEL="$TOPLEVEL/kernel"
        INITRD="$TOPLEVEL/initrd"
        LABEL=$(basename "$TOPLEVEL")

        if [ ! -e "$INIT" ] || [ ! -e "$KERNEL" ] || [ ! -e "$INITRD" ]; then
          echo "❌ Auto-recovery failed: missing init/kernel/initrd in $TOPLEVEL"
          return 1
        fi

        TMP_JSON=$(mktemp /tmp/boot-fix.XXXXXX.json)
        command cat > "$TMP_JSON" << EOF
{
  "org.nixos.bootspec.v1": {
    "init": "$INIT",
    "initrd": "$INITRD",
    "kernel": "$KERNEL",
    "kernelParams": [],
    "label": "$LABEL",
    "system": "x86_64-linux",
    "toplevel": "$TOPLEVEL"
  },
  "org.nixos.specialisation.v1": {},
  "org.nixos.systemd-boot": {
    "sortKey": "nixos"
  }
}
EOF

        mount --bind "$TMP_JSON" "$BROKEN_BOOT_JSON"
        local _cleanup_done=0
        _upgrade_os_cleanup() {
          if [ "$_cleanup_done" -eq 0 ]; then
            umount "$BROKEN_BOOT_JSON" 2>/dev/null || true
            rm -f "$TMP_JSON"
            _cleanup_done=1
          fi
        }
        trap _upgrade_os_cleanup EXIT INT TERM

        echo "🔁 Retrying nixos-rebuild switch --flake path:$REPO#nixos --impure ..."
        if ! nixos-rebuild switch --flake "path:$REPO#nixos" --impure; then
          _upgrade_os_cleanup
          trap - EXIT INT TERM
          echo "❌ nixos-rebuild failed (even after boot.json recovery)"
          return 1
        fi

        _upgrade_os_cleanup
        trap - EXIT INT TERM
        echo "🧹 Running garbage collection (older than 30 days)..."
        nix-collect-garbage --delete-older-than 30d || true
        echo "✅ Upgrade complete (after boot.json recovery)"
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
