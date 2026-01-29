#!/bin/bash
# ============================================================
# Field Reporter - PRD Progress Summary
# Quick view of progress across all PRD files
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Check for jq
command -v jq >/dev/null || { echo "Error: jq is required but not installed"; exit 1; }

total_done=0
total_count=0

echo ""
echo "========================================"
echo "Field Reporter - PRD Progress Summary"
echo "========================================"
echo ""

printf "%-22s %8s %10s\n" "PRD" "Progress" "Status"
echo "----------------------------------------"

for prd in "${PRD_FILES[@]}"; do
  prd_path="$SCRIPT_DIR/$prd"
  if [ -f "$prd_path" ]; then
    prd_total=$(jq 'length' "$prd_path" 2>/dev/null || echo "0")
    prd_done=$(jq '[.[] | select(.passes == true)] | length' "$prd_path" 2>/dev/null || echo "0")
    prd_name=$(echo "$prd" | sed -E 's/[0-9]+-prd-(.+)\.json/\1/')

    total_count=$((total_count + prd_total))
    total_done=$((total_done + prd_done))

    # Calculate percentage
    if [ "$prd_total" -gt 0 ]; then
      pct=$((prd_done * 100 / prd_total))
    else
      pct=0
    fi

    # Determine status
    if [ "$prd_done" -eq "$prd_total" ] && [ "$prd_total" -gt 0 ]; then
      status="COMPLETE"
    elif [ "$prd_done" -gt 0 ]; then
      status="IN PROGRESS"
    else
      status="PENDING"
    fi

    printf "%-22s %3d/%-4d %10s\n" "$prd_name" "$prd_done" "$prd_total" "$status"
  else
    prd_name=$(echo "$prd" | sed -E 's/[0-9]+-prd-(.+)\.json/\1/')
    printf "%-22s %8s %10s\n" "$prd_name" "N/A" "MISSING"
  fi
done

echo "----------------------------------------"

# Calculate overall percentage
if [ "$total_count" -gt 0 ]; then
  overall_pct=$((total_done * 100 / total_count))
else
  overall_pct=0
fi

printf "%-22s %3d/%-4d (%d%%)\n" "TOTAL" "$total_done" "$total_count" "$overall_pct"
echo ""

# Show progress bar
bar_width=40
filled=$((overall_pct * bar_width / 100))
empty=$((bar_width - filled))

printf "["
printf "%${filled}s" | tr ' ' '#'
printf "%${empty}s" | tr ' ' '-'
printf "] %d%%\n" "$overall_pct"
echo ""

# Show next feature to implement
for prd in "${PRD_FILES[@]}"; do
  prd_path="$SCRIPT_DIR/$prd"
  if [ -f "$prd_path" ]; then
    next_feature=$(jq -r '[.[] | select(.passes == false)][0].description // empty' "$prd_path" 2>/dev/null)
    if [ -n "$next_feature" ]; then
      prd_name=$(echo "$prd" | sed -E 's/[0-9]+-prd-(.+)\.json/\1/')
      echo "Next: [$prd_name] $next_feature"
      break
    fi
  fi
done
echo ""
