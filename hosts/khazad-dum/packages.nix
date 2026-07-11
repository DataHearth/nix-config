{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    qt5.qtwayland
    qt6.qtwayland

    doggo
    sbctl
    procs
    duf
  ];

  programs = {
    steam = {
      enable = true;

      # GE-Proton carries extra media codecs and per-title patches that Valve's
      # Proton lacks. Installing it only makes it selectable — pick it per game
      # under Properties > Compatibility.
      extraCompatPackages = [ pkgs.proton-ge-bin ];
    };

    # DP-4 (4K AOC) runs at scale 2.0, so the compositor only advertises a
    # logical 1920x1080 to XWayland — Proton games enumerate modes from there
    # and never offer 3840x2160. gamescope nests its own virtual display, so
    # per-game launch options can request 4K without touching desktop scaling:
    #   gamescope -W 3840 -H 2160 -f -- %command%
    gamescope = {
      enable = true;

      # MUST stay false. With the capability wrapper in place, gamescope tries
      # to propagate cap_sys_nice to its children; inside the Steam FHS user
      # namespace that raise is denied, so every game dies on launch with
      # "failed to inherit capabilities: Operation not permitted" (exit 1).
      # Costs only renice priority. See NixOS/nixpkgs#351516.
      capSysNice = false;
    };

    # CPU governor, scheduling and IO priority tweaks for the duration of a
    # game. Worth more than usual here: this host is iGPU-only (Radeon 780M),
    # so the CPU and GPU contend for the same power budget.
    gamemode.enable = true;
  };
}
