#!/usr/bin/env bash
# lib/config.sh - Configuration storage and management

# Global configuration state
declare -A CONFIG_VALUES
CONFIG_DIR="${HOME}/.popos-toolkit"
CONFIG_FILE="${CONFIG_DIR}/config"
CONFIG_LOADED=0

# config_init - Initialize configuration directory
config_init() {
    if [[ ! -d "$CONFIG_DIR" ]]; then
        mkdir -p "$CONFIG_DIR" 2>/dev/null || {
            echo "[ERROR] Failed to create config directory: $CONFIG_DIR" >> "${DEBUG_LOG}"
            return 1
        }
        chmod 700 "$CONFIG_DIR" 2>/dev/null
        echo "[INFO] Created config directory: $CONFIG_DIR" >> "${DEBUG_LOG}"
    fi

    # Create empty config file if it doesn't exist
    if [[ ! -f "$CONFIG_FILE" ]]; then
        cat > "$CONFIG_FILE" <<'EOF'
# PopOS Security Toolkit Configuration

[git]
user_name=
user_email=

[github]
token=
ssh_key_path=

[toolkit]
config_version=1.0
EOF
        chmod 600 "$CONFIG_FILE" 2>/dev/null
        echo "[INFO] Created config file: $CONFIG_FILE" >> "${DEBUG_LOG}"
    fi

    return 0
}

# config_load - Load configuration from INI file
config_load() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "[WARN] Config file not found: $CONFIG_FILE" >> "${DEBUG_LOG}"
        return 1
    fi

    local section=""
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue

        # Parse section headers
        if [[ "$line" =~ ^\[([^]]+)\] ]]; then
            section="${BASH_REMATCH[1]}"
            continue
        fi

        # Parse key=value pairs
        if [[ "$line" =~ ^([^=]+)=(.*)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            # Trim whitespace
            key="${key#"${key%%[![:space:]]*}"}"
            key="${key%"${key##*[![:space:]]}"}"
            value="${value#"${value%%[![:space:]]*}"}"
            value="${value%"${value##*[![:space:]]}"}"

            if [[ -n "$section" ]]; then
                CONFIG_VALUES["${section}_${key}"]="$value"
            fi
        fi
    done < "$CONFIG_FILE"

    CONFIG_LOADED=1
    echo "[INFO] Configuration loaded from: $CONFIG_FILE" >> "${DEBUG_LOG}"
    return 0
}

# config_save - Save configuration to INI file
config_save() {
    # Create backup
    if [[ -f "$CONFIG_FILE" ]]; then
        cp "$CONFIG_FILE" "${CONFIG_FILE}.bak" 2>/dev/null
    fi

    # Write new config
    cat > "$CONFIG_FILE" <<EOF
# PopOS Security Toolkit Configuration

[git]
user_name=${CONFIG_VALUES[git_user_name]:-}
user_email=${CONFIG_VALUES[git_user_email]:-}

[github]
token=${CONFIG_VALUES[github_token]:-}
ssh_key_path=${CONFIG_VALUES[github_ssh_key_path]:-}

[toolkit]
config_version=1.0
EOF

    chmod 600 "$CONFIG_FILE" 2>/dev/null
    echo "[INFO] Configuration saved to: $CONFIG_FILE" >> "${DEBUG_LOG}"
    return 0
}

# config_get - Get configuration value
# Usage: config_get <section> <key>
config_get() {
    local section="$1"
    local key="$2"
    echo "${CONFIG_VALUES[${section}_${key}]:-}"
}

# config_set - Set configuration value
# Usage: config_set <section> <key> <value>
config_set() {
    local section="$1"
    local key="$2"
    local value="$3"
    CONFIG_VALUES["${section}_${key}"]="$value"
    echo "[INFO] Set ${section}_${key}=${value}" >> "${DEBUG_LOG}"
}

# config_apply_git - Apply git configuration
config_apply_git() {
    local name
    local email
    name=$(config_get "git" "user_name")
    email=$(config_get "git" "user_email")

    if [[ -z "$name" && -z "$email" ]]; then
        echo "[WARN] No git configuration to apply" >> "${DEBUG_LOG}"
        return 0
    fi

    if [[ -n "$name" ]]; then
        if git config --global user.name "$name" 2>>"${DEBUG_LOG}"; then
            echo "[INFO] Set git user.name: $name" >> "${DEBUG_LOG}"
        else
            echo "[ERROR] Failed to set git user.name" >> "${DEBUG_LOG}"
            return 1
        fi
    fi

    if [[ -n "$email" ]]; then
        if git config --global user.email "$email" 2>>"${DEBUG_LOG}"; then
            echo "[INFO] Set git user.email: $email" >> "${DEBUG_LOG}"
        else
            echo "[ERROR] Failed to set git user.email" >> "${DEBUG_LOG}"
            return 1
        fi
    fi

    return 0
}

# config_generate_ssh_key - Generate SSH key for GitHub
# Usage: config_generate_ssh_key <key_path>
config_generate_ssh_key() {
    local key_path="$1"

    if [[ -z "$key_path" ]]; then
        key_path="${HOME}/.ssh/id_ed25519"
    fi

    # Check if key already exists
    if [[ -f "$key_path" ]]; then
        echo "[WARN] SSH key already exists: $key_path" >> "${DEBUG_LOG}"
        return 1
    fi

    # Ensure .ssh directory exists
    local ssh_dir
    ssh_dir=$(dirname "$key_path")
    if [[ ! -d "$ssh_dir" ]]; then
        mkdir -p "$ssh_dir" 2>/dev/null || {
            echo "[ERROR] Failed to create SSH directory: $ssh_dir" >> "${DEBUG_LOG}"
            return 1
        }
        chmod 700 "$ssh_dir" 2>/dev/null
    fi

    # Get email for key comment
    local email
    email=$(config_get "git" "user_email")
    if [[ -z "$email" ]]; then
        email="user@popos-toolkit"
    fi

    # Generate key
    echo "[INFO] Generating SSH key: $key_path" >> "${DEBUG_LOG}"
    if ! ssh-keygen -t ed25519 -C "$email" -f "$key_path" -N "" >> "${DEBUG_LOG}" 2>&1; then
        echo "[ERROR] Failed to generate SSH key" >> "${DEBUG_LOG}"
        return 1
    fi

    # Set proper permissions
    chmod 600 "$key_path" 2>/dev/null
    chmod 644 "${key_path}.pub" 2>/dev/null

    # Add to ssh-agent if running
    if command -v ssh-add &>/dev/null && pgrep -u "$USER" ssh-agent >/dev/null 2>&1; then
        ssh-add "$key_path" >> "${DEBUG_LOG}" 2>&1
        echo "[INFO] Added key to ssh-agent" >> "${DEBUG_LOG}"
    fi

    # Update config
    config_set "github" "ssh_key_path" "$key_path"

    echo "[INFO] SSH key generated successfully" >> "${DEBUG_LOG}"
    echo "[INFO] Public key: ${key_path}.pub" >> "${DEBUG_LOG}"
    return 0
}

# config_validate_github_token - Validate GitHub token format
# Usage: config_validate_github_token <token>
config_validate_github_token() {
    local token="$1"

    if [[ -z "$token" ]]; then
        return 1
    fi

    # GitHub personal access tokens start with ghp_ (classic) or github_pat_ (fine-grained)
    if [[ "$token" =~ ^ghp_[a-zA-Z0-9]{36}$ ]] || [[ "$token" =~ ^github_pat_[a-zA-Z0-9_]{82}$ ]]; then
        return 0
    fi

    echo "[WARN] Token format may be invalid (expected ghp_* or github_pat_*)" >> "${DEBUG_LOG}"
    return 1
}

# config_get_ssh_pubkey - Get SSH public key content
# Usage: config_get_ssh_pubkey
config_get_ssh_pubkey() {
    local key_path
    key_path=$(config_get "github" "ssh_key_path")

    if [[ -z "$key_path" ]]; then
        echo ""
        return 1
    fi

    if [[ ! -f "${key_path}.pub" ]]; then
        echo ""
        return 1
    fi

    cat "${key_path}.pub" 2>/dev/null || echo ""
}

# config_has_unsaved_changes - Check if there are unsaved changes
# Usage: config_has_unsaved_changes
config_has_unsaved_changes() {
    # Compare current CONFIG_VALUES with what's on disk
    # For simplicity, we'll just return false for now
    # A full implementation would reload and compare
    return 1
}
