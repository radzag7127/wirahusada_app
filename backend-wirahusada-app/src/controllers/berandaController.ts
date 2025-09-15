import { Request, Response } from "express";
import { BerandaService } from "../services/berandaService";
import { ApiResponse } from "../types";

const berandaService = new BerandaService();

export class BerandaController {
  /**
   * GET /beranda
   * Get aggregated data for the homepage
   */
  async getBerandaData(req: Request, res: Response): Promise<void> {
    console.log("🏠 BERANDA CONTROLLER - Request received:", {
      timestamp: new Date().toISOString(),
    });

    try {
      const user = (req as any).user; // Set by authenticateToken middleware

      console.log("🏠 BERANDA CONTROLLER - User from token:", {
        nrm: user?.nrm,
        nrm_type: typeof user?.nrm,
        hasUser: !!user,
      });

      if (!user || !user.nrm) {
        console.log("🏠 BERANDA CONTROLLER - Authentication failed");
        const response: ApiResponse<null> = {
          success: false,
          message: "Authentication required",
          data: null,
        };
        res.status(401).json(response);
        return;
      }

      console.log(
        "🏠 BERANDA CONTROLLER - Fetching beranda data for NRM:",
        user.nrm
      );

      const berandaData = await berandaService.getBerandaData(user.nrm);

      console.log("🏠 BERANDA CONTROLLER - Data fetched successfully");

      const response: ApiResponse<typeof berandaData> = {
        success: true,
        message: "Beranda data retrieved successfully",
        data: berandaData,
        _timestamp: new Date().toISOString(), // Add timestamp for cache busting
        _requestId: `beranda-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`, // Unique request ID
      };

      // Set additional headers to ensure fresh data after re-authentication
      res.set({
        'X-Data-Freshness': 'live',
        'X-User-Context': user.nrm.substr(-4), // Last 4 chars of NRM for debugging
        'Last-Modified': new Date().toUTCString(),
      });

      res.status(200).json(response);
    } catch (error) {
      console.error("🏠 BERANDA CONTROLLER - Error:", error);

      const response: ApiResponse<null> = {
        success: false,
        message:
          error instanceof Error
            ? error.message
            : "Failed to fetch beranda data",
        data: null,
      };

      res.status(500).json(response);
    }
  }

  /**
   * GET /beranda/announcements
   * Get announcements for the hero carousel
   */
  async getAnnouncements(req: Request, res: Response): Promise<void> {
    console.log("🏠 BERANDA CONTROLLER - Announcements request received:", {
      timestamp: new Date().toISOString(),
    });

    try {
      const announcements = await berandaService.getAnnouncements();

      console.log("🏠 BERANDA CONTROLLER - Announcements fetched successfully");

      const response: ApiResponse<typeof announcements> = {
        success: true,
        message: "Announcements retrieved successfully",
        data: announcements,
      };

      res.status(200).json(response);
    } catch (error) {
      console.error("🏠 BERANDA CONTROLLER - Announcements error:", error);

      const response: ApiResponse<null> = {
        success: false,
        message:
          error instanceof Error
            ? error.message
            : "Failed to fetch announcements",
        data: null,
      };

      res.status(500).json(response);
    }
  }
}
