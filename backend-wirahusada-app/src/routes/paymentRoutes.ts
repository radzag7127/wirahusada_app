import { Router } from "express";
import { PaymentController } from "../controllers/paymentController";
import { authenticateToken } from "../utils/auth";
import { validatePayment, validateGeneral } from "../middleware/validation";
import { authCacheMiddleware, userContextIsolationMiddleware } from "../middleware/cacheControl";

const router = Router();
const paymentController = new PaymentController();

// Apply cache control middleware to prevent stale authentication responses
router.use(authCacheMiddleware);

// All payment routes require authentication
router.use(authenticateToken);

// Apply user context isolation to prevent cross-user data leakage
router.use(userContextIsolationMiddleware);

// Payment history with filtering and pagination validation
router.get(
  "/history",
  ...validatePayment.dateRange,
  paymentController.getPaymentHistory.bind(paymentController)
);

// Payment summary/recapitulation with date range validation
router.get(
  "/summary",
  ...validatePayment.dateRange,
  paymentController.getPaymentSummary.bind(paymentController)
);

// Transaction detail with ID validation
router.get(
  "/detail/:id",
  ...validatePayment.paymentId,
  paymentController.getTransactionDetail.bind(paymentController)
);

// Refresh payment data
router.post(
  "/refresh",
  paymentController.refreshPaymentData.bind(paymentController)
);

// Get payment types for filtering
router.get("/types", paymentController.getPaymentTypes.bind(paymentController));

export default router;
