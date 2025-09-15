import { Request, Response } from "express";
import db from "../../config/perpustakaanDb";

export const testDbConnection = async (req: Request, res: Response) => {
  try {
    const [result] = await db.query("SELECT 1 as test");
    return res.json({ message: "Database connection successful", result });
  } catch (err) {
    return res.status(500).json({ message: "Database connection failed", error: err });
  }
};

// Test endpoint untuk mengecek data mahasiswa
export const testMahasiswaData = async (req: Request, res: Response) => {
  try {
    console.log("Testing mahasiswa data...");
    
    // Cek apakah tabel mahasiswa ada
    const [tableCheck] = await db.query(`
      SELECT COUNT(*) as count 
      FROM information_schema.tables 
      WHERE table_schema = DATABASE() 
      AND table_name = 'mahasiswa'
    `);
    
    // Hitung jumlah data mahasiswa
    const [countResult] = await db.query("SELECT COUNT(*) as total FROM mahasiswa");
    
    // Ambil semua data mahasiswa
    const [mahasiswaData] = await db.query("SELECT * FROM mahasiswa LIMIT 5");
    
    return res.json({
      tableExists: (tableCheck as any[])[0].count > 0,
      totalMahasiswa: (countResult as any[])[0].total,
      sampleData: mahasiswaData
    });
  } catch (err) {
    console.error("Error testing mahasiswa data:", err);
    return res.status(500).json({ message: "Error testing mahasiswa data", error: err });
  }
};
