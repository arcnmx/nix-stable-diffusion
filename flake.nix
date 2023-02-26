{
  description = "A very basic flake";

  inputs = {
    nixlib.url = "github:nix-community/nixpkgs.lib";
    nixpkgs = {
      url = "github:NixOS/nixpkgs?rev=fd54651f5ffb4a36e8463e0c327a78442b26cbe7";
    };
    nixpkgs-tensorflow = {
      url = "github:NixOS/nixpkgs?rev=dcc26b62da6963053c299af3e19b89b94924edec";
    };
  };
  outputs = { self, nixpkgs, nixlib, ... }@inputs:
    let
      nixlib = inputs.nixlib.outputs.lib;
      supportedSystems = [ "x86_64-linux" ];
      forAll = nixlib.genAttrs supportedSystems;
      relaxDeps = deps: python3Packages: old: {
        nativeBuildInputs = old.nativeBuildInputs ++ [ python3Packages.pythonRelaxDepsHook ];
        pythonRelaxDeps = old.pythonRelaxDeps or [ ] ++ nixlib.toList deps;
      };
      relaxProtobuf = relaxDeps "protobuf";
      inherit (nixlib) optional;
      nixpkgs__ = system: { amd ? false, nvidia ? false }:
        import inputs.nixpkgs {
          inherit system;
          config = {
            allowUnfree = nvidia; #CUDA is unfree.
          };
          overlays = [
            self.overlays.default
          ] ++ optional amd self.overlays.amd
          ++ optional nvidia self.overlays.nvidia;
        };
    in
    {
      pythonOverlays =
        {
          default = final: super:
            {
              pytorch-lightning = super.pytorch-lightning.overrideAttrs (relaxProtobuf final);
              wandb = super.wandb.overrideAttrs (relaxProtobuf final);
              scikit-image = final.scikitimage;
              streamlit = super.pkgs.streamlit.overrideAttrs (relaxProtobuf final);
            };
          bin = final: super:
            {
              torch = final.torch-bin;
              torchvision = final.torchvision-bin;
              tensorflow = final.tensorflow-bin;
              tensorflow-io = final.tensorflow-io-bin;
            };
          nvidia = final: super:
            {
              tensorflow-bin = let
                #tensorflow-bin = super.tensorflow-bin.override { cudaSupport = true; };
                tensorflow-bin = final.callPackage (inputs.nixpkgs-tensorflow.outPath + "/pkgs/development/python-modules/tensorflow/bin.nix") {
                  cudaSupport = true;
                };
              in tensorflow-bin.overrideAttrs (old: rec {
                version = "2.11.0";
                src = final.pkgs.fetchurl {
                  url = "https://storage.googleapis.com/tensorflow/linux/cpu/tensorflow_cpu-${version}-cp310-cp310-manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
                  sha256 = "sha256-sxhCkhk5Ky5z9yCZ21uSz9UWFxweEOTvN7D1MWb2J9o=";
                };
              });
            };
          amd = final: super:
            {
              torch-bin = super.torch-bin.overrideAttrs (old: {
                src = final.pkgs.fetchurl {
                  name = "torch-1.12.1+rocm5.1.1-cp310-cp310-linux_x86_64.whl";
                  url = "https://download.pytorch.org/whl/rocm5.1.1/torch-1.12.1%2Brocm5.1.1-cp310-cp310-linux_x86_64.whl";
                  hash = "sha256-kNShDx88BZjRQhWgnsaJAT8hXnStVMU1ugPNMEJcgnA=";
                };
              });
              torchvision-bin = super.torchvision-bin.overrideAttrs (old: {
                src = final.pkgs.fetchurl {
                  name = "torchvision-0.13.1+rocm5.1.1-cp310-cp310-linux_x86_64.whl";
                  url = "https://download.pytorch.org/whl/rocm5.1.1/torchvision-0.13.1%2Brocm5.1.1-cp310-cp310-linux_x86_64.whl";
                  hash = "sha256-mYk4+XNXU6rjpgWfKUDq+5fH/HNPQ5wkEtAgJUDN/Jg=";
                };
              });
              #overriding because of https://github.com/NixOS/nixpkgs/issues/196653
              opencv4 = super.opencv4.override { openblas = final.pkgs.blas; };
            };
          pynixify = final: super:
            let
              rm = d: d.overrideAttrs (old: {
                nativeBuildInputs = old.nativeBuildInputs ++ [ final.pythonRelaxDepsHook ];
                pythonRemoveDeps = [ "opencv-python-headless" "opencv-python" "tb-nightly" "clip" ];
              });
              inherit (final) callPackage;
              rmCallPackage = path: args: rm (callPackage path args);
            in
            {
              stable-diffusion-webui = final.callPackage ./packages/stable-diffusion-webui { };
              invokeai = final.callPackage ./packages/invokeai { };
              stable-diffusion = final.callPackage ./packages/stable-diffusion { };

              opencv-python = final.opencv4;
              opencv-python-headless = final.opencv-python;

              pydeprecate = callPackage ./packages/pydeprecate { };
              taming-transformers-rom1504 =
                callPackage ./packages/taming-transformers-rom1504 { };
              albumentations = rmCallPackage ./packages/albumentations { };
              qudida = rmCallPackage ./packages/qudida { };
              gfpgan = rmCallPackage ./packages/gfpgan { };
              basicsr = rmCallPackage ./packages/basicsr { };
              facexlib = rmCallPackage ./packages/facexlib { };
              realesrgan = rmCallPackage ./packages/realesrgan { };
              codeformer = callPackage ./packages/codeformer { };
              clipseg = rmCallPackage ./packages/clipseg { };
              filterpy = callPackage ./packages/filterpy { };
              kornia = callPackage ./packages/kornia { };
              lpips = callPackage ./packages/lpips { };
              ffmpy = callPackage ./packages/ffmpy { };
              shap = callPackage ./packages/shap { };
              fonts = callPackage ./packages/fonts { };
              font-roboto = callPackage ./packages/font-roboto { };
              analytics-python = callPackage ./packages/analytics-python { };
              markdown-it-py = callPackage ./packages/markdown-it-py { };
              gradio = callPackage ./packages/gradio { };
              hatch-requirements-txt = callPackage ./packages/hatch-requirements-txt { };
              timm = callPackage ./packages/timm { };
              blip = callPackage ./packages/blip { };
              fairscale = callPackage ./packages/fairscale { };
              torch-fidelity = callPackage ./packages/torch-fidelity { };
              resize-right = callPackage ./packages/resize-right { };
              torchdiffeq = callPackage ./packages/torchdiffeq { };
              k-diffusion = callPackage ./packages/k-diffusion { };
              accelerate = callPackage ./packages/accelerate { };
              clip-anytorch = callPackage ./packages/clip-anytorch { };
              jsonmerge = callPackage ./packages/jsonmerge { };
              clean-fid = callPackage ./packages/clean-fid { };
              getpass-asterisk = callPackage ./packages/getpass-asterisk { };

              deepdanbooru = callPackage ./packages/deepdanbooru { };
              sentence-transformers = callPackage ./packages/sentence-transformers { };
              tensorflow-io = callPackage ./packages/tensorflow-io { };
              tensorflow-io-bin = callPackage ./packages/tensorflow-io-bin { };
            };
        };
      overlays =
        {
          default = final: prev:
            {
              pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
                self.pythonOverlays.default
                self.pythonOverlays.pynixify
              ];
              stable-diffusion-webui = final.python3Packages.toPythonApplication
                final.python3Packages.stable-diffusion-webui;
              invokeai = final.python3Packages.toPythonApplication
                final.python3Packages.invokeai;
            };
          nvidia = final: prev:
            {
              pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
                self.pythonOverlays.nvidia
                self.pythonOverlays.bin
              ];
            };
          amd = final: prev:
            rec {
              pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
                self.pythonOverlays.amd
                self.pythonOverlays.bin
              ];
            };
        };
      legacyPackages = forAll (system: {
        nvidia = nixlib.recurseIntoAttrs {
          inherit (nixpkgs__ system { nvidia = true; })
            stable-diffusion-webui invokeai
            pkgs;
        };
        amd = nixlib.recurseIntoAttrs {
          inherit (nixpkgs__ system { amd = true; })
            stable-diffusion-webui invokeai
            pkgs;
        };
        pkgs = nixpkgs__ system { };
      });
      packages = forAll
        (system: with self.legacyPackages.${system};
          {
            stable-diffusion-webui = pkgs.stable-diffusion-webui //
              {
                nvidia = nvidia.stable-diffusion-webui;
                amd = amd.stable-diffusion-webui;
              };
            invokeai = pkgs.invokeai //
              {
                nvidia = nvidia.invokeai;
                amd = amd.invokeai;
              };
            default = amd.invokeai;
          });
      devShells = forAll
        (system: with self.legacyPackages.${system};
          let
            mkShell = inputs.nixpkgs.legacyPackages.${system}.mkShell;
          in
          rec {
            invokeai =
              let
                shellHookFor = packages: ''
                '';
              in
              {
                default = mkShell
                  ({
                    shellHook = shellHookFor pkgs;
                    name = "invokeai";
                    nativeBuildInputs = [ pkgs.invokeai ];
                    inherit (pkgs.invokeai) propagatedBuildInputs;
                  });
                amd = mkShell
                  ({
                    shellHook = shellHookFor amd;
                    name = "invokeai.amd";
                    nativeBuildInputs = [ amd.invokeai ];
                    inherit (amd.invokeai) propagatedBuildInputs;
                  });
                nvidia = mkShell
                  ({
                    shellHook = shellHookFor nvidia;
                    name = "invokeai.nvidia";
                    nativeBuildInputs = [ amd.invokeai ];
                    inherit (nvidia.invokeai) propagatedBuildInputs;
                  });
              };
            webui =
              let
                shellHookFor = packages:
                  ''
                    if [[ -z ''${SD_WEBUI_SCRIPT_PATH-} ]]; then
                      export SD_WEBUI_SCRIPT_PATH=$PWD/webui
                    fi
                    if [[ -d $SD_WEBUI_SCRIPT_PATH ]]; then
                      ${nixlib.getExe packages.pkgs.findutils} "$SD_WEBUI_SCRIPT_PATH" \
                        -type l -lname '${builtins.storeDir}/*-${packages.stable-diffusion-webui.pname}-*/*' -delete
                    fi
                    mkdir -p "$SD_WEBUI_SCRIPT_PATH"
                    cp -nr --no-preserve=mode ${packages.stable-diffusion-webui}/lib/stable-diffusion-webui/* "$SD_WEBUI_SCRIPT_PATH/"
                    cd "$SD_WEBUI_SCRIPT_PATH"
                  '';
              in
              {
                default = mkShell
                  (
                    {
                      shellHook = shellHookFor pkgs;
                      name = "webui";
                      nativeBuildInputs = [ pkgs.stable-diffusion-webui ];
                      inherit (pkgs.stable-diffusion-webui) propagatedBuildInputs;
                    }
                  );
                amd = mkShell
                  (
                    {
                      shellHook = shellHookFor amd;
                      name = "webui.amd";
                      nativeBuildInputs = [ amd.stable-diffusion-webui ];
                      inherit (amd.stable-diffusion-webui) propagatedBuildInputs;
                    }
                  );
                nvidia = mkShell
                  (
                    {
                      shellHook = shellHookFor nvidia;
                      name = "webui.nvidia";
                      nativeBuildInputs = [ nvidia.stable-diffusion-webui ];
                      inherit (nvidia.stable-diffusion-webui) propagatedBuildInputs;
                    }
                  );
              };
            default = amd.invokeai;
          });
    };
}
