#!/usr/bin/env bash
TERM_COLS=0
TERM_ROWS=0
DRAW_BUFFER=""

declare -A C=(
    [reset]="\033[0m"
    [bold]="\033[1m"
    [dim]="\033[2m"
    [italic]="\033[3m"
    [border]="\033[38;5;75m"
    [border_dim]="\033[38;5;60m"
    [title]="\033[1;38;5;87m"
    [text]="\033[38;5;252m"
    [text_dim]="\033[38;5;242m"
    [highlight]="\033[48;5;75;38;5;16m"
    [highlight_dim]="\033[48;5;238;38;5;255m"
    [green]="\033[38;5;78m"
    [red]="\033[38;5;196m"
    [yellow]="\033[38;5;220m"
    [magenta]="\033[38;5;177m"
    [cyan]="\033[38;5;81m"
    [white]="\033[38;5;255m"
    [bar_bg]="\033[48;5;236;38;5;252m"
    [desc_head]="\033[1;38;5;87m"
    [log_ts]="\033[38;5;245m"
    [pkg]="\033[38;5;245m"
)

declare -A STATUS_ICON=(
    [not_installed]="○"
    [installed]="●"
    [queue_install]="◆"
    [queue_uninstall]="◇"
    [installing]="⟳"
    [uninstalling]="⟳"
    [failed]="✗"
)

declare -A STATUS_COLOR=(
    [not_installed]="text_dim"
    [installed]="green"
    [queue_install]="magenta"
    [queue_uninstall]="yellow"
    [installing]="cyan"
    [uninstalling]="yellow"
    [failed]="red"
)

buf_clear() { DRAW_BUFFER=""; }
buf_add() { DRAW_BUFFER+="$1"; }
buf_flush() { printf '%b' "$DRAW_BUFFER"; DRAW_BUFFER=""; }
move_to() { buf_add "\033[${1};${2}H"; }

print_at() {
    local row="$1" col="$2" max_w="$3" text="$4" attr="${5:-}"
    if (( row < 1 || row > TERM_ROWS || col < 1 || col > TERM_COLS )); then
        return 0
    fi
    local avail=$(( TERM_COLS - col + 1 ))
    if (( avail > max_w )); then avail=$max_w; fi
    if (( avail <= 0 )); then return 0; fi
    move_to "$row" "$col"
    if [[ -n "$attr" ]]; then buf_add "$attr"; fi
    buf_add "${text:0:$avail}"
    if [[ -n "$attr" ]]; then buf_add "${C[reset]}"; fi
}

fill_at() {
    local row="$1" col="$2" width="$3" attr="${4:-}"
    local spaces=""
    printf -v spaces '%*s' "$width" ""
    print_at "$row" "$col" "$width" "$spaces" "$attr"
}

draw_box() {
    local y="$1" x="$2" h="$3" w="$4" title="${5:-}"
    local color="${C[border]}"
    if (( h < 2 || w < 2 )); then return 0; fi

    # Top
    move_to "$y" "$x"
    buf_add "${color}╭"
    local i
    for (( i = 1; i < w - 1; i++ )); do buf_add "─"; done
    buf_add "╮${C[reset]}"

    # Bottom
    move_to "$(( y + h - 1 ))" "$x"
    buf_add "${color}╰"
    for (( i = 1; i < w - 1; i++ )); do buf_add "─"; done
    buf_add "╯${C[reset]}"

    # Sides
    for (( i = 1; i < h - 1; i++ )); do
        move_to "$(( y + i ))" "$x"
        buf_add "${color}│${C[reset]}"
        move_to "$(( y + i ))" "$(( x + w - 1 ))"
        buf_add "${color}│${C[reset]}"
    done

    # Title
    if [[ -n "$title" ]]; then
        local t=" ${title} "
        local tlen=${#t}
        local tx=$(( x + (w - tlen) / 2 ))
        if (( tx < x )); then tx=$(( x + 1 )); fi
        move_to "$y" "$tx"
        buf_add "${C[title]}${t}${C[reset]}"
    fi
}

word_wrap() {
    local text="$1" max_w="$2" arrname="$3"
    local -a lines=()
    local line="" word

    if (( max_w < 1 )); then max_w=1; fi

    for word in $text; do
        if [[ -z "$line" ]]; then
            line="$word"
        elif (( ${#line} + ${#word} + 1 <= max_w )); then
            line+=" $word"
        else
            lines+=("$line")
            line="$word"
        fi
    done
    if [[ -n "$line" ]]; then lines+=("$line"); fi

    eval "$arrname=(\"\${lines[@]:-}\")"
}

update_term_size() {
    TERM_COLS=$(tput cols 2>/dev/null || echo 120)
    TERM_ROWS=$(tput lines 2>/dev/null || echo 40)
    # Safety floor
    if (( TERM_COLS < 40 )); then TERM_COLS=40; fi
    if (( TERM_ROWS < 10 )); then TERM_ROWS=10; fi
}

read_key() {
    local key=""
    IFS= read -rsn1 -t 0.15 key 2>/dev/null || return 1

    if [[ "$key" == $'\x1b' ]]; then
        local seq=""
        IFS= read -rsn2 -t 0.05 seq 2>/dev/null || { echo "escape"; return 0; }
        case "$seq" in
            '[A') echo "up";;
            '[B') echo "down";;
            '[C') echo "right";;
            '[D') echo "left";;
            '[5') read -rsn1 -t 0.05 2>/dev/null; echo "pgup";;
            '[6') read -rsn1 -t 0.05 2>/dev/null; echo "pgdn";;
            *)    echo "unknown";;
        esac
    elif [[ "$key" == "" ]]; then
        echo "enter"
    elif [[ "$key" == " " ]]; then
        echo "space"
    elif [[ "$key" == $'\t' ]]; then
        echo "tab"
    elif [[ "$key" == "q" || "$key" == "Q" ]]; then
        echo "quit"
    elif [[ "$key" == "a" || "$key" == "A" ]]; then
        echo "apply"
    elif [[ "$key" == "c" || "$key" == "C" ]]; then
        echo "clear"
    elif [[ "$key" == "r" || "$key" == "R" ]]; then
        echo "refresh"
    else
        echo "$key"
    fi
    return 0
}
