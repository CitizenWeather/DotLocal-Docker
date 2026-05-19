const API_URL = 'https://dns-api.net.local';

async function loadZones() {
    const resp = await fetch(`${API_URL}/zones`);
    const zones = await resp.json();
    const list = document.getElementById('zone-list');
    list.innerHTML = zones.map(z => `<li>${z.name} <button onclick="deleteZone('${z.name}')">Delete</button></li>`).join('');
    const select = document.getElementById('zone-select');
    select.innerHTML = zones.map(z => `<option value="${z.name}">${z.name}</option>`).join('');
}

async function createZone() {
    const name = document.getElementById('new-zone').value;
    await fetch(`${API_URL}/zones`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name })
    });
    loadZones();
}

async function deleteZone(zoneName) {
    await fetch(`${API_URL}/zones/${encodeURIComponent(zoneName)}`, { method: 'DELETE' });
    loadZones();
}

async function loadRecords() {
    const zone = document.getElementById('zone-select').value;
    if (!zone) return;
    const resp = await fetch(`${API_URL}/zones/${encodeURIComponent(zone)}/records`);
    const records = await resp.json();
    const tbody = document.querySelector('#records-table tbody');
    tbody.innerHTML = '';
    records.forEach(rr => {
        // Skip SOA and NS records
        if (rr.type === 'SOA' || rr.type === 'NS') return;
        rr.records.forEach(rec => {
            const row = tbody.insertRow();
            row.insertCell(0).innerText = rr.name;
            row.insertCell(1).innerText = rr.type;
            row.insertCell(2).innerText = rec.content;
            row.insertCell(3).innerText = rr.ttl;
            const btn = document.createElement('button');
            btn.innerText = 'Delete';
            btn.onclick = () => deleteRecord(zone, rr.name, rr.type);
            row.insertCell(4).appendChild(btn);
        });
    });
}

async function addRecord() {
    const zone = document.getElementById('zone-select').value;
    const name = document.getElementById('record-name').value;
    const type = document.getElementById('record-type').value;
    const content = document.getElementById('record-content').value;
    const ttl = document.getElementById('record-ttl').value;
    await fetch(`${API_URL}/zones/${encodeURIComponent(zone)}/records`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, type, content, ttl: parseInt(ttl) })
    });
    loadRecords();
}

async function deleteRecord(zone, name, type) {
    await fetch(`${API_URL}/zones/${encodeURIComponent(zone)}/records`, {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, type })
    });
    loadRecords();
}

loadZones();