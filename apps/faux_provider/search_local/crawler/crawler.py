import requests
from bs4 import BeautifulSoup
from meilisearch import Client
import time
import os
from urllib.parse import urljoin, urlparse

MEILISEARCH_HOST = os.getenv('MEILISEARCH_HOST', 'http://meilisearch:7700')
MEILISEARCH_KEY = os.getenv('MEILISEARCH_KEY', 'masterKey123')
CRAWL_DOMAIN = os.getenv('CRAWL_DOMAIN', 'net.local')
INDEX_NAME = 'netlocal_pages'

client = Client(MEILISEARCH_HOST, MEILISEARCH_KEY)
client.create_index(INDEX_NAME, {'primaryKey': 'url'})
index = client.index(INDEX_NAME)

# Update searchable attributes
index.update_settings({
    'searchableAttributes': ['title', 'content', 'url'],
    'displayedAttributes': ['title', 'url', 'snippet']
})

visited = set()
to_visit = [f'http://{CRAWL_DOMAIN}']

def crawl():
    while to_visit:
        url = to_visit.pop(0)
        if url in visited:
            continue
        try:
            resp = requests.get(url, timeout=10)
            if resp.status_code == 200:
                soup = BeautifulSoup(resp.text, 'html.parser')
                title = soup.title.string if soup.title else url
                text = soup.get_text(separator=' ', strip=True)
                doc = {
                    'url': url,
                    'title': title,
                    'content': text[:5000],
                    'snippet': text[:200]
                }
                index.add_documents([doc])
                # Extract new links within the same domain
                for link in soup.find_all('a', href=True):
                    full = urljoin(url, link['href'])
                    if urlparse(full).netloc.endswith(CRAWL_DOMAIN) and full not in visited:
                        to_visit.append(full)
            visited.add(url)
        except Exception as e:
            print(f"Error crawling {url}: {e}")
        time.sleep(0.5)  # Be gentle

if __name__ == '__main__':
    crawl()