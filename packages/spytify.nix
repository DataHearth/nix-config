{
  lib,
  buildGoModule,
  fetchFromGitHub,
  pkg-config,
  makeWrapper,
  installShellFiles,
  libGL,
  libx11,
  libxcursor,
  libxi,
  libxinerama,
  libxrandr,
  libxxf86vm,
  libxkbcommon,
  wayland,
  ffmpeg-headless,
  pipewire,
}:

buildGoModule (finalAttrs: {
  pname = "spytify";
  version = "2.0.0-alpha.7";

  src = fetchFromGitHub {
    owner = "spytify";
    repo = "spytify";
    tag = finalAttrs.version;
    hash = "sha256-1ZO7KsLv2ZibDY/SS19tVr4/jiMaiq4I9lai0msibEQ=";
  };

  vendorHash = "sha256-gAkyij3F2x8hVBU2NvJmgBRMZn0dO7Rm5y2P9k7MBMQ=";

  subPackages = [
    "cmd/spytifyd"
    "cmd/spytify-cli"
    "cmd/spytify-ui"
  ];

  # No telemetry.DSN: upstream's builds bake their Sentry project in; without
  # one nothing is ever sent and the privacy switch is hidden.
  ldflags = [
    "-s"
    "-w"
    "-X github.com/spytify/spytify/pkg/proto.Version=v${finalAttrs.version}"
  ];

  # Spotify on Linux emits an MPRIS Seeked every 5 minutes restating its
  # position ~2 s behind Spytify's wall clock, right at the 2 s slack, so
  # whole tracks get dropped as "track bar moved" though the audio is
  # continuous. Drop once upstream widens the slack or filters these
  # restatements; --replace-fail breaks the build when the line changes.
  #
  # completeToleranceMs: on albums whose tracks run into each other there is
  # no quiet point at the real change, so a cut can land ~2 s late; the next
  # take then comes out 2-3 s short of its declared length and is dropped as
  # "incomplete", its audio gone once the following track saves.
  postPatch = ''
    substituteInPlace internal/meta/jxa.go \
      --replace-fail "seekSlackMs = 2000" "seekSlackMs = 5000"
    substituteInPlace internal/core/finisher.go \
      --replace-fail "completeToleranceMs = 2000" "completeToleranceMs = 3000"
  '';

  nativeBuildInputs = [
    pkg-config
    makeWrapper
    installShellFiles
  ];

  buildInputs = [
    libGL
    libx11
    libxcursor
    libxi
    libxinerama
    libxrandr
    libxxf86vm
    libxkbcommon
    wayland
  ];

  postInstall = ''
    install -Dm444 packaging/linux/org.spytify.ui.desktop -t $out/share/applications
    install -Dm444 assets/logo.png $out/share/icons/hicolor/128x128/apps/spytify.png
    install -Dm444 assets/logo256px.png $out/share/icons/hicolor/256x256/apps/spytify.png
    installShellCompletion --cmd spytify-cli \
      --bash <($out/bin/spytify-cli completion bash) \
      --fish <($out/bin/spytify-cli completion fish) \
      --zsh <($out/bin/spytify-cli completion zsh)
  '';

  # --suffix: the system's own pw-* tools win, so they match the running
  # PipeWire daemon.
  #
  # FYNE_PLATFORM: with both GLFW backends built in, Fyne drops to XWayland
  # whenever DISPLAY is set and it decides the compositor lacks server-side
  # decorations, and XWayland is bitmap-upscaled (blurry) under fractional
  # scaling. Native Wayland renders at the fractional scale.
  postFixup = ''
    for b in $out/bin/*; do
      wrapProgram "$b" \
        --set-default SPYTIFY_FFMPEG ${lib.getExe' ffmpeg-headless "ffmpeg"} \
        --set-default FYNE_PLATFORM wayland \
        --suffix PATH : ${lib.makeBinPath [ pipewire ]}
    done
  '';

  meta = {
    description = "Records an application's audio, splits it into tracks and tags them";
    homepage = "https://github.com/spytify/spytify";
    license = lib.licenses.mit;
    mainProgram = "spytify-ui";
    platforms = lib.platforms.linux;
  };
})
