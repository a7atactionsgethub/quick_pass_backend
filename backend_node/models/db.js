// models/db.js
require('dotenv').config();
const mysql = require('mysql2/promise');

// Create connection pool (recommended for production)
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'students_db',
  port: process.env.DB_PORT || 3306,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  enableKeepAlive: true,
  keepAliveInitialDelay: 0
});

// Test connection
async function testConnection() {
  try {
    const connection = await pool.getConnection();
    console.log('✅ MySQL connected successfully');
    connection.release();
    return true;
  } catch (err) {
    console.error('❌ Database connection failed:', err.message);
    if (err.code === 'ECONNREFUSED') {
      console.error('⚠️  Make sure MySQL is running');
    } else if (err.code === 'ER_ACCESS_DENIED_ERROR') {
      console.error('⚠️  Check your database username and password');
    } else if (err.code === 'ER_BAD_DB_ERROR') {
      console.error('⚠️  Database does not exist. Create it first:');
      console.error('   CREATE DATABASE ' + (process.env.DB_NAME || 'students_db') + ';');
    }
    return false;
  }
}

// Run the test
testConnection();

// Export the pool for use in other files
module.exports = pool;