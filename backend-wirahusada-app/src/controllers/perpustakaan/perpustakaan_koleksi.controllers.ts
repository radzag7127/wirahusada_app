import { Request, Response } from "express";
import db from "../../config/perpustakaanDb";

// GET semua koleksi dengan status berdasarkan aktivitas
export const getKoleksi = async (req: Request, res: Response): Promise<any> => {
  try {
    console.log('=== GET KOLEKSI REQUEST RECEIVED ===');

    // Query untuk mendapatkan koleksi dengan status berdasarkan aktivitas
    const result = await db.query(`
      SELECT
        k.*,
        CASE
          WHEN EXISTS (
            SELECT 1 FROM aktivitas a
            WHERE a.kode = k.kode
            AND a.status = 'dipinjam'
          ) THEN 'Dipinjam'
          ELSE 'Tersedia'
        END as status,
        1 as stok_total,
        CASE
          WHEN EXISTS (
            SELECT 1 FROM aktivitas a
            WHERE a.kode = k.kode
            AND a.status = 'dipinjam'
          ) THEN 0
          ELSE 1
        END as stok_tersedia,
        CASE
          WHEN EXISTS (
            SELECT 1 FROM aktivitas a
            WHERE a.kode = k.kode
            AND a.status = 'dipinjam'
          ) THEN 1
          ELSE 0
        END as active_borrows
      FROM koleksi k
      ORDER BY k.kode
    `);

    // Handle the database result properly - the result is the actual array
    const safeRows = Array.isArray(result) ? result : [];

    console.log('🗄️ PERPUSTAKAAN DB - Query successful:', {
      resultCount: safeRows.length,
      firstResult: safeRows.length > 0 ? safeRows[0] : undefined
    });
    console.log('Koleksi data fetched with status:', safeRows);
    console.log('Number of records:', safeRows.length);

    res.json(safeRows);
  } catch (err) {
    console.error('Error fetching koleksi:', err);
    res.status(500).json({ message: "Error mengambil koleksi", error: err });
  }
};

// GET koleksi by kode dengan status
export const getKoleksiByKode = async (req: Request, res: Response) => {
  const { kode } = req.params;
  try {
    console.log(`=== GET KOLEKSI BY KODE: ${kode} ===`);

    const result = await db.query(`
      SELECT
        k.*,
        CASE
          WHEN EXISTS (
            SELECT 1 FROM aktivitas a
            WHERE a.kode = k.kode
            AND a.status = 'dipinjam'
          ) THEN 'Dipinjam'
          ELSE 'Tersedia'
        END as status
      FROM koleksi k
      WHERE k.kode = ?
    `, [kode]);

    // Handle the database result properly - the result is the actual array
    const safeRows = Array.isArray(result) ? result : [];

    console.log('🗄️ PERPUSTAKAAN DB - Query by kode successful:', {
      kode,
      resultCount: safeRows.length,
      firstResult: safeRows.length > 0 ? safeRows[0] : undefined
    });

    if (safeRows.length > 0) {
      res.json(safeRows[0]);
    } else {
      res.status(404).json({ message: "Koleksi tidak ditemukan" });
    }
  } catch (err) {
    console.error(`Error fetching koleksi by kode ${kode}:`, err);
    res.status(500).json({ message: "Error mengambil koleksi", error: err });
  }
};

// CREATE koleksi
export const createKoleksi = async (req: Request, res: Response) => {
    console.log("Body data:", req.body); // DEBUG
  const { kode, kategori, topik, judul, penulis, penerbit, tahun_terbit, lokasi_rak, deskripsi, sampul } = req.body;
  
  // Jika kategori bukan buku, set topik menjadi "-"
  const topikValue = kategori === 'buku' ? topik : '-';
  
  try {
    await db.query(
      `INSERT INTO koleksi (kode, kategori, topik, judul, penulis, penerbit, tahun_terbit, lokasi_rak, deskripsi, sampul) 
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [kode, kategori, topikValue, judul, penulis, penerbit, tahun_terbit, lokasi_rak, deskripsi, sampul]
    );
    res.status(201).json({ message: "Koleksi ditambahkan" });
  } catch (err) {
    res.status(500).json({ message: "Error menambah koleksi", error: err });
  }
};

// UPDATE koleksi
export const updateKoleksi = async (req: Request, res: Response) => {
  console.log('=== UPDATE KOLEKSI REQUEST RECEIVED ===');
  console.log('Method:', req.method);
  console.log('URL:', req.url);
  console.log('Headers:', req.headers);
  
  const { kode } = req.params;
  const { kategori, topik, judul, penulis, penerbit, tahun_terbit, lokasi_rak, deskripsi, sampul } = req.body;
  
  // Jika kategori bukan buku, set topik menjadi "-"
  const topikValue = kategori === 'buku' ? topik : '-';
  
  console.log('Kode:', kode);
  console.log('Request body:', req.body);
  console.log('Topik value:', topikValue);
  
  try {
    const [result] = await db.query(
      `UPDATE koleksi 
       SET kategori=?, topik=?, judul=?, penulis=?, penerbit=?, tahun_terbit=?, lokasi_rak=?, deskripsi=?, sampul=? 
       WHERE kode=?`,
      [kategori, topikValue, judul, penulis, penerbit, tahun_terbit, lokasi_rak, deskripsi, sampul, kode]
    );
    
    console.log('Update result:', result);
    
    // Verify the update by fetching the updated record
    const [updatedRows] = await db.query("SELECT * FROM koleksi WHERE kode = ?", [kode]);
    console.log('Updated record:', updatedRows);
    
    res.json({ message: "Koleksi diperbarui", updated: (updatedRows as any[])[0] });
  } catch (err) {
    console.error('Error updating koleksi:', err);
    res.status(500).json({ message: "Error update koleksi", error: err });
  }
};

// DELETE koleksi
export const deleteKoleksi = async (req: Request, res: Response) => {
  console.log('=== DELETE KOLEKSI REQUEST RECEIVED ===');
  console.log('Method:', req.method);
  console.log('URL:', req.url);
  console.log('Headers:', req.headers);
  
  const { kode } = req.params;
  console.log('Kode to delete:', kode);
  
  try {
    // First, check if the record exists
    const [existingRows] = await db.query("SELECT * FROM koleksi WHERE kode = ?", [kode]);
    console.log('Existing records found:', (existingRows as any[]).length);
    
    if ((existingRows as any[]).length === 0) {
      console.log('No record found with kode:', kode);
      return res.status(404).json({ message: "Koleksi tidak ditemukan", kode: kode });
    }
    
    // Perform the delete
    const [result] = await db.query("DELETE FROM koleksi WHERE kode = ?", [kode]);
    console.log('Delete result:', result);
    
    // Verify the deletion
    const [remainingRows] = await db.query("SELECT * FROM koleksi WHERE kode = ?", [kode]);
    console.log('Remaining records after delete:', (remainingRows as any[]).length);
    
    if ((remainingRows as any[]).length === 0) {
      console.log('Successfully deleted koleksi with kode:', kode);
      return res.json({ message: "Koleksi berhasil dihapus", kode: kode });
    } else {
      console.log('Failed to delete koleksi with kode:', kode);
      return res.status(500).json({ message: "Gagal menghapus koleksi", kode: kode });
    }
  } catch (err) {
    console.error('Error deleting koleksi:', err);
    return res.status(500).json({ message: "Error hapus koleksi", error: err, kode: kode });
  }
};

// GET koleksi by kategori NEW ADDITION BARU
export const getByKategori = async (req: Request, res: Response) => {
  try {
    const { kategori } = req.params;
    if (!kategori) {
      return res.status(400).json({ message: "Kategori parameter is required" });
    }

    console.log(`=== GET KOLEKSI BY KATEGORI: ${kategori} ===`);

    const result: any = await db.query(`
      SELECT
        k.*,
        k.status as status,
        1 as stok_total,
        CASE
          WHEN k.status = 'Dipinjam' THEN 0
          ELSE 1
        END as stok_tersedia,
        CASE
          WHEN k.status = 'Dipinjam' THEN 1
          ELSE 0
        END as active_borrows
      FROM koleksi k 
      WHERE k.kategori = ?
      ORDER BY k.kode
    `, [kategori.toLowerCase()]);

    // Handle the database result properly - the result is the actual array
    const safeRows = Array.isArray(result) ? result : [];

    console.log('🗄️ PERPUSTAKAAN DB - Query by kategori successful:', {
      kategori: kategori.toLowerCase(),
      resultCount: safeRows.length,
      firstResult: safeRows.length > 0 ? safeRows[0] : undefined
    });

    // Return empty array instead of 404 when no results found
    if (safeRows.length === 0) {
      console.log(`No koleksi found for kategori: ${kategori}`);
      return res.json([]); // Return empty array instead of 404
    }

    const data = safeRows.map((item: any) => ({
      ...item,
      sampul: item.sampul
        ? `http://localhost:5000/uploads/sampul/${item.sampul}`
        : null,
    }));

    return res.json(data);
  } catch (error: any) {
    console.error(`Error fetching koleksi by kategori ${req.params.kategori}:`, error);
    return res.status(500).json({ message: "Error mengambil koleksi", error });
  }
};

// CREATE pengajuan
export const createPengajuan = async (req: Request, res: Response) => {
  try {
    const { nrm, kode, tanggal_pengambilan } = req.body;

    if (!nrm || !kode || !tanggal_pengambilan) {
      return res.status(400).json({ message: "NRM, kode, dan tanggal wajib diisi" });
    }

    // Generate a unique ID for the pengajuan
    const id_pengajuan = `P${Date.now()}`;

    const [result]: any = await db.query(
      "INSERT INTO pengajuan (id_pengajuan, nrm, kode, tanggal_peminjaman) VALUES (?, ?, ?, ?)",
      [id_pengajuan, nrm, kode, tanggal_pengambilan]
    );

    return res.status(201).json({
      message: "Pengajuan berhasil dibuat",
      data: {
        id_pengajuan: id_pengajuan,
        nrm,
        kode,
        tanggal_pengambilan,
      },
    });
  } catch (error) {
    console.error("Error create pengajuan:", error);
    return res.status(500).json({ message: "Error membuat pengajuan", error });
  }
};
