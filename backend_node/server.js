const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const studentRoutes = require('./routes/studentRoutes'); // ✅ Correct relative path
const path = require('path');

const app = express();

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Serve static files (for images)
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Student routes
app.use('/api', studentRoutes); // All routes from studentRoutes.js will be prefixed with /api

// Start server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});