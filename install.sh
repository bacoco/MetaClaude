#!/bin/bash

# UI Designer Claude Orchestrator Installation Script

echo "🎨 Installing UI Designer Claude Orchestrator..."

# Check for Claude Code CLI
if ! command -v clause &> /dev/null; then
    echo "❌ Claude Code CLI not found. Please install it first."
    exit 1
fi

# Set execute permissions
chmod +x install.sh

# Initialize git repository
if [ ! -d ".git" ]; then
    git init
    echo "✅ Git repository initialized"
fi

# Create .claudeignore for efficiency
cat > .claudeignore << EOF
node_modules/
*.log
.DS_Store
.env
build/
dist/
*.sketch
*.fig
*.psd
EOF

# Install dependencies if package.json exists
if [ -f "package.json" ]; then
    npm install
    echo "✅ Dependencies installed"
fi

# Verify structure
if [ -d ".claude" ] && [ -f ".claude/CLAUDE.md" ]; then
    echo "✅ UI Designer Orchestrator structure verified"
else
    echo "❌ Invalid structure. Please ensure .claude/CLAUDE.md exists"
    exit 1
fi

# Configure Claude settings
echo "📝 Configuring Claude settings..."
cp .claude/settings.json ~/.claude/ui-designer-settings.json 2>/dev/null || true

echo ""
echo "🎉 UI Designer Claude Orchestrator installed successfully!"
echo ""
echo "Quick start with Claude Code:"
echo "  Navigate to: cd $(pwd)"
echo "  Then use Claude Code with commands like:"
echo "    \"Create a modern SaaS dashboard\""
echo "    \"Extract design DNA from inspiration images\""
echo "    \"Run a design sprint for a mobile app concept\""
echo ""
echo "See README.md for full documentation."
echo ""