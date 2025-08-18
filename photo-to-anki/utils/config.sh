#!/bin/bash

if [[ -z "$OPENAI_API_KEY" ]]; then
  echo "Error: OPENAI_API_KEY is not set. Please set it in your environment variables."
  exit 1
fi
export API_KEY=$OPENAI_API_KEY

#export MODEL="gpt-4o"                # gpt-4o     input: $2.50  cached-inp: $1.250 output: $10.00
#export MODEL="gpt-5"                 # gpt-5      input: $1.25  cached-inp: $0.125 output: $10.00
#export MODEL="gpt-5-mini"             # gpt-5-mini input: $0.25  cached-inp: $0.025 output: $2.00
export MODEL="gpt-5-nano"            # gpt-5-nano input: $0.05  cached-inp: $0.005 output: $0.40
export MAX_OUTPUT_TOKENS=10000

