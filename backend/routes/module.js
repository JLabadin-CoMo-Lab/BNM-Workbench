const express = require('express');
const path = require('path');
const fs = require('fs');
const { setSession, getSession } = require('../utils/session');

const router = express.Router();

router.get('/select-module', (req, res) => {
  res.send(`
    <h2>Select Module</h2>
    <form method="POST" action="/select-module">
      <label>Select Module:</label><br/>
      <select name="module">
        <option value="COVID-19">COVID-19</option>
        <option value="Dengue" disabled>Dengue (coming soon)</option>
        <option value="Subfunction" disabled>Subfunction (coming soon)</option>
      </select><br/><br/>
      <button type="submit">Continue</button>
    </form>
  `);
});


router.post('/select-module', (req, res) => {
  const { module } = req.body;
  setSession(getSession().username, module);

  const { username } = getSession();
  const userPath = path.join(__dirname, '..', 'uploads', username, module);

  const hasUploaded =
    fs.existsSync(path.join(userPath, 'contact_tracing.txt')) ||
    fs.existsSync(path.join(userPath, 'human_meta.txt'));

  const warning = hasUploaded
    ? `<p style="color:red;"><strong>⚠️ Warning:</strong> Data already exists for module <strong>${module}</strong>. Uploading new files will overwrite the current data.</p>`
    : '';

  res.send(`
    <h2>Upload Files for ${module}</h2>
    ${warning}
    <form method="POST" action="/upload" enctype="multipart/form-data">
      <label>Contact Tracing File: <input type="file" name="contactTracing" /></label><br/>
      <label>Human Metadata File: <input type="file" name="humanMeta" /></label><br/>
      <button type="submit">Upload</button>
    </form>
  `);
});

module.exports = router;

