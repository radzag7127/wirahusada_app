import { Request, Response } from "express";
import { PaymentService } from "../services/paymentService";
import { ApiResponse, PaymentHistoryQuery } from "../types";

const paymentService = new PaymentService();

export class PaymentController {
  /**
   * GET /payments/history
   * Get payment history with filtering and pagination
   */
  async getPaymentHistory(req: Request, res: Response): Promise<void> {
    console.log("💳 PAYMENT HISTORY - Request received:", {
      query: req.query,
      timestamp: new Date().toISOString(),
    });

    try {
      const user = (req as any).user; // Set by authenticateToken middleware

      console.log("💳 PAYMENT HISTORY - User from token:", {
        nrm: user?.nrm,
        nrm_type: typeof user?.nrm,
        hasUser: !!user,
      });

      if (!user || !user.nrm) {
        console.log("💳 PAYMENT HISTORY - Authentication failed");
        res.status(401).json({
          success: false,
          message: "Authentication required",
          errors: ["User not found in request"],
        } as ApiResponse);
        return;
      }

      // Parse query parameters
      const filters: PaymentHistoryQuery = {
        page: parseInt(req.query.page as string) || 1,
        limit: parseInt(req.query.limit as string) || 20,
        startDate: req.query.startDate as string,
        endDate: req.query.endDate as string,
        type: req.query.type as string,
        sortBy:
          (req.query.sortBy as "tanggal" | "jumlah" | "type") || "tanggal",
        sortOrder: (req.query.sortOrder as "asc" | "desc") || "desc",
      };

      console.log("💳 PAYMENT HISTORY - Parsed filters:", {
        filters,
        userNrm: user.nrm,
        userNrmType: typeof user.nrm,
      });

      console.log("💳 PAYMENT HISTORY - Calling service...");
      const result = await paymentService.getPaymentHistory(user.nrm, filters);

      console.log("💳 PAYMENT HISTORY - Service result:", {
        dataCount: result?.data?.length || 0,
        total: result?.total,
        page: result?.page,
        limit: result?.limit,
        firstItem: result?.data?.[0],
      });

      // Add user context to response for additional cache isolation
      res.set('X-User-Context-Payment', user.nrm);
      
      res.status(200).json({
        success: true,
        message: "Payment history retrieved successfully",
        data: result,
        _userContext: user.nrm, // Add user context to response body for client validation
      } as ApiResponse);
    } catch (error) {
      console.error("💳 PAYMENT HISTORY - Error:", error);

      res.status(500).json({
        success: false,
        message: "Failed to retrieve payment history",
        errors: [error instanceof Error ? error.message : "Unknown error"],
      } as ApiResponse);
    }
  }

  /**
   * GET /payments/summary
   * Get payment summary/recapitulation
   */
  async getPaymentSummary(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user; // Set by authenticateToken middleware

      if (!user || !user.nrm) {
        res.status(401).json({
          success: false,
          message: "Authentication required",
          errors: ["User not found in request"],
        } as ApiResponse);
        return;
      }

      const summary = await paymentService.getPaymentSummary(user.nrm);

      res.status(200).json({
        success: true,
        message: "Payment summary retrieved successfully",
        data: summary,
      } as ApiResponse);
    } catch (error) {
      console.error("Get payment summary error:", error);

      res.status(500).json({
        success: false,
        message: "Failed to retrieve payment summary",
        errors: [error instanceof Error ? error.message : "Unknown error"],
      } as ApiResponse);
    }
  }

  /**
   * GET /payments/detail/:id
   * Get detailed transaction information
   */
  async getTransactionDetail(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user; // Set by authenticateToken middleware
      const transactionId = req.params.id;

      if (!user || !user.nrm) {
        res.status(401).json({
          success: false,
          message: "Authentication required",
          errors: ["User not found in request"],
        } as ApiResponse);
        return;
      }

      if (!transactionId) {
        res.status(400).json({
          success: false,
          message: "Transaction ID is required",
          errors: ["Transaction ID parameter is missing"],
        } as ApiResponse);
        return;
      }

      const detail = await paymentService.getTransactionDetail(
        transactionId,
        user.nrm
      );

      if (!detail) {
        res.status(404).json({
          success: false,
          message: "Transaction not found",
          errors: ["Transaction not found or does not belong to this user"],
        } as ApiResponse);
        return;
      }

      res.status(200).json({
        success: true,
        message: "Transaction detail retrieved successfully",
        data: detail,
      } as ApiResponse);
    } catch (error) {
      console.error("Get transaction detail error:", error);

      res.status(500).json({
        success: false,
        message: "Failed to retrieve transaction detail",
        errors: [error instanceof Error ? error.message : "Unknown error"],
      } as ApiResponse);
    }
  }

  /**
   * POST /payments/refresh
   * Refresh payment data
   */
  async refreshPaymentData(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user; // Set by authenticateToken middleware

      if (!user || !user.nrm) {
        res.status(401).json({
          success: false,
          message: "Authentication required",
          errors: ["User not found in request"],
        } as ApiResponse);
        return;
      }

      const refreshed = await paymentService.refreshPaymentData(user.nrm);

      if (refreshed) {
        res.status(200).json({
          success: true,
          message: "Payment data refreshed successfully",
          data: { refreshed: true },
        } as ApiResponse);
      } else {
        res.status(400).json({
          success: false,
          message: "Failed to refresh payment data",
          errors: ["No payment data found for this user"],
        } as ApiResponse);
      }
    } catch (error) {
      console.error("Refresh payment data error:", error);

      res.status(500).json({
        success: false,
        message: "Failed to refresh payment data",
        errors: [error instanceof Error ? error.message : "Unknown error"],
      } as ApiResponse);
    }
  }

  /**
   * GET /payments/types
   * Get available payment types for filtering
   */
  async getPaymentTypes(req: Request, res: Response): Promise<void> {
    console.log("💳 PAYMENT TYPES - Request received:", {
      timestamp: new Date().toISOString(),
    });

    try {
      console.log("💳 PAYMENT TYPES - Calling service...");
      const paymentTypes = await paymentService.getPaymentTypes();

      console.log("💳 PAYMENT TYPES - Service result:", {
        count: paymentTypes?.length || 0,
        types: paymentTypes,
      });

      res.status(200).json({
        success: true,
        message: "Payment types retrieved successfully",
        data: paymentTypes,
      } as ApiResponse);
    } catch (error) {
      console.error("💳 PAYMENT TYPES - Error:", error);

      res.status(500).json({
        success: false,
        message: "Failed to retrieve payment types",
        errors: [error instanceof Error ? error.message : "Unknown error"],
      } as ApiResponse);
    }
  }
}
