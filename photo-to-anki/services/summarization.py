import os
from openai import OpenAI
from utils.conversation.fetch_recent_messages import get_most_recent_messages
from db.summary.get_summary import fetch_summary
import traceback


def _pretty_str_messages(messages):
    result = []
    for sender, content, message_type, timestamp in messages:
        result.append(f"Sender: {sender}\nContent: {content}\nType: {message_type}\nTimestamp: {timestamp}\n{'-' * 40}")
    return "\n".join(result)


def summarize_most_recent(limit=3):
    session_id = os.getenv("SESSION_ID")
    messages = get_most_recent_messages(session_id, limit=limit)
    client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
    # start prompt with any existing running summary so the model can update it
    previous_summary = fetch_summary(session_id)

    if previous_summary:
        prompt = (
            "You are given a running summary of a chat, followed by the most recent messages. "
            "Update and condense the running summary to include the new messages while preserving important context.\n\n"
        )
        prompt += f"Existing summary:\n{previous_summary}\n\n"
    else:
        prompt = (
            "Craft a summary about the given messages. Keep the main points of the conversation "
            "while maintaining the context in a concise manner. Consider how the conversation has evolved over time.\n\n"
        )

    prompt += _pretty_str_messages(messages)

    try:
        response = client.responses.create(
            model="gpt-5-nano",
            input=prompt,
        )
        return response.output_text
    except Exception as e:
        # don't crash the CLI for summarization failures; return empty string
        print("Warning: summarization failed:", e)
        traceback.print_exc()
        return ""
