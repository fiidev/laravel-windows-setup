# ==============================================================================
#  Laravel & PHP Windows Setup Automation Script
#  Target: Windows 10 / Windows 11
#  Components: XAMPP (PHP + SQLite + GD + Fileinfo + MySQL), Composer, Laravel, Postman
#  Author: fiidev (https://github.com/fiidev)
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "Laravel & PHP Development Setup - Windows"

# ------------------------------------------------------------------------------
# 0. Hak Akses Administrator (Auto-Elevation)
# ------------------------------------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "`n[!] Hak akses Administrator diperlukan untuk menginstall software dan mengonfigurasi System PATH." -ForegroundColor Yellow
    Write-Host "[*] Membuka jendela PowerShell baru sebagai Administrator..." -ForegroundColor Cyan
    
    if ($PSCommandPath) {
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    } else {
        $rawUrl = "https://raw.githubusercontent.com/fiidev/laravel-windows-setup/main/setup.ps1"
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"& { [scriptblock]::Create((Invoke-RestMethod -Uri '$rawUrl')) }`""
    }
    Exit
}

Clear-Host
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "       Laravel, PHP, XAMPP, SQLite & Postman Automated Setup          " -ForegroundColor Cyan
Write-Host "                       Created by @fiidev                             " -ForegroundColor DarkCyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

# Helper function untuk reload PATH di sesi PowerShell sekarang
function Refresh-EnvPath {
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machinePath;$userPath"
}

# Helper function menambahkan folder ke Machine PATH permanen
function Add-ToMachinePath {
    param ([string]$Folder)
    $current = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $parts = $current -split ';' | Where-Object { $_ -ne "" }
    if ($parts -notcontains $Folder) {
        $newPath = "$current;$Folder"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
        Write-Host "  -> Ditambahkan ke System PATH: $Folder" -ForegroundColor Gray
    }
}

# Helper function menambahkan folder ke User PATH permanen
function Add-ToUserPath {
    param ([string]$Folder)
    $current = [Environment]::GetEnvironmentVariable("Path", "User")
    $parts = $current -split ';' | Where-Object { $_ -ne "" }
    if ($parts -notcontains $Folder) {
        $newPath = if ([string]::IsNullOrEmpty($current)) { $Folder } else { "$current;$Folder" }
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Host "  -> Ditambahkan ke User PATH: $Folder" -ForegroundColor Gray
    }
}

# ------------------------------------------------------------------------------
# 1. Cek Winget
# ------------------------------------------------------------------------------
Write-Host "[1/7] Memeriksa Windows Package Manager (Winget)..." -ForegroundColor Green
$hasWinget = (Get-Command winget -ErrorAction SilentlyContinue) -ne $null
if ($hasWinget) {
    Write-Host "  -> Winget terdeteksi." -ForegroundColor Gray
} else {
    Write-Host "  [!] Winget tidak ditemukan. Script akan menggunakan fallback direct download jika diperlukan." -ForegroundColor Yellow
}

# ------------------------------------------------------------------------------
# 2. Cek & Install Git (Dibutuhkan Composer & Laravel)
# ------------------------------------------------------------------------------
Write-Host "`n[2/7] Memeriksa Git..." -ForegroundColor Green
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host "  -> Git sudah terpasang." -ForegroundColor Gray
} else {
    Write-Host "  -> Menginstall Git for Windows..." -ForegroundColor Yellow
    if ($hasWinget) {
        winget install --id Git.Git -e --silent --accept-package-agreements --accept-source-agreements
    }
    Refresh-EnvPath
}

# ------------------------------------------------------------------------------
# 3. Setup XAMPP
# ------------------------------------------------------------------------------
Write-Host "`n[3/7] Memeriksa instalasi XAMPP..." -ForegroundColor Green
$xamppRoot = "C:\xampp"
$phpDir = "C:\xampp\php"

if (Test-Path "$phpDir\php.exe") {
    Write-Host "  -> XAMPP sudah terpasang di $xamppRoot." -ForegroundColor Gray
} else {
    Write-Host "  -> Menginstall XAMPP via Winget..." -ForegroundColor Yellow
    if ($hasWinget) {
        winget install --id ApacheFriends.Xampp -e --silent --accept-package-agreements --accept-source-agreements
    }

    # Jika winget gagal atau tidak terpasang di C:\xampp
    if (-not (Test-Path "$phpDir\php.exe")) {
        Write-Host "  -> Mengunduh installer XAMPP langsung dari Apache Friends..." -ForegroundColor Yellow
        $installerUrl = "https://sourceforge.net/projects/xampp/files/XAMPP%20Windows/8.2.12/xampp-windows-x64-8.2.12-0-VS16-installer.exe/download"
        $installerDest = "$env:TEMP\xampp-installer.exe"
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerDest
        Write-Host "  -> Menjalankan installer XAMPP (silakan ikuti instruksi jika pop-up muncul)..." -ForegroundColor Yellow
        Start-Process -FilePath $installerDest -ArgumentList "--mode unattended" -Wait
    }
}

# Daftarkan PHP XAMPP ke PATH
Add-ToMachinePath $phpDir
Refresh-EnvPath

# ------------------------------------------------------------------------------
# 4. Konfigurasi php.ini (SQLite, File Upload, GD, Exif, Zip)
# ------------------------------------------------------------------------------
Write-Host "`n[4/7] Mengonfigurasi php.ini untuk SQLite & Fitur Upload File/Image..." -ForegroundColor Green
$phpIni = "$phpDir\php.ini"

if (-not (Test-Path $phpIni)) {
    if (Test-Path "$phpDir\php.ini-development") {
        Copy-Item "$phpDir\php.ini-development" $phpIni -Force
    } elseif (Test-Path "$phpDir\php.ini-production") {
        Copy-Item "$phpDir\php.ini-production" $phpIni -Force
    }
}

if (Test-Path $phpIni) {
    Copy-Item $phpIni "$phpIni.bak" -Force
    $content = Get-Content $phpIni -Raw

    # Ekstensi yang wajib aktif untuk Laravel & File Upload
    $extensions = @(
        "pdo_sqlite",
        "sqlite3",
        "fileinfo",
        "gd",
        "exif",
        "curl",
        "zip",
        "mbstring",
        "openssl",
        "pdo_mysql",
        "mysqli",
        "sodium"
    )

    foreach ($ext in $extensions) {
        if ($content -match ";\s*extension\s*=\s*$ext") {
            $content = $content -replace ";\s*extension\s*=\s*$ext", "extension=$ext"
        } elseif ($content -notmatch "(?m)^extension\s*=\s*$ext") {
            $content += "`nextension=$ext`n"
        }
    }

    # Optimasi limit upload & memori untuk upload gambar/video/dokumen
    $settings = [ordered]@{
        "upload_max_filesize" = "64M"
        "post_max_size"       = "64M"
        "memory_limit"        = "256M"
        "max_execution_time"  = "300"
        "max_input_time"      = "300"
        "max_file_uploads"    = "20"
        "file_uploads"        = "On"
    }

    foreach ($key in $settings.Keys) {
        $val = $settings[$key]
        if ($content -match "(?m)^;?\s*$key\s*=") {
            $content = $content -replace "(?m)^;?\s*$key\s*=.*$", "$key = $val"
        } else {
            $content += "`n$key = $val`n"
        }
    }

    [System.IO.File]::WriteAllText($phpIni, $content, [System.Text.Encoding]::UTF8)
    Write-Host "  -> php.ini berhasil dikonfigurasi!" -ForegroundColor Gray
    Write-Host "     - Ekstensi Aktif : pdo_sqlite, sqlite3, fileinfo, gd, exif, zip, openssl" -ForegroundColor Gray
    Write-Host "     - Limit Upload   : upload_max_filesize = 64M, post_max_size = 64M" -ForegroundColor Gray
    Write-Host "     - Memory Limit   : 256M" -ForegroundColor Gray
} else {
    Write-Host "  [!] File php.ini belum ditemukan di $phpIni." -ForegroundColor Yellow
}

# ------------------------------------------------------------------------------
# 5. Setup Composer
# ------------------------------------------------------------------------------
Write-Host "`n[5/7] Memeriksa Composer..." -ForegroundColor Green
Refresh-EnvPath
if (Get-Command composer -ErrorAction SilentlyContinue) {
    Write-Host "  -> Composer sudah terpasang." -ForegroundColor Gray
} else {
    Write-Host "  -> Menginstall Composer via Winget..." -ForegroundColor Yellow
    if ($hasWinget) {
        winget install --id Composer.Composer -e --silent --accept-package-agreements --accept-source-agreements
    }

    Refresh-EnvPath
    if (-not (Get-Command composer -ErrorAction SilentlyContinue)) {
        Write-Host "  -> Mengunduh Composer-Setup.exe langsung..." -ForegroundColor Yellow
        $composerInstaller = "$env:TEMP\Composer-Setup.exe"
        Invoke-WebRequest -Uri "https://getcomposer.org/Composer-Setup.exe" -OutFile $composerInstaller
        Start-Process -FilePath $composerInstaller -ArgumentList "/VERYSILENT" -Wait
    }
}

Refresh-EnvPath

# ------------------------------------------------------------------------------
# 6. Setup Laravel Installer CLI
# ------------------------------------------------------------------------------
Write-Host "`n[6/7] Memeriksa Laravel Installer..." -ForegroundColor Green
$composerBin = "$env:APPDATA\Composer\vendor\bin"
Add-ToUserPath $composerBin
Refresh-EnvPath

if (Get-Command laravel -ErrorAction SilentlyContinue) {
    Write-Host "  -> Laravel CLI sudah terpasang." -ForegroundColor Gray
} else {
    Write-Host "  -> Memasang Laravel Installer secara global..." -ForegroundColor Yellow
    if (Get-Command composer -ErrorAction SilentlyContinue) {
        composer global require laravel/installer --quiet
        Refresh-EnvPath
        Write-Host "  -> Laravel Installer berhasil dipasang!" -ForegroundColor Gray
    } else {
        Write-Host "  [!] Composer belum siap di sesi ini. Jalankan 'composer global require laravel/installer' nanti." -ForegroundColor Yellow
    }
}

# ------------------------------------------------------------------------------
# 7. Setup Postman
# ------------------------------------------------------------------------------
Write-Host "`n[7/7] Memeriksa Postman..." -ForegroundColor Green
$postmanLocalPath = "$env:LOCALAPPDATA\Postman\app-*\Postman.exe"
$postmanExists = (Get-Command postman -ErrorAction SilentlyContinue) -ne $null -or (Test-Path $postmanLocalPath)

if ($postmanExists) {
    Write-Host "  -> Postman sudah terpasang." -ForegroundColor Gray
} else {
    Write-Host "  -> Menginstall Postman via Winget..." -ForegroundColor Yellow
    if ($hasWinget) {
        winget install --id Postman.Postman -e --silent --accept-package-agreements --accept-source-agreements
    }

    if (-not (Get-Command postman -ErrorAction SilentlyContinue) -and -not (Test-Path $postmanLocalPath)) {
        Write-Host "  -> Mengunduh Postman installer langsung..." -ForegroundColor Yellow
        $postmanInstaller = "$env:TEMP\Postman-Setup.exe"
        Invoke-WebRequest -Uri "https://dl.pstmn.io/download/latest/win64" -OutFile $postmanInstaller
        Start-Process -FilePath $postmanInstaller -ArgumentList "/silent" -Wait
    }
}

# ------------------------------------------------------------------------------
# Selesai & Informasi Verifikasi
# ------------------------------------------------------------------------------
Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "           SETUP SELESAI! LINGKUNGAN DEV SIAP DIGUNAKAN               " -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Langkah Verifikasi:" -ForegroundColor White
Write-Host "1. Tutup jendela terminal ini dan BUKA TERMINAL BARU (PowerShell/CMD/Git Bash)." -ForegroundColor Yellow
Write-Host "2. Uji instalasi dengan perintah berikut:" -ForegroundColor White
Write-Host "   - php -v        (Verifikasi PHP dari XAMPP)" -ForegroundColor Gray
Write-Host "   - php -m        (Lihat modul: pdo_sqlite, sqlite3, fileinfo, gd, dll)" -ForegroundColor Gray
Write-Host "   - composer -v   (Verifikasi Composer)" -ForegroundColor Gray
Write-Host "   - laravel -v    (Verifikasi Laravel Installer)" -ForegroundColor Gray
Write-Host "   - postman       (Buka aplikasi Postman)" -ForegroundColor Gray
Write-Host ""
Write-Host "Cara cepat buat project Laravel + SQLite + File Upload:" -ForegroundColor White
Write-Host "   laravel new my-app --database=sqlite --no-interaction" -ForegroundColor Cyan
Write-Host "   cd my-app" -ForegroundColor Cyan
Write-Host "   php artisan storage:link" -ForegroundColor Cyan
Write-Host "   php artisan serve" -ForegroundColor Cyan
Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan
