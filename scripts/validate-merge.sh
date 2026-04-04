#!/bin/bash
# validate-merge.sh — Run after merging upstream/main to catch residual issues.
#
# Usage:
#   ./scripts/validate-merge.sh          # full validation
#   ./scripts/validate-merge.sh --quick  # conflict markers only

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

ERRORS=0
WARNINGS=0

info()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; ((WARNINGS++)); }
fail()  { echo -e "${RED}[FAIL]${NC} $1"; ((ERRORS++)); }

echo "=== AnyLanguageModel Post-Merge Validation ==="
echo ""

# 1. Conflict markers
echo "--- Checking for conflict markers ---"
if grep -rn '<<<<<<\|>>>>>>' Sources/ --include='*.swift' 2>/dev/null; then
    fail "Conflict markers found in source files"
else
    info "No conflict markers"
fi

if grep -rn '<<<<<<\|>>>>>>' Package.resolved 2>/dev/null; then
    fail "Conflict markers in Package.resolved"
else
    info "Package.resolved clean"
fi

# 2. git diff --check
echo ""
echo "--- Running git diff --check ---"
if git diff --check HEAD 2>/dev/null; then
    info "git diff --check passed"
else
    fail "git diff --check found issues"
fi

if [[ "${1:-}" == "--quick" ]]; then
    echo ""
    echo "Quick mode — skipping build. Errors: $ERRORS, Warnings: $WARNINGS"
    exit $ERRORS
fi

# 3. Duplicate type declarations (common merge artifact)
echo ""
echo "--- Checking for duplicate declarations ---"
for type in "class GPUMemoryManager" "class SessionCacheEntry" "struct GPUMemoryConfiguration"; do
    count=$(grep -c "$type" Sources/AnyLanguageModel/Models/MLXLanguageModel.swift 2>/dev/null || echo 0)
    if [ "$count" -gt 1 ]; then
        fail "Duplicate declaration: '$type' appears $count times in MLXLanguageModel.swift"
    else
        info "'$type' appears $count time(s)"
    fi
done

# 4. Dead fork patterns (should not exist after clean merge)
echo ""
echo "--- Checking for residual fork code ---"
for pattern in "hashTokenPrefix" "prefillTokenHash" "func configure.*GPUMemoryConfiguration" "resolveCache(for:"; do
    if grep -qn "$pattern" Sources/AnyLanguageModel/Models/MLXLanguageModel.swift 2>/dev/null; then
        warn "Possible residual fork code: '$pattern' found in MLXLanguageModel.swift"
    fi
done

# 5. Build
echo ""
echo "--- Building ---"
if swift build 2>&1; then
    info "Build succeeded"
else
    fail "Build failed"
fi

# Summary
echo ""
echo "=== Summary ==="
echo -e "Errors:   $ERRORS"
echo -e "Warnings: $WARNINGS"

if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}Validation FAILED — fix errors before proceeding${NC}"
    exit 1
else
    echo -e "${GREEN}Validation passed${NC}"
    exit 0
fi
