<#
==============================================================================
  Helper Script: Scaffold Laravel Demo Project with SQLite & File Upload
  Author: fiidev (https://github.com/fiidev)
==============================================================================
#>

param (
    [string]$ProjectName = "laravel-upload-demo"
)

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "  Membuat Project Laravel: $ProjectName (SQLite + File Upload)         " -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

# 1. Buat project Laravel baru dengan SQLite
Write-Host "`n[1/5] Menjalankan 'laravel new $ProjectName' dengan database SQLite..." -ForegroundColor Green
laravel new $ProjectName --database=sqlite --no-interaction

if (-not (Test-Path $ProjectName)) {
    Write-Host "[!] Gagal membuat project Laravel." -ForegroundColor Red
    Exit 1
}

Push-Location $ProjectName

# 2. Pastikan file database sqlite ada & migrate
Write-Host "`n[2/5] Menyiapkan database SQLite & Migrasi..." -ForegroundColor Green
if (-not (Test-Path "database\database.sqlite")) {
    New-Item -ItemType File -Path "database\database.sqlite" -Force | Out-Null
}
php artisan migrate --force

# 3. Buat symlink storage (Wajib untuk upload file/gambar)
Write-Host "`n[3/5] Menjalankan 'php artisan storage:link'..." -ForegroundColor Green
php artisan storage:link

# 4. Install API route jika Laravel 11+
Write-Host "`n[4/5] Memastikan API routing aktif..." -ForegroundColor Green
if (-not (Test-Path "routes\api.php")) {
    php artisan install:api --no-interaction
}

# 5. Buat FileUploadController
Write-Host "`n[5/5] Membuat FileUploadController..." -ForegroundColor Green
$controllerDir = "app\Http\Controllers\Api"
if (-not (Test-Path $controllerDir)) {
    New-Item -ItemType Directory -Path $controllerDir -Force | Out-Null
}

$controllerCode = @'
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class FileUploadController extends Controller
{
    /**
     * Upload Single File / Image
     */
    public function upload(Request $request)
    {
        $request->validate([
            'file'  => 'required|file|max:51200', // Max 50MB
            'title' => 'nullable|string|max:100'
        ]);

        if ($request->hasFile('file')) {
            $file = $request->file('file');
            
            // Simpan ke storage/app/public/uploads
            $path = $file->store('uploads', 'public');

            return response()->json([
                'success' => true,
                'message' => 'File berhasil diunggah!',
                'data' => [
                    'original_name' => $file->getClientOriginalName(),
                    'path'          => $path,
                    'url'           => asset('storage/' . $path),
                    'size_bytes'    => $file->getSize(),
                    'mime_type'     => $file->getClientMimeType(),
                    'title'         => $request->input('title', 'Untitled')
                ]
            ], 201);
        }

        return response()->json([
            'success' => false,
            'message' => 'Tidak ada file yang terdeteksi.'
        ], 400);
    }
}
'@

Set-Content -Path "$controllerDir\FileUploadController.php" -Value $controllerCode -Encoding UTF8

# Tambahkan route ke routes/api.php
$apiRouteFile = "routes\api.php"
$routeContent = Get-Content $apiRouteFile -Raw
if ($routeContent -notmatch "FileUploadController") {
    $routeAppend = @"

use App\Http\Controllers\Api\FileUploadController;

Route::post('/upload', [FileUploadController::class, 'upload']);
"@
    Add-Content -Path $apiRouteFile -Value $routeAppend -Encoding UTF8
}

Pop-Location

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host " Project '$ProjectName' Siap Digunakan!                                " -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "Jalankan:" -ForegroundColor White
Write-Host "   cd $ProjectName" -ForegroundColor Yellow
Write-Host "   php artisan serve" -ForegroundColor Yellow
Write-Host "`nEndpoint upload: POST http://127.0.0.1:8000/api/upload (key: 'file')" -ForegroundColor White
