# MetaClaude Intelligent Reinforcement Hooks

This directory contains Phase 3 of the MetaClaude implementation: Intelligent Reinforcement hooks that ensure balanced concept representation throughout the codebase.

## Overview

The reinforcement system monitors and optimizes the density of MetaClaude concepts (transparency, adaptability, user-centricity, etc.) to maintain clarity without redundancy.

## Components

### 1. Concept Density Analysis (`concept-density.sh`)

Analyzes files for repetition of core concepts and calculates density scores.

**Usage:**
```bash
./concept-density.sh [target] [format]
# target: file or directory (default: current directory)
# format: json (default)
```

**Features:**
- Tracks 7 core MetaClaude concepts
- Calculates density per 1000 words
- Adjusts for file type (documentation vs code)
- Provides optimization recommendations

### 2. Consolidation Suggestions (`suggest-consolidation.sh`)

Identifies over-explained concepts and suggests consolidation strategies.

**Usage:**
```bash
./suggest-consolidation.sh [target]
```

**Features:**
- Detects repeated definitions
- Suggests implicit vs explicit documentation strategies
- Recommends central definition references
- File-type aware recommendations

### 3. Concept Mapping (`concept-map.sh`)

Generates visual concept maps showing where principles are defined and referenced.

**Usage:**
```bash
./concept-map.sh [target] [format]
# format: html (default) or dot
```

**Features:**
- Interactive HTML visualization
- DOT graph generation for image export
- Redundancy detection
- Definition vs reference tracking

### 4. Balance Checker (`balance-checker.sh`)

Ensures concepts are adequately represented without over-emphasis.

**Usage:**
```bash
./balance-checker.sh [target]
```

**Features:**
- Weight-adjusted balance scoring
- Project-wide health assessment
- Actionable recommendations
- Issue severity classification

### 5. Integration Hooks

#### Pre-Write Density Check (`pre-write-density-check.sh`)
- Runs before Write/Edit operations
- Warns about concept over-emphasis
- Non-blocking (allows operation to proceed)

#### Post-Write Tracking (`post-write-update-tracking.sh`)
- Updates concept tracking database
- Analyzes trends over time
- Triggers consolidation suggestions when needed

## Configuration

### Concept Patterns (`concept-patterns.json`)

Defines:
- Core concepts and their keywords
- Optimal density ranges
- File type multipliers
- Consolidation triggers

### Hook Configuration (`hook-config.json`)

Configures:
- Hook registration for tools
- Warning thresholds
- Tracking parameters
- Feature toggles

## Optimal Density Guidelines

| Concept | Min Density | Max Density | Description |
|---------|------------|-------------|-------------|
| Transparency | 0.002 | 0.008 | 2-8 mentions per 1000 words |
| Adaptability | 0.002 | 0.008 | 2-8 mentions per 1000 words |
| User-centricity | 0.002 | 0.008 | 2-8 mentions per 1000 words |
| Orchestration | 0.001 | 0.006 | 1-6 mentions per 1000 words |
| Metacognition | 0.001 | 0.005 | 1-5 mentions per 1000 words |
| Evolution | 0.001 | 0.005 | 1-5 mentions per 1000 words |
| Autonomy | 0.001 | 0.004 | 1-4 mentions per 1000 words |

## File Type Adjustments

- **Documentation** (*.md, README*): 1.0x multiplier
- **Code** (*.sh, *.py, *.js): 0.5x multiplier
- **Configuration** (*.json, *.yaml): 0.3x multiplier

## Best Practices

1. **Initial Definition**: Define concepts clearly in central documentation
2. **Subsequent References**: Use brief mentions or links to definitions
3. **Code Comments**: Focus on implementation details, not concept explanations
4. **Balance**: Aim for "balanced" status across all files
5. **Regular Checks**: Run balance-checker.sh periodically

## Integration with Claude Code

To enable automatic reinforcement checking:

1. The hooks are designed to integrate with Claude Code's tool use events
2. Pre-write checks provide warnings but don't block operations
3. Post-write tracking builds historical data for trend analysis
4. Suggestions are provided as informational messages

## Troubleshooting

### High Concept Density
- Run `suggest-consolidation.sh` for specific recommendations
- Consider moving definitions to central documentation
- Use implicit references after initial introduction

### Low Concept Density
- Ensure key concepts are adequately introduced
- Add context where concepts are implemented
- Balance technical accuracy with readability

### Visualization Issues
- For DOT graphs: Install graphviz (`brew install graphviz`)
- For HTML: Use a modern web browser
- Check file permissions for output directory

## Future Enhancements

- [ ] Real-time density monitoring in editor
- [ ] Automated consolidation PR generation
- [ ] Cross-repository concept tracking
- [ ] Machine learning for optimal density prediction
- [ ] Integration with documentation generators