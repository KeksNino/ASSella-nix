{
  description = "Nix flake for ASSella (ACCELA Fork)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    assella-src = {
      url = "github:niwia/ASSella?ref=v2.5.8";
      flake = false;
    };

    # Git dependencies
    steam-src = {
      url = "github:solsticegamestudios/steam/1373e885f26bb636225443787f54d4082283e5f3";
      flake = false;
    };

    vdf-src = {
      url = "github:solsticegamestudios/vdf/fb88ea7e38a85476743f5601b0c80d5715034623";
      flake = false;
    };
  };

  outputs =
    { self
    , nixpkgs
    , assella-src
    , steam-src
    , vdf-src
    }:

    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };

          lib = pkgs.lib;
          python = pkgs.python3;
          ps = python.pkgs;

          vdf = ps.buildPythonPackage {
            pname = "vdf";
            version = "3.4";

            src = vdf-src;

            format = "setuptools";
            doCheck = false;
          };

          gevent-eventemitter = ps.buildPythonPackage rec {
            pname = "gevent-eventemitter";
            version = "2.1";

            src = ps.fetchPypi {
              inherit pname version;

              hash = "sha256-AObmiMaiVfe9zvHYyZng0C2auH08b/Ym5twaCXYhB/Q=";
            };

            format = "setuptools";
            doCheck = false;

            propagatedBuildInputs = [
              ps.gevent
            ];
          };

          just-playback = ps.buildPythonPackage rec {
            pname = "just_playback";
            version = "0.1.8";

            src = ps.fetchPypi {
              inherit pname version;

              hash = "sha256-5ZdHSfEPque7drPx43eaE2knWrF52HWdrifp8ptBA1A=";
            };

            format = "setuptools";
            doCheck = false;

            propagatedBuildInputs = [
              ps.miniaudio
              ps.tinytag
            ];
          };

          steam-py = ps.buildPythonPackage {
            pname = "steam";
            version = "1.4.4";

            src = steam-src;

            format = "setuptools";
            doCheck = false;

            nativeBuildInputs = [
              ps.pythonRelaxDepsHook
            ];

            pythonRelaxDeps = [
              "protobuf"
              "gevent"
              "vdf"
            ];

            propagatedBuildInputs = [
              ps.cachetools
              ps.gevent
              gevent-eventemitter
              ps.protobuf
              ps.pycryptodomex
              ps.requests
              ps.six
              vdf
              ps.pyrate-limiter
              ps.urllib3
            ];
          };


          pythonEnv = python.withPackages (p: [
            p.pyqt6
            p."pyqt6-sip"
            p.psutil
            p.requests
            p.zstandard
            p.gevent
            gevent-eventemitter
            just-playback
            p.tinytag
            p.beautifulsoup4
            steam-py
            vdf
            p.pillow
            p.urwid
            p.cryptography
            p.numpy
            p.urllib3
          ]);

          runtimeLibs = with pkgs; [
            zstd
            alsa-lib
            libpulseaudio
          ];

          assella = pkgs.stdenvNoCC.mkDerivation {
            pname = "assella";
            version = "0-unstable-${assella-src.shortRev or "unknown"}";

            src = assella-src;

            nativeBuildInputs = [
              pkgs.makeWrapper
              pkgs.qt6.wrapQtAppsHook
            ];

            buildInputs = [
              pkgs.qt6.qtbase
              pkgs.qt6.qtwayland
              pkgs.qt6.qtsvg
              pkgs.zstd
            ];

            dontBuild = true;
            dontWrapQtApps = true;

            installPhase = ''
              runHook preInstall

              mkdir -p $out/lib/assella
              cp -R src/. $out/lib/assella/

              mkdir -p $out/bin

              makeWrapper ${pythonEnv}/bin/python $out/bin/assella \
                --add-flags "$out/lib/assella/main.py" \
                --chdir "$out/lib/assella" \
                --set PYTHONNOUSERSITE 1 \
                --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}" \
                "''${qtWrapperArgs[@]}"

              mkdir -p $out/share/applications

              cat > $out/share/applications/assella.desktop <<EOF
                [Desktop Entry]
                Type=Application
                Name=ASSella
                Comment=ASSella Application
                Exec=$out/bin/assella %u
                Icon=assella
                Terminal=false
                Categories=Utility;Application;
                MimeType=x-scheme-handler/accela;
                EOF

                if [ -f src/res/logo/icon.png ]; then
                    install -Dm644 src/res/logo/icon.png \
                    $out/share/icons/hicolor/256x256/apps/assella.png
                fi

                runHook postInstall
            '';

            meta = {
              description = "ASSella packaged for Nix";
              homepage = "https://github.com/niwia/ASSella";
              platforms = lib.platforms.linux;
              mainProgram = "assella";
            };
          };
        in
        {
          default = assella;
          assella = assella;
        });

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.assella}/bin/assella";
        };

        assella = {
          type = "app";
          program = "${self.packages.${system}.assella}/bin/assella";
        };
      });
    };
}
