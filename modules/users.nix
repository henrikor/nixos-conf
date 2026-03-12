{ pkgs, ... }:

{
  users.users.henrik = {
    isNormalUser = true;
    description = "Henrik Ormåsen";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      brave
      element-desktop
      vscode
    ];
  };
}


