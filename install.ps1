$ErrorActionPreference = "Stop"

$Repo = "infraspecdev/goperf"
$ExeName = "goperf.exe"

$Version = if ($env:VERSION) { $env:VERSION } else { "latest" }
$BinDir  = if ($env:BIN_DIR) { $env:BIN_DIR } else { "$env:LOCALAPPDATA\goperf\bin" }

$RawArch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLower()
switch ($RawArch) {
    "x64"   { $Arch = "amd64" }
    "arm64" { $Arch = "arm64" }
    default { Write-Error "Unsupported architecture: $RawArch"; exit 1 }
}

if ($Arch -eq "arm64") {
    Write-Error "Windows ARM64 is not supported. Please build from source."
    exit 1
}

$BinaryName = "goperf-windows-${Arch}.exe"

if ($Version -eq "latest") {
    $BinaryUrl = "https://github.com/$Repo/releases/latest/download/$BinaryName"
} else {
    $BinaryUrl = "https://github.com/$Repo/releases/download/$Version/$BinaryName"
}

if (-not (Test-Path $BinDir)) {
    try {
        New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
    } catch {
        Write-Error "Cannot create directory: $BinDir`n$($_.Exception.Message)"
        exit 1
    }
}

Write-Host "Installing goperf..."
Write-Host "  Platform : windows/$Arch"
Write-Host "  Directory: $BinDir"

if ($Version -eq "latest") {
    Write-Host "  Downloading latest release..."
} else {
    Write-Host "  Downloading release $Version..."
}

$TmpFile = Join-Path ([System.IO.Path]::GetTempPath()) "goperf_$([System.Guid]::NewGuid().ToString('N')).exe"

try {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $BinaryUrl -OutFile $TmpFile -UseBasicParsing -ErrorAction Stop
} catch {
    Remove-Item -Path $TmpFile -Force -ErrorAction SilentlyContinue
    Write-Error @"
Failed to download binary from:
  $BinaryUrl

Possible reasons:
  - No internet connection
  - GitHub is unavailable
  - No release asset for windows/$Arch (version: $Version)

Browse releases manually:
  https://github.com/$Repo/releases
"@
    exit 1
}

if (-not (Test-Path $TmpFile) -or (Get-Item $TmpFile).Length -eq 0) {
    Remove-Item -Path $TmpFile -Force -ErrorAction SilentlyContinue
    Write-Error "Downloaded binary is empty or corrupted."
    exit 1
}

Write-Host "  Download complete 🎉"

$DestPath = Join-Path $BinDir $ExeName

try {
    Move-Item -Path $TmpFile -Destination $DestPath -Force
} catch {
    Remove-Item -Path $TmpFile -Force -ErrorAction SilentlyContinue
    Write-Error "Failed to install binary to $DestPath`n$($_.Exception.Message)"
    exit 1
}

Write-Host ""
Write-Host "✅ Installed: $DestPath"

$CurrentPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
if ($CurrentPath -notlike "*$BinDir*") {
    Write-Host ""
    Write-Host "  Note: '$BinDir' is not in your PATH."
    Write-Host ""
    Write-Host "  To add it permanently, run the following in PowerShell:"
    Write-Host ""
    Write-Host "    [System.Environment]::SetEnvironmentVariable('Path', `"$BinDir;`$env:Path`", 'User')"
    Write-Host ""
    Write-Host "  Then restart your terminal."
}

Write-Host ""
Write-Host "Run 'goperf --help' to get started."
