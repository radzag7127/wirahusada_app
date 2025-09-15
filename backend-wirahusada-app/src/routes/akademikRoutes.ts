// src/routes/akademikRoutes.ts

import { Router } from 'express';
import { AkademikController } from '../controllers/akademikController';
import { authenticateToken } from '../utils/auth';
import { validateAcademic, validateGeneral } from '../middleware/validation';
import { authCacheMiddleware, userContextIsolationMiddleware } from '../middleware/cacheControl';

const router = Router();
const akademikController = new AkademikController();

// Apply cache control middleware to prevent stale authentication responses
router.use(authCacheMiddleware);

// All academic routes require authentication
router.use(authenticateToken);

// Apply user context isolation to prevent cross-user data leakage
router.use(userContextIsolationMiddleware);

// Rute untuk mendapatkan daftar semua mahasiswa (contoh rute publik)
router.get('/mahasiswa/daftar', akademikController.getDaftarMahasiswa); //palingan gak dipakai, bisa dihapus harusnya?

// Rute baru untuk mendapatkan info semester mahasiswa
router.get('/mahasiswa/info', akademikController.getMahasiswaInfo);





// Rute untuk mendapatkan transkrip mahasiswa
router.get('/mahasiswa/transkrip', akademikController.getTranskrip);

// Rute untuk mengajukan/membatalkan usulan penghapusan
router.post("/mahasiswa/transkrip/usul-hapus", (req, res) => akademikController.updateUsulanHapus(req, res));

// Rute untuk mendapatkan KHS per semester dengan validasi query parameters
router.get('/mahasiswa/khs', 
  ...validateGeneral.pagination,
  akademikController.getKhs
);

// Rute untuk mendapatkan KRS per semester dengan validasi query parameters
router.get('/mahasiswa/krs', 
  ...validateGeneral.pagination,
  akademikController.getKrs
);

export default router;