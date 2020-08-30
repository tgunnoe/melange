final: prev: {
  slock = prev.slock.overrideAttrs (o: {
    pname = "slock";
    patches = [ ../pkgs/misc/screensavers/slock/window_name.patch ];
  });
}
