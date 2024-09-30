{
  autoPatchelfHook,
  cups,
  fetchurl,
  lib,
  stdenv,
}:

stdenv.mkDerivation {
  pname = "flashlabel-a80";
  version = "1.2.1";

  src = fetchurl {
    url = "https://help.flashlabel.com/helpdesk/attachments/150080666194";
    hash = "sha256-qkc3NJ1dK0nJf+Q7xL7f1/+X0COWSWMEbH4luzaFARc=";
  };

  # The driver is distributed as a self-extracting executable consisting of a
  # shell script concatenated with a gzipped tar archive. The script hard codes
  # its length in the `lines` variable, which we read to locate the archive.
  unpackPhase = ''
    lines="$(sed 's/^lines=//; t; d' "$src")"
    tail --lines "+$lines" "$src" | tar --extract --gzip --strip-components=1
  '';

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ cups ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir --parents $out/lib/cups/filter
    mv {A80,A80H} $out/lib/cups/filter

    mkdir --parents $out/share/cups/model
    mv *.ppd $out/share/cups/model

    runHook postInstall
  '';

  postFixup = ''
    gzip --best $out/share/cups/model/*.ppd
  '';

  meta = {
    description = "Printer driver for FlashLabel A80 & A80H";
    longDescription = ''
      Supported models:

        - A80
        - A80H
        - C80
        - C80H
        - C80S
        - C80Y
        - D80
        - D80 Pro
        - Y8
        - Y8 Pro

      Driver is internally named YXWL.
    '';
    homepage = "https://flashlabel.com/";
    downloadPage = "https://help.flashlabel.com/support/solutions/articles/150000191214";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
  };
}
