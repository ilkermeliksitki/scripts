#!/bin/bash

API_KEY=$OPENAI_API_KEY

RAND=$(head /dev/urandom | tr -dc a-z0-9 | head -c6)
PNG_IMG="/tmp/slide_${RAND}.png"
JPG_IMG="/tmp/slide_${RAND}.jpg"

# prompt the user for their question default text: fill in the blanks.
USER_QUESTION=$(zenity --entry --title="Your Question" --text="")

PERSONA_PROMPT="Your job is to explain the key concepts in the image provided by using a good language and examples. Note that the provided image will be asked in master level deep learning exams. You should provide the answer in a way that it can be helpful in the exam."

FULL_PROMPT=$(printf "%s\n\n%s" "$USER_QUESTION" "$PERSONA_PROMPT")

# capture screenshot
flameshot gui -p "$PNG_IMG" > /dev/null 2>&1

if [ ! -s "$PNG_IMG" ]; then
  notify-send "Cancellation" "Job cancelled or no image captured."
  exit 1
fi

# save image to clipboard for practical use
xclip -selection clipboard -t image/png -i "$PNG_IMG"

# convert to jpg to reduce size and save bandwidth
convert "$PNG_IMG" -quality 70 "$JPG_IMG"

if [ ! -s "$JPG_IMG" ]; then
  notify-send "Error" "Failed to convert image to JPG or the file is empty."
  exit 1
fi

# convert image to base64 to be able to send the picture vial api
BASE64_IMAGE=$(base64 -w 0 "$JPG_IMG")

notify-send "Processing" "Generating Anki cards from the image..."

#TODO create json payload for the API request separately
RESPONSE=$(curl -s https://api.openai.com/v1/responses \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d @- <<EOF
{
  "model": "gpt-4.1-nano",
  "input": [
    {
      "role": "user",
      "content": [
        {
          "type": "input_text",
          "text": "$FULL_PROMPT"
        },
        {
          "type": "input_image",
          "image_url": "data:image/jpeg;base64,$BASE64_IMAGE"
        }
      ]
    }
  ],
  "text": {
    "format": {
      "type": "text"
    }
  },
  "max_output_tokens": 2048
}
EOF
)

echo "$RESPONSE" | jq -r '
  .output[]
  | select(.type == "message")
  | .content[]
  | select(.type == "output_text")
  | .text' > /home/melik/Documents/projects/scripts/photo-to-anki/raw_output.txt

# go back to default mode
i3-msg mode "default" > /dev/null 2>&1

RESPONSE_TEXT=$(cat /home/melik/Documents/projects/scripts/photo-to-anki/raw_output.txt)

# print the response to the terminal by using printf
printf "\nASSISTANT: %s\n" "$RESPONSE_TEXT"

CONVO_HISTORY=$(printf "USER: %s\n\nASSISTANT: %s" "$USER_QUESTION" "$RESPONSE_TEXT")

#TODO change the file location later to tmp folder
HISTORY_FILE="/home/melik/Documents/projects/scripts/photo-to-anki/convo_history.txt"

echo
echo "You can now ask follow-up questions in the terminal (type 'exit' to quit):"
while true; do
    echo
    read -p "> " FOLLOW_UP
    [[ "$FOLLOW_UP" == "exit" ]] && break

    # append the follow-up question to the conversation history
    CONVO_HISTORY=$(printf "%s\n\nUSER: %s" "$CONVO_HISTORY" "$FOLLOW_UP")

    
    # save the conversation history to a file
    printf "%s\n" "$CONVO_HISTORY" > "$HISTORY_FILE"

    # clip/fetch the last 4 messages from the conversation history
    CLIPPED_HISTORY=$(./clip_history.sh "$HISTORY_FILE" 4)

    # build full prompt without re-sending the image
    FULL_FOLLOWUP_PROMPT=$(printf "%s\n\nASSISTANT:" "$CLIPPED_HISTORY")

    # prepare json payload
    JSON_PAYLOAD=$(jq -n --arg prompt "$FULL_FOLLOWUP_PROMPT" '{
      model: "gpt-4.1-nano",
      input: [
        {
          role: "user",
          content: [
            {
              type: "input_text",
              text: $prompt
            }
          ]
        }
      ],
      text: {
        format: {
          type: "text"
        }
      },
      max_output_tokens: 2048,
    }')

    # send requests
    RESPONSE=$(curl -s https://api.openai.com/v1/responses \
      -H "Authorization: Bearer $API_KEY" \
      -H "Content-Type: application/json" \
      -d "$JSON_PAYLOAD")

    # extract the response
    if echo "$RESPONSE" | jq -e '.output' > /dev/null; then
      ASSISTANT_REPLY=$(echo "$RESPONSE" | jq -r '
          .output[]
          | select(.type == "message")
          | .content[]
          | select(.type == "output_text")
          | .text')
    else
      echo "❌ Error: Unexpected or null response from API:"
      echo "$RESPONSE"
      break
    fi

    printf "\nASSISTANT: %s\n" "$ASSISTANT_REPLY"

    CONVO_HISTORY=$(printf "%s\n\nASSISTANT: %s" "$CONVO_HISTORY" "$ASSISTANT_REPLY")
done
