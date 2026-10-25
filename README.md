# Mission-Advance-Backend
**Mission 1 — FSD-20 (Back-End Developer Node.js)**  
**Projek:** Perancangan Basis Data Aplikasi Streaming Film "Chill"

Repository ini berisi rancangan basis data lengkap, dokumentasi teknis, skrip DDL SQL, serta Entity Relationship Diagram (ERD) untuk aplikasi *Movie Streaming Platform* **"Chill"** berdasarkan analisis desain antarmuka Figma.

---

## 📁 Daftar Berkas Projek

1. 📄 **[`Dokumentasi_Skema_Database_Mission_1.docx`](./Dokumentasi_Skema_Database_Mission_1.docx)**  
   Dokumen resmi acuan pengumpulan tugas (format Microsoft Word / siap dibuka langsung di Google Docs).

2. 📝 **[`DOKUMENTASI_DATABASE_MISSION_1.md`](./DOKUMENTASI_DATABASE_MISSION_1.md)**  
   Dokumentasi teknis lengkap berbasis Markdown yang mencakup:
   - **Naming Convention** (Aturan penamaan objek DB dan 4 alasan teknis).
   - **Daftar Tabel & Relasi** (8 entitas brief + 1 junction table, kardinalitas, catatan arsitektur).
   - **Justifikasi Tipe Data** (Setiap kolom pada seluruh tabel dengan analisis batas nilai dan efisiensi memori).
   - **Strategi Indexing** (Single, composite, unique index beserta alasan query dan B-Tree optimization).

3. 📐 **[`erd_chill_movie_app.drawio`](./erd_chill_movie_app.drawio)**  
   Berkas diagram native Draw.io (dapat dibuka dan diedit di [app.diagrams.net](https://app.diagrams.net)).

4. 🖼️ **[`erd_chill_movie_app.svg`](./erd_chill_movie_app.svg)**  
   Gambar vektor Entity Relationship Diagram (ERD) resolusi tinggi.

5. 🗄️ **[`schema.sql`](./schema.sql)**  
   Skrip DDL SQL lengkap (MySQL 8.0+ / MariaDB) yang berisi definisi tabel, *foreign key constraints*, *composite unique indexes*, dan data *seeder* dummy awal.

6. 🌐 **[`preview_erd.html`](./preview_erd.html)**  
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
