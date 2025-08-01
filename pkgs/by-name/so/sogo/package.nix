{
  lib,
  clangStdenv,
  fetchFromGitHub,
  makeWrapper,
  python3,
  lndir,
  libxcrypt,
  openssl,
  openldap,
  sope,
  libmemcached,
  curl,
  libsodium,
  libytnef,
  libzip,
  pkg-config,
  nixosTests,
  oath-toolkit,
  gnustep-make,
  gnustep-base,
  enableActiveSync ? false,
  libwbxml,
}:

clangStdenv.mkDerivation rec {
  pname = "sogo";
  version = "5.12.3";

  # always update the sope package as well, when updating sogo
  src = fetchFromGitHub {
    owner = "Alinto";
    repo = "sogo";
    rev = "SOGo-${version}";
    hash = "sha256-HTfe/ZiipqS6QdKQK0wf4Xl6xCTNw5fEdXfRFbBMWMY=";
  };

  nativeBuildInputs = [
    makeWrapper
    python3
    pkg-config
  ];
  buildInputs = [
    gnustep-base
    sope
    openssl
    libmemcached
    curl
    libsodium
    libytnef
    libzip
    openldap
    oath-toolkit
    libxcrypt
  ]
  ++ lib.optional enableActiveSync libwbxml;

  patches = lib.optional enableActiveSync ./enable-activesync.patch;

  postPatch = ''
    # Exclude NIX_ variables
    sed -i 's/grep GNUSTEP_/grep ^GNUSTEP_/g' configure

    # Disable argument verification because $out is not a GNUStep prefix
    sed -i 's/^validateArgs$//g' configure

    # Patch exception-generating python scripts
    patchShebangs .

    # Move all GNUStep makefiles to a common directory
    mkdir -p makefiles
    cp -r {${gnustep-make},${sope}}/share/GNUstep/Makefiles/* makefiles

    # Modify the search path for GNUStep makefiles
    find . -type f -name GNUmakefile -exec sed -i "s:\\$.GNUSTEP_MAKEFILES.:$PWD/makefiles:g" {} +
  '';

  configureFlags = [
    "--disable-debug"
    "--with-ssl=ssl"
    "--enable-mfa"
  ];

  env.NIX_CFLAGS_COMPILE = "-Wno-error=incompatible-pointer-types -Wno-error=int-conversion -Wno-error=implicit-int -Wno-error=return-type";

  preFixup = ''
    # Create gnustep.conf
    mkdir -p $out/share/GNUstep
    cp ${gnustep-make}/etc/GNUstep/GNUstep.conf $out/share/GNUstep/
    sed -i "s:${gnustep-make}:$out:g" $out/share/GNUstep/GNUstep.conf

    # Link in GNUstep base
    ${lndir}/bin/lndir ${lib.getLib gnustep-base}/lib/GNUstep/ $out/lib/GNUstep/

    # Link in sope
    ${lndir}/bin/lndir ${sope}/ $out/

    # sbin fixup
    mkdir -p $out/bin
    mv $out/sbin/* $out/bin
    rmdir $out/sbin

    # Make sogo find its files
    for bin in $out/bin/*; do
      wrapProgram $bin --prefix LD_LIBRARY_PATH : $out/lib/sogo --prefix GNUSTEP_CONFIG_FILE : $out/share/GNUstep/GNUstep.conf
    done
  '';

  passthru.tests.sogo = nixosTests.sogo;

  meta = with lib; {
    description = "Very fast and scalable modern collaboration suite (groupware)";
    license = with licenses; [
      gpl2Only
      lgpl21Only
    ];
    homepage = "https://sogo.nu/";
    platforms = platforms.linux;
    maintainers = with maintainers; [ jceb ];
  };
}
