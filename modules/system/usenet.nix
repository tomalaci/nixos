# Usenet downloader and indexer proxy.
{...}: {
  services.nzbget = {
    enable = true;
    user = "tomalaci";
    group = "users";
  };
  services.nzbhydra2.enable = true;
}
