#!/usr/bin/env zsh
DIR="${1:-.}"
declare -A seen 
while IFS= read -r -d '' file; do
	hash=$(shasum "$file" | awk '{print $1}')
	if [[ -n "${seen[$hash]}" ]]; then
		rm "$file"
	else
		seen[$hash]="$file"
	fi
done < <(find "$DIR" -type f -print0)
