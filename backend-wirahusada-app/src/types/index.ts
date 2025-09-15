// User and Authentication Types
export interface User {
  id: string;
  username: string;
  email?: string;
  created_at?: Date;
}

export interface UserRole {
  username: string;
  app: string;
  rid: string;
}

export interface Student {
  nrm: string;
  nim: string;
  namam: string;
  tgdaftar?: Date;
  tplahir?: string;  // Place of birth (not date)
  kdagama?: string;
  email?: string;
  phone?: string;
}

export interface Employee {
  nip: string;
  nama: string;
  kdagama?: string;
}

// Payment Types
export interface PaymentTransaction {
  id: string;
  kode_transaksi: string;
  tanggal: Date;
  total: number;
  status: string;
  jenistransaksi_id?: string;
  akun_debit?: string;
  akun_kredit?: string;
}

export interface PaymentType {
  id: string;
  kode: string;
  nama_jenis: string;
}

export interface Account {
  id: string;
  kode: string;
  nama_akun: string;
}

export interface StudentPayment {
  no: string;
  nrm: string;
  prodi?: string;
  semester?: string;
  tahun_akademik?: string;
  jumlah: number;
  tanggal_bayar: Date;
}

// API Response Types
export interface ApiResponse<T = any> {
  success: boolean;
  message: string;
  data?: T;
  errors?: string[];
  _timestamp?: string; // Cache busting timestamp
  _requestId?: string; // Unique request identifier for debugging
}

export interface LoginRequest {
  namam_nim: string; // Can be student name or NIM
  nrm: string;
}

// Legacy interface - kept for backward compatibility
export interface LoginResponse {
  token: string;
  user: {
    nrm: string;
    nim: string;
    namam: string;
  };
}

// Enhanced login response with dual token system
export interface EnhancedLoginResponse {
  accessToken: string;
  refreshToken: string;
  user: {
    nrm: string;
    nim: string;
    namam: string;
    tgdaftar?: Date;
    tplahir?: string;  // Place of birth (not date)
    kdagama?: string;
    email?: string;
    phone?: string;
  };
  expiresIn: string; // Access token expiry (e.g., "15m")
}

// Token refresh request payload
export interface TokenRefreshRequest {
  refreshToken?: string; // Optional if using httpOnly cookies
}

// Token refresh response
export interface TokenRefreshResponse {
  accessToken: string;
  expiresIn: string;
}

// Enhanced JWT payload with token type
export interface EnhancedJWTPayload {
  nrm: string;
  nim: string;
  namam: string;
  type: "access" | "refresh";
  iat?: number;
  exp?: number;
}

// Refresh token specific payload
export interface RefreshTokenPayload extends EnhancedJWTPayload {
  tokenId: string; // Unique identifier for token rotation
  type: "refresh";
}

// Security event logging interface
export interface SecurityEvent {
  type: "login" | "logout" | "token_refresh" | "auth_failure";
  userId?: string;
  ip?: string;
  userAgent?: string;
  timestamp: Date;
  details?: Record<string, any>;
}

export interface PaymentHistoryQuery {
  page?: number;
  limit?: number;
  startDate?: string;
  endDate?: string;
  type?: string;
  sortBy?: "tanggal" | "jumlah" | "type";
  sortOrder?: "asc" | "desc";
}

export interface PaymentHistoryItem {
  id: string;
  tanggal: string;
  tanggal_full: string;
  type: string;
  jumlah: string;
  status: string;
  tx_id: string;
  method: string;
  method_code: string;
}

export interface PaymentSummary {
  total_pembayaran: string;
  breakdown: {
    [key: string]: string;
  };
}

export interface TransactionDetail extends PaymentHistoryItem {
  student_name: string;
  student_nim: string;
  student_prodi: string;
  payment_breakdown: {
    [key: string]: string;
  };
}






// --- Akademik ---
export interface Course {
  kodeMataKuliah: string; // PERUBAHAN: Ditambahkan
  kurikulum: string; // PERUBAHAN: Ditambahkan
  namamk: string;
  sks: number;
  nilai?: string;
  bobotNilai: number;
  semesterKe?: number;

  // --- PERUBAHAN: Tambahkan properti untuk status usulan hapus (INI BARU SOALNYA SAMPE ALTER DB) ---
  usulanHapus?: boolean;
}


export interface Transkrip {
  ipk: string;
  total_sks: number;
  courses: Course[];
}

/**
 * Legacy JWT payload interface - kept for backward compatibility
 * @deprecated Use EnhancedJWTPayload instead
 */
export interface JWTPayload {
  nrm: string;
  nim: string;
  namam: string;
  iat?: number;
  exp?: number;
}

/**
 * Interface untuk struktur data KRS yang akan dikirim sebagai respons API.
 */
export interface Krs {
  semesterKe: number;
  jenisSemester: string; // e.g., "Ganjil", "Genap"
  tahunAjaran: string; // e.g., "2023/2024"
  mataKuliah: KrsCourse[];
  totalSks: number;
}

/**
* Merepresentasikan objek KHS secara keseluruhan yang akan dikirim sebagai respons.
*/
export interface Khs {
  semesterKe: number;
  jenisSemester: string;
  tahunAjaran: string;
  mataKuliah: KhsCourse[];
  rekapitulasi: Rekapitulasi;
}

// ITU KRSCOURSE SAMA KHSCOURSE REDUNDANT, MUNGKIN BAKALAN TAK BENERIN KALAU UDAH SELESAI
/**
 * Interface untuk satu mata kuliah yang ada di dalam KRS.
 */
export interface KrsCourse {
  kodeMataKuliah: string;
  namaMataKuliah: string;
  sks: number;
  kelas: string | null; // Kelas bisa jadi null jika tidak ada data kelas yang cocok
}

/**
 * Merepresentasikan satu mata kuliah dalam Kartu Hasil Studi (KHS).
 */
export interface KhsCourse {
  nilai: string; // Nilai huruf (A, B, C, D, E)
  kodeMataKuliah: string;
  namaMataKuliah: string;
  sks: number;
  kelas: string | null;
}

/**
* Merepresentasikan rekapitulasi perhitungan IP dan SKS.
*/
export interface Rekapitulasi {
  ipSemester: string;      // Format: "Lulus / Beban" -> "3.50 / 3.25"
  sksSemester: string;     // Format: "Lulus / Beban" -> "18 / 20"
  ipKumulatif: string;     // Format: "Lulus / Beban"
  sksKumulatif: string;    // Format: "Lulus / Beban"
}

export interface DaftarMahasiswa {
  nrm: string;
  nama: string;
}
