#!/bin/bash

if [[ -z "$OPENAI_API_KEY" ]]; then
  echo "Error: OPENAI_API_KEY is not set. Please set it in your environment variables."
  exit 1
fi
export API_KEY=$OPENAI_API_KEY

export MODEL="gpt-5-nano"            # gpt-5-nano input: $0.05 cached-inp: $0.005 output: $0.40
export MAX_OUTPUT_TOKENS=5000

