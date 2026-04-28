#!/bin/bash
# Disable all existing GitHub Actions workflows except Alpine build
# This script renames all .yml files to .yml.disabled

set -e

WORKFLOW_DIR="$(dirname "$0")"
cd "$WORKFLOW_DIR"

echo "🔧 Disabling existing workflows..."
echo "   Directory: $WORKFLOW_DIR"
echo ""

# Count files
TOTAL=$(ls *.yml 2>/dev/null | wc -l)
echo "📊 Found $TOTAL workflow files"
echo ""

# Disable each workflow
DISABLED=0
for file in *.yml; do
    if [ -f "$file" ]; then
        # Skip if already disabled
        if [[ "$file" == *.disabled ]]; then
            echo "   ⏭️  Skipping (already disabled): $file"
            continue
        fi
        
        # Rename to .disabled
        mv "$file" "${file}.disabled"
        echo "   ✅ Disabled: $file → ${file}.disabled"
        DISABLED=$((DISABLED + 1))
    fi
done

echo ""
echo "✅ Done! Disabled $DISABLED workflows"
echo ""
echo "📝 To re-enable a workflow:"
echo "   mv filename.yml.disabled filename.yml"
echo ""
echo "📋 Disabled files:"
ls *.yml.disabled 2>/dev/null || echo "   (none)"
