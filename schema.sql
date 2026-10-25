-- =====================================================================
-- DATABASE SCHEMA: CHILL MOVIE STREAMING APP
-- Mission 1 — FSD-20 (Back-End Developer Node.js)
-- Target RDBMS: MySQL 8.0+ / MariaDB 10.5+
-- Naming Convention: snake_case, plural tables, descriptive columns
-- =====================================================================

CREATE DATABASE IF NOT EXISTS chill_movie_db
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE chill_movie_db;

-- ---------------------------------------------------------------------
-- 1. TABEL: users
-- Menyimpan informasi akun pengguna dan hak akses platform
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    avatar_url VARCHAR(255) NULL,
    role ENUM('admin', 'user') NOT NULL DEFAULT 'user',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_users PRIMARY KEY (id),
    CONSTRAINT uq_users_email UNIQUE (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 2. TABEL: packages (Paket)
-- Menyimpan pilihan paket langganan berbayar (VIP/Premium)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS packages (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    slug VARCHAR(50) NOT NULL,
    description TEXT NULL,
    price DECIMAL(12, 2) NOT NULL,
    duration_days SMALLINT UNSIGNED NOT NULL,
    max_resolution VARCHAR(20) NOT NULL DEFAULT '1080p',
    max_screens TINYINT UNSIGNED NOT NULL DEFAULT 1,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_packages PRIMARY KEY (id),
    CONSTRAINT uq_packages_slug UNIQUE (slug)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 3. TABEL: orders (Order)
-- Menyimpan transaksi pemesanan langganan paket oleh pengguna
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS orders (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    order_code VARCHAR(50) NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    package_id BIGINT UNSIGNED NOT NULL,
    total_amount DECIMAL(12, 2) NOT NULL,
    status ENUM('pending', 'paid', 'cancelled', 'expired') NOT NULL DEFAULT 'pending',
    start_date TIMESTAMP NULL,
    end_date TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_orders PRIMARY KEY (id),
    CONSTRAINT uq_orders_order_code UNIQUE (order_code),
    CONSTRAINT fk_orders_users FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_orders_packages FOREIGN KEY (package_id) REFERENCES packages (id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexing untuk tabel orders
CREATE INDEX idx_orders_user_id ON orders (user_id);
CREATE INDEX idx_orders_package_id ON orders (package_id);
CREATE INDEX idx_orders_user_status ON orders (user_id, status);

-- ---------------------------------------------------------------------
-- 4. TABEL: payments (Pembayaran)
-- Menyimpan riwayat log transaksi pembayaran dari payment gateway
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS payments (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    payment_code VARCHAR(50) NOT NULL,
    order_id BIGINT UNSIGNED NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    payment_gateway VARCHAR(50) NULL,
    amount DECIMAL(12, 2) NOT NULL,
    payment_status ENUM('pending', 'settlement', 'failed', 'refunded', 'expired') NOT NULL DEFAULT 'pending',
    paid_at TIMESTAMP NULL,
    payload_response JSON NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_payments PRIMARY KEY (id),
    CONSTRAINT uq_payments_payment_code UNIQUE (payment_code),
    CONSTRAINT fk_payments_orders FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexing untuk tabel payments
CREATE INDEX idx_payments_order_id ON payments (order_id);
CREATE INDEX idx_payments_payment_status ON payments (payment_status);

-- ---------------------------------------------------------------------
-- 5. TABEL: genres (Genre)
-- Menyimpan kategori/genre konten film & serial TV
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS genres (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    slug VARCHAR(50) NOT NULL,
    description TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_genres PRIMARY KEY (id),
    CONSTRAINT uq_genres_name UNIQUE (name),
    CONSTRAINT uq_genres_slug UNIQUE (slug)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 6. TABEL: films (Series/Film)
-- Menyimpan entitas utama katalog film & serial TV
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS films (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL,
    synopsis TEXT NOT NULL,
    type ENUM('movie', 'series') NOT NULL DEFAULT 'movie',
    release_year SMALLINT UNSIGNED NOT NULL,
    age_rating VARCHAR(10) NOT NULL DEFAULT '13+',
    poster_url VARCHAR(255) NOT NULL,
    trailer_url VARCHAR(255) NULL,
    rating DECIMAL(3, 1) NOT NULL DEFAULT 0.0,
    is_premium BOOLEAN NOT NULL DEFAULT FALSE,
    is_published BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_films PRIMARY KEY (id),
    CONSTRAINT uq_films_slug UNIQUE (slug)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexing untuk tabel films
CREATE INDEX idx_films_type_published ON films (type, is_published);
CREATE INDEX idx_films_rating_year ON films (rating DESC, release_year DESC);

-- ---------------------------------------------------------------------
-- 7. TABEL: film_genres (Junction M:N Series/Film <-> Genre)
-- Menghubungkan relasi many-to-many antara film dan genre
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS film_genres (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    film_id BIGINT UNSIGNED NOT NULL,
    genre_id BIGINT UNSIGNED NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_film_genres PRIMARY KEY (id),
    CONSTRAINT uq_film_genres_film_genre UNIQUE (film_id, genre_id),
    CONSTRAINT fk_film_genres_films FOREIGN KEY (film_id) REFERENCES films (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_film_genres_genres FOREIGN KEY (genre_id) REFERENCES genres (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexing untuk tabel film_genres
CREATE INDEX idx_film_genres_genre_id ON film_genres (genre_id);

-- ---------------------------------------------------------------------
-- 8. TABEL: episodes (Episode/Movie)
-- Menyimpan file media video untuk film mandiri maupun tiap episode serial
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS episodes (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    film_id BIGINT UNSIGNED NOT NULL,
    title VARCHAR(255) NOT NULL,
    season_number SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    episode_number SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    duration_minutes SMALLINT UNSIGNED NOT NULL,
    video_url VARCHAR(500) NOT NULL,
    thumbnail_url VARCHAR(255) NULL,
    release_date DATE NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_episodes PRIMARY KEY (id),
    CONSTRAINT uq_episodes_film_season_ep UNIQUE (film_id, season_number, episode_number),
    CONSTRAINT fk_episodes_films FOREIGN KEY (film_id) REFERENCES films (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexing untuk tabel episodes
CREATE INDEX idx_episodes_film_id ON episodes (film_id);

-- ---------------------------------------------------------------------
-- 9. TABEL: my_lists (Daftar Saya / Watchlist)
-- Menyimpan daftar tontonan yang di-bookmark oleh pengguna
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS my_lists (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id BIGINT UNSIGNED NOT NULL,
    film_id BIGINT UNSIGNED NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_my_lists PRIMARY KEY (id),
    CONSTRAINT uq_my_lists_user_film UNIQUE (user_id, film_id),
    CONSTRAINT fk_my_lists_users FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_my_lists_films FOREIGN KEY (film_id) REFERENCES films (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexing untuk tabel my_lists
CREATE INDEX idx_my_lists_film_id ON my_lists (film_id);

-- ---------------------------------------------------------------------
-- DUMMY SEED DATA (Opsional untuk pengujian)
-- ---------------------------------------------------------------------
INSERT INTO packages (name, slug, description, price, duration_days, max_resolution, max_screens, is_active)
VALUES 
('Basic', 'basic', 'Kualitas 720p, 1 Layar Aktif', 35000.00, 30, '720p', 1, TRUE),
('Standard', 'standard', 'Kualitas Full HD 1080p, 2 Layar Aktif', 65000.00, 30, '1080p', 2, TRUE),
('Premium', 'premium', 'Kualitas Ultra HD 4K + HDR, 4 Layar Aktif', 99000.00, 30, '4K', 4, TRUE);

INSERT INTO genres (name, slug, description)
VALUES 
('Action', 'action', 'Film penuh adegan aksi laga menegangkan'),
('Drama', 'drama', 'Kisah naratif sarat konflik emosional'),
('Thriller', 'thriller', 'Kisah misteri dengan ketegangan tinggi'),
('Sci-Fi', 'sci-fi', 'Cerita bertema fiksi ilmiah dan teknologi');

INSERT INTO films (title, slug, synopsis, type, release_year, age_rating, poster_url, rating, is_premium, is_published)
VALUES 
('Happiness', 'happiness', 'Mengisahkan tentang kelompok orang yang berjuang untuk bertahan hidup di dalam sebuah gedung apartemen tertutup saat wabah penyakit menular mematikan melanda kota.', 'series', 2021, '18+', 'https://images.chill.com/posters/happiness.jpg', 4.8, TRUE, TRUE),
('Alice in Borderland', 'alice-in-borderland', 'Seorang gamer tanpa tujuan dan dua temannya menemukan diri mereka di Tokyo paralel di mana mereka dipaksa bersaing dalam permainan berbahaya untuk bertahan hidup.', 'series', 2020, '18+', 'https://images.chill.com/posters/alice-in-borderland.jpg', 4.5, TRUE, TRUE);

INSERT INTO film_genres (film_id, genre_id)
VALUES 
(1, 2), -- Happiness: Drama
(1, 3), -- Happiness: Thriller
(2, 1), -- Alice in Borderland: Action
(2, 3), -- Alice in Borderland: Thriller
(2, 4); -- Alice in Borderland: Sci-Fi
