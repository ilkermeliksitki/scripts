import os
import sys
from utils.conversation.fetch_recent_messages import get_most_recent_messages


def format_recent_messages(session_id=None, limit=3):
    if session_id is None:
        session_id = os.getenv("SESSION_ID")
    if session_id is None:
        return ""

    messages = get_most_recent_messages(session_id, limit=limit)
    #messages = list(reversed(messages))

    parts = []
    for sender, content, message_type, timestamp in messages:
        parts.append(f"Sender: {sender}\nContent: {content}\nType: {message_type}\n---")

    return "\n".join(parts)


if __name__ == "__main__":
    sid = None
    lim = 3
    if len(sys.argv) > 1:
        sid = sys.argv[1]
    if len(sys.argv) > 2:
        try:
            lim = int(sys.argv[2])
        except ValueError:
            pass

    print(format_recent_messages(sid, lim))

