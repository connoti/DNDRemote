# DirectNorth Remote Access

DirectNorth's RustDesk installer source and TCP reachability check. Upstream software is maintained in [RustDesk](https://github.com/rustdesk/rustdesk) and [RustDesk Server](https://github.com/rustdesk/rustdesk-server).

## Check the Server

Use Python 3.10 or newer:

```sh
python3 check_ports.py rustdesk.directnorth.digital --ssh
```

This checks TCP reachability for the DirectNorth deployment and exits nonzero if a port is unreachable. Check the local RustDesk app for **Ready** and connect to a second authorized RustDesk client to verify a remote desktop session.

## Client Installers

The macOS and Windows helpers in `installers/` install the pinned upstream RustDesk client if it is absent and configure it for DirectNorth. Supply the server public key when prompted or through the `RUSTDESK_SERVER_KEY` environment variable. The helpers replace the existing `RustDesk2.toml` settings file. Back it up before running the helpers if you need to retain your settings.
