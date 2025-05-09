// === routes/upload.js ===
const express = require('express');
const path = require('path');
const fs = require('fs');
const upload = require('../middleware/storage');
const { getSession } = require('../utils/session');

const router = express.Router();

router.post('/upload', (req, res, next) => {
  const { username, module } = getSession();
  const userPath = path.join(__dirname, '..', 'uploads', username, module);

  if (fs.existsSync(userPath)) {
    fs.readdirSync(userPath).forEach(file => fs.unlinkSync(path.join(userPath, file)));
  }
  next();
}, upload.fields([
  { name: 'contactTracing', maxCount: 1 },
  { name: 'humanMeta', maxCount: 1 }
]), (req, res) => {
  res.redirect('/post-upload');
});

router.get('/post-upload', (req, res) => {
  res.send(`
    <h2>✅ Files uploaded successfully to folder: ${getSession().username}/${getSession().module}</h2>
    <p>Do you want to proceed with the analysis?</p>
    <form method="POST" action="/analyze">
      <button type="submit" name="proceed" value="yes">Yes, Proceed</button>
      <button type="submit" name="proceed" value="no">No, Exit</button>
    </form>
  `);
});

module.exports = router;

