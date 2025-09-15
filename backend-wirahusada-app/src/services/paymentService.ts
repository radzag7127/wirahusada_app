import { executeWismonQuery, executeWisQuery } from "../config/database";
import {
  PaymentHistoryItem,
  PaymentSummary,
  TransactionDetail,
  PaymentHistoryQuery,
  Student,
} from "../types";

export class PaymentService {
  /**
   * Get payment history for a student with filtering and pagination
   */
  async getPaymentHistory(
    nrm: string,
    filters: PaymentHistoryQuery = {}
  ): Promise<{
    data: PaymentHistoryItem[];
    total: number;
    page: number;
    limit: number;
  }> {
    console.log("🗄️ PAYMENT SERVICE - getPaymentHistory called:", {
      nrm,
      nrmType: typeof nrm,
      filters,
      timestamp: new Date().toISOString(),
    });

    try {
      const {
        page = 1,
        limit = 20,
        startDate,
        endDate,
        type,
        sortBy = "tanggal",
        sortOrder = "desc",
      } = filters;

      const offset = (page - 1) * limit;

      console.log("🗄️ PAYMENT SERVICE - Processed parameters:", {
        page,
        limit,
        offset,
        startDate,
        endDate,
        type,
        sortBy,
        sortOrder,
      });

      // Build WHERE conditions
      const conditions = ["tpm.nrm = ?"];
      const params = [nrm];

      if (startDate) {
        conditions.push("t.tanggal >= ?");
        params.push(startDate);
      }

      if (endDate) {
        conditions.push("t.tanggal <= ?");
        params.push(endDate);
      }

      if (type) {
        conditions.push("a_credit.nama LIKE ?");
        params.push(`%${type}%`);
      }

      // Build ORDER BY clause
      let orderByClause = "";
      switch (sortBy) {
        case "tanggal":
          orderByClause = `ORDER BY t.tanggal ${sortOrder.toUpperCase()}, t.jam ${sortOrder.toUpperCase()}`;
          break;
        case "jumlah":
          orderByClause = `ORDER BY t.nominal ${sortOrder.toUpperCase()}`;
          break;
        case "type":
          orderByClause = `ORDER BY a_credit.nama ${sortOrder.toUpperCase()}`;
          break;
        default:
          orderByClause = `ORDER BY t.tanggal ${sortOrder.toUpperCase()}, t.jam ${sortOrder.toUpperCase()}`;
      }

      // Main query for payment history
      const query = `
        SELECT 
          t.no as id,
          t.no as tx_id,
          DATE_FORMAT(t.tanggal, '%d %M %Y') as tanggal,
          DATE_FORMAT(CONCAT(t.tanggal, ' ', IFNULL(t.jam, '00:00:00')), '%d %M %Y, %H:%i:%s WIB') as tanggal_full,
          a_credit.nama as type,
          CONCAT('Rp ', FORMAT(t.nominal, 0)) as jumlah,
          'LUNAS' as status,
          CONCAT(a_debit.kode, ' - ', a_debit.nama) as method,
          a_debit.kode as method_code
        FROM transaksi t
        INNER JOIN t_pembayaranmahasiswa tpm ON t.no = tpm.no
        LEFT JOIN akun a_debit ON t.kodeakundebit = a_debit.kode
        LEFT JOIN akun a_credit ON t.kodeakunkredit = a_credit.kode
        WHERE ${conditions.join(" AND ")}
        ${orderByClause}
        LIMIT ? OFFSET ?
      `;

      params.push(limit.toString(), offset.toString());

      console.log("🗄️ PAYMENT SERVICE - Final query params:", {
        conditions: conditions.join(" AND "),
        params,
        paramsTypes: params.map((p) => typeof p),
      });

      // Count query for total records
      const countQuery = `
        SELECT COUNT(*) as total
        FROM transaksi t
        INNER JOIN t_pembayaranmahasiswa tpm ON t.no = tpm.no
        LEFT JOIN akun a_debit ON t.kodeakundebit = a_debit.kode
        LEFT JOIN akun a_credit ON t.kodeakunkredit = a_credit.kode
        WHERE ${conditions.join(" AND ")}
      `;

      const countParams = params.slice(0, -2); // Remove limit and offset

      console.log("🗄️ PAYMENT SERVICE - Executing queries:", {
        mainQuery: query.replace(/\s+/g, " ").trim(),
        countQuery: countQuery.replace(/\s+/g, " ").trim(),
        mainParams: params,
        countParams,
      });

      // Execute queries
      const [results, countResults] = await Promise.all([
        executeWismonQuery(query, params) as Promise<any[]>,
        executeWismonQuery(countQuery, countParams) as Promise<any[]>,
      ]);

      console.log("🗄️ PAYMENT SERVICE - Raw query results:", {
        resultsCount: results?.length || 0,
        countResult: countResults?.[0],
        firstResult: results?.[0],
        allResults: results,
      });

      const total = (countResults as any[])[0]?.total || 0;

      console.log("🗄️ PAYMENT SERVICE - Returning data:", {
        dataCount: results?.length || 0,
        total,
        page,
        limit,
      });

      return {
        data: results as PaymentHistoryItem[],
        total,
        page,
        limit,
      };
    } catch (error) {
      console.error("Error getting payment history:", error);
      throw new Error("Database error while getting payment history");
    }
  }

  /**
   * Get payment summary/recapitulation for a student
   */
  async getPaymentSummary(nrm: string): Promise<PaymentSummary> {
    try {
      const query = `
        SELECT 
          a_credit.nama as payment_type,
          SUM(t.nominal) as total_amount
        FROM transaksi t
        INNER JOIN t_pembayaranmahasiswa tpm ON t.no = tpm.no
        LEFT JOIN akun a_credit ON t.kodeakunkredit = a_credit.kode
        WHERE tpm.nrm = ?
        GROUP BY a_credit.nama, a_credit.kode
        ORDER BY total_amount DESC
      `;

      const results = (await executeWismonQuery(query, [nrm])) as any[];

      const breakdown: { [key: string]: string } = {};
      let totalPayment = 0;

      results.forEach((row: any) => {
        const amount = parseFloat(row.total_amount) || 0;
        breakdown[row.payment_type] = `Rp ${amount.toLocaleString("id-ID")}`;
        totalPayment += amount;
      });

      return {
        total_pembayaran: `Rp ${totalPayment.toLocaleString("id-ID")}`,
        breakdown,
      };
    } catch (error) {
      console.error("Error getting payment summary:", error);
      throw new Error("Database error while getting payment summary");
    }
  }

  /**
   * Get detailed transaction information
   */
  async getTransactionDetail(
    transactionId: string,
    nrm: string
  ): Promise<TransactionDetail | null> {
    try {
      // Get transaction details
      const query = `
        SELECT 
          t.no as id,
          t.no as tx_id,
          DATE_FORMAT(t.tanggal, '%d %M %Y') as tanggal,
          DATE_FORMAT(CONCAT(t.tanggal, ' ', IFNULL(t.jam, '00:00:00')), '%d %M %Y, %H:%i:%s WIB') as tanggal_full,
          a_credit.nama as type,
          CONCAT('Rp ', FORMAT(t.nominal, 0)) as jumlah,
          'LUNAS' as status,
          CONCAT(a_debit.kode, ' - ', a_debit.nama) as method,
          a_debit.kode as method_code,
          tpm.prodi
        FROM transaksi t
        INNER JOIN t_pembayaranmahasiswa tpm ON t.no = tpm.no
        LEFT JOIN akun a_debit ON t.kodeakundebit = a_debit.kode
        LEFT JOIN akun a_credit ON t.kodeakunkredit = a_credit.kode
        WHERE t.no = ? AND tpm.nrm = ?
      `;

      const results = (await executeWismonQuery(query, [
        transactionId,
        nrm,
      ])) as any[];

      if (results.length === 0) {
        return null;
      }

      const transaction = results[0];

      // Get student information
      const studentQuery = `
        SELECT nrm, nim, namam 
        FROM mahasiswa 
        WHERE nrm = ?
      `;

      const studentResults = (await executeWisQuery(studentQuery, [
        nrm,
      ])) as any[];
      const student = studentResults[0] || {};

      // Build transaction detail
      const transactionDetail: TransactionDetail = {
        id: transaction.id,
        tanggal: transaction.tanggal,
        tanggal_full: transaction.tanggal_full,
        type: transaction.type,
        jumlah: transaction.jumlah,
        status: transaction.status,
        tx_id: transaction.tx_id,
        method: transaction.method,
        method_code: transaction.method_code,
        student_name: student.namam || "Unknown",
        student_nim: student.nim || "Unknown",
        student_prodi: transaction.prodi || "Unknown",
        payment_breakdown: {
          [transaction.type]: transaction.jumlah,
        },
      };

      return transactionDetail;
    } catch (error) {
      console.error("Error getting transaction detail:", error);
      throw new Error("Database error while getting transaction detail");
    }
  }

  /**
   * Refresh payment data (mainly for triggering cache refresh if needed)
   */
  async refreshPaymentData(nrm: string): Promise<boolean> {
    try {
      // This could include cache clearing logic in the future
      // For now, just verify the student exists
      const query = `
        SELECT COUNT(*) as count
        FROM t_pembayaranmahasiswa 
        WHERE nrm = ?
      `;

      const results = (await executeWismonQuery(query, [nrm])) as any[];
      return results.length > 0;
    } catch (error) {
      console.error("Error refreshing payment data:", error);
      return false;
    }
  }

  /**
   * Get available payment types from the database
   */
  async getPaymentTypes(): Promise<{ kode: string; nama: string }[]> {
    try {
      const query = `
        SELECT DISTINCT a.kode, a.nama 
        FROM akun a
        INNER JOIN transaksi t ON t.kodeakunkredit = a.kode
        INNER JOIN t_pembayaranmahasiswa tpm ON t.no = tpm.no
        WHERE a.kode >= 400 AND a.kode < 500
        ORDER BY a.kode
      `;

      console.log("🗄️ PAYMENT SERVICE - Getting payment types from akun table");

      const results = (await executeWismonQuery(query, [])) as any[];

      console.log("🗄️ PAYMENT SERVICE - Payment types retrieved:", {
        count: results?.length || 0,
        types: results,
      });

      return results as { kode: string; nama: string }[];
    } catch (error) {
      console.error("Error getting payment types:", error);
      throw new Error("Database error while getting payment types");
    }
  }
}
