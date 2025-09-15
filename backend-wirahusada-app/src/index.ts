import express from "express";
import cors from "cors";
import cookieParser from "cookie-parser";
import dotenv from "dotenv";
import { testConnections, closeDatabaseConnections, getDatabaseHealth } from "./config/database";
import { databaseMigration } from "./utils/migrations";
import authRoutes from "./routes/authRoutes";
import paymentRoutes from "./routes/paymentRoutes";
import akademikRoutes from "./routes/akademikRoutes";
import berandaRoutes from "./routes/berandaRoutes";
import healthRoutes from "./routes/healthRoutes";
import perpustakaanRoutes from "./routes/perpustakaan_routes";

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;
const CORS_ORIGIN = process.env.CORS_ORIGIN || "http://localhost:3000";

// Middleware - Allow multiple origins for development
const allowedOrigins = [
  "http://localhost:3000",
  "http://localhost:8080",
  "http://localhost:54128",
  /^http:\/\/localhost:\d+$/, // Allow any localhost port
];

app.use(
  cors({
    origin: (origin, callback) => {
      // Allow requests with no origin (like mobile apps or curl requests)
      if (!origin) return callback(null, true);

      // Check if origin is in allowed list or matches localhost pattern
      const isAllowed = allowedOrigins.some((allowedOrigin) => {
        if (typeof allowedOrigin === "string") {
          return allowedOrigin === origin;
        } else {
          return allowedOrigin.test(origin);
        }
      });

      if (isAllowed) {
        callback(null, true);
      } else {
        callback(new Error("Not allowed by CORS"));
      }
    },
    credentials: true,
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
  })
);
app.use(cookieParser()); // Enable cookie parsing for httpOnly refresh tokens
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true, limit: "10mb" }));

// Serve static files for perpustakaan sampul images
app.use("/uploads/sampul", express.static("src/uploads/sampul"));

// Request logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/payments", paymentRoutes);
//akademik routes
app.use("/api/akademik", akademikRoutes);
// beranda routes
app.use("/api/beranda", berandaRoutes);
// perpustakaan routes
app.use("/api/perpustakaan", perpustakaanRoutes);
// health check routes
app.use("/health", healthRoutes);

// Legacy health check endpoint (redirect to new routes)
app.get("/health-legacy", (req, res) => {
  res.redirect(301, '/health');
});

// Basic route
app.get("/", (req, res) => {
  res.json({
    message: "Wismon Keuangan Backend API",
    status: "running",
    timestamp: new Date().toISOString(),
    version: "1.0.0",
    endpoints: {
      auth: {
        login: "POST /api/auth/login",
        profile: "GET /api/auth/profile",
        verify: "POST /api/auth/verify",
        refresh: "POST /api/auth/refresh",
        logout: "POST /api/auth/logout",
      },
      payments: {
        history: "GET /api/payments/history",
        summary: "GET /api/payments/summary",
        detail: "GET /api/payments/detail/:id",
        refresh: "POST /api/payments/refresh",
        types: "GET /api/payments/types",
      },
    },
  });
});

// Error handling middleware
app.use(
  (
    error: any,
    req: express.Request,
    res: express.Response,
    next: express.NextFunction
  ) => {
    console.error("Unhandled error:", error);
    res.status(500).json({
      success: false,
      message: "Internal server error",
      errors: [
        process.env.NODE_ENV === "development"
          ? error.message
          : "Something went wrong",
      ],
    });
  }
);

// 404 handler
app.use("*", (req, res) => {
  res.status(404).json({
    success: false,
    message: "Endpoint not found",
    errors: [`${req.method} ${req.originalUrl} not found`],
  });
});

// Start server function
async function startServer() {
  try {
    console.log("🚀 Starting Wismon Keuangan Backend Server...");
    console.log(`📍 Environment: ${process.env.NODE_ENV || "development"}`);

    // Test database connections with comprehensive retry logic
    console.log("🔍 Testing database connections...");
    const dbResults = await testConnections();

    // Validate that critical databases are connected
    const criticalDatabases = ['sso', 'wismon']; // SSO for auth, WISMON for payments
    const criticalFailures = criticalDatabases.filter(db => !dbResults[db as keyof typeof dbResults].success);
    
    if (criticalFailures.length > 0) {
      console.error(`💥 CRITICAL: Cannot start server - essential databases failed: ${criticalFailures.join(', ')}`);
      console.error('These databases are required for core functionality.');
      process.exit(1);
    }

    // Run database migrations
    console.log("🔧 Running database migrations...");
    await databaseMigration.initialize();

    const successCount = Object.values(dbResults).filter(r => r.success).length;
    const totalCount = Object.keys(dbResults).length;

    if (successCount === totalCount) {
      console.log("✅ All database connections successful!");
    } else {
      console.log(
        `⚠️  ${successCount}/${totalCount} database connections successful`
      );
      console.log("Non-critical databases may have limited functionality.");
    }

    // Start the server
    const server = app.listen(PORT, () => {
      console.log("🎉 Server started successfully!");
      console.log(`📡 API endpoint: http://localhost:${PORT}`);
      console.log(`📋 API documentation: http://localhost:${PORT}`);
      console.log(`🔧 Health check: http://localhost:${PORT}/health`);
      console.log(`🗄️  Database health: http://localhost:${PORT}/health/database`);
      console.log(`📊 Detailed health: http://localhost:${PORT}/health/detailed`);
      console.log("");
      console.log("Available Endpoints:");
      console.log("  Authentication:");
      console.log("    POST /api/auth/login      - Student login");
      console.log("    GET  /api/auth/profile    - Get student profile");
      console.log("    POST /api/auth/verify     - Verify JWT token");
      console.log("  Payments:");
      console.log(
        "    GET  /api/payments/history     - Payment history with filters"
      );
      console.log("    GET  /api/payments/summary     - Payment summary/recap");
      console.log("    GET  /api/payments/detail/:id  - Transaction details");
      console.log("    POST /api/payments/refresh     - Refresh payment data");
      console.log(
        "    GET  /api/payments/types       - Available payment types"
      );
      console.log("  Health Monitoring:");
      console.log("    GET  /health                   - Basic health check");
      console.log("    GET  /health/database          - Database health status");
      console.log("    GET  /health/database/config   - Database configuration info");
      console.log("    GET  /health/detailed          - Comprehensive system health");
      console.log("");
      console.log("💡 Ready to accept requests!");
    });

    // Store server reference for graceful shutdown
    (global as any).httpServer = server;

  } catch (error) {
    console.error("💥 Failed to start server:", error);
    
    // Provide helpful error messages for common issues
    if (error instanceof Error) {
      if (error.name === 'EnvironmentValidationError') {
        console.error('\n🔧 Fix: Ensure your .env file contains all required database credentials');
        console.error('Required variables: DB_*_HOST, DB_*_PORT, DB_*_USER, DB_*_PASSWORD, DB_*_NAME');
        console.error('Where * is: SSO, WIS, WISAKA, WISMON');
      } else if (error.message.includes('ECONNREFUSED')) {
        console.error('\n🔧 Fix: Ensure MySQL server is running and accessible');
      } else if (error.message.includes('ENOTFOUND')) {
        console.error('\n🔧 Fix: Check database host configuration');
      }
    }
    
    // Ensure graceful cleanup before exit
    await closeDatabaseConnections();
    process.exit(1);
  }
}

// Enhanced graceful shutdown handler
async function gracefulShutdown(signal: string) {
  console.log(`\n🛑 ${signal} received. Initiating graceful shutdown...`);
  
  try {
    // Close HTTP server
    const server = (global as any).httpServer;
    if (server) {
      console.log('🔄 Closing HTTP server...');
      await new Promise<void>((resolve, reject) => {
        server.close((err: Error | undefined) => {
          if (err) reject(err);
          else resolve();
        });
      });
      console.log('✅ HTTP server closed');
    }
    
    // Close database connections
    await closeDatabaseConnections();
    
    console.log('✅ Graceful shutdown completed');
    process.exit(0);
    
  } catch (error) {
    console.error('❌ Error during graceful shutdown:', error);
    process.exit(1);
  }
}

// Handle graceful shutdown signals
process.on("SIGTERM", () => gracefulShutdown('SIGTERM'));
process.on("SIGINT", () => gracefulShutdown('SIGINT'));

// Handle unhandled promise rejections
process.on("unhandledRejection", async (reason, promise) => {
  console.error("💥 Unhandled Rejection at:", promise, "reason:", reason);
  
  // Attempt graceful shutdown
  try {
    await closeDatabaseConnections();
  } catch (error) {
    console.error('Error closing connections during unhandled rejection:', error);
  }
  
  process.exit(1);
});

// Handle uncaught exceptions
process.on('uncaughtException', async (error) => {
  console.error('💥 Uncaught Exception:', error);
  
  // Attempt graceful shutdown
  try {
    await closeDatabaseConnections();
  } catch (shutdownError) {
    console.error('Error closing connections during uncaught exception:', shutdownError);
  }
  
  process.exit(1);
});

// Start the server
startServer();
