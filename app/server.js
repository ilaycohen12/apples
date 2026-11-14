// Apples app: a tiny web server that reads fruit data from MongoDB.
const express = require('express');
const { MongoClient } = require('mongodb');
const os = require('os');

// Settings come from environment variables (set in docker-compose), with local defaults.
const PORT = process.env.PORT || 3000;
const MONGO_URL = process.env.MONGO_URL || 'mongodb://localhost:27017';
const DB_NAME = process.env.DB_NAME || 'store';

const app = express();
const client = new MongoClient(MONGO_URL);
let fruits; // the "fruits" collection, set after connecting

// Main page: shows the number of apples (the required test) + all fruits.
app.get('/', async (req, res) => {
  try {
    const apple = await fruits.findOne({ name: 'apples' });
    const all = await fruits.find().sort({ _id: 1 }).toArray();
    const rows = all
      .map(f => `<tr><td>${f.name}</td><td>${f.qty}</td><td>${f.rating}</td></tr>`)
      .join('');

    res.send(`<!doctype html>
<html>
<head><meta charset="utf-8"><title>Apples</title></head>
<body style="font-family:sans-serif;text-align:center">
  <h1>Hello World 🍎</h1>
  <h2>Number of apples: <span id="apples">${apple ? apple.qty : 0}</span></h2>
  <table border="1" cellpadding="6" style="margin:auto">
    <tr><th>Fruit</th><th>Qty</th><th>Rating</th></tr>${rows}
  </table>
  <p><small>Served by container: ${os.hostname()}</small></p>
</body>
</html>`);
  } catch (err) {
    console.error(err);
    res.status(500).send('Database error');
  }
});

// Health check: used by Docker/nginx to know the app is alive and DB reachable.
app.get('/health', async (req, res) => {
  try {
    await client.db('admin').command({ ping: 1 });
    res.json({ status: 'ok', host: os.hostname() });
  } catch {
    res.status(503).json({ status: 'db unavailable' });
  }
});

// Connect to MongoDB first, then start listening.
async function start() {
  await client.connect();
  fruits = client.db(DB_NAME).collection('fruits');
  app.listen(PORT, () => console.log(`apples app listening on port ${PORT}`));
}

start().catch(err => {
  console.error('Failed to start:', err);
  process.exit(1); // Docker restart policy will retry
});
