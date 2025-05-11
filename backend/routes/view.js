const { exec } = require('child_process');
const path = require('path');

app.post('/hotspot-redirect', (req, res) => {
  const { username, module } = getSession();  // if using your session utility
  const userPath = path.join(__dirname, 'uploads', username, module);
  const scriptPath = path.join(__dirname, 'Script', 'generate_hotspot_json.R');
  const cmd = `Rscript "${scriptPath}"`;

  exec(cmd, { cwd: userPath }, (err, stdout, stderr) => {
    if (err) {
      return res.send(`<h2>❌ Hotspot JSON generation failed:</h2><pre>${stderr}</pre>`);
    }
    res.sendFile(path.join(__dirname, 'frontend', 'hotspot-map.html'));
  });
});

