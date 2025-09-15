// src/utils/migrations.ts

import {
  executeWisakaQuery,
  executePerpustakaanQuery,
} from "../config/database";

export class DatabaseMigration {
  /**
   * Check if usulan_hapus column exists in krsmatakuliah table
   */
  private async checkUsulanHapusColumn(): Promise<boolean> {
    try {
      const sql = `
        SELECT COLUMN_NAME
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'krsmatakuliah'
          AND COLUMN_NAME = 'usulan_hapus'
      `;

      const result = await executeWisakaQuery(sql, []);
      const columns = result as any[];

      console.log(
        "🔍 Migration Check - usulan_hapus column exists:",
        columns.length > 0
      );
      return columns.length > 0;
    } catch (error) {
      console.error(
        "❌ Migration Check - Error checking usulan_hapus column:",
        error
      );
      throw error;
    }
  }

  /**
   * Add usulan_hapus column to krsmatakuliah table if it doesn't exist
   */
  private async addUsulanHapusColumn(): Promise<void> {
    try {
      const sql = `
        ALTER TABLE krsmatakuliah
        ADD COLUMN usulan_hapus BOOLEAN NOT NULL DEFAULT FALSE
      `;

      await executeWisakaQuery(sql, []);
      console.log(
        "✅ Migration Success - Added usulan_hapus column to krsmatakuliah table"
      );
    } catch (error) {
      console.error(
        "❌ Migration Error - Failed to add usulan_hapus column:",
        error
      );
      throw error;
    }
  }

  /**
   * Check if krsmatakuliah table has the expected structure
   */
  async checkTableStructure(): Promise<{
    hasUsulanHapus: boolean;
    tableExists: boolean;
    columnCount: number;
  }> {
    try {
      // First check if table exists
      const tableCheckSql = `
        SELECT COUNT(*) as count
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'krsmatakuliah'
      `;

      const tableResult = await executeWisakaQuery(tableCheckSql, []);
      const tableExists = (tableResult as any[])[0]?.count > 0;

      if (!tableExists) {
        throw new Error("krsmatakuliah table does not exist!");
      }

      // Check all columns
      const columnsSql = `
        SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_DEFAULT
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'krsmatakuliah'
        ORDER BY ORDINAL_POSITION
      `;

      const columns = (await executeWisakaQuery(columnsSql, [])) as any[];
      const hasUsulanHapus = columns.some(
        (col) => col.COLUMN_NAME === "usulan_hapus"
      );

      console.log("📊 Table Structure Check:", {
        tableExists,
        hasUsulanHapus,
        columnCount: columns.length,
        columns: columns.map((col) => ({
          name: col.COLUMN_NAME,
          type: col.COLUMN_TYPE,
          nullable: col.IS_NULLABLE,
          default: col.COLUMN_DEFAULT,
        })),
      });

      return {
        hasUsulanHapus,
        tableExists,
        columnCount: columns.length,
      };
    } catch (error) {
      console.error("❌ Table Structure Check Failed:", error);
      throw error;
    }
  }

  /**
   * Create perpustakaan database tables with proper error handling
   */
  private async createPerpustakaanTables(): Promise<void> {
    try {
      console.log("🔧 Creating perpustakaan database tables...");

      // First, ensure we can connect to the database
      await executePerpustakaanQuery("SELECT 1", []);
      console.log("✅ Perpustakaan database connection verified");

      // Create tables in the correct order (no foreign keys first)
      const tablesToCreate = [
        {
          name: "mahasiswa",
          sql: `CREATE TABLE IF NOT EXISTS mahasiswa (
            nrm varchar(12) PRIMARY KEY NOT NULL,
            nim varchar(12),
            namam varchar(60) NOT NULL
          )`,
        },
        {
          name: "admin",
          sql: `CREATE TABLE IF NOT EXISTS admin (
            nip varchar(10) PRIMARY KEY NOT NULL,
            email varchar(100) NOT NULL,
            password varchar(255) NOT NULL
          )`,
        },
        {
          name: "koleksi",
          sql: `CREATE TABLE IF NOT EXISTS koleksi (
            kode varchar(50) PRIMARY KEY NOT NULL,
            kategori ENUM('buku','jurnal','skripsi') NOT NULL,
            topik varchar(100),
            judul varchar(200) NOT NULL,
            penulis varchar(100),
            penerbit varchar(100),
            tahun_terbit varchar(4),
            lokasi_rak varchar(50) NOT NULL,
            deskripsi varchar(255),
            sampul varchar(255),
            status ENUM('Tersedia', 'Dipinjam') DEFAULT 'Tersedia',
            link varchar(8000)
          )`,
        },
        {
          name: "aktivitas",
          sql: `CREATE TABLE IF NOT EXISTS aktivitas (
            id_aktivitas varchar(50) PRIMARY KEY NOT NULL,
            kode varchar(50) NOT NULL,
            nrm varchar(12) NOT NULL,
            tanggal_peminjaman DATE NOT NULL,
            jatuh_tempo DATE NOT NULL,
            status ENUM('dipinjam', 'dikembalikan') NOT NULL DEFAULT 'dipinjam',
            FOREIGN KEY (kode) REFERENCES koleksi(kode),
            FOREIGN KEY (nrm) REFERENCES mahasiswa(nrm)
          )`,
        },
        {
          name: "pengajuan",
          sql: `CREATE TABLE IF NOT EXISTS pengajuan (
            id_pengajuan varchar(50) PRIMARY KEY NOT NULL,
            nrm varchar(12) NOT NULL,
            kode varchar(50) NOT NULL,
            tanggal_peminjaman DATE NOT NULL,
            FOREIGN KEY (kode) REFERENCES koleksi(kode),
            FOREIGN KEY (nrm) REFERENCES mahasiswa(nrm)
          )`,
        },
      ];

      // Create each table individually with error handling
      for (const table of tablesToCreate) {
        try {
          console.log(`🔧 Creating table: ${table.name}`);
          await executePerpustakaanQuery(table.sql, []);
          console.log(`✅ Table created successfully: ${table.name}`);
        } catch (error) {
          console.error(`❌ Error creating table ${table.name}:`, error);
          throw error;
        }
      }

      console.log("✅ All perpustakaan tables created successfully");
    } catch (error) {
      console.error("❌ Error creating perpustakaan tables:", error);
      throw error;
    }
  }

  /**
   * Insert basic sample data
   */
  private async insertSampleData(): Promise<void> {
    try {
      console.log("🔧 Inserting sample data...");

      // Check if mahasiswa data already exists
      const checkMahasiswaSql = `SELECT COUNT(*) as count FROM mahasiswa LIMIT 1`;
      const mahasiswaResult = (await executePerpustakaanQuery(
        checkMahasiswaSql,
        []
      )) as any[];

      if (mahasiswaResult[0].count === 0) {
        // Insert sample mahasiswa data
        const mahasiswaSql = `
          INSERT INTO mahasiswa (nrm, nim, namam) VALUES
          ('202500000001', '2312345678', 'Andi Saputra'),
          ('202500000002', '2312345679', 'Budi Santoso'),
          ('202500000003', '2312345680', 'Citra Dewi'),
          ('202500000004', '2312345681', 'Dimas Pratama')
        `;
        await executePerpustakaanQuery(mahasiswaSql, []);
        console.log("✅ Sample mahasiswa data inserted");
      } else {
        console.log("ℹ️ Mahasiswa sample data already exists");
      }

      // Check if admin data already exists
      const checkAdminSql = `SELECT COUNT(*) as count FROM admin LIMIT 1`;
      const adminResult = (await executePerpustakaanQuery(
        checkAdminSql,
        []
      )) as any[];

      if (adminResult[0].count === 0) {
        // Insert sample admin data
        const adminSql = `
          INSERT INTO admin (nip, email, password) VALUES
          ('1234567890', 'admin@perpustakaan.ac.id', '$2b$10$example.hash.here')
        `;
        await executePerpustakaanQuery(adminSql, []);
        console.log("✅ Sample admin data inserted");
      } else {
        console.log("ℹ️ Admin sample data already exists");
      }

      // Check if koleksi data already exists
      const checkKoleksiSql = `SELECT COUNT(*) as count FROM koleksi LIMIT 1`;
      const koleksiResult = (await executePerpustakaanQuery(
        checkKoleksiSql,
        []
      )) as any[];

      if (koleksiResult[0].count === 0) {
        // Insert comprehensive sample koleksi data TOLONG DICOMMENT KALAU SUDAHA ADA DATA ASLI
        const koleksiSql = `
          INSERT INTO koleksi (kode, kategori, topik, judul, penulis, penerbit, tahun_terbit, lokasi_rak, deskripsi, sampul, status) VALUES

          -- Buku Kedokteran
          ('BK001', 'buku', 'Anatomi', 'Anatomi dan Fisiologi Manusia', 'Dr. Suharto Gunawan', 'Penerbit Medika', '2023', 'Rak A1', 'Buku lengkap tentang anatomi dan fisiologi tubuh manusia', 'anatomi_cover.jpg', 'Tersedia'),
          ('BK002', 'buku', 'Farmakologi', 'Farmakologi Dasar dan Klinik', 'Prof. Dr. Siti Rahayu', 'Penerbit Medis Jakarta', '2022', 'Rak A2', 'Panduan farmakologi untuk mahasiswa kedokteran', 'farmakologi_cover.jpg', 'Tersedia'),
          ('BK003', 'buku', 'Patologi', 'Patologi Umum', 'Dr. Ahmad Wijaya', 'EGC Medical', '2023', 'Rak A3', 'Konsep dasar patologi untuk mahasiswa kedokteran', 'patologi_cover.jpg', 'Tersedia'),
          ('BK004', 'buku', 'Kardiologi', 'Kardiologi Praktis', 'Dr. Budi Hartono', 'Penerbit Medika', '2024', 'Rak B1', 'Panduan praktis kardiologi untuk klinisi', 'kardiologi_cover.jpg', 'Tersedia'),
          ('BK005', 'buku', 'Pediatri', 'Ilmu Kesehatan Anak', 'Prof. Dr. Maya Sari', 'FKUI Press', '2023', 'Rak B2', 'Buku teks pediatri untuk mahasiswa dan dokter', 'pediatri_cover.jpg', 'Tersedia'),

          -- Jurnal Kedokteran
          ('JR001', 'jurnal', '-', 'Indonesian Journal of Medicine', 'Various Authors', 'Medical Association Indonesia', '2024', 'Rak C1', 'Jurnal kedokteran Indonesia terbaru volume 45', 'journal_med_cover.jpg', 'Tersedia'),
          ('JR002', 'jurnal', '-', 'Journal of Public Health', 'Various Authors', 'Public Health Society', '2024', 'Rak C2', 'Jurnal kesehatan masyarakat volume 12', 'journal_public_cover.jpg', 'Tersedia'),
          ('JR003', 'jurnal', '-', 'Clinical Research Journal', 'Various Authors', 'Clinical Research Institute', '2023', 'Rak C3', 'Jurnal penelitian klinis volume 8', 'journal_clinical_cover.jpg', 'Tersedia'),
          ('JR004', 'jurnal', '-', 'Emergency Medicine Review', 'Various Authors', 'Emergency Medicine Board', '2024', 'Rak C4', 'Review kedokteran darurat volume 3', 'journal_emergency_cover.jpg', 'Tersedia'),

          -- Skripsi
          ('SK001', 'skripsi', '-', 'Analisis Efektivitas Antibiotik pada Infeksi Saluran Kemih', 'Putri Maharani', 'Fakultas Kedokteran', '2023', 'Rak D1', 'Penelitian tentang efektivitas berbagai jenis antibiotik', 'skripsi_001_cover.jpg', 'Tersedia'),
          ('SK002', 'skripsi', '-', 'Hubungan Pola Makan dengan Kejadian Diabetes Mellitus', 'Rahman Sidiq', 'Fakultas Kedokteran', '2023', 'Rak D2', 'Studi epidemiologi tentang diabetes mellitus', 'skripsi_002_cover.jpg', 'Tersedia'),
          ('SK003', 'skripsi', '-', 'Pengaruh Terapi Musik terhadap Kecemasan Pasien Pre-Operasi', 'Sari Indrawati', 'Fakultas Kedokteran', '2024', 'Rak D3', 'Penelitian tentang terapi musik dalam mengurangi kecemasan', 'skripsi_003_cover.jpg', 'Tersedia'),
          ('SK004', 'skripsi', '-', 'Analisis Faktor Risiko Hipertensi pada Dewasa Muda', 'Andi Permana', 'Fakultas Kedokteran', '2024', 'Rak D4', 'Studi analitik faktor risiko hipertensi', 'skripsi_004_cover.jpg', 'Tersedia'),
          ('SK005', 'skripsi', '-', 'Evaluasi Program Imunisasi di Puskesmas', 'Nur Hidayati', 'Fakultas Kedokteran', '2023', 'Rak D5', 'Evaluasi pelaksanaan program imunisasi', 'skripsi_005_cover.jpg', 'Tersedia')
        `;
        await executePerpustakaanQuery(koleksiSql, []);
        console.log(
          "✅ Sample koleksi data inserted (15 items: 5 buku, 4 jurnal, 5 skripsi)"
        );
      } else {
        console.log("ℹ️ Koleksi sample data already exists");
      }

      console.log("✅ All sample data insertion completed");
    } catch (error) {
      console.error("❌ Error inserting sample data:", error);
      // Don't throw - sample data is optional
    }
  }

  /**
   * Run perpustakaan database migration
   */
  private async runPerpustakaanMigration(): Promise<{
    success: boolean;
    message: string;
  }> {
    try {
      console.log("🚀 Starting perpustakaan database migration...");

      // Test database connection
      await executePerpustakaanQuery("SELECT 1", []);
      console.log("✅ Perpustakaan database is accessible");

      // Check if tables already exist
      const checkTablesSql = `
        SELECT TABLE_NAME
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME IN ('mahasiswa', 'koleksi', 'aktivitas', 'admin', 'pengajuan')
      `;

      const existingTables = (await executePerpustakaanQuery(
        checkTablesSql,
        []
      )) as any[];
      const tableNames = existingTables.map((row: any) => row.TABLE_NAME);

      console.log("📊 Existing perpustakaan tables:", tableNames);

      if (tableNames.length === 5) {
        console.log("✅ All perpustakaan tables already exist");
        return {
          success: true,
          message: "Perpustakaan tables already exist",
        };
      }

      // Create missing tables
      await this.createPerpustakaanTables();

      // Insert sample data
      await this.insertSampleData();

      return {
        success: true,
        message: "Perpustakaan database migration completed successfully",
      };
    } catch (error) {
      console.error("❌ Perpustakaan migration failed:", error);
      return {
        success: false,
        message: `Perpustakaan migration failed: ${
          error instanceof Error ? error.message : "Unknown error"
        }`,
      };
    }
  }

  /**
   * Run WISAKA migration for usulan_hapus column
   */
  async runMigration(): Promise<{
    success: boolean;
    message: string;
    hadToMigrate: boolean;
  }> {
    try {
      console.log("🚀 Starting database migration check...");

      const structure = await this.checkTableStructure();

      if (!structure.tableExists) {
        return {
          success: false,
          message: "krsmatakuliah table does not exist",
          hadToMigrate: false,
        };
      }

      if (structure.hasUsulanHapus) {
        console.log(
          "✅ Migration Check - usulan_hapus column already exists, no migration needed"
        );
        return {
          success: true,
          message: "usulan_hapus column already exists",
          hadToMigrate: false,
        };
      }

      console.log("🔧 Migration - Adding usulan_hapus column...");
      await this.addUsulanHapusColumn();

      // Verify the migration was successful
      const postMigrationCheck = await this.checkUsulanHapusColumn();

      if (postMigrationCheck) {
        return {
          success: true,
          message:
            "Successfully added usulan_hapus column to krsmatakuliah table",
          hadToMigrate: true,
        };
      } else {
        return {
          success: false,
          message: "Migration completed but column verification failed",
          hadToMigrate: true,
        };
      }
    } catch (error) {
      console.error("❌ Migration Failed:", error);
      return {
        success: false,
        message: `Migration failed: ${
          error instanceof Error ? error.message : "Unknown error"
        }`,
        hadToMigrate: false,
      };
    }
  }

  /**
   * Initialize database migrations - call this on server startup
   */
  async initialize(): Promise<void> {
    try {
      // Run WISAKA migration
      const wisakaResult = await this.runMigration();

      if (!wisakaResult.success) {
        console.error(
          "❌ WISAKA Database Migration Failed:",
          wisakaResult.message
        );
      } else {
        if (wisakaResult.hadToMigrate) {
          console.log(
            "✅ WISAKA Database Migration Completed:",
            wisakaResult.message
          );
        } else {
          console.log(
            "ℹ️ WISAKA Database Migration Skipped:",
            wisakaResult.message
          );
        }
      }

      // Run perpustakaan migration
      const perpustakaanResult = await this.runPerpustakaanMigration();

      if (!perpustakaanResult.success) {
        console.error(
          "❌ Perpustakaan Database Migration Failed:",
          perpustakaanResult.message
        );
      } else {
        console.log(
          "✅ Perpustakaan Database Migration Completed:",
          perpustakaanResult.message
        );
      }

      console.log("🎉 Database migrations initialization completed");
    } catch (error) {
      console.error("❌ Database Migration Initialization Failed:", error);
    }
  }
}

// Export singleton instance
export const databaseMigration = new DatabaseMigration();
