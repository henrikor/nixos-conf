# nixos-conf

## Oppgradering (flake-basert)

Dette repoet bruker nå flake-workflow for systemoppgraderinger.

### Anbefalt kommando (root)

```bash
upgrade-os
```

`upgrade-os` gjør følgende:
1. Preflight: fjerner system-generasjoner som peker til tom `boot.json`
2. Oppdaterer flake-inputs (`nix flake update`)
3. Kjører `nixos-rebuild switch --flake "path:/home/henrik/nixos-config#nixos" --impure`
4. Hvis nødvendig: fallback med midlertidig `boot.json` og retry

## Manuell fallback

Hvis du trenger å kjøre recovery direkte:

```bash
sudo bash /home/henrik/nixos-config/fix-boot-and-upgrade.sh
```

Scriptet:
- rydder ødelagte system-generasjoner
- håndterer tom `boot.json` via bind-mount av gyldig midlertidig JSON
- oppdaterer flake-inputs og bygger systemet på nytt

## Viktig

Bruk flake-kommando (ikke kanal-basert rebuild):

```bash
sudo nixos-rebuild switch --flake "path:/home/henrik/nixos-config#nixos" --impure
```
