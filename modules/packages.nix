{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
     vim
     wget
     emacs
     git
     byobu
     nix-index
     hyprland
     waybar
     yadm
     tmux
     zsh
     nerd-fonts.meslo-lg
  ];
}


