{ lib, pkgs, ... }:
let
  inherit (builtins) tofile readfile;
  inherit (lib) filecontents mkforce;

  name = "taylor gunnoe";
in
{

  imports = [ ../../profiles/develop /*./vpn.nix ./mail.nix ./graphical*/ ];

  users.users.root.hashedpassword = filecontents ../../secrets/root;

  users.users.tgunnoe.packages = with pkgs; [ pandoc ];

  programs.gnupg.agent = {
    enable = true;
    enablesshsupport = true;
  };

  environment.systempackages = with pkgs; [ cachix ];

  home-manager.users.tgunnoe = {
    imports = [
      ../profiles/git
      ../profiles/alacritty
      ../profiles/direnv
      ../profiles/emacs
    ];

    home = {
      packages = mkForce [ ];

      file = {
#        ".ec2-keys".source = ../../secrets/ec2;
#        ".cargo/credentials".source = ../../secrets/cargo;
        ".zshrc".text = "#";
        ".gnupg/gpg-agent.conf".text = ''
          pinentry-program ${pkgs.pinentry_curses}/bin/pinentry-curses
        '';
#        ".config/cachix/cachix.dhall".source = ../../secrets/cachix.dhall;
      };
    };

    programs.mpv = {
      enable = true;
      config = {
        ytdl-format = "bestvideo[height<=?1080]+bestaudio/best";
        hwdec = "auto";
        vo = "gpu";
      };
    };

    programs.git = {
      userName = name;
      userEmail = "t@gvno.net";
      # signing = {
      #   key = "8985725DB5B0C122";
      #   signByDefault = true;
      # };
    };

    programs.ssh = {
      enable = true;
      hashKnownHosts = true;

      # matchBlocks =
      #   let
      #     githubKey = toFile "github" (readFile ../../secrets/github);

      #     gitlabKey = toFile "gitlab" (readFile ../../secrets/gitlab);
      #   in
      #   {
      #     github = {
      #       host = "github.com";
      #       identityFile = githubKey;
      #       extraOptions = { AddKeysToAgent = "yes"; };
      #     };
      #     gitlab = {
      #       host = "gitlab.com";
      #       identityFile = gitlabKey;
      #       extraOptions = { AddKeysToAgent = "yes"; };
      #     };
      #     # "gitlab.company" = {
      #     #   host = "gitlab.company.com";
      #     #   identityFile = gitlabKey;
      #     #   extraOptions = { AddKeysToAgent = "yes"; };
      #     # };
      #   };
    };
  };

  users.groups.media.members = [ "tgunnoe" ];

  users.users.tgunnoe = {
    uid = 1000;
    description = name;
    isNormalUser = true;
    hashedPassword = fileContents ../../secrets/tgunnoe;
    extraGroups = [ "wheel" "input" "networkmanager" "libvirtd" ];
  };
}
