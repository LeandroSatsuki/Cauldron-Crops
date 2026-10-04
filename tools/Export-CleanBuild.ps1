[CmdletBinding()]
param(
    [string]$GodotPath = $env:GODOT4_PATH,
    [string]$Preset = "Windows Desktop - Fase 1 Demo",
    [string]$OutputPath = "Builds/Fase1/CauldronCrops_Fase1.exe",
    [switch]$SmokeTest,
    [switch]$Playtest,
    [switch]$RunRegressionSuite
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
if ($Playtest) {
    $Preset = "Windows Desktop - Post-V0 Playtest"
    if (-not $PSBoundParameters.ContainsKey("OutputPath")) {
        $OutputPath = "Builds/Playtest/CauldronCrops_Playtest.exe"
    }
}
$godotExecutable = Find-GodotExecutable -RequestedPath $GodotPath
$outputAbsolute = if ([System.IO.Path]::IsPathRooted($OutputPath)) {
    [System.IO.Path]::GetFullPath($OutputPath)
} else {
    [System.IO.Path]::GetFullPath((Join-Path $repoRoot $OutputPath))
}
$outputDirectory = Split-Path -Parent $outputAbsolute
$worktreePath = Join-Path $repoRoot "Builds/.clean-export-$PID"
$worktreeAdded = $false
$originalAppData = $env:APPDATA
$qaAppData = Join-Path $worktreePath "Builds/QA/GodotSandboxCleanExport"
$reopenCount = 0
$additionalFixtureCount = 0
$buildSucceeded = $false

if (Test-Path -LiteralPath $worktreePath) {
    throw "Temporary export directory already exists: $worktreePath"
}

New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null

$sourceCommit = (& git -C $repoRoot rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0) { throw "Could not identify the source commit." }
$head = $sourceCommit.Substring(0, 7)
$localChanges = & git -C $repoRoot status --porcelain
if ($localChanges) {
    Write-Host "Local changes detected; they will not be included in this build."
}

Write-Host "Exporting commit $head with preset '$Preset'."

try {
    Invoke-NativeCommand -FailureMessage "Could not create the clean export worktree" -Command {
        & git -C $repoRoot worktree add --detach $worktreePath $sourceCommit
    }
    $worktreeAdded = $true

    # Export-only transformation: direct launch cannot load the author's save.
    # This is recorded in the manifest; source gameplay and save schema stay intact.
    if ($Playtest) {
        $projectPath = Join-Path $worktreePath "project.godot"
        $projectText = [System.IO.File]::ReadAllText($projectPath)
        $projectText = $projectText.Replace("[application]", "[application]`nconfig/use_custom_user_dir=true`nconfig/custom_user_dir_name=`"CauldronCropsPlaytest`"")
        [System.IO.File]::WriteAllText($projectPath, $projectText)
    }

    $godotCacheDirectory = Join-Path $worktreePath ".godot"
    New-Item -ItemType Directory -Path $godotCacheDirectory -Force | Out-Null

    Write-Host "Preparing Godot imports and class cache."
    Invoke-GodotCommand `
        -Executable $godotExecutable `
        -Arguments @("--path", $worktreePath, "--editor", "--headless", "--quit") `
        -LogPath (Join-Path $godotCacheDirectory "clean-export-import.log") `
        -FailureMessage "Godot import preparation failed" `
        -RejectLoggedErrors

    $env:APPDATA = $qaAppData
    Write-Host "Validating the clean project."
    Invoke-GodotCommand `
        -Executable $godotExecutable `
        -Arguments @("--path", $worktreePath, "--headless", "--quit") `
        -LogPath (Join-Path $godotCacheDirectory "clean-export-validation.log") `
        -FailureMessage "Clean project validation failed" `
        -RejectLoggedErrors

    if ($RunRegressionSuite) {
        $tests = Get-ChildItem -LiteralPath (Join-Path $worktreePath "Scenes/dev") -Filter "*SmokeTest.tscn" | Sort-Object Name
        foreach ($test in $tests) {
            $log = Join-Path $godotCacheDirectory ($test.BaseName + ".log")
            Invoke-GodotCommand -Executable $godotExecutable `
                -Arguments @("--path", $worktreePath, "--headless", ("res://Scenes/dev/" + $test.Name)) `
                -LogPath $log -FailureMessage $test.Name -RejectLoggedErrors
            if (-not (Select-String -LiteralPath $log -Pattern ": PASS")) {
                throw "$($test.Name) did not report PASS."
            }
            Write-Host "PASS $($test.Name)"
            # Reopen immediately, before another fixture can replace the QA save.
            $steps = @(switch ($test.BaseName) {
                "TomatoCropSmokeTest" {
                    @{ Name = "tomato-fixture"; Mode = "--write-tomato-crop-fixture"; Checks = 2; Reopen = $false }
                    @{ Name = "tomato-reopen"; Mode = "--verify-tomato-crop-reopen"; Checks = 8; Reopen = $true }
                }
                "RenewableRootSmokeTest" {
                    @{ Name = "root-fixture"; Mode = "--write-renewable-root-fixture"; Checks = 2; Reopen = $false }
                    @{ Name = "root-reopen"; Mode = "--verify-renewable-root-reopen"; Checks = 8; Reopen = $true }
                }
                "AcceleratorDeliverySmokeTest" {
                    @{ Name = "prepared-fixture"; Mode = "--write-accelerator-prepared-fixture"; Checks = 2; Reopen = $false }
                    @{ Name = "prepared-reopen"; Mode = "--verify-accelerator-prepared-reopen"; Checks = 8; Reopen = $true }
                    @{ Name = "active-fixture"; Mode = "--write-accelerator-active-fixture"; Checks = 2; Reopen = $false }
                    @{ Name = "active-reopen"; Mode = "--verify-accelerator-active-reopen"; Checks = 8; Reopen = $true }
                }
                "GolemWorkPersistenceSmokeTest" {
                    @{ Name = "reopen"; Mode = "--verify-sower-reopen"; Checks = 6; Reopen = $true }
                }
                "GolemSowerUISmokeTest" {
                    @{ Name = "reopen"; Mode = "--verify-seeding-ui-reopen"; Checks = 3; Reopen = $true }
                }
                "SustainableFarmCycleSmokeTest" {
                    @{ Name = "recovery-reopen"; Mode = "--verify-seed-cycle-reopen"; Checks = 8; Reopen = $true }
                    @{ Name = "replant-fixture"; Mode = "--prepare-seed-replant-save"; Checks = 2; Reopen = $false }
                    @{ Name = "replant-reopen"; Mode = "--verify-seed-cycle-reopen"; Checks = 8; Reopen = $true }
                }
                "VillageWellPhysicalSmokeTest" {
                    @{ Name = "physical-reopen"; Mode = "--verify-well-physical-reopen"; Checks = 4; Reopen = $true }
                }
                "VillageWellProgressSmokeTest" {
                    @{ Name = "project-reopen"; Mode = "--verify-well-reopen"; Checks = 8; Reopen = $true }
                    @{ Name = "water-skill-fixture"; Mode = "--prepare-water-skill-save"; Checks = 2; Reopen = $false }
                    @{ Name = "water-skill-reopen"; Mode = "--verify-well-reopen"; Checks = 8; Reopen = $true }
                }
                "LivingSoilSmokeTest" {
                    @{ Name = "living-soil-reopen"; Mode = "--verify-living-soil-reopen"; Checks = 8; Reopen = $true }
                }
            })
            foreach ($step in $steps) {
                $stepLog = Join-Path $godotCacheDirectory ($test.BaseName + "-" + $step.Name + ".log")
                Invoke-GodotCommand -Executable $godotExecutable `
                    -Arguments @("--path", $worktreePath, "--headless", ("res://Scenes/dev/" + $test.Name), "--", $step.Mode) `
                    -LogPath $stepLog -FailureMessage "$($test.Name) $($step.Name)" -RejectLoggedErrors
                if (-not (Select-String -LiteralPath $stepLog -Pattern (": PASS - " + $step.Checks + " verific"))) {
                    throw "$($test.Name) $($step.Name) did not report the expected $($step.Checks) checks."
                }
                if ($step.Reopen) { $reopenCount++ } else { $additionalFixtureCount++ }
                Write-Host "PASS $($test.Name) $($step.Name) ($($step.Checks) checks)"
            }
        }
        Write-Host "Regression suite: $($tests.Count)/$($tests.Count)."
    }

    # Export templates live in the normal Godot profile; export does not run gameplay.
    $env:APPDATA = $originalAppData
    Write-Host "Creating Windows build."
    Invoke-GodotCommand `
        -Executable $godotExecutable `
        -Arguments @("--path", $worktreePath, "--headless", "--export-debug", $Preset, $outputAbsolute) `
        -LogPath (Join-Path $godotCacheDirectory "clean-export-build.log") `
        -FailureMessage "Godot export failed" `
        -RejectLoggedErrors

    if ($SmokeTest) {
        $env:APPDATA = $qaAppData
        $smokeStandardOutput = Join-Path $godotCacheDirectory "clean-export-smoke.stdout.log"
        $smokeStandardError = Join-Path $godotCacheDirectory "clean-export-smoke.stderr.log"
        $process = Start-Process `
            -FilePath $outputAbsolute `
            -ArgumentList "--headless", "--quit-after", "120" `
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
        if ($Playtest) {
            $graphicsOutput = Join-Path $godotCacheDirectory "clean-export-opengl.stdout.log"
            $graphicsError = Join-Path $godotCacheDirectory "clean-export-opengl.stderr.log"
            $graphicsProcess = Start-Process -FilePath $outputAbsolute `
                -ArgumentList "--rendering-method", "gl_compatibility", "--quit-after", "120" `
                -WorkingDirectory $outputDirectory -WindowStyle Hidden `
                -RedirectStandardOutput $graphicsOutput -RedirectStandardError $graphicsError -Wait -PassThru
            if ($graphicsProcess.ExitCode -ne 0) {
                throw "Exported OpenGL startup failed (exit code $($graphicsProcess.ExitCode))."
            }
            if (Select-String -LiteralPath $graphicsOutput, $graphicsError -Pattern "(^|\s)(SCRIPT ERROR:|ERROR:)") {
                throw "Exported OpenGL startup logged errors."
            }
            Write-Host "OpenGL startup passed (not manual gameplay acceptance)."
        }
    }

    if ($Playtest) {
        $env:APPDATA = $qaAppData
        $packPath = [System.IO.Path]::ChangeExtension($outputAbsolute, ".pck")
        Invoke-GodotCommand -Executable $godotExecutable `
            -Arguments @("--headless", "--path", $outputDirectory, "--main-pack", $packPath, "--script", (Join-Path $worktreePath "tools/Inspect-PlaytestPack.gd")) `
            -LogPath (Join-Path $godotCacheDirectory "pack-audit.log") `
            -FailureMessage "Playtest pack audit failed" -RejectLoggedErrors
        $manifest = [ordered]@{
            commit = $sourceCommit
            preset = $Preset
            export_only_user_directory = "CauldronCropsPlaytest"
            regression_count = $(if ($RunRegressionSuite) { $tests.Count } else { 0 })
            process_reopen_count = $reopenCount
            additional_fixture_count = $additionalFixtureCount
            headless_startup_passed = [bool]$SmokeTest
            opengl_startup_passed = [bool]$SmokeTest
            pack_audit_passed = $true
            executable_sha256 = (Get-FileHash -LiteralPath $outputAbsolute -Algorithm SHA256).Hash
            pack_sha256 = (Get-FileHash -LiteralPath $packPath -Algorithm SHA256).Hash
            manual_status = "pending"
        }
        Copy-Item -LiteralPath (Join-Path $worktreePath "tools/StartPlaytest.cmd") -Destination (Join-Path $outputDirectory "StartPlaytest.cmd")
        $roadmap = [System.IO.File]::ReadAllText((Join-Path $worktreePath "docs/ROADMAP.md"))
        $checklist = [regex]::Match($roadmap, '(?s)### Checklist integrado.*?(?=\r?\n### Riscos técnicos)')
        if (-not $checklist.Success) { throw "Integrated checklist was not found." }
        $manualCaseCount = [regex]::Matches($checklist.Value, '(?m)^- \[ \] \*\*[A-Z]+-\d+').Count
        $manifest["manual_case_count"] = $manualCaseCount
        $manifest | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $outputDirectory "build-manifest.json") -Encoding UTF8
        [System.IO.File]::WriteAllText((Join-Path $outputDirectory "CHECKLIST.md"), $checklist.Value)
        Copy-Item -LiteralPath (Join-Path $worktreePath "tools/Playtest-Readme.txt") -Destination (Join-Path $outputDirectory "LEIA-ME.txt")
        $logsDirectory = Join-Path $outputDirectory "Logs"
        New-Item -ItemType Directory -Path $logsDirectory -Force | Out-Null
        Copy-Item -Path (Join-Path $godotCacheDirectory "*.log") -Destination $logsDirectory
    }

    $outputFile = Get-Item -LiteralPath $outputAbsolute
    Write-Host "Build created: $($outputFile.FullName) ($($outputFile.Length) bytes)"
    $buildSucceeded = $true
} finally {
    $env:APPDATA = $originalAppData
    if ($worktreeAdded) {
        $resolvedWorktree = [System.IO.Path]::GetFullPath($worktreePath)
        $expectedParent = [System.IO.Path]::GetFullPath((Join-Path $repoRoot "Builds")) + [System.IO.Path]::DirectorySeparatorChar
        if (-not $resolvedWorktree.StartsWith($expectedParent, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing cleanup outside Builds: $resolvedWorktree"
        }
        if (-not $buildSucceeded) {
            $failedLogs = Join-Path $outputDirectory ("FailedLogs-" + $head + "-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
            New-Item -ItemType Directory -Path $failedLogs -Force | Out-Null
            Get-ChildItem -LiteralPath (Join-Path $resolvedWorktree ".godot") -Filter "*.log" -File -ErrorAction SilentlyContinue |
                Copy-Item -Destination $failedLogs
            Write-Warning "Export failed; diagnostic logs retained at $failedLogs"
        }
        & git -C $repoRoot worktree remove --force $worktreePath
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Could not remove temporary worktree: $worktreePath"
        }
    }
}
