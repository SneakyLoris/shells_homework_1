#!/usr/bin/env bash

usage() {
    printf 'Использование: %s [--path каталог] [--mask шаблон] [--number число] команда\n' "$0" >&2
    exit 2
}

dir=.
mask='*'
limit=
while [[ $1 == --* ]]; do
    [[ $# -ge 2 && -n $2 ]] || usage
    case $1 in
        --path) dir=$2 ;;
        --mask) mask=$2 ;;
        --number) limit=$2 ;;
        *) usage ;;
    esac
    shift 2
done
[[ $# == 1 && -d $dir && -n $1 ]] || usage

if [[ $1 == */* ]]; then
    worker=$1
else
    worker=$(type -P -- "$1") || usage
fi
[[ -f $worker && -x $worker ]] || usage

if [[ -z $limit ]]; then
    limit=$(nproc 2>/dev/null || sysctl -n hw.logicalcpu) || exit 1
fi
[[ $limit =~ ^[0-9]+$ ]] || usage
limit=${limit#"${limit%%[!0]*}"}
[[ -n $limit ]] || usage

dir=$(CDPATH= cd -- "$dir" && pwd -P) || exit 1
shopt -s nullglob dotglob
files=()
for file in "${dir%/}"/*; do
    [[ -f $file && ! -L $file && ${file##*/} == $mask ]] && files+=("$file")
done
total=${#files[@]}
((total)) || exit 0
if ((${#limit} > ${#total})) || ((limit > total)); then
    limit=$total
fi

queue=$(mktemp -d) || exit 1
trap 'rm -rf -- "$queue"' EXIT
mkfifo "$queue/done" || exit 1
exec 3<>"$queue/done" || exit 1

process() {
    local result=0
    "$worker" "$1" 3>&- || result=$?
    printf '%s\n' "$2" >&3
    return "$result"
}

# В очередь каждый процесс сообщает свой слот, в том числе при ошибке команды.
wait_for_slot() {
    IFS= read -r slot <&3 || exit 1
    wait "${pids[slot]}" || status=1
}

status=0
for ((index = 0; index < total; index++)); do
    if ((index < limit)); then
        slot=$index
    else
        wait_for_slot
    fi
    process "${files[index]}" "$slot" &
    pids[slot]=$!
done
for ((index = 0; index < limit; index++)); do
    wait_for_slot
done
exit "$status"
