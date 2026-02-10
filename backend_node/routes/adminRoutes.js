const express = require('express');
const bcrypt = require('bcryptjs');
const pool = require('../db');
const upload = require('../middlewares/upload');

const router = express.Router();

/**
 * ADD STUDENT
 * POST /api/admin/add-student
 */
router.post('/add-student', upload.single('profileImage'), async (req, res) => {
  const {
    name,
    dob,
    department,
    address,
    phone,
    gender,
    guardianName,
    guardianPhone,
    rollNumber,
    password
  } = req.body;

  if (!name || !dob || !department || !phone || !rollNumber || !password) {
    return res.status(400).json({ message: 'Required fields missing' });
  }

  const email = `${rollNumber.toLowerCase()}@students.mygate`;
  const imageUrl = req.file
    ? `/uploads/${req.file.filename}`
    : '';

  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    // Check existing user
    const [existing] = await connection.query(
      'SELECT id FROM users WHERE email = ? OR roll_number = ?',
      [email, rollNumber]
    );

    if (existing.length > 0) {
      await connection.rollback();
      return res.status(409).json({ message: 'Student already exists' });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Insert into users
    const [userResult] = await connection.query(
      `INSERT INTO users (name, email, roll_number, password, role, profileImageUrl)
       VALUES (?, ?, ?, ?, 'student', ?)`,
      [name, email, rollNumber, hashedPassword, imageUrl]
    );

    const userId = userResult.insertId;

    // Insert into students
    await connection.query(
      `INSERT INTO student
       (user_id, name, dob, department, address, phone, gender, guardian_name, guardian_phone)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        userId,
        name,
        dob,
        department,
        address,
        phone,
        gender,
        guardianName,
        guardianPhone
      ]
    );

    await connection.commit();

    res.status(201).json({
      message: 'Student created successfully',
      email,
      rollNumber
    });

  } catch (err) {
    await connection.rollback();
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  } finally {
    connection.release();
  }
});

module.exports = router;
