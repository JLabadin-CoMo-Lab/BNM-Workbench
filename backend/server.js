const express = require('express');
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Static file access
app.use('/downloads', express.static(path.join(__dirname, 'uploads')));

// Route modules
app.use('/', require('./routes/auth'));
app.use('/', require('./routes/module'));
app.use('/', require('./routes/upload'));
app.use('/', require('./routes/analyze'));

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Server running at: http://localhost:${PORT}`);
});
