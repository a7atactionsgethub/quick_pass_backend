const express = require('express');
const router = express.Router();

// TEMP test route
router.put('/approve', (req, res) => {
  res.send('Approve route working');
});

module.exports = router;
