{
  description = "A very basic flake";
  inputs = {
    zig.url = "github:arqv/zig-overlay";
    zls = {
      url = "https://github.com/zigtools/zls.git";
      type = "git";
      submodules = true;
      flake = false;
    };
    flake-utils.url = "github:numtide/flake-utils";
  };
  
  outputs = { self, nixpkgs, zig, zls, flake-utils }:
    let systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" ];
    in flake-utils.lib.eachSystem systems (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in rec {
        packages.zls = pkgs.stdenv.mkDerivation {
          pname = "zls";
          version = "master";
          src = zls;
          nativeBuildInputs = with pkgs; [
            zig.packages.${system}.master.latest
          ];
          buildPhase = "zig build -Drelease-safe";
          installPhase = "zig build install -Drelease-safe --prefix $out";
          XDG_CACHE_HOME = "/tmp/zig-cache";
        };
        
        packages.zbar = pkgs.stdenv.mkDerivation {
          pname = "zbar";
          version = "1";
          src = ./.;
          nativeBuildInputs = with pkgs; [
	          zig.packages.${system}.master.latest
            packages.zls
            gdb valgrind
          ];
          buildPhase = ''
            zig build -Drelease-safe
          '';
          installPhase = ''
            zig build install -Drelease-safe --prefix $out
          '';

          XDG_CACHE_HOME = "/tmp/zig-cache";
        };
        defaultPackage = packages.zbar;
        apps.zig-hello = flake-utils.lib.mkApp { drv = defaultPackage; };
        defaultApp = apps.zbar;
      });
}
