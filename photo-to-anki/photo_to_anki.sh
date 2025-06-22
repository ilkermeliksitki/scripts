#!/bin/bash

API_KEY=$OPENAI_API_KEY
PNG_IMG="/tmp/slide.png"
JPG_IMG="/tmp/slide.jpg"

PROMPT="Please create Anki cards based on the provided image. The image contains lecture content that will be asked in the exam, so ensure that you do not miss any important information. Your goal is to help me master the subject through spaced repetition. But first, identify the most essential concepts in the image and then generate modular Anki cards that promote long-term understanding. The cards should be clear, concise, and self-contained. If helpful, include relevant examples or explanations on the back of the card. Be careful about not missing important information."

flameshot gui -c

xclip -selection clipboard -t image/png -o > "$PNG_IMG"

# convert to jpg to reduce size and save bandwidth
convert "$PNG_IMG" -quality 70 "$JPG_IMG"

if [ ! -s "$JPG_IMG" ]; then
  echo "❌ Error: No image in clipboard. Did you press Ctrl+C after screenshot?"
  exit 1
fi

# convert image to base64 to be able to send the picture vial api
BASE64_IMAGE=$(base64 -w 0 "$JPG_IMG")

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
          "text": "$PROMPT"
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
  "temperature": 1,
  "top_p": 1,
  "max_output_tokens": 2048
}
EOF
)

echo "$RESPONSE" | jq -r '
  .output[]
  | select(.type == "message")
  | .content[]
  | select(.type == "output_text")
  | .text'
> /home/melik/Documents/projects/scripts/photo-to-anki/output.txt

cat /home/melik/Documents/projects/scripts/photo-to-anki/output.txt | pandoc -f markdown -t plain

