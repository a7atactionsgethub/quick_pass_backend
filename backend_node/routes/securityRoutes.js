const express = require('express');
const router = express.Router();
const db = require('../models/db');
// TEST POST ROUTE
router.post('/scan', (req, res) => {
  res.json({
    message: 'Security scan route working',
    body: req.body
  });
});

module.exports = router;
