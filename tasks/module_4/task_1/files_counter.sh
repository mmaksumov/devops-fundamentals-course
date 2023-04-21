#!/usr/bin/env bash

COLOR_GREEN='\e[32m'
COLOR_WARNING='\e[33m'
COLOR_RESET='\e[0m'

dirs_count="$#"
dirs=("$@")

if ((dirs_count == 0)); then
    echo -e "${COLOR_WARNING}Usage: $0 <directory> [...<directory2> [...<directory3> ...]]${COLOR_RESET}"
    exit 1
fi

for dir in "${dirs[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "Error: ${dir} is not a directory"
        exit 1
    fi

    echo -e "\nDirectory: ${COLOR_GREEN}${dir}${COLOR_RESET}"

    count="$(find "${dir}" -type f 2>/dev/null | wc -l)"

    echo "Number of files in directory '${dir}': ${count}"
done
