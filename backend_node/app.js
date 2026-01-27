const express = require('express');
const dotenv = require('dotenv');
const bodyParser = require('body-parser');
const path = require('path');
const cors = require('cors');  // Import CORS

dotenv.config();
const app = express();

// Enable CORS for all routes
app.use(cors()); // This allows all domains, you can restrict to your frontend URL later if needed.

// If you want to restrict to a specific frontend URL (e.g., localhost:3000), use:
// app.use(cors({ origin: 'http://localhost:3000' }));

app.use(bodyParser.json());
app.use('/qrcodes', express.static(path.join(__dirname, 'public/qrcodes')));
// Add at the top with other route imports
app.use('/api', require('./routes/authRoutes'));

// Routes
app.use('/api', require('./routes/authRoutes'));

app.use('/api/student', require('./routes/studentRoutes'));
app.use('/api/admin', require('./routes/adminRoutes'));
app.use('/api/security', require('./routes/securityRoutes'));

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));