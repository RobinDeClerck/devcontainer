# git.sh — git repo info + SSH agent sanity check.
# Exposes: collect_git(), check_ssh_agent(), print_git_info()
# Requires: ansi.sh, box.sh (for print_rows).
# Sets: GIT_ROWS array (collect_git).

GIT_ROWS=()

# Populate GIT_ROWS with "Key|Value" entries. Empty if not in a repo.
collect_git() {
  command -v git >/dev/null 2>&1 || return 0
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0

  local branch sha subject status_count remote upstream ahead_behind

  branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null \
    || printf '(detached @ %s)' "$(git rev-parse --short HEAD)")

  sha=$(git rev-parse --short HEAD 2>/dev/null || echo '-')
  subject=$(git log -1 --pretty=%s 2>/dev/null || echo '-')
  (( ${#subject} > 60 )) && subject="${subject:0:57}..."

  status_count=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  if [ "$status_count" = "0" ]; then
    status_count="clean"
  else
    status_count="$status_count change(s)"
  fi

  remote=$(git config --get remote.origin.url 2>/dev/null || echo '-')
  (( ${#remote} > 60 )) && remote="...${remote: -57}"

  upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)
  if [ -n "$upstream" ]; then
    local ahead behind
    read -r ahead behind < <(git rev-list --left-right --count "@{u}...HEAD" 2>/dev/null || echo "0 0")
    ahead_behind="↑${behind} ↓${ahead} (${upstream})"
  else
    ahead_behind="no upstream"
  fi

  GIT_ROWS=(
    "Branch|$branch"
    "Commit|$sha — $subject"
    "Status|$status_count"
    "Upstream|$ahead_behind"
    "Remote|$remote"
  )
}

# Warn if the repo uses SSH but no keys are forwarded into the container.
check_ssh_agent() {
  command -v git >/dev/null 2>&1 || return 0
  command -v ssh-add >/dev/null 2>&1 || return 0
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0

  local remote
  remote=$(git config --get remote.origin.url 2>/dev/null || true)
  [[ "$remote" == git@* || "$remote" == ssh://* ]] || return 0

  ssh-add -l >/dev/null 2>&1 && return 0

  gum log --time rfc822 --level warn \
    "no SSH keys forwarded — run on host: ssh-add ~/.ssh/id_ed25519, then rebuild the container"
}

# High-level: collect, then print rows + run ssh check. No-op outside a repo.
print_git_info() {
  collect_git
  (( ${#GIT_ROWS[@]} == 0 )) && return 0

  gum log --time rfc822 --level info "found git, retrieving information..."
  echo
  print_rows 12 "${GIT_ROWS[@]}"
  echo
  check_ssh_agent
}
