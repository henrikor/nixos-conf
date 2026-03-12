{ pkgs, ... }:

{
  # zsh må aktiveres som tilgjengelig shell på systemnivå
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
  };

  users.users.henrik = {
    isNormalUser = true;
    description = "Henrik Ormåsen";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
    # Packages are now managed by Home Manager in home.nix
  };
}


