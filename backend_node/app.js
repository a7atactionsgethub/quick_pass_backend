// app.js
const express = require('express');
const dotenv = require('dotenv');
const path = require('path');
const cors = require('cors');
const fs = require('fs');

dotenv.config();

const app = express();

/* ================================
   CORS
================================ */
app.use(cors({
  origin: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true
}));

/* ================================
   REQUEST LOGGER
================================ */
app.use((req, res, next) => {
  console.log(`➡️ ${req.method} ${req.url}`);
  next();
});

/* ================================
   BODY PARSER (BUILT-IN)
================================ */
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

/* ================================
   STATIC FILES
================================ */
// Create uploads directory if it doesn't exist
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
  console.log('📁 Created uploads directory');
}

// Serve static files
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));
app.use('/qrcodes', express.static(path.join(__dirname, 'public/qrcodes')));

/* ================================
   TEST ROUTE
================================ */
app.get('/api/test', (req, res) => {
  res.json({
    message: 'API test successful ✅',
    time: new Date(),
  });
});

/* ================================
   API ROUTES
================================ */
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/students', require('./routes/studentRoutes')); // Make sure this matches
app.use('/api/admin', require('./routes/adminRoutes'));
app.use('/api/security', require('./routes/securityRoutes'));

/* ================================
   404 HANDLER
================================ */
app.use((req, res) => {
  res.status(404).json({
    message: 'Route not found',
    path: req.originalUrl,
  });
});

/* ================================
   ERROR HANDLER
================================ */
app.use((err, req, res, next) => {
  console.error('❌ Server error:', err.stack);
  res.status(500).json({
    message: 'Internal server error',
    error: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

/* ================================
   SERVER
================================ */
const PORT = process.env.PORT || 5000;

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on:`);
  console.log(`   • Local: http://localhost:${PORT}`);
  console.log(`   • Test: http://localhost:${PORT}/api/test`);
  
  // Get local IP for network access
  const { networkInterfaces } = require('os');
  const nets = networkInterfaces();
  for (const name of Object.keys(nets)) {
    for (const net of nets[name]) {
      if (net.family === 'IPv4' && !net.internal) {
        console.log(`   • Network: http://${net.address}:${PORT}`);
      }
    }
  }
});