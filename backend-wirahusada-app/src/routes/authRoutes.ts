import { Router } from "express";
import { AuthController } from "../controllers/authController";
import { authenticateToken, authenticateRefreshToken } from "../utils/auth";
import { validateAuth } from "../middleware/validation";
import { clearAuthCacheMiddleware, noCacheMiddleware, logoutCacheClearMiddleware } from "../middleware/cacheControl";
import rateLimit from "express-rate-limit";

// Rate limiting configuration for authentication endpoints
const authRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // Limit each IP to 5 login attempts per windowMs
  message: {
    success: false,
    message: "Too many login attempts, please try again later",
    errors: ["Rate limit exceeded"]
  },
  standardHeaders: true,
  legacyHeaders: false,
  // Skip rate limiting in development mode for easier testing
  skip: () => process.env.NODE_ENV === "development"
});

// More restrictive rate limiting for refresh tokens
const refreshRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // Allow more refresh attempts than login attempts
  message: {
    success: false,
    message: "Too many refresh attempts, please try again later",
    errors: ["Refresh rate limit exceeded"]
  },
  standardHeaders: true,
  legacyHeaders: false,
  skip: () => process.env.NODE_ENV === "development"
});

const router = Router();
const authController = new AuthController();

// Public routes with rate limiting and input validation
router.post(
  "/login", 
  authRateLimit, 
  clearAuthCacheMiddleware, // Clear cached auth responses after login
  ...validateAuth.login, 
  authController.login.bind(authController)
);

// Token refresh endpoint with rate limiting and validation
router.post(
  "/refresh", 
  refreshRateLimit,
  clearAuthCacheMiddleware, // Clear cached responses after token refresh
  ...validateAuth.refresh,
  authenticateRefreshToken, 
  authController.refreshToken.bind(authController)
);

// Protected routes (require authentication)
router.get(
  "/profile",
  noCacheMiddleware, // Prevent profile data caching
  authenticateToken,
  authController.getProfile.bind(authController)
);

router.post(
  "/verify",
  noCacheMiddleware, // Prevent token verification caching
  authenticateToken,
  authController.verifyToken.bind(authController)
);

// Logout endpoint (public but secured with CSRF protection via cookies)
router.post(
  "/logout",
  logoutCacheClearMiddleware, // Enhanced cache clearing on logout
  authController.logout.bind(authController)
);

export default router;
