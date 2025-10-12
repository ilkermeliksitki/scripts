import requests
from bs4 import BeautifulSoup

def fetch_page(url):
    headers = {
        "User-Agent": (
            "Mozilla/5.0 (X11; Linux x86_64) "
            "AppleWebKit/537.36 (KHTML, like Gecko) "
            "Chrome/128.0.0.0 Safari/537.36"
        ),
        "Accept-Language": "en-US,en;q=0.9",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
        "Connection": "keep-alive",
    }
    response = requests.get(url, headers=headers)
    response.raise_for_status()
    return response.text

def get_word_of_the_day(html_content):
    soup = BeautifulSoup(html_content, 'html.parser')
    wotd_element = soup.select_one('div.wotd')
    title_element = wotd_element.select_one('span.title_entry').get_text(strip=True)
    definition_element = wotd_element.select_one('span.ldoceEntry.Entry').get_text(strip=True)
    return {"title": title_element, "definition": definition_element}

url = "https://www.ldoceonline.com/"
html_content = fetch_page(url)
word_of_the_day = get_word_of_the_day(html_content)
print(word_of_the_day["title"])
print(word_of_the_day["definition"])

