const express = require('express');
const multer = require('multer');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const archiver = require('archiver');

const app = express();
const PORT = 3000;

const USER_FILE = path.join(__dirname, 'userID.txt');
const uploadDir = path.join(__dirname, 'uploads');

// In-memory current user/module (for demo only)
let currentUsername = null;
let currentModule = null;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Multer setup with per-user + module folder and fixed filenames
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const baseDir = currentUsername || 'guest';
    const moduleDir = currentModule || 'general';
    const userDir = path.join(uploadDir, baseDir, moduleDir);
    if (!fs.existsSync(userDir)) fs.mkdirSync(userDir, { recursive: true });
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
const upload = multer({ storage });


// ========== ROUTES ==========


app.get('/', (req, res) => {
  res.send(`
    <h2>Login to Upload Files</h2>
    <form method="POST" action="/login">
      <label>Username: <input name="username" /></label><br/>
      <label>Password: <input name="password" type="password" /></label><br/>
      <button type="submit">Login</button>
    </form>
  `);
});

app.post('/login', (req, res) => {
  const { username, password } = req.body;
  currentUsername = username;

  if (!fs.existsSync(USER_FILE)) return res.send("No user records.");

  const users = fs.readFileSync(USER_FILE, 'utf-8').split('\n').filter(Boolean);
  const match = users.find(line => {
    const [u, p] = line.trim().split('\t');
    return u === username && p === password;
  });

  if (!match) {
    return res.send(`
      <h2>User not found. Register?</h2>
      <form method="POST" action="/register">
        <input name="username" value="${username}" /><br/>
        <input name="password" type="password" /><br/>
        <input name="email" placeholder="Email" /><br/>
        <button type="submit">Register</button>
      </form>
    `);
  }

  res.send(`
    <h2>Welcome, ${username}</h2>
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

app.use('/downloads', express.static(path.join(__dirname, 'uploads')));


app.post('/register', (req, res) => {
  const { username, password, email } = req.body;
  if (!username || !password || !email) {
    return res.send("All fields are required.");
  }

  const users = fs.existsSync(USER_FILE)
    ? fs.readFileSync(USER_FILE, 'utf-8').split('\n').filter(Boolean)
    : [];

  const exists = users.some(line => line.startsWith(username + '\t'));
  if (exists) {
    return res.send("Username already exists.");
  }

  fs.appendFileSync(USER_FILE, `${username}\t${password}\t${email}\n`);
  res.redirect('/');
});

app.post('/select-module', (req, res) => {
  const { module } = req.body;
  currentModule = module;

  const userPath = path.join(uploadDir, currentUsername, currentModule);
  const hasUploaded = fs.existsSync(path.join(userPath, 'contact_tracing.txt')) ||
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

app.post('/upload', (req, res, next) => {
  const userPath = path.join(uploadDir, currentUsername, currentModule);
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

app.get('/post-upload', (req, res) => {
  res.send(`
    <h2>✅ Files uploaded successfully to folder: ${currentUsername}/${currentModule}</h2>
    <p>Do you want to proceed with the analysis?</p>
    <form method="POST" action="/analyze">
      <button type="submit" name="proceed" value="yes">Yes, Proceed</button>
      <button type="submit" name="proceed" value="no">No, Exit</button>
    </form>
  `);
});


app.post('/analyze', (req, res) => {
  const { proceed } = req.body;

  // Check session info
  if (!currentUsername || !currentModule) {
    return res.send(`<h2>❌ Session expired. Please <a href="/">log in again</a>.</h2>`);
  }

  if (proceed === 'yes') {

    // Restrict to COVID-19 only
    if (currentModule !== 'COVID-19') {
      return res.send(`<h2>⚠️ Analysis for module "${currentModule}" is not implemented yet.</h2>`);
    }

    const userDir = path.join(uploadDir, currentUsername, currentModule);
    const rScriptPath = path.join(__dirname, 'Script', 'run_covid_pipeline.R');
    const cmd = `Rscript "${rScriptPath}" "${userDir}"`;

    exec(cmd, (err, stdout, stderr) => {
      if (err) {
        return res.send(`<h2>❌ COVID-19 pipeline failed:</h2><pre>${stderr}</pre>`);
      }

      // List all output files and generate download links
      let files = [];
      try {
        files = fs.readdirSync(userDir);
      } catch (e) {
        return res.send(`<h2>✅ Pipeline ran, but no output files found.</h2><pre>${stdout}</pre>`);
      }

      const links = files.map(file => {
        const fileUrl = `/downloads/${currentUsername}/${currentModule}/${file}`;
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

  } else {
    res.send(`<h2>❌ Analysis cancelled. You may close this window.</h2>`);
  }
});

app.get('/download-zip', (req, res) => {
  if (!currentUsername || !currentModule) {
    return res.status(400).send("Session expired.");
  }
  const userDir = path.join(uploadDir, currentUsername, currentModule);
  const zipFileName = `${currentUsername}_${currentModule}_results.zip`;

  res.setHeader('Content-Disposition', `attachment; filename=${zipFileName}`);
  res.setHeader('Content-Type', 'application/zip');

  const archive = archiver('zip', { zlib: { level: 9 } });
  archive.directory(userDir, false); // add all files in user dir
  archive.pipe(res);
  archive.finalize();
});


app.listen(PORT, () => {
  console.log(`🚀 Server running at: http://localhost:${PORT}`);
});
