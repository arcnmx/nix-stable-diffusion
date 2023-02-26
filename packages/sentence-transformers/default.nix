{ buildPythonPackage
, fetchPypi
, transformers
, tokenizers
, tqdm
, torch
, torchvision
, numpy
, scikit-learn
, scipy
, nltk
, sentencepiece
, huggingface-hub
}: buildPythonPackage rec {
  pname = "sentence-transformers";
  version = "2.2.2";
  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-28YBY7J94hB2yaMNJLW3tvoFFB1ozyVT+pp3v3mikTY=";
  };
  propagatedBuildInputs = [
    transformers tokenizers tqdm torch
    torchvision numpy scikit-learn scipy nltk
    sentencepiece huggingface-hub
  ];
  doCheck = false;
}
