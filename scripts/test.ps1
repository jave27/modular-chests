param(
    [string]$FactorioExe = $env:FACTORIO_EXE
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repoRoot = Split-Path -Parent $PSScriptRoot
$outputRoot = Join-Path $repoRoot ".test-output"
$modsDirectory = Join-Path $outputRoot "mods"
$writeDataDirectory = Join-Path $outputRoot "factorio-data"
$packageStage = Join-Path $outputRoot "package"
$testSave = Join-Path $outputRoot "integration-test.zip"
$scriptOutputDirectory = Join-Path $writeDataDirectory "script-output"
$resultFile = Join-Path $scriptOutputDirectory "integration-test-result.txt"
$logFile = Join-Path $writeDataDirectory "factorio-current.log"

function Resolve-FactorioExecutable {
    param([string]$RequestedPath)

    $candidates = @()
    if ($RequestedPath) {
        $candidates += $RequestedPath
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

function New-PortableZip {
    param(
        [string]$SourceDirectory,
        [string]$RootEntryName,
        [string]$Destination
    )

    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    if (Test-Path -LiteralPath $Destination) {
        Remove-Item -LiteralPath $Destination -Force
    }

    $stream = [System.IO.File]::Open(
        $Destination,
        [System.IO.FileMode]::CreateNew
    )

    try {
        $archive = [System.IO.Compression.ZipArchive]::new(
            $stream,
            [System.IO.Compression.ZipArchiveMode]::Create,
            $false
        )

        try {
            Get-ChildItem -LiteralPath $SourceDirectory -Recurse -File |
                ForEach-Object {
                    $relative = $_.FullName.Substring($SourceDirectory.Length).
                        TrimStart('\', '/').
                        Replace('\', '/')
                    $entryName = "$RootEntryName/$relative"
                    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                        $archive,
                        $_.FullName,
                        $entryName,
                        [System.IO.Compression.CompressionLevel]::Optimal
                    ) | Out-Null
                }
        }
        finally {
            $archive.Dispose()
        }
    }
    finally {
        $stream.Dispose()
    }
}

$FactorioExe = Resolve-FactorioExecutable $FactorioExe
$info = Get-Content -LiteralPath (Join-Path $repoRoot "info.json") -Raw |
    ConvertFrom-Json
$packageName = "$($info.name)_$($info.version)"
$packageDirectory = Join-Path $packageStage $packageName
$packageZip = Join-Path $modsDirectory "$packageName.zip"
$testsDirectory = Join-Path $repoRoot "tests"
$testModSource = Join-Path $testsDirectory "integration-mod"
$testModDestination = Join-Path $modsDirectory "modular-chests-continued-tests_1.0.0"

if (Test-Path -LiteralPath $outputRoot) {
    Remove-Item -LiteralPath $outputRoot -Recurse -Force
}

New-Item -ItemType Directory -Path $modsDirectory | Out-Null
New-Item -ItemType Directory -Path $writeDataDirectory | Out-Null
New-Item -ItemType Directory -Path $packageDirectory | Out-Null

$excludedNames = @(
    ".git",
    ".test-output",
    "scripts",
    "tests",
    "DEVELOPMENT.md",
    ".gitignore"
)

Get-ChildItem -LiteralPath $repoRoot -Force |
    Where-Object { $_.Name -notin $excludedNames } |
    Copy-Item -Destination $packageDirectory -Recurse

New-PortableZip $packageDirectory $packageName $packageZip
Copy-Item -LiteralPath $testModSource -Destination $testModDestination -Recurse

$modList = @{
    mods = @(
        @{name = "base"; enabled = $true},
        @{name = "quality"; enabled = $true},
        @{name = $info.name; enabled = $true},
        @{name = "modular-chests-continued-tests"; enabled = $true}
    )
} | ConvertTo-Json -Depth 4
Set-Content -LiteralPath (Join-Path $modsDirectory "mod-list.json") -Value $modList

$writeDataPath = $writeDataDirectory.Replace('\', '/')
$config = @"
[path]
read-data=__PATH__system-read-data__
write-data=$writeDataPath

[general]
locale=en
"@
Set-Content -LiteralPath (Join-Path $outputRoot "config.ini") -Value $config

& $FactorioExe `
    --config (Join-Path $outputRoot "config.ini") `
    --mod-directory $modsDirectory `
    --create $testSave | Out-Null

if (-not (Test-Path -LiteralPath $resultFile)) {
    if (Test-Path -LiteralPath $logFile) {
        Get-Content -LiteralPath $logFile -Tail 80
    }
    throw "Integration tests did not produce a success marker."
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

Write-Host "PASS: Factorio integration tests"
Write-Host "Package: $packageZip"
