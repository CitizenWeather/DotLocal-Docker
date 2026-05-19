const axios = require('axios');
const PDNS_API_KEY = process.env.POWERDNS_API_KEY;
const PDNS_HOST = process.env.POWERDNS_HOST || 'powerdns';
const DOMAIN = process.env.NETLOCAL_ROOT_DOMAIN || 'net.local';

async function addRecord(subdomain, ip, type='A') {
    const record = {
        rrsets: [{
            name: `${subdomain}.${DOMAIN}.`,
            type: type,
            ttl: 3600,
            records: [{ content: ip, disabled: false }]
        }]
    };
    const url = `http://${PDNS_HOST}:8081/api/v1/servers/localhost/zones/${DOMAIN}`;
    try {
        await axios.patch(url, record, {
            headers: { 'X-API-Key': PDNS_API_KEY }
        });
        return { success: true };
    } catch (err) {
        return { success: false, error: err.message };
    }
}

module.exports = { addRecord };