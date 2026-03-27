#!/usr/bin/env bash
# Maps GHA event context to a deploytarot intent.
# Writes intent= to $GITHUB_OUTPUT.
set -euo pipefail

# If the user provided an explicit intent, use it directly.
if [ -n "${INPUT_INTENT:-}" ]; then
  echo "intent=$INPUT_INTENT" >> "$GITHUB_OUTPUT"
  exit 0
fi

INTENT=""
BRANCH="${GH_HEAD_REF:-${GH_REF#refs/heads/}}"

case "${GH_EVENT:-}" in
  release)
    INTENT="full-release"
    ;;
  push)
    case "$GH_REF" in
      refs/heads/main|refs/heads/master|refs/tags/*)
        INTENT="full-release"
        ;;
      *)
        INTENT="quick-fix"
        ;;
    esac
    ;;
  pull_request|pull_request_target)
    # Dependabot or auto-dependency bots
    if [[ "${GH_ACTOR:-}" == "dependabot[bot]" || "${BRANCH:-}" == deps/* || "${BRANCH:-}" == dependabot/* ]]; then
      INTENT="dependency-update"
    # Branch name patterns
    elif [[ "${BRANCH:-}" == hotfix/* || "${BRANCH:-}" == fix/* ]]; then
      INTENT="hotfix-prod"
    elif [[ "${BRANCH:-}" == refactor/* || "${BRANCH:-}" == chore/* ]]; then
      INTENT="refactor"
    elif [[ "${BRANCH:-}" == feat/* || "${BRANCH:-}" == feature/* ]]; then
      INTENT="new-feature"
    elif [[ "${BRANCH:-}" == db/* || "${BRANCH:-}" == migration/* ]]; then
      INTENT="db-migration"
    elif [[ "${BRANCH:-}" == infra/* || "${BRANCH:-}" == ops/* ]]; then
      INTENT="infra-change"
    elif [[ "${BRANCH:-}" == docs/* || "${BRANCH:-}" == doc/* ]]; then
      INTENT="public-doc-release"
    elif [[ "${BRANCH:-}" == security/* || "${BRANCH:-}" == sec/* ]]; then
      INTENT="security-patch"
    else
      INTENT="new-feature"
    fi
    ;;
  schedule)
    INTENT="dependency-update"
    ;;
  workflow_dispatch)
    # Manual trigger — default to just-vibes if nothing specified
    INTENT="just-vibes"
    ;;
  *)
    INTENT="quick-fix"
    ;;
esac

echo "intent=$INTENT" >> "$GITHUB_OUTPUT"
