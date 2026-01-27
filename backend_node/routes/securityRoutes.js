const express = require('express');
const router = express.Router();

// TEST POST ROUTE
router.post('/scan', (req, res) => {
  res.json({
    message: 'Security scan route working',
    body: req.body
  });
});

module.exports = router;
