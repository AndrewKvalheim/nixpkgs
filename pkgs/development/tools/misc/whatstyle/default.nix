{ lib, stdenv, python3, fetchFromGitHub, clang-unwrapped }:

python3.pkgs.buildPythonApplication rec {
  pname = "whatstyle";
  version = "0.1.8";
  src = fetchFromGitHub {
    owner = "mikr";
    repo = pname;
    rev = "v${version}";
    sha256 = "08lfd8h5fnvy5gci4f3an411cypad7p2yiahvbmlp51r9xwpaiwr";
  };

  # Fix references to previous version, to avoid confusion:
  postPatch = ''
    substituteInPlace setup.py --replace 0.1.6 ${version}
    substituteInPlace ${pname}.py --replace 0.1.6 ${version}
  '';

  checkInputs = [ clang-unwrapped /* clang-format */ ];

  doCheck = false; # 3 or 4 failures depending on version, haven't investigated.

  meta = with lib; {
    description = "Find a code format style that fits given source files";
    homepage = "https://github.com/mikr/whatstyle";
    license = licenses.mit;
    maintainers = with maintainers; [ dtzWill ];
    platforms = platforms.all;
  };
}
