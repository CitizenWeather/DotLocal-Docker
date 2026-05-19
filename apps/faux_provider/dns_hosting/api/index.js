const express = require('express');
const cors = require('cors');
const pdns = require('./pdns-client');

const app = express();
app.use(cors());
app.use(express.json());

const ROOT_DOMAIN = process.env.ROOT_DOMAIN || 'net.local';

// List all zones
app.get('/zones', async (req, res) => {
    try {
        const zones = await pdns.listZones();
        res.json(zones);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Create a new zone (subdomain of root domain)
app.post('/zones', async (req, res) => {
    const { name } = req.body;
    if (!name) return res.status(400).json({ error: 'Missing zone name' });
    // Ensure it's under the root domain
    const fullName = name.endsWith('.') ? name : `${name}.${ROOT_DOMAIN}.`;
    try {
        const zone = await pdns.createZone(fullName);
        res.json(zone);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Delete a zone
app.delete('/zones/:zoneName', async (req, res) => {
    const { zoneName } = req.params;
    try {
        await pdns.deleteZone(zoneName);
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get records for a zone
app.get('/zones/:zoneName/records', async (req, res) => {
    const { zoneName } = req.params;
    try {
        const records = await pdns.getRecords(zoneName);
        res.json(records);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Add a DNS record
app.post('/zones/:zoneName/records', async (req, res) => {
    const { zoneName } = req.params;
    const { name, type, content, ttl } = req.body;
    if (!name || !type || !content) {
        return res.status(400).json({ error: 'Missing name, type, or content' });
    }
    try {
        const result = await pdns.addRecord(zoneName, name, type, content, ttl || 3600);
        res.json(result);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Delete a DNS record
app.delete('/zones/:zoneName/records', async (req, res) => {
    const { zoneName } = req.params;
    const { name, type } = req.body;
    if (!name || !type) {
        return res.status(400).json({ error: 'Missing name or type' });
    }
    try {
        const result = await pdns.deleteRecord(zoneName, name, type);
        res.json(result);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.listen(3003, () => console.log('DNS Hosting API on port 3003'));