#!/usr/bin/env bash
# Maps GHA event context to a deploytarot role and intent.
# Writes role= and intent= to $GITHUB_OUTPUT.
set -euo pipefail

BRANCH="${GH_HEAD_REF:-${GH_REF#refs/heads/}}"

# ---------------------------------------------------------------------------
# Role detection
# ---------------------------------------------------------------------------

if [ -n "${INPUT_ROLE:-}" ]; then
  ROLE="$INPUT_ROLE"
elif [[ "${GH_ACTOR:-}" == *"[bot]" ]]; then
  # Any GitHub bot actor (dependabot[bot], renovate[bot], copilot[bot], etc.)
  ROLE="ai-agent"
elif [[ "${GH_ACTOR:-}" == "github-actions" ]]; then
  ROLE="ai-agent"
else
  ROLE="devops"
fi

# ---------------------------------------------------------------------------
# Intent detection
# ---------------------------------------------------------------------------

if [ -n "${INPUT_INTENT:-}" ]; then
  INTENT="$INPUT_INTENT"
else
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
      if [[ "${GH_ACTOR:-}" == "dependabot[bot]" || "${GH_ACTOR:-}" == "renovate[bot]" \
            || "${BRANCH:-}" == deps/* || "${BRANCH:-}" == dependabot/* || "${BRANCH:-}" == renovate/* ]]; then
        INTENT="dependency-update"
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
      INTENT="just-vibes"
      ;;
    *)
      INTENT="quick-fix"
      ;;
  esac
fi

echo "role=$ROLE" >> "$GITHUB_OUTPUT"
echo "intent=$INTENT" >> "$GITHUB_OUTPUT"
