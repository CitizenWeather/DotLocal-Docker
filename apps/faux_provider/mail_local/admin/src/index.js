const express = require('express');
const path = require('path');
const session = require('express-session');
const stalwart = require('./stalwart-client');

const app = express();
app.use(express.json());
app.use(session({ secret: 'netlocal-mail-admin', resave: false, saveUninitialized: true }));
app.use(express.static(path.join(__dirname, 'public')));

// API endpoints
app.post('/api/domains', async (req, res) => {
    const { domain } = req.body;
    const result = await stalwart.createDomain(domain);
    res.json(result);
});

app.get('/api/domains', async (req, res) => {
    const domains = await stalwart.listDomains();
    res.json(domains);
});

app.post('/api/accounts', async (req, res) => {
    const { domain, username, password } = req.body;
    const result = await stalwart.createAccount(domain, username, password);
    res.json(result);
});

app.post('/api/aliases', async (req, res) => {
    const { domain, source, destination } = req.body;
    const result = await stalwart.createAlias(domain, source, destination);
    res.json(result);
});

app.listen(3001, () => console.log('Mail Admin API on port 3001'));