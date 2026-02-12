#!/usr/bin/env bash
# lib/config_ui.sh - Configuration UI components

# Config UI state
CONFIG_SCREEN="main"  # main, git, github, gh
CONFIG_SELECTED_IDX=0
CONFIG_EDITING_FIELD=""
CONFIG_EDIT_VALUE=""
CONFIG_EDIT_CURSOR=0
CONFIG_MODIFIED=0

# draw_config_mode - Main router for config screen rendering
draw_config_mode() {
    case "$CONFIG_SCREEN" in
        main)
            draw_config_main
            ;;
        git)
            draw_config_git
            ;;
        github)
            draw_config_github
            ;;
        gh)
            draw_config_gh
            ;;
        *)
            draw_config_main
            ;;
    esac
}

# draw_config_main - Main configuration menu
draw_config_main() {
    local row=2
    local col=2
    local width=$((TERM_COLS - 4))
    local height=$((TERM_ROWS - 4))

    # Draw title
    buf_add "$(tput cup $row $col)"
    buf_add "${C[cyan]}╔$(printf '═%.0s' $(seq 1 $((width - 2))))╗${C[reset]}"
    ((row++))

    buf_add "$(tput cup $row $col)"
    local title="Configuration Menu"
    local padding=$(( (width - ${#title} - 2) / 2 ))
    buf_add "${C[cyan]}║${C[reset]}$(printf ' %.0s' $(seq 1 $padding))"
    buf_add "${C[bold]}${C[white]}$title${C[reset]}"
    buf_add "$(printf ' %.0s' $(seq 1 $((width - ${#title} - padding - 2))))"
    buf_add "${C[cyan]}║${C[reset]}"
    ((row++))

    buf_add "$(tput cup $row $col)"
    buf_add "${C[cyan]}╠$(printf '═%.0s' $(seq 1 $((width - 2))))╣${C[reset]}"
    ((row++))

    # Configuration options
    local options=(
        "GitHub CLI Configuration"
    )
    local descriptions=(
        "Authenticate gh and set git protocol"
    )

    local i=0
    for option in "${options[@]}"; do
        buf_add "$(tput cup $row $col)"
        buf_add "${C[cyan]}║${C[reset]} "

        if [[ $i -eq $CONFIG_SELECTED_IDX ]]; then
            buf_add "${C[highlight]}${C[white]} ▶ $option "
            local padding_len=$((width - ${#option} - 6))
            buf_add "$(printf ' %.0s' $(seq 1 $padding_len))"
            buf_add "${C[reset]}"
        else
            buf_add "   $option"
            local padding_len=$((width - ${#option} - 5))
            buf_add "$(printf ' %.0s' $(seq 1 $padding_len))"
        fi

        buf_add " ${C[cyan]}║${C[reset]}"
        ((row++))

        # Description
        buf_add "$(tput cup $row $col)"
        buf_add "${C[cyan]}║${C[reset]}     ${C[dim]}${descriptions[$i]}${C[reset]}"
        local desc_padding=$((width - ${#descriptions[$i]} - 7))
        buf_add "$(printf ' %.0s' $(seq 1 $desc_padding))"
        buf_add " ${C[cyan]}║${C[reset]}"
        ((row++))

        ((i++))
    done

    # Fill remaining space
    while [[ $row -lt $((TERM_ROWS - 2)) ]]; do
        buf_add "$(tput cup $row $col)"
        buf_add "${C[cyan]}║${C[reset]}$(printf ' %.0s' $(seq 1 $((width - 2))))${C[cyan]}║${C[reset]}"
        ((row++))
    done

    # Bottom border
    buf_add "$(tput cup $row $col)"
    buf_add "${C[cyan]}╚$(printf '═%.0s' $(seq 1 $((width - 2))))╝${C[reset]}"

    # Help text at bottom
    ((row++))
    buf_add "$(tput cup $row $col)"
    buf_add "${C[dim]}↑↓: Navigate  ENTER: Select  T: Return to Tools  Q: Quit${C[reset]}"
}

# draw_config_git - Git configuration screen
draw_config_git() {
    local row=2
    local col=2
    local width=$((TERM_COLS - 4))
    local height=$((TERM_ROWS - 4))

    # Draw title
    buf_add "$(tput cup $row $col)"
    buf_add "${C[cyan]}╔$(printf '═%.0s' $(seq 1 $((width - 2))))╗${C[reset]}"
    ((row++))

    buf_add "$(tput cup $row $col)"
    local title="Git Configuration"
    local padding=$(( (width - ${#title} - 2) / 2 ))
    buf_add "${C[cyan]}║${C[reset]}$(printf ' %.0s' $(seq 1 $padding))"
    buf_add "${C[bold]}${C[white]}$title${C[reset]}"
    buf_add "$(printf ' %.0s' $(seq 1 $((width - ${#title} - padding - 2))))"
    buf_add "${C[cyan]}║${C[reset]}"
    ((row++))

    buf_add "$(tput cup $row $col)"
    buf_add "${C[cyan]}╠$(printf '═%.0s' $(seq 1 $((width - 2))))╣${C[reset]}"
    ((row++))

    # Get current values
    local user_name
    local user_email
    user_name=$(config_get "git" "user_name")
    user_email=$(config_get "git" "user_email")

    # Field labels and values
    local fields=("user_name" "user_email")
    local labels=("User Name:" "User Email:")
    local values=("$user_name" "$user_email")

    local i=0
    for field in "${fields[@]}"; do
        buf_add "$(tput cup $row $col)"
        buf_add "${C[cyan]}║${C[reset]} "

        local is_selected=0
        [[ $i -eq $CONFIG_SELECTED_IDX ]] && is_selected=1

        # Label
        if [[ $is_selected -eq 1 ]]; then
            buf_add "${C[yellow]}▶ ${labels[$i]}${C[reset]}"
        else
            buf_add "  ${labels[$i]}"
        fi

        local label_len=${#labels[$i]}
        local padding_after_label=$((20 - label_len - 2))
        buf_add "$(printf ' %.0s' $(seq 1 $padding_after_label))"

        # Value field
        local display_value="${values[$i]}"
        if [[ "$CONFIG_EDITING_FIELD" == "$field" ]]; then
            # Show edit value with cursor
            display_value="$CONFIG_EDIT_VALUE"
            buf_add "${C[highlight]}${C[white]}"
            buf_add "$display_value"
            buf_add "█"  # Cursor
            local value_padding=$((width - 25 - ${#display_value} - 1))
            buf_add "$(printf ' %.0s' $(seq 1 $value_padding))"
            buf_add "${C[reset]}"
        else
            # Show current value
            if [[ -z "$display_value" ]]; then
                display_value="${C[dim]}(not set)${C[reset]}"
                buf_add "$display_value"
                local value_padding=$((width - 25 - 9))
                buf_add "$(printf ' %.0s' $(seq 1 $value_padding))"
            else
                buf_add "$display_value"
                local value_padding=$((width - 25 - ${#display_value}))
                buf_add "$(printf ' %.0s' $(seq 1 $value_padding))"
            fi
        fi

        buf_add " ${C[cyan]}║${C[reset]}"
        ((row++))
        ((i++))
    done

    # Empty line
    buf_add "$(tput cup $row $col)"
    buf_add "${C[cyan]}║${C[reset]}$(printf ' %.0s' $(seq 1 $((width - 2))))${C[cyan]}║${C[reset]}"
    ((row++))

    # Info about what will happen
    buf_add "$(tput cup $row $col)"
    buf_add "${C[cyan]}║${C[reset]} ${C[dim]}Changes will be applied to git config --global${C[reset]}"
    local info_padding=$((width - 47))
    buf_add "$(printf ' %.0s' $(seq 1 $info_padding))"
    buf_add "${C[cyan]}║${C[reset]}"
    ((row++))

    # Fill remaining space
    while [[ $row -lt $((TERM_ROWS - 2)) ]]; do
        buf_add "$(tput cup $row $col)"
        buf_add "${C[cyan]}║${C[reset]}$(printf ' %.0s' $(seq 1 $((width - 2))))${C[cyan]}║${C[reset]}"
        ((row++))
    done

    # Bottom border
    buf_add "$(tput cup $row $col)"
    buf_add "${C[cyan]}╚$(printf '═%.0s' $(seq 1 $((width - 2))))╝${C[reset]}"

    # Help text
    ((row++))
    buf_add "$(tput cup $row $col)"
    if [[ -n "$CONFIG_EDITING_FIELD" ]]; then
        buf_add "${C[dim]}Type to edit  ENTER: Save  ESC: Cancel${C[reset]}"
    else
        buf_add "${C[dim]}↑↓: Navigate  ENTER: Edit  S: Save & Apply  ESC: Back  Q: Quit${C[reset]}"
    fi
}

# draw_config_github - GitHub configuration screen
draw_config_github() {
    local row=2
    local col=2
    local width=$((TERM_COLS - 4))
    local height=$((TERM_ROWS - 4))

    # Draw title
    buf_add "$(tput cup $row $col)"
    buf_add "${C[cyan]}╔$(printf '═%.0s' $(seq 1 $((width - 2))))╗${C[reset]}"
    ((row++))

    buf_add "$(tput cup $row $col)"
    local title="GitHub Configuration"
    local padding=$(( (width - ${#title} - 2) / 2 ))
    buf_add "${C[cyan]}║${C[reset]}$(printf ' %.0s' $(seq 1 $padding))"
    buf_add "${C[bold]}${C[white]}$title${C[reset]}"
    buf_add "$(printf ' %.0s' $(seq 1 $((width - ${#title} - padding - 2))))"
    buf_add "${C[cyan]}║${C[reset]}"
    ((row++))

    buf_add "$(tput cup $row $col)"
    buf_add "${C[cyan]}╠$(printf '═%.0s' $(seq 1 $((width - 2))))╣${C[reset]}"
    ((row++))

    # Get current values
    local ssh_key_path
    local token
    ssh_key_path=$(config_get "github" "ssh_key_path")
    token=$(config_get "github" "token")

    # Field labels and values
    local fields=("ssh_key_path" "token")
    local labels=("SSH Key Path:" "GitHub Token:")
    local values=("$ssh_key_path" "$token")

    local i=0
    for field in "${fields[@]}"; do
        buf_add "$(tput cup $row $col)"
        buf_add "${C[cyan]}║${C[reset]} "

        local is_selected=0
        [[ $i -eq $CONFIG_SELECTED_IDX ]] && is_selected=1

        # Label
        if [[ $is_selected -eq 1 ]]; then
            buf_add "${C[yellow]}▶ ${labels[$i]}${C[reset]}"
        else
            buf_add "  ${labels[$i]}"
        fi

        local label_len=${#labels[$i]}
        local padding_after_label=$((20 - label_len - 2))
        buf_add "$(printf ' %.0s' $(seq 1 $padding_after_label))"

        # Value field
        local display_value="${values[$i]}"

        if [[ "$CONFIG_EDITING_FIELD" == "$field" ]]; then
            # Show edit value with cursor
            display_value="$CONFIG_EDIT_VALUE"
            if [[ "$field" == "token" ]]; then
                # Mask token while editing (show last 4 chars)
                local masked=""
                if [[ ${#display_value} -gt 4 ]]; then
                    masked="$(printf '*%.0s' $(seq 1 $((${#display_value} - 4))))${display_value: -4}"
                else
                    masked="$display_value"
                fi
                buf_add "${C[highlight]}${C[white]}"
                buf_add "$masked"
                buf_add "█"  # Cursor
                local value_padding=$((width - 25 - ${#masked} - 1))
                buf_add "$(printf ' %.0s' $(seq 1 $value_padding))"
                buf_add "${C[reset]}"
            else
                buf_add "${C[highlight]}${C[white]}"
                buf_add "$display_value"
                buf_add "█"  # Cursor
                local value_padding=$((width - 25 - ${#display_value} - 1))
                buf_add "$(printf ' %.0s' $(seq 1 $value_padding))"
                buf_add "${C[reset]}"
            fi
        else
            # Show current value
            if [[ -z "$display_value" ]]; then
                display_value="${C[dim]}(not set)${C[reset]}"
                buf_add "$display_value"
                local value_padding=$((width - 25 - 9))
                buf_add "$(printf ' %.0s' $(seq 1 $value_padding))"
            else
                # Mask token
                if [[ "$field" == "token" ]]; then
                    local masked="••••••••••••"
                    buf_add "$masked"
                    local value_padding=$((width - 25 - ${#masked}))
                else
                    buf_add "$display_value"
                    local value_padding=$((width - 25 - ${#display_value}))
                fi
                buf_add "$(printf ' %.0s' $(seq 1 $value_padding))"
            fi
        fi

        buf_add " ${C[cyan]}║${C[reset]}"
        ((row++))

        # Extra action for SSH key
        if [[ "$field" == "ssh_key_path" && $is_selected -eq 1 && -z "$CONFIG_EDITING_FIELD" ]]; then
            buf_add "$(tput cup $row $col)"
            buf_add "${C[cyan]}║${C[reset]}     ${C[dim]}Press G to generate new SSH key${C[reset]}"
            local hint_padding=$((width - 36))
            buf_add "$(printf ' %.0s' $(seq 1 $hint_padding))"
            buf_add "${C[cyan]}║${C[reset]}"
            ((row++))
        fi

        ((i++))
    done

    # Empty line
    buf_add "$(tput cup $row $col)"
    buf_add "${C[cyan]}║${C[reset]}$(printf ' %.0s' $(seq 1 $((width - 2))))${C[cyan]}║${C[reset]}"
    ((row++))

    # Show public key if available
    if [[ -n "$ssh_key_path" && -f "${ssh_key_path}.pub" ]]; then
        buf_add "$(tput cup $row $col)"
        buf_add "${C[cyan]}║${C[reset]} ${C[green]}SSH Public Key:${C[reset]}"
        local pubkey_padding=$((width - 18))
        buf_add "$(printf ' %.0s' $(seq 1 $pubkey_padding))"
        buf_add "${C[cyan]}║${C[reset]}"
        ((row++))

        local pubkey
        pubkey=$(cat "${ssh_key_path}.pub" 2>/dev/null)
        # Truncate if too long
        if [[ ${#pubkey} -gt $((width - 4)) ]]; then
            pubkey="${pubkey:0:$((width - 7))}..."
        fi
        buf_add "$(tput cup $row $col)"
        buf_add "${C[cyan]}║${C[reset]} ${C[dim]}$pubkey${C[reset]}"
        local pubkey_padding=$((width - ${#pubkey} - 3))
        buf_add "$(printf ' %.0s' $(seq 1 $pubkey_padding))"
        buf_add "${C[cyan]}║${C[reset]}"
        ((row++))
    fi

    # Fill remaining space
    while [[ $row -lt $((TERM_ROWS - 2)) ]]; do
        buf_add "$(tput cup $row $col)"
        buf_add "${C[cyan]}║${C[reset]}$(printf ' %.0s' $(seq 1 $((width - 2))))${C[cyan]}║${C[reset]}"
        ((row++))
    done

    # Bottom border
    buf_add "$(tput cup $row $col)"
    buf_add "${C[cyan]}╚$(printf '═%.0s' $(seq 1 $((width - 2))))╝${C[reset]}"

    # Help text
    ((row++))
    buf_add "$(tput cup $row $col)"
    if [[ -n "$CONFIG_EDITING_FIELD" ]]; then
        buf_add "${C[dim]}Type to edit  ENTER: Save  ESC: Cancel${C[reset]}"
    else
        buf_add "${C[dim]}↑↓: Navigate  ENTER: Edit  G: Generate Key  S: Save  ESC: Back  Q: Quit${C[reset]}"
    fi
}

# draw_config_gh - GitHub CLI configuration screen
draw_config_gh() {
    local row=2
    local col=2
    local width=$((TERM_COLS - 4))
    local height=$((TERM_ROWS - 4))

    # Draw title
    buf_add "$(tput cup $row $col)"
    buf_add "${C[cyan]}╔$(printf '═%.0s' $(seq 1 $((width - 2))))╗${C[reset]}"
    ((row++))

    buf_add "$(tput cup $row $col)"
    local title="GitHub CLI Configuration"
    local padding=$(( (width - ${#title} - 2) / 2 ))
    buf_add "${C[cyan]}║${C[reset]}$(printf ' %.0s' $(seq 1 $padding))"
    buf_add "${C[bold]}${C[white]}$title${C[reset]}"
    buf_add "$(printf ' %.0s' $(seq 1 $((width - ${#title} - padding - 2))))"
    buf_add "${C[cyan]}║${C[reset]}"
    ((row++))

    buf_add "$(tput cup $row $col)"
    buf_add "${C[cyan]}╠$(printf '═%.0s' $(seq 1 $((width - 2))))╣${C[reset]}"
    ((row++))

    # Check gh authentication status
    local auth_status="Not Authenticated"
    local auth_color="${C[red]}"
    if command -v gh &>/dev/null; then
        if gh auth status &>/dev/null; then
            auth_status="Authenticated"
            auth_color="${C[green]}"
        fi
    else
        auth_status="gh not installed"
        auth_color="${C[yellow]}"
    fi

    # Get current git protocol
    local git_protocol
    git_protocol=$(config_get "gh" "git_protocol")
    if [[ -z "$git_protocol" ]]; then
        git_protocol="https"
    fi

    # Field labels and values
    local fields=("auth_status" "git_protocol")
    local labels=("Auth Status:" "Git Protocol:")
    local values=("$auth_status" "$git_protocol")

    local i=0
    for field in "${fields[@]}"; do
        buf_add "$(tput cup $row $col)"
        buf_add "${C[cyan]}║${C[reset]} "

        local is_selected=0
        [[ $i -eq $CONFIG_SELECTED_IDX ]] && is_selected=1

        # Label
        if [[ $is_selected -eq 1 ]]; then
            buf_add "${C[yellow]}▶ ${labels[$i]}${C[reset]}"
        else
            buf_add "  ${labels[$i]}"
        fi

        local label_len=${#labels[$i]}
        local padding_after_label=$((20 - label_len - 2))
        buf_add "$(printf ' %.0s' $(seq 1 $padding_after_label))"

        # Value display
        if [[ "$field" == "auth_status" ]]; then
            buf_add "${auth_color}${values[$i]}${C[reset]}"
            local value_padding=$((width - 25 - ${#values[$i]}))
            buf_add "$(printf ' %.0s' $(seq 1 $value_padding))"
        elif [[ "$field" == "git_protocol" ]]; then
            if [[ "$is_selected" -eq 1 ]]; then
                buf_add "${C[highlight]}${C[white]} ${values[$i]} ${C[reset]}"
                local value_padding=$((width - 25 - ${#values[$i]} - 2))
            else
                buf_add "${values[$i]}"
                local value_padding=$((width - 25 - ${#values[$i]}))
            fi
            buf_add "$(printf ' %.0s' $(seq 1 $value_padding))"
        fi

        buf_add " ${C[cyan]}║${C[reset]}"
        ((row++))

        # Extra hints
        if [[ $is_selected -eq 1 ]]; then
            buf_add "$(tput cup $row $col)"
            if [[ "$field" == "auth_status" ]]; then
                if [[ "$auth_status" == "Not Authenticated" ]]; then
                    buf_add "${C[cyan]}║${C[reset]}     ${C[dim]}Press A to authenticate with GitHub${C[reset]}"
                    local hint_padding=$((width - 41))
                else
                    buf_add "${C[cyan]}║${C[reset]}     ${C[dim]}Press L to logout${C[reset]}"
                    local hint_padding=$((width - 21))
                fi
            elif [[ "$field" == "git_protocol" ]]; then
                buf_add "${C[cyan]}║${C[reset]}     ${C[dim]}Press ENTER to toggle (https/ssh)${C[reset]}"
                local hint_padding=$((width - 40))
            fi
            buf_add "$(printf ' %.0s' $(seq 1 $hint_padding))"
            buf_add "${C[cyan]}║${C[reset]}"
            ((row++))
        fi

        ((i++))
    done

    # Empty line
    buf_add "$(tput cup $row $col)"
    buf_add "${C[cyan]}║${C[reset]}$(printf ' %.0s' $(seq 1 $((width - 2))))${C[cyan]}║${C[reset]}"
    ((row++))

    # Info text
    buf_add "$(tput cup $row $col)"
    buf_add "${C[cyan]}║${C[reset]} ${C[dim]}GitHub CLI must be installed to use this feature${C[reset]}"
    local info_padding=$((width - 51))
    buf_add "$(printf ' %.0s' $(seq 1 $info_padding))"
    buf_add "${C[cyan]}║${C[reset]}"
    ((row++))

    # Fill remaining space
    while [[ $row -lt $((TERM_ROWS - 2)) ]]; do
        buf_add "$(tput cup $row $col)"
        buf_add "${C[cyan]}║${C[reset]}$(printf ' %.0s' $(seq 1 $((width - 2))))${C[cyan]}║${C[reset]}"
        ((row++))
    done

    # Bottom border
    buf_add "$(tput cup $row $col)"
    buf_add "${C[cyan]}╚$(printf '═%.0s' $(seq 1 $((width - 2))))╝${C[reset]}"

    # Help text
    ((row++))
    buf_add "$(tput cup $row $col)"
    buf_add "${C[dim]}↑↓: Navigate  A: Authenticate  L: Logout  ENTER: Toggle Protocol  ESC: Back  Q: Quit${C[reset]}"
}

# handle_config_input - Route keyboard input in config mode
handle_config_input() {
    local key="$1"

    # If editing a field, handle edit mode input
    if [[ -n "$CONFIG_EDITING_FIELD" ]]; then
        handle_config_edit "$key"
        return
    fi

    # Normal navigation mode
    case "$key" in
        "up")
            if [[ $CONFIG_SELECTED_IDX -gt 0 ]]; then
                ((CONFIG_SELECTED_IDX--))
                NEEDS_REDRAW=1
            fi
            ;;
        "down")
            local max_idx
            case "$CONFIG_SCREEN" in
                main) max_idx=0 ;;
                git) max_idx=1 ;;
                github) max_idx=1 ;;
                gh) max_idx=1 ;;
                *) max_idx=0 ;;
            esac
            if [[ $CONFIG_SELECTED_IDX -lt $max_idx ]]; then
                ((CONFIG_SELECTED_IDX++))
                NEEDS_REDRAW=1
            fi
            ;;
        "enter")
            handle_config_select
            ;;
        "escape")
            handle_config_back
            ;;
        "s"|"S")
            handle_config_save
            ;;
        "g"|"G")
            handle_config_generate_key
            ;;
        "a"|"A")
            handle_config_gh_auth
            ;;
        "l"|"L")
            handle_config_gh_logout
            ;;
        "t"|"T")
            # Toggle back to tools mode
            APP_MODE="tools"
            NEEDS_REDRAW=1
            ;;
        "q"|"Q")
            handle_quit
            ;;
    esac
}

# handle_config_select - Handle ENTER key in config navigation
handle_config_select() {
    case "$CONFIG_SCREEN" in
        main)
            case $CONFIG_SELECTED_IDX in
                0)
                    CONFIG_SCREEN="gh"
                    CONFIG_SELECTED_IDX=0
                    NEEDS_REDRAW=1
                    ;;
            esac
            ;;
        git)
            case $CONFIG_SELECTED_IDX in
                0)
                    # Edit user_name
                    CONFIG_EDITING_FIELD="user_name"
                    CONFIG_EDIT_VALUE=$(config_get "git" "user_name")
                    CONFIG_EDIT_CURSOR=${#CONFIG_EDIT_VALUE}
                    NEEDS_REDRAW=1
                    ;;
                1)
                    # Edit user_email
                    CONFIG_EDITING_FIELD="user_email"
                    CONFIG_EDIT_VALUE=$(config_get "git" "user_email")
                    CONFIG_EDIT_CURSOR=${#CONFIG_EDIT_VALUE}
                    NEEDS_REDRAW=1
                    ;;
            esac
            ;;
        github)
            case $CONFIG_SELECTED_IDX in
                0)
                    # Edit ssh_key_path
                    CONFIG_EDITING_FIELD="ssh_key_path"
                    CONFIG_EDIT_VALUE=$(config_get "github" "ssh_key_path")
                    CONFIG_EDIT_CURSOR=${#CONFIG_EDIT_VALUE}
                    NEEDS_REDRAW=1
                    ;;
                1)
                    # Edit token
                    CONFIG_EDITING_FIELD="token"
                    CONFIG_EDIT_VALUE=$(config_get "github" "token")
                    CONFIG_EDIT_CURSOR=${#CONFIG_EDIT_VALUE}
                    NEEDS_REDRAW=1
                    ;;
            esac
            ;;
        gh)
            case $CONFIG_SELECTED_IDX in
                0)
                    # Auth status - do nothing on enter, use A or L keys
                    ;;
                1)
                    # Toggle git protocol
                    local current_protocol
                    current_protocol=$(config_get "gh" "git_protocol")
                    if [[ "$current_protocol" == "https" || -z "$current_protocol" ]]; then
                        config_set "gh" "git_protocol" "ssh"
                    else
                        config_set "gh" "git_protocol" "https"
                    fi
                    CONFIG_MODIFIED=1
                    NEEDS_REDRAW=1
                    ;;
            esac
            ;;
    esac
}

# handle_config_back - Handle ESC key
handle_config_back() {
    case "$CONFIG_SCREEN" in
        main)
            # Return to tools mode
            APP_MODE="tools"
            NEEDS_REDRAW=1
            ;;
        *)
            # Return to main config menu
            CONFIG_SCREEN="main"
            CONFIG_SELECTED_IDX=0
            NEEDS_REDRAW=1
            ;;
    esac
}

# handle_config_save - Save configuration
handle_config_save() {
    config_save
    CONFIG_MODIFIED=0

    # Apply git config if on git screen
    if [[ "$CONFIG_SCREEN" == "git" ]]; then
        config_apply_git
    fi

    # Apply gh git protocol if on gh screen
    if [[ "$CONFIG_SCREEN" == "gh" ]]; then
        local protocol
        protocol=$(config_get "gh" "git_protocol")
        if command -v gh &>/dev/null && [[ -n "$protocol" ]]; then
            gh config set git_protocol "$protocol" 2>/dev/null || true
        fi
    fi

    NEEDS_REDRAW=1
}

# handle_config_generate_key - Generate SSH key
handle_config_generate_key() {
    if [[ "$CONFIG_SCREEN" != "github" || $CONFIG_SELECTED_IDX -ne 0 ]]; then
        return
    fi

    local default_path="${HOME}/.ssh/id_ed25519"
    local key_path
    key_path=$(config_get "github" "ssh_key_path")

    if [[ -z "$key_path" ]]; then
        key_path="$default_path"
    fi

    if config_generate_ssh_key "$key_path"; then
        CONFIG_MODIFIED=1
        NEEDS_REDRAW=1
    fi
}

# handle_config_gh_auth - Authenticate with GitHub CLI
handle_config_gh_auth() {
    if [[ "$CONFIG_SCREEN" != "gh" || $CONFIG_SELECTED_IDX -ne 0 ]]; then
        return
    fi

    if ! command -v gh &>/dev/null; then
        return
    fi

    # Exit TUI temporarily
    tput rmcup 2>/dev/null
    tput cnorm 2>/dev/null
    stty sane 2>/dev/null
    clear

    echo ""
    echo "Authenticating with GitHub CLI..."
    echo ""

    # Run gh auth login interactively
    gh auth login

    # Apply git protocol preference if set
    local protocol
    protocol=$(config_get "gh" "git_protocol")
    if [[ -n "$protocol" ]]; then
        gh config set git_protocol "$protocol" 2>/dev/null || true
    fi

    echo ""
    echo "Press ENTER to return to the toolkit..."
    read -r

    # Restore TUI
    tput smcup 2>/dev/null
    tput civis 2>/dev/null
    stty -echo 2>/dev/null

    CONFIG_MODIFIED=1
    NEEDS_REDRAW=1
}

# handle_config_gh_logout - Logout from GitHub CLI
handle_config_gh_logout() {
    if [[ "$CONFIG_SCREEN" != "gh" || $CONFIG_SELECTED_IDX -ne 0 ]]; then
        return
    fi

    if ! command -v gh &>/dev/null; then
        return
    fi

    # Check if authenticated first
    if ! gh auth status &>/dev/null; then
        return
    fi

    # Exit TUI temporarily
    tput rmcup 2>/dev/null
    tput cnorm 2>/dev/null
    stty sane 2>/dev/null
    clear

    echo ""
    echo "Logging out from GitHub CLI..."
    echo ""

    gh auth logout --hostname github.com

    echo ""
    echo "Press ENTER to return to the toolkit..."
    read -r

    # Restore TUI
    tput smcup 2>/dev/null
    tput civis 2>/dev/null
    stty -echo 2>/dev/null

    CONFIG_MODIFIED=1
    NEEDS_REDRAW=1
}

# handle_config_edit - Handle text editing
handle_config_edit() {
    local key="$1"

    case "$key" in
        "enter")
            # Save the edited value
            case "$CONFIG_SCREEN" in
                git)
                    case $CONFIG_SELECTED_IDX in
                        0) config_set "git" "user_name" "$CONFIG_EDIT_VALUE" ;;
                        1) config_set "git" "user_email" "$CONFIG_EDIT_VALUE" ;;
                    esac
                    ;;
                github)
                    case $CONFIG_SELECTED_IDX in
                        0) config_set "github" "ssh_key_path" "$CONFIG_EDIT_VALUE" ;;
                        1) config_set "github" "token" "$CONFIG_EDIT_VALUE" ;;
                    esac
                    ;;
            esac
            CONFIG_EDITING_FIELD=""
            CONFIG_EDIT_VALUE=""
            CONFIG_MODIFIED=1
            NEEDS_REDRAW=1
            ;;
        "escape")
            # Cancel editing
            CONFIG_EDITING_FIELD=""
            CONFIG_EDIT_VALUE=""
            NEEDS_REDRAW=1
            ;;
        "backspace")
            # Remove last character
            if [[ ${#CONFIG_EDIT_VALUE} -gt 0 ]]; then
                CONFIG_EDIT_VALUE="${CONFIG_EDIT_VALUE:0:$((${#CONFIG_EDIT_VALUE} - 1))}"
                NEEDS_REDRAW=1
            fi
            ;;
        *)
            # Add character to edit value
            if [[ ${#key} -eq 1 ]]; then
                CONFIG_EDIT_VALUE="${CONFIG_EDIT_VALUE}${key}"
                NEEDS_REDRAW=1
            fi
            ;;
    esac
}
