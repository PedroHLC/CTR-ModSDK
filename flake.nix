{
  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*.tar.gz";
    systems.url = "github:nix-systems/default-linux";
    yafas = {
      url = "https://flakehub.com/f/UbiqueLambda/yafas/0.1.*.tar.gz";
      inputs.systems.follows = "systems";
    };
  };
  outputs = { self, nixpkgs, yafas, ... }: yafas.withAllSystems nixpkgs
    (_: { pkgs, system }: with pkgs; rec {
      packages =
        let
          pkgsAarch64 = pkgsCross.aarch64-multiplatform;
          pkgsARM32 = pkgsCross.armv7l-hf-multiplatform;
          pkgs32 = if system == "x86_64-linux" then pkgsi686Linux else pkgsARM32;

          mkCTR = withDebug: withMods: {
            native32 = with pkgs32; {
              gcc = callPackage ./rebuild_PC { ctrModSDK = self; inherit withDebug withMods; };
              clang = callPackage ./rebuild_PC { ctrModSDK = self; stdenv = clangStdenv; inherit withDebug withMods; };
            };
            mingw32 = with pkgsCross.mingw32; {
              gcc = callPackage ./rebuild_PC { ctrModSDK = self; inherit withDebug withMods; };
              clang = callPackage ./rebuild_PC { ctrModSDK = self; stdenv = clangStdenv; trustCompiler = true; inherit withDebug withMods; };
            };
          };

          mkOnline = path: withDebug: {
            native = {
              gcc = callPackage path { ctrModSDK = self; inherit withDebug; };
              clang = callPackage path { ctrModSDK = self; stdenv = clangStdenv; inherit withDebug; };
            };
            native32 = with pkgs32; {
              gcc = callPackage path { ctrModSDK = self; inherit withDebug; };
              clang = callPackage path { ctrModSDK = self; stdenv = clangStdenv; inherit withDebug; };
            };
            aarch64 = with pkgsAarch64; {
              gcc = callPackage path { ctrModSDK = self; inherit withDebug; };
              clang = callPackage path { ctrModSDK = self; stdenv = clangStdenv; inherit withDebug; };
            };
            arm32 = with pkgsARM32; {
              gcc = callPackage path { ctrModSDK = self; inherit withDebug; };
              clang = callPackage path { ctrModSDK = self; stdenv = clangStdenv; inherit withDebug; };
            };
            mingwW64 = with pkgsCross.mingwW64; {
              gcc = callPackage path { ctrModSDK = self; inherit withDebug; };
              clang = callPackage path { ctrModSDK = self; stdenv = clangStdenv; trustCompiler = true; inherit withDebug; };
            };
            mingw32 = with pkgsCross.mingw32; {
              gcc = callPackage path { ctrModSDK = self; inherit withDebug; };
              clang = callPackage path { ctrModSDK = self; stdenv = clangStdenv; trustCompiler = true; inherit withDebug; };
            };
          };

          mkOnlineServer = mkOnline ./mods/Windows/OnlineCTR/Network_PC/Server;
          mkOnlineClient = mkOnline ./mods/Windows/OnlineCTR/Network_PC/Client;
        in
        rec {
          pc-retail = {
            release = mkCTR false false;
            debug = mkCTR true false;
          };
          pc-decomp = {
            release = mkCTR false true;
            debug = mkCTR true true;
          };
          online-server = {
            release = mkOnlineServer false;
            debug = mkOnlineServer true;
          };
          online-client = {
            release = mkOnlineClient false;
            debug = mkOnlineClient true;
          };
        };
    })
    { };
}
