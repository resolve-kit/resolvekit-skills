#!/bin/bash
# ResolveKit Agent Skills Installer
# Copies ResolveKit integration skills into your project's .agents/skills/ directory.
#
# Usage:
#   ./install.sh                    # Installs to current directory
#   ./install.sh /path/to/project   # Installs to specified directory
#
# After installation, AI agents (Hermes, Codex, Claude Code, Cursor, etc.)
# will automatically discover and use these skills when working on your project.

set -e

TARGET_DIR="${1:-.}"

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory '$TARGET_DIR' does not exist."
    exit 1
fi

SKILLS_DIR="$TARGET_DIR/.agents/skills"

echo "Installing ResolveKit agent skills into: $SKILLS_DIR"

# Copy all skill directories
for skill in resolvekit-integration resolvekit-ios-integration resolvekit-android-integration resolvekit-backend-setup resolvekit-agent-instructions; do
    if [ -d "$skill" ]; then
        mkdir -p "$SKILLS_DIR/$skill"
        cp -r "$skill"/* "$SKILLS_DIR/$skill/"
        echo "  Installed: $skill"
    fi
done

echo ""
echo "Done! Skills installed in $SKILLS_DIR"
echo ""
echo "Available skills:"
for skill in "$SKILLS_DIR"/resolvekit-*/; do
    name=$(basename "$skill")
    desc=$(head -3 "$skill/SKILL.md" | grep "^description:" | sed 's/^description: //')
    echo "  - $name: $desc"
done

echo ""
echo "Next steps:"
echo "  1. Tell your AI agent: 'Integrate ResolveKit into this project'"
echo "  2. The agent will auto-discover the skills and follow the integration guide"
echo ""
echo "For manual integration, see: https://docs.thingsarestaging.tech"
