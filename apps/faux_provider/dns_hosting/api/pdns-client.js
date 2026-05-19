const axios = require('axios');

const API_KEY = process.env.POWERDNS_API_KEY;
const HOST = process.env.POWERDNS_HOST || 'powerdns';
const PORT = process.env.POWERDNS_PORT || 8081;
const ROOT_DOMAIN = process.env.ROOT_DOMAIN || 'net.local';
const BASE_URL = `http://${HOST}:${PORT}/api/v1/servers/localhost`;

const client = axios.create({
    baseURL: BASE_URL,
    headers: { 'X-API-Key': API_KEY }
});

async function getZone(zoneName) {
    try {
        const res = await client.get(`/zones/${zoneName}`);
        return res.data;
    } catch (err) {
        if (err.response?.status === 404) return null;
        throw err;
    }
}

async function createZone(zoneName, nameservers = ['ns1.net.local']) {
    const zoneConfig = {
        name: zoneName,
        kind: 'Native',
        nameservers: nameservers,
        masters: [],
        dnssec: false,
        soa_edit_api: 'DEFAULT'
    };
    const res = await client.post('/zones', zoneConfig);
    return res.data;
}

async function deleteZone(zoneName) {
    await client.delete(`/zones/${zoneName}`);
}

async function listZones() {
    const res = await client.get('/zones');
    return res.data;
}

async function addRecord(zoneName, name, type, content, ttl = 3600) {
    const zone = await getZone(zoneName);
    if (!zone) throw new Error(`Zone ${zoneName} not found`);

    const rrset = {
        name: name.endsWith('.') ? name : `${name}.${zoneName}`,
        type: type,
        ttl: ttl,
        records: [{ content: content, disabled: false }],
        changetype: 'REPLACE'
    };

    const res = await client.patch(`/zones/${zoneName}`, { rrsets: [rrset] });
    return res.data;
}

async function deleteRecord(zoneName, name, type) {
    const rrset = {
        name: name.endsWith('.') ? name : `${name}.${zoneName}`,
        type: type,
        changetype: 'DELETE'
    };
    const res = await client.patch(`/zones/${zoneName}`, { rrsets: [rrset] });
    return res.data;
}

async function getRecords(zoneName) {
    const zone = await getZone(zoneName);
    if (!zone) return [];
    return zone.rrsets;
}

module.exports = {
    getZone,
    createZone,
    deleteZone,
    listZones,
    addRecord,
    deleteRecord,
    getRecords
};