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
$changed = $false

function Apply-PatchBytes {
    param(
        [string]$Name,
        [int]$Offset,
        [byte[]]$Expected,
        [byte[]]$Patched
    )

    if ($Offset + $Expected.Length -gt $bytes.Length) {
        throw "This eqgame.exe is not the expected RoF2 client. $Name patch was not applied."
    }

    $already_patched = $true
    for ($i = 0; $i -lt $Patched.Length; $i++) {
        if ($bytes[$Offset + $i] -ne $Patched[$i]) {
            $already_patched = $false
            break
        }
    }

    if ($already_patched) {
        Write-Host "$Name patch is already applied."
        return
    }

    for ($i = 0; $i -lt $Expected.Length; $i++) {
        if ($bytes[$Offset + $i] -ne $Expected[$i]) {
            throw ("Unsupported eqgame.exe bytes for {0} at 0x{1:X}. Patch was not applied." -f $Name, $Offset)
        }
    }

    if (!(Test-Path -LiteralPath $backup)) {
        Copy-Item -LiteralPath $eqgame -Destination $backup
    }

    for ($i = 0; $i -lt $Patched.Length; $i++) {
        $bytes[$Offset + $i] = $Patched[$i]
    }

    $script:changed = $true
    Write-Host "$Name patch was applied."
}

foreach ($offset in @(0x2095D4, 0x20962F)) {
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

Apply-PatchBytes `
    -Name "Aura window class/client gate" `
    -Offset 0x97021 `
    -Expected ([byte[]](0x74, 0x57)) `
    -Patched ([byte[]](0x90, 0x90))

Apply-PatchBytes `
    -Name "Bard melody prestige gate" `
    -Offset 0xF5025 `
    -Expected ([byte[]](0x0F, 0x85, 0x12, 0x01, 0x00, 0x00)) `
    -Patched ([byte[]](0x90, 0x90, 0x90, 0x90, 0x90, 0x90))

if ($changed) {
    [IO.File]::WriteAllBytes($eqgame, $bytes)
    Write-Host "The Hero Chronicles client patches were applied. Backup: eqgame.exe.bak-thc-aa-slider"
}
else {
    Write-Host "The Hero Chronicles client patches are already applied."
}

if (!$NoLaunch) {
    Start-Process -FilePath $eqgame -ArgumentList "patchme" -WorkingDirectory $root
}
