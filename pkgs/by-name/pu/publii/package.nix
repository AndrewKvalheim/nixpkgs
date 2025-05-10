{
  stdenv,
  lib,
  fetchurl,
  autoPatchelfHook,
  makeShellWrapper,
  wrapGAppsHook3,
  alsa-lib,
  asar,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  glib,
  glibc,
  gtk3,
  jq,
  libsecret,
  libgbm,
  musl,
  nss,
  pango,
  udev,
  xdg-utils,
  xorg,
}:

stdenv.mkDerivation rec {
  pname = "publii";
  version = "0.46.5";

  src = fetchurl {
    url = "https://getpublii.com/download/Publii-${version}.deb";
    hash = "sha256-VymAHQNv3N7Mqe8wiUfYawi1BooczLFClxuwaW8NetA=";
  };

  packageJson = fetchurl {
    url = "https://raw.githubusercontent.com/GetPublii/Publii/refs/tags/v.0.46.5-build-17089/package.json";
    hash = "sha256-Xy1kbChZtm5BjS/HWhm2agQsQj1RSREwzp5JhHQg3X4=";
  };

  dontConfigure = true;
  dontBuild = true;
  dontWrapGApps = true;

  nativeBuildInputs = [
    autoPatchelfHook
    makeShellWrapper
    wrapGAppsHook3
  ];

  buildInputs = [
    alsa-lib
    asar
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    glib
    glibc
    gtk3
    jq
    libsecret
    libgbm
    musl
    nss
    pango
    xorg.libX11
    xorg.libxcb
  ];

  unpackPhase = ''
    ar p $src data.tar.xz | tar xJ
  '';

  prePatch = ''
    asar extract opt/Publii/resources/app.asar app
  '';

  postPatch = ''
    asar pack app opt/Publii/resources/app.asar \
      --unpack "$(jq --raw-output '.build.asarUnpack | "{\(join(","))}"' ${packageJson})"
    rm -r app
  '';

  patches = [
    (builtins.toFile "publii-issue-1322.patch" ''
      --- a/app/back-end/site.js
      +++ b/app/back-end/site.js
      @@ -96,4 +96,5 @@
                   path.join(this.siteDir, 'input', 'themes', 'simple')
               );
      +        require('child_process').execFileSync('chmod', ['--recursive', 'u+w', path.join(this.siteDir, 'input', 'themes', 'simple')]);
           }

      --- a/app/back-end/themes.js
      +++ b/app/back-end/themes.js
      @@ -229,4 +229,5 @@
                   path.join(this.sitePath, newTheme)
               );
      +        require('child_process').execFileSync('chmod', ['--recursive', 'u+w', path.join(this.sitePath, newTheme)]);

               // Return new name
    '')
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    mv usr/share $out
    substituteInPlace $out/share/applications/Publii.desktop \
      --replace-fail 'Exec=/opt/Publii/Publii' 'Exec=Publii'

    mv opt $out

    runHook postInstall
  '';

  preFixup = ''
    makeWrapper $out/opt/Publii/Publii $out/bin/Publii \
      "''${gappsWrapperArgs[@]}" \
      --suffix PATH : ${lib.makeBinPath [ xdg-utils ]} \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ udev ]}
  '';

  meta = with lib; {
    description = "Static Site CMS with GUI to build privacy-focused SEO-friendly website";
    mainProgram = "Publii";
    longDescription = ''
      Creating a website doesn't have to be complicated or expensive. With Publii, the most
      intuitive static site CMS, you can create a beautiful, safe, and privacy-friendly website
      quickly and easily; perfect for anyone who wants a fast, secure website in a flash.
    '';
    homepage = "https://getpublii.com";
    changelog = "https://github.com/getpublii/publii/releases/tag/v${version}";
    license = licenses.gpl3Only;
    maintainers = with lib.maintainers; [
      urandom
      sebtm
    ];
    platforms = [ "x86_64-linux" ];
  };
}
