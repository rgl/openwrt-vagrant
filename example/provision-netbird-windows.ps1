Set-StrictMode -Version Latest
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
trap {
    Write-Host "ERROR: $_"
    ($_.ScriptStackTrace -split '\r?\n') -replace '^(.*)$','ERROR: $1' | Write-Host
    ($_.Exception.ToString() -split '\r?\n') -replace '^(.*)$','ERROR EXCEPTION: $1' | Write-Host
    Exit 1
}

# see https://github.com/messense/openwrt-netbird/releases
$version = '0.12.0'

# install.
# NB to configure netbird, you still need to connect from the ui or
#    execute sudo netbird up.
# see https://github.com/netbirdio/netbird
# see https://app.netbird.io/add-peer
$artifactUrl = "https://github.com/netbirdio/netbird/releases/download/v${version}/netbird_installer_${version}_windows_amd64.exe"
$artifactPath = "$env:TEMP\$(Split-Path -Leaf $artifactUrl)"

Write-Host 'Downloading the installer...'
(New-Object System.Net.WebClient).DownloadFile($artifactUrl, $artifactPath)

Write-Host 'Installing...'
&$artifactPath /S | Out-String -Stream

# add netbird to the current shell PATH.
$env:PATH += ';C:\Program Files\Netbird'

# configure and start netbird.
if (Test-Path env:NETBIRD_SETUP_KEY) {
    netbird login --setup-key $env:NETBIRD_SETUP_KEY
    netbird up
    while (!(netbird status | Out-String)) { Start-Sleep 3 } # wait for being up.
    netbird status --detail
} else {
    Write-Output @'
# WARNING
# WARNING since you did not provide the NETBIRD_SETUP_KEY environment variable
# WARNING netbird was not configured. you have to configure it manually using:
# WARNING
# WARNING   netbird up
# WARNING
'@
}
