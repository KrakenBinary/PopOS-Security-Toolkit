#!/usr/bin/env bash
register_tool "gh" "GitHub CLI" "Development Tools" "gh" "gh" \
    "Official GitHub command line tool. Interact with pull requests, issues, repos, gists, and more directly from the terminal. Supports authentication and git protocol configuration."

install_gh() {
      echo "[INFO] Installing GitHub CLI..." >> "${RUN_LOG}"
      safe_exec apt-get install -y curl gnupg || return 1
      echo "[INFO] Adding GitHub CLI GPG key..." >> "${RUN_LOG}"
      if ! curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>>"${RUN_LOG}"; then
          echo "[ERROR] Failed to add GitHub CLI GPG key" >> "${RUN_LOG}"
          return 1
      fi
      chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
      echo "[INFO] Adding GitHub CLI repository..." >> "${RUN_LOG}"
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
      safe_exec apt-get update || return 1
      safe_exec apt-get install -y gh || return 1
      verify_binary gh || return 1
      return 0
  }

uninstall_gh() {
      echo "[INFO] Removing GitHub CLI..." >> "${RUN_LOG}"
      apt-get remove -y gh >> "${RUN_LOG}" 2>&1
      rm -f /etc/apt/sources.list.d/github-cli.list
      rm -f /usr/share/keyrings/githubcli-archive-keyring.gpg
      return 0
  }
