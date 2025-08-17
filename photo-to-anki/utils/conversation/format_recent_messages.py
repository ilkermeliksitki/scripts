import os
import sys
from utils.conversation.get_most_recent_messages import get_most_recent_messages
from db.summary.get_summary import fetch_summary


def format_recent_messages(session_id=None, limit=3):
    if session_id is None:
        session_id = os.getenv("SESSION_ID")

    messages = get_most_recent_messages(session_id, limit=limit)
    if not messages:
        return ""
    messages = list(reversed(messages)) # so that the most recent message is at the end (as in the chat but clipped)

    parts = []
    # include running summary (if any) so clipped context isn't entirely lost
    running_summary = fetch_summary(session_id)
    if running_summary:
        parts.append(f"Running summary:\n{running_summary}\n---")
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
