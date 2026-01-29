#!/bin/bash
set -e

# ============================================================
# Field Reporter - Flutter TDD Loop Script
# Processes PRD files sequentially (01-14), enforcing strict
# red-green TDD cycle for each feature.
# ============================================================

# ============================================================
# Argument handling
# ============================================================
if [ -z "$1" ]; then
  echo "Usage: $0 <iterations>"
  echo "Example: $0 40"
  exit 1
fi

ITERATIONS="$1"

# ============================================================
# Dependency checks
# ============================================================
command -v jq >/dev/null || { echo "Error: jq is required but not installed"; exit 1; }
command -v flutter >/dev/null || { echo "Error: flutter is required but not installed"; exit 1; }
command -v dart >/dev/null || { echo "Error: dart is required but not installed"; exit 1; }

# Detect timeout command (timeout on Linux, gtimeout on macOS via coreutils)
TIMEOUT_CMD=$(command -v timeout || command -v gtimeout || echo "")
if [ -z "$TIMEOUT_CMD" ]; then
  echo "Warning: timeout/gtimeout not found - iterations won't have time limits"
  echo "Install with: brew install coreutils (macOS) or apt install coreutils (Linux)"
fi

# ============================================================
# Path setup
# ============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"

# PRD files in processing order
PRD_FILES=(
  "01-prd-auth.json"
  "02-prd-dashboard.json"
  "03-prd-projects.json"
  "04-prd-reports.json"
  "05-prd-camera-media.json"
  "06-prd-device-sensors.json"
  "07-prd-location-maps.json"
  "08-prd-entry-detail.json"
  "09-prd-offline-sync.json"
  "10-prd-ai-features.json"
  "11-prd-pdf-generation.json"
  "12-prd-notifications.json"
  "13-prd-settings.json"
  "14-prd-app-lifecycle.json"
)

# Reference files for Claude prompt
DESIGN_GUIDELINES="$PROJECT_ROOT/DESIGN_GUIDELINES.md"
CLAUDE_INSTRUCTIONS="$SCRIPT_DIR/CLAUDE_CODE_INSTRUCTIONS.md"

cd "$PROJECT_ROOT"
echo "Working from: $PROJECT_ROOT"
echo ""

# ============================================================
# Helper Functions
# ============================================================

# Get the first PRD file that has incomplete features
get_current_prd() {
  for prd in "${PRD_FILES[@]}"; do
    local prd_path="$SCRIPT_DIR/$prd"
    if [ -f "$prd_path" ]; then
      local remaining=$(jq '[.[] | select(.passes == false)] | length' "$prd_path" 2>/dev/null || echo "0")
      if [ "$remaining" -gt 0 ]; then
        echo "$prd"
        return
      fi
    fi
  done
  echo ""
}

# Extract PRD name from filename (e.g., "01-prd-auth.json" -> "auth")
get_prd_name() {
  local filename="$1"
  echo "$filename" | sed -E 's/[0-9]+-prd-(.+)\.json/\1/'
}

# Map PRD name to test directory paths
get_test_path() {
  local prd_name="$1"
  case "$prd_name" in
    auth)           echo "test/unit/services/auth test/widget/screens/auth" ;;
    dashboard)      echo "test/widget/screens/dashboard" ;;
    projects)       echo "test/unit/repositories/project test/widget/screens/projects" ;;
    reports)        echo "test/unit/repositories/report test/widget/screens/reports" ;;
    camera-media)   echo "test/unit/services/camera test/widget/screens/capture" ;;
    device-sensors) echo "test/unit/services/sensors" ;;
    location-maps)  echo "test/unit/services/location test/widget/screens/maps" ;;
    entry-detail)   echo "test/widget/screens/entries" ;;
    offline-sync)   echo "test/unit/services/sync" ;;
    ai-features)    echo "test/unit/services/ai" ;;
    pdf-generation) echo "test/unit/services/pdf" ;;
    notifications)  echo "test/unit/services/notifications" ;;
    settings)       echo "test/widget/screens/settings" ;;
    app-lifecycle)  echo "test/unit/services/lifecycle" ;;
    *)              echo "test/" ;;
  esac
}

# Calculate global progress across all PRDs
get_global_progress() {
  local total_done=0
  local total_count=0

  for prd in "${PRD_FILES[@]}"; do
    local prd_path="$SCRIPT_DIR/$prd"
    if [ -f "$prd_path" ]; then
      local prd_total=$(jq 'length' "$prd_path" 2>/dev/null || echo "0")
      local prd_done=$(jq '[.[] | select(.passes == true)] | length' "$prd_path" 2>/dev/null || echo "0")
      total_count=$((total_count + prd_total))
      total_done=$((total_done + prd_done))
    fi
  done

  echo "$total_done/$total_count"
}

# Get detailed progress per PRD
show_progress_summary() {
  echo ""
  echo "PRD Progress Summary:"
  echo "----------------------------------------"
  for prd in "${PRD_FILES[@]}"; do
    local prd_path="$SCRIPT_DIR/$prd"
    if [ -f "$prd_path" ]; then
      local prd_total=$(jq 'length' "$prd_path" 2>/dev/null || echo "0")
      local prd_done=$(jq '[.[] | select(.passes == true)] | length' "$prd_path" 2>/dev/null || echo "0")
      local prd_name=$(get_prd_name "$prd")
      local status=""
      if [ "$prd_done" -eq "$prd_total" ]; then
        status=" [COMPLETE]"
      elif [ "$prd_done" -gt 0 ]; then
        status=" [IN PROGRESS]"
      fi
      printf "  %-20s %3d/%3d%s\n" "$prd_name" "$prd_done" "$prd_total" "$status"
    fi
  done
  echo "----------------------------------------"
}

# Track stuck detection
LAST_FEATURE=""
STUCK_COUNT=0

# ============================================================
# Track total time for all iterations
# ============================================================
TOTAL_START=$(date +%s)

# Initial progress summary
show_progress_summary

for ((i=1; i<=$ITERATIONS; i++)); do
  echo ""
  echo "========================================"
  echo "Iteration $i of $ITERATIONS"
  echo "========================================"

  # ============================================================
  # Track time per iteration
  # ============================================================
  ITER_START=$(date +%s)

  # ============================================================
  # Find current PRD to work on
  # ============================================================
  CURRENT_PRD=$(get_current_prd)

  if [ -z "$CURRENT_PRD" ]; then
    echo ""
    echo "========================================"
    echo "ALL PRDs COMPLETE!"
    echo "========================================"
    TOTAL_END=$(date +%s)
    TOTAL_DURATION=$((TOTAL_END - TOTAL_START))
    echo "Total time: $((TOTAL_DURATION / 60))m $((TOTAL_DURATION % 60))s"
    show_progress_summary
    exit 0
  fi

  PRD_PATH="$SCRIPT_DIR/$CURRENT_PRD"
  PRD_NAME=$(get_prd_name "$CURRENT_PRD")
  TEST_PATH=$(get_test_path "$PRD_NAME")

  # ============================================================
  # Count remaining features in current PRD
  # ============================================================
  PRD_REMAINING=$(jq '[.[] | select(.passes == false)] | length' "$PRD_PATH" 2>/dev/null || echo "0")
  PRD_TOTAL=$(jq 'length' "$PRD_PATH" 2>/dev/null || echo "0")
  PRD_DONE=$((PRD_TOTAL - PRD_REMAINING))
  GLOBAL_PROGRESS=$(get_global_progress)

  # Get current feature description for stuck detection
  CURRENT_FEATURE=$(jq -r '[.[] | select(.passes == false)][0].description // empty' "$PRD_PATH" 2>/dev/null || echo "")

  # Stuck detection
  if [ "$CURRENT_FEATURE" = "$LAST_FEATURE" ]; then
    STUCK_COUNT=$((STUCK_COUNT + 1))
    if [ "$STUCK_COUNT" -ge 3 ]; then
      echo ""
      echo "WARNING: Same feature failed 3x in a row: $CURRENT_FEATURE"
      echo "Review progress.txt and recent commits before continuing"
      exit 1
    fi
  else
    LAST_FEATURE="$CURRENT_FEATURE"
    STUCK_COUNT=0
  fi

  echo "Current PRD: $CURRENT_PRD ($PRD_NAME)"
  echo "PRD Progress: $PRD_DONE/$PRD_TOTAL features"
  echo "Global Progress: $GLOBAL_PROGRESS features"
  echo "Test Path: $TEST_PATH"
  echo "Current Feature: $CURRENT_FEATURE"
  echo "----------------------------------------"

  # ============================================================
  # Extract the current feature JSON from PRD
  # ============================================================
  FEATURE_JSON=$(jq -c '[.[] | select(.passes == false)][0]' "$PRD_PATH" 2>/dev/null || echo "{}")
  FEATURE_STEPS=$(jq -r '[.[] | select(.passes == false)][0].steps | join("\n- ")' "$PRD_PATH" 2>/dev/null || echo "")

  # ============================================================
  # Build Claude prompt with TDD enforcement
  # Embed only essential data, reference docs by path for Claude to read
  # ============================================================
  CLAUDE_PROMPT="You are implementing the Field Reporter Flutter app using strict TDD.

## CURRENT TASK
- PRD File: $PRD_PATH
- PRD Name: $PRD_NAME
- PRD Progress: $PRD_DONE/$PRD_TOTAL
- Global Progress: $GLOBAL_PROGRESS

## FEATURE TO IMPLEMENT
Description: $CURRENT_FEATURE
Category: $(echo "$FEATURE_JSON" | jq -r '.category // "functional"')

Acceptance Criteria (steps):
- $FEATURE_STEPS

## REFERENCE DOCS (read these first if doing UI work)
- DESIGN_GUIDELINES.md - for colors, typography, spacing, components
- ralph-loop/CLAUDE_CODE_INSTRUCTIONS.md - for architecture patterns

## STRICT TDD WORKFLOW

1. WRITE TEST FIRST in: $TEST_PATH
   - Test must verify ALL acceptance criteria steps above

2. RUN TEST - MUST FAIL (RED)
   flutter test <your_test_file>

3. IMPLEMENT MINIMAL CODE (GREEN)
   - Only what's needed to pass the test
   - Use Riverpod for state management

4. RUN TEST - MUST PASS
   flutter test <your_test_file>

5. LINT & FORMAT
   dart analyze
   dart format --output=none --set-exit-if-changed .

6. UPDATE PRD & COMMIT
   - Edit $PRD_PATH: set \"passes\": true for this feature
   - Append to ralph-loop/progress.txt: [$(date '+%Y-%m-%d %H:%M')] | $PRD_NAME | $CURRENT_FEATURE | PASS | <files>
   - git add -A && git commit -m \"feat($PRD_NAME): <description>\"

## RULES
- ONE FEATURE ONLY
- Test MUST fail before you write implementation
- Be terse, skip explanations

Output <promise>COMPLETE</promise> when ALL features in ALL PRDs pass."

  # ============================================================
  # Run Claude with optional timeout (45 min max)
  # Pass prompt as argument (works with multi-line strings)
  # ============================================================
  if [ -n "$TIMEOUT_CMD" ]; then
    result=$($TIMEOUT_CMD 2700 claude -p "$CLAUDE_PROMPT" --permission-mode acceptEdits 2>&1) || {
      echo "WARNING: Iteration timed out or failed, continuing..."
      continue
    }
  else
    result=$(claude -p "$CLAUDE_PROMPT" --permission-mode acceptEdits 2>&1) || {
      echo "WARNING: Iteration failed, continuing..."
      continue
    }
  fi

  echo "$result"

  # ============================================================
  # Calculate and display iteration duration
  # ============================================================
  ITER_END=$(date +%s)
  ITER_DURATION=$((ITER_END - ITER_START))
  echo ""
  echo "Iteration completed in ${ITER_DURATION}s ($((ITER_DURATION / 60))m $((ITER_DURATION % 60))s)"

  # Check for completion signal
  if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
    TOTAL_END=$(date +%s)
    TOTAL_DURATION=$((TOTAL_END - TOTAL_START))
    echo ""
    echo "========================================"
    echo "ALL PRDs COMPLETE!"
    echo "Total time: $((TOTAL_DURATION / 60))m $((TOTAL_DURATION % 60))s"
    echo "========================================"
    show_progress_summary
    exit 0
  fi

  # ============================================================
  # Safety check - abort if same commit 3x in a row
  # ============================================================
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    LAST_COMMITS=$(git log --oneline -3 2>/dev/null | awk '{$1=""; print $0}' | sort | uniq -c | sort -rn | head -1 | awk '{print $1}')
    if [ "$LAST_COMMITS" = "3" ]; then
      echo ""
      echo "WARNING: Same commit message 3x in a row - possible stuck loop"
      echo "Review recent commits and progress.txt before continuing"
      exit 1
    fi
  fi

done

# ============================================================
# Summary when iterations exhausted (not complete)
# ============================================================
TOTAL_END=$(date +%s)
TOTAL_DURATION=$((TOTAL_END - TOTAL_START))
echo ""
echo "========================================"
echo "Iterations complete (PRDs not finished)"
echo "Total time: $((TOTAL_DURATION / 60))m $((TOTAL_DURATION % 60))s"
echo "========================================"
show_progress_summary
