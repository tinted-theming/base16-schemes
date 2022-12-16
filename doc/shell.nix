with import <nixpkgs> { };

stdenv.mkDerivation {
  name = "nixbox-shell";
  buildInputs = [
    helvetica-neue-lt-std
    imagemagick
    ghostscript
    envsubst
    yq
  ];
}
