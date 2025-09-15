import { Request, Response, NextFunction } from "express";

/**
 * Cache Control Middleware
 * 
 * This middleware prevents caching of sensitive API responses to avoid
 * session persistence issues where expired authentication responses
 * are cached by clients/browsers.
 * 
 * Critical for fixing the "session cache not refreshing after re-login" issue.
 */

/**
 * No-cache middleware for authentication-sensitive endpoints
 * Prevents any caching of responses that contain user-specific or session data
 */
export const noCacheMiddleware = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  // Set comprehensive no-cache headers
  res.set({
    'Cache-Control': 'no-cache, no-store, must-revalidate, private, max-age=0',
    'Pragma': 'no-cache',
    'Expires': '0',
    'Last-Modified': new Date().toUTCString(),
    'Surrogate-Control': 'no-store'
  });

  // Add a unique ETag to prevent conditional caching
  const etag = `"${Date.now()}-${Math.random().toString(36).substr(2, 9)}"`;
  res.set('ETag', etag);

  // Add timestamp header for debugging cache issues
  res.set('X-Response-Time', new Date().toISOString());
  
  // Add custom header to identify cache-controlled responses
  res.set('X-Cache-Control', 'no-cache-applied');

  next();
};

/**
 * Short-term cache middleware for less sensitive data
 * Allows caching for 60 seconds with validation requirements
 */
export const shortCacheMiddleware = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  res.set({
    'Cache-Control': 'private, max-age=60, must-revalidate',
    'Last-Modified': new Date().toUTCString(),
  });

  next();
};

/**
 * Enhanced authentication cache middleware
 * Specifically designed for authenticated endpoints to prevent
 * stale authentication responses from being cached
 */
export const authCacheMiddleware = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  // Get the authorization header to include in cache invalidation
  const authHeader = req.headers.authorization || '';
  const hasValidAuth = authHeader.startsWith('Bearer ');
  
  // Set aggressive no-cache headers for authenticated requests
  res.set({
    'Cache-Control': 'no-cache, no-store, must-revalidate, private, max-age=0',
    'Pragma': 'no-cache',
    'Expires': '0',
    'Last-Modified': new Date().toUTCString(),
    'Vary': 'Authorization', // Ensure responses vary by auth token
    'X-Auth-Cache': hasValidAuth ? 'auth-present' : 'no-auth'
  });

  // Generate unique ETag based on timestamp and auth token
  let authToken = 'noauth';
  if (hasValidAuth) {
    const tokenParts = authHeader.split(' ');
    if (tokenParts.length > 1 && tokenParts[1] && tokenParts[1].length >= 8) {
      authToken = tokenParts[1].substring(tokenParts[1].length - 8);
    } else {
      authToken = 'token';
    }
  }
  const etag = `"auth-${Date.now()}-${authToken}"`;
  res.set('ETag', etag);

  next();
};

/**
 * API response wrapper middleware that ensures fresh data delivery
 * Overrides the res.json method to add cache busting
 */
export const freshResponseMiddleware = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  const originalJson = res.json;
  
  res.json = function(body: any) {
    // Add timestamp to response body to ensure freshness
    if (body && typeof body === 'object' && !Array.isArray(body)) {
      body._responseTime = new Date().toISOString();
      body._requestId = `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    }
    
    // Ensure no-cache headers are set
    if (!res.get('Cache-Control')) {
      res.set('Cache-Control', 'no-cache, no-store, must-revalidate, private');
    }
    
    return originalJson.call(this, body);
  };
  
  next();
};

/**
 * Middleware to clear client-side cache on authentication endpoints
 * Forces browsers to invalidate cached authentication responses
 */
export const clearAuthCacheMiddleware = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  // Add headers that signal clients to clear auth-related cache
  res.set({
    'Clear-Site-Data': '"cache", "storage"',
    'X-Cache-Invalidate': 'auth-data',
    'Cache-Control': 'no-cache, no-store, must-revalidate, private, max-age=0',
    'Pragma': 'no-cache',
    'Expires': '-1'
  });

  next();
};

/**
 * Enhanced logout cache clearing middleware
 * Specifically designed to ensure all user data is cleared on logout
 */
export const logoutCacheClearMiddleware = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  // Add comprehensive headers to force cache invalidation
  res.set({
    'Clear-Site-Data': '"cache", "storage", "cookies"',
    'X-Cache-Invalidate': 'all-user-data',
    'Cache-Control': 'no-cache, no-store, must-revalidate, private, max-age=0, no-transform',
    'Pragma': 'no-cache',
    'Expires': '-1',
    'Vary': '*',
    'X-Logout-Timestamp': new Date().toISOString()
  });

  next();
};

/**
 * User context isolation middleware
 * Ensures that user-specific data is never cached in a way that could leak between users
 */
export const userContextIsolationMiddleware = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  // Get user context from request (set by authentication middleware)
  const user = (req as any).user;
  
  // Add user-specific cache headers to prevent cross-user data leakage
  if (user && user.nrm) {
    // Make responses vary by user context
    res.set({
      'Vary': 'Authorization, X-User-Context',
      'X-User-Context': user.nrm,
      'Cache-Control': 'no-cache, no-store, must-revalidate, private, max-age=0',
      'Pragma': 'no-cache',
      'Expires': '0'
    });
    
    // Add user-specific ETag
    const etag = `"user-${user.nrm}-${Date.now()}"`;
    res.set('ETag', etag);
  } else {
    // For non-authenticated requests, still apply no-cache
    res.set({
      'Cache-Control': 'no-cache, no-store, must-revalidate, private, max-age=0',
      'Pragma': 'no-cache',
      'Expires': '0'
    });
  }

  next();
};