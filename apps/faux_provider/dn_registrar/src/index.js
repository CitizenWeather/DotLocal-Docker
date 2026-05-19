const express = require('express');
const pdns = require('./powerdns-client');
const app = express();
app.use(express.json());

app.post('/domains', async (req, res) => {
    const { subdomain, ip } = req.body;
    if (!subdomain || !ip) {
        return res.status(400).json({ error: 'Missing subdomain or ip' });
    }
    const result = await pdns.addRecord(subdomain, ip);
    if (result.success) {
        res.json({ message: `Registered ${subdomain}.${process.env.NETLOCAL_ROOT_DOMAIN || 'net.local'} -> ${ip}` });
    } else {
        res.status(500).json({ error: result.error });
    }
});

app.listen(3000, () => console.log('Registrar API listening on port 3000'));