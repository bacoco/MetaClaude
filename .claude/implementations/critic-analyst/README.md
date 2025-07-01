# 🔍 Gemini Critic-Analyst Specialist

> **The analytical mind of MetaClaude - providing continuous quality analysis and feedback using Google's Gemini as a dedicated analysis engine.**

## Overview

The Critic-Analyst specialist creates an unprecedented AI collaboration where Claude creates while Gemini critiques. This specialist leverages Google's Gemini CLI to provide deep analysis, security audits, performance assessments, and architectural reviews of all Claude outputs.

### Key Principle

**Gemini analyzes what Claude creates, but never creates anything itself.**

## Architecture

```
critic-analyst/
├── agents/              # Analysis specialists
├── workflows/           # Analysis processes
├── patterns/            # Analysis templates
├── scripts/             # Gemini CLI wrappers
└── reports/             # Generated analyses
    ├── analyses/        # Code analyses
    ├── audits/          # Security audits
    ├── reviews/         # Architecture reviews
    └── comparisons/     # Version comparisons
```

## Agents

### 1. Code Critic (`code-critic.md`)
- Analyzes code structure and quality
- Identifies anti-patterns and code smells
- Suggests improvements (descriptions only)
- Scores maintainability and readability

### 2. Security Auditor (`security-auditor.md`)
- Performs security vulnerability analysis
- Checks for OWASP Top 10 issues
- Reviews authentication and authorization
- Identifies data exposure risks

### 3. Architecture Reviewer (`architecture-reviewer.md`)
- Evaluates system design decisions
- Analyzes scalability and resilience
- Reviews design pattern usage
- Assesses technical debt

### 4. Performance Analyst (`performance-analyst.md`)
- Identifies performance bottlenecks
- Analyzes algorithmic complexity
- Reviews resource utilization
- Suggests optimization strategies

### 5. Documentation Reviewer (`documentation-reviewer.md`)
- Assesses documentation completeness
- Reviews clarity and accuracy
- Identifies missing information
- Suggests improvements

## Workflows

### 1. Comprehensive Review (`comprehensive-review.md`)
Full analysis covering all aspects:
- Code quality
- Security vulnerabilities
- Architecture soundness
- Performance implications
- Documentation coverage

### 2. Iterative Improvement (`iterative-improvement.md`)
Continuous feedback loop:
- Initial analysis
- Claude improvements
- Re-analysis
- Quality verification

### 3. Pre-Release Audit (`pre-release-audit.md`)
Final quality gate:
- Security clearance
- Performance validation
- Architecture approval
- Documentation check

## Integration

### With Gemini CLI

```bash
# Install Gemini CLI
npm install -g @google/gemini-cli

# Configure authentication
gemini configure --auth
```

### Analysis Commands

```bash
# Analyze code
./scripts/gemini-critic.sh analyze <file>

# Security audit
./scripts/gemini-critic.sh audit <project>

# Architecture review
./scripts/gemini-critic.sh review <design>

# Compare versions
./scripts/gemini-critic.sh compare <v1> <v2>
```

## Output Format

All Gemini outputs are structured analysis documents:

```markdown
# Gemini Analysis Report

## Executive Summary
[High-level findings]

## Detailed Analysis
### Code Quality
- Score: X/10
- Issues: [List]
- Suggestions: [List]

### Security Assessment
- Critical: [Count]
- High: [Count]
- Medium: [Count]
- Low: [Count]

### Performance Analysis
[Findings]

### Recommendations
[Prioritized improvements]
```

## Safeguards

1. **Analysis-Only Mode**: Gemini can only generate analysis documents
2. **No Code Generation**: Wrapper scripts prevent code creation
3. **Structured Output**: All outputs follow predefined templates
4. **Audit Trail**: All analyses are timestamped and archived

## Usage Examples

### Basic Analysis
```bash
# Claude creates feature
claude implement user-auth.js

# Gemini analyzes
gemini-critic analyze user-auth.js

# Output: reports/analyses/2024-01-15-user-auth-analysis.md
```

### Security Audit
```bash
# Full security scan
gemini-critic audit --security ./src

# Output: reports/audits/2024-01-15-security-audit.md
```

### Continuous Improvement
```bash
# Iterative refinement
./workflows/iterative-improvement.sh feature.js

# Automatically cycles until quality threshold met
```

## Best Practices

1. **Regular Analysis**: Run after every significant Claude output
2. **Automated Integration**: Use hooks for automatic analysis
3. **Track Metrics**: Monitor improvement over time
4. **Archive Reports**: Keep historical analyses for learning

## Future Enhancements

- Real-time analysis during Claude creation
- Comparative analysis across projects
- Trend analysis and reporting
- Integration with CI/CD pipelines

---

*The Critic-Analyst specialist ensures MetaClaude maintains the highest quality standards through continuous, objective analysis.*