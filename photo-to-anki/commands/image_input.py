#!/usr/bin/env python3
"""
image input command

behavior:
- capture a screenshot using `flameshot gui`
- save image to clipboard
- build a context-aware prompt by including recent messages and a persona.
- send `input_text` + `input_image` to the OpenAI Responses API.
- save user and assistant messages to the local DB
"""

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

from utils.conversation.format_recent_messages import format_recent_messages


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


def main():
    OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
    if not OPENAI_API_KEY:
        fatal("Error: OPENAI_API_KEY is not set. Please set it in your environment.")
    MODEL = os.getenv("MODEL", "gpt-5-nano")
    MAX_OUTPUT_TOKENS = int(os.getenv("MAX_OUTPUT_TOKENS", "5000"))

    # build context
    session_id = os.getenv("SESSION_ID")
    recent = format_recent_messages(session_id)

    # capture screenshot
    rand = os.urandom(6).hex()
    png_path = f"/tmp/slide_{rand}.png"

    print("Capture an image. Close/confirm the capture to continue.")

    # give user time to prepare for closing the terminal window
    sleep(3)

    run(["flameshot", "gui", "-p", png_path])
    if not Path(png_path).is_file():
        fatal("Job cancelled or no image captured.")

    # copy to clipboard if possible (for practical use)
    if shutil_which("xclip"):
        try:
            run(["xclip", "-selection", "clipboard", "-t", "text/plain", "-i", png_path])
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
    except EOFError:
        fatal("No prompt provided; exiting.")

    persona = (
        "Your job is to explain the key concepts in the provided image in an easy-to-understand"
        " language and provide toy examples if applicable. Assume the image will be asked in a"
        " master-level image processing exam and answer in an exam-helpful style."
    )

    full_prompt = f"{recent}\nUser: {user_prompt}\n\nYOUR PERSONA: {persona}"

    # save user text message to the DB (re-use db/save_message.py)
    save_message(session_id, "user", full_prompt, "text")

    # generate a concise image description automatically via the Responses API
    def generate_image_description(data_url, api_key, model):
        url = "https://api.openai.com/v1/responses"
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}",
        }

        # ask the model to create a short caption/description for the image
        prompt_text = (
            "Provide a concise (one- or two-sentence) neutral description of the provided image."
            "Keep it under 40 words and suitable as a short caption."
        )

        payload = {
            "model": model,
            "input": [
                {
                    "role": "user",
                    "content": [
                        {"type": "input_image", "image_url": data_url},
                        {"type": "input_text", "text": prompt_text},
                    ],
                }
            ],
            "text": {"format": {"type": "text"}},
            "max_output_tokens": 60,
        }

        try:
            r = requests.post(url, headers=headers, json=payload, timeout=15)
            r.raise_for_status()
            j = r.json()
            output = j.get("output", [])
            texts = []
            for item in output:
                if item.get("type") == "message":
                    for c in item.get("content", []):
                        if c.get("type") == "output_text" and c.get("text"):
                            texts.append(c.get("text"))
            if texts:
                # return the first line as a concise description
                return " ".join(texts).strip()
        except Exception:
            pass

        return ""

    image_description = generate_image_description(data_url, OPENAI_API_KEY, os.getenv("IMAGE_DESC_MODEL", MODEL))

    # save image message to the DB (pass description and the user's prompt)
    save_message(session_id, "user", data_url, "image", image_description, user_prompt)

    payload = {
        "model": MODEL,
        "input": [
            {
                "role": "user",
                "content": [
                    {"type": "input_text", "text": full_prompt},
                    {"type": "input_image", "image_url": data_url},
                ],
            }
        ],
        "text": {"format": {"type": "text"}},
        "max_output_tokens": MAX_OUTPUT_TOKENS,
    }

    print("image is sending to the server...")

    url = "https://api.openai.com/v1/responses"
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {OPENAI_API_KEY}",
    }

    # send request to OpenAI API
    try:
        response = requests.post(url, headers=headers, json=payload)
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
    save_message(session_id, "minerva", response_text, "text")


def save_message(session_id, sender, content, message_type="text", image_description=None, image_prompt=None):
    # use the existing db/save_message.py script to preserve DB behavior
    script = SCRIPT_DIR / "db" / "save_message.py"
    args = [sys.executable, str(script), str(session_id or ""), sender, content, message_type]
    if image_description:
        args.append(image_description)
    if image_prompt:
        args.append(image_prompt)
    subprocess.run(args)



if __name__ == "__main__":
    main()
