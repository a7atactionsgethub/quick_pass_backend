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
      profile_image   // 👈 receive base64 here
    } = req.body;

    console.log("📥 Image received:", profile_image ? "YES" : "NO");

    if (!name || !rollNumber || !password) {
      return res.status(400).json({
        success: false,
        message: "Name, Roll Number and Password are required"
      });
    }

    const email = `${rollNumber.toLowerCase()}@students.mygate`;

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

      const [userResult] = await connection.query(
  "INSERT INTO users (name, email, password, role, profileImageUrl) VALUES (?, ?, ?, ?, ?)",
  [
    name,
    email,
    hashedPassword,
    'student',
    profile_image || null   // 🔥 store in users also
  ]
);
      const userId = userResult.insertId;

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
          profile_image || null   // 👈 store base64 directly
        ]
      );

      await connection.commit();
      connection.release();

      res.status(200).json({
        success: true,
        message: "Student added successfully"
      });

    } catch (err) {
      await connection.rollback();
      connection.release();
      throw err;
    }

  } catch (error) {
    console.error("❌ Error:", error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});
module.exports = router;