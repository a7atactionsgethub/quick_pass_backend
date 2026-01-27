const express = require('express');
const router = express.Router();
const mysql = require('mysql2/promise');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

require('dotenv').config();

// MySQL connection pool
const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT
});

// POST /api/auth/login
router.post('/auth/login', async (req, res) => {
  const { identifier, password, role } = req.body;

  if (!identifier || !password || !role) {
    return res.status(400).json({ message: 'All fields are required' });
  }

  try {
    // Table structure assumption: users (id, name, email, roll_number, password, role, profileImageUrl)
    const [rows] = await pool.query(
      'SELECT * FROM users WHERE (email = ? OR roll_number = ?) AND role = ? LIMIT 1',
      [identifier, identifier, role]
    );

    if (rows.length === 0) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const user = rows[0];

    // Check hashed password using bcrypt
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // Generate JWT token
    const token = jwt.sign(
      { id: user.id, role: user.role },
      process.env.JWT_SECRET || 'secret123',
      { expiresIn: '8h' }
    );

    return res.json({
      token,
      role: user.role,
      name: user.name,
      profileImageUrl: user.profileImageUrl || '',
      identifier: user.roll_number || user.email
    });

  } catch (err) {
    console.error('Login error:', err);
    return res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
