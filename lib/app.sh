#!/usr/bin/env bash
# CRITICAL: No set -e or set -u in this file or any sourced file.
# read_key returns 1 on timeout (normal), and associative array
# lookups on missing keys return non-zero — both kill set -e scripts.

source "${LIB_DIR}/tui_engine.sh"
source "${LIB_DIR}/registry.sh"
source "${LIB_DIR}/runner.sh"
source "${LIB_DIR}/config.sh"
source "${LIB_DIR}/config_ui.sh"

APP_MODE="tools"  # "tools" or "config"
FOCUS=0
CAT_IDX=0
TOOL_IDX=0
NEEDS_REDRAW=1
IS_PROCESSING=0

declare -A LY

calc_layout() {
    update_term_size
    local w=$TERM_COLS h=$TERM_ROWS

    LY[cat_x]=1
    LY[cat_y]=2
    LY[cat_w]=$(( w / 5 ))
    if (( LY[cat_w] < 24 )); then LY[cat_w]=24; fi

    LY[log_h]=$(( h / 4 ))
    if (( LY[log_h] < 8 )); then LY[log_h]=8; fi

    LY[top_h]=$(( h - LY[log_h] - 1 ))
    if (( LY[top_h] < 5 )); then LY[top_h]=5; fi

    LY[cat_h]=$(( LY[top_h] - 1 ))
    if (( LY[cat_h] < 4 )); then LY[cat_h]=4; fi

    LY[desc_w]=$(( w / 3 ))
    if (( LY[desc_w] < 32 )); then LY[desc_w]=32; fi

    LY[tool_x]=$(( LY[cat_w] + 1 ))
    LY[tool_y]=2
    LY[tool_w]=$(( w - LY[cat_w] - LY[desc_w] ))
    if (( LY[tool_w] < 20 )); then LY[tool_w]=20; fi
    LY[tool_h]=$(( LY[top_h] - 1 ))
    if (( LY[tool_h] < 4 )); then LY[tool_h]=4; fi

    LY[desc_x]=$(( LY[tool_x] + LY[tool_w] ))
    LY[desc_y]=2
    LY[desc_h]=$(( LY[top_h] - 1 ))
    if (( LY[desc_h] < 4 )); then LY[desc_h]=4; fi

    LY[log_x]=1
    LY[log_y]=$(( LY[top_h] + 1 ))
    LY[log_w]=$w
    if (( LY[log_w] < 40 )); then LY[log_w]=40; fi

    LY[bar_y]=$h
    LY[bar_w]=$w

    dbg "Layout: cat=${LY[cat_w]}x${LY[cat_h]} tool=${LY[tool_w]}x${LY[tool_h]} desc=${LY[desc_w]}x${LY[desc_h]} log=${LY[log_w]}x${LY[log_h]}"
}

get_current_tools() {
    local cat="${CATEGORIES[$CAT_IDX]:-}"
    if [[ -z "$cat" ]]; then return; fi
    echo "${CAT_TOOLS[$cat]:-}"
}

get_current_tool_id() {
    local -a t=($(get_current_tools))
    if (( TOOL_IDX < ${#t[@]} )); then
        echo "${t[$TOOL_IDX]}"
    fi
}

get_current_tool_count() {
    local -a t=($(get_current_tools))
    echo "${#t[@]}"
}

# ─── Panel Renderers ──────────────────────────────────────────

draw_title_bar() {
    fill_at 1 1 "$TERM_COLS" "${C[bar_bg]}"
    local tx=$(( (TERM_COLS - ${#APP_TITLE}) / 2 ))
    if (( tx < 1 )); then tx=1; fi
    print_at 1 "$tx" "${#APP_TITLE}" "$APP_TITLE" "${C[title]}${C[bold]}"
}

draw_categories() {
    local x=${LY[cat_x]} y=${LY[cat_y]} h=${LY[cat_h]} w=${LY[cat_w]}
    draw_box "$y" "$x" "$h" "$w" "Categories"

    local i
    for (( i = 0; i < ${#CATEGORIES[@]}; i++ )); do
        local row=$(( y + 2 + i ))
        if (( row >= y + h - 1 )); then break; fi

        local cat="${CATEGORIES[$i]}"
        local stats
        stats=$(get_cat_stats "$cat")

        fill_at "$row" "$(( x + 1 ))" "$(( w - 2 ))" ""

        if (( i == CAT_IDX )); then
            local attr
            if (( FOCUS == 0 )); then
                attr="${C[highlight]}"
            else
                attr="${C[highlight_dim]}"
            fi
            fill_at "$row" "$(( x + 1 ))" "$(( w - 2 ))" "$attr"
            print_at "$row" "$(( x + 2 ))" "$(( w - 4 ))" " ▸ ${cat}" "${attr}${C[bold]}"
            local bx=$(( x + w - ${#stats} - 3 ))
            if (( bx > x + 2 )); then
                print_at "$row" "$bx" "$(( ${#stats} + 1 ))" "$stats" "$attr"
            fi
        else
            print_at "$row" "$(( x + 2 ))" "$(( w - 4 ))" "   ${cat}" "${C[text]}"
            local bx=$(( x + w - ${#stats} - 3 ))
            if (( bx > x + 2 )); then
                print_at "$row" "$bx" "$(( ${#stats} + 1 ))" "$stats" "${C[text_dim]}"
            fi
        fi
    done
}

draw_tools() {
    local x=${LY[tool_x]} y=${LY[tool_y]} h=${LY[tool_h]} w=${LY[tool_w]}
    local cat="${CATEGORIES[$CAT_IDX]:-}"
    draw_box "$y" "$x" "$h" "$w" "Tools ─ ${cat}"

    local -a tools=($(get_current_tools))
    local i
    for (( i = 0; i < ${#tools[@]}; i++ )); do
        local row=$(( y + 2 + i ))
        if (( row >= y + h - 1 )); then break; fi

        local tid="${tools[$i]}"
        local name="${TOOL_NAME[$tid]:-$tid}"
        local status="${TOOL_STATUS[$tid]:-not_installed}"
        local icon="${STATUS_ICON[$status]:-?}"
        local scolor="${STATUS_COLOR[$status]:-text}"
        local tag="${status//_/ }"

        fill_at "$row" "$(( x + 1 ))" "$(( w - 2 ))" ""

        if (( i == TOOL_IDX && FOCUS == 1 )); then
            fill_at "$row" "$(( x + 1 ))" "$(( w - 2 ))" "${C[highlight]}"
            print_at "$row" "$(( x + 3 ))" "$(( w - 6 ))" "${icon}  ${name}" "${C[highlight]}${C[bold]}"
            local tx=$(( x + w - ${#tag} - 3 ))
            if (( tx > x + 3 )); then
                print_at "$row" "$tx" "$(( ${#tag} + 1 ))" "$tag" "${C[highlight]}"
            fi
        else
            print_at "$row" "$(( x + 3 ))" 2 "$icon" "${C[$scolor]:-${C[text]}}"
            print_at "$row" "$(( x + 6 ))" "$(( w - 8 ))" "$name" "${C[text]}"
            local tx=$(( x + w - ${#tag} - 3 ))
            if (( tx > x + 3 )); then
                print_at "$row" "$tx" "$(( ${#tag} + 1 ))" "$tag" "${C[$scolor]:-${C[text]}}"
            fi
        fi
    done
}

draw_description() {
    local x=${LY[desc_x]} y=${LY[desc_y]} h=${LY[desc_h]} w=${LY[desc_w]}
    draw_box "$y" "$x" "$h" "$w" "Description"

    local tid
    tid=$(get_current_tool_id)
    if [[ -z "$tid" ]]; then return 0; fi

    local name="${TOOL_NAME[$tid]:-}"
    local desc="${TOOL_DESC[$tid]:-}"
    local pkg="${TOOL_PKG[$tid]:-}"
    local status="${TOOL_STATUS[$tid]:-not_installed}"
    local icon="${STATUS_ICON[$status]:-?}"
    local scolor="${STATUS_COLOR[$status]:-text}"
    local stxt="${status//_/ }"
    local inner=$(( w - 6 ))
    if (( inner < 10 )); then inner=10; fi
    local row=$(( y + 2 ))

    print_at "$row" "$(( x + 3 ))" "$inner" "$name" "${C[desc_head]}${C[bold]}"
    (( row++ ))
    print_at "$row" "$(( x + 3 ))" "$inner" "${icon} ${stxt}" "${C[$scolor]:-${C[text]}}"
    (( row++ ))
    print_at "$row" "$(( x + 3 ))" "$inner" "pkg: ${pkg}" "${C[pkg]}"
    (( row += 2 ))

    if [[ -n "$desc" ]]; then
        local -a wrapped=()
        word_wrap "$desc" "$inner" wrapped
        local line
        for line in "${wrapped[@]:-}"; do
            if [[ -z "$line" ]]; then continue; fi
            if (( row >= y + h - 1 )); then break; fi
            print_at "$row" "$(( x + 3 ))" "$inner" "$line" "${C[text]}"
            (( row++ ))
        done
    fi
}

draw_log() {
    local x=${LY[log_x]} y=${LY[log_y]} h=${LY[log_h]} w=${LY[log_w]}
    draw_box "$y" "$x" "$h" "$w" "Status Log"

    local visible=$(( h - 2 ))
    local total=${#LOG_LINES[@]}
    local start=$(( total - visible ))
    if (( start < 0 )); then start=0; fi

    local i row=0
    for (( i = start; i < total && row < visible; i++, row++ )); do
        local entry="${LOG_LINES[$i]}"
        # Parse: color|timestamp|message
        local color="${entry%%|*}"
        local rest="${entry#*|}"
        local ts="${rest%%|*}"
        local msg="${rest#*|}"
        local r=$(( y + 1 + row ))

        fill_at "$r" "$(( x + 1 ))" "$(( w - 2 ))" ""
        print_at "$r" "$(( x + 2 ))" 8 "$ts" "${C[log_ts]}"
        print_at "$r" "$(( x + 11 ))" "$(( w - 13 ))" "$msg" "${C[$color]:-${C[text]}}"
    done
}

draw_status_bar() {
    local y=${LY[bar_y]} w=${LY[bar_w]}
    fill_at "$y" 1 "$w" "${C[bar_bg]}"

    local counts qi qu
    counts=$(count_queued)
    qi="${counts%% *}"
    qu="${counts##* }"

    local left=" ◆ ${qi} install  ◇ ${qu} uninstall"
    if (( IS_PROCESSING )); then left+="  ⟳ Processing..."; fi

    local keys
    if [[ "$APP_MODE" == "config" ]]; then
        keys="  T Tools  ↑↓ Nav  ENTER Edit  S Save  Q Quit  "
    else
        keys="  T Config  ←→ Focus  ↑↓ Nav  SPACE Toggle  A Apply  C Clear  R Refresh  Q Quit  "
    fi

    print_at "$y" 2 "$(( w / 2 ))" "$left" "${C[bar_bg]}"
    local kx=$(( w - ${#keys} ))
    if (( kx < 1 )); then kx=1; fi
    print_at "$y" "$kx" "${#keys}" "$keys" "${C[bar_bg]}"
}

# ─── Full Redraw ──────────────────────────────────────────────

full_draw() {
    buf_clear
    buf_add "\033[2J"

    if [[ "$APP_MODE" == "config" ]]; then
        # Config mode rendering
        draw_config_mode
        buf_flush
    else
        # Tools mode rendering
        draw_title_bar
        draw_categories
        draw_tools
        draw_description
        draw_log
        draw_status_bar
        buf_flush
    fi
}

# ─── Quit Handler ──────────────────────────────────────────────

handle_quit() {
    local counts qi qu
    counts=$(count_queued)
    qi="${counts%% *}"
    qu="${counts##* }"
    if (( qi + qu > 0 )); then
        log_msg "yellow" "⚠ Queued items pending. Q again to quit, A to apply."
        NEEDS_REDRAW=1
        full_draw
        local confirm=""
        confirm=$(read_key 2>/dev/null) || confirm=""
        if [[ "$confirm" == "quit" ]]; then
            return 1
        fi
    else
        return 1
    fi
    return 0
}

# ─── Input Handler ─────────────────────────────────────────────

handle_input() {
    local key=""
    key=$(read_key 2>/dev/null) || return 0  # timeout = no key = keep running

    if [[ -z "$key" ]]; then return 0; fi

    # Route to config mode if active
    if [[ "$APP_MODE" == "config" ]]; then
        handle_config_input "$key"
        return 0
    fi

    # Handle mode toggle
    if [[ "$key" == "t" || "$key" == "T" ]]; then
        APP_MODE="config"
        CONFIG_SCREEN="main"
        CONFIG_SELECTED_IDX=0
        NEEDS_REDRAW=1
        return 0
    fi

    # Tools mode input handling
    case "$key" in
        up)
            if (( FOCUS == 0 )); then
                if (( CAT_IDX > 0 )); then (( CAT_IDX-- )); fi
                TOOL_IDX=0
            else
                if (( TOOL_IDX > 0 )); then (( TOOL_IDX-- )); fi
            fi
            NEEDS_REDRAW=1
            ;;
        down)
            if (( FOCUS == 0 )); then
                local mx=$(( ${#CATEGORIES[@]} - 1 ))
                if (( CAT_IDX < mx )); then (( CAT_IDX++ )); fi
                TOOL_IDX=0
            else
                local mx=$(( $(get_current_tool_count) - 1 ))
                if (( TOOL_IDX < mx )); then (( TOOL_IDX++ )); fi
            fi
            NEEDS_REDRAW=1
            ;;
        left)
            FOCUS=0
            NEEDS_REDRAW=1
            ;;
        right|tab)
            FOCUS=1
            NEEDS_REDRAW=1
            ;;
        space)
            if (( FOCUS == 1 && ! IS_PROCESSING )); then
                local tid
                tid=$(get_current_tool_id)
                if [[ -n "$tid" ]]; then
                    toggle_tool "$tid"
                    local nm="${TOOL_NAME[$tid]:-$tid}"
                    local st="${TOOL_STATUS[$tid]:-}"
                    case "$st" in
                        queue_install)   log_msg "magenta" "◆ Queued ${nm} for install";;
                        queue_uninstall) log_msg "yellow"  "◇ Queued ${nm} for removal";;
                        not_installed)   log_msg "text_dim" "○ Dequeued ${nm}";;
                        installed)       log_msg "text_dim" "● Dequeued ${nm}";;
                    esac
                    NEEDS_REDRAW=1
                fi
            fi
            ;;
        apply)
            if (( ! IS_PROCESSING )); then
                IS_PROCESSING=1
                NEEDS_REDRAW=1
                full_draw
                process_queue
                IS_PROCESSING=0
                NEEDS_REDRAW=1
            fi
            ;;
        clear)
            if (( ! IS_PROCESSING )); then
                clear_queue
                log_msg "text_dim" "Queue cleared."
                NEEDS_REDRAW=1
            fi
            ;;
        refresh)
            log_msg "cyan" "Re-detecting installed tools..."
            detect_installed
            log_msg "cyan" "Detection complete."
            NEEDS_REDRAW=1
            ;;
        quit)
            handle_quit && return 0 || return 1
            ;;
        unknown|escape)
            # Ignore unknown keys
            ;;
    esac
    return 0
}

# ─── Main Loop ─────────────────────────────────────────────────

run_app() {
    dbg "run_app: entering"

    # Switch to alternate screen buffer
    tput smcup 2>/dev/null
    dbg "run_app: smcup done"

    # Hide cursor
    tput civis 2>/dev/null
    dbg "run_app: civis done"

    # Raw terminal mode
    stty -echo -icanon min 0 time 1 2>/dev/null
    dbg "run_app: stty done"

    log_msg "cyan" "◈ PopOS Security Toolkit starting..."
    log_msg "text_dim" "Loading tool modules..."

    # Initialize configuration system
    config_init
    config_load
    dbg "run_app: config system initialized"

    load_modules
    dbg "run_app: modules loaded (${#ALL_TOOL_IDS[@]} tools, ${#CATEGORIES[@]} categories)"

    log_msg "text_dim" "Found ${#ALL_TOOL_IDS[@]} tools in ${#CATEGORIES[@]} categories."
    log_msg "cyan" "Detecting installed packages..."

    detect_installed
    dbg "run_app: detection complete"

    local inst=0 tid
    for tid in "${ALL_TOOL_IDS[@]}"; do
        if [[ "${TOOL_STATUS[$tid]:-}" == "installed" ]]; then (( inst++ )); fi
    done
    log_msg "green" "● ${inst} tool(s) already installed."
    log_msg "text_dim" "────────────────────────────────────────"
    log_msg "text" "←→ panels  ↑↓ navigate  SPACE toggle  A apply  C clear  Q quit"

    calc_layout
    dbg "run_app: layout calculated, entering draw"

    full_draw
    dbg "run_app: first draw complete, entering main loop"

    while true; do
        local input_result=0
        handle_input || input_result=$?
        if (( input_result == 1 )); then
            dbg "run_app: quit requested"
            break
        fi

        # Check for resize
        local nc nr
        nc=$(tput cols 2>/dev/null || echo "$TERM_COLS")
        nr=$(tput lines 2>/dev/null || echo "$TERM_ROWS")
        if (( nc != TERM_COLS || nr != TERM_ROWS )); then
            calc_layout
            NEEDS_REDRAW=1
        fi

        if (( NEEDS_REDRAW )); then
            full_draw
            NEEDS_REDRAW=0
        fi
    done

    dbg "run_app: exited main loop"
}
