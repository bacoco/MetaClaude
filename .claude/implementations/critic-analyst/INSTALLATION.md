# Gemini Critic-Analyst Installation Guide

## Prerequisites

- Node.js 18+ installed
- npm or yarn package manager
- Google account for Gemini API access

## Installation Steps

### 1. Install Gemini CLI

```bash
# Global installation (recommended)
npm install -g @google/gemini-cli

# Or use npx (no installation needed)
npx @google/gemini-cli
```

### 2. Configure Authentication

#### Option A: Browser Authentication (Easiest)
```bash
# Run any gemini command to trigger auth
gemini-critic analyze test.js

# This will open your browser for Google authentication
# Grant permissions when prompted
```

#### Option B: API Key (Advanced)
```bash
# Generate API key at https://aistudio.google.com/apikey
export GEMINI_API_KEY="your-api-key-here"

# Or add to your shell profile
echo 'export GEMINI_API_KEY="your-api-key-here"' >> ~/.bashrc
```

### 3. Verify Installation

```bash
# Test Gemini CLI directly
npx @google/gemini-cli "What is 2+2?"

# Test our wrapper
cd .claude/implementations/critic-analyst
./scripts/gemini-critic.sh help
```

### 4. Set Up Permissions

```bash
# Make scripts executable
chmod +x .claude/implementations/critic-analyst/scripts/*.sh
```

## Configuration

### Environment Variables
```bash
# Optional: Set default output directory
export GEMINI_CRITIC_REPORTS_DIR="$HOME/gemini-reports"

# Optional: Set default model
export GEMINI_MODEL="gemini-pro"
```

### Integration with MetaClaude

1. **Hook Integration**
   ```bash
   # Link to hooks directory
   ln -s $PWD/.claude/implementations/critic-analyst/scripts/gemini-critic.sh \
         $PWD/.claude/hooks/metaclaude/critic/
   ```

2. **Update Hook Settings**
   ```json
   // .claude/hooks/settings.json
   {
     "hooks": {
       "PostGenerate": [
         {
           "matcher": "*.js|*.py|*.ts",
           "hooks": [
             {
               "type": "command",
               "command": "critic/gemini-critic.sh analyze"
             }
           ]
         }
       ]
     }
   }
   ```

## Usage Examples

### Basic Analysis
```bash
# Analyze a single file
./scripts/gemini-critic.sh analyze src/auth.js

# Save report to file
./scripts/gemini-critic.sh analyze src/auth.js --output report.md
```

### Security Audit
```bash
# Audit entire project
./scripts/gemini-critic.sh audit .

# Reports saved to: reports/audits/[timestamp]/
```

### Compare Versions
```bash
# Compare two implementations
./scripts/gemini-critic.sh compare v1.js v2.js
```

### Comprehensive Review
```bash
# Run all agents
./scripts/gemini-critic.sh analyze src/main.js --comprehensive
```

## Troubleshooting

### Common Issues

1. **Authentication Failed**
   ```bash
   # Clear credentials and re-authenticate
   rm -rf ~/.config/gemini-cli
   npx @google/gemini-cli auth
   ```

2. **Rate Limiting**
   - Free tier: 60 requests/minute
   - Add delays between requests if needed

3. **Network Issues**
   ```bash
   # Test connectivity
   curl https://generativelanguage.googleapis.com
   ```

### API Limits

- **Free Tier**:
  - 60 requests per minute
  - 1,000 requests per day
  - 32K token context window

- **With API Key**:
  - Higher rate limits
  - Larger context windows
  - Priority access

## Best Practices

1. **Batch Analysis**: Group files to minimize API calls
2. **Cache Results**: Store reports for future reference
3. **Monitor Usage**: Track API usage to avoid limits
4. **Regular Updates**: Keep Gemini CLI updated

```bash
# Update Gemini CLI
npm update -g @google/gemini-cli
```

## Security Notes

- Never commit API keys to version control
- Use environment variables for sensitive data
- Restrict report directory permissions
- Review Gemini's data usage policies

## Support

- Gemini CLI Issues: https://github.com/google-gemini/gemini-cli/issues
- MetaClaude Integration: Create issue in this repository
- API Documentation: https://ai.google.dev/

---

*Installation guide for Gemini Critic-Analyst specialist*