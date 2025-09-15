import {
  body,
  param,
  query,
  ValidationChain,
  validationResult,
} from "express-validator";
import { Request, Response, NextFunction } from "express";

/**
 * Custom validation error interface for comprehensive error handling
 */
interface ValidationError {
  field: string;
  message: string;
  value?: any;
  location: string;
}

/**
 * Enhanced error handler for express-validator with security-focused error messages
 */
export const handleValidationErrors = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  const errors = validationResult(req);

  if (!errors.isEmpty()) {
    const validationErrors: ValidationError[] = errors.array().map((error) => ({
      field: error.type === "field" ? (error as any).path : "unknown",
      message: error.msg,
      value:
        process.env.NODE_ENV === "development"
          ? (error as any).value
          : undefined,
      location: (error as any).location || "body",
    }));

    // Log validation failures for security monitoring
    console.warn("🚫 Input validation failed:", {
      ip: req.ip,
      userAgent: req.get("User-Agent"),
      path: req.path,
      method: req.method,
      errors: validationErrors,
      timestamp: new Date().toISOString(),
    });

    res.status(400).json({
      success: false,
      message: "Input validation failed",
      errors: validationErrors,
      timestamp: new Date().toISOString(),
    });
    return;
  }

  next();
};

/**
 * Authentication input validation rules
 */
export const validateAuth = {
  login: [
    body("namam_nim")
      .trim()
      .isLength({ min: 2, max: 100 })
      .withMessage("Student name/NIM must be between 2 and 100 characters")
      .matches(/^[a-zA-Z0-9\s.'-]+$/)
      .withMessage(
        "Student name/NIM can only contain letters, numbers, spaces, dots, apostrophes, and hyphens"
      )
      .escape(), // Sanitize HTML entities

    body("nrm")
      .trim()
      .isLength({ min: 5, max: 20 })
      .withMessage("NRM must be between 5 and 20 characters")
      .matches(/^[A-Z0-9\-]+$/)
      .withMessage(
        "NRM can only contain uppercase letters, numbers, and hyphens"
      )
      .escape(),

    handleValidationErrors,
  ],

  refresh: [
    // No body validation needed for refresh (uses httpOnly cookies)
    handleValidationErrors,
  ],
};

/**
 * Academic system validation rules (KRS/KHS)
 */
export const validateAcademic = {
  semester: [
    param("semester")
      .trim()
      .matches(/^\d{4}[12]$/)
      .withMessage("Semester must be in format YYYY1 or YYYY2 (e.g., 20241)")
      .isLength({ min: 5, max: 5 })
      .withMessage("Semester must be exactly 5 characters"),

    handleValidationErrors,
  ],

  nrm: [
    param("nrm")
      .trim()
      .isLength({ min: 5, max: 20 })
      .withMessage("NRM must be between 5 and 20 characters")
      .matches(/^[A-Z0-9\-]+$/)
      .withMessage("NRM format is invalid")
      .escape(),

    handleValidationErrors,
  ],
};

/**
 * Payment system validation rules
 */
export const validatePayment = {
  paymentId: [
    param("id")
      .trim()
      .isLength({ min: 1, max: 50 })
      .withMessage("Transaction ID must be between 1 and 50 characters")
      .matches(/^[A-Z0-9\-_]+$/i)
      .withMessage(
        "Transaction ID can only contain letters, numbers, hyphens, and underscores"
      )
      .escape(),

    handleValidationErrors,
  ],

  dateRange: [
    query("startDate")
      .optional()
      .trim()
      .isISO8601()
      .withMessage("Start date must be in ISO 8601 format (YYYY-MM-DD)")
      .toDate(),

    query("endDate")
      .optional()
      .trim()
      .isISO8601()
      .withMessage("End date must be in ISO 8601 format (YYYY-MM-DD)")
      .toDate()
      .custom((endDate, { req }) => {
        const startDate = req.query?.startDate;
        if (
          startDate &&
          endDate &&
          new Date(endDate) < new Date(startDate as string)
        ) {
          throw new Error("End date must be after start date");
        }
        return true;
      }),

    query("limit")
      .optional()
      .trim()
      .isInt({ min: 1, max: 1000 })
      .withMessage("Limit must be between 1 and 1000")
      .toInt(),

    query("offset")
      .optional()
      .trim()
      .isInt({ min: 0 })
      .withMessage("Offset must be 0 or greater")
      .toInt(),

    handleValidationErrors,
  ],
};

/**
 * General utility validations
 */
export const validateGeneral = {
  nrmParam: [
    param("nrm")
      .trim()
      .isLength({ min: 5, max: 20 })
      .withMessage("NRM must be between 5 and 20 characters")
      .matches(/^[A-Z0-9\-]+$/)
      .withMessage("Invalid NRM format")
      .escape(),

    handleValidationErrors,
  ],

  pagination: [
    query("page")
      .optional()
      .trim()
      .isInt({ min: 1, max: 10000 })
      .withMessage("Page must be between 1 and 10000")
      .toInt(),

    query("limit")
      .optional()
      .trim()
      .isInt({ min: 1, max: 100 })
      .withMessage("Limit must be between 1 and 100")
      .toInt(),

    handleValidationErrors,
  ],

  search: [
    query("q")
      .optional()
      .trim()
      .isLength({ min: 1, max: 100 })
      .withMessage("Search query must be between 1 and 100 characters")
      .matches(/^[a-zA-Z0-9\s\-_.]+$/)
      .withMessage("Search query contains invalid characters")
      .escape(),

    handleValidationErrors,
  ],
};

/**
 * Sanitization utilities for additional security
 */
export const sanitizeInput = {
  /**
   * Removes potential SQL injection patterns (defense in depth)
   */
  sqlInjection: (input: string): string => {
    if (typeof input !== "string") return input;

    // Remove common SQL injection patterns
    const sqlPatterns = [
      /(\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|UNION|SCRIPT)\b)/gi,
      /(--|\/\*|\*\/|;|'|"|`)/g,
      /(\b(OR|AND)\s+\d+\s*=\s*\d+)/gi,
    ];

    let sanitized = input;
    sqlPatterns.forEach((pattern) => {
      sanitized = sanitized.replace(pattern, "");
    });

    return sanitized.trim();
  },

  /**
   * Removes potential XSS patterns
   */
  xss: (input: string): string => {
    if (typeof input !== "string") return input;

    const xssPatterns = [
      /<script[^>]*>.*?<\/script>/gi,
      /<iframe[^>]*>.*?<\/iframe>/gi,
      /javascript:/gi,
      /on\w+\s*=/gi,
      /<[^>]+>/g, // Remove all HTML tags
    ];

    let sanitized = input;
    xssPatterns.forEach((pattern) => {
      sanitized = sanitized.replace(pattern, "");
    });

    return sanitized.trim();
  },
};

/**
 * Custom validation middleware for complex business rules
 */
export const customValidations = {
  /**
   * Validates NRM format based on institution rules
   */
  validateNrmFormat: (nrm: string): boolean => {
    // Basic format: 3 letters + 4-6 digits + optional suffix
    const nrmPattern = /^[A-Z]{2,3}[0-9]{4,6}(-[A-Z0-9]{1,3})?$/;
    return nrmPattern.test(nrm);
  },

  /**
   * Validates semester format (YYYYS where S is 1 or 2)
   */
  validateSemesterFormat: (semester: string): boolean => {
    const semesterPattern = /^20[0-9]{2}[12]$/;
    const year = parseInt(semester.substring(0, 4));
    const currentYear = new Date().getFullYear();

    return (
      semesterPattern.test(semester) && year >= 2000 && year <= currentYear + 1
    ); // Allow next year for planning
  },

  /**
   * Validates student name format
   */
  validateStudentName: (name: string): boolean => {
    // Allow letters, spaces, common name punctuation
    const namePattern = /^[a-zA-Z\s.'-]{2,100}$/;
    const hasValidLength = name.trim().length >= 2 && name.trim().length <= 100;
    const hasNoConsecutiveSpaces = !/\s{2,}/.test(name);

    return namePattern.test(name) && hasValidLength && hasNoConsecutiveSpaces;
  },
};

/**
 * Security logging for validation events
 */
export const logValidationEvent = (
  req: Request,
  eventType: "success" | "failure" | "suspicious",
  details?: any
) => {
  const logData = {
    event: `validation_${eventType}`,
    ip: req.ip,
    userAgent: req.get("User-Agent"),
    path: req.path,
    method: req.method,
    timestamp: new Date().toISOString(),
    ...details,
  };

  if (eventType === "suspicious") {
    console.warn("🚨 Suspicious input detected:", logData);
  } else if (eventType === "failure") {
    console.warn("⚠️ Validation failure:", logData);
  } else {
    console.log("✅ Validation success:", logData);
  }
};

/**
 * Advanced validation middleware factory for complex scenarios
 */
export const createAdvancedValidation = (
  validationRules: ValidationChain[],
  customChecks?: Array<(req: Request) => { isValid: boolean; message?: string }>
) => {
  return [
    ...validationRules,
    (req: Request, res: Response, next: NextFunction): void => {
      // First check express-validator results
      const errors = validationResult(req);

      if (!errors.isEmpty()) {
        logValidationEvent(req, "failure", { validatorErrors: errors.array() });
        handleValidationErrors(req, res, next);
        return;
      }

      // Then run custom checks if provided
      if (customChecks) {
        for (const check of customChecks) {
          const result = check(req);
          if (!result.isValid) {
            logValidationEvent(req, "failure", {
              customCheckFailed: result.message,
            });
            res.status(400).json({
              success: false,
              message: result.message || "Custom validation failed",
              timestamp: new Date().toISOString(),
            });
            return;
          }
        }
      }

      logValidationEvent(req, "success");
      next();
    },
  ];
};

export default {
  validateAuth,
  validateAcademic,
  validatePayment,
  validateGeneral,
  handleValidationErrors,
  sanitizeInput,
  customValidations,
  logValidationEvent,
  createAdvancedValidation,
};
