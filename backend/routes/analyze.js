// === routes/analyze.js ===
const express = require('express');
const path = require('path');
const fs = require('fs');
const { exec } = require('child_process');
const archiver = require('archiver');
const { getSession } = require('../utils/session');

const router = express.Router();

router.post('/analyze', (req, res) => {
  const { proceed } = req.body;
  const { username, module } = getSession();

  if (!username || !module) {
    return res.send(`<h2>❌ Session expired. Please <a href="/">log in again</a>.</h2>`);
  }

  if (proceed !== 'yes') {
    return res.send(`<h2>❌ Analysis cancelled. You may close this window.</h2>`);
  }

  if (module !== 'COVID-19') {
    return res.send(`<h2>⚠️ Analysis for module "${module}" is not implemented yet.</h2>`);
  }

  const userDir = path.join(__dirname, '..', 'uploads', username, module);
  const rScriptPath = path.join(__dirname, '..', 'Script', 'run_covid_pipeline.R');
  const cmd = `Rscript "${rScriptPath}" "${userDir}"`;

  exec(cmd, (err, stdout, stderr) => {
    if (err) {
      return res.send(`<h2>❌ COVID-19 pipeline failed:</h2><pre>${stderr}</pre>`);
    }

    let files = [];
    try {
      files = fs.readdirSync(userDir);
    } catch (e) {
      return res.send(`<h2>✅ Pipeline ran, but no output files found.</h2><pre>${stdout}</pre>`);
    }

    const links = files.map(file => {
      const fileUrl = `/downloads/${username}/${module}/${file}`;
      return `<li><a href="${fileUrl}" target="_blank">${file}</a></li>`;
    }).join('\n');

    const zipLink = `<p><a href="/download-zip" class="button">📦 Download All as ZIP</a></p>`;

    res.send(`
      <h2>🦠 COVID-19 Full Pipeline Completed</h2>
      ${zipLink}
      <p><strong>Download Individual Files:</strong></p>
      <ul>${links}</ul>
      <pre>${stdout}</pre>
    `);
  });
});

router.get('/download-zip', (req, res) => {
  const { username, module } = getSession();

  if (!username || !module) {
    return res.status(400).send("Session expired.");
  }

  const userDir = path.join(__dirname, '..', 'uploads', username, module);
  const zipFileName = `${username}_${module}_results.zip`;

  res.setHeader('Content-Disposition', `attachment; filename=${zipFileName}`);
  res.setHeader('Content-Type', 'application/zip');

  const archive = archiver('zip', { zlib: { level: 9 } });
  archive.directory(userDir, false);
  archive.pipe(res);
  archive.finalize();
});

module.exports = router;
