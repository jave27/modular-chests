param(
    [string]$FactorioExe = $env:FACTORIO_EXE,
    [ValidateSet("Base", "Quality", "SpaceAge")]
    [string]$ModSet = "Quality"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repoRoot = Split-Path -Parent $PSScriptRoot

function Resolve-FactorioExecutable {
    param([string]$RequestedPath)

    $candidates = @()
    if ($RequestedPath) {
        if (-not (Test-Path -LiteralPath $RequestedPath -PathType Leaf)) {
            throw "The requested Factorio executable does not exist: $RequestedPath"
        }
        return (Resolve-Path -LiteralPath $RequestedPath).Path
    }

    if ($PSVersionTable.PSEdition -eq "Desktop" -or $IsWindows) {
        $candidates += @(
            (Join-Path ${env:ProgramFiles(x86)} "Steam\steamapps\common\Factorio\bin\x64\factorio.exe"),
            (Join-Path $env:ProgramFiles "Factorio\bin\x64\factorio.exe")
        )
    }
    elseif ($IsLinux) {
        $candidates += @(
            (Join-Path $HOME ".steam/steam/steamapps/common/Factorio/bin/x64/factorio"),
            "/usr/bin/factorio"
        )
    }
    elseif ($IsMacOS) {
        $candidates += "/Applications/factorio.app/Contents/MacOS/factorio"
    }

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    throw "Factorio was not found. Set FACTORIO_EXE or pass -FactorioExe."
}

$FactorioExe = Resolve-FactorioExecutable $FactorioExe
$versionOutput = (& $FactorioExe --version | Out-String)
if ($LASTEXITCODE -ne 0 -or $versionOutput -notmatch 'Version:\s+(2\.[01])\.\d+') {
    throw "Expected a Factorio 2.0 or 2.1 executable. Version output: $versionOutput"
}
$factorioVersion = $Matches[1]
$testRoot = Join-Path $repoRoot ".test-output"
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
$testRoot = (Resolve-Path -LiteralPath $testRoot).Path
$outputRoot = [System.IO.Path]::GetFullPath((Join-Path $testRoot "$factorioVersion-$ModSet"))
# Verify the absolute cleanup target before deleting any generated files.
if ((Split-Path -Parent $outputRoot) -ne $testRoot) {
    throw "Test output must be a direct child of $testRoot"
}
$modsDirectory = Join-Path $outputRoot "mods"
$writeDataDirectory = Join-Path $outputRoot "factorio-data"
$testSave = Join-Path $outputRoot "integration-test.zip"
$resultFile = Join-Path $writeDataDirectory "script-output/integration-test-result.txt"
$logFile = Join-Path $writeDataDirectory "factorio-current.log"
$info = Get-Content -LiteralPath (Join-Path $repoRoot "info.json") -Raw |
    ConvertFrom-Json
$testsDirectory = Join-Path $repoRoot "tests"
$testModSource = Join-Path $testsDirectory "integration-mod"
$testModDestination = Join-Path $modsDirectory "modular-chests-continued-tests_1.0.0"

if (Test-Path -LiteralPath $outputRoot) {
    Remove-Item -LiteralPath $outputRoot -Recurse -Force
}

New-Item -ItemType Directory -Path $modsDirectory | Out-Null
New-Item -ItemType Directory -Path $writeDataDirectory | Out-Null
$packageZip = & (Join-Path $PSScriptRoot "package.ps1") `
    -FactorioVersion $factorioVersion -OutputDirectory $modsDirectory
Copy-Item -LiteralPath $testModSource -Destination $testModDestination -Recurse
$testInfoPath = Join-Path $testModDestination "info.json"
$testInfo = Get-Content -LiteralPath $testInfoPath -Raw | ConvertFrom-Json
$testInfo.factorio_version = $factorioVersion
$testInfo | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $testInfoPath -Encoding UTF8

$enabledMods = @(
        @{name = "base"; enabled = $true},
        @{name = "quality"; enabled = ($ModSet -ne "Base")},
        @{name = "elevated-rails"; enabled = ($ModSet -eq "SpaceAge")},
        @{name = "space-age"; enabled = ($ModSet -eq "SpaceAge")},
        @{name = $info.name; enabled = $true},
        @{name = "modular-chests-continued-tests"; enabled = $true}
)
if ($factorioVersion -eq "2.1") {
    $enabledMods += @{name = "recycler"; enabled = ($ModSet -ne "Base")}
}
$modList = @{ mods = $enabledMods } | ConvertTo-Json -Depth 4
Set-Content -LiteralPath (Join-Path $modsDirectory "mod-list.json") -Value $modList

$writeDataPath = $writeDataDirectory.Replace('\', '/')
$readDataPath = "__PATH__system-read-data__"
$installRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $FactorioExe))
$portableData = Join-Path $installRoot "data"
if (Test-Path -LiteralPath (Join-Path $portableData "core/info.json")) {
    $readDataPath = $portableData.Replace('\', '/')
}
$config = @"
[path]
read-data=$readDataPath
write-data=$writeDataPath

[general]
locale=en
"@
Set-Content -LiteralPath (Join-Path $outputRoot "config.ini") -Value $config

$factorioOutput = & $FactorioExe `
    --config (Join-Path $outputRoot "config.ini") `
    --mod-directory $modsDirectory `
    --create $testSave 2>&1 | Out-String

$factorioExitCode = $LASTEXITCODE
if ($factorioExitCode -ne 0 -or -not (Test-Path -LiteralPath $resultFile)) {
    if (Test-Path -LiteralPath $logFile) {
        Get-Content -LiteralPath $logFile -Tail 80
    }
    else {
        Write-Host $factorioOutput
    }
    throw "Integration tests failed (exit $factorioExitCode) or did not produce a success marker."
}

$result = (Get-Content -LiteralPath $resultFile -Raw).Trim()
if ($result -ne "PASS") {
    throw "Integration tests returned '$result'."
}

$archive = [System.IO.Compression.ZipFile]::OpenRead($packageZip)
try {
    $invalidEntries = @(
        $archive.Entries |
            Where-Object { $_.FullName.Contains('\') }
    )
    if ($invalidEntries.Count -ne 0) {
        throw "Package contains Windows-style ZIP separators."
    }
}
finally {
    $archive.Dispose()
}

Write-Host "PASS: Factorio $factorioVersion integration tests ($ModSet)"
Write-Host "Package: $packageZip"
