const axios = require('axios');

const STALWART_HOST = process.env.STALWART_HOST || 'stalwart';
const STALWART_PORT = process.env.STALWART_API_PORT || 8080;
const STALWART_SECRET = process.env.STALWART_SECRET;

const client = axios.create({
    baseURL: `http://${STALWART_HOST}:${STALWART_PORT}`,
    headers: { 'Authorization': `Bearer ${STALWART_SECRET}` }
});

async function createDomain(domain) {
    try {
        await client.post('/api/domain', { name: domain });
        return { success: true };
    } catch (err) {
        return { success: false, error: err.response?.data || err.message };
    }
}

async function listDomains() {
    try {
        const res = await client.get('/api/domain');
        return res.data;
    } catch (err) {
        return [];
    }
}

async function createAccount(domain, username, password) {
    try {
        const address = `${username}@${domain}`;
        await client.post('/api/account', {
            address,
            password,
            name: username,
            quota: 1024 * 1024 * 100 // 100 MB
        });
        return { success: true };
    } catch (err) {
        return { success: false, error: err.response?.data || err.message };
    }
}

async function createAlias(domain, source, destination) {
    try {
        const sourceAddr = `${source}@${domain}`;
        const destAddr = `${destination}@${domain}`;
        await client.post('/api/alias', { source: sourceAddr, destination: destAddr });
        return { success: true };
    } catch (err) {
        return { success: false, error: err.response?.data || err.message };
    }
}

module.exports = { createDomain, listDomains, createAccount, createAlias };