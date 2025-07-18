# Gemini Analysis Report Template

## Report Metadata
```yaml
report_type: [analysis|audit|review|comparison]
date: YYYY-MM-DD HH:MM:SS
analyst: [agent-name]
version: 1.0
file: [analyzed-file-path]
```

## Executive Summary
- **Overall Score**: X.X/10
- **Critical Issues**: X
- **High Priority Issues**: X
- **Total Findings**: X
- **Key Recommendation**: [One-line summary]

## Quality Scores
| Metric | Score | Target | Status |
|--------|-------|--------|--------|
| Code Quality | X.X/10 | 7.0 | ✓/✗ |
| Security | X.X/10 | 8.0 | ✓/✗ |
| Performance | X.X/10 | 7.0 | ✓/✗ |
| Architecture | X.X/10 | 7.0 | ✓/✗ |
| Documentation | X.X/10 | 6.0 | ✓/✗ |

## Critical Findings

### Finding #1: [Title]
- **Severity**: CRITICAL
- **Category**: [Security/Performance/Quality]
- **Location**: [file:line]

**Description**: [Clear explanation of the issue]

**Impact**: [What happens if not fixed]

**Recommendation**: [Conceptual approach to fixing - no code]

---

## High Priority Findings

### Finding #2: [Title]
- **Severity**: HIGH
- **Category**: [Category]
- **Location**: [file:line]

**Description**: [Explanation]

**Impact**: [Consequences]

**Recommendation**: [Approach]

---

## Medium Priority Findings

[List of medium priority issues with brief descriptions]

## Low Priority Findings

[List of minor issues and improvements]

## Positive Aspects

### What's Working Well
- ✓ [Positive finding 1]
- ✓ [Positive finding 2]
- ✓ [Positive finding 3]

## Detailed Analysis

### Code Structure
[Detailed analysis of code organization, patterns, etc.]

### Security Assessment
[In-depth security analysis]

### Performance Analysis
[Performance considerations and bottlenecks]

### Architecture Review
[System design analysis]

### Documentation Coverage
[Documentation completeness assessment]

## Recommendations Summary

### Immediate Actions (This Sprint)
1. [Most critical fix]
2. [Second critical fix]
3. [Third critical fix]

### Short-term Improvements (Next Sprint)
1. [Important improvement]
2. [Another improvement]

### Long-term Considerations
1. [Strategic improvement]
2. [Architectural consideration]

## Trends and Patterns

### Compared to Previous Analysis
- Overall Score: X.X → Y.Y (↑/↓ Z.Z)
- Issues Fixed: X
- New Issues: Y
- Regression: Yes/No

### Common Patterns Observed
- [Pattern 1]
- [Pattern 2]

## Appendices

### A. Methodology
[How the analysis was performed]

### B. Tools Used
- Gemini CLI version X.X
- Analysis frameworks
- Security scanners

### C. References
- [Best practice guide]
- [Security standard]
- [Performance benchmark]

---

*Report generated by Gemini Critic-Analyst - Analysis Only Mode*