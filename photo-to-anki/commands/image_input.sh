#!/bin/bash

# upload the configuration variables
SCRIPT_DIR=$(dirname "$(realpath "$0")")
source "$SCRIPT_DIR/../utils/config.sh"

# TODO: change the prompt after the exam :)
PERSONA_PROMPT="Your job is to explain the key concepts in the provided image by using a easy-to-understand language and and provide toy examples if applicable. Note that the provided image will be asked in master level image processing exam. You should provide the answer in a way that it can be helpful in the exam."

RAND=$(head /dev/urandom | tr -dc a-z0-9 | head -c6)
PNG_IMG="/tmp/slide_${RAND}.png"
JPG_IMG="/tmp/slide_${RAND}.jpg"

flameshot gui -p "$PNG_IMG" > /dev/null 2>&1

if [ ! -s "$PNG_IMG" ]; then
  #notify-send "Cancellation" "Job cancelled or no image captured."
  echo "Job cancelled or no image captured."
  exit 1
fi

# TODO: add a flag if it is pasted into the clipboard
# save image to clipboard for practical use
xclip -selection clipboard -t image/png -i "$PNG_IMG"

# convert to jpg to reduce size and save bandwidth
convert "$PNG_IMG" -quality 70 "$JPG_IMG"

if [ ! -s "$JPG_IMG" ]; then
  #notify-send "Error" "Failed to convert image to JPG or the file is empty."
  echo "Failed to convert image to JPG or the file is empty."
  exit 1
fi

# convert image to base64 to be able to send it via api
BASE64_IMAGE=$(base64 -w 0 "$JPG_IMG")

read -p "#: " USER_PROMPT

FULL_PROMPT=$(printf "USER QUESTION: %s\n\n YOUR TASK: %s" "$USER_QUESTION" "$PERSONA_PROMPT")

# create the json payload
JSON_PAYLOAD=$(
    jq -n \
      --arg full_prompt "$FULL_PROMPT" \
      --arg base64_image "$BASE64_IMAGE" \
      --arg model "$MODEL" \
      --argjson max_output_tokens "$MAX_OUTPUT_TOKENS" \
      '{
         model: $model,
         input: [
           {
             role: "user",
             content: [
               {
                 type: "input_text",
                 text: $full_prompt
               },
               {
                 type: "input_image",
                 image_url: "data:image/jpeg;base64,\($base64_image)"
               }
             ]
           }
         ],
         text: {
           format: {
              type: "text"
           }
         },
         max_output_tokens: $max_output_tokens
      }'
)

echo "image is sending to the server..."

# send request to the server
RESPONSE=$(curl -s https://api.openai.com/v1/responses \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    -d "$JSON_PAYLOAD")


# extract the respse

if echo "$RESPONSE" | jq -e '.output' > /dev/null; then
    RESPONSE_TEXT=$(echo "$RESPONSE" | jq -r '
          .output[]
          | select(.type == "message")
          | .content[]
          | select(.type == "output_text")
          | .text')
    printf "\nAI: %s\n" "$RESPONSE_TEXT"
else
    echo "❌ Error: Unexpected or null response from API:"
    echo "$RESPONSE"
    exit 1
fi
