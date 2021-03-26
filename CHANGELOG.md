# Changelog
This project adheres to [Semantic Versioning](https://semver.org/).

## 1.2.4 (2021-03-26)
- Moved maintenance page in `/etc/nginx/html/maintenance`

## 1.2.3 (2021-03-25)
- Fix regressive bugs introduced in 1.2.2 release
- Revert 1.2.2 upgrade changes

## 1.2.2 (2021-03-24)
- Rename service `nginx` to `proxy` in order to use it in internal DNS
- Upgrade command now shuts down container and recreate it after upgrade

## 1.2.1 (2021-02-24)
- New `version` controller command to print
- Improve upgrade command
- Improve and complete help command

## 1.2.0 (2021-02-06)
- Merged `maintenance` and `online` controller commands to `maintenance on|off`
- Fixed bugs in maintenance command

## 1.1.0 (2021-01-16)
- Many improvements in proxy controller
- Use certbot embedded distribution package
