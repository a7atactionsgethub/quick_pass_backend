// routes/authRoutes.js
const express = require('express');
const router = express.Router();
const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
require('dotenv').config();

// Create MySQL connection pool
const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT
});

// POST /api/auth/login
router.post('/login', async (req, res) => {
  const { identifier, password, role } = req.body;

  if (!identifier || !password || !role) {
    return res.status(400).json({ message: 'All fields required' });
  }

  try {
    // Use LOWER() to make role case-insensitive
    const [rows] = await pool.query(
      `SELECT * FROM users
       WHERE LOWER(role) = LOWER(?)
       AND (email = ? OR roll_number = ?)
       LIMIT 1`,
      [role, identifier, identifier]
    );

    if (rows.length === 0) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const user = rows[0];

    // Compare password
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

    // Send back all necessary info
    res.json({
      token,
      role: user.role.toLowerCase(), // always lowercase for Flutter switch
      name: user.name,
      email: user.email,
      roll_number: user.roll_number,
      profileImageUrl: user.profileImageUrl || '',
      identifier: user.roll_number || user.email // for Flutter extra
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
