#!/bin/bash

API_KEY=$OPENAI_API_KEY

RAND=$(head /dev/urandom | tr -dc a-z0-9 | head -c6)
PNG_IMG="/tmp/slide_${RAND}.png"
JPG_IMG="/tmp/slide_${RAND}.jpg"

PROMPT="You are a learning and subject-matter expert. Your task is to deeply understand the core principles given in the picture. Then, think like the experts in the field, such as a physics professor or senior software engineer depending on the subject. Then explain the concepts clearly. If applicable, provide some toy examples to make the explanation more understandable. Then, create high-quality, modular Anki cards that promote long-term understanding. Also, include relevant examples or explanations on the back of the card if applicable. Note that the provided content is lecture content and it will be asked in the exam. So be careful about not missing important information. Your long-term goal is to help me master the subject through spaced repetition. If there are mathematical equations, write them in LaTeX format. If there are code snippets, write them in a code block."

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
  | .text' > /home/melik/Documents/projects/scripts/photo-to-anki/raw_output.txt

#cat /home/melik/Documents/projects/scripts/photo-to-anki/raw_output.txt | pandoc -f markdown -t plain -o /home/melik/Documents/projects/scripts/photo-to-anki/output.txt

cat /home/melik/Documents/projects/scripts/photo-to-anki/raw_output.txt

# go back to default mode
i3-msg mode "default" > /dev/null 2>&1

