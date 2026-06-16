tmux-sessionizer() {
    local selected="${1:-}"
    if [[ -z "$selected" ]]; then
        local dirs=()
        for d in "$HOME/workspace" "$HOME/projects" "$HOME/repos"; do
            [[ -d "$d" ]] && dirs+=("$d")
        done
        [[ ${#dirs[@]} -eq 0 ]] && dirs=("$HOME")
        selected=$(find "${dirs[@]}" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort -u | fzf --prompt="session> ")
    fi
    [[ -z "$selected" ]] && return 0

    local selected_name="${$(basename "$selected")//./_}"

    if [[ -z "${TMUX:-}" ]]; then
        tmux new-session -As "$selected_name" -c "$selected"
    else
        if ! tmux has-session -t="$selected_name" 2>/dev/null; then
            tmux new-session -ds "$selected_name" -c "$selected"
        fi
        tmux switch-client -t "$selected_name"
    fi
}
