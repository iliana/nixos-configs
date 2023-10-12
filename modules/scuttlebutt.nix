{...}: {
  services.syncthing.enable = true;
  services.syncthing.folders."/media/z/scuttlebutt" = {
    id = "fystg-75vui";
    label = "scuttlebutt";
    devices = ["tartarus"];
    rescanInterval = 21600;
    type = "sendonly";
  };
}
