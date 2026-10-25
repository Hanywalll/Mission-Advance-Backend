# TEMPLATE DOKUMENTASI SKEMA DATABASE
**Mission 1 — FSD-20 (Back-End Developer Node.js)**  
**Projek:** Perancangan Basis Data Aplikasi Streaming Film "Chill"  
**RDBMS Target:** MySQL 8.0+ / MariaDB 10.5+ (Kompatibel dengan PostgreSQL)  

---

> 📝 **Petunjuk:** Dokumen ini adalah laporan dokumentasi teknis acuan perancangan basis data untuk Mission 1. Gambar ERD dibuat dan dilampirkan **TERPISAH** dari dokumen ini dalam file `erd_chill_movie_app.drawio` dan `erd_chill_movie_app.svg` (atau diekspor ke `.png` / `.pdf`), sesuai instruksi pengumpulan tugas.

---

## 1. Naming Convention

Berikut adalah aturan penamaan objek database (tabel, kolom, key, constraint, dan index) yang diimplementasikan secara konsisten di seluruh skema basis data aplikasi streaming **Chill**:

| Objek | Aturan | Contoh |
| :--- | :--- | :--- |
| **Nama tabel** | `snake_case`, bentuk jamak (*plural*), seluruh huruf kecil (*lowercase*) | `users`, `packages`, `orders`, `payments`, `films`, `genres`, `film_genres`, `episodes`, `my_lists` |
| **Nama kolom** | `snake_case`, huruf kecil, deskriptif, melarang singkatan ambigu | `full_name`, `password_hash`, `duration_days`, `total_amount`, `payment_method` |
| **Primary Key** | Selalu bernama `id`, tipe integer besar tanpa tanda (`BIGINT UNSIGNED`) auto-increment | `id` |
| **Foreign Key** | Pola `{nama_tabel_singular}_id`, merujuk langsung ke Primary Key (`id`) tabel induk | `user_id`, `package_id`, `order_id`, `film_id`, `genre_id` |
| **Kolom boolean** | Diawali prefix `is_` atau `has_` untuk menegaskan kondisi logika boolean (0/1 atau true/false) | `is_active`, `is_premium`, `is_published` |
| **Kolom timestamp** | Menggunakan akhiran `_at` untuk mencatat waktu kejadian spesifik | `created_at`, `updated_at`, `paid_at` |
| **Kolom tanggal murni** | Menggunakan akhiran `_date` untuk tipe data tanggal murni (*date-only*) | `start_date`, `end_date`, `release_date` |
| **Kolom unik (bukan PK)** | Nama deskriptif sesuai konteks bisnis, ditandai `UNIQUE` constraint | `email`, `slug`, `order_code`, `payment_code` |
| **Nama index** | Pola `idx_{nama_tabel}_{nama_kolom}` | `idx_orders_user_id`, `idx_films_type_published`, `idx_orders_user_status` |
| **Nama constraint FK** | Pola `fk_{nama_tabel_anak}_{nama_tabel_induk}` | `fk_orders_users`, `fk_orders_packages`, `fk_payments_orders`, `fk_episodes_films` |
| **Nama constraint Unique** | Pola `uq_{nama_tabel}_{nama_kolom}` | `uq_users_email`, `uq_films_slug`, `uq_my_lists_user_film` |

---

### Alasan Pemilihan Konvensi Ini:

1. **Kompatibilitas RDBMS Multi-Platform (*Cross-OS Case-Insensitivity*)**  
   Penggunaan gaya penulisan `snake_case` dengan huruf kecil (*all lowercase*) memastikan skema basis data berjalan konsisten tanpa risiko galat (*error*) di berbagai sistem operasi. Pada sistem operasi berbasis Linux (*case-sensitive*), nama tabel seperti `UserOrders` dan `userorders` diperlakukan sebagai dua tabel berbeda, sementara di Windows (*case-insensitive*) keduanya dianggap sama. Standarisasi `snake_case` huruf kecil menghindarkan potensi kegagalan migrasi dan query antara lingkungan *development* lokal (misalnya Laragon / Windows) dan lingkungan *production server* (Ubuntu / Debian).

2. **Semantik Jamak (*Plural*) untuk Tabel dan Tunggal (*Singular*) untuk Entitas Record**  
   Tabel dalam basis data relasional merepresentasikan kumpulan (*collection/set*) dari banyak baris data, sehingga penamaan jamak (`users`, `films`, `packages`, `orders`) secara gramatikal dan semantik paling akurat menggambarkan wadah kumpulan entitas tersebut. Sebaliknya, saat diakses sebagai baris data tunggal atau model objek dalam kode program Node.js, entitas disebut secara tunggal (misal: objek `user`, `order`).

3. **Kemudahan Keterbacaan Relasi Melalui Pola `{singular_table}_id`**  
   Format nama foreign key yang seragam (`user_id`, `film_id`, `package_id`) secara instan menginformasikan relasi tabel induk asal tanpa perlu membuka dokumentasi kamus data. Pengembang back-end dapat langsung mengetahui bahwa kolom `user_id` pada tabel `orders` merujuk ke kolom `id` pada tabel `users`. Hal ini juga mempermudah penulisan klausa join seperti `JOIN users ON users.id = orders.user_id` atau sintaks `USING(user_id)`.

4. **Standar Konvensi Otomatisasi ORM Modern pada Ekosistem Node.JS**  
   Ekosistem back-end Node.js sangat umum menggunakan Object-Relational Mapping (ORM) seperti Prisma, Sequelize, TypeORM, atau Knex.js. Framework dan ORM tersebut mengadopsi standar konvensi internasional: primary key bernama `id`, foreign key berakhiran `_id`, serta kolom timestamp `created_at` dan `updated_at`. Mengikuti aturan ini memungkinkan ORM mendeteksi relasi (*relations mapping*), *eager loading*, dan *timestamp lifecycle hooks* secara otomatis (*out-of-the-box*) tanpa konfigurasi pemetaan manual yang berlebihan (*zero boilerplate*).

---

## 2. Daftar Tabel dan Relasi

Berdasarkan analisis kebutuhan fungsional pada aplikasi streaming **"Chill"** (yang mencakup penjelajahan katalog film/series, filter genre, penambahan ke daftar tontonan pribadi "Daftar Saya", hingga transaksi pembelian paket berlangganan), berikut adalah daftar tabel utama beserta relasi antar-entitas:

| Tabel Induk | Tabel Anak | Kardinalitas | Foreign Key | Penjelasan Relasi |
| :--- | :--- | :---: | :--- | :--- |
| `users` | `orders` | **1 : N** | `orders.user_id` | Satu pengguna (*user*) dapat membuat banyak pesanan paket langganan (*orders*) sepanjang waktu, namun setiap transaksi pesanan hanya dimiliki oleh satu pengguna terdaftar. Dilengkapi `ON DELETE CASCADE`. |
| `packages` | `orders` | **1 : N** | `orders.package_id` | Satu paket langganan (*package*) dapat dipilih dan dibeli dalam banyak transaksi pesanan oleh berbagai pengguna, tetapi satu pesanan hanya merujuk pada satu paket langganan tertentu. Menggunakan `ON DELETE RESTRICT` agar paket yang sudah memiliki riwayat pesanan tidak terhapus secara tidak sengaja. |
| `orders` | `payments` | **1 : N** | `payments.order_id` | Satu pesanan (*order*) dapat memiliki satu atau lebih catatan riwayat percobaan pembayaran (*payments*). Hal ini mengakomodasi skenario di mana pengguna gagal di percobaan pertama (misal: saldo tidak cukup atau QRIS kadaluwarsa) dan mencoba kembali dengan metode pembayaran lain untuk order yang sama hingga sukses (*settlement*). Dilengkapi `ON DELETE CASCADE`. |
| `users` | `my_lists` | **1 : N** | `my_lists.user_id` | Satu pengguna dapat menambahkan banyak judul film atau series ke dalam daftar tontonan favoritnya (**"Daftar Saya"**). Dilengkapi `ON DELETE CASCADE`. |
| `films` | `my_lists` | **1 : N** | `my_lists.film_id` | Satu film/series dapat dimasukkan ke dalam daftar tontonan (**"Daftar Saya"**) oleh banyak pengguna sekaligus. Relasi antara `users` dan `films` membentuk relasi **Many-to-Many (M : N)** dengan tabel `my_lists` sebagai *junction table*. Dilengkapi `ON DELETE CASCADE`. |
| `films` | `episodes` | **1 : N** | `episodes.film_id` | Satu judul konten pada katalog `films` memiliki satu atau lebih media tayang di tabel `episodes`. Jika tipe konten adalah `'movie'`, maka terdapat tepat 1 baris episode (media film utama). Jika tipe konten adalah `'series'`, maka memiliki banyak episode yang dikelompokkan berdasarkan nomor musim (*season*) dan nomor episode (*episode_number*). Dilengkapi `ON DELETE CASCADE`. |
| `films` | `film_genres` | **1 : N** | `film_genres.film_id` | Satu judul film/series dapat memiliki banyak kategori genre (misalnya "Alice in Borderland" bergenre Action, Sci-Fi, dan Thriller sekaligus). Dilengkapi `ON DELETE CASCADE`. |
| `genres` | `film_genres` | **1 : N** | `film_genres.genre_id` | Satu genre dapat menaungi banyak judul film/series yang terdaftar di platform. Hubungan antara `films` dan `genres` membentuk relasi **Many-to-Many (M : N)** melalui *junction table* `film_genres`. Dilengkapi `ON DELETE CASCADE`. |

---

### Catatan Desain Relasi:

1. **Junction Table untuk Normalisasi Relasi Many-to-Many (M : N)**  
   - **`film_genres`**: Dalam dunia perfilman, satu film hampir selalu memiliki lebih dari satu kategori genre, dan satu genre tentu memayungi ratusan film. Menyimpan genre dalam kolom teks sederhana (seperti `genre: "Action, Drama"`) melanggar kaidah normalisasi Pertama (1NF) dan menyulitkan query pencarian serta pengindeksan. Oleh karena itu, dibuat *junction table* `film_genres` dengan *composite unique constraint* `(film_id, genre_id)` untuk memastikan tidak ada duplikasi genre pada film yang sama.
   - **`my_lists`**: Fitur **"Daftar Saya"** yang tampak pada navigasi header Figma Chill adalah perwujudan relasi *Many-to-Many* antara `users` dan `films`. Tabel `my_lists` bertindak sebagai *junction table* yang menghubungkan `user_id` dan `film_id`, disertai aturan integritas data `UNIQUE(user_id, film_id)` sehingga pengguna tidak dapat menambahkan film yang sama dua kali.

2. **Pola Desain Terpadu (*Single Catalog Pattern*) untuk Series dan Film**  
   Pada brief terdapat entitas **"Series/Film"** dan **"Episode/Movie"**. Dalam perancangan arsitektur basis data platform video on demand (seperti Netflix atau Disney+), film lepas (*single movie*) dan serial televisi (*series*) memiliki 90% kesamaan atribut: judul (*title*), sinopsis, poster, rating umur (*age rating*), rating pengguna (*user rating*), dan trailer.  
   - Menggabungkannya ke dalam satu tabel katalog utama `films` dengan kolom diskriminator `type ENUM('movie', 'series')` memberikan keuntungan performa yang masif: query untuk halaman beranda (*homepage*), filter genre, fitur pencarian (*search bar*), dan "Daftar Saya" dapat dijalankan secara langsung tanpa perlu melakukan operasi `UNION` antar tabel yang lambat.  
   - File video fisik dan detail pemutaran (*runtime*) dipisahkan ke tabel `episodes`. Untuk film (*movie*), tabel `episodes` menyimpan 1 baris record dengan nomor episode 1, sedangkan untuk serial (*series*), tabel `episodes` menyimpan puluhan record dengan nomor *season* dan *episode* masing-masing.

3. **Kardinalitas Fleksibel 1 : N Antara `orders` dan `payments`**  
   Alih-alih membuat relasi 1 : 1 yang kaku antara pesanan dan pembayaran, relasi 1 : N dipilih secara sengaja untuk mencerminkan mekanisme *Payment Gateway* dunia nyata (seperti Midtrans atau Xendit). Pengguna sering kali membuat order, memilih metode QRIS, membatalkannya, lalu mencoba kembali menggunakan metode Transfer Bank atau Kartu Kredit. Dengan relasi 1 : N, sistem dapat menyimpan seluruh riwayat *payment attempt* dan mencatat *webhook payload* secara transparan untuk keperluan audit finansial, dengan aturan bisnis bahwa pesanan dianggap lunas jika salah satu pembayaran memiliki status `'settlement'`.

4. **Integritas Referensial dengan `ON DELETE CASCADE` dan `ON DELETE RESTRICT`**  
   - Relasi data yang bersifat dependen langsung terhadap entitas induk (seperti episode milik film, item dalam Daftar Saya milik user, atau log pembayaran milik order) dikonfigurasi dengan aturan `ON DELETE CASCADE`. Artinya jika sebuah film dihapus dari katalog, seluruh episode dan kaitannya di daftar pengguna akan otomatis dibersihkan oleh RDBMS, mencegah timbulnya *orphaned records*.
   - Khusus relasi antara `packages` dan `orders` digunakan `ON DELETE RESTRICT`. Jika admin ingin menghapus suatu paket langganan, RDBMS akan menolak penghapusan apabila sudah terdapat data order yang mengaitkan paket tersebut. Langkah ini melindungi integritas data histori transaksi finansial perusahaan.

---

## 3. Justifikasi Tipe Data per Kolom

Berikut adalah rincian lengkap atribut pada setiap tabel beserta justifikasi pemilihan tipe data berdasarkan batas kapasitas nilai, efisiensi alokasi memori, kepatuhan integritas, dan persiapan skalabilitas sistem jangka panjang (*right-sizing*).

---

### Tabel: `users`
Menyimpan kredensial autentikasi pengguna, peran hak akses, dan status profil.

| Kolom | Tipe Data | Justifikasi Pemilihan Tipe Data |
| :--- | :--- | :--- |
| `id` | `BIGINT UNSIGNED` (PK, Auto Increment) | Menggunakan 8 byte dengan rentang nilai 0 hingga 18,44 triliun (18.446.744.073.709.551.615). Menjamin sistem tidak akan mengalami kehabisan kapasitas ID (*ID exhaustion*) saat jumlah pengguna aplikasi bertumbuh secara eksponensial di masa depan. |
| `full_name` | `VARCHAR(100)` | Alokasi dinamis hingga 100 karakter sudah sangat memadai untuk menampung nama lengkap pengguna dari berbagai negara tanpa membuang memori penyimpanan secara berlebih. |
| `email` | `VARCHAR(150)` (UNIQUE) | Standar alamat email RFC 5321 membatasi hingga 254 karakter. Kapasitas 150 karakter mencakup 99,9% alamat email nyata di dunia dan lebih efisien saat dibuatkan B-Tree Unique Index dibandingkan panjang maksimal. |
| `password_hash` | `VARCHAR(255)` | Digunakan untuk menyimpan string hasil hashing kata sandi satu arah yang aman menggunakan algoritma standar industri seperti `bcrypt` (panjang 60 karakter) atau `Argon2id` (panjang 90-128 karakter) beserta garam (*salt*). Ukuran 255 memberikan fleksibilitas jika sistem melakukan migrasi algoritma hash di kemudian hari. |
| `avatar_url` | `VARCHAR(255)` NULL | Menyimpan alamat URL file foto profil pengguna yang di-host pada penyimpanan Cloud Object Storage (seperti AWS S3 atau Google Cloud Storage). Kolom boleh bernilai `NULL` jika pengguna menggunakan avatar default. |
| `role` | `ENUM('admin', 'user')` | Digunakan untuk otorisasi kontrol akses (*Role-Based Access Control* / RBAC). Tipe `ENUM` disimpan secara internal oleh RDBMS sebagai bilangan bulat kecil (1 byte), jauh lebih hemat memori dibanding `VARCHAR` dan otomatis memvalidasi bahwa nilai yang masuk hanyalah `'admin'` atau `'user'`. |
| `is_active` | `BOOLEAN` (`TINYINT(1)`) | Flag penanda status keaktifan akun pengguna (1 untuk aktif, 0 jika akun disuspend). Menggunakan 1 byte penyimpanan, sangat hemat dan kompatibel dengan tipe boolean di Node.js. |
| `created_at` | `TIMESTAMP` | Mencatat waktu pembuatan akun pengguna secara otomatis berbasis zona waktu UTC standar menggunakan default `CURRENT_TIMESTAMP`. |
| `updated_at` | `TIMESTAMP` | Mencatat waktu pembaruan profil terakhir secara otomatis menggunakan trigger bawaan RDBMS `ON UPDATE CURRENT_TIMESTAMP`. |

---

### Tabel: `packages` (Paket)
Menyimpan paket berlangganan konten berbayar (*VIP/Premium*).

| Kolom | Tipe Data | Justifikasi Pemilihan Tipe Data |
| :--- | :--- | :--- |
| `id` | `BIGINT UNSIGNED` (PK, Auto Increment) | Primary key standar konsisten bertipe integer 64-bit tanpa tanda. |
| `name` | `VARCHAR(50)` | Nama paket langganan (contoh: "Basic", "Standard", "Premium VIP"). Panjang 50 karakter sangat mencukupi kebutuhan penamaan produk pemasaran. |
| `slug` | `VARCHAR(50)` (UNIQUE) | String pengenal ramah URL (*URL-friendly identifier*) untuk routing API atau antarmuka frontend (misal: `/subscribe/premium-vip`). |
| `description` | `TEXT` NULL | Menyimpan deskripsi detail daftar benefit paket (seperti fitur unduhan offline, ketiadaan iklan, dll.). Tipe `TEXT` dialokasikan di luar halaman data utama (*off-page storage*) sehingga tidak memperlambat pembacaan kolom lainnya. |
| `price` | `DECIMAL(12, 2)` | Menyimpan nominal harga langganan. Sangat krusial menggunakan `DECIMAL` bertipe *fixed-point* (bukan `FLOAT` atau `DOUBLE`) untuk mencegah galat pembulatan desimal (*floating-point rounding errors*) pada operasi finansial mata uang Rupiah maupun mata uang asing. Format (12, 2) mampu menampung nilai hingga Rp 9.999.999.999,99. |
| `duration_days` | `SMALLINT UNSIGNED` | Menyimpan durasi aktif paket dalam satuan hari (contoh: 30, 90, 365 hari). Tipe 2 byte ini memiliki batas hingga 65.535 hari (lebih dari 170 tahun), sangat efisien dan pas untuk skala kebutuhan bisnis. |
| `max_resolution` | `VARCHAR(20)` | Keterangan resolusi tayangan maksimal yang diizinkan oleh paket (contoh: "720p", "1080p FHD", "4K HDR"). |
| `max_screens` | `TINYINT UNSIGNED` | Jumlah perangkat/layar yang diizinkan streaming bersamaan (contoh: 1, 2, atau 4 layar). Menggunakan 1 byte (rentang nilai 0 hingga 255), sangat hemat memori. |
| `is_active` | `BOOLEAN` (`TINYINT(1)`) | Menandai apakah paket sedang aktif dijual atau sudah diarsipkan/dinonaktifkan oleh manajemen aplikasi. |
| `created_at` | `TIMESTAMP` | Timestamp pencatatan awal pembuatan data paket. |
| `updated_at` | `TIMESTAMP` | Timestamp pembaruan data paket terakhir. |

---

### Tabel: `orders` (Order)
Menyimpan transaksi pemesanan langganan paket oleh pengguna.

| Kolom | Tipe Data | Justifikasi Pemilihan Tipe Data |
| :--- | :--- | :--- |
| `id` | `BIGINT UNSIGNED` (PK, Auto Increment) | Primary key untuk tabel transaksi dengan frekuensi penambahan data yang tinggi (*high insert rate*). |
| `order_code` | `VARCHAR(50)` (UNIQUE) | Kode unik transaksi pesanan yang mudah dibaca (*human-readable invoice code*) dan aman diekspos ke publik (contoh: `ORD-20261025-00129`). Diberi constraint `UNIQUE` untuk mencegah duplikasi pesanan. |
| `user_id` | `BIGINT UNSIGNED` (FK) | Foreign key yang merujuk pada tabel `users.id`. Tipe data dan tanda (*unsigned*) identik mutlak dengan tabel induk agar proses join efisien. |
| `package_id` | `BIGINT UNSIGNED` (FK) | Foreign key yang merujuk pada tabel `packages.id`. Menghubungkan paket yang dibeli. |
| `total_amount` | `DECIMAL(12, 2)` | Total nominal tagihan pesanan (termasuk pajak atau diskon). Menggunakan `DECIMAL` untuk presisi moneter mutlak. |
| `status` | `ENUM('pending', 'paid', 'cancelled', 'expired')` | Status siklus hidup transaksi pesanan. Dibatasi pada 4 status spesifik, memastikan integritas *state machine* aplikasi dan efisiensi penyimpanan (1 byte). |
| `start_date` | `TIMESTAMP` NULL | Waktu awal dimulainya masa aktif paket langganan. Bernilai `NULL` saat order masih berstatus `pending`, dan baru terisi saat pembayaran terkonfirmasi. |
| `end_date` | `TIMESTAMP` NULL | Waktu berakhirnya masa langganan (dihitung otomatis: `start_date` + `duration_days`). Digunakan sistem untuk pengecekan hak akses konten VIP pengguna secara cepat. |
| `created_at` | `TIMESTAMP` | Waktu saat invoice pesanan pertama kali digenerate oleh sistem. |
| `updated_at` | `TIMESTAMP` | Waktu saat terjadi perubahan status pesanan. |

---

### Tabel: `payments` (Pembayaran)
Menyimpan detail pembayaran dari gerbang pembayaran (*payment gateway*).

| Kolom | Tipe Data | Justifikasi Pemilihan Tipe Data |
| :--- | :--- | :--- |
| `id` | `BIGINT UNSIGNED` (PK, Auto Increment) | Primary key tabel riwayat transaksi pembayaran bertipe 64-bit integer. |
| `payment_code` | `VARCHAR(50)` (UNIQUE) | Kode referensi pembayaran unik dari gateway pembayaran atau sistem internal (contoh: `PAY-20261025-09871`) untuk menjamin sifat idempoten (*idempotency*) pada penanganan webhook. |
| `order_id` | `BIGINT UNSIGNED` (FK) | Foreign key merujuk ke tabel `orders.id`. |
| `payment_method` | `VARCHAR(50)` | Saluran metode pembayaran yang dipilih konsumen (contoh: `qris`, `bank_transfer_bca`, `gopay`, `credit_card`). |
| `payment_gateway` | `VARCHAR(50)` NULL | Nama penyedia layanan gerbang pembayaran pihak ketiga (contoh: "Midtrans", "Xendit"). |
| `amount` | `DECIMAL(12, 2)` | Jumlah dana riil yang dibayarkan oleh konsumen dalam transaksi tersebut. |
| `payment_status` | `ENUM('pending', 'settlement', 'failed', 'refunded', 'expired')` | Status status pembayaran dari gateway pembayaran. Status `'settlement'` menandakan dana telah berhasil diterima secara sah. |
| `paid_at` | `TIMESTAMP` NULL | Waktu pasti saat transaksi dinyatakan berhasil oleh payment gateway. Bernilai `NULL` jika belum dibayar atau gagal. |
| `payload_response` | `JSON` NULL | Menyimpan data respon mentah (*raw webhook response*) dari payment gateway dalam format JSON terstruktur untuk audit jejak digital dan penyelesaian sengketa transaksi tanpa perlu mengubah skema kolom tabel. |
| `created_at` | `TIMESTAMP` | Waktu log pembayaran dibuat. |
| `updated_at` | `TIMESTAMP` | Waktu status log pembayaran diperbarui. |

---

### Tabel: `genres` (Genre)
Menyimpan klasifikasi kategori konten tayangan.

| Kolom | Tipe Data | Justifikasi Pemilihan Tipe Data |
| :--- | :--- | :--- |
| `id` | `BIGINT UNSIGNED` (PK, Auto Increment) | Primary key standar konsisten bertipe integer 64-bit tanpa tanda. |
| `name` | `VARCHAR(50)` (UNIQUE) | Nama genre konten (contoh: "Action", "Drama", "Horror", "Sci-Fi"). Diberi constraint `UNIQUE` agar tidak terjadi duplikasi penamaan genre. |
| `slug` | `VARCHAR(50)` (UNIQUE) | Format penamaan ramah URL untuk kategori film (contoh: `/genre/sci-fi`). Memudahkan navigasi frontend dan pengindeksan mesin pencari (SEO). |
| `description` | `TEXT` NULL | Ringkasan penjelasan definisi kategori genre film yang bersangkutan. |
| `created_at` | `TIMESTAMP` | Timestamp pencatatan awal pembuatan genre. |
| `updated_at` | `TIMESTAMP` | Timestamp pembaruan data genre terakhir. |

---

### Tabel: `films` (Series/Film)
Katalog judul konten multimedia utama (mencakup film layar lebar dan serial televisi seperti pada desain Figma "Happiness" & "Alice in Borderland").

| Kolom | Tipe Data | Justifikasi Pemilihan Tipe Data |
| :--- | :--- | :--- |
| `id` | `BIGINT UNSIGNED` (PK, Auto Increment) | Primary key katalog film dengan pertumbuhan data berkelanjutan. |
| `title` | `VARCHAR(255)` | Judul utama tayangan (contoh: "Happiness", "Alice in Borderland"). Panjang 255 karakter sangat aman menampung judul film terpanjang sekalipun. |
| `slug` | `VARCHAR(255)` (UNIQUE) | String URL unik yang representatif dan ramah pengguna (contoh: `alice-in-borderland`) untuk endpoint API seperti `GET /api/v1/films/happiness`. |
| `synopsis` | `TEXT` | Ringkasan sinopsis cerita film/series. Tipe `TEXT` mampu menyimpan hingga 65.535 karakter, sangat ideal untuk uraian narasi cerita yang panjang. |
| `type` | `ENUM('movie', 'series')` | Menentukan jenis katalog secara tegas: apakah merupakan film mandiri (*movie*) atau serial bersambung (*series*). Sangat hemat memori (1 byte) dan mempercepat penyaringan query tab navigasi di Figma. |
| `release_year` | `SMALLINT UNSIGNED` | Tahun rilis perdana konten (contoh: 2020, 2021). Tipe `SMALLINT` (2 byte) efisien untuk angka 4 digit tahun dibanding `INT` standar (4 byte). |
| `age_rating` | `VARCHAR(10)` | Klasifikasi batas usia penonton (seperti terlihat pada mockup Figma: "18+", "13+", "SU"). Panjang 10 karakter sangat fleksibel untuk kode sensor rating lokal maupun internasional. |
| `poster_url` | `VARCHAR(255)` | Alamat URL gambar sampul (*poster/banner*) beresolusi tinggi yang ditampilkan pada halaman beranda aplikasi streaming. |
| `trailer_url` | `VARCHAR(255)` NULL | Alamat URL video cuplikan/trailer tayangan (misalnya YouTube URL atau HLS streaming link). Bersifat opsional (`NULL`). |
| `rating` | `DECIMAL(3, 1)` | Rata-rata skor ulasan penonton dengan rentang 0.0 sampai 10.0 (seperti badge "★ 4.5" di Figma). Menggunakan `DECIMAL(3,1)` menghemat memori penyimpanan dan menjamin presisi tampilan satu angka di belakang koma. |
| `is_premium` | `BOOLEAN` (`TINYINT(1)`) | Menandai apakah konten memerlukan paket langganan VIP aktif untuk menonton, atau dapat diakses secara gratis. |
| `is_published` | `BOOLEAN` (`TINYINT(1)`) | Status publikasi konten di katalog (1 = tayang, 0 = draf / disembunyikan admin). |
| `created_at` | `TIMESTAMP` | Timestamp pencatatan awal pembuatan data film. |
| `updated_at` | `TIMESTAMP` | Timestamp pembaruan metadata film terakhir. |

---

### Tabel: `film_genres` (Junction Table M:N)
Menghubungkan relasi banyak-ke-banyak (*Many-to-Many*) antara tabel `films` dan `genres`.

| Kolom | Tipe Data | Justifikasi Pemilihan Tipe Data |
| :--- | :--- | :--- |
| `id` | `BIGINT UNSIGNED` (PK, Auto Increment) | Primary key penanda unik setiap baris asosiasi. |
| `film_id` | `BIGINT UNSIGNED` (FK) | Merujuk ke `films.id`. Diberi index untuk mempermudah pemanggilan seluruh genre dari satu film tertentu. |
| `genre_id` | `BIGINT UNSIGNED` (FK) | Merujuk ke `genres.id`. Diberi index untuk mempermudah filtering katalog film berdasarkan genre terpilih. |
| `created_at` | `TIMESTAMP` | Timestamp waktu penautan genre pada film. |

*Catatan: Tabel ini memiliki aturan constraint `UNIQUE(film_id, genre_id)` untuk mencegah relasi ganda antara film dan genre yang sama.*

---

### Tabel: `episodes` (Episode/Movie)
Menyimpan file media tayang dan durasi video, baik untuk film mandiri maupun per episode serial TV.

| Kolom | Tipe Data | Justifikasi Pemilihan Tipe Data |
| :--- | :--- | :--- |
| `id` | `BIGINT UNSIGNED` (PK, Auto Increment) | Primary key untuk entitas media video individual. |
| `film_id` | `BIGINT UNSIGNED` (FK) | Merujuk ke entitas katalog induk `films.id`. Relasi `ON DELETE CASCADE` menjamin penghapusan otomatis seluruh file episode jika judul film dihapus. |
| `title` | `VARCHAR(255)` | Judul episode (contoh: "Episode 1: Game On" atau judul film untuk jenis konten *movie*). |
| `season_number` | `SMALLINT UNSIGNED` | Nomor musim penayangan serial (default bernilai 1). Untuk konten film tunggal, kolom ini tetap bernilai 1. |
| `episode_number` | `SMALLINT UNSIGNED` | Urutan penomoran episode dalam musim terkait (default bernilai 1). |
| `duration_minutes` | `SMALLINT UNSIGNED` | Durasi video dalam satuan menit (contoh: 45 menit, 120 menit). Menggunakan `SMALLINT UNSIGNED` (0 sampai 65.535) sangat ideal dan jauh lebih hemat dibanding `INT`. |
| `video_url` | `VARCHAR(500)` | URL jalur streaming video (contoh: playlist HLS `.m3u8` atau CDN streaming video asset). Alokasi 500 karakter mengantisipasi URL CDN yang panjang dengan parameter query token keamanan bertanda tangan (*signed URL token*). |
| `thumbnail_url` | `VARCHAR(255)` NULL | URL gambar *still-frame* pratinjau cuplikan episode. |
| `release_date` | `DATE` NULL | Tanggal rilis khusus untuk episode bersangkutan. Menggunakan tipe `DATE` (3 byte) karena hanya membutuhkan informasi kalender (YYYY-MM-DD) tanpa presisi jam/menit. |
| `created_at` | `TIMESTAMP` | Timestamp pembuatan data episode. |
| `updated_at` | `TIMESTAMP` | Timestamp pembaruan data episode terakhir. |

*Catatan: Tabel ini memiliki aturan constraint `UNIQUE(film_id, season_number, episode_number)` untuk menjamin integritas urutan episode per season.*

---

### Tabel: `my_lists` (Daftar Saya)
Menyimpan bookmark daftar tontonan favorit pengguna sesuai fitur **"Daftar Saya"** pada Figma.

| Kolom | Tipe Data | Justifikasi Pemilihan Tipe Data |
| :--- | :--- | :--- |
| `id` | `BIGINT UNSIGNED` (PK, Auto Increment) | Primary key penanda unik setiap entri item daftar tontonan. |
| `user_id` | `BIGINT UNSIGNED` (FK) | Merujuk ke `users.id`. Menandakan pemilik daftar tontonan. |
| `film_id` | `BIGINT UNSIGNED` (FK) | Merujuk ke `films.id`. Menandakan film/series yang disimpan. |
| `created_at` | `TIMESTAMP` | Waktu saat film ditambahkan ke dalam daftar. Sangat berguna untuk pengurutan tampilan antarmuka (menampilkan film yang baru saja ditambahkan di urutan teratas: `ORDER BY created_at DESC`). |

*Catatan: Diberikan aturan constraint `UNIQUE(user_id, film_id)` untuk memastikan seorang pengguna tidak dapat mem-bookmark film yang sama lebih dari satu kali.*

---

### Prinsip Umum Perancangan Tipe Data:
> **"Right-Sizing & Data Integrity First"**  
> Seluruh tipe data dipilih dengan prinsip sekecil dan seakurat mungkin sesuai domain nilai bisnis riil di lapangan. Tipe numerik dialokasikan dengan batas yang realistis (seperti `TINYINT` untuk jumlah layar, `SMALLINT` untuk durasi menit dan tahun, serta `BIGINT` hanya untuk Primary/Foreign Key berskala besar). Manipulasi nilai moneter diwajibkan menggunakan `DECIMAL` untuk mencegah galat presisi pecahan aritmatika desimal. Kolom status dengan kemungkinan nilai terbatas diwajibkan menggunakan `ENUM` untuk mengunci integritas data di level RDBMS sebelum mencapai lapisan aplikasi backend.

---

## 4. Strategi Indexing

Indexing merupakan struktur data B-Tree pada basis data relasional yang mempercepat operasi pencarian (`WHERE`), penyambungan tabel (`JOIN`), dan pengurutan data (`ORDER BY`). Berikut adalah strategi pengindeksan yang dirancang untuk mengoptimalkan performa aplikasi streaming **Chill**:

| Tabel | Kolom | Jenis Index | Alasan dan Skenario Penggunaan |
| :--- | :--- | :--- | :--- |
| `users` | `email` | **UNIQUE INDEX** | Mempercepat pencarian data kredensial saat autentikasi *Login* (`SELECT * FROM users WHERE email = ?`) dengan kompleksitas $O(\log N)$, sekaligus mencegah registrasi ganda dengan email yang sama di level database. |
| `packages` | `slug` | **UNIQUE INDEX** | Optimasi pencarian rincian paket berlangganan pada halaman katalog langganan berdasarkan parameter slug URL (contoh: `WHERE slug = 'premium'`). |
| `orders` | `order_code` | **UNIQUE INDEX** | Mempercepat pencarian status transaksi pesanan saat verifikasi webhook dari payment gateway dan pengecekan invoice oleh pelanggan. |
| `orders` | `user_id` | **SINGLE INDEX** | Mengoptimalkan operasi `JOIN` antara tabel `users` dan `orders`, serta mempercepat query riwayat pesanan milik pengguna (`WHERE user_id = ?`). |
| `orders` | `(user_id, status)` | **COMPOSITE INDEX** | Sangat penting untuk *middleware* autentikasi streaming. Setiap kali user memutar video berbayar, sistem mengecek hak akses langganan aktif pengguna (`WHERE user_id = ? AND status = 'paid'`). Composite index ini membuat query verifikasi berjalan seketika tanpa membaca seluruh baris data (*index-covered lookup*). |
| `payments` | `payment_code` | **UNIQUE INDEX** | Memastikan pemrosesan transaksi dari payment gateway bersifat *idempotent* (mencegah pencatatan ganda atas notifikasi webhook yang sama) dan pencarian transaksi instan. |
| `payments` | `order_id` | **SINGLE INDEX** | Mempercepat proses `JOIN` saat mengambil histori pembayaran dari pesanan tertentu (`WHERE order_id = ?`). |
| `payments` | `payment_status` | **SINGLE INDEX** | Mempercepat query penyaringan (*filtering*) pada dashboard analitik tim finance atau proses rekonsiliasi berkala oleh *background cron job* (misal: mencari seluruh pembayaran berstatus `'pending'` yang sudah kadaluwarsa). |
| `genres` | `slug` | **UNIQUE INDEX** | Mempercepat query routing halaman genre pada aplikasi (misal saat pengguna memilih menu dropdown *Genre* di navigasi header Figma). |
| `films` | `slug` | **UNIQUE INDEX** | Mempercepat akses detail tayangan pada halaman rincian film berdasarkan slug URL yang SEO-friendly (misal: `WHERE slug = 'happiness'`). |
| `films` | `(type, is_published)` | **COMPOSITE INDEX** | Mengakomodasi tombol navigasi utama pada Figma header: menu **"Series"** dan menu **"Film"**. Query seperti `WHERE type = 'series' AND is_published = TRUE` akan langsung terpenuhi dari indeks komposit tanpa melakukan *full table scan*. |
| `films` | `(rating DESC, release_year DESC)` | **COMPOSITE INDEX** | Mengoptimalkan query section halaman beranda seperti *"Film Populer"* atau *"Top Rated"* (`ORDER BY rating DESC, release_year DESC LIMIT 10`) sehingga basis data tidak perlu melakukan pemilahan memori yang berat (*filesort elimination*). |
| `film_genres` | `(film_id, genre_id)` | **COMPOSITE UNIQUE INDEX** | Menjamin integritas bahwa relasi film dan genre tidak pernah terduplikasi, sekaligus mempercepat *eager loading* genre dari daftar film. |
| `film_genres` | `genre_id` | **SINGLE INDEX** | Sangat krusial saat pengguna mengklik suatu kategori genre (misalnya "Action"), query mencari semua film dengan genre tersebut (`WHERE genre_id = ?`) dapat memanfaatkan indeks ini secara langsung untuk proses *join*. |
| `episodes` | `film_id` | **SINGLE INDEX** | Mempercepat pemanggilan seluruh daftar episode ketika halaman detail serial dibuka oleh penonton (`WHERE film_id = ?`). |
| `episodes` | `(film_id, season_number, episode_number)` | **COMPOSITE UNIQUE INDEX** | Menjamin tidak ada nomor episode yang sama dalam satu musim, serta mempercepat pemutaran video berikutnya (*load next episode*) pada antarmuka pemutar media. |
| `my_lists` | `(user_id, film_id)` | **COMPOSITE UNIQUE INDEX** | Menjamin integritas relasi bookmark pengguna tidak terduplikasi, sekaligus menjadi indeks pencarian daftar tontonan user. |
| `my_lists` | `film_id` | **SINGLE INDEX** | Berguna untuk analisis metrik popularitas konten di sisi back-end: menghitung berapa banyak pengguna yang mem-bookmark film tertentu (`WHERE film_id = ?`). |

---

### Pertimbangan Tambahan:

1. **Pengindeksan Otomatis Primary Key (Clustered Index)**  
   Pada mesin penyimpanan InnoDB MySQL, kolom `id` sebagai `PRIMARY KEY` secara otomatis dijadikan sebagai *Clustered Index*. Seluruh baris data pada tabel secara fisik disimpan dan diurutkan berdasarkan urutan B-Tree dari `id`. Hal ini memberikan kompleksitas waktu pencarian $O(\log N)$ dan akses instan saat record dipanggil melalui primary key.

2. **Pengindeksan Mandiri pada Seluruh Foreign Key**  
   Meskipun beberapa RDBMS membuat indeks otomatis saat foreign key didefinisikan, pemberian indeks eksplisit pada seluruh kolom foreign key (`user_id`, `package_id`, `order_id`, `film_id`, `genre_id`) adalah praktik terbaik (*best practice*). Indeks ini mencegah terjadinya penguncian tabel penuh (*table-level locking*) selama operasi `UPDATE` atau `DELETE` pada tabel induk yang berelasi dengan aturan `CASCADE`.

3. **Prinsip Prefiks Paling Kiri (*Leftmost-Prefix Rule*) pada Composite Index**  
   Penyusunan urutan kolom pada indeks komposit dirancang secara terencana. Sebagai contoh, indeks `(user_id, status)` pada tabel `orders` dapat melayani dua pola query sekaligus:
   - Query yang menyaring berdasarkan `user_id` DAN `status` (menggunakan kedua kolom indeks).
   - Query yang HANYA menyaring berdasarkan `user_id` (menggunakan kolom prefiks paling kiri).  
   Dengan menerapkan kaidah *leftmost-prefix*, kita tidak perlu membuat indeks tunggal tambahan pada `user_id`, sehingga menghemat memori RAM database buffer pool dan mempercepat operasi penulisan (*write performance*).

4. **Keseimbangan Biaya (*Trade-off*) antara Kecepatan Baca vs Tulis (B-Tree Maintenance Overhead)**  
   Setiap indeks tambahan membutuhkan ruang penyimpanan disk dan menambah beban proses saat operasi `INSERT`, `UPDATE`, dan `DELETE`, karena pohon indeks B-Tree harus ditata ulang (*rebalanced*). Oleh karena itu, indeks tidak dipasang sembarangan di seluruh kolom, melainkan hanya di kolom yang memiliki kardinalitas tinggi (*high selectivity*) dan frekuensi pemanggilan tinggi pada jalur kritis aplikasi (*hot query paths*).

5. **Evaluasi Rutin Menggunakan Profiling Query (`EXPLAIN / EXPLAIN ANALYZE`)**  
   Selama siklus hidup aplikasi di lingkungan produksi, pola query harus dievaluasi secara berkala menggunakan perintah `EXPLAIN ANALYZE`. Langkah ini dilakukan untuk mendeteksi potensi *bottleneck* seperti eksekusi *Full Table Scan* (tipe akses `ALL`), penggunaan temporary table yang tidak perlu, atau *filesort*, sehingga indeks dapat disesuaikan seiring bertambahnya volume data riil.

---
**— Akhir Dokumentasi Skema Database Mission 1 —**
