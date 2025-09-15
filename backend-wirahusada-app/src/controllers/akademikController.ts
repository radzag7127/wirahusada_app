// src/controllers/akademikController.ts

import { Request, Response } from 'express';
import { AkademikService } from '../services/akademikService';
import { ApiResponse, JWTPayload } from '../types';


const akademikService = new AkademikService();

export class AkademikController {
  async getDaftarMahasiswa(req: Request, res: Response): Promise<void> {
    try {
      const data = await akademikService.getDaftarMahasiswa();
      res.status(200).json({
        success: true,
        message: 'Daftar mahasiswa berhasil diambil',
        data: data,
      } as ApiResponse);
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Gagal mengambil daftar mahasiswa',
        errors: [error instanceof Error ? error.message : 'Unknown error'],
      } as ApiResponse);
    }
  }






  async getMahasiswaInfo(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user as JWTPayload;
      if (!user || !user.nrm) {
        res.status(401).json({ success: false, message: 'Akses ditolak. Token tidak valid.' });
        return;
      }

      const nrm = user.nrm;
      const data = await akademikService.getMahasiswaInfo(nrm);

      res.status(200).json({
        success: true,
        message: 'Informasi mahasiswa berhasil diambil',
        data: data,
      } as ApiResponse);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      const statusCode = errorMessage.toLowerCase().includes('ditemukan') ? 404 : 500;
      res.status(statusCode).json({
        success: false,
        message: 'Gagal mengambil informasi mahasiswa',
        errors: [errorMessage],
      });
    }
  }

















  async getTranskrip(req: Request, res: Response): Promise<void> {
    try {
        // 1. Ambil data pengguna dari token yang sudah diproses oleh middleware 'authenticateToken'
        const user = (req as any).user;

        // 2. Validasi: Pastikan pengguna terotentikasi dan data NRM ada di dalam token
        if (!user || !user.nrm) {
            res.status(401).json({ 
                success: false, 
                message: 'Akses ditolak. Pengguna tidak terotentikasi atau token tidak valid.' 
            });
            return;
        }

        // 3. Panggil Service: Gunakan NRM dari token untuk memanggil service
        const nrm = user.nrm;
        const data = await akademikService.getTranskrip(nrm);

        // 4. Kirim Respon Sukses with user context headers
        res.set('X-User-Context-Akademik', nrm);
        res.status(200).json({ 
            success: true, 
            message: 'Transkrip berhasil diambil', 
            data,
            _userContext: nrm // Add user context to response body for client validation
        });

    } catch (error) {
        // 5. Tangani Error
        const errorMessage = error instanceof Error ? error.message : 'Unknown error';
        const statusCode = errorMessage.toLowerCase().includes('ditemukan') ? 404 : 500;
        res.status(statusCode).json({ 
            success: false, 
            message: 'Gagal mengambil transkrip', 
            errors: [errorMessage] 
        });
    }
  }




    /**
   * CONTROLLER BARU: Menangani permintaan untuk mengubah status usulan hapus.
   */
    async updateUsulanHapus(req: Request, res: Response): Promise<void> {
      try {
        const user = (req as any).user as JWTPayload;
        const { kodeMataKuliah, kurikulum, semesterKe, newStatus } = req.body;
  
        // Validasi input dari body request
        if (
          kodeMataKuliah == null ||
          kurikulum == null ||
          semesterKe == null ||
          newStatus == null
        ) {
          res.status(400).json({
            success: false,
            message: "Parameter tidak lengkap. 'kodeMataKuliah', 'kurikulum', 'semesterKe', dan 'newStatus' wajib diisi.",
          } as ApiResponse);
          return;
        }
  
        const success = await akademikService.updateUsulanHapus(
          user.nrm,
          kodeMataKuliah,
          kurikulum,
          semesterKe,
          newStatus
        );
  
        if (success) {
          res.json({
            success: true,
            message: "Status usulan penghapusan mata kuliah berhasil diperbarui.",
          } as ApiResponse);
        } else {
          res.status(404).json({
            success: false,
            message: "Mata kuliah tidak ditemukan atau gagal diperbarui.",
          } as ApiResponse);
        }
      } catch (error) {
        res.status(500).json({
          success: false,
          message: "Terjadi kesalahan pada server.",
          errors: [error instanceof Error ? error.message : "Unknown error"],
        } as ApiResponse);
      }
    }

    async getKhs(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user as JWTPayload;
      if (!user || !user.nrm) {
        res.status(401).json({ success: false, message: 'Akses ditolak. Token tidak valid.' });
        return;
      }
      const nrm = user.nrm;

      // PERUBAHAN: Ambil 'semesterKe' dan 'jenisSemester' dari query
      const { semesterKe, jenisSemester } = req.query;

      if (!semesterKe || !jenisSemester) {
        res.status(400).json({
          success: false,
          message: "Parameter 'semesterKe' dan 'jenisSemester' wajib diisi.",
        });
        return;
      }

      const semesterKeNum = parseInt(semesterKe as string, 10);
      const jenisSemesterNum = parseInt(jenisSemester as string, 10);

      if (isNaN(semesterKeNum) || isNaN(jenisSemesterNum)) {
        res.status(400).json({
          success: false,
          message: "Parameter 'semesterKe' dan 'jenisSemester' harus berupa angka.",
        });
        return;
      }

      // Panggil service dengan parameter yang sudah divalidasi
      const data = await akademikService.getKhs(nrm, semesterKeNum, jenisSemesterNum);

      // Add user context headers for cache isolation
      res.set('X-User-Context-Akademik', nrm);
      res.status(200).json({
        success: true,
        message: `KHS berhasil diambil`,
        data: data,
        _userContext: nrm // Add user context to response body for client validation
      });
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      const statusCode = errorMessage.toLowerCase().includes('ditemukan') ? 404 : 500;
      res.status(statusCode).json({
        success: false,
        message: 'Gagal mengambil data KHS',
        errors: [errorMessage],
      });
    }
  }

  async getKrs(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user as JWTPayload;
      if (!user || !user.nrm) {
        res.status(401).json({ success: false, message: 'Akses ditolak. Token tidak valid.' });
        return;
      }
      const nrm = user.nrm;

      // PERUBAHAN: Ambil 'semesterKe' dan 'jenisSemester' dari query
      const { semesterKe, jenisSemester } = req.query;

      // Validasi kedua parameter
      if (!semesterKe || !jenisSemester) {
        res.status(400).json({
          success: false,
          message: "Parameter 'semesterKe' dan 'jenisSemester' wajib diisi.",
        });
        return;
      }

      const semesterKeNum = parseInt(semesterKe as string, 10);
      const jenisSemesterNum = parseInt(jenisSemester as string, 10);

      if (isNaN(semesterKeNum) || isNaN(jenisSemesterNum)) {
        res.status(400).json({
          success: false,
          message: "Parameter 'semesterKe' dan 'jenisSemester' harus berupa angka.",
        });
        return;
      }

      // Panggil service dengan parameter yang sudah divalidasi
      const data = await akademikService.getKrs(nrm, semesterKeNum, jenisSemesterNum);

      // Add user context headers for cache isolation
      res.set('X-User-Context-Akademik', nrm);
      res.status(200).json({
        success: true,
        message: 'Data KRS berhasil diambil',
        data: data,
        _userContext: nrm // Add user context to response body for client validation
      });
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      const statusCode = errorMessage.toLowerCase().includes('ditemukan') ? 404 : 500;
      res.status(statusCode).json({
        success: false,
        message: 'Gagal mengambil data KRS',
        errors: [errorMessage],
      });
    }
  }
}
