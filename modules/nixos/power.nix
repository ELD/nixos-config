{
  services.power-profiles-daemon.enable = false;

  services.tlp = {
    enable = true;
    settings = {
      # CPU policy: stronger battery saving
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      # CPU frequency governor
      CPU_SCALING_GOVERNOR_ON_AC = "schedutil";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      # Hardware/platform profile, if your laptop exposes it
      PLATFORM_PROFILE_ON_AC = "balanced";
      PLATFORM_PROFILE_ON_BAT = "power-saver";

      # Optional: reduce turbo on battery
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;

      # Optional: runtime PM
      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";
    };
  };
}
