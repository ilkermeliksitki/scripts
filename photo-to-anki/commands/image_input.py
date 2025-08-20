#!/usr/bin/env python3

import os
import sys
import subprocess
from time import sleep
import base64
import json
import requests
from pathlib import Path


SCRIPT_DIR = Path(os.environ.get("SCRIPT_DIR"))
sys.path.insert(0, str(SCRIPT_DIR))

from utils.conversation.get_most_recent_messages import get_most_recent_messages
from db.save_message import save_message


def fatal(msg, code=1):
    print(msg)
    sys.exit(code)


def run(cmd, **kwargs):
    return subprocess.run(cmd, check=False, **kwargs)


def shutil_which(cmd):
    """find the available command"""
    try:
        import shutil
        return shutil.which(cmd)
    except Exception:
        return None


def image_input():
    OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
    if not OPENAI_API_KEY:
        fatal("Error: OPENAI_API_KEY is not set. Please set it in your environment.")
    MODEL = os.getenv("MODEL", "gpt-5-nano")
    MAX_OUTPUT_TOKENS = int(os.getenv("MAX_OUTPUT_TOKENS", "5000"))

    # build context
    session_id = os.getenv("SESSION_ID")
    api_inputs = get_most_recent_messages(session_id)

    # capture screenshot
    rand = os.urandom(6).hex()
    png_path = f"/tmp/minerva_{rand}.png"

    print("Capture an image. Close/confirm the capture to continue.")

    # give user time to prepare for closing the terminal window
    sleep(2)

    run(["flameshot", "gui", "-p", png_path])
    if not Path(png_path).is_file():
        fatal("Job cancelled or no image captured.")

    # copy to clipboard if possible (for practical use)
    if shutil_which("xclip"):
        try:
            run(["xclip", "-selection", "clipboard", "-t", "image/png", "-i", png_path])
        except Exception:
            pass

    # read and base64-encode the png
    with open(png_path, "rb") as f:
        img_bytes = f.read()
    b64 = base64.b64encode(img_bytes).decode("ascii")
    data_url = f"data:image/png;base64,{b64}"

    # prompt
    try:
        user_prompt = input("prompt about image: ")
        user_prompt = user_prompt.strip()
    except EOFError:
        fatal("No prompt provided; exiting.")

    persona = (
        "Your job is to explain the key concepts in the provided image in an easy-to-understand"
        " language and provide toy examples if applicable. Assume the image will be asked in a"
        " master-level image processing exam and answer in an exam-helpful style."
    )

    # save user prompt for the image to the messages table in DB
    save_message(session_id, "user", text_content=user_prompt)

    # save image to the images table in DB
    save_message(session_id, "user", image_bytes=img_bytes)

    # combine context messages (List[Dict]) and user prompt with image
    payload_input = api_inputs + [
        {
            "role": "user",
            "content": [
                {"type": "input_text", "text": user_prompt},
                {"type": "input_image", "image_url": data_url},
            ],
        }
    ]

    payload = {
        "model": MODEL,
        "input": payload_input,
        "text": {"format": {"type": "text"}},
        "max_output_tokens": MAX_OUTPUT_TOKENS,
    }

    print("image is sending to the server...")

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

    output = resp_json.get("output", [])
    texts = []
    for item in output:
        if item.get("type") == "message":
            for c in item.get("content", []):
                if c.get("type") == "output_text" and c.get("text"):
                    texts.append(c.get("text"))

    if not texts:
        fatal(f"❌ Error: unexpected or null response from API:\n{json.dumps(resp_json, indent=2)}")

    response_text = "\n".join(texts)
    print(f"\nminerva: {response_text}\n")

    # save assistant response
    save_message(session_id, "minerva", text_content=response_text)


if __name__ == "__main__":
    image_input()
