#!/usr/bin/env bash

declare -a CATEGORIES=()
declare -a ALL_TOOL_IDS=()
declare -A CAT_TOOLS=()
declare -A TOOL_NAME=()
declare -A TOOL_DESC=()
declare -A TOOL_PKG=()
declare -A TOOL_CHECK=()
declare -A TOOL_STATUS=()
declare -A TOOL_CAT=()

register_tool() {
    local id="$1" name="$2" category="$3" pkg="$4" check="$5" desc="$6"

    TOOL_NAME["$id"]="$name"
    TOOL_DESC["$id"]="$desc"
    TOOL_PKG["$id"]="$pkg"
    TOOL_CHECK["$id"]="$check"
    TOOL_STATUS["$id"]="not_installed"
    TOOL_CAT["$id"]="$category"
    ALL_TOOL_IDS+=("$id")

    # Add category if new
    local found=0
    local cat
    for cat in "${CATEGORIES[@]}"; do
        if [[ "$cat" == "$category" ]]; then found=1; break; fi
    done
    if (( found == 0 )); then
        CATEGORIES+=("$category")
    fi

    # Append to category tool list
    local existing="${CAT_TOOLS[$category]:-}"
    if [[ -n "$existing" ]]; then
        CAT_TOOLS["$category"]="${existing} ${id}"
    else
        CAT_TOOLS["$category"]="$id"
    fi
}

load_modules() {
    local mod
    for mod in "${SCRIPT_DIR}"/*.sh; do
        if [[ -f "$mod" ]]; then
            source "$mod"
        fi
    done
}

get_cat_tools() {
    echo "${CAT_TOOLS[$1]:-}"
}

get_cat_tool_count() {
    local tools="${CAT_TOOLS[$1]:-}"
    if [[ -z "$tools" ]]; then echo 0; return; fi
    local -a arr=($tools)
    echo "${#arr[@]}"
}

get_cat_stats() {
    local tools="${CAT_TOOLS[$1]:-}"
    local total=0 installed=0 tid
    for tid in $tools; do
        (( total++ ))
        if [[ "${TOOL_STATUS[$tid]:-}" == "installed" ]]; then
            (( installed++ ))
        fi
    done
    echo "${installed}/${total}"
}

detect_installed() {
    local tid
    for tid in "${ALL_TOOL_IDS[@]}"; do
        local check="${TOOL_CHECK[$tid]:-}"
        local pkg="${TOOL_PKG[$tid]:-}"

        if [[ -n "$check" ]] && command -v "$check" &>/dev/null; then
            TOOL_STATUS["$tid"]="installed"
        elif [[ -n "$pkg" ]] && dpkg -s "$pkg" &>/dev/null 2>&1; then
            TOOL_STATUS["$tid"]="installed"
        fi
    done
}

toggle_tool() {
    local tid="$1"
    local current="${TOOL_STATUS[$tid]:-not_installed}"
    case "$current" in
        not_installed)   TOOL_STATUS["$tid"]="queue_install";;
        installed)       TOOL_STATUS["$tid"]="queue_uninstall";;
        queue_install)   TOOL_STATUS["$tid"]="not_installed";;
        queue_uninstall) TOOL_STATUS["$tid"]="installed";;
        failed)
            if command -v "${TOOL_CHECK[$tid]:-__none__}" &>/dev/null; then
                TOOL_STATUS["$tid"]="installed"
            else
                TOOL_STATUS["$tid"]="not_installed"
            fi
            ;;
    esac
}

count_queued() {
    local qi=0 qu=0 tid
    for tid in "${ALL_TOOL_IDS[@]}"; do
        local st="${TOOL_STATUS[$tid]:-}"
        if [[ "$st" == "queue_install" ]]; then (( qi++ )); fi
        if [[ "$st" == "queue_uninstall" ]]; then (( qu++ )); fi
    done
    echo "$qi $qu"
}

clear_queue() {
    local tid
    for tid in "${ALL_TOOL_IDS[@]}"; do
        local st="${TOOL_STATUS[$tid]:-}"
        if [[ "$st" == "queue_install" ]]; then TOOL_STATUS["$tid"]="not_installed"; fi
        if [[ "$st" == "queue_uninstall" ]]; then TOOL_STATUS["$tid"]="installed"; fi
    done
}
