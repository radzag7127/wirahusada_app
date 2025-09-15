import { Request, Response } from "express";
import db from "../../config/perpustakaanDb";

// GET semua aktivitas
export const getAktivitas = async (req: Request, res: Response) => {
  try {
    console.log('Fetching aktivitas data...');
    
    // Ambil semua aktivitas dengan data koleksi dan mahasiswa
    // Status diambil dari tabel aktivitas
    const [rows] = await db.query(`
      SELECT 
        a.id_aktivitas, 
        a.kode, 
        a.nrm, 
        a.tanggal_peminjaman, 
        a.jatuh_tempo,
        a.status AS status_aktivitas,
        m.namam AS nama_mahasiswa, 
        k.judul AS judul_buku,
        k.kategori
      FROM aktivitas a
      JOIN mahasiswa m ON a.nrm = m.nrm
      JOIN koleksi k ON a.kode = k.kode
      ORDER BY a.tanggal_peminjaman DESC
    `);
    
    const aktivitasData = rows as any[];
    
    console.log('Aktivitas data fetched:', {
      count: aktivitasData.length,
      sample: aktivitasData.slice(0, 2)
    });
    
    return res.json(aktivitasData);
  } catch (err) {
    console.error('Error fetching aktivitas:', err);
    return res.status(500).json({ message: "Error mengambil data aktivitas", error: err });
  }
};

// GET aktivitas berdasarkan ID
export const getAktivitasById = async (req: Request, res: Response) => {
  try {
    const { id_aktivitas } = req.params;
    const [rows] = await db.query(
      `
      SELECT a.id_aktivitas, a.kode, a.nrm, a.tanggal_peminjaman, a.jatuh_tempo, a.status AS status_aktivitas,
             m.namam AS nama_mahasiswa, k.judul AS judul_buku, k.kategori
      FROM aktivitas a
      JOIN mahasiswa m ON a.nrm = m.nrm
      JOIN koleksi k ON a.kode = k.kode
      WHERE a.id_aktivitas = ?
      `,
      [id_aktivitas]
    );

    if ((rows as any[]).length === 0) {
      return res.status(404).json({ message: "Aktivitas tidak ditemukan" });
    }

    return res.json((rows as any[])[0]);
  } catch (err) {
    return res.status(500).json({ message: "Error mengambil aktivitas", error: err });
  }
};

// CREATE aktivitas (peminjaman)
export const createAktivitas = async (req: Request, res: Response) => {
  try {
    const { id_aktivitas, kode, nrm, tanggal_peminjaman, jatuh_tempo } = req.body;

    // Mulai transaction untuk memastikan konsistensi data
    await db.query("START TRANSACTION");

    try {
      // Cek apakah buku masih dipinjam (belum dikembalikan)
      const [existingAktivitas] = await db.query(
        "SELECT id_aktivitas FROM aktivitas WHERE kode = ? AND status = 'dipinjam'",
        [kode]
      );

      if ((existingAktivitas as any[]).length > 0) {
        await db.query("ROLLBACK");
        console.log('Buku masih dipinjam, tidak bisa dipinjam lagi:', kode);
        return res.status(400).json({ 
          message: "Buku masih dipinjam dan belum dikembalikan. Tidak bisa dipinjam lagi." 
        });
      }

      // Cek apakah koleksi ada
      const [koleksiRows] = await db.query(
        "SELECT kode FROM koleksi WHERE kode = ?",
        [kode]
      );

      if ((koleksiRows as any[]).length === 0) {
        await db.query("ROLLBACK");
        console.log('Koleksi tidak ditemukan:', kode);
        return res.status(404).json({ 
          message: "Koleksi tidak ditemukan" 
        });
      }

      // Insert aktivitas dengan status default 'dipinjam'
      await db.query(
        "INSERT INTO aktivitas (id_aktivitas, kode, nrm, tanggal_peminjaman, jatuh_tempo, status) VALUES (?, ?, ?, ?, ?, 'dipinjam')",
        [id_aktivitas, kode, nrm, tanggal_peminjaman, jatuh_tempo]
      );

      console.log('Aktivitas peminjaman created with status dipinjam for kode:', kode);

      // Commit transaction
      await db.query("COMMIT");

      return res.status(201).json({
        message: "Aktivitas berhasil ditambahkan",
        koleksi_status_updated: true,
        new_status: 'Dipinjam'
      });
    } catch (err) {
      // Rollback jika ada error
      await db.query("ROLLBACK");
      throw err;
    }
  } catch (err) {
    return res.status(500).json({ message: "Error menambah aktivitas", error: err });
  }
};

// UPDATE status aktivitas (sekarang mengupdate status koleksi)
export const updateStatusAktivitas = async (req: Request, res: Response) => {
  try {
    const { id_aktivitas } = req.params;
    const { status } = req.body;

    console.log('UpdateStatusAktivitas called with:', { id_aktivitas, status });
    console.log('Request body:', req.body);
    console.log('Request params:', req.params);

    // Validasi status enum
    if (!['dipinjam', 'dikembalikan'].includes(status)) {
      console.log('Invalid status:', status);
      return res.status(400).json({ message: "Status harus 'dipinjam' atau 'dikembalikan'" });
    }

    // Mulai transaction
    await db.query("START TRANSACTION");

    try {
      // Cek apakah aktivitas ada
      const [aktivitasRows] = await db.query(
        "SELECT id_aktivitas FROM aktivitas WHERE id_aktivitas = ?",
        [id_aktivitas]
      );

      if ((aktivitasRows as any[]).length === 0) {
        await db.query("ROLLBACK");
        console.log('Aktivitas tidak ditemukan for id_aktivitas:', id_aktivitas);
        return res.status(404).json({ message: "Aktivitas tidak ditemukan" });
      }

      // Update status di tabel aktivitas
      await db.query(
        "UPDATE aktivitas SET status = ? WHERE id_aktivitas = ?",
        [status, id_aktivitas]
      );
      
      console.log('Aktivitas status updated to', status, 'for id_aktivitas:', id_aktivitas);

      // Commit transaction
      await db.query("COMMIT");

      // Ambil data aktivitas yang sudah diupdate
      console.log('Fetching updated data for id_aktivitas:', id_aktivitas);
      const [rows] = await db.query(
        `
        SELECT a.id_aktivitas, a.kode, a.nrm, a.tanggal_peminjaman, a.jatuh_tempo, a.status AS status_aktivitas,
               m.namam AS nama_mahasiswa, k.judul AS judul_buku, k.kategori
        FROM aktivitas a
        JOIN mahasiswa m ON a.nrm = m.nrm
        JOIN koleksi k ON a.kode = k.kode
        WHERE a.id_aktivitas = ?
        `,
        [id_aktivitas]
      );

      console.log('Fetched rows:', rows);

      if ((rows as any[]).length === 0) {
        console.log('No data found after update for id_aktivitas:', id_aktivitas);
        return res.status(404).json({ message: "Aktivitas tidak ditemukan" });
      }

      const responseData = { 
        message: "Status aktivitas berhasil diupdate", 
        data: (rows as any[])[0] 
      };

      console.log('Sending response:', responseData);
      return res.json(responseData);
    } catch (err) {
      await db.query("ROLLBACK");
      throw err;
    }
  } catch (err) {
    console.error('Error in updateStatusAktivitas:', err);
    return res.status(500).json({ message: "Error update status aktivitas", error: err });
  }
};

// UPDATE aktivitas (hanya update jatuh_tempo, status dihandle terpisah)
export const updateAktivitas = async (req: Request, res: Response) => {
  try {
    const { id_aktivitas } = req.params;
    const { jatuh_tempo } = req.body;

    if (!jatuh_tempo) {
      return res.status(400).json({ message: "Jatuh tempo harus diisi" });
    }

    await db.query(
      "UPDATE aktivitas SET jatuh_tempo = ? WHERE id_aktivitas = ?",
      [jatuh_tempo, id_aktivitas]
    );

    return res.json({ message: "Aktivitas berhasil diperbarui" });
  } catch (err) {
    return res.status(500).json({ message: "Error update aktivitas", error: err });
  }
};

// DELETE aktivitas (jika perlu)
export const deleteAktivitas = async (req: Request, res: Response) => {
  try {
    const { id_aktivitas } = req.params;
    await db.query("DELETE FROM aktivitas WHERE id_aktivitas = ?", [id_aktivitas]);
    return res.json({ message: "Aktivitas berhasil dihapus" });
  } catch (err) {
    return res.status(500).json({ message: "Error hapus aktivitas", error: err });
  }
};