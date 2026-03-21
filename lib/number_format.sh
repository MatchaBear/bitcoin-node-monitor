#!/bin/bash

# Locale-independent number formatting helpers.

group_integer_digits() {
    local digits="${1:-0}"
    local grouped=""

    [[ -z "$digits" ]] && digits="0"

    while (( ${#digits} > 3 )); do
        grouped=",${digits: -3}${grouped}"
        digits="${digits:0:${#digits}-3}"
    done

    printf "%s%s" "$digits" "$grouped"
}

format_number() {
    local value="${1:-0}"
    local decimals="${2:-0}"
    local formatted
    local sign=""
    local integer_part
    local fractional_part=""

    if [[ -z "$value" || "$value" == "null" ]]; then
        value="0"
    fi

    if ! formatted=$(printf "%.${decimals}f" "$value" 2>/dev/null); then
        formatted=$(printf "%.${decimals}f" 0)
    fi

    if [[ "$formatted" =~ ^-?0(\.0+)?$ ]]; then
        formatted="${formatted#-}"
    fi

    if [[ "$formatted" == -* ]]; then
        sign="-"
        formatted="${formatted#-}"
    fi

    if [[ "$formatted" == *.* ]]; then
        integer_part="${formatted%%.*}"
        fractional_part=".${formatted#*.}"
    else
        integer_part="$formatted"
    fi

    printf "%s%s%s" "$sign" "$(group_integer_digits "$integer_part")" "$fractional_part"
}

format_integer() {
    format_number "${1:-0}" 0
}

format_number_width() {
    local width="$1"
    local value="$2"
    local decimals="${3:-0}"
    local formatted

    formatted=$(format_number "$value" "$decimals")
    printf "%${width}s" "$formatted"
}
