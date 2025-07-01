# MetaClaude Cross-Domain Learning System Summary

## Quick Reference

### Learning Hooks Overview

| Hook | Purpose | Trigger | Output |
|------|---------|---------|--------|
| **extract-patterns.sh** | Captures successful strategies | Hourly or after successful operations | Extracted patterns in JSON |
| **abstract-patterns.sh** | Converts to universal patterns | After pattern extraction | Universal patterns at multiple abstraction levels |
| **share-improvements.sh** | Broadcasts patterns | Daily | Updated pattern library |
| **pattern-feedback.sh** | Rates pattern effectiveness | Daily | Pattern metrics and archives |
| **meta-learner.sh** | Discovers pattern combinations | Daily | Compositions and insights |
| **evolution-tracker.sh** | Tracks pattern changes | Weekly | Evolution metrics and lineage |
| **persist-knowledge.sh** | Saves all learned knowledge | Daily | Knowledge checkpoints |

### Directory Structure

```
.claude/
├── patterns/
│   ├── extracted/       # Raw extracted patterns
│   ├── universal/       # Abstracted universal patterns
│   ├── library/         # Curated pattern library
│   ├── broadcast/       # Patterns being shared
│   ├── feedback/        # Pattern feedback data
│   └── archive/         # Ineffective patterns
├── learning/
│   ├── meta/
│   │   ├── insights/    # Learning insights
│   │   └── compositions/# Pattern combinations
│   ├── evolution/
│   │   ├── lineage/     # Pattern evolution history
│   │   ├── emergence/   # Emerging patterns
│   │   └── history/     # Modification records
│   └── persistence/
│       ├── checkpoints/ # Knowledge snapshots
│       └── exports/     # Exported knowledge
└── hooks/metaclaude/learning/
    └── [all learning hooks]
```

### Key Commands

```bash
# Manual pattern extraction
.claude/hooks/metaclaude/learning/extract-patterns.sh

# Force pattern sharing
.claude/hooks/metaclaude/learning/share-improvements.sh

# Generate learning report
.claude/hooks/metaclaude/learning/meta-learner.sh

# Export knowledge
.claude/hooks/metaclaude/learning/persist-knowledge.sh export json

# Import knowledge from another system
.claude/hooks/metaclaude/learning/persist-knowledge.sh import /path/to/export.json

# Check learning system status
cat .claude/learning/meta/meta-learning-summary.json
```

### Integration Checklist

- [ ] Add operation logging to PostToolUse hooks
- [ ] Configure cron jobs for periodic learning tasks
- [ ] Set up feedback collection in pattern usage
- [ ] Configure abstraction rules for your domain
- [ ] Enable knowledge persistence
- [ ] Monitor learning metrics

### Quick Setup

```bash
# 1. Make hooks executable
chmod +x .claude/hooks/metaclaude/learning/*.sh

# 2. Create required directories
mkdir -p .claude/{patterns,learning,logs,data}

# 3. Add to crontab
crontab -e
# Add the learning tasks from the integration guide

# 4. Configure environment
export CLAUDE_LEARNING_ENABLED=true
export CLAUDE_HOME="$HOME/.claude"

# 5. Initialize learning
.claude/hooks/metaclaude/learning/persist-knowledge.sh
```

### Monitoring Commands

```bash
# View extraction metrics
jq '.' .claude/patterns/extraction-metrics.json

# Check pattern library
jq '.patterns | keys' .claude/patterns/library/index.json

# View learning progress
jq '.learning_progress' .claude/learning/meta/insights/*.json | tail -1

# Check evolution status
jq '.evolution_metrics' .claude/learning/evolution/evolution-report.json

# View persistence status
.claude/hooks/metaclaude/learning/persist-knowledge.sh report
```

### Troubleshooting

| Issue | Check | Fix |
|-------|-------|-----|
| No patterns extracted | Operations log format | Ensure proper JSON logging |
| Patterns not shared | Implementation config | Check implementation directories |
| Low effectiveness scores | Feedback data | Review feedback quality |
| Missing insights | Meta-learner schedule | Run meta-learner manually |
| Knowledge not persisted | Checkpoint schedule | Check persist-knowledge cron |

## Learning Flow

```
1. Operation Success
   ↓
2. Pattern Extraction (extract-patterns.sh)
   ↓
3. Pattern Abstraction (abstract-patterns.sh)
   ↓
4. Pattern Sharing (share-improvements.sh)
   ↓
5. Pattern Usage & Feedback
   ↓
6. Effectiveness Rating (pattern-feedback.sh)
   ↓
7. Meta-Learning (meta-learner.sh)
   ↓
8. Evolution Tracking (evolution-tracker.sh)
   ↓
9. Knowledge Persistence (persist-knowledge.sh)
```

## Key Concepts

### Pattern Lifecycle
1. **Extraction**: Captured from successful operations
2. **Abstraction**: Generalized to universal principles
3. **Sharing**: Distributed to implementations
4. **Usage**: Applied in various contexts
5. **Feedback**: Effectiveness measured
6. **Evolution**: Patterns improve over time
7. **Archive**: Ineffective patterns removed

### Abstraction Levels
- **Tactical**: Specific implementations
- **Strategic**: High-level approaches
- **Architectural**: System designs
- **Conceptual**: Pure principles

### Learning Metrics
- **Effectiveness Score**: Pattern success rate
- **Domain Versatility**: Cross-domain usage
- **Evolution Rate**: Pattern improvements
- **Adoption Rate**: Implementation uptake

## Best Practices

1. **Log all operations** with proper structure and metrics
2. **Provide feedback** on pattern usage (success/failure)
3. **Tag operations** with accurate domain information
4. **Regular backups** via knowledge export
5. **Monitor metrics** to track learning progress
6. **Update rules** to match your domain needs

## Next Steps

1. Review `metaclaude-learning-integration.md` for detailed integration
2. Configure abstraction rules for your domain
3. Set up automated learning tasks
4. Start logging operations for pattern extraction
5. Monitor initial learning progress
6. Export and share successful patterns