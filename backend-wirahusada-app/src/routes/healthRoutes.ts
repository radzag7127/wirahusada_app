import express from 'express';
import { getDatabaseHealth, getDatabaseConfigurations } from '../config/database';

const router = express.Router();

/**
 * Basic health check endpoint
 * Returns server uptime, environment, and version info
 */
router.get('/', (req, res) => {
  res.json({
    status: 'healthy',
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
    version: '2.0.0',
    memory: {
      used: Math.round(process.memoryUsage().heapUsed / 1024 / 1024),
      total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024),
      unit: 'MB'
    }
  });
});

/**
 * Comprehensive database health check endpoint
 * Tests all database connections and returns detailed status
 */
router.get('/database', async (req, res) => {
  try {
    const startTime = Date.now();
    const healthData = await getDatabaseHealth();
    const checkDuration = Date.now() - startTime;
    
    // Add check duration to response
    const healthDataWithDuration = {
      ...healthData,
      checkDuration: `${checkDuration}ms`
    };
    
    // Set appropriate HTTP status based on database health
    let httpStatus = 200;
    if (healthData.status === 'unhealthy') {
      httpStatus = 503; // Service Unavailable
    } else if (healthData.status === 'degraded') {
      httpStatus = 200; // OK but with warnings
    }
    
    res.status(httpStatus).json(healthDataWithDuration);
  } catch (error) {
    console.error('Database health check failed:', error);
    res.status(503).json({
      status: 'unhealthy',
      error: error instanceof Error ? error.message : 'Database health check failed',
      timestamp: new Date().toISOString(),
      checkDuration: 'failed'
    });
  }
});

/**
 * Database configuration endpoint (without sensitive data)
 * Shows connection settings for monitoring purposes
 */
router.get('/database/config', (req, res) => {
  try {
    const configs = getDatabaseConfigurations();
    res.json({
      status: 'success',
      configurations: configs,
      timestamp: new Date().toISOString(),
      note: 'Sensitive credentials are not exposed in this endpoint'
    });
  } catch (error) {
    console.error('Failed to get database configurations:', error);
    res.status(500).json({
      status: 'error',
      error: 'Failed to retrieve database configurations',
      timestamp: new Date().toISOString()
    });
  }
});

/**
 * Detailed system health check
 * Combines all health metrics into a single comprehensive endpoint
 */
router.get('/detailed', async (req, res) => {
  try {
    const startTime = Date.now();
    
    // Get database health
    const dbHealth = await getDatabaseHealth();
    
    // Get system info
    const systemHealth = {
      uptime: process.uptime(),
      environment: process.env.NODE_ENV || 'development',
      version: '2.0.0',
      node: process.version,
      platform: process.platform,
      arch: process.arch,
      memory: {
        used: Math.round(process.memoryUsage().heapUsed / 1024 / 1024),
        total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024),
        external: Math.round(process.memoryUsage().external / 1024 / 1024),
        unit: 'MB'
      },
      cpu: process.cpuUsage()
    };
    
    const checkDuration = Date.now() - startTime;
    
    // Determine overall system health
    let overallStatus: 'healthy' | 'degraded' | 'unhealthy' = 'healthy';
    if (dbHealth.status === 'unhealthy') {
      overallStatus = 'unhealthy';
    } else if (dbHealth.status === 'degraded') {
      overallStatus = 'degraded';
    }
    
    const response = {
      status: overallStatus,
      timestamp: new Date().toISOString(),
      checkDuration: `${checkDuration}ms`,
      system: systemHealth,
      database: dbHealth
    };
    
    // Set HTTP status based on overall health
    const httpStatus = overallStatus === 'unhealthy' ? 503 : 200;
    res.status(httpStatus).json(response);
    
  } catch (error) {
    console.error('Detailed health check failed:', error);
    res.status(503).json({
      status: 'unhealthy',
      error: error instanceof Error ? error.message : 'Health check failed',
      timestamp: new Date().toISOString()
    });
  }
});

export default router;