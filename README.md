## (inofficial) [droplan][droplan] docker image

This is an autobuild-enabled docker image for tam7t's [droplan][droplan] utility for [DigitalOcean][digitalocean].  
It automagically isolates your DigitalOcean droplets from other people's droplets in the same datacenter.

Each time `droplan` runs (default interval: 5 minutes), it'll get a list of droplets in the current datacenter
(and filters them by `$DO_TAG` if specified) and configures the firewall to prevent all incoming traffic
from anywhere but your droplets' IPs.

`droplan` affects new incoming connections

This prevents malicious droplets to access your internal services.

### Example usage:

```sh
docker run -d --restart=always --net=host --cap-add=NET_ADMIN -e DO_KEY=$your_digitalocean_api_key mreithub/droplan
```

- `-d --restart=always` starts the container in the background and restarts it on error
- `--net=host` is required because we want to affect the host's firewall rules, not the container's
- `--cap-add=NET_ADMIN` is needed to modify firewall rules
- specify your DigitalOcean API key (using `-e DO_KEY`)
- add `-e DO_INTERVAL=123` to run droplan every `123` seconds (default: `300`)
- add `-e DO_TAG=tagname` to restrict access to droplets having a certain tag
- add `-e PUBLIC=true` to also isolate the droplet's public interface  
  **WARNING**: This will block incoming `ssh` connections and could potentially lock you out of your droplet  
  Your current connection will remain open, but new ones will get blocked. You can still use DigitalOcean's
  'access droplet' feature (if you've set up a user account with a password) or ssh into it from your other
  droplets.

### Example `docker-compose.yml`

```yaml
  droplan:
    image: mreithub/droplan
    network_mode: host
    restart: always
    cap_add:
      - NET_ADMIN
    environment:
      DO_KEY: ${your-digitalocean-api-key}
      DO_TAG: someTag
      PUBLIC: "true"
```


### How `droplan` configures the firewall

`droplan` will add the following rules to your `INPUT` table (I've added some comments to explain what these rules do)

```sh
# jump to 'droplan-peers' (see below)
iptables -A INPUT -i eth1 -j droplan-peers
# ALLOW existing connections (i.e. only affect new, incoming connections)
iptables -A INPUT -i eth1 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
# DROP all incoming traffic that didn't match above rules
iptables -A INPUT -i eth1 -j DROP
```

`-i eth1` means it'll only affect *incoming* traffic on the *private* network interface.

`droplan-peers` rules look like this (added comments again)

```sh
# accept all traffic from 10.1.2.3 (there's gonna be one entry for each of your droplets' internal IP)
iptables -A droplan-peers -s 10.1.2.3/32 -j ACCEPT
```

### Troubleshooting

- To immediately 'scan' for new droplets (i.e. avoid having to wait `DO_INTERVAL` seconds, just restart the container: `docker restart droplan`)
- If there's an error reaching DigitalOcean's API servers, the existing `iptables` firewall rules are left unchanged.
- This image restarts `droplan` automatically on error. If the first invocation fails however, it'll exit with the specified error code.  
  This makes sure `DO_INTERVAL` is honored even in case of errors (and somewhat protects you from misconfiguration)
- For a simple way to reach your internal servers (the ones with `PUBLIC=true`), you could use [ondevice.io](https://ondevice.io).  
  It'll wrap your incoming `ssh` connections into an outgoing websocket connection (which isn't affected by `droplan`'s firewall rules).
 

[droplan]: https://hub.docker.com/r/tam7t/droplan/
[digitalocean]: https://digitalocean.com/
