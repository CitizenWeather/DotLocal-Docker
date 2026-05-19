const API_URL = 'https://cdn-api.net.local';

async function purge() {
    const url = document.getElementById('purge-url').value;
    if (!url) return alert('Enter a URL');
    const resp = await fetch(`${API_URL}/purge`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ url })
    });
    const data = await resp.json();
    alert(data.message || 'Purge requested');
}

async function loadStats() {
    const resp = await fetch(`${API_URL}/stats`);
    const stats = await resp.json();
    document.getElementById('stats').innerHTML = `
        <p>Hit ratio: ${stats.hit_ratio * 100}%</p>
        <p>Total requests: ${stats.total_requests}</p>
        <p>Cache hits: ${stats.cache_hits}</p>
        <p>Cache misses: ${stats.cache_misses}</p>
    `;
}