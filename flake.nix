{
  description = "A LuaTex project flake template";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/nixos-unstable;
    flake-utils.url = github:numtide/flake-utils;
    fonts.url = github:jeslie0/fonts;
  };

  outputs = { self, nixpkgs, flake-utils, fonts }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        myfonts = fonts.defaultPackage.${system};
        tex = pkgs.texlive.combine {
          # Put the packages that we want texlive to use when compiling the PDF in here.
          inherit (pkgs.texlive)
            # scheme-minimal
            # scheme-basic
            # scheme-small
            # scheme-medium
            scheme-full
            latex-bin
            fontspec
            latexmk;
        };
        buildInputs = [ pkgs.coreutils tex myfonts ];
        packageName = "mathematics";
        version = "0.0.0";
      in
      {
        packages.${packageName} = pkgs.stdenvNoCC.mkDerivation {
          pname = packageName;
          version = version;
          buildInputs = buildInputs;
          src = ./src;
          phases = [ "unpackPhase" "buildPhase" "installPhase" ];
          buildPhase = ''
            export PATH="${pkgs.lib.makeBinPath buildInputs}";
            mkdir -p .cache/texmf-var
            env TEXMFVAR=.cache/texmf-var \
                OSFONTDIR=${myfonts}/share/fonts \
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

        defaultPackage = self.packages.${system}.${packageName};

        devShell = pkgs.mkShell {
          packages = with pkgs; [
            texlab # A latex language server
          ];
          inputsFrom = [
            self.packages.${system}.${packageName} # Include the inputs from our tex build
          ];
        };
      }
    );
}
