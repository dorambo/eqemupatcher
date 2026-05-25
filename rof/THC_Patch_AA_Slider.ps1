param(
    [switch]$NoLaunch
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$eqgame = Join-Path $root "eqgame.exe"
$backup = Join-Path $root "eqgame.exe.bak-thc-aa-slider"

if (!(Test-Path -LiteralPath $eqgame)) {
    throw "eqgame.exe was not found. Put this launcher in your EverQuest RoF2 folder."
}

$bytes = [IO.File]::ReadAllBytes($eqgame)
$offsets = @(0x2095D4, 0x20962F)
$changed = $false

foreach ($offset in $offsets) {
    if ($offset -ge $bytes.Length) {
        throw "This eqgame.exe is not the expected RoF2 client. AA slider patch was not applied."
    }

    $current = $bytes[$offset]
    if ($current -eq 0x33) {
        if (!(Test-Path -LiteralPath $backup)) {
            Copy-Item -LiteralPath $eqgame -Destination $backup
        }

        $bytes[$offset] = 0x01
        $changed = $true
    }
    elseif ($current -eq 0x01) {
        # Already patched.
    }
    else {
        throw ("Unsupported eqgame.exe byte at 0x{0:X}. Expected 0x33 or 0x01, found 0x{1:X2}. AA slider patch was not applied." -f $offset, $current)
    }
}

if ($changed) {
    [IO.File]::WriteAllBytes($eqgame, $bytes)
    Write-Host "The Hero Chronicles AA slider patch was applied. Backup: eqgame.exe.bak-thc-aa-slider"
}
else {
    Write-Host "The Hero Chronicles AA slider patch is already applied."
}

if (!$NoLaunch) {
    Start-Process -FilePath $eqgame -ArgumentList "patchme" -WorkingDirectory $root
}
