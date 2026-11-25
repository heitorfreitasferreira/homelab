# A RackNerd nao tem DHCP: endereco, mascara e gateway fixos, casados pelo MAC da placa.
{
  networking.useDHCP = false;
  networking.useNetworkd = true;

  systemd.network.networks."10-wan" = {
    matchConfig.MACAddress = "00:16:3c:2f:d4:d8";
    address = [ "23.254.208.229/26" ];
    routes = [ { Gateway = "23.254.208.193"; } ];
    linkConfig.RequiredForOnline = "routable";
  };

  networking.nameservers = [
    "1.1.1.1"
    "9.9.9.9"
  ];

  # Publico: SSH e as entradas HTTPS do Caddy. O resto so pela tailnet.
  networking.firewall.allowedTCPPorts = [
    22
    80
    443
  ];
}
