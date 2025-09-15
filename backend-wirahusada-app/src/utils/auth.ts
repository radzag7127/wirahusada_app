import jwt from "jsonwebtoken";
import { Request, Response, NextFunction } from "express";
import crypto from "crypto";

/**
 * Environment validation for JWT security
 * Ensures JWT_SECRET meets security requirements
 */
const validateJwtSecret = (): string => {
  const jwtSecret = process.env.JWT_SECRET;

  if (!jwtSecret) {
    throw new Error(
      "SECURITY ERROR: JWT_SECRET environment variable is required for production security"
    );
  }

  if (jwtSecret.length < 32) {
    throw new Error(
      "SECURITY ERROR: JWT_SECRET must be at least 32 characters long for adequate security"
    );
  }

  return jwtSecret;
};

const validateRefreshSecret = (): string => {
  const refreshSecret = process.env.JWT_REFRESH_SECRET;

  if (!refreshSecret) {
    throw new Error(
      "SECURITY ERROR: JWT_REFRESH_SECRET environment variable is required for refresh token security"
    );
  }

  if (refreshSecret.length < 32) {
    throw new Error(
      "SECURITY ERROR: JWT_REFRESH_SECRET must be at least 32 characters long for adequate security"
    );
  }

  return refreshSecret;
};

// Validate secrets at module load time to fail fast
const JWT_SECRET = validateJwtSecret();
const JWT_REFRESH_SECRET = validateRefreshSecret();

// Token expiration constants
const ACCESS_TOKEN_EXPIRY = "15m"; // 15 minutes (security best practice)
const REFRESH_TOKEN_EXPIRY = "30d"; // 30 days

export interface JWTPayload {
  nrm: string;
  nim: string;
  namam: string;
  type: "access" | "refresh";
  iat?: number;
  exp?: number;
}

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
}

export interface RefreshTokenPayload {
  nrm: string;
  nim: string;
  namam: string;
  tokenId: string; // Unique identifier for token rotation
  type: "refresh";
  iat?: number;
  exp?: number;
}

/**
 * Generate access token (short-lived)
 */
export const generateAccessToken = (
  payload: Omit<JWTPayload, "iat" | "exp" | "type">
): string => {
  const tokenPayload: Omit<JWTPayload, "iat" | "exp"> = {
    ...payload,
    type: "access",
  };

  return jwt.sign(tokenPayload, JWT_SECRET, {
    expiresIn: ACCESS_TOKEN_EXPIRY,
    issuer: "wismon-api",
    audience: "wismon-client",
  });
};

/**
 * Generate refresh token (long-lived)
 */
export const generateRefreshToken = (
  payload: Omit<RefreshTokenPayload, "iat" | "exp" | "type" | "tokenId">
): string => {
  const tokenId = crypto.randomBytes(16).toString("hex");
  const tokenPayload: Omit<RefreshTokenPayload, "iat" | "exp"> = {
    ...payload,
    tokenId,
    type: "refresh",
  };

  return jwt.sign(tokenPayload, JWT_REFRESH_SECRET, {
    expiresIn: REFRESH_TOKEN_EXPIRY,
    issuer: "wismon-api",
    audience: "wismon-client",
  });
};

/**
 * Generate token pair (access + refresh)
 */
export const generateTokenPair = (
  payload: Omit<JWTPayload, "iat" | "exp" | "type">
): TokenPair => {
  const accessToken = generateAccessToken(payload);
  const refreshToken = generateRefreshToken(payload);

  return { accessToken, refreshToken };
};

/**
 * Verify access token
 */
export const verifyAccessToken = (token: string): JWTPayload => {
  try {
    const decoded = jwt.verify(token, JWT_SECRET, {
      issuer: "wismon-api",
      audience: "wismon-client",
    }) as JWTPayload;

    if (decoded.type !== "access") {
      throw new Error("Invalid token type");
    }

    return decoded;
  } catch (error) {
    if (error instanceof jwt.TokenExpiredError) {
      throw new Error("Access token expired");
    }
    if (error instanceof jwt.JsonWebTokenError) {
      throw new Error("Invalid access token");
    }
    throw error;
  }
};

/**
 * Verify refresh token
 */
export const verifyRefreshToken = (token: string): RefreshTokenPayload => {
  try {
    const decoded = jwt.verify(token, JWT_REFRESH_SECRET, {
      issuer: "wismon-api",
      audience: "wismon-client",
    }) as RefreshTokenPayload;

    if (decoded.type !== "refresh") {
      throw new Error("Invalid token type");
    }

    return decoded;
  } catch (error) {
    if (error instanceof jwt.TokenExpiredError) {
      throw new Error("Refresh token expired");
    }
    if (error instanceof jwt.JsonWebTokenError) {
      throw new Error("Invalid refresh token");
    }
    throw error;
  }
};

/**
 * Enhanced authentication middleware with better error handling,
 * security logging, and cache prevention for stale responses
 */
export const authenticateToken = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  // Set no-cache headers immediately to prevent caching of auth errors
  res.set({
    'Cache-Control': 'no-cache, no-store, must-revalidate, private, max-age=0',
    'Pragma': 'no-cache',
    'Expires': '0',
    'X-Auth-Middleware': 'active'
  });

  const authHeader = req.headers["authorization"];
  const token = extractTokenFromHeader(authHeader);

  if (!token) {
    // Add additional cache prevention headers for auth errors
    res.set({
      'Vary': 'Authorization',
      'X-Auth-Error': 'token-missing',
      'Last-Modified': new Date().toUTCString()
    });
    
    res.status(401).json({
      success: false,
      message: "Access token required",
      errors: ["Authorization header with Bearer token is required"],
      _timestamp: new Date().toISOString(), // Ensure unique responses
    });
    return;
  }

  try {
    const decoded = verifyAccessToken(token);

    // Validate user context integrity
    if (!decoded.nrm || !decoded.nim || !decoded.namam) {
      console.warn(
        `🔒 Authentication failed: Invalid token payload - IP: ${
          req.ip
        } - User-Agent: ${req.get("user-agent")} - Timestamp: ${new Date().toISOString()}`
      );
      
      res.status(401).json({
        success: false,
        message: "Invalid token payload",
        errors: ["Token missing required user information"],
        timestamp: new Date().toISOString(),
        _responseId: `auth-error-${Date.now()}`,
      });
      return;
    }

    // Attach user info to request object with proper typing
    (req as any).user = {
      nrm: decoded.nrm,
      nim: decoded.nim,
      namam: decoded.namam,
      tokenType: decoded.type,
    };

    // Add user context to response headers for client-side cache isolation
    res.set({
      'X-User-Context': decoded.nrm,
      'Vary': 'Authorization, X-User-Context'
    });

    next();
  } catch (error) {
    const errorMessage =
      error instanceof Error ? error.message : "Token verification failed";

    // Log security events for monitoring
    console.warn(
      `🔒 Authentication failed: ${errorMessage} - IP: ${
        req.ip
      } - User-Agent: ${req.get("user-agent")} - Timestamp: ${new Date().toISOString()}`
    );

    // Provide more specific status codes and error types
    let statusCode = 401;
    let errorType = "authentication_failed";

    if (errorMessage.includes("expired")) {
      statusCode = 401;
      errorType = "token_expired";
    } else if (errorMessage.includes("Invalid")) {
      statusCode = 403;
      errorType = "token_invalid";
    } else if (errorMessage.includes("required")) {
      statusCode = 401;
      errorType = "token_missing";
    }

    // Add specific cache prevention headers for different error types
    res.set({
      'Vary': 'Authorization',
      'X-Auth-Error': errorType,
      'X-Token-Status': 'failed',
      'Last-Modified': new Date().toUTCString(),
      'ETag': `"auth-error-${Date.now()}-${Math.random().toString(36).substr(2, 9)}"`
    });

    res.status(statusCode).json({
      success: false,
      message: errorMessage,
      errorType: errorType,
      errors: [errorMessage],
      timestamp: new Date().toISOString(),
      _responseId: `auth-error-${Date.now()}`, // Unique identifier to prevent caching
    });
  }
};

/**
 * Middleware specifically for refresh token validation
 */
export const authenticateRefreshToken = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  // Try to get refresh token from httpOnly cookie first, then from body
  const refreshToken = req.cookies?.refreshToken || req.body?.refreshToken;

  if (!refreshToken) {
    res.status(401).json({
      success: false,
      message: "Refresh token required",
      errors: [
        "Refresh token must be provided in httpOnly cookie or request body",
      ],
    });
    return;
  }

  try {
    const decoded = verifyRefreshToken(refreshToken);

    (req as any).refreshTokenData = decoded;

    next();
  } catch (error) {
    const errorMessage =
      error instanceof Error
        ? error.message
        : "Refresh token verification failed";

    console.warn(
      `🔒 Refresh token validation failed: ${errorMessage} - IP: ${req.ip}`
    );

    // Provide specific error types for refresh token failures
    let errorType = "refresh_token_failed";

    if (errorMessage.includes("expired")) {
      errorType = "refresh_token_expired";
    } else if (errorMessage.includes("Invalid")) {
      errorType = "refresh_token_invalid";
    } else if (errorMessage.includes("required")) {
      errorType = "refresh_token_missing";
    }

    res.status(401).json({
      success: false,
      message: errorMessage,
      errorType: errorType,
      errors: [errorMessage],
      timestamp: new Date().toISOString(),
    });
  }
};

/**
 * Extract Bearer token from Authorization header
 */
export const extractTokenFromHeader = (authHeader?: string): string | null => {
  if (!authHeader) return null;

  const parts = authHeader.split(" ");
  if (parts.length !== 2 || parts[0] !== "Bearer") {
    return null;
  }

  const token = parts[1];
  if (!token || token.length === 0) {
    return null;
  }

  return token;
};

/**
 * Cookie configuration for secure token storage
 */
export const getSecureCookieOptions = () => {
  const isProduction = process.env.NODE_ENV === "production";

  return {
    httpOnly: true,
    secure: isProduction, // HTTPS only in production
    sameSite: isProduction ? ("strict" as const) : ("lax" as const),
    maxAge: 30 * 24 * 60 * 60 * 1000, // 30 days, setiap buka aplikasi diperbarui, remove 7 hari
    path: "/",
  };
};

/**
 * Validate environment variables at startup
 * Call this function during application initialization
 */
export const validateAuthEnvironment = (): void => {
  try {
    validateJwtSecret();
    validateRefreshSecret();
    console.log("✅ JWT security environment validation passed");
  } catch (error) {
    console.error("💥 JWT security environment validation failed:", error);
    throw error;
  }
};

/**
 * Legacy token verification (for backward compatibility)
 * @deprecated Use verifyAccessToken instead
 */
export const verifyToken = (token: string): JWTPayload => {
  return verifyAccessToken(token);
};

/**
 * Legacy token generation (for backward compatibility)
 * @deprecated Use generateTokenPair instead
 */
export const generateToken = (
  payload: Omit<JWTPayload, "iat" | "exp" | "type">
): string => {
  return generateAccessToken(payload);
};
