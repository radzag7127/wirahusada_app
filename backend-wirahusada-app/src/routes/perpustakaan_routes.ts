import express from "express";
import {
  getKoleksi,
  getKoleksiByKode,
  createKoleksi,
  updateKoleksi,
  deleteKoleksi,
  getByKategori,
  createPengajuan
} from "../controllers/perpustakaan/perpustakaan_koleksi.controllers";

import {
  getAktivitas,
  getAktivitasById,
  createAktivitas,
  updateAktivitas,
  deleteAktivitas,
  updateStatusAktivitas
} from "../controllers/perpustakaan/perpustakaan_aktivitas.controllers";

import {
  getMahasiswa,
  getMahasiswaByNrm,
  createMahasiswa
} from "../controllers/perpustakaan/perpustakaan_mahasiswa.controllers";

import { testDbConnection, testMahasiswaData } from "../controllers/perpustakaan/perpustakaan_test.contollers";

const router = express.Router();

// Routes Koleksi
router.get("/koleksi", getKoleksi);
router.get("/koleksi/:kode", getKoleksiByKode);
router.post("/koleksi", createKoleksi);
router.put("/koleksi/:kode", updateKoleksi);
router.delete("/koleksi/:kode", deleteKoleksi);
router.get("/koleksi/kategori/:kategori", getByKategori);
router.post("/pengajuan", createPengajuan);
router.options("/koleksi/:kode", (req, res) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'PUT, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, Accept');
  res.sendStatus(200);
});

// Routes Aktivitas
router.get("/aktivitas", getAktivitas);
router.get("/aktivitas/:id_aktivitas", getAktivitasById);
router.post("/aktivitas", createAktivitas);
router.put("/aktivitas/:id_aktivitas", updateAktivitas);
router.patch("/aktivitas/:id_aktivitas/status", updateStatusAktivitas);
router.delete("/aktivitas/:id_aktivitas", deleteAktivitas);

// Routes Mahasiswa
router.get("/mahasiswa", getMahasiswa);
router.get("/mahasiswa/:nrm", getMahasiswaByNrm);
router.post("/mahasiswa", createMahasiswa);

// Test routes
router.get("/test-db", testDbConnection);
router.get("/test-mahasiswa", testMahasiswaData);

export default router;