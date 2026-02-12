#!/usr/bin/env bash

RUN_LOG="${TOOLKIT_DIR}/run.log"
declare -a LOG_LINES=()
LOG_MAX=200

log_msg() {
    local color="${1:-text}" msg="${2:-}"
    local ts
    ts=$(date +%H:%M:%S)
    LOG_LINES+=("${color}|${ts}|${msg}")
    if (( ${#LOG_LINES[@]} > LOG_MAX )); then
        LOG_LINES=("${LOG_LINES[@]:$(( ${#LOG_LINES[@]} - LOG_MAX ))}")
    fi
}

process_queue() {
    local -a queued=()
    local tid
    for tid in "${ALL_TOOL_IDS[@]}"; do
        local st="${TOOL_STATUS[$tid]:-}"
        if [[ "$st" == "queue_install" || "$st" == "queue_uninstall" ]]; then
            queued+=("$tid")
        fi
    done

    if (( ${#queued[@]} == 0 )); then
        log_msg "yellow" "Nothing in queue."
        return 0
    fi

    log_msg "cyan" "Processing ${#queued[@]} item(s)..."
    log_msg "text_dim" "────────────────────────────────────────"

    for tid in "${queued[@]}"; do
        local name="${TOOL_NAME[$tid]:-$tid}"
        local pkg="${TOOL_PKG[$tid]:-$tid}"
        local st="${TOOL_STATUS[$tid]:-}"

        if [[ "$st" == "queue_install" ]]; then
            TOOL_STATUS["$tid"]="installing"
            log_msg "cyan" "⟳ Installing ${name}..."
            full_draw

            local ok=0
            if declare -f "install_${tid}" &>/dev/null; then
                if "install_${tid}" >> "${RUN_LOG}" 2>&1; then ok=1; fi
            else
                if apt-get install -y "$pkg" >> "${RUN_LOG}" 2>&1; then ok=1; fi
            fi

            if (( ok )); then
                TOOL_STATUS["$tid"]="installed"
                log_msg "green" "✓ ${name} installed."
            else
                TOOL_STATUS["$tid"]="failed"
                log_msg "red" "✗ ${name} install failed."
            fi

        elif [[ "$st" == "queue_uninstall" ]]; then
            TOOL_STATUS["$tid"]="uninstalling"
            log_msg "yellow" "⟳ Removing ${name}..."
            full_draw

            local ok=0
            if declare -f "uninstall_${tid}" &>/dev/null; then
                if "uninstall_${tid}" >> "${RUN_LOG}" 2>&1; then ok=1; fi
            else
                if apt-get remove -y "$pkg" >> "${RUN_LOG}" 2>&1; then ok=1; fi
            fi

            if (( ok )); then
                TOOL_STATUS["$tid"]="not_installed"
                log_msg "green" "✓ ${name} removed."
            else
                TOOL_STATUS["$tid"]="failed"
                log_msg "red" "✗ ${name} removal failed."
            fi
        fi

        log_msg "text_dim" "────────────────────────────────────────"
        full_draw
    done

    log_msg "cyan" "All operations complete."
    return 0
}
