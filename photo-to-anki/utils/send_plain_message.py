import os
import sys
import requests

from utils.conversation.get_most_recent_messages import get_most_recent_messages
from db.save_message import save_message

def fatal(msg, code=1):
    print(msg)
    sys.exit(code)

def send_plain_message(user_prompt=None):
    OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
    if not OPENAI_API_KEY:
        fatal("Error: OPENAI_API_KEY is not set. Please set it in your environment.")
    MODEL = os.getenv("MODEL", "gpt-5-nano")
    MAX_OUTPUT_TOKENS = int(os.getenv("MAX_OUTPUT_TOKENS", "5000"))

    # build context
    session_id = os.getenv("SESSION_ID")
    api_inputs = get_most_recent_messages(session_id)

    # depracted way of getting persona (to be removed)
    persona = "Your name is Minerva, a helpful AI assistant. Your job is to answer the user's questions with a clear and easy-to-understand language. Also, provide toy examples if relevant."

    # save user prompt to the messages table in DB
    save_message(session_id, "user", text_content=user_prompt)

    # prepare the request payload
    payload_input = api_inputs + [
        {
            "role": "user",
            "content": [
                {
                    "type": "input_text",
                    "text": user_prompt
                }
            ]
        }
    ]

    payload = {
        "model": MODEL,
        "input": payload_input,
        "max_output_tokens": MAX_OUTPUT_TOKENS
    }

    # TODO: this appears frequently, consider creating a utility function for it
    url = "https://api.openai.com/v1/responses"
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {OPENAI_API_KEY}",
    }

    # send request to OpenAI API
    response = requests.post(url, headers=headers, json=payload)
    try:
        response.raise_for_status()
        resp_json = response.json()
    except requests.exceptions.RequestException as e:
        fatal(f"❌ Error: failed to send request to OpenAI API: {e}")
        return
        
    output = resp_json.get("output", [])
    texts = []
    for item in output:
        if item.get("type") == "message":
            for c in item.get("content", []):
                if c.get("type") == "output_text" and c.get("text"):
                    texts.append(c.get("text").strip())
    
    if not texts:
        fatal("❌ Error: no text output received from the API.")

    response_text = "\n".join(texts)
    print(f"\nminerva: {response_text}\n")

    # save assistant response
    save_message(session_id, "minerva", text_content=response_text)

if __name__ == "__main__":
    send_plain_message()
