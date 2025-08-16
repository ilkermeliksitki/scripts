import os
from openai import OpenAI
from utils.conversation.fetch_recent_messages import get_most_recent_messages


def _pretty_str_messages(messages):
    result = []
    for sender, content, message_type, timestamp in messages:
        result.append(f"Sender: {sender}\nContent: {content}\nType: {message_type}\nTimestamp: {timestamp}\n{'-' * 40}")
    return "\n".join(result)


def summarize_most_recent():
    session_id = os.getenv("SESSION_ID")
    messages = get_most_recent_messages(session_id, limit=3)
    client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
    prompt = (
        "Craft a summary about the given messages. Keep the main points of the conversation "
        "while maintaining the context in a concise manner. Consider how the conversation has evolved over time.\n\n"
    )
    prompt += _pretty_str_messages(messages)

    response = client.responses.create(
        model="gpt-5-nano",
        input=prompt,
    )
    return response.output_text
