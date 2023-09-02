{config, ...}: {
  # The Uputronics GPS HAT sends garbage (well, NMEA 0183 data, but to U-Boot
  # it's garbage) over the serial console, which interrupts boot. Unfortunately
  # the only way to deal with this is to completely disable input and output for
  # both the serial console and the HDMI display.
  # See https://stackoverflow.com/a/40367443
  iliana.hardware.ubootOverrides = {
    extraConfig = ''
      CONFIG_BOARD_EARLY_INIT_F=y
      CONFIG_BOOTDELAY=-2
      CONFIG_DISABLE_CONSOLE=y
      CONFIG_SILENT_CONSOLE=y
      CONFIG_SYS_DEVICE_NULLDEV=y
    '';
    extraPatches = [./u-boot-no-uart.patch];
  };

  hardware.deviceTree.overlays = [
    {
      name = "pps-gpio";
      dtsFile = ./pps-gpio-overlay.dts;
    }
  ];

  services.chrony.extraConfig = ''
    allow 100.64.0.0/10
    refclock PPS /dev/pps0 prefer
    refclock SHM 0 refid NMEA noselect
  '';

  services.gpsd.enable = true;
  services.gpsd.devices = ["/dev/ttyS1"];
  services.gpsd.nowait = true;

  iliana.tailscale.policy.acls = [
    {
      action = "accept";
      src = ["*"];
      proto = "udp";
      dst = ["${config.networking.hostName}:123"];
    }
  ];
}
