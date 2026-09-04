# Build and verify a local CurseForge ZIP without uploading anything
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$addonName = 'IronfurTracker'
$tocPath = Join-Path $repoRoot ($addonName + '.toc')
$tocLines = Get-Content -LiteralPath $tocPath

function Get-TocMetadata([string] $key) {
    $pattern = '^## ' + [regex]::Escape($key) + ':\s*(.+)$'
    $values = @($tocLines | ForEach-Object {
        if ($_ -match $pattern) { $Matches[1].Trim() }
    })
    if ($values.Count -ne 1) { throw "Expected one $key entry in the TOC" }
    return $values[0]
}

$version = Get-TocMetadata 'Version'
if ($version -notmatch '^\d+\.\d+\.\d+(?:[-+][A-Za-z0-9.-]+)?$') {
    throw "Invalid package version: $version"
}
$changelog = Get-Content -LiteralPath (Join-Path $repoRoot 'docs/CHANGELOG.md') -Raw
if ($changelog -notmatch ('(?m)^## \[' + [regex]::Escape($version) + '\]')) {
    throw 'The changelog must contain the current TOC version'
}

$icon = (Get-TocMetadata 'IconTexture').Replace('\', '/')
$iconPrefix = 'Interface/AddOns/' + $addonName + '/'
if (-not $icon.StartsWith($iconPrefix, [StringComparison]::Ordinal)) {
    throw 'IconTexture must refer to an image inside this addon'
}

$runtimePaths = @($tocLines | Where-Object {
    $_.Trim() -and -not $_.TrimStart().StartsWith('#')
} | ForEach-Object { $_.Trim().Replace('\', '/') })
$packagePaths = @(($addonName + '.toc'), 'LICENSE', 'docs/CHANGELOG.md', 'docs/LIBRARIES.md') +
    $runtimePaths + @($icon.Substring($iconPrefix.Length),
    'libs/CallbackHandler-1.0/LICENSE.txt', 'libs/LibSharedMedia-3.0/LICENSE.txt')
if (@($packagePaths | Select-Object -Unique).Count -ne $packagePaths.Count) {
    throw 'Duplicate package path'
}

# Resolve each segment with exact casing before writing the archive
$sources = @{}
foreach ($path in $packagePaths) {
    if ([IO.Path]::IsPathRooted($path) -or $path -match '(^|/)\.\.?(/|$)|//') {
        throw "Invalid package path: $path"
    }
    $currentPath = $repoRoot
    foreach ($segment in $path.Split('/')) {
        $matchesByCase = @(Get-ChildItem -LiteralPath $currentPath -Force | Where-Object {
            $_.Name -ceq $segment
        })
        if ($matchesByCase.Count -ne 1) { throw "Missing file or incorrect casing: $path" }
        $currentPath = $matchesByCase[0].FullName
    }
    if (-not (Test-Path -LiteralPath $currentPath -PathType Leaf)) {
        throw "Not a package file: $path"
    }
    $sources[$path] = $currentPath
}

$outputDirectory = Join-Path $repoRoot 'dist'
$null = New-Item -ItemType Directory -Path $outputDirectory -Force
$archivePath = Join-Path $outputDirectory ($addonName + '-' + $version + '.zip')
$pendingPath = Join-Path $outputDirectory ($addonName + '-' + [guid]::NewGuid().ToString('N') + '.tmp')
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::Open($pendingPath, [IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($path in $packagePaths) {
        $null = [IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $archive, $sources[$path], "$addonName/$path", [IO.Compression.CompressionLevel]::Optimal)
    }
} finally { $archive.Dispose() }

$archive = [IO.Compression.ZipFile]::OpenRead($pendingPath)
try {
    if ($archive.Entries.Count -ne $packagePaths.Count) { throw 'Incorrect archive entry count' }
    foreach ($path in $packagePaths) {
        $entry = @($archive.Entries | Where-Object { $_.FullName -ceq "$addonName/$path" })
        if ($entry.Count -ne 1) { throw "Missing archive entry: $path" }
        $stream = $entry[0].Open()
        $hasher = [Security.Cryptography.SHA256]::Create()
        try {
            $archiveHash = [BitConverter]::ToString($hasher.ComputeHash($stream)).Replace('-', '')
        } finally { $hasher.Dispose(); $stream.Dispose() }
        if ($archiveHash -ne (Get-FileHash -LiteralPath $sources[$path] -Algorithm SHA256).Hash) {
            throw "Archive content mismatch: $path"
        }
    }
} finally { $archive.Dispose() }

# Only replace the previous local build once the new ZIP has passed verification
Move-Item -LiteralPath $pendingPath -Destination $archivePath -Force
Write-Output "Built $archivePath"
Write-Output "Verified $($packagePaths.Count) files; version $version; interface $(Get-TocMetadata 'Interface')"
Get-FileHash -LiteralPath $archivePath -Algorithm SHA256
