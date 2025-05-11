const express = require('express');
const path = require('path');
const fs = require('fs');
const multer = require('multer');
const { getSession } = require('../utils/session');

const router = express.Router();
const upload = multer({ dest: 'tmp/' });

router.post('/upload', (req, res, next) => {
  const { username, module } = getSession();
  const userPath = path.join(__dirname, '..', 'uploads', username, module);

  if (fs.existsSync(userPath)) {
    fs.readdirSync(userPath).forEach(file => {
      const fullPath = path.join(userPath, file);
      const stat = fs.lstatSync(fullPath);
      if (stat.isDirectory()) {
        fs.rmSync(fullPath, { recursive: true, force: true });
      } else {
        fs.unlinkSync(fullPath);
      }
    });
  } else {
    fs.mkdirSync(userPath, { recursive: true });
  }

  req.userPath = userPath;
  req.module = module;
  next();
}, (req, res, next) => {
  const module = req.module;

  const fieldsMap = {
    'COVID-19': [
      { name: 'contactTracing', maxCount: 1 },
      { name: 'humanMeta', maxCount: 1 }
    ],
    'Dengue': [
      { name: 'movement', maxCount: 1 },
      { name: 'locationList', maxCount: 1 } // optional, but multer accepts it if provided
    ]
  };

  const fieldConfig = fieldsMap[module];
  if (!fieldConfig) return res.status(400).send('❌ Unsupported module during upload.');

  upload.fields(fieldConfig)(req, res, next);
}, (req, res) => {
  const { username, module } = getSession();
  const files = req.files || {};
  const userPath = req.userPath;

  const renameMap = {
    'COVID-19': {
      contactTracing: 'contact_tracing.txt',
      humanMeta: 'human_meta.txt'
    },
    'Dengue': {
      movement: 'movement_list.txt',
      locationList: 'location_list.txt' // optional
    }
  };

  const mapping = renameMap[module] || {};

  for (const field in mapping) {
    if (files[field] && files[field][0]) {
      const src = files[field][0].path;
      const dest = path.join(userPath, mapping[field]);
      fs.renameSync(src, dest);
    }
  }

  const qs = `?user=${encodeURIComponent(username)}&module=${encodeURIComponent(module)}`;
  res.redirect(`/post-upload.html${qs}`);
});

module.exports = router;
