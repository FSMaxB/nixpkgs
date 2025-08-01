{
  stdenv,
  fetchFromGitHub,
  cmake,
  bpp-core,
  bpp-seq,
}:

stdenv.mkDerivation rec {
  pname = "bpp-phyl";

  inherit (bpp-core) version;

  src = fetchFromGitHub {
    owner = "BioPP";
    repo = "bpp-phyl";
    rev = "v${version}";
    sha256 = "192zks6wyk903n06c2lbsscdhkjnfwms8p7jblsmk3lvjhdipb20";
  };

  nativeBuildInputs = [ cmake ];
  buildInputs = [
    bpp-core
    bpp-seq
  ];

  postFixup = ''
    substituteInPlace $out/lib/cmake/bpp-phyl/bpp-phyl-targets.cmake  \
      --replace 'set(_IMPORT_PREFIX' '#set(_IMPORT_PREFIX'
  '';

  doCheck = !stdenv.hostPlatform.isDarwin;

  meta = bpp-core.meta // {
    homepage = "https://github.com/BioPP/bpp-phyl";
    changelog = "https://github.com/BioPP/bpp-phyl/blob/master/ChangeLog";
  };
}
