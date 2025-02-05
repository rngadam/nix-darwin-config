{
  description = "Ricky's nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      home-manager,
    }:
    let
      configuration =
        { pkgs, ... }:
        {
          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          environment.systemPackages = [
            pkgs.vim
            pkgs.nixfmt-rfc-style
            pkgs.neofetch
            pkgs.ansible
            pkgs.bashInteractive
            pkgs.git
            pkgs.jq
            pkgs.direnv
            pkgs.sshpass
          ];

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # Enable alternative shell support in nix-darwin.
          # programs.fish.enable = true;

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 6;

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "x86_64-darwin";

          # enable TouchID integration
          security.pam.enableSudoTouchIdAuth = true;
          system.defaults = {
            dock.autohide = true;
            dock.mru-spaces = false;
            finder.AppleShowAllExtensions = true;
            finder.FXPreferredViewStyle = "clmv";
            loginwindow.LoginwindowText = "ricky@coderbunker.ca";
            screencapture.location = "~/Downloads";
            screensaver.askForPasswordDelay = 10;
          };
        # Declare the user that will be running `nix-darwin`.
          users.users.rngadam = {
              name = "rngadam";
              home = "/Users/rngadam";
          };

        };
      homeconfig =
        { pkgs, ... }:
        {
          # this is internal compatibility configuration
          # for home-manager, don't change this!
          home.stateVersion = "23.05";
          # Let home-manager install and manage itself.
          programs.home-manager.enable = true;

          home.packages = with pkgs; [ ];

          home.sessionVariables = {
            EDITOR = "vim";
          };

          home.file.".vimrc".source = ./vim_configuration;
          programs.git = {
              enable = true;
              userName = "Ricky Ng-Adam";
              userEmail = "ricky@coderbunker.ca";
              ignores = [ ".DS_Store" ];
              extraConfig = {
                  init.defaultBranch = "main";
                  push.autoSetupRemote = true;
              };
          };
          programs.bash = {
              enable = true;
              shellAliases = {
                  switch = "darwin-rebuild switch --flake ~/nix-darwin-config";
              };
          };

          programs.starship = {
            enable = true;
          };
        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#simple
      darwinConfigurations."rngadam-mac" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.verbose = true;
            home-manager.users.rngadam = homeconfig;
            home-manager.backupFileExtension = "bak";
          }
        ];
      };
    };
}
