import os
from openai import OpenAI
import sqlite3
from utils.conversation.fetch_recent_messages import get_most_recent_messages

SESSION_ID = os.getenv("SESSION_ID")
DATABASE_PATH = os.getenv("DATABASE_PATH")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")


def pretty_str_messages(messages):
    result = []
    for sender, content, message_type, timestamp in messages:
        result.append(f"Sender: {sender}\nContent: {content}\nType: {message_type}\nTimestamp: {timestamp}\n{'-' * 40}")
    return "\n".join(result)


def summarize(messages):
    """Summarize the most recent messages using api"""
    inp = "Craft a summary about the given messages. Kept the main points of the conversation while maintaining the context"
    inp += "in a concise manner. Consider how the conversation has evolved over time.\n\n"
    inp += pretty_str_messages(messages)

    client = OpenAI(api_key=OPENAI_API_KEY)
    response = client.responses.create(
        model="gpt-5-nano",
        input=inp,
    )
    return response.output_text


if __name__ == "__main__":
    messages = get_most_recent_messages(SESSION_ID)
    summary = summarize(messages)
    print(summary)
