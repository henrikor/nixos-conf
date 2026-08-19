#!/usr/bin/env bash
set -euo pipefail

REPO="/home/henrik/nixos-config"

echo "🧹 Preflight: rydder ødelagte system-generasjoner (tom boot.json)..."
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
  echo "⚠️ Fjerner generasjoner: $BROKEN_GENS"
  for gen in $BROKEN_GENS; do
    nix-env -p /nix/var/nix/profiles/system --delete-generations "$gen" || true
  done
else
  echo "✅ Fant ingen ødelagte generasjoner"
fi

# Finn en ødelagt (tom) boot.json i /nix/store.
BROKEN_BOOT_JSON=$(find /nix/store -maxdepth 2 -type f -name boot.json -size 0c 2>/dev/null | head -n1 || true)

if [ -z "$BROKEN_BOOT_JSON" ]; then
  echo "ℹ️ Fant ingen tom boot.json. Kjører vanlig flake-oppgradering..."
  nix flake update --flake "$REPO"
  nixos-rebuild switch --flake "path:$REPO#nixos" --impure
  exit 0
fi

TOPLEVEL=$(dirname "$BROKEN_BOOT_JSON")
INIT="$TOPLEVEL/init"
KERNEL="$TOPLEVEL/kernel"
INITRD="$TOPLEVEL/initrd"
LABEL=$(basename "$TOPLEVEL")

if [ ! -e "$INIT" ] || [ ! -e "$KERNEL" ] || [ ! -e "$INITRD" ]; then
  echo "❌ Mangler init/kernel/initrd i $TOPLEVEL"
  echo "   Init:   $INIT"
  echo "   Kernel: $KERNEL"
  echo "   Initrd: $INITRD"
  exit 1
fi

TMP_JSON=$(mktemp /tmp/boot-fix.XXXXXX.json)

echo "📝 Lager gyldig boot.json i $TMP_JSON ..."
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

echo "🔗 Bind-mounter $TMP_JSON over $BROKEN_BOOT_JSON ..."
mount --bind "$TMP_JSON" "$BROKEN_BOOT_JSON"

cleanup() {
  echo "🧹 Rydder opp bind mount og tmp-fil..."
  umount "$BROKEN_BOOT_JSON" 2>/dev/null || true
  rm -f "$TMP_JSON"
}
trap cleanup EXIT

echo "🔄 Oppdaterer flake inputs..."
nix flake update --flake "$REPO"

echo "🔄 Kjører nixos-rebuild switch --flake path:$REPO#nixos --impure ..."
nixos-rebuild switch --flake "path:$REPO#nixos" --impure

echo "🧹 Kjører garbage collection (eldre enn 30 dager)..."
nix-collect-garbage --delete-older-than 30d || true

echo "✅ Ferdig!"
