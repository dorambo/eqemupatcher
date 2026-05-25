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

Apply-PatchBytes `
    -Name "Bard melody spell level gate" `
    -Offset 0xF5079 `
    -Expected ([byte[]](0x0F, 0xB6, 0x80, 0x74, 0x33, 0x00, 0x00)) `
    -Patched ([byte[]](0xB8, 0x08, 0x00, 0x00, 0x00, 0x90, 0x90))

Apply-PatchBytes `
    -Name "Combat abilities class gate" `
    -Offset 0xF1312 `
    -Expected ([byte[]](0x8D, 0x49, 0x04, 0xE8, 0xF6)) `
    -Patched ([byte[]](0xE9, 0x46, 0x01, 0x00, 0x00))

if ($changed) {
    [IO.File]::WriteAllBytes($eqgame, $bytes)
    Write-Host "The Hero Chronicles client patches were applied. Backup: eqgame.exe.bak-thc-aa-slider"
}
else {
    Write-Host "The Hero Chronicles client patches are already applied."
}

function Set-UiSectionDefaults {
    param(
        [string]$Path,
        [string]$Section,
        [string[]]$Defaults
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.AddRange([string[]](Get-Content -LiteralPath $Path))

    $start = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -ieq "[$Section]") {
            $start = $i
            break
        }
    }

    if ($start -lt 0) {
        if ($lines.Count -gt 0 -and $lines[$lines.Count - 1].Trim().Length -ne 0) {
            $lines.Add("")
        }

        $lines.Add("[$Section]")
        foreach ($entry in $Defaults) {
            $lines.Add($entry)
        }

        Set-Content -LiteralPath $Path -Value $lines
        return
    }

    $end = $lines.Count
    for ($i = $start + 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i].StartsWith("[") -and $lines[$i].EndsWith("]")) {
            $end = $i
            break
        }
    }

    $keys = @{}
    foreach ($entry in $Defaults) {
        $key = $entry.Split("=", 2)[0]
        $keys[$key.ToLowerInvariant()] = $true
    }

    for ($i = $end - 1; $i -gt $start; $i--) {
        $line = $lines[$i]
        $equals = $line.IndexOf("=")
        if ($equals -gt 0) {
            $key = $line.Substring(0, $equals).ToLowerInvariant()
            if ($keys.ContainsKey($key)) {
                $lines.RemoveAt($i)
            }
        }
    }

    [array]::Reverse($Defaults)
    foreach ($entry in $Defaults) {
        $lines.Insert($start + 1, $entry)
    }

    Set-Content -LiteralPath $Path -Value $lines
}

$ui_files = Get-ChildItem -LiteralPath $root -Filter "UI_*.ini" -File -ErrorAction SilentlyContinue
foreach ($ui_file in $ui_files) {
    Set-UiSectionDefaults -Path $ui_file.FullName -Section "CombatAbilityWnd" -Defaults @(
        "Show=0",
        "INIVersion=1",
        "XPosWindowed=147",
        "YPosWindowed=370",
        "RestoreXPosWindowed=50",
        "RestoreYPosWindowed=50",
        "MinimizedWindowed=0"
    )

    Set-UiSectionDefaults -Path $ui_file.FullName -Section "AuraWindow" -Defaults @(
        "Show=0",
        "INIVersion=1",
        "XPosWindowed=731",
        "YPosWindowed=137",
        "WidthWindowed=156",
        "HeightWindowed=87",
        "RestoreXPosWindowed=731",
        "RestoreYPosWindowed=137",
        "MinimizedWindowed=0"
    )
}

if ($ui_files.Count -gt 0) {
    Write-Host "The Hero Chronicles UI window positions were refreshed for Aura and Combat Abilities."
}

if (!$NoLaunch) {
    Start-Process -FilePath $eqgame -ArgumentList "patchme" -WorkingDirectory $root
}
