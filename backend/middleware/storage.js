const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { getSession } = require('../utils/session');

// Multer storage config
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const { username, module } = getSession();
    const userDir = path.join(__dirname, '..', 'uploads', username || 'guest', module || 'general');

    if (!fs.existsSync(userDir)) {
      fs.mkdirSync(userDir, { recursive: true });
    }

    cb(null, userDir);
  },

  filename: function (req, file, cb) {
    if (file.fieldname === 'contactTracing') {
      cb(null, 'contact_tracing.txt');
    } else if (file.fieldname === 'humanMeta') {
      cb(null, 'human_meta.txt');
    } else {
      cb(null, `${file.fieldname}.txt`);
    }
  }
});

module.exports = multer({ storage });

