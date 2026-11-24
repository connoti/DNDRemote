# DirectNorth Remote Access — Windows configuration helper
# Downloads the official RustDesk app, installs it, and configures it.

param([string]$ServerKey = $env:RUSTDESK_SERVER_KEY)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($ServerKey)) {
  $ServerKey = Read-Host 'Enter the DirectNorth RustDesk server public key'
}
if ($ServerKey -cnotmatch '^[A-Za-z0-9+/]{43}=$') {
  throw 'Expected a base64-encoded RustDesk server public key.'
}

$app = Join-Path $env:ProgramFiles 'RustDesk\RustDesk.exe'
if (!(Test-Path $app)) {
  $installer = Join-Path $env:TEMP 'rustdesk-1.4.9-x86_64.exe'
  Invoke-WebRequest 'https://github.com/rustdesk/rustdesk/releases/download/1.4.9/rustdesk-1.4.9-x86_64.exe' -OutFile $installer
  Start-Process -FilePath $installer -ArgumentList '--silent-install' -Verb RunAs -Wait
}

Stop-Process -Name RustDesk -Force -ErrorAction SilentlyContinue

$config = @"
rendezvous_server = 'remote.directnorth.digital:21116'
nat_type = 1
serial = 0

[options]
custom-rendezvous-server = 'remote.directnorth.digital'
key = '$ServerKey'
"@

$paths = @(
  (Join-Path $env:APPDATA 'RustDesk\config'),
  'C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config'
)

foreach ($path in $paths) {
  New-Item -ItemType Directory -Force -Path $path | Out-Null
  Set-Content -Path (Join-Path $path 'RustDesk2.toml') -Value $config -Encoding ASCII
}

if (Test-Path $app) { Start-Process $app }
