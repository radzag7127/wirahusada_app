// src/services/akademikService.ts

import { executeWisakaQuery } from "../config/database";
import {
  Course,
  Transkrip,
  Khs,
  KhsCourse,
  Rekapitulasi,
  Krs,
  KrsCourse,
  DaftarMahasiswa,
} from "../types";

export class AkademikService {
  /**
   * Mengambil daftar semua mahasiswa (NRM dan Nama)
   */
  async getDaftarMahasiswa(): Promise<DaftarMahasiswa[]> {
    const sql = `
      SELECT
        a.nrm,
        m.namam
      FROM u4714151_wisaka.akademik AS a
      JOIN u4714151_wis.mahasiswa AS m ON a.nrm = m.nrm
      ORDER BY m.namam ASC;
    `;
    const results = await executeWisakaQuery(sql, []);
    return results as DaftarMahasiswa[];
  }


  async getMahasiswaInfo(nrm: string): Promise<{ semester: number }> {
    const sql = `
      SELECT MAX(semesterke) as semester
      FROM krsmatakuliah
      WHERE nrm = ?;
    `;
    const result = (await executeWisakaQuery(sql, [nrm])) as any[];
    if (result.length === 0 || !result[0].semester) {
      // Jika mahasiswa baru dan belum ada KRS, default ke semester 1
      return { semester: 1 };
    }
    return { semester: result[0].semester };
  }


















  /**
   * Mengambil transkrip akademik lengkap seorang mahasiswa
   * PERUBAHAN: Menambahkan kolom usulan_hapus dari database
   */
  async getTranskrip(nrm: string): Promise<Transkrip> {
    const sql = `
      SELECT
        mk.kdmk AS kodeMataKuliah,
        krs.kurikulum,
        mk.namamk,
        mk.sks,
        krs.nilai,
        krs.bobotnilai AS bobotNilai,
        krs.semesterke AS semesterKe,
        krs.usulan_hapus AS usulanHapus
      FROM
        krsmatakuliah AS krs
      JOIN
        matakuliah AS mk
      ON krs.kdmk = mk.kdmk
        AND krs.kurikulum = mk.kurikulum
      WHERE
        krs.nrm = ?
      ORDER BY
        mk.kdmk, krs.semesterke;
    `;

    const courses = (await executeWisakaQuery(sql, [nrm])) as Course[];

    if (courses.length === 0) {
      throw new Error(
        "Tidak ada data transkrip ditemukan untuk mahasiswa ini."
      );
    }

    let totalSks = 0;
    let totalBobot = 0;

    courses.forEach((course) => {
      if (course.bobotNilai != null && course.sks != null) {
        totalSks += course.sks;
        totalBobot += course.bobotNilai * course.sks;
      }
    });

    const ipk = totalSks > 0 ? totalBobot / totalSks : 0;

    return {
      ipk: ipk.toFixed(2),
      total_sks: totalSks,
      courses: courses,
    };
  }

  /**
   * FUNGSI BARU: Mengubah status usulan penghapusan mata kuliah.
   * Fungsi ini membutuhkan kunci unik dari baris data: nrm, kdmk, kurikulum, dan semesterke.
   */
  async updateUsulanHapus(
    nrm: string,
    kodeMataKuliah: string,
    kurikulum: string,
    semesterKe: number,
    newStatus: boolean
  ): Promise<boolean> {
    const sql = `
      UPDATE krsmatakuliah
      SET usulan_hapus = ?
      WHERE nrm = ? AND kdmk = ? AND kurikulum = ? AND semesterke = ?;
    `;

    const result = await executeWisakaQuery(sql, [
      newStatus,
      nrm,
      kodeMataKuliah,
      kurikulum,
      semesterKe,
    ]);
    
    // Mengembalikan true jika ada baris yang terpengaruh (berhasil di-update)
    return (result as any).affectedRows > 0;
  }

  /**
   * Get transcript summary data for Beranda page
   * Returns only aggregated data without full course list
   */
  async getTranscriptSummary(nrm: string) {
    console.log("📚 AKADEMIK SERVICE - getTranscriptSummary called:", {
      nrm,
      timestamp: new Date().toISOString(),
    });

    try {
      const sql = `
        SELECT
          mk.sks,
          krs.bobotnilai,
          COALESCE(krs.usulan_hapus, FALSE) AS usulan_hapus
        FROM
          krsmatakuliah AS krs
        JOIN
          matakuliah AS mk
        ON krs.kdmk = mk.kdmk
          AND krs.kurikulum = mk.kurikulum
        WHERE
          krs.nrm = ?
          AND krs.bobotnilai IS NOT NULL
          AND mk.sks IS NOT NULL;
      `;

      const courses = (await executeWisakaQuery(sql, [nrm])) as any[];

      if (courses.length === 0) {
        console.log(
          "📚 AKADEMIK SERVICE - No transcript data found for student:",
          nrm
        );
        return {
          totalSks: 0,
          totalBobot: 0,
          ipKumulatif: 0,
        };
      }

      let totalSks = 0;
      let totalBobot = 0;

      courses.forEach((course) => {
        if (course.bobotnilai !== null && course.sks != null) {
          totalSks += course.sks;
          totalBobot += course.bobotnilai * course.sks;
        }
      });

      const ipk = totalSks > 0 ? totalBobot / totalSks : 0;

      const summary = {
        totalSks,
        totalBobot: parseFloat(totalBobot.toFixed(1)),
        ipKumulatif: parseFloat(ipk.toFixed(2)),
      };

      console.log(
        "📚 AKADEMIK SERVICE - Transcript summary calculated:",
        summary
      );

      return summary;
    } catch (error) {
      console.error(
        "📚 AKADEMIK SERVICE - Error getting transcript summary:",
        error
      );
      throw error;
    }
  }

  /**
   * Mengambil Kartu Hasil Studi (KHS) mahasiswa, lengkap dengan rekapitulasi IP dan SKS.
   * Fungsi ini mengadopsi struktur dari getKrs dan mengembangkannya untuk kebutuhan KHS.
   * Updated: Handles usulan_hapus column gracefully
   */
  async getKhs(nrm: string, semesterKe: number, jenisSemester: number): Promise<Khs> {
    const query = `
      SELECT
          k.semesterke,
          k.semester AS jenisSemesterKode,
          k.tahun,
          km.nilai,
          km.bobotnilai,
          km.status,
          mk.kdmk,
          mk.namamk,
          mk.sks,
          kls.nama AS kelas,
          COALESCE(km.usulan_hapus, FALSE) AS usulan_hapus
      FROM
          krsmatakuliah km
      JOIN
          matakuliah mk ON km.kdmk = mk.kdmk AND km.kurikulum = mk.kurikulum
      LEFT JOIN
          krs k ON km.nrm = k.nrm AND km.semesterke = k.semesterke AND km.semesterkrs = k.semester
      LEFT JOIN
          kelasmahasiswa kls ON km.nrm = kls.nrm
              AND k.tahun = kls.tahun
              AND km.semesterkrs = kls.semester
              AND km.kdmk = kls.kdmk
      WHERE
          km.nrm = ?
      ORDER BY
          k.semesterke, mk.kdmk;
    `;

    const allCoursesHistory = (await executeWisakaQuery(query, [nrm])) as any[];

    if (allCoursesHistory.length === 0) {
      throw new Error("Tidak ada data riwayat studi ditemukan untuk mahasiswa ini.");
    }

    let sksSemesterBeban = 0, sksSemesterLulus = 0;
    let totalBobotSemester = 0, totalBobotLulusSemester = 0;
    let sksKumulatifBeban = 0, sksKumulatifLulus = 0;
    let totalBobotKumulatif = 0, totalBobotLulusKumulatif = 0;
    const mataKuliahList: KhsCourse[] = [];
    let semesterInfo: any = null;

    for (const course of allCoursesHistory) {
      const sks = Number(course.sks) || 0;
      const bobotNilai = Number(course.bobotnilai) || 0;
      const isLulus = course.status === 1;

      // PERUBAHAN: Kalkulasi untuk semester yang dipilih, sekarang mencocokkan jenis semester juga
      if (course.semesterke === semesterKe && course.jenisSemesterKode === jenisSemester) {
        if (!semesterInfo) {
          semesterInfo = course;
        }
        sksSemesterBeban += sks;
        totalBobotSemester += sks * bobotNilai;
        if (isLulus) {
          sksSemesterLulus += sks;
          totalBobotLulusSemester += sks * bobotNilai;
        }
        mataKuliahList.push({
          nilai: course.nilai || '-',
          kodeMataKuliah: course.kdmk,
          namaMataKuliah: course.namamk,
          sks: sks,
          kelas: course.kelas || null,
        });
      }

      // Kalkulasi kumulatif (tidak berubah, tetap mengakumulasi semua semester sebelumnya)
      if (course.semesterke <= semesterKe) {
        sksKumulatifBeban += sks;
        totalBobotKumulatif += sks * bobotNilai;
        if (isLulus) {
          sksKumulatifLulus += sks;
          totalBobotLulusKumulatif += sks * bobotNilai;
        }
      }
    }

    if (!semesterInfo) {
      throw new Error(`Tidak ada data KHS ditemukan untuk semester ${semesterKe} yang dipilih.`);
    }

    const ipSemesterBeban = sksSemesterBeban > 0 ? totalBobotSemester / sksSemesterBeban : 0;
    const ipSemesterLulus = sksSemesterLulus > 0 ? totalBobotLulusSemester / sksSemesterLulus : 0;
    const ipKumulatifBeban = sksKumulatifBeban > 0 ? totalBobotKumulatif / sksKumulatifBeban : 0;
    const ipKumulatifLulus = sksKumulatifLulus > 0 ? totalBobotLulusKumulatif / sksKumulatifLulus : 0;

    const rekapitulasi: Rekapitulasi = {
      ipSemester: `${ipSemesterLulus.toFixed(2)} / ${ipSemesterBeban.toFixed(2)}`,
      sksSemester: `${sksSemesterLulus} / ${sksSemesterBeban}`,
      ipKumulatif: `${ipKumulatifLulus.toFixed(2)} / ${ipKumulatifBeban.toFixed(2)}`,
      sksKumulatif: `${sksKumulatifLulus} / ${sksKumulatifBeban}`,
    };

    const getJenisSemesterText = (kode: number): string => {
        switch (kode) {
            case 1: return "Ganjil Reguler";
            case 2: return "Genap Reguler";
            case 4: return "Genap Pendek";
            case 5: return "Ganjil Pendek";
            default: return "Tidak Diketahui";
        }
    };

    const khsResult: Khs = {
      semesterKe: semesterInfo.semesterke,
      jenisSemester: getJenisSemesterText(semesterInfo.jenisSemesterKode),
      tahunAjaran: `${semesterInfo.tahun}/${semesterInfo.tahun + 1}`,
      mataKuliah: mataKuliahList,
      rekapitulasi: rekapitulasi,
    };

    return khsResult;
  }

  /**
   * Mengambil Kartu Rencana Studi (KRS) per semester.
   * Query ini diperbaiki untuk menggunakan krs.tahun sebagai acuan join yang benar.
   * REVISED: This function now only requires semesterKe.
   * Updated: Handles usulan_hapus column gracefully
   */
  async getKrs(nrm: string, semesterKe: number, jenisSemester: number): Promise<Krs> {
    // Logika penentuan jenis semester otomatis dihapus, karena sekarang diterima dari parameter.
    
    const query = `
      SELECT
          krs.semesterke AS semesterKe,
          krs.semester AS jenisSemesterKode,
          krs.tahun AS tahunAjaran,
          mk.kdmk AS kodeMataKuliah,
          mk.namamk AS namaMataKuliah,
          mk.sks AS sks,
          kls_mhs.nama AS kelas,
          COALESCE(krs_mk.usulan_hapus, FALSE) AS usulan_hapus
      FROM krs
      JOIN krsmatakuliah AS krs_mk ON krs.nrm = krs_mk.nrm
          AND krs.semesterke = krs_mk.semesterke
          AND krs.semester = krs_mk.semesterkrs
          AND krs.tahun = krs_mk.tahun
      JOIN matakuliah AS mk ON krs_mk.kdmk = mk.kdmk
          AND krs_mk.kurikulum = mk.kurikulum
      LEFT JOIN kelasmahasiswa AS kls_mhs ON krs_mk.nrm = kls_mhs.nrm
          AND krs.tahun = kls_mhs.tahun
          AND krs_mk.semesterkrs = kls_mhs.semester
          AND krs_mk.kdmk = kls_mhs.kdmk
          AND krs_mk.kurikulum = kls_mhs.kurikulum
      WHERE
          krs.nrm = ? 
          AND krs.semesterke = ?
          AND krs.semester = ?  -- PERUBAHAN: Filter berdasarkan jenis semester
      ORDER BY
          mk.kdmk;
    `;

    const krsData = (await executeWisakaQuery(query, [
      nrm,
      semesterKe,
      jenisSemester, // Parameter baru digunakan di sini
    ])) as any[];

    if (krsData.length === 0) {
      throw new Error("Tidak ada data KRS ditemukan untuk semester yang diminta.");
    }

    // PERUBAHAN: Update helper untuk mencakup semester pendek
    const getJenisSemesterText = (kode: number): string => {
      switch (kode) {
        case 1: return "Ganjil Reguler";
        case 2: return "Genap Reguler";
        case 4: return "Genap Pendek";
        case 5: return "Ganjil Pendek";
        default: return "Tidak Diketahui";
      }
    };
    
    // Sisa logika di bawah ini tidak perlu diubah
    const firstRow = krsData[0];
    const mataKuliahList: KrsCourse[] = krsData.map((row: any) => ({
      kodeMataKuliah: row.kodeMataKuliah,
      namaMataKuliah: row.namaMataKuliah,
      sks: row.sks,
      kelas: row.kelas || null,
    }));
    const totalSks = mataKuliahList.reduce((sum, course) => sum + (course.sks || 0), 0);
    
    const krsResult: Krs = {
      semesterKe: firstRow.semesterKe,
      jenisSemester: getJenisSemesterText(firstRow.jenisSemesterKode),
      tahunAjaran: `${firstRow.tahunAjaran}/${firstRow.tahunAjaran + 1}`,
      mataKuliah: mataKuliahList,
      totalSks: totalSks,
    };

    return krsResult;
  }
}
