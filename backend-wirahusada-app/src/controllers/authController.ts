import { Request, Response } from "express";
import { AuthService } from "../services/authService";
import { ApiResponse, LoginRequest } from "../types";
import { getSecureCookieOptions, RefreshTokenPayload } from "../utils/auth";

const authService = new AuthService();

// Add request context interface for better type safety
interface AuthenticatedRequest extends Request {
  user?: {
    nrm: string;
    nim: string;
    namam: string;
    tgdaftar?: Date;
    tplahir?: string;  // Place of birth (not date)
    kdagama?: string;
    email?: string;
    phone?: string;
    tokenType: string;
  };
  refreshTokenData?: RefreshTokenPayload;
}

export class AuthController {
  /**
   * POST /auth/login
   * Login endpoint for students
   */
  async login(req: Request, res: Response): Promise<void> {
    console.log("🔐 AUTH LOGIN - Request received:", {
      body: req.body,
      headers: req.headers,
      timestamp: new Date().toISOString(),
    });

    try {
      const { namam_nim, nrm }: LoginRequest = req.body;

      console.log("🔐 AUTH LOGIN - Extracted credentials:", {
        namam_nim,
        nrm,
        namam_nim_type: typeof namam_nim,
        nrm_type: typeof nrm,
      });

      if (!namam_nim || !nrm) {
        console.log("🔐 AUTH LOGIN - Missing credentials");
        res.status(400).json({
          success: false,
          message: "Student name/NIM and NRM are required",
          errors: ["namam_nim and nrm fields are required"],
        } as ApiResponse);
        return;
      }

      console.log("🔐 AUTH LOGIN - Attempting authentication...");
      const loginResult = await authService.login({ namam_nim, nrm });

      console.log("🔐 AUTH LOGIN - Authentication successful:", {
        hasAccessToken: !!loginResult.accessToken,
        hasRefreshToken: !!loginResult.refreshToken,
        userNrm: loginResult.user?.nrm,
        userNim: loginResult.user?.nim,
      });

      // Set refresh token as httpOnly cookie for web clients
      const cookieOptions = getSecureCookieOptions();
      res.cookie('refreshToken', loginResult.refreshToken, cookieOptions);
      
      // For mobile apps, we need to provide refresh token in response body
      // as they can't access httpOnly cookies
      const userAgent = req.get('User-Agent') || '';
      const isMobileApp = !userAgent.includes('Mozilla') && !userAgent.includes('Chrome');
      
      // Return access token in response body (client will store this)
      res.status(200).json({
        success: true,
        message: "Login successful",
        data: {
          accessToken: loginResult.accessToken,
          user: loginResult.user,
          // Include refresh token for mobile apps, exclude for web browsers
          ...(isMobileApp && { refreshToken: loginResult.refreshToken }),
          expiresIn: 900 // Access token expiry in seconds (15 minutes)
        },
      } as ApiResponse);
    } catch (error) {
      console.error("🔐 AUTH LOGIN - Error:", error);

      const errorMessage =
        error instanceof Error ? error.message : "Login failed";
      const statusCode =
        errorMessage.includes("not found") || errorMessage.includes("invalid")
          ? 401
          : 500;

      res.status(statusCode).json({
        success: false,
        message: errorMessage,
        errors: [errorMessage],
      } as ApiResponse);
    }
  }

  /**
   * GET /auth/profile
   * Get current user profile (requires authentication)
   */
  async getProfile(req: Request, res: Response): Promise<void> {
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

      const student = await authService.getStudentProfile(user.nrm);

      if (!student) {
        res.status(404).json({
          success: false,
          message: "Student profile not found",
          errors: ["Student data not found"],
        } as ApiResponse);
        return;
      }

      res.status(200).json({
        success: true,
        message: "Profile retrieved successfully",
        data: {
          nrm: student.nrm,
          nim: student.nim,
          namam: student.namam,
          tgdaftar: student.tgdaftar,
          tplahir: student.tplahir,
          email: student.email || null,
          phone: student.phone || null,
        },
      } as ApiResponse);
    } catch (error) {
      console.error("Get profile error:", error);

      res.status(500).json({
        success: false,
        message: "Failed to retrieve profile",
        errors: [error instanceof Error ? error.message : "Unknown error"],
      } as ApiResponse);
    }
  }

  /**
   * POST /auth/verify
   * Verify JWT access token
   */
  async verifyToken(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user; // Set by authenticateToken middleware

      res.status(200).json({
        success: true,
        message: "Access token is valid",
        data: {
          nrm: user.nrm,
          nim: user.nim,
          namam: user.namam,
          tokenType: user.tokenType,
        },
      } as ApiResponse);
    } catch (error) {
      res.status(401).json({
        success: false,
        message: "Invalid or expired access token",
        errors: ["Access token verification failed"],
      } as ApiResponse);
    }
  }

  /**
   * POST /auth/refresh
   * Refresh access token using refresh token
   */
  async refreshToken(req: Request, res: Response): Promise<void> {
    try {
      const refreshTokenData = (req as any).refreshTokenData as RefreshTokenPayload;
      
      console.log("🔄 TOKEN REFRESH - Request received:", {
        userNrm: refreshTokenData.nrm,
        tokenId: refreshTokenData.tokenId,
        timestamp: new Date().toISOString(),
      });

      // Generate new token pair using the existing user data
      const newTokens = await authService.refreshTokens({
        nrm: refreshTokenData.nrm,
        nim: refreshTokenData.nim,
        namam: refreshTokenData.namam,
      });

      console.log("🔄 TOKEN REFRESH - New tokens generated successfully");

      // Set new refresh token as httpOnly cookie for web clients
      const cookieOptions = getSecureCookieOptions();
      res.cookie('refreshToken', newTokens.refreshToken, cookieOptions);
      
      // Check if this is a mobile app request
      const userAgent = req.get('User-Agent') || '';
      const isMobileApp = !userAgent.includes('Mozilla') && !userAgent.includes('Chrome');
      
      // Return new access token
      res.status(200).json({
        success: true,
        message: "Tokens refreshed successfully",
        data: {
          accessToken: newTokens.accessToken,
          // Include refresh token for mobile apps
          ...(isMobileApp && { refreshToken: newTokens.refreshToken }),
          expiresIn: 900 // Access token expiry in seconds (15 minutes)
        },
      } as ApiResponse);
      
    } catch (error) {
      console.error("🔄 TOKEN REFRESH - Error:", error);
      
      // Clear refresh token cookie on error
      res.clearCookie('refreshToken');
      
      const errorMessage = error instanceof Error ? error.message : "Token refresh failed";
      
      res.status(401).json({
        success: false,
        message: errorMessage,
        errors: ["Please login again"],
      } as ApiResponse);
    }
  }

  /**
   * POST /auth/logout
   * Logout user by clearing refresh token and additional cache data
   */
  async logout(req: Request, res: Response): Promise<void> {
    try {
      // Clear the refresh token cookie
      res.clearCookie('refreshToken');
      
      // Get user info from request if available (for logging)
      const user = (req as any).user;
      
      console.log("🚪 LOGOUT - User logged out successfully", {
        userNrm: user?.nrm || 'unknown',
        timestamp: new Date().toISOString(),
        userAgent: req.get('User-Agent'),
        ip: req.ip
      });
      
      res.status(200).json({
        success: true,
        message: "Logged out successfully",
        data: null,
      } as ApiResponse);
      
    } catch (error) {
      console.error("🚪 LOGOUT - Error:", error);
      
      res.status(500).json({
        success: false,
        message: "Logout failed",
        errors: [error instanceof Error ? error.message : "Unknown error"],
      } as ApiResponse);
    }
  }
}
