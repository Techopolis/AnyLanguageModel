#!/bin/bash
# check-upstream.sh — Report divergence between our fork and upstream.
#
# Usage:
#   ./scripts/check-upstream.sh           # fetch + report
#   ./scripts/check-upstream.sh --local   # skip fetch, use cached refs

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

UPSTREAM="upstream"
MAIN="main"

# Verify upstream remote exists
if ! git remote get-url "$UPSTREAM" &>/dev/null; then
    echo "Error: No '$UPSTREAM' remote configured."
    echo "Add it with: git remote add upstream https://github.com/mattt/AnyLanguageModel.git"
    exit 1
fi

# Fetch unless --local
if [[ "${1:-}" != "--local" ]]; then
    echo "Fetching upstream..."
    git fetch "$UPSTREAM" --tags --quiet
fi

echo ""
echo "=== Upstream Divergence Report ==="
echo "  Fork:     $(git remote get-url origin)"
echo "  Upstream: $(git remote get-url $UPSTREAM)"
echo ""

# Commits ahead/behind
AHEAD=$(git rev-list "$UPSTREAM/$MAIN".."$MAIN" --count 2>/dev/null || echo "?")
BEHIND=$(git rev-list "$MAIN".."$UPSTREAM/$MAIN" --count 2>/dev/null || echo "?")

echo "  Local main is $AHEAD commits ahead, $BEHIND commits behind upstream/main"
echo ""

# New upstream commits
if [ "$BEHIND" != "0" ] && [ "$BEHIND" != "?" ]; then
    echo "--- New upstream commits (not in our fork) ---"
    git log "$MAIN".."$UPSTREAM/$MAIN" --oneline --no-merges
    echo ""

    # Files that would conflict
    echo "--- Files modified by both sides (potential conflicts) ---"
    UPSTREAM_FILES=$(git diff --name-only "$MAIN"..."$UPSTREAM/$MAIN" 2>/dev/null)
    FORK_FILES=$(git diff --name-only "$UPSTREAM/$MAIN"..."$MAIN" 2>/dev/null)
    CONFLICTS=$(comm -12 <(echo "$UPSTREAM_FILES" | sort) <(echo "$FORK_FILES" | sort) 2>/dev/null)
    if [ -n "$CONFLICTS" ]; then
        echo "$CONFLICTS"
    else
        echo "  (none — clean merge expected)"
    fi
    echo ""
fi

# New tags
echo "--- Upstream tags not in fork ---"
UPSTREAM_TAGS=$(git tag --list --sort=-version:refname | head -10)
if [ -n "$UPSTREAM_TAGS" ]; then
    for tag in $UPSTREAM_TAGS; do
        if git merge-base --is-ancestor "$tag" "$MAIN" 2>/dev/null; then
            echo "  $tag (already merged)"
        else
            echo "  $tag (NOT merged)"
        fi
    done
else
    echo "  (no tags)"
fi

echo ""

# Fork-specific files (not in upstream)
echo "--- Fork-specific files ---"
git diff --name-only "$UPSTREAM/$MAIN"..."$MAIN" --diff-filter=A 2>/dev/null | while read -r f; do
    echo "  + $f"
done

echo ""

if [ "$BEHIND" = "0" ]; then
    echo "Up to date with upstream."
elif [ "$BEHIND" != "?" ]; then
    echo "Action needed: $BEHIND upstream commits to merge."
    echo "Run: git merge upstream/main --no-edit"
    echo "Then: ./scripts/validate-merge.sh"
fi
