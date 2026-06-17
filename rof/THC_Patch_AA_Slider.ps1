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

function Restore-PatchBytes {
    param(
        [string]$Name,
        [int]$Offset,
        [byte[]]$BadPatched,
        [byte[]]$Original,
        [byte[]]$AllowedPatched = @()
    )

    if ($Offset + $Original.Length -gt $bytes.Length) {
        throw "This eqgame.exe is not the expected RoF2 client. $Name restore was not applied."
    }

    $already_original = $true
    for ($i = 0; $i -lt $Original.Length; $i++) {
        if ($bytes[$Offset + $i] -ne $Original[$i]) {
            $already_original = $false
            break
        }
    }

    if ($already_original) {
        Write-Host "$Name restore is already applied."
        return
    }

    if ($AllowedPatched.Length -gt 0) {
        $allowed = $true
        for ($i = 0; $i -lt $AllowedPatched.Length; $i++) {
            if ($bytes[$Offset + $i] -ne $AllowedPatched[$i]) {
                $allowed = $false
                break
            }
        }

        if ($allowed) {
            Write-Host "$Name restore is not needed; supported replacement patch is already applied."
            return
        }
    }

    for ($i = 0; $i -lt $BadPatched.Length; $i++) {
        if ($bytes[$Offset + $i] -ne $BadPatched[$i]) {
            throw ("Unsupported eqgame.exe bytes for {0} at 0x{1:X}. Restore was not applied." -f $Name, $Offset)
        }
    }

    if (!(Test-Path -LiteralPath $backup)) {
        Copy-Item -LiteralPath $eqgame -Destination $backup
    }

    for ($i = 0; $i -lt $Original.Length; $i++) {
        $bytes[$Offset + $i] = $Original[$i]
    }

    $script:changed = $true
    Write-Host "$Name restore was applied."
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

Restore-PatchBytes `
    -Name "Forced level-one spell client lookup" `
    -Offset 0xAEB00 `
    -BadPatched ([byte[]](0xB0, 0x01, 0xC2, 0x04, 0x00)) `
    -Original ([byte[]](
        0x8B, 0x44, 0x24, 0x04, 0x8D, 0x50, 0xFF, 0x83, 0xFA, 0x22, 0x77, 0x10, 0x83, 0xF8, 0x24, 0x72,
        0x01, 0xCC, 0x8A, 0x84, 0x01, 0x46, 0x02, 0x00, 0x00, 0xC2, 0x04, 0x00, 0x8A, 0x81, 0x47, 0x02,
        0x00, 0x00, 0xC2, 0x04, 0x00
    )) `
    -AllowedPatched ([byte[]](
        0x53, 0xBA, 0x01, 0x00, 0x00, 0x00, 0xB3, 0xFF, 0x8A, 0x84, 0x11, 0x46, 0x02, 0x00, 0x00, 0x3C,
        0xFF, 0x73, 0x04, 0x3A, 0xC3, 0x73, 0x02, 0x8A, 0xD8, 0x42, 0x83, 0xFA, 0x11, 0x7C, 0xE9, 0x8A,
        0xC3, 0x5B, 0xC2, 0x04, 0x00
    ))

Apply-PatchBytes `
    -Name "Prestige spell client minimum level lookup" `
    -Offset 0xAEB00 `
    -Expected ([byte[]](
        0x8B, 0x44, 0x24, 0x04, 0x8D, 0x50, 0xFF, 0x83, 0xFA, 0x22, 0x77, 0x10, 0x83, 0xF8, 0x24, 0x72,
        0x01, 0xCC, 0x8A, 0x84, 0x01, 0x46, 0x02, 0x00, 0x00, 0xC2, 0x04, 0x00, 0x8A, 0x81, 0x47, 0x02,
        0x00, 0x00, 0xC2, 0x04, 0x00
    )) `
    -Patched ([byte[]](
        0x53, 0xBA, 0x01, 0x00, 0x00, 0x00, 0xB3, 0xFF, 0x8A, 0x84, 0x11, 0x46, 0x02, 0x00, 0x00, 0x3C,
        0xFF, 0x73, 0x04, 0x3A, 0xC3, 0x73, 0x02, 0x8A, 0xD8, 0x42, 0x83, 0xFA, 0x11, 0x7C, 0xE9, 0x8A,
        0xC3, 0x5B, 0xC2, 0x04, 0x00
    ))

Apply-PatchBytes `
    -Name "Universal cast spell window gate" `
    -Offset 0x247C3E `
    -Expected ([byte[]](0x83, 0xB8, 0x0C, 0x34, 0x00, 0x00, 0x00, 0x74, 0x14)) `
    -Patched ([byte[]](0xEB, 0x1B, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90))

Apply-PatchBytes `
    -Name "Universal player mana gauge visibility" `
    -Offset 0x31829A `
    -Expected ([byte[]](0x74, 0x05)) `
    -Patched ([byte[]](0x90, 0x90))

Apply-PatchBytes `
    -Name "Combat abilities class gate" `
    -Offset 0xF1312 `
    -Expected ([byte[]](0x8D, 0x49, 0x04, 0xE8, 0xF6)) `
    -Patched ([byte[]](0xE9, 0x46, 0x01, 0x00, 0x00))

Apply-PatchBytes `
    -Name "Combat abilities window command route" `
    -Offset 0xD7703 `
    -Expected ([byte[]](0x81, 0xC7, 0x9B, 0xFE, 0xFF)) `
    -Patched ([byte[]](0xE9, 0x9D, 0x01, 0x00, 0x00))

$character_select_name_offset = 0x5D5998
$character_select_name_original = [byte[]](0x25, 0x73, 0x20, 0x5B, 0x25, 0x64, 0x20, 0x25, 0x73, 0x5D)
$character_select_name_old_patch = [byte[]](0x25, 0x73, 0x20, 0x5B, 0x25, 0x64, 0x5D, 0x20, 0x20, 0x20)
$character_select_name_unterminated_patch = [byte[]](0x25, 0x73, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20)
$character_select_name_null_patch = [byte[]](0x25, 0x73, 0x00, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20)
$character_select_name_new_patch = [byte[]](0x25, 0x73, 0x20, 0x5B, 0x25, 0x64, 0x20, 0x25, 0x73, 0x5D)

$character_select_name_matches = $false
foreach ($allowed in @($character_select_name_original, $character_select_name_old_patch, $character_select_name_unterminated_patch, $character_select_name_null_patch, $character_select_name_new_patch)) {
    $same = $true
    for ($i = 0; $i -lt $allowed.Length; $i++) {
        if ($bytes[$character_select_name_offset + $i] -ne $allowed[$i]) {
            $same = $false
            break
        }
    }

    if ($same) {
        $character_select_name_matches = $true
        break
    }
}

if (!$character_select_name_matches) {
    throw ("Unsupported eqgame.exe bytes for Character select selected-name prestige path at 0x{0:X}. Patch was not applied." -f $character_select_name_offset)
}

$character_select_name_already_patched = $true
for ($i = 0; $i -lt $character_select_name_new_patch.Length; $i++) {
    if ($bytes[$character_select_name_offset + $i] -ne $character_select_name_new_patch[$i]) {
        $character_select_name_already_patched = $false
        break
    }
}

if ($character_select_name_already_patched) {
    Write-Host "Character select selected-name prestige path patch is already applied."
}
else {
    if (!(Test-Path -LiteralPath $backup)) {
        Copy-Item -LiteralPath $eqgame -Destination $backup
    }

    for ($i = 0; $i -lt $character_select_name_new_patch.Length; $i++) {
        $bytes[$character_select_name_offset + $i] = $character_select_name_new_patch[$i]
    }

    $changed = $true
    Write-Host "Character select selected-name prestige path patch was applied."
}

Restore-PatchBytes `
    -Name "Character select selected-name class argument suppress" `
    -Offset 0x18D954 `
    -BadPatched ([byte[]](0x90)) `
    -Original ([byte[]](0x50))

Apply-PatchBytes `
    -Name "Character select selected-name level argument suppress" `
    -Offset 0x18D95F `
    -Expected ([byte[]](0x90)) `
    -Patched ([byte[]](0x50))

Apply-PatchBytes `
    -Name "Character select selected-name stack cleanup" `
    -Offset 0x18D973 `
    -Expected ([byte[]](0x83, 0xC4, 0x10)) `
    -Patched ([byte[]](0x83, 0xC4, 0x18))

Apply-PatchBytes `
    -Name "Character select detail line zone-only formatter" `
    -Offset 0x5C8F90 `
    -Expected ([byte[]](0x25, 0x73, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20)) `
    -Patched ([byte[]](0x25, 0x73, 0x3C, 0x42, 0x52, 0x3E, 0x25, 0x73))

Restore-PatchBytes `
    -Name "Character select detail line first argument order" `
    -Offset 0xB70F5 `
    -BadPatched ([byte[]](0x50, 0x90, 0x90, 0x90, 0x90)) `
    -Original ([byte[]](0x8D, 0x4C, 0x24, 0x38, 0x51))

Restore-PatchBytes `
    -Name "Character select detail line second argument order" `
    -Offset 0xB71E4 `
    -BadPatched ([byte[]](0x50, 0x90, 0x90, 0x90, 0x90)) `
    -Original ([byte[]](0x8D, 0x4C, 0x24, 0x38, 0x51))

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
        "Show=1",
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
