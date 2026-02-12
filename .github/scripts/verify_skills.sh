#!/usr/bin/env bash
set -euo pipefail

# Verify ONLY the SKILL.md files changed in this PR/push.
# This allows incremental adoption without forcing a repo-wide rewrite.

fail=0

changed_files() {
  # Ensure we have enough history for diffs
  git rev-parse --is-inside-work-tree >/dev/null

  if [[ -n "${GITHUB_BASE_REF:-}" ]]; then
    # pull_request
    git fetch --no-tags --prune --depth=1 origin "+refs/heads/${GITHUB_BASE_REF}:refs/remotes/origin/${GITHUB_BASE_REF}" >/dev/null 2>&1 || true
    git diff --name-only "origin/${GITHUB_BASE_REF}...HEAD"
  else
    # push or local run: just check last commit
    if git rev-parse --verify HEAD^ >/dev/null 2>&1; then
      git diff --name-only HEAD^..HEAD
    else
      git ls-files
    fi
  fi
}

files=$(changed_files | grep -E '(^|/)SKILL\.md$' || true)

if [[ -z "${files}" ]]; then
  echo "No SKILL.md changes detected. Nothing to verify."
  exit 0
fi

echo "Verifying changed SKILL.md files:"

IFS=$'\n'
for f in $files; do
  [[ -z "$f" ]] && continue
  echo "- $f"

  if ! grep -Eq '^description:\s*"?Use when:' "$f"; then
    echo "  [FAIL] description must start with: Use when: ... (routing logic)"
    fail=1
  fi

  if ! grep -Eq '^##\s+How to verify' "$f"; then
    echo "  [FAIL] missing section: ## How to verify"
    fail=1
  fi

  if ! grep -Eq '^##\s+Negative examples' "$f"; then
    echo "  [FAIL] missing section: ## Negative examples"
    fail=1
  fi
done
unset IFS

if [[ $fail -ne 0 ]]; then
  echo
  echo "Skill verification FAILED. Fix the issues above."
  exit 1
fi

echo "Skill verification PASSED."
