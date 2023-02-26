{
  buildPythonPackage
, fetchFromGitHub
, stable-diffusion
, python
, lndir

, taming-transformers-rom1504
, transformers
, k-diffusion

, realesrgan
, pillow

, addict
, future
, lmdb
, pyyaml
, scikitimage
, tqdm
, yapf
, gdown
, lpips
, fastapi
, lark
, analytics-python
, ffmpy
, markdown-it-py
, shap
, gradio
, fonts
, font-roboto
, piexif
, websockets
, codeformer
, blip
, deepdanbooru
, timm
, fairscale
, inflection
}@args:
let
  transformers = args.transformers.overrideAttrs (old: {
    src = fetchFromGitHub {
      owner = "huggingface";
      repo = "transformers";
      rev = "refs/tags/v4.19.2";
      hash = "sha256-9r/1vW7Rhv9+Swxdzu5PTnlQlT8ofJeZamHf5X4ql8w=";
    };
  });
  stable-diffusion = args.stable-diffusion.override {
    inherit transformers;
  };
  blip = args.blip.override {
    inherit transformers;
  };
  shap = args.shap.override {
    inherit transformers;
  };
  gradio = args.gradio.override {
    inherit transformers shap;
  };
  submodel = pkg: "${pkg}/${pkg.pythonModule.sitePackages or python.sitePackages}";
in
buildPythonPackage {
  pname = "stable-diffusion-webui";
  version = "2022-10-26";

  src = fetchFromGitHub {
    owner = "AUTOMATIC1111";
    repo = "stable-diffusion-webui";
    rev = "737eb28faca8be2bb996ee0930ec77d1f7ebd939";
    sha256 = "sha256-eL6/di8lmSmZ8YFs0a9FuUZadM2TiCOerRqilmK3BfY=";
  };

  patches = [
    ./path-hacks.patch
  ];

  stable_diffusion = stable-diffusion.src;
  taming_transformers = submodel taming-transformers-rom1504;
  k_diffusion = submodel k-diffusion;
  codeformer = "${submodel codeformer}/codeformer";
  blip = "${submodel blip}/blip";

  postPatch = ''
    substituteAll $setupPath setup.py
    substituteInPlace requirements.txt \
      --replace "opencv-python" "opencv" \
      --replace "timm==0.4.12" "timm" \
      --replace "fairscale==0.4.4" "fairscale" \
      --replace "diffusers" "" \
      --replace "invisible-watermark" ""

    mkdir repositories
    ln -s $stable_diffusion repositories/stable-diffusion
    substituteAllInPlace modules/paths.py
    mkdir -p models/{hypernetworks,Codeformer,ESRGAN,facelib/weights,GFPGAN,LDSR,SwinIR}

    for script_file in launch.py webui.py scripts/*.py; do
      sed -i '1 i #!/usr/bin/env python' $script_file
    done
  '';

  dontRewriteSymlinks = true;

  inherit (python) sitePackages;
  dataPaths = [ "artists.csv" "models" "embeddings" "extensions" "textual_inversion_templates" "repositories" ];
  scriptDirs = [ "javascript" "localizations" ];
  scriptFiles = [ "style.css" "script.js" ];
  postInstall = ''
    install -d $out/lib/stable-diffusion-webui
    for data_path in $dataPaths; do
      mv $data_path $out/lib/stable-diffusion-webui/
    done
    for script_path in $scriptDirs; do
      install -d $out/lib/stable-diffusion-webui/$script_path
      lndir -silent $out/$sitePackages/$script_path $out/lib/stable-diffusion-webui/$script_path
    done
    for script_file in $scriptFiles; do
      ln -s $out/$sitePackages/$script_file $out/lib/stable-diffusion-webui/
    done
  '';

  passAsFile = [ "setup" ];
  setup = ''
    from io import open
    from glob import glob
    from setuptools import find_packages, setup

    with open('requirements.txt') as f:
      requirements = f.read().splitlines()

    setup(
      name='@pname@',
      version='@version@',
      install_requires=requirements,
      py_modules=['webui'],
      packages=['modules'] + glob('modules/*/'),
      scripts=[
        'launch.py', 'webui.py',
      ] + glob('scripts/*.py'),
      package_data = {
        'modules': [
          '../style.css',
          '../script.js',
          '../javascript/*.js',
          '../localizations/*.json',
        ],
      },
    )
  '';

  nativeBuildInputs = [
    lndir
  ];
  propagatedBuildInputs = [
    stable-diffusion
    realesrgan
    pillow
    addict
    future
    lmdb
    pyyaml
    scikitimage
    tqdm
    yapf
    gdown
    lpips
    fastapi
    lark
    analytics-python
    ffmpy
    markdown-it-py
    shap
    gradio
    fonts
    font-roboto
    piexif
    websockets
    codeformer
    blip
    deepdanbooru
    timm
    fairscale
    inflection
  ];

  doCheck = false;

  passthru = {
    overrides = {
      inherit
        transformers blip shap gradio
        stable-diffusion;
    };
  };

  meta = {
    mainProgram = "webui.py";
  };
}
