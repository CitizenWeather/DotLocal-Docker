async function loadDomains() {
    const res = await fetch('/api/domains');
    const domains = await res.json();
    const list = document.getElementById('domain-list');
    list.innerHTML = domains.map(d => `<li>${d.name}</li>`).join('');
    const selects = ['domain-select', 'alias-domain-select'];
    selects.forEach(id => {
        const sel = document.getElementById(id);
        sel.innerHTML = domains.map(d => `<option value="${d.name}">${d.name}</option>`).join('');
    });
}

async function createDomain() {
    const domain = document.getElementById('new-domain').value;
    await fetch('/api/domains', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ domain })
    });
    loadDomains();
}

async function createAccount() {
    const domain = document.getElementById('domain-select').value;
    const username = document.getElementById('username').value;
    const password = document.getElementById('password').value;
    await fetch('/api/accounts', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ domain, username, password })
    });
    alert('Account created');
}

async function createAlias() {
    const domain = document.getElementById('alias-domain-select').value;
    const source = document.getElementById('source').value;
    const destination = document.getElementById('destination').value;
    await fetch('/api/aliases', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ domain, source, destination })
    });
    alert('Alias created');
}

loadDomains();