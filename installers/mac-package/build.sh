#!/bin/bash
set -euo pipefail
umask 077

if [[ $# -lt 3 || $# -gt 4 ]]; then
  echo "Usage: $0 DMG_DIRECTORY SERVER_PUBLIC_KEY_FILE OUTPUT.pkg [both|intel|apple-silicon]" >&2
  exit 2
fi

source_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
dmg_dir="$1"
key="$(/bin/cat "$2")"
output="$3"
variant="${4:-both}"
version=1.5.3
identity="${DIRECTNORTH_INSTALLER_IDENTITY:-}"
notary_profile="${DIRECTNORTH_NOTARY_PROFILE:-}"
if [[ "$output" != *.pkg || ! "$key" =~ ^[A-Za-z0-9+/]{43}=$ ]]; then
  echo 'Provide a .pkg destination and a RustDesk server public key file.' >&2
  exit 2
fi
if [[ -n "$notary_profile" && -z "$identity" ]]; then
  echo 'Notarization requires a Developer ID Installer identity.' >&2
  exit 2
fi
case "$variant" in
  both|intel|apple-silicon) ;;
  *) echo "Unknown Mac package variant: $variant" >&2; exit 2 ;;
esac

scratch="$(mktemp -d "${TMPDIR:-/tmp}/directnorth-pkg.XXXXXX")"
mount_point="$scratch/mount"
mounted=false
cleanup() {
  if $mounted && ! /usr/bin/hdiutil detach "$mount_point" -quiet; then
    echo "Could not detach $mount_point. Leaving the build directory in place." >&2
    return
  fi
  /bin/rm -rf -- "$scratch"
}
trap cleanup EXIT
/bin/mkdir -p "$mount_point" "$scratch/scripts"
for script in preinstall postinstall configure-user.sh; do
  /usr/bin/install -m 755 "$source_dir/$script" "$scratch/scripts/$script"
done
printf '%s\n' "$key" > "$scratch/scripts/server-key"

build_component() {
  local arch="$1" asset="$2" expected_sha="$3"
  local dmg="$dmg_dir/rustdesk-$version-$asset.dmg"
  local root="$scratch/root-$arch"
  local app="$root/RustDesk.app"
  local digest executable
  digest="$(/usr/bin/shasum -a 256 "$dmg")"
  if [[ "${digest%% *}" != "$expected_sha" ]]; then
    echo "SHA-256 mismatch: $dmg" >&2
    exit 1
  fi
  /usr/bin/hdiutil attach "$dmg" -readonly -nobrowse -mountpoint "$mount_point" -quiet
  mounted=true
  /bin/mkdir "$root"
  /usr/bin/ditto "$mount_point/RustDesk.app" "$app"
  /usr/bin/hdiutil detach "$mount_point" -quiet
  mounted=false
  /usr/bin/codesign --verify --deep --strict "$app"
  executable="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$app/Contents/Info.plist")"
  /usr/bin/lipo "$app/Contents/MacOS/$executable" -verify_arch "$arch"
  /usr/bin/pkgbuild --root "$root" --component-plist "$source_dir/components.plist" \
    --install-location /Applications --ownership recommended \
    --identifier "digital.directnorth.remoteaccess.rustdesk.$arch" --version "$version" \
    --scripts "$scratch/scripts" "$scratch/rustdesk-$arch.pkg"
}

if [[ "$variant" != intel ]]; then
  build_component arm64 aarch64 e6d30fa1633d772c48935907c208ca4e555a856fb2038af3aaa87a327c29360b
fi
if [[ "$variant" != apple-silicon ]]; then
  build_component x86_64 x86_64 74d06e6b2e273a128e8d36313e30d47db2063f453a4235ed4d9e5cdfdf9be538
fi

distribution="$source_dir/Distribution.xml"
if [[ "$variant" != both ]]; then
  arch=arm64
  label="Apple silicon"
  if [[ "$variant" == intel ]]; then
    arch=x86_64
    label="Intel"
  fi
  distribution="$scratch/Distribution.xml"
  /bin/cat > "$distribution" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
  <title>DirectNorth Remote Access for Mac ($label)</title>
  <options customize="never" hostArchitectures="$arch" require-scripts="false"/>
  <domains enable_anywhere="false" enable_currentUserHome="false" enable_localSystem="true"/>
  <choices-outline><line choice="rustdesk"/></choices-outline>
  <choice id="rustdesk" visible="false" selected="true">
    <pkg-ref id="digital.directnorth.remoteaccess.rustdesk.$arch"/>
  </choice>
  <pkg-ref id="digital.directnorth.remoteaccess.rustdesk.$arch">rustdesk-$arch.pkg</pkg-ref>
</installer-gui-script>
EOF
fi
package="$scratch/DirectNorth Remote Access.pkg"
build=(/usr/bin/productbuild --distribution "$distribution" --package-path "$scratch")
if [[ -n "$identity" ]]; then build+=(--sign "$identity"); fi
"${build[@]}" "$package"
if [[ -n "$notary_profile" ]]; then
  /usr/bin/xcrun notarytool submit "$package" --keychain-profile "$notary_profile" --wait
  /usr/bin/xcrun stapler staple "$package"
  /usr/sbin/spctl --assess --type install "$package"
fi
/bin/cp "$package" "$output"
