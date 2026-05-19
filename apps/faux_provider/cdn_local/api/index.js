const express = require('express');
const axios = require('axios');
const app = express();
app.use(express.json());

const VARNISH_ADDR = process.env.VARNISH_ADDR || 'varnish';
const VARNISH_ADMIN_PORT = process.env.VARNISH_ADMIN_PORT || 6082;
const VARNISH_ADMIN = `http://${VARNISH_ADDR}:${VARNISH_ADMIN_PORT}`;

// Purge a URL
app.post('/purge', async (req, res) => {
    const { url } = req.body;
    if (!url) return res.status(400).json({ error: 'Missing url' });

    try {
        // Varnish admin endpoint (using CLI via HTTP not trivial, but we can use ban)
        // Alternative: use varnishadm via subprocess, but for simplicity we'll use ban
        const banCommand = `ban obj.http.x-url ~ ${url}`;
        // For this demo, we assume a sidecar script; we'll just simulate success.
        // In reality, you'd run `varnishadm -T varnish:6082 "ban obj.http.x-url ~ ${url}"`
        await axios.post(`${VARNISH_ADMIN}/ban`, { url });
        res.json({ message: `Purged ${url}` });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get cache statistics
app.get('/stats', async (req, res) => {
    try {
        // Simulate stats – real would query varnishstat
        res.json({
            hit_ratio: 0.85,
            total_requests: 12345,
            cache_hits: 10493,
            cache_misses: 1852
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.listen(3002, () => console.log('CDN API listening on 3002'));