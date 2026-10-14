# 🚀 Laravel & PHP Windows Setup Automation

Script otomasi PowerShell untuk menyiapkan lingkungan pengembangan **PHP**, **Laravel**, **XAMPP**, **SQLite**, dan **Postman** di **Windows 10 / Windows 11** hanya dengan satu baris perintah!

---

## ⚡ Quick Start (Jalankan Sekali Klik)

Buka **PowerShell** (atau Windows Terminal), lalu jalankan perintah berikut:

```powershell
irm https://raw.githubusercontent.com/fiidev/laravel-windows-setup/main/setup.ps1 | iex
```

> **Catatan:** Jika belum membuka sebagai Administrator, script akan secara otomatis memunculkan pop-up UAC meminta izin Administrator (*Auto-Elevation*).

---

## 🛠️ Apa Saja yang Dikonfigurasi?

1. **XAMPP (PHP 8.2+)**:
   - Terpasang otomatis di `C:\xampp`.
   - Menambahkan `C:\xampp\php` ke **System PATH** permanen (sehingga perintah `php` bisa dipanggil langsung dari PowerShell, CMD, Git Bash, atau VS Code).
2. **Optimasi `php.ini`**:
   - Mengaktifkan ekstensi **SQLite** (`pdo_sqlite`, `sqlite3`).
   - Mengaktifkan ekstensi **Upload & Pengolahan Gambar/File** (`fileinfo`, `gd`, `exif`, `zip`, `openssl`, `mbstring`, `curl`).
   - Menaikkan limit upload dari default 2MB ke **64MB** (`upload_max_filesize = 64M`, `post_max_size = 64M`, `memory_limit = 256M`).
3. **Git for Windows**:
   - Dipasang otomatis jika belum ada (dibutuhkan Composer dan Git version control).
4. **Composer**:
   - Terpasang via Winget atau installer resmi.
5. **Laravel Installer**:
   - `laravel` CLI terpasang secara global (`composer global require laravel/installer`).
   - Menambahkan `$env:APPDATA\Composer\vendor\bin` ke User PATH.
6. **Postman**:
   - Aplikasi desktop Postman terpasang dan siap digunakan untuk testing API.

---

## 🧪 Verifikasi Instalasi

Setelah script selesai dijalankan, tutup terminal lama dan buka **Terminal baru**:

```powershell
php -v
php -m          # Pastikan pdo_sqlite, sqlite3, gd, dan fileinfo muncul
composer -v
laravel -v
postman
```

---

## 📂 Contoh Membuat Project Laravel + SQLite + Upload File

Di dalam repo ini disediakan script scaffolding otomatis:

```powershell
# Jalankan helper scaffold demo
powershell -ExecutionPolicy Bypass -File .\scaffold-upload-demo.ps1 -ProjectName my-upload-api
```

Atau lakukan secara manual:

```powershell
# 1. Buat project baru dengan database SQLite
laravel new my-app --database=sqlite --no-interaction
cd my-app

# 2. Hubungkan symlink storage agar gambar/file di storage bisa diakses publik
php artisan storage:link

# 3. Jalankan server lokal
php artisan serve
```

---

## 📮 Testing Upload File dengan Postman

1. Buka aplikasi **Postman**.
2. Klik tombol **Import** di kiri atas.
3. Pilih file [`Laravel_Upload_Test.postman_collection.json`](./Laravel_Upload_Test.postman_collection.json) dari repository ini.
4. Buka request **Upload Image or File**.
5. Masuk ke tab **Body** -> **form-data**.
6. Pada baris `file`, klik dan pilih file/foto yang ingin diunggah.
7. Klik **Send**. Response akan menampilkan URL gambar dan detail file yang sukses tersimpan!

---

## ❓ FAQ & Troubleshooting

<details>
<summary><b>Script tidak bisa jalan karena Execution Policy?</b></summary>

Jalankan perintah ini di PowerShell sebelum menjalankan script:
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```
</details>

<details>
<summary><b>Perintah php atau composer belum dikenali?</b></summary>

Tutup jendela terminal kamu lalu buka kembali terminal baru agar perubahan variabel lingkungan (`PATH`) Windows dimuat ulang oleh sistem.
</details>

---

## 📄 Lisensi

Distributed under the [MIT License](./LICENSE). Dibuat dengan ❤️ oleh [@fiidev](https://github.com/fiidev).
