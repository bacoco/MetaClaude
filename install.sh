#!/bin/bash

# MetaClaude Framework Installation Script

echo "🧠 Installing MetaClaude Framework..."

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
if [ -d ".claude" ] && [ -f ".claude/core/framework.md" ]; then
    echo "✅ MetaClaude framework structure verified"
    
    # Check for implementations
    if [ -d ".claude/implementations/ui-designer" ]; then
        echo "✅ UI Designer implementation found"
    fi
else
    echo "❌ Invalid structure. Please ensure .claude/core/framework.md exists"
    exit 1
fi

# Configure MetaClaude settings
echo "📝 Configuring MetaClaude settings..."
cp .claude/settings.json ~/.claude/metaclaude-settings.json 2>/dev/null || true

echo ""
echo "🎉 MetaClaude Framework installed successfully!"
echo ""
echo "Available implementations:"
if [ -d ".claude/implementations/ui-designer" ]; then
    echo "  ✅ UI Designer - Create professional UI/UX designs"
fi
echo ""
echo "Quick start with Claude Code:"
echo "  Navigate to: cd $(pwd)"
echo "  Then use Claude Code with natural language:"
echo "    \"Create a modern SaaS dashboard\""
echo "    \"Design a mobile app for task management\""
echo "    \"Run a design sprint for an e-commerce platform\""
echo ""
echo "Learn more:"
echo "  - Getting Started: .claude/GETTING_STARTED.md"
echo "  - Full docs: README.md"
echo ""
echo "MetaClaude: Building cognitive systems that think about thinking"
echo ""