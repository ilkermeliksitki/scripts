import requests
from bs4 import BeautifulSoup

def fetch_wotd_html_page(url):
    headers = {
        "User-Agent": (
            "Mozilla/5.0 (X11; Linux x86_64) "
            "AppleWebKit/537.36 (KHTML, like Gecko) "
            "Chrome/128.0.0.0 Safari/537.36"
        ),
        "Accept-Language": "en-US,en;q=0.9",
        "Accept" : "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
        "Connection": "keep-alive",
    }
    response = requests.get(url, headers=headers)
    response.raise_for_status()
    return response.text


def get_word_of_the_day(html_content):
    soup = BeautifulSoup(html_content, "html.parser")
    title = soup.select_one("div.word-and-pronunciation > h2").get_text(strip=True)
    definition = soup.select_one("div.wod-definition-container > p").get_text(strip=True)
    return {"title": title, "definition": definition}



def get_wotd():
    url = "https://www.merriam-webster.com/word-of-the-day"
    html_content = fetch_wotd_html_page(url)
    wotd_info = get_word_of_the_day(html_content)
    return wotd_info


if __name__ == "__main__":
    wotd = get_wotd()
    print(wotd["title"])
    print(wotd["definition"])
