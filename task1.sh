#!/bin/bash

step_count=1
win=0
lose=0
declare -a numbers

RED=$'\033[31m'
GREEN=$'\033[32m'
RESET=$'\033[0m'

rand_int=${RANDOM: -1}

while :
do
    echo "Step: $step_count"
    read -p "Please enter value: " input

    case "$input" in
        [0-9])
            if [[ "$input" == "$rand_int" ]]; then
                ((win+=1))
                number_string="${GREEN}${rand_int}${RESET}"
                echo "Hit! My number: $rand_int"
            else
                ((lose+=1))
                number_string="${RED}${rand_int}${RESET}"
                echo "Miss! My number: $rand_int"
            fi

            numbers+=("$number_string")
            if (( ${#numbers[@]} > 10 )); then
                numbers=("${numbers[@]: -10}")
            fi
            ;;
        q)
            break
            ;;
        *)
            echo "Not valid input"
            echo "Please repeat"
            continue
            ;;
    esac

    ((step_count+=1))

    total=$((win + lose))
    let win_percent=win*100/total
    let lose_percent=100-win_percent
    echo "Hit: ${win_percent}%" "Miss: ${lose_percent}%"

    printf 'Last 10 items: %s\n\n' "${numbers[*]}"
    rand_int=${RANDOM: -1}
done
