{ lib
, stdenv
, python3Packages
, fetchFromGitHub
, fetchpatch
, intltool
, gtk3
, gobject-introspection
, gst_all_1
, wrapGAppsHook
, xvfb-run
}:
let
  sqlalchemy_1 = python3Packages.sqlalchemy.overridePythonAttrs (a: rec {
    version = "1.4.49";
    src = python3Packages.fetchPypi {
      pname = "SQLAlchemy";
      inherit version;
      hash = "sha256-Bv8ly64ww5bEt3N0ZPKn/Deme32kCZk7GCsCTOyArtk=";
    };
    disabledTestPaths = [
      "test/aaa_profiling"
      "test/ext/mypy"
    ];
  });
in
python3Packages.buildPythonApplication rec {
  pname = "gourmand";
  version = "unstable-2023-01-27";

  src = fetchFromGitHub {
    owner = "GourmandRecipeManager";
    repo = "gourmand";
    rev = "19a544882b1aabb75d83494e3797e515909300bb";
    sha256 = "sha256-zux8EfNSEUUNuPiXzWixxufCS5lUoGdpCtBuhgxQjEk=";
  };

  # https://github.com/NixOS/nixpkgs/issues/56943
  strictDeps = false;

  postPatch = ''
    substituteInPlace setup.py \
      --replace "beautifulsoup4>=4.10.0" "beautifulsoup4" \
      --replace "lxml==4.6.3" "lxml" \
      --replace "pillow>=8.3.2" "pillow" \
      --replace "pygobject==3.40.1" "pygobject" \
      --replace "sqlalchemy==1.4.36" "sqlalchemy" \
      --replace "toml==0.10.2" "toml" \
      --replace "recipe-scrapers>=14.27.0" "recipe-scrapers"
  '';

  nativeBuildInputs = [
    intltool
  ];

  buildInputs = [
    gtk3
    gobject-introspection
    gst_all_1.gstreamer
    wrapGAppsHook
  ];

  propagatedBuildInputs = with python3Packages; [
    beautifulsoup4
    lxml
    pillow
    pygobject3
    recipe-scrapers
    sqlalchemy_1
    toml
    setuptools
    reportlab
    ebooklib
    pyenchant
    pygtkspellcheck
  ];

  checkInputs = [
    xvfb-run
  ] ++  (with python3Packages; [
    pytest
  ]);

  postInstall = ''
    install -D data/io.github.GourmandRecipeManager.Gourmand.desktop -t $out/share/applications/
    install -D data/io.github.GourmandRecipeManager.Gourmand.svg -t $out/share/icons/hicolor/scalable/apps/
    install -D data/io.github.GourmandRecipeManager.Gourmand.appdata.xml -t $out/share/appdata/

    substituteInPlace $out/share/applications/io.github.GourmandRecipeManager.Gourmand.desktop \
      --replace "Exec=gourmand" "Exec=$out/bin/gourmand"
  '';

  dontWrapGApps = true;

  preFixup = ''
    makeWrapperArgs+=("''${gappsWrapperArgs[@]}")
  '';

  # we skip anything upstream ci doesn't run, and also the web scraping plugin
  # tests, since we do not enable the optional web scrape feature
  checkPhase = ''
    export HOME=$(mktemp -d)
    LANGUAGE=de_DE xvfb-run -a pytest -vv \
      --ignore-glob='tests/test_*_plugin.py' \
      --ignore=tests/broken \
      --ignore=tests/dogtail \
      --ignore=tests/old_databases \
      --ignore=tests/recipe_files \
      --ignore tests/test_db.py \
      tests/
  '';

  meta = with lib; {
    description = "Desktop recipe manager";
    longDescription = ''
      Gourmand Recipe Manager is a desktop cookbook application for editing and organizing recipes. It is a fork of the Gourmet Recipe Manager.
    '';
    homepage = "https://github.com/GourmandRecipeManager/gourmand";
    license = licenses.gpl2Only;
    maintainers = with maintainers; [ DeeUnderscore ];
  };
}
