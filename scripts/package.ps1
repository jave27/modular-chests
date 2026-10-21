param(
    [ValidateSet("2.0", "2.1")]
    [string]$FactorioVersion = "2.0",
    [string]$OutputDirectory = (Join-Path (Split-Path -Parent $PSScriptRoot) "dist")
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repoRoot = Split-Path -Parent $PSScriptRoot
$info = Get-Content -LiteralPath (Join-Path $repoRoot "info.json") -Raw |
    ConvertFrom-Json
$sourceVersion = $info.version
# The game-version release lines share the same patch number and Lua sources.
$info.version = "$FactorioVersion.$(($info.version -split '\.')[2])"
$info.factorio_version = $FactorioVersion
$info.dependencies = @($info.dependencies | ForEach-Object {
    if ($_ -match '^base\s*>=') { "base >= $FactorioVersion" } else { $_ }
})
$packageName = "$($info.name)_$($info.version)"
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$OutputDirectory = (Resolve-Path -LiteralPath $OutputDirectory).Path
$destination = Join-Path $OutputDirectory "$packageName.zip"

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$stream = [System.IO.File]::Open($destination, [System.IO.FileMode]::Create)
try {
    $archive = [System.IO.Compression.ZipArchive]::new(
        $stream, [System.IO.Compression.ZipArchiveMode]::Create, $false
    )
    try {
        $entry = $archive.CreateEntry("$packageName/info.json")
        $writer = [System.IO.StreamWriter]::new($entry.Open())
        try { $writer.WriteLine(($info | ConvertTo-Json -Depth 4)) }
        finally { $writer.Dispose() }

        $entry = $archive.CreateEntry("$packageName/changelog.txt")
        $writer = [System.IO.StreamWriter]::new($entry.Open())
        try {
            $changelog = Get-Content -LiteralPath (Join-Path $repoRoot "changelog.txt") -Raw
            $writer.Write($changelog.Replace("Version: $sourceVersion", "Version: $($info.version)"))
        }
        finally { $writer.Dispose() }

        # Only ship mod assets, never tests, local saves, or packaging output.
        $files = @(foreach ($name in @(
            "control.lua", "data.lua", "README.md", "LICENSE", "thumbnail.png"
        )) { Get-Item -LiteralPath (Join-Path $repoRoot $name) })
        foreach ($directory in @("prototypes", "graphics", "locale")) {
            $files += @(Get-ChildItem -LiteralPath (Join-Path $repoRoot $directory) -Recurse -File)
        }
        foreach ($file in $files) {
            $relative = $file.FullName.Substring($repoRoot.Length).
                TrimStart('\', '/').Replace('\', '/')
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                $archive, $file.FullName, "$packageName/$relative",
                [System.IO.Compression.CompressionLevel]::Optimal
            ) | Out-Null
        }
    }
    finally { $archive.Dispose() }
}
finally { $stream.Dispose() }

# Emit only the path so the integration harness can use the same package.
$destination
