const express = require('express');
const path = require('path');
const fs = require('fs');
const { exec } = require('child_process');
const archiver = require('archiver');
const { getSession } = require('../utils/session');

const router = express.Router();

router.post('/analyze', (req, res) => {
  const { proceed } = req.body;
  const { username, module, radius } = getSession();
  const query = `?user=${encodeURIComponent(username)}&module=${encodeURIComponent(module)}`;

  if (!username || !module) {
    return res.send(`<h2>❌ Session expired. Please <a href="/">log in again</a>.</h2>`);
  }

  if (proceed !== 'yes') {
    return res.send(`<h2>❌ Analysis cancelled. You may close this window.</h2>`);
  }

  const supportedModules = {
    'COVID-19': 'run_covid_pipeline.R',
    'Dengue': 'run_dengue_pipeline.R'
  };

  const scriptName = supportedModules[module];
  if (!scriptName) {
    return res.send(`<h2>⚠️ Analysis for module "${module}" is not implemented yet.</h2>`);
  }

  const userDir = path.join(__dirname, '..', 'uploads', username, module);
  const rScriptPath = path.join(__dirname, '..', 'Script', scriptName);

  let cmd = `Rscript "${rScriptPath}" "${userDir}"`;

  if (module === 'Dengue') {
    const radiusVal = (!radius || isNaN(radius) || parseFloat(radius) <= 0) ? 400 : parseFloat(radius);
    cmd += ` "${radiusVal}"`;
  }

  exec(cmd, (err, stdout, stderr) => {
    if (err) {
      return res.send(`<h2>❌ ${module} pipeline failed:</h2><pre>${stderr}</pre>`);
    }
    res.redirect(`/analysis-result.html${query}`);
  });
});

router.get('/list-outputs', (req, res) => {
  const { username, module } = getSession();
  const userDir = path.join(__dirname, '..', 'uploads', username, module, 'res');

  if (!username || !module) {
    return res.status(400).json({ error: 'Session expired' });
  }

  try {
    const files = fs.readdirSync(userDir).filter(f => fs.lstatSync(path.join(userDir, f)).isFile());
    res.json(files);
  } catch (e) {
    res.status(500).json({ error: 'Failed to list files' });
  }
});

router.get('/download-zip', (req, res) => {
  const { username, module } = getSession();

  if (!username || !module) {
    return res.status(400).send("Session expired.");
  }

  const userDir = path.join(__dirname, '..', 'uploads', username, module, 'res');
  const zipFileName = `${username}_${module}_results.zip`;

  res.setHeader('Content-Disposition', `attachment; filename=${zipFileName}`);
  res.setHeader('Content-Type', 'application/zip');

  const archive = archiver('zip', { zlib: { level: 9 } });
  archive.directory(userDir, false);
  archive.pipe(res);
  archive.finalize();
});

module.exports = router;
