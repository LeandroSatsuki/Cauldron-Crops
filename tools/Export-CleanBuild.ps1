[CmdletBinding()]
param(
    [string]$GodotPath = $env:GODOT4_PATH,
    [string]$Preset = "Windows Desktop - Fase 1 Demo",
    [string]$OutputPath = "Builds/Fase1/CauldronCrops_Fase1.exe",
    [switch]$SmokeTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Invoke-NativeCommand {
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Command,

        [Parameter(Mandatory = $true)]
        [string]$FailureMessage
    )

    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "$FailureMessage (exit code $LASTEXITCODE)."
    }
}

function Invoke-GodotCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Executable,

        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,

        [Parameter(Mandatory = $true)]
        [string]$LogPath,

        [Parameter(Mandatory = $true)]
        [string]$FailureMessage,

        [switch]$RejectLoggedErrors
    )

    $previousErrorActionPreference = $ErrorActionPreference
    try {
        # Windows PowerShell 5 promotes native stderr to ErrorRecord objects when
        # ErrorActionPreference is Stop. Capture it first so the log can be
        # evaluated consistently from either Windows PowerShell or PowerShell 7.
        $ErrorActionPreference = "Continue"
        & $Executable @Arguments *> $LogPath
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    if ($exitCode -ne 0) {
        Get-Content -LiteralPath $LogPath | Write-Host
        throw "$FailureMessage (exit code $exitCode)."
    }

    if ($RejectLoggedErrors) {
        $loggedErrors = Select-String `
            -LiteralPath $LogPath `
            -Pattern "(^|\s)(SCRIPT ERROR:|ERROR:)"

        if ($loggedErrors) {
            $loggedErrors.Line | Write-Host
            throw "$FailureMessage (Godot logged errors)."
        }
    }
}

function Find-GodotExecutable {
    param([string]$RequestedPath)

    if ($RequestedPath) {
        if (-not (Test-Path -LiteralPath $RequestedPath -PathType Leaf)) {
            throw "Godot executable not found: $RequestedPath"
        }

        return (Resolve-Path -LiteralPath $RequestedPath).Path
    }

    foreach ($commandName in @("godot4", "godot")) {
        $command = Get-Command $commandName -ErrorAction SilentlyContinue
        if ($command) {
            return $command.Source
        }
    }

    $localGodot = Join-Path $env:LOCALAPPDATA "Programs/Godot/Godot_v4.6.2-stable_win64_console.exe"
    if (Test-Path -LiteralPath $localGodot -PathType Leaf) {
        return (Resolve-Path -LiteralPath $localGodot).Path
    }

    throw "Godot was not found. Pass -GodotPath or define GODOT4_PATH."
}

$repoRootOutput = & git rev-parse --show-toplevel
if ($LASTEXITCODE -ne 0) {
    throw "Run this script from inside the Cauldron Crops Git repository."
}

$repoRoot = $repoRootOutput.Trim()
$godotExecutable = Find-GodotExecutable -RequestedPath $GodotPath
$outputAbsolute = if ([System.IO.Path]::IsPathRooted($OutputPath)) {
    [System.IO.Path]::GetFullPath($OutputPath)
} else {
    [System.IO.Path]::GetFullPath((Join-Path $repoRoot $OutputPath))
}
$outputDirectory = Split-Path -Parent $outputAbsolute
$worktreePath = Join-Path $repoRoot "Builds/.clean-export-$PID"
$worktreeAdded = $false

if (Test-Path -LiteralPath $worktreePath) {
    throw "Temporary export directory already exists: $worktreePath"
}

New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null

$head = (& git -C $repoRoot rev-parse --short HEAD).Trim()
$localChanges = & git -C $repoRoot status --porcelain
if ($localChanges) {
    Write-Host "Local changes detected; they will not be included in this build."
}

Write-Host "Exporting commit $head with preset '$Preset'."

try {
    Invoke-NativeCommand -FailureMessage "Could not create the clean export worktree" -Command {
        & git -C $repoRoot worktree add --detach $worktreePath HEAD
    }
    $worktreeAdded = $true

    $godotCacheDirectory = Join-Path $worktreePath ".godot"
    New-Item -ItemType Directory -Path $godotCacheDirectory -Force | Out-Null

    Write-Host "Preparing Godot imports and class cache."
    Invoke-GodotCommand `
        -Executable $godotExecutable `
        -Arguments @("--path", $worktreePath, "--editor", "--headless", "--quit") `
        -LogPath (Join-Path $godotCacheDirectory "clean-export-import.log") `
        -FailureMessage "Godot import preparation failed"

    Write-Host "Validating the clean project."
    Invoke-GodotCommand `
        -Executable $godotExecutable `
        -Arguments @("--path", $worktreePath, "--headless", "--quit") `
        -LogPath (Join-Path $godotCacheDirectory "clean-export-validation.log") `
        -FailureMessage "Clean project validation failed" `
        -RejectLoggedErrors

    Write-Host "Creating Windows build."
    Invoke-GodotCommand `
        -Executable $godotExecutable `
        -Arguments @("--path", $worktreePath, "--headless", "--export-debug", $Preset, $outputAbsolute) `
        -LogPath (Join-Path $godotCacheDirectory "clean-export-build.log") `
        -FailureMessage "Godot export failed" `
        -RejectLoggedErrors

    if ($SmokeTest) {
        $smokeStandardOutput = Join-Path $godotCacheDirectory "clean-export-smoke.stdout.log"
        $smokeStandardError = Join-Path $godotCacheDirectory "clean-export-smoke.stderr.log"
        $process = Start-Process `
            -FilePath $outputAbsolute `
            -ArgumentList "--headless", "--quit" `
            -WorkingDirectory $outputDirectory `
            -WindowStyle Hidden `
            -RedirectStandardOutput $smokeStandardOutput `
            -RedirectStandardError $smokeStandardError `
            -Wait `
            -PassThru

        if ($process.ExitCode -ne 0) {
            throw "Exported game smoke test failed (exit code $($process.ExitCode))."
        }

        $smokeErrors = Select-String `
            -LiteralPath $smokeStandardOutput, $smokeStandardError `
            -Pattern "(^|\s)(SCRIPT ERROR:|ERROR:)"
        if ($smokeErrors) {
            $smokeErrors.Line | Write-Host
            throw "Exported game smoke test logged errors."
        }

        Write-Host "Smoke test passed."
    }

    $outputFile = Get-Item -LiteralPath $outputAbsolute
    Write-Host "Build created: $($outputFile.FullName) ($($outputFile.Length) bytes)"
} finally {
    if ($worktreeAdded) {
        & git -C $repoRoot worktree remove --force $worktreePath
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Could not remove temporary worktree: $worktreePath"
        }
    }
}
