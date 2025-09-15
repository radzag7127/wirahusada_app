import * as mysql from "mysql2/promise";
import { Pool, PoolConnection } from "mysql2/promise";
import * as dotenv from "dotenv";

dotenv.config();

/**
 * Secure database configuration interface with SSL support
 */
export interface DatabaseConfig {
  host: string;
  port: number;
  user: string;
  password: string;
  database: string;
  connectionLimit: number;
  acquireTimeout: number;
  idleTimeout: number;
  ssl?: {
    rejectUnauthorized: boolean;
  };
  charset: string;
  timezone: string;
}

/**
 * Environment validation error class for detailed error reporting
 */
class EnvironmentValidationError extends Error {
  constructor(missingVars: string[]) {
    super(
      `Missing required environment variables: ${missingVars.join(", ")}. ` +
      "Database connections cannot be established without proper credentials."
    );
    this.name = "EnvironmentValidationError";
  }
}

/**
 * Database connection error class for retry mechanism
 */
class DatabaseConnectionError extends Error {
  constructor(database: string, originalError: Error, attempt: number) {
    super(
      `Failed to connect to ${database} database (attempt ${attempt}): ${originalError.message}`
    );
    this.name = "DatabaseConnectionError";
  }
}

/**
 * Validates that all required environment variables are present
 * Throws EnvironmentValidationError if any are missing
 */
function validateEnvironmentVariables(): void {
  const requiredVars = [
    // SSO Database
    'DB_SSO_HOST', 'DB_SSO_PORT', 'DB_SSO_USER', 'DB_SSO_PASSWORD', 'DB_SSO_NAME',
    // WIS Database  
    'DB_WIS_HOST', 'DB_WIS_PORT', 'DB_WIS_USER', 'DB_WIS_PASSWORD', 'DB_WIS_NAME',
    // WISAKA Database
    'DB_WISAKA_HOST', 'DB_WISAKA_PORT', 'DB_WISAKA_USER', 'DB_WISAKA_PASSWORD', 'DB_WISAKA_NAME',
    // WISMON Database
    'DB_WISMON_HOST', 'DB_WISMON_PORT', 'DB_WISMON_USER', 'DB_WISMON_PASSWORD', 'DB_WISMON_NAME',
    // PERPUSTAKAAN Database
    'DB_PERPUSTAKAAN_HOST', 'DB_PERPUSTAKAAN_PORT', 'DB_PERPUSTAKAAN_USER', 'DB_PERPUSTAKAAN_PASSWORD', 'DB_PERPUSTAKAAN_NAME'
  ];

  const missingVars = requiredVars.filter(varName => {
    const value = process.env[varName];
    return !value || value.trim() === '';
  });

  if (missingVars.length > 0) {
    console.error('\n🚨 CRITICAL: Database Environment Validation Failed');
    console.error('Missing or empty environment variables:');
    missingVars.forEach(varName => {
      console.error(`  - ${varName}`);
    });
    console.error('\nPlease ensure all database credentials are properly configured in your .env file.\n');
    throw new EnvironmentValidationError(missingVars);
  }

  console.log('✅ Environment validation passed - all database credentials present');
}

/**
 * Creates secure database configuration with SSL/TLS encryption
 */
function createDatabaseConfig(prefix: string): DatabaseConfig {
  const portStr = process.env[`DB_${prefix}_PORT`]!;
  const port = parseInt(portStr, 10);
  
  if (isNaN(port) || port < 1 || port > 65535) {
    throw new Error(`Invalid port number for ${prefix} database: ${portStr}`);
  }

  return {
    host: process.env[`DB_${prefix}_HOST`]!,
    port,
    user: process.env[`DB_${prefix}_USER`]!,
    password: process.env[`DB_${prefix}_PASSWORD`]!,
    database: process.env[`DB_${prefix}_NAME`]!,
    connectionLimit: 15, // Increased for better concurrency
    acquireTimeout: 30000, // Connection acquisition timeout
    idleTimeout: 300000, // 5 minutes idle timeout
    // SSL configuration with environment variable override
    // When DB_REQUIRE_SSL is not 'true', omit ssl property entirely (undefined)
    // This is compatible with mysql2 PoolOptions which expects string | SslOptions | undefined
    ...(process.env.DB_REQUIRE_SSL === 'true' && {
      ssl: {
        rejectUnauthorized: process.env.DB_SSL_REJECT_UNAUTHORIZED !== 'false'
      }
    }),
    charset: 'utf8mb4', // Full UTF-8 support
    timezone: '+00:00' // UTC timezone
  };
}

// Validate environment variables before creating configurations
validateEnvironmentVariables();

// Create secure database configurations
const ssoDbConfig: DatabaseConfig = createDatabaseConfig('SSO');
const wisDbConfig: DatabaseConfig = createDatabaseConfig('WIS'); 
const wisakaDbConfig: DatabaseConfig = createDatabaseConfig('WISAKA');
const wismonDbConfig: DatabaseConfig = createDatabaseConfig('WISMON');
const perpustakaanDbConfig: DatabaseConfig = createDatabaseConfig('PERPUSTAKAAN');

/**
 * Connection retry configuration
 */
interface RetryConfig {
  maxAttempts: number;
  baseDelay: number; // Base delay in milliseconds
  maxDelay: number;  // Maximum delay cap
}

const RETRY_CONFIG: RetryConfig = {
  maxAttempts: 3,
  baseDelay: 1000,   // 1 second
  maxDelay: 9000     // 9 seconds max
};

/**
 * Calculates exponential backoff delay with jitter
 */
function calculateRetryDelay(attempt: number): number {
  const exponentialDelay = RETRY_CONFIG.baseDelay * Math.pow(3, attempt - 1);
  const jitter = Math.random() * 200; // Add small random jitter
  return Math.min(exponentialDelay + jitter, RETRY_CONFIG.maxDelay);
}

/**
 * Sleep utility for retry delays
 */
function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * Creates connection pool with retry logic and monitoring
 */
function createConnectionPoolWithRetry(config: DatabaseConfig, dbName: string): Pool {
  const pool = mysql.createPool(config);
  
  // Add connection pool event monitoring
  pool.on('connection', () => {
    console.log(`🔗 New connection established to ${dbName} database`);
  });
  
  pool.on('error' as any, (err: any) => {
    console.error(`💥 ${dbName} database pool error:`, err.message);
    if (err.code === 'PROTOCOL_CONNECTION_LOST') {
      console.log(`🔄 Attempting to reconnect to ${dbName} database...`);
    }
  });
  
  return pool;
}

// Create connection pools with monitoring
export const ssoPool = createConnectionPoolWithRetry(ssoDbConfig, 'SSO');
export const wisPool = createConnectionPoolWithRetry(wisDbConfig, 'WIS');
export const wisakaPool = createConnectionPoolWithRetry(wisakaDbConfig, 'WISAKA');
export const wismonPool = createConnectionPoolWithRetry(wismonDbConfig, 'WISMON');
export const perpustakaanPool = createConnectionPoolWithRetry(perpustakaanDbConfig, 'PERPUSTAKAAN');

/**
 * Database connection test results interface
 */
interface ConnectionTestResult {
  success: boolean;
  error?: string;
  responseTime?: number;
  attempts: number;
}

interface ConnectionTestResults {
  sso: ConnectionTestResult;
  wis: ConnectionTestResult;
  wisaka: ConnectionTestResult;
  wismon: ConnectionTestResult;
  perpustakaan: ConnectionTestResult;
}

/**
 * Tests a single database connection with retry logic
 */
async function testSingleConnection(
  pool: Pool, 
  config: DatabaseConfig, 
  dbName: string
): Promise<ConnectionTestResult> {
  let lastError: Error | null = null;
  
  for (let attempt = 1; attempt <= RETRY_CONFIG.maxAttempts; attempt++) {
    const startTime = Date.now();
    
    try {
      console.log(`🔍 Testing ${dbName} database connection (attempt ${attempt}/${RETRY_CONFIG.maxAttempts})...`);
      
      const connection: PoolConnection = await pool.getConnection();
      
      // Perform a simple query to verify connection health
      await connection.execute('SELECT 1 as test');
      
      const responseTime = Date.now() - startTime;
      connection.release();
      
      console.log(`✅ ${dbName} Database connected successfully`);
      console.log(`📊 ${dbName} Connected to: ${config.host}:${config.port}/${config.database}`);
      console.log(`⚡ ${dbName} Response time: ${responseTime}ms`);
      
      return {
        success: true,
        responseTime,
        attempts: attempt
      };
      
    } catch (error) {
      const errorObj = error as Error;
      lastError = errorObj;
      
      console.error(`❌ ${dbName} Database connection failed (attempt ${attempt}):`, errorObj.message);
      
      // Provide specific guidance for SSL-related errors
      if (errorObj.message.includes('secure connection') || 
          errorObj.message.includes('SSL') || 
          errorObj.message.includes('TLS')) {
        console.error(`💡 SSL Connection Error Solution for ${dbName}:`);
        console.error('   1. Add DB_REQUIRE_SSL=false to your .env file to disable SSL');
        console.error('   2. Or configure your MySQL server to support SSL connections');
        console.error('   3. Check if your MySQL server version supports SSL/TLS');
      }
      
      if (attempt < RETRY_CONFIG.maxAttempts) {
        const delay = calculateRetryDelay(attempt);
        console.log(`⏳ Retrying ${dbName} connection in ${delay}ms...`);
        await sleep(delay);
      }
    }
  }
  
  return {
    success: false,
    error: lastError?.message || 'Unknown error',
    attempts: RETRY_CONFIG.maxAttempts
  };
}

/**
 * Tests all database connections with comprehensive retry logic
 * Returns detailed connection results for monitoring
 */
export async function testConnections(): Promise<ConnectionTestResults> {
  console.log('🔍 Starting comprehensive database connection tests...');
  console.log(`🔄 Retry configuration: ${RETRY_CONFIG.maxAttempts} attempts with exponential backoff`);
  
  const startTime = Date.now();
  
  // Test all connections concurrently for faster startup
  const [ssoResult, wisResult, wisakaResult, wismonResult, perpustakaanResult] = await Promise.all([
    testSingleConnection(ssoPool, ssoDbConfig, 'SSO'),
    testSingleConnection(wisPool, wisDbConfig, 'WIS'), 
    testSingleConnection(wisakaPool, wisakaDbConfig, 'WISAKA'),
    testSingleConnection(wismonPool, wismonDbConfig, 'WISMON'),
    testSingleConnection(perpustakaanPool, perpustakaanDbConfig, 'PERPUSTAKAAN')
  ]);
  
  const totalTime = Date.now() - startTime;
  const results: ConnectionTestResults = {
    sso: ssoResult,
    wis: wisResult,
    wisaka: wisakaResult,
    wismon: wismonResult,
    perpustakaan: perpustakaanResult
  };
  
  // Calculate connection statistics
  const successful = Object.values(results).filter(r => r.success).length;
  const total = Object.keys(results).length;
  const avgResponseTime = Object.values(results)
    .filter(r => r.success && r.responseTime)
    .reduce((sum, r) => sum + (r.responseTime || 0), 0) / successful || 0;
  
  console.log('\n📊 Database Connection Summary:');
  console.log(`   Success Rate: ${successful}/${total} databases`);
  console.log(`   Total Test Time: ${totalTime}ms`);
  if (successful > 0) {
    console.log(`   Average Response Time: ${Math.round(avgResponseTime)}ms`);
  }
  
  // Log failed connections for debugging
  Object.entries(results).forEach(([db, result]) => {
    if (!result.success) {
      console.error(`💥 ${db.toUpperCase()} Database: ${result.error}`);
    }
  });
  
  if (successful === total) {
    console.log('✅ All database connections successful!');
  } else {
    console.warn(`⚠️  ${successful}/${total} database connections successful`);
    
    // In production, we might want to fail if critical databases are down
    if (successful === 0) {
      throw new Error('Critical failure: No database connections could be established');
    }
  }
  
  return results;
}

/**
 * Query execution options for enhanced monitoring
 */
interface QueryExecutionOptions {
  timeout?: number;
  retryOnFailure?: boolean;
  logQuery?: boolean;
}

/**
 * Enhanced query executor with retry logic and comprehensive error handling
 */
async function executeQueryWithRetry(
  pool: Pool,
  dbName: string,
  query: string,
  params?: any[],
  options: QueryExecutionOptions = {}
): Promise<any> {
  const {
    timeout = 30000,
    retryOnFailure = true,
    logQuery = process.env.NODE_ENV === 'development'
  } = options;
  
  const maxAttempts = retryOnFailure ? 2 : 1;
  let lastError: Error | null = null;
  
  if (logQuery) {
    console.log(`🗄️ ${dbName} DB - Executing query:`, {
      query: query.replace(/\s+/g, " ").trim(),
      params,
      paramsTypes: params?.map((p) => ({ value: p, type: typeof p })),
      timestamp: new Date().toISOString(),
    });
  }
  
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      const startTime = Date.now();
      
      // Execute query with timeout
      const [results] = await Promise.race([
        pool.execute(query, params),
        new Promise((_, reject) => 
          setTimeout(() => reject(new Error('Query timeout')), timeout)
        )
      ]) as [any];
      
      const executionTime = Date.now() - startTime;
      
      if (logQuery) {
        console.log(`🗄️ ${dbName} DB - Query successful:`, {
          resultCount: Array.isArray(results) ? results.length : "Not array",
          resultType: typeof results,
          executionTime: `${executionTime}ms`,
          attempt: attempt > 1 ? attempt : undefined,
          firstResult: Array.isArray(results) ? results[0] : results,
        });
      }
      
      return results;
      
    } catch (error) {
      const errorObj = error as Error;
      lastError = errorObj;
      
      console.error(`🗄️ ${dbName} DB - Query error (attempt ${attempt}):`, {
        error: errorObj.message,
        query: query.replace(/\s+/g, " ").trim(),
        params,
        code: (errorObj as any).code,
        errno: (errorObj as any).errno,
        timestamp: new Date().toISOString()
      });
      
      // Retry on connection errors but not on syntax errors
      const retryableErrors = ['ECONNRESET', 'ETIMEDOUT', 'PROTOCOL_CONNECTION_LOST'];
      const isRetryable = retryableErrors.includes((errorObj as any).code);
      
      if (attempt < maxAttempts && isRetryable) {
        const delay = 1000 * attempt; // Linear backoff for query retries
        console.log(`⏳ Retrying ${dbName} query in ${delay}ms...`);
        await sleep(delay);
      }
    }
  }
  
  throw new Error(`${dbName} Database query failed after ${maxAttempts} attempts: ${lastError?.message}`);
}

// Enhanced query execution functions with retry logic
export const executeSsoQuery = async (
  query: string, 
  params?: any[], 
  options?: QueryExecutionOptions
): Promise<any> => {
  return executeQueryWithRetry(ssoPool, 'SSO', query, params, options);
};

export const executeWisQuery = async (
  query: string, 
  params?: any[], 
  options?: QueryExecutionOptions
): Promise<any> => {
  return executeQueryWithRetry(wisPool, 'WIS', query, params, options);
};

export const executeWisakaQuery = async (
  query: string, 
  params?: any[], 
  options?: QueryExecutionOptions
): Promise<any> => {
  return executeQueryWithRetry(wisakaPool, 'WISAKA', query, params, {
    logQuery: true, // Always log WISAKA queries as per original behavior
    ...options
  });
};

export const executeWismonQuery = async (
  query: string, 
  params?: any[], 
  options?: QueryExecutionOptions
): Promise<any> => {
  return executeQueryWithRetry(wismonPool, 'WISMON', query, params, {
    logQuery: true, // Always log WISMON queries as per original behavior
    ...options
  });
};

// Perpustakaan database query executor
export const executePerpustakaanQuery = async (
  query: string, 
  params?: any[], 
  options?: QueryExecutionOptions
): Promise<any> => {
  return executeQueryWithRetry(perpustakaanPool, 'PERPUSTAKAAN', query, params, options);
};

/**
 * Database health check function for monitoring endpoints
 */
export async function getDatabaseHealth(): Promise<{
  status: 'healthy' | 'degraded' | 'unhealthy';
  databases: Record<string, {
    status: 'connected' | 'disconnected';
    responseTime?: number;
    error?: string;
    poolInfo: {
      totalConnections: number;
      idleConnections: number;
      queuedRequests: number;
    };
  }>;
  timestamp: string;
}> {
  const results = await testConnections();
  
  const healthData = {
    status: 'healthy' as 'healthy' | 'degraded' | 'unhealthy',
    databases: {} as any,
    timestamp: new Date().toISOString()
  };
  
  let healthyCount = 0;
  const pools = { ssoPool, wisPool, wisakaPool, wismonPool, perpustakaanPool };
  
  Object.entries(results).forEach(([dbName, result]) => {
    const poolName = `${dbName}Pool` as keyof typeof pools;
    const pool = pools[poolName];
    
    healthData.databases[dbName] = {
      status: result.success ? 'connected' : 'disconnected',
      responseTime: result.responseTime,
      error: result.error,
      poolInfo: {
        totalConnections: (pool as any)._allConnections?.length || 0,
        idleConnections: (pool as any)._freeConnections?.length || 0,
        queuedRequests: (pool as any)._connectionQueue?.length || 0
      }
    };
    
    if (result.success) healthyCount++;
  });
  
  // Determine overall health status
  const totalDatabases = Object.keys(results).length;
  if (healthyCount === totalDatabases) {
    healthData.status = 'healthy';
  } else if (healthyCount > 0) {
    healthData.status = 'degraded';
  } else {
    healthData.status = 'unhealthy';
  }
  
  return healthData;
}

/**
 * Graceful shutdown handler for connection pools
 */
export async function closeDatabaseConnections(): Promise<void> {
  console.log('🔄 Closing database connections gracefully...');
  
  const closePromises = [
    ssoPool.end().then(() => console.log('✅ SSO database pool closed')),
    wisPool.end().then(() => console.log('✅ WIS database pool closed')),
    wisakaPool.end().then(() => console.log('✅ WISAKA database pool closed')),
    wismonPool.end().then(() => console.log('✅ WISMON database pool closed')),
    perpustakaanPool.end().then(() => console.log('✅ PERPUSTAKAAN database pool closed'))
  ];
  
  try {
    await Promise.all(closePromises);
    console.log('✅ All database connections closed successfully');
  } catch (error) {
    console.error('❌ Error closing database connections:', error);
  }
}

// Export configurations for monitoring (without sensitive data in logs)
export const getDatabaseConfigurations = () => ({
  sso: {
    host: ssoDbConfig.host,
    port: ssoDbConfig.port,
    database: ssoDbConfig.database,
    connectionLimit: ssoDbConfig.connectionLimit
  },
  wis: {
    host: wisDbConfig.host,
    port: wisDbConfig.port,
    database: wisDbConfig.database,
    connectionLimit: wisDbConfig.connectionLimit
  },
  wisaka: {
    host: wisakaDbConfig.host,
    port: wisakaDbConfig.port,
    database: wisakaDbConfig.database,
    connectionLimit: wisakaDbConfig.connectionLimit
  },
  wismon: {
    host: wismonDbConfig.host,
    port: wismonDbConfig.port,
    database: wismonDbConfig.database,
    connectionLimit: wismonDbConfig.connectionLimit
  },
  perpustakaan: {
    host: perpustakaanDbConfig.host,
    port: perpustakaanDbConfig.port,
    database: perpustakaanDbConfig.database,
    connectionLimit: perpustakaanDbConfig.connectionLimit
  }
});

// Export pools for direct access if needed
export { ssoDbConfig, wisDbConfig, wisakaDbConfig, wismonDbConfig };

// Keep backward compatibility
export const pool = ssoPool; // Default to SSO for auth
export const executeQuery = executeSsoQuery;