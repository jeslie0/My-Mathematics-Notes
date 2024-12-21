{
  description = "Nix flake to build my mathematics notes";

  inputs = {
    nixpkgs.url =
      "github:nixos/nixpkgs/nixos-unstable";

    fonts.url =
      "github:jeslie0/fonts";

    texmf.url =
      "github:jeslie0/texmf";
  };

  outputs = { self, nixpkgs, fonts, texmf }:
    let
      supportedSystems =
        [ "aarch64-linux" "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];

      forAllSystems =
        nixpkgs.lib.genAttrs supportedSystems;

      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
        });

      myfonts = system:
        fonts.defaultPackage.${system};

      mytexmf = system:
        texmf.defaultPackage.${system};

      mytex = system:
        nixpkgsFor.${system}.texlive.combine {
          # Put the packages that we want texlive to use when compiling the PDF in here.
          inherit (nixpkgsFor.${system}.texlive)
            scheme-full
            latex-bin
            fontspec
            latexmk;
        };

      buildInputs = system:
        [ nixpkgsFor.${system}.coreutils
          (mytex system)
          (mytexmf system)
          (myfonts system)
        ];

      packageName =
        "mathematics";

      version =
        "0.1.0";
    in
      {
        packages =
          forAllSystems (system:
            let
              pkgs =
                nixpkgsFor.${system};
            in
              {
                ${packageName} =
                  pkgs.stdenvNoCC.mkDerivation {
                    pname = packageName;
                    version = version;
                    buildInputs = buildInputs system;
                    src = ./src;
                    phases = [ "unpackPhase" "buildPhase" "installPhase" ];
                    buildPhase = ''
                    cp -r ${myfonts system}/share/fonts/opentype/* .
                    export PATH="${pkgs.lib.makeBinPath (buildInputs system)}";
                    mkdir -p .cache/texmf-var
                    env TEXMFHOME=${texmf} \
                        TEXMFVAR=.cache/texmf-var \
                        OSFONTDIR=${myfonts system}/share/fonts \
                        SOURCE_DATE_EPOCH=${toString self.lastModified} \
                        latexmk -interaction=nonstopmode -pdf -lualatex -bibtex \
                        -pretex="\pdfvariable suppressoptionalinfo 512\relax" \
                        $src/main.tex
                        '';
                    installPhase = ''
                    mkdir -p $out
                    cp main.pdf $out/${packageName}.pdf
                    '';
                  };

                default =
                  self.packages.${system}.${packageName};
              }
          );


        devShell =
          forAllSystems (system:
            let
              pkgs =
                nixpkgsFor.${system};
            in
              pkgs.mkShell {
                packages = with pkgs; [
                ];
                inputsFrom = [
                  self.packages.${system}.${packageName} # Include the inputs from our tex build
                ];
              }
          );
      };
}
