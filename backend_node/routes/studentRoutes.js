// routes/studentRoutes.js

const express = require('express');
const router = express.Router();
const db = require('../models/db');
const bcrypt = require('bcryptjs');

/* =====================================
   ADD STUDENT (FROM ADMIN PANEL)
===================================== */
router.post('/add', async (req, res) => {
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
      password,
      profile_image   // base64 image
    } = req.body;

    if (!name || !rollNumber || !password) {
      return res.status(400).json({
        success: false,
        message: "Name, Roll Number and Password are required"
      });
    }

    const email = `${rollNumber.toLowerCase()}@students.mygate`;

    // 🔍 Check existing
    const [existingUsers] = await db.query(
      `SELECT u.id 
       FROM users u 
       LEFT JOIN student s ON u.id = s.user_id 
       WHERE u.email = ? OR s.roll_number = ?`,
      [email, rollNumber]
    );

    if (existingUsers.length > 0) {
      return res.status(400).json({
        success: false,
        message: "Student already exists"
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const connection = await db.getConnection();
    await connection.beginTransaction();

    try {
      // ✅ Insert into users table
      const [userResult] = await connection.query(
        `INSERT INTO users 
        (name, email, roll_number, password, role, profileImageUrl) 
        VALUES (?, ?, ?, ?, ?, ?)`,
        [
          name,
          email,
          rollNumber,
          hashedPassword,
          'student',
          profile_image || null
        ]
      );

      const userId = userResult.insertId;

      // ✅ Insert into student table
      await connection.query(
        `INSERT INTO student 
        (user_id, name, roll_number, dob, department, address, phone, gender, guardian_name, guardian_phone, profile_image)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
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
          profile_image || null
        ]
      );

      await connection.commit();
      connection.release();

      res.status(201).json({
        success: true,
        message: "Student added successfully"
      });

    } catch (err) {
      await connection.rollback();
      connection.release();
      throw err;
    }

  } catch (error) {
    console.error("❌ Error adding student:", error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});


/* =====================================
   GET STUDENT DETAILS BY ROLL NUMBER
===================================== */
router.get('/:rollNumber', async (req, res) => {
  try {
    const { rollNumber } = req.params;

    const [rows] = await db.query(
      `SELECT 
         u.id,
         u.name,
         u.email,
         u.role,
         u.profileImageUrl,
         s.roll_number,
         s.department,
         s.dob,
         s.address,
         s.phone,
         s.gender,
         s.guardian_name,
         s.guardian_phone
       FROM users u
       LEFT JOIN student s ON u.id = s.user_id
       WHERE s.roll_number = ?`,
      [rollNumber]
    );

    if (rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Student not found"
      });
    }

    res.json({
      success: true,
      id: rows[0].id,
      name: rows[0].name,
      email: rows[0].email,
      rollNumber: rows[0].roll_number,
      department: rows[0].department,
      dob: rows[0].dob,
      address: rows[0].address,
      phone: rows[0].phone,
      gender: rows[0].gender,
      guardian_name: rows[0].guardian_name,
      guardian_phone: rows[0].guardian_phone,
      profileImageUrl: rows[0].profileImageUrl
    });

  } catch (error) {
    console.error("❌ Error fetching student:", error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

module.exports = router;