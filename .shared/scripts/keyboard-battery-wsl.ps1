# Read the ZMK split keyboard battery levels on a Windows host.
#
# The host runs PowerShell in ConstrainedLanguage mode, which blocks Add-Type
# and WinRT method calls. The compiled helper (build-battery-helper.sh) does
# the GATT read instead. Output: "left right"; exit 1 on failure.
$helper = Join-Path $env:WINDIR "Temp\dotfiles-battery-helper.exe"
if (-not (Test-Path $helper)) { exit 1 }
& $helper keyboard
exit $LASTEXITCODE
