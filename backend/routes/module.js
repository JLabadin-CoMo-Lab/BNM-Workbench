const express = require('express');
const path = require('path');
const fs = require('fs');
const { setSession, getSession } = require('../utils/session');

const router = express.Router();

router.post('/select-module', (req, res) => {
  const { module, radius } = req.body;
  const supportedModules = ['COVID-19', 'Dengue'];

  if (!supportedModules.includes(module)) {
    return res.status(400).send(`❌ Invalid module "${module}".`);
  }

  const { username } = getSession();

  if (module === 'Dengue') {
    const radiusVal = (!radius || isNaN(radius) || parseFloat(radius) <= 0) ? '400' : radius;
    setSession(username, module, radiusVal);
  } else {
    setSession(username, module);
  }

  const baseDir = path.join(__dirname, '..', 'uploads', username, module);
  const outputDir = path.join(baseDir, 'res');

  let inputsExist = false;

  if (module === 'COVID-19') {
    inputsExist = fs.existsSync(path.join(baseDir, 'contact_tracing.txt')) &&
                  fs.existsSync(path.join(baseDir, 'human_meta.txt')); // ✅ fixed
  } else if (module === 'Dengue') {
    inputsExist = fs.existsSync(path.join(baseDir, 'movement_list.txt'));
  }

  const outputExists = fs.existsSync(outputDir) && fs.readdirSync(outputDir).length > 0;

  const qs = `?user=${encodeURIComponent(username)}&module=${encodeURIComponent(module)}`;
  if (inputsExist && outputExists) {
    return res.redirect(`/reuse-or-upload.html${qs}`);
  }
  return res.redirect(`/upload.html${qs}`);

});

module.exports = router;
