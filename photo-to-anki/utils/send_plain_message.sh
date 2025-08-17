#!/bin/bash

# upload the configuration variables
source "$SCRIPT_DIR/utils/config.sh"

PERSONAL_PROMPT="Your name is Minerva, an helpful assistant. Your job is to answer the user with a clear and easy-to-understand language. Also, provide toy examples if relevant."

USER_INPUT="$1"

FULL_PROMPT=$(printf "USER QUESTION: %s\n\nYOUR PERSONA: %s" "$USER_INPUT" "$PERSONAL_PROMPT")

# save the message to the database
python3 "$SCRIPT_DIR/db/save_message.py" \
    --session-id "$SESSION_ID" \
    --sender "user" \
    --content "$FULL_PROMPT" \
    --message-type "text"

# create the json payload
JSON_PAYLOAD=$(
    jq -n \
      --arg full_prompt "$FULL_PROMPT" \
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

# send request to the server
RESPONSE=$(curl -s https://api.openai.com/v1/responses \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    -d "$JSON_PAYLOAD")

# extract the response
if echo "$RESPONSE" | jq -e '.output' > /dev/null; then
    RESPONSE_TEXT=$(echo "$RESPONSE" | jq -r '
          .output[]
          | select(.type == "message")
          | .content[]
          | select(.type == "output_text")
          | .text')
    printf "\nminerva: %s\n" "$RESPONSE_TEXT"
else
    echo "❌ Error: Unexpected or null response from API:"
    echo "$RESPONSE"
    exit 1
fi

# save the response to the database
python3 "$SCRIPT_DIR/db/save_message.py" \
    --session-id "$SESSION_ID" \
    --sender "minerva" \
    --content "$RESPONSE_TEXT" \
    --message-type "text"
