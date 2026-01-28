const express = require('express');
const dotenv = require('dotenv');
const bodyParser = require('body-parser');
const path = require('path');
const cors = require('cors');

dotenv.config();

const app = express();

/* ================================
   CORS CONFIG (EXPRESS v5 SAFE)
================================ */
app.use(cors({
  origin: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// Handle OPTIONS safely (NO path-to-regexp crash)
app.use((req, res, next) => {
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  next();
});

/* ================================
   REQUEST LOGGER
================================ */
app.use((req, res, next) => {
  console.log(`➡️ ${req.method} ${req.url}`);
  next();
});

/* ================================
   BODY PARSER
================================ */
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

/* ================================
   STATIC FILES
================================ */
app.use('/qrcodes', express.static(path.join(__dirname, 'public/qrcodes')));

/* ================================
   TEST ROUTE
================================ */
app.get('/api/test', (req, res) => {
  res.json({
    message: 'API test successful ✅',
    time: new Date()
  });
});

/* ================================
   API ROUTES
================================ */
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/student', require('./routes/studentRoutes'));
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
   SERVER
================================ */
const PORT = process.env.PORT || 5000;

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on port ${PORT}`);
});
