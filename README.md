# Nginx proxy for docker containers

When running multiples web containers on a same machine, you must set a reverse proxy.
This project aims to configure a simple nginx proxy.

# First build and run
1. Copy `env.example` file to `.env` and customize it if you want.
2. Copy `docker-compose.example.yml` file to `docker-compose.yml` and customize it if you want.
3. Run `./proxy_ctl.sh up`

# SSL certificates
Auto-signed certificate will be created inside `volumes/certs` but if you want to use
your custom certificate, create the following files:
`volumes/certs/default.crt` and `volumes/certs/default.key`

Be sure to protect correctly these files with good permissions.

# Configuration for your containers
Add nginx config files inside `volumes/nginx/conf`.

# Connect your containers to the proxy
## with docker compose
In your `docker-compose.yml` files, disable exposing ports 80 & 443 and append:
```yaml
services:
  my-web-service:
    ...
    networks:
      - proxy
...
networks:
  proxy:
    external: true
```
Note: If you changed `PROXY_NETWORK` in the env file, change `proxy` by this value.

## with docker commands
Append to your command:
```bash
docker run ... --network proxy ...
```
Note: If you changed `PROXY_NETWORK` in the env file, change `proxy` by this value.

# Proxy behaviour
In case there is an error in one of your config files (e.g. container unreachable):
## proxy started
You have to run `./proxy_ctl.sh reload` to reload config. If it fails, it will not reload (safe in production environment).

## proxy restarted
At the first run or if the proxy container must restart, it will rename your bad config files with `.disabled` suffix.

You will have to fix the config file (or maybe it's because a container is not reachable), then reload config with `--force` option to re-enable it.

When proxy container restarts, if there are `.disabled` files, it will test them and if config is fixed, it will automatically rename and enable them.

# Customizations
By default, if nothing is found, nginx will return the 503 error code (site in maintenance).

You can create your own maintenance page in `volumes/nginx/html/maintenance/index.html`

# Upgrade
Run `proxy_ctl upgrade` to upgrade proxy.

If you don't have git on the host, you can also manually copy the sources, then run `proxy_ctl build` and `proxy_ctl up`.

# License
This project is licensed under the MIT License. See [LICENSE.md](LICENSE.md) for the full license text.

# Credits
Author: Jean Prunneaux https://jean.prunneaux.com

Website: https://github.com/pruje/docker-proxy-nginx
