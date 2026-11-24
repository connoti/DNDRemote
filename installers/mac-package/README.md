# DirectNorth Remote Access Mac Package

This package installs RustDesk 1.5.3 in Applications. It contains the original RustDesk app bundles for Apple silicon and Intel. Installer picks the bundle that matches the Mac. The package applies the DirectNorth server settings for the user signed in at the Mac desktop. If settings change, it saves the previous settings file beside the new one.

## Build on macOS

1. Download `rustdesk-1.5.3-aarch64.dmg` and `rustdesk-1.5.3-x86_64.dmg` from the [official release](https://github.com/rustdesk/rustdesk/releases/tag/1.5.3) into the same directory.
2. Use a file containing the DirectNorth RustDesk server public key only. Keep the file outside the source repository. The builder verifies the disk image hashes and the app signatures before creating the package.
3. From the repository root, run:

```sh
bash installers/mac-package/build.sh \
  /path/to/upstream-dmgs /path/to/server-public-key \
  "/path/to/DirectNorth Remote Access.pkg"
```

Without a signing identity this creates an unsigned pilot for controlled testing. To build a package for distribution, set `DIRECTNORTH_INSTALLER_IDENTITY` to the Developer ID Installer certificate identity and `DIRECTNORTH_NOTARY_PROFILE` to an existing `notarytool` keychain profile. With both set, the builder signs, notarizes, staples, and assesses the package. Before public distribution, include the [RustDesk license and corresponding upstream source](https://github.com/rustdesk/rustdesk/tree/1.5.3) with the release.

To make separate downloads, pass `intel` or `apple-silicon` as the fourth argument to the builder. Each package includes just the matching app. Use these labels on the download page:

- **Download for Mac (Apple silicon)** for Macs with an Apple M-series chip.
- **Download for Mac (Intel)** for Macs with an Intel processor.

Readers can check **Apple menu → About This Mac** if they are unsure.

## Pilot on a Second Mac

1. Sign into the Mac, quit RustDesk if it is running, and open the package in Finder. Install to the startup disk.
2. Open **RustDesk** from Applications. Under **Settings → Network**, verify **ID Server** is `remote.directnorth.digital`. Confirm green **Ready**.
3. Connect from the test Mac to the first Mac. Confirm that you can see its screen and move its pointer, then disconnect. If needed, grant **Screen Recording** and **Accessibility** on the Mac receiving the connection.

Keep the live download in place until a signed and notarized candidate passes the same test on a fresh Mac.
