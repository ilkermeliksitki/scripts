#!/bin/bash

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 output.mp3 input1.mpga input2.mpga [input3.mpga ...]"
  exit 1
fi

output="$1"
shift # remove output argument from the list

input_args=()
concat_input=""
index=0

for file in "$@"; do
  input_args+=("-i" "$file")
  concat_inputs+="[$index:a]"
  ((index++))
done

filter="${concat_inputs}concat=n=${#@}:v=0:a=1[outa]"

ffmpeg "${input_args[@]}" -filter_complex "$filter" -map "[outa]" -c:a libmp3lame -b:a 192k "$output"
