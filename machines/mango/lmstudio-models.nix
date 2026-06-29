{ lib, config, ... }:
let
  # Pull the GGUF store paths back out of the running llama-swap config so we
  # share one fetch across both services. Upstream's cmd template is
  # `${llama-server} -m ${gguf} --port ${PORT} [extras]`, so the token after
  # `-m` is the model file. Refetching with our own url+sha256 would silently
  # duplicate downloads (and diverge) the moment spaces-os bumps a hash.
  ggufOf =
    cmd:
    let
      m = builtins.match ".* -m ([^ ]+).*" cmd;
    in
    if m == null then throw "lmstudio-models: no -m argument in cmd: ${cmd}" else builtins.head m;

  # Drop the leading `<32-char-hash>-` from a nix store basename so LM Studio
  # shows the model's real filename in its picker.
  stripHash = name: builtins.substring 33 (builtins.stringLength name - 33) name;

  # Sanitize `:` (legal in Linux paths, awkward in LM Studio's UI) into `-`.
  sanitize = lib.replaceStrings [ ":" ] [ "-" ];

  # Only store-pinned models (cmd carries `-m <store-path>`) can be shared with
  # LM Studio. Lazily-downloaded `-hf` models have no store path at eval time —
  # their GGUF only lands in llama.cpp's cache on first use — so skip them here.
  storeModels = lib.filterAttrs (
    _: m: builtins.match ".* -m ([^ ]+).*" m.cmd != null
  ) config.services.llama-swap.settings.models;

  modelLinks = lib.mapAttrs' (id: m: {
    # Layout: ~/.lmstudio/models/llama-swap/<model-id>/<file>.gguf
    # The author/repo level is arbitrary as far as LM Studio is concerned —
    # it scans recursively. Bucketing everything under `llama-swap/` makes
    # the source obvious in LM Studio's model list.
    name = ".lmstudio/models/llama-swap/${sanitize id}/${stripHash (baseNameOf (ggufOf m.cmd))}";
    value.source = ggufOf m.cmd;
  }) storeModels;
in
{
  # LM Studio scans ~/.lmstudio/models recursively. Only the leaf is a
  # symlink into the nix store; the parent dirs are real, so LM Studio can
  # still drop its own metadata sidecars next to each model.
  home-manager.users.pinpox.home.file = modelLinks;
}
