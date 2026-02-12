// routes/studentRoutes.js
const express = require('express');
const router = express.Router();
const db = require('../models/db'); // ✅ Correct path
const bcrypt = require('bcryptjs');
const upload = require('../uploads/upload');

// ... rest of your code
/* =====================================
   ADD STUDENT (FROM ADMIN PANEL)
===================================== */
router.post('/add', upload.single('profile_image'), async (req, res) => {
  try {
    const {
      name,
      rollNumber,
      dob,
      department,
      address,
      phone,
      gender,
      guardian_name,
      guardian_phone,
      password
    } = req.body;

    console.log('📥 Received student data:', { name, rollNumber, department });

    // Validate required fields
    if (!name || !rollNumber || !password) {
      return res.status(400).json({
        success: false,
        message: "Name, Roll Number and Password are required"
      });
    }

    const email = `${rollNumber.toLowerCase()}@students.mygate`;
    
    // Handle profile image if uploaded
    let profileImagePath = null;
    if (req.file) {
      profileImagePath = `/uploads/${req.file.filename}`;
    }

    // Check if student already exists
    const [existingUsers] = await db.query(
      `SELECT u.id, u.email, s.roll_number 
       FROM users u 
       LEFT JOIN student s ON u.id = s.user_id 
       WHERE u.email = ? OR s.roll_number = ?`,
      [email, rollNumber]
    );

    if (existingUsers.length > 0) {
      return res.status(400).json({
        success: false,
        message: "Student with this roll number or email already exists"
      });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Start transaction
    const connection = await db.getConnection();
    await connection.beginTransaction();

    try {
      // Insert into users table
      const [userResult] = await connection.query(
        "INSERT INTO users (name, email, password, role, created_at) VALUES (?, ?, ?, ?, NOW())",
        [name, email, hashedPassword, 'student']
      );

      const userId = userResult.insertId;

      // Insert into student table
      await connection.query(
        `INSERT INTO student 
        (user_id, name, roll_number, dob, department, address, phone, gender, guardian_name, guardian_phone, profile_image, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())`,
        [
          userId,
          name,
          rollNumber,
          dob || null,
          department || null,
          address || null,
          phone || null,
          gender || null,
          guardian_name || null,
          guardian_phone || null,
          profileImagePath || null
        ]
      );

      await connection.commit();
      connection.release();

      console.log('✅ Student added successfully:', rollNumber);

      res.status(200).json({
        success: true,
        message: "Student added successfully ✅",
        data: {
          userId: userId,
          rollNumber: rollNumber,
          email: email
        }
      });

    } catch (error) {
      await connection.rollback();
      connection.release();
      throw error;
    }

  } catch (error) {
    console.error('❌ Error adding student:', error);
    res.status(500).json({
      success: false,
      message: "Failed to add student",
      error: error.message
    });
  }
});

module.exports = router;