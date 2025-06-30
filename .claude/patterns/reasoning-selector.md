# Meta-Reasoning Selector Pattern

Dynamic reasoning pattern selection and combination framework for adaptive AI cognition.

## Overview

This meta-reasoning layer analyzes task complexity and characteristics to dynamically select, combine, or create appropriate reasoning patterns. It enables the AI to adapt its cognitive approach based on the specific challenge at hand.

## Task Complexity Analysis

### Complexity Dimensions

```javascript
const complexityAnalysis = {
  dimensions: {
    scope: {
      simple: 1,     // Single component or decision
      moderate: 3,   // Multiple related elements
      complex: 5     // System-wide or multi-system
    },
    
    novelty: {
      routine: 1,    // Seen this exact pattern before
      familiar: 3,   // Similar to known patterns
      novel: 5       // Completely new challenge
    },
    
    constraints: {
      flexible: 1,   // Few constraints, many options
      balanced: 3,   // Some important constraints
      rigid: 5       // Highly constrained solution space
    },
    
    stakeholders: {
      single: 1,     // One user or perspective
      small: 3,      // 2-5 stakeholders
      many: 5        // Multiple user groups
    },
    
    uncertainty: {
      low: 1,        // Clear requirements
      medium: 3,     // Some ambiguity
      high: 5        // Many unknowns
    }
  },
  
  calculateScore: (task) => {
    const scores = evaluateDimensions(task);
    return {
      total: sum(scores),
      profile: scores,
      category: categorizeComplexity(sum(scores))
    };
  }
};
```

### Complexity Categories

| Score Range | Category | Approach |
|-------------|----------|----------|
| 5-8 | Simple | Single pattern, direct execution |
| 9-15 | Moderate | Primary + supporting patterns |
| 16-20 | Complex | Multiple patterns, iterative approach |
| 21-25 | Highly Complex | Custom pattern combination, phased execution |

## Pattern Selection Logic

### Selection Framework

```javascript
const patternSelector = {
  analyzeTask: (request) => {
    // Step 1: Extract task characteristics
    const characteristics = {
      domain: identifyDomain(request),        // UI, UX, Brand, System
      action: identifyAction(request),        // Create, Analyze, Optimize, Audit
      scope: identifyScope(request),          // Component, Page, Flow, System
      constraints: identifyConstraints(request)
    };
    
    // Step 2: Calculate complexity
    const complexity = complexityAnalysis.calculateScore(characteristics);
    
    // Step 3: Select patterns
    return selectPatterns(characteristics, complexity);
  },
  
  selectPatterns: (characteristics, complexity) => {
    if (complexity.category === 'Simple') {
      return selectSinglePattern(characteristics);
    } else if (complexity.category === 'Moderate') {
      return selectPrimaryAndSupporting(characteristics);
    } else {
      return createCustomCombination(characteristics, complexity);
    }
  }
};
```

### Pattern Compatibility Matrix

```javascript
const patternCompatibility = {
  // Primary patterns that work well together
  compatible: {
    'PASE': ['OBSERVE-EXTRACT-SYNTHESIZE', 'EMPATHIZE-IDENTIFY-TRANSLATE'],
    'ESTABLISH-STRUCTURE-DOCUMENT': ['CONSIDER-EXPLORE-REFINE'],
    'UNDERSTAND-IMAGINE-ALIGN': ['EVALUATE-PRIORITIZE-RECOMMEND']
  },
  
  // Patterns that should not be combined
  incompatible: {
    'rapid-iteration': ['deep-analysis'],
    'user-research': ['technical-implementation']
  },
  
  // Synergistic combinations
  synergistic: {
    'brand-strategy + visual-design': 'Enhanced creative coherence',
    'user-research + accessibility': 'Inclusive design approach',
    'systematic-analysis + rapid-generation': 'Efficient exploration'
  }
};
```

## Dynamic Pattern Adaptation

### Adaptive Reasoning Strategies

#### 1. Simple Tasks (Score: 5-8)
```
*Meta-reasoning: This is a straightforward request with clear parameters.*

Selected Pattern: [Single appropriate pattern]
Execution: Direct application with standard steps
Reflection: Brief quality check
```

#### 2. Moderate Tasks (Score: 9-15)
```
*Meta-reasoning: This requires coordination between multiple aspects.*

Primary Pattern: [Main cognitive framework]
Supporting Patterns: [1-2 complementary patterns]
Execution: Staged approach with checkpoints
Reflection: Pattern effectiveness evaluation
```

#### 3. Complex Tasks (Score: 16-20)
```
*Meta-reasoning: This needs sophisticated multi-pattern orchestration.*

Pattern Combination:
- Discovery Phase: [Research patterns]
- Synthesis Phase: [Analysis patterns]
- Creation Phase: [Generation patterns]
- Validation Phase: [Evaluation patterns]

Execution: Iterative with continuous adaptation
Reflection: Comprehensive pattern performance analysis
```

#### 4. Highly Complex Tasks (Score: 21-25)
```
*Meta-reasoning: This requires custom cognitive architecture.*

Custom Framework:
1. Decompose into sub-problems
2. Assign optimal patterns per sub-problem
3. Define integration points
4. Create feedback loops
5. Implement progressive refinement

Execution: Phased with dynamic adjustment
Reflection: System-wide optimization analysis
```

## Pattern Combination Strategies

### Sequential Combination
```javascript
const sequentialCombination = {
  research_then_create: [
    'EMPATHIZE-IDENTIFY-TRANSLATE',  // Understand users
    'OBSERVE-EXTRACT-SYNTHESIZE',     // Analyze patterns
    'CONSIDER-EXPLORE-REFINE'          // Generate solutions
  ],
  
  analyze_then_optimize: [
    'EVALUATE-PRIORITIZE-RECOMMEND',  // Assess current state
    'PASE',                           // Deep reasoning
    'ESTABLISH-STRUCTURE-DOCUMENT'    // Systematic improvement
  ]
};
```

### Parallel Combination
```javascript
const parallelCombination = {
  multi_perspective: {
    user_view: 'EMPATHIZE-IDENTIFY-TRANSLATE',
    brand_view: 'UNDERSTAND-IMAGINE-ALIGN',
    technical_view: 'EVALUATE-PRIORITIZE-RECOMMEND'
  },
  
  merge_strategy: 'Synthesize insights from all perspectives'
};
```

### Nested Combination
```javascript
const nestedCombination = {
  outer: 'PASE',  // Overall framework
  inner: {
    ponder: 'OBSERVE-EXTRACT-SYNTHESIZE',
    analyze: 'EVALUATE-PRIORITIZE-RECOMMEND',
    synthesize: 'UNDERSTAND-IMAGINE-ALIGN',
    execute: 'CONSIDER-EXPLORE-REFINE'
  }
};
```

## Reasoning Adaptation Triggers

### When to Switch Patterns

```javascript
const adaptationTriggers = {
  unexpected_complexity: {
    signal: 'Task reveals hidden complexity',
    action: 'Upgrade to more sophisticated pattern'
  },
  
  insufficient_progress: {
    signal: 'Current pattern not yielding results',
    action: 'Switch to alternative approach'
  },
  
  new_constraints: {
    signal: 'Additional requirements emerge',
    action: 'Add complementary pattern'
  },
  
  breakthrough_insight: {
    signal: 'Discover simpler approach',
    action: 'Downgrade to simpler pattern'
  }
};
```

## Meta-Reasoning Execution

### Pre-Task Analysis
```
*Engaging meta-reasoning for task analysis...*

1. Task Classification:
   - Domain: [Identified domain]
   - Complexity Score: [Calculated score]
   - Key Challenges: [Listed challenges]

2. Pattern Selection:
   - Primary: [Selected pattern with rationale]
   - Supporting: [Additional patterns if needed]
   - Combination Strategy: [How patterns will work together]

3. Execution Plan:
   - Phases: [Breakdown of approach]
   - Checkpoints: [Where to evaluate progress]
   - Adaptation Points: [Where pattern changes might occur]
```

### Mid-Task Adaptation
```
*Meta-reasoning checkpoint: Evaluating approach effectiveness...*

Current Progress:
- Pattern Performance: [1-5 rating]
- Unexpected Elements: [New discoveries]
- Adaptation Needed: [Yes/No with rationale]

Adjustment Decision:
[Continue with current pattern / Switch to alternative / Add supporting pattern]
```

### Post-Task Learning
```
*Meta-reasoning reflection: Capturing learning for future tasks...*

Pattern Effectiveness:
- Selected Patterns: [List with performance ratings]
- Combination Success: [How well patterns worked together]
- Optimal Approach: [What would work best in hindsight]

Knowledge Update:
- New Pattern Combinations Discovered: [Document successful combinations]
- Complexity Assessment Accuracy: [Was initial assessment correct?]
- Improvement Recommendations: [For similar future tasks]
```

## Integration with Existing Patterns

### Enhancement Instructions
Each existing reasoning pattern in `reasoning-patterns.md` should be enhanced with:

1. **Complexity Rating**: When this pattern works best (simple/moderate/complex)
2. **Combination Compatibility**: Which patterns it works well with
3. **Adaptation Hooks**: Points where the pattern can be modified or switched

### Dynamic Invocation
```javascript
// Instead of static pattern selection:
// "I'll use the PASE method for this task"

// Dynamic selection:
const selectedApproach = metaReasoning.selectOptimalPattern(task);
console.log(`*Meta-reasoning: Based on complexity analysis (score: ${selectedApproach.complexity}), 
             I'll use ${selectedApproach.pattern} with ${selectedApproach.adaptations}*`);
```

## Practical Examples

### Example 1: Simple Component Request
```
User: "Create a button component"

*Meta-reasoning: Simple task (score: 6) - single component, clear requirements*
Selected Pattern: CONSIDER-EXPLORE-REFINE
Execution: Direct generation with standard variations
```

### Example 2: Complex System Design
```
User: "Design a complete e-commerce checkout flow with international support"

*Meta-reasoning: Complex task (score: 18) - multiple systems, many constraints*
Pattern Combination:
- Research: EMPATHIZE-IDENTIFY-TRANSLATE (user needs)
- Analysis: EVALUATE-PRIORITIZE-RECOMMEND (payment systems)
- Design: PASE (systematic approach)
- Validation: OBSERVE-EXTRACT-SYNTHESIZE (pattern checking)
```

### Example 3: Novel Challenge
```
User: "Create an AI-powered design system that adapts to user emotions"

*Meta-reasoning: Highly complex task (score: 23) - novel concept, high uncertainty*
Custom Framework:
1. Exploration Phase: Combined research patterns
2. Conceptualization: Creative pattern fusion
3. Prototyping: Rapid iteration patterns
4. Validation: Multi-perspective evaluation
```

## Continuous Improvement

### Pattern Performance Tracking
```javascript
const patternMetrics = {
  trackPerformance: (pattern, task, outcome) => {
    return {
      pattern: pattern,
      taskType: task.type,
      complexity: task.complexity,
      successRate: outcome.success,
      completionTime: outcome.duration,
      userSatisfaction: outcome.feedback
    };
  },
  
  optimizeSelection: (historicalData) => {
    // Use performance data to improve future selections
    return analyzePatterns(historicalData);
  }
};
```

### Learning Integration
- Document successful pattern combinations
- Update complexity scoring based on outcomes
- Refine compatibility matrix with experience
- Share insights across the agent network

---

*Meta-Reasoning Selector v1.0 | Dynamic pattern adaptation | Cognitive flexibility framework*