#!/bin/bash

HEADER="============ Help Menu ============"
COLUMNS=$(tput cols)
STRING_LEN=${#HEADER}
PADDING=$(( (COLUMNS - STRING_LEN) / 2 ))
if [ "$PADDING" -lt 0 ]; then
  echo "$HEADER"
else
    printf "%${PADDING}s%s\n" "" "$HEADER"
fi

echo "Available Commands:"
echo ""
echo "  /i         - Input an image. Capture a screenshot or use an existing image file."
echo "  /a         - Create an Anki cards."
echo "  /w <query> - Perform a web search for the given query.(not implemented yet)"
echo "  /d <topic> - Deep dive into a topic. Get detailed information and insights.(not implemented yet)"
echo "  /qa        - Question-Answer mode. Teach a subject until the user understands. (not implemented yet)"
echo "  /h         - Display this help menu."
echo "  /c         - Change the llm model used for responses. (not implemented yet)"
echo "  /q         - Quit the chat session."
echo ""
echo "Usage Tips:"
echo "  - Commands starting with '/' are shortcuts for specific actions."
echo "  - For general queries, simply type your question or prompt."
echo ""
