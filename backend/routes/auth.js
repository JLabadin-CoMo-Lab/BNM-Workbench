const express = require('express');
const fs = require('fs');
const path = require('path');
const { setSession } = require('../utils/session');

const router = express.Router();
const USER_FILE = path.join(__dirname, '..', 'userID.txt');

router.get('/', (req, res) => {
  res.redirect('/index.html');
});

router.post('/login', (req, res) => {
  const { username, password } = req.body;
  setSession(username);

  if (!fs.existsSync(USER_FILE)) return res.send("No user records.");
  const users = fs.readFileSync(USER_FILE, 'utf-8').split('\n').filter(Boolean);
  const match = users.find(line => {
    const [u, p] = line.split('\t');
    return u === username && p === password;
  });

  if (!match) {
    res.redirect('/register.html');
  }

  res.redirect('/select-module.html');
});

router.post('/register', (req, res) => {
  const { username, password, email } = req.body;
  if (!username || !password || !email) return res.send("All fields are required.");

  const users = fs.existsSync(USER_FILE)
    ? fs.readFileSync(USER_FILE, 'utf-8').split('\n').filter(Boolean)
    : [];

  const exists = users.some(line => line.startsWith(username + '\t'));
  if (exists) return res.send("Username already exists.");

  fs.appendFileSync(USER_FILE, `${username}\t${password}\t${email}\n`);
  res.redirect('/');
});

module.exports = router;

