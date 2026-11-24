#!/bin/bash
set -euo pipefail
umask 077

server=remote.directnorth.digital
key=${1:?A RustDesk server public key is required}
if [[ ! "$key" =~ ^[A-Za-z0-9+/]{43}=$ ]]; then
  echo 'Invalid RustDesk server public key.' >&2
  exit 1
fi

directory="$HOME/Library/Preferences/com.carriez.RustDesk"
config="$directory/RustDesk2.toml"
mkdir -p -- "$directory"
if [[ -L "$config" || ( -e "$config" && ! -f "$config" ) ]]; then
  echo 'RustDesk settings must be a regular file.' >&2
  exit 1
fi

staged="$(mktemp "$directory/.DirectNorth.XXXXXX")"
trap 'rm -f -- "$staged"' EXIT
input=/dev/null
if [[ -f "$config" ]]; then input="$config"; fi

/usr/bin/awk -v server="$server" -v key="$key" '
  BEGIN { print "rendezvous_server = \"" server ":21116\"" }
  /^[[:space:]]*\[/ {
    in_table = 1
    in_options = ($0 ~ /^[[:space:]]*\[options\][[:space:]]*(#.*)?$/)
    print
    if (in_options) {
      emit_options()
      have_options = 1
    }
    next
  }
  !in_table && /^[[:space:]]*rendezvous_server[[:space:]]*=/ { next }
  in_options && /^[[:space:]]*(custom-rendezvous-server|relay-server|api-server|key)[[:space:]]*=/ { next }
  { print }
  END {
    if (!have_options) {
      print "\n[options]"
      emit_options()
    }
  }
  function emit_options() {
    print "custom-rendezvous-server = \"" server "\""
    print "key = \"" key "\""
  }
' "$input" > "$staged"

if [[ -f "$config" ]]; then
  if /usr/bin/cmp -s "$config" "$staged"; then exit 0; fi
  backup="$(mktemp "$directory/RustDesk2.pre-DirectNorth.XXXXXX")"
  /bin/cat "$config" > "$backup"
fi
mv -f -- "$staged" "$config"
