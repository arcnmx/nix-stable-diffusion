{
  buildPythonPackage
, fetchFromGitHub

, stable-diffusion

# following packages not needed for vanilla SD but used by both UIs
, realesrgan
, pillow

, send2trash
, flask
, flask-socketio
, flask-cors
, dependency-injector
, gfpgan
, eventlet
, clipseg
, getpass-asterisk
}:
buildPythonPackage rec {
  pname = "invokeai";
  version = "2.0.2";

  src = fetchFromGitHub {
    owner = "invoke-ai";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-MSQplZM/byER3TZn90C5ezU441bsS+OcXuMiCXVL3lU=";
  };
  patches = [ ./paths.patch ];

  postPatch = ''
    touch ldm/{.,models,modules,invoke}/__init__.py
  '';

  propagatedBuildInputs = [
    stable-diffusion
    realesrgan
    pillow
    send2trash
    flask
    flask-socketio
    flask-cors
    dependency-injector
    gfpgan
    eventlet
    clipseg
    getpass-asterisk
  ];

  doCheck = false;
}
