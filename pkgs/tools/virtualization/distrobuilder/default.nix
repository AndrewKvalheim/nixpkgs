{ lib
, buildGoModule
, callPackage
, cdrkit
, coreutils
, debootstrap
, fetchFromGitHub
, gnupg
, gnutar
, hivex
, makeWrapper
, nixosTests
, pkg-config
, squashfsTools
, wimlib
}:

let
  bins = [
    cdrkit
    coreutils
    debootstrap
    gnupg
    gnutar
    hivex
    squashfsTools
    wimlib
  ];
in
buildGoModule rec {
  pname = "distrobuilder";
  version = "3.0";

  vendorHash = "sha256-pFrEkZnrcx0d3oM1klQrNHH+MiLvO4V1uFQdE0kXUqM=";

  src = fetchFromGitHub {
    owner = "lxc";
    repo = "distrobuilder";
    rev = "refs/tags/distrobuilder-${version}";
    sha256 = "sha256-JfME9VaqaQnrhnzhSLGUy9uU+tki1hXdnwqBUD/5XH0=";
    fetchSubmodules = false;
  };

  buildInputs = bins;


  # tests require a local keyserver (mkg20001/nixpkgs branch distrobuilder-with-tests) but gpg is currently broken in tests
  doCheck = false;

  nativeBuildInputs = [
    pkg-config
    makeWrapper
  ] ++ bins;

  postInstall = ''
    wrapProgram $out/bin/distrobuilder --prefix PATH ":" ${lib.makeBinPath bins}
  '';

  passthru = {
    tests = {
      incus-legacy-init = nixosTests.incus.container-legacy-init;
      incus-systemd-init = nixosTests.incus.container-systemd-init;
    };

    generator = callPackage ./generator.nix { inherit src version; };
  };

  meta = {
    description = "System container image builder for LXC and LXD";
    homepage = "https://github.com/lxc/distrobuilder";
    license = lib.licenses.asl20;
    maintainers = lib.teams.lxc.members;
    platforms = lib.platforms.linux;
    mainProgram = "distrobuilder";
  };
}
