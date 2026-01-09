#!/bin/bash

export DISPLAY=:0
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus

# create a function to notify the user
notify_user() {
        notify-send "$1"
}

case "$1" in
    "modularAnkiCards")
        prompt="Extract the key concepts and create clear, standalone Anki cards. Each card must be understandable on its own months later without relying on the original or external context during anki repetition. They even shouldn't rely on each other in terms of information because they can be repeated in a completely different times or sequence. Focus only on the essential ideas that is meant to teach. Keep cards modular, concise, and centered on a single learning point. If appropriate, include a small toy example to clarify the concept."
        echo -n "$prompt" | xclip -selection clipboard
        notify_user "Create anki cards prompt from image copied to clipboard"
        ;;
    "teach_step_by_step")
        prompt="I am having difficulty understanding this content. Help me understand it by explaining concepts step by step. Start with the foundational knowledge required for each concept, and gradually build up to more complex ideas. Where applicable, use simple examples or toy problems to illustrate each step. Ensure I fully grasp each part before moving on to the next."
        echo -n "$prompt" | xclip -selection clipboard
        notify_user "Teach step by step prompt copied to clipboard"
        ;;
    "create_anki_cards")
        prompt="Alright. Now create some Anki cards."
        echo -n "$prompt" | xclip -selection clipboard
        notify_user "Create anki cards prompt copied to clipboard"
        ;;
    "explain_further")
        prompt="I did not understand quite well. Please explain further."
        echo -n "$prompt" | xclip -selection clipboard
        notify_user "Explain further prompt copied to clipboard"
        ;;
    "provide_example")
        prompt="Please provide some abstract examples to make it more clear and understandable."
        echo -n "$prompt" | xclip -selection clipboard
        notify_user "Provide example prompt copied to clipboard"
        ;;
    "complicated_anki_card")
        CLIP_TEXT=$(xclip -selection clipboard -o)
        prompt="The following anki card is so complicated. Make it simpler, easier to understand, and \
suitable for long-term memory: $CLIP_TEXT. PS: if there is an <img> or [sound:...] tags, preserve it."
        echo -n "$prompt" | xclip -selection clipboard
        notify_user "Complicated anki card prompt copied to clipboard"
        ;;
    "teach")
        subject=$(zenity --entry --title="Sujcet to teach" --text="What do you want to learn about? default: clipboard content" --entry-text="$(xclip -selection clipboard -o)")
        if [ -z "$subject" ]; then
            notify_user "No subject provided, exiting."
            exit 1
        fi
        prompt="I didn't understand at all the concepts in this subject. I would like you to ask me questions \
to achieve to learn about <subject>$subject</subject>. You should ask questions until I can answer questions \
flawlessly. You can ask multiple choice questions, true or false questions, and open-ended question"
        echo -n "$prompt" | xclip -selection clipboard
        notify_user "Teach prompt copied to clipboard"
        ;;
    *)
        notify_user "Invalid argument, no action taken"
        ;;
esac

