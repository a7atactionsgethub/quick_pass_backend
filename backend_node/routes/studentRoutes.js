const express = require('express');
const multer = require('multer');
const path = require('path');
const router = express.Router();
const db = require('../models/db');




// Multer setup
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, 'uploads/'),
  filename: (req, file, cb) =>
    cb(null, Date.now() + path.extname(file.originalname)),
});
const upload = multer({ storage });

// Add student
router.post('/students', upload.single('profileImage'), (req, res) => {
  const {
    name, dob, department, address, phone,
    fatherName, motherName, username, password
  } = req.body;

  const profileImage = req.file ? `/uploads/${req.file.filename}` : null;

  const sql = `INSERT INTO students 
    (name, dob, department, address, phone, fatherName, motherName, username, password, profileImage)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`;

  db.query(sql, [name, dob, department, address, phone, fatherName, motherName, username, password, profileImage],
    (err, result) => {
      if (err) {
        console.error("Insert error:", err);
        return res.status(500).json({ error: "Database error" });
      }
      res.status(200).json({ message: "Student added successfully" });
    }
  );
});

// Get all students
router.get('/students', (req, res) => {
  db.query('SELECT * FROM students', (err, results) => {
    if (err) {
      return res.status(500).json({ error: "Database error" });
    }
    res.status(200).json(results);
  });
});

module.exports = router;