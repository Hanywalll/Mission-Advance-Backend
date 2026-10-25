# Mission-Advance-Backend
**Mission 1 — FSD-20 (Back-End Developer Node.js)**  
**Student:** Muhammad Burhanudin (20071)  
**Projek:** Perancangan Basis Data Aplikasi Streaming Film "Chill"

Repository ini berisi rancangan basis data lengkap, dokumentasi teknis, skrip DDL SQL, serta Entity Relationship Diagram (ERD) untuk aplikasi *Movie Streaming Platform* **"Chill"** berdasarkan analisis desain antarmuka Figma.

---

## 📁 Berkas Dokumentasi & Pengumpulan Misi

1. 📕 **[`Muhammad Burhanudin_20071_ Mission Advance Backend.pdf`](./Muhammad%20Burhanudin_20071_%20Mission%20Advance%20Backend.pdf)**  
   **Dokumen Laporan Resmi Pengumpulan Misi (PDF)** yang telah diekspor dan siap dikumpulkan ke Google Classroom / Formulir Misi.

2. 🖼️ **[`erd_chill_movie_app.jpg`](./erd_chill_movie_app.jpg)** & **[`erd_chill_movie_app.svg`](./erd_chill_movie_app.svg)**  
   Gambar Entity Relationship Diagram (ERD) resolusi tinggi untuk dilampirkan terpisah.

3. 📄 **[`Dokumentasi_Skema_Database_Mission_1.docx`](./Dokumentasi_Skema_Database_Mission_1.docx)**  
   Dokumen Word resmi template acuan tugas (dapat dibuka langsung di Google Docs).

4. 📝 **[`DOKUMENTASI_DATABASE_MISSION_1.md`](./DOKUMENTASI_DATABASE_MISSION_1.md)**  
   Dokumentasi teknis lengkap berbasis Markdown yang mencakup:
   - **Naming Convention** (Aturan penamaan objek DB dan 4 alasan teknis).
   - **Daftar Tabel & Relasi** (8 entitas brief + 1 junction table, kardinalitas, catatan arsitektur).
   - **Justifikasi Tipe Data** (Setiap kolom pada seluruh 9 tabel dengan analisis batas nilai dan efisiensi memori).
   - **Strategi Indexing** (Single, composite, unique index beserta optimasi B-Tree).

5. 📐 **[`erd_chill_movie_app.drawio`](./erd_chill_movie_app.drawio)**  
   Berkas diagram native Draw.io (dapat dibuka dan diedit di [app.diagrams.net](https://app.diagrams.net)).

6. 🗄️ **[`schema.sql`](./schema.sql)**  
   Skrip DDL SQL lengkap (MySQL 8.0+ / MariaDB) yang berisi definisi tabel, *foreign key constraints*, *composite unique indexes*, dan data *seeder* awal.

7. 🌐 **[`preview_erd.html`](./preview_erd.html)**  
   Halaman antarmuka interaktif lokal untuk mempratinjau ERD dan mengunduh berkas yang dibutuhkan.

---

## 🏛️ Desain Entitas & Relasi (ERD)

Aplikasi streaming **Chill** dirancang menggunakan 8 entitas utama dan 1 *junction table*:
- `users` : Akun pengguna dan otorisasi hak akses (*admin / user*).
- `packages` : Pilihan paket langganan berbayar (*VIP / Premium*).
- `orders` : Transaksi pemesanan langganan paket oleh pengguna.
- `payments` : Riwayat log percobaan transaksi pembayaran (*payment gateway*).
- `films` : Katalog utama film mandiri (*movie*) maupun serial bersambung (*series*).
- `genres` : Kategori genre film/series.
- `film_genres` : *Junction table* penanganan relasi Many-to-Many antara `films` dan `genres`.
- `episodes` : File video media tayang dan durasi penayangan.
- `my_lists` : *Junction table* fitur bookmark tontonan pribadi pengguna (**"Daftar Saya"**).

---

## 🛠️ Cara Import Database ke MySQL (Laragon / XAMPP)

```bash
# Masuk ke MySQL client dan eksekusi skrip schema.sql
mysql -u root -p < schema.sql
```
Atau buka **phpMyAdmin / DBeaver / HeidiSQL**, buat database baru atau langsung import file `schema.sql`.
