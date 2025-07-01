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
    // Check pattern health before selection
    const healthCheck = patternLifecycle.checkHealth(availablePatterns);
    const healthyPatterns = healthCheck.filter(p => p.status !== 'deprecated');
    
    if (complexity.category === 'Simple') {
      return selectSinglePattern(characteristics, healthyPatterns);
    } else if (complexity.category === 'Moderate') {
      return selectPrimaryAndSupporting(characteristics, healthyPatterns);
    } else {
      // Check if we need adaptive pattern generation
      const existingPatterns = findSuitablePatterns(characteristics, healthyPatterns);
      
      if (existingPatterns.length === 0 || existingPatterns[0].fitness < 0.7) {
        // No suitable pattern exists, generate new one
        const newPattern = adaptivePatternGeneration.create({
          task: characteristics,
          complexity: complexity,
          context: getCurrentContext()
        });
        
        // Register new pattern in lifecycle
        patternLifecycle.register(newPattern);
        
        return [newPattern];
      }
      
      return createCustomCombination(characteristics, complexity, healthyPatterns);
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

## Pattern Performance Tracking & Metrics

### Advanced Performance Monitoring
```javascript
const performanceTracker = {
  // Real-time metrics collection
  metrics: {
    executionTime: new Map(),      // Pattern -> avg time in ms
    successRate: new Map(),        // Pattern -> success percentage
    resourceUsage: new Map(),      // Pattern -> memory/CPU usage
    userSatisfaction: new Map(),   // Pattern -> satisfaction score
    errorRate: new Map(),          // Pattern -> error frequency
    cacheHitRate: new Map()        // Pattern -> cache effectiveness
  },
  
  // Detailed tracking system
  trackExecution: async (pattern, task, execution) => {
    const startTime = performance.now();
    const startMemory = process.memoryUsage();
    
    try {
      const result = await execution();
      const endTime = performance.now();
      const endMemory = process.memoryUsage();
      
      return {
        pattern: pattern,
        taskId: task.id,
        metrics: {
          duration: endTime - startTime,
          memoryDelta: endMemory.heapUsed - startMemory.heapUsed,
          success: true,
          timestamp: Date.now(),
          complexity: task.complexity,
          cacheHits: result.cacheHits || 0,
          patternSwitches: result.patternSwitches || 0
        }
      };
    } catch (error) {
      trackError(pattern, error);
      throw error;
    }
  },
  
  // Performance scoring algorithm
  calculatePatternScore: (pattern) => {
    const weights = {
      speed: 0.3,
      success: 0.3,
      efficiency: 0.2,
      satisfaction: 0.2
    };
    
    const metrics = {
      speed: 1 / (performanceTracker.metrics.executionTime.get(pattern) || 1000),
      success: performanceTracker.metrics.successRate.get(pattern) || 0,
      efficiency: performanceTracker.metrics.cacheHitRate.get(pattern) || 0,
      satisfaction: performanceTracker.metrics.userSatisfaction.get(pattern) || 0
    };
    
    return Object.entries(weights).reduce((score, [metric, weight]) => 
      score + (metrics[metric] * weight), 0
    );
  }
};
```

### Performance Thresholds & Alerts
```javascript
const performanceThresholds = {
  critical: {
    executionTime: 5000,    // 5 seconds
    errorRate: 0.1,         // 10% error rate
    memoryUsage: 500 * 1024 * 1024  // 500MB
  },
  
  warning: {
    executionTime: 2000,    // 2 seconds
    errorRate: 0.05,        // 5% error rate
    memoryUsage: 200 * 1024 * 1024  // 200MB
  },
  
  checkThresholds: (pattern, metrics) => {
    const alerts = [];
    
    if (metrics.duration > performanceThresholds.critical.executionTime) {
      alerts.push({
        level: 'critical',
        message: `Pattern ${pattern} execution time ${metrics.duration}ms exceeds critical threshold`
      });
    }
    
    return alerts;
  }
};
```

## Optimization Strategies for Large Pattern Libraries

### Pattern Indexing System
```javascript
const patternIndex = {
  // Multi-dimensional index for fast lookup
  indexes: {
    byDomain: new Map(),        // domain -> Set<patterns>
    byComplexity: new Map(),    // complexity -> Set<patterns>
    byCompatibility: new Map(),  // pattern -> Set<compatible patterns>
    byPerformance: [],          // Sorted array by performance score
    byFrequency: new Map(),     // pattern -> usage count
    byTags: new Map()           // tag -> Set<patterns>
  },
  
  // Build indexes on initialization
  buildIndexes: (patterns) => {
    patterns.forEach(pattern => {
      // Index by domain
      pattern.domains.forEach(domain => {
        if (!patternIndex.indexes.byDomain.has(domain)) {
          patternIndex.indexes.byDomain.set(domain, new Set());
        }
        patternIndex.indexes.byDomain.get(domain).add(pattern.id);
      });
      
      // Index by complexity
      const complexityBucket = Math.floor(pattern.complexity / 5) * 5;
      if (!patternIndex.indexes.byComplexity.has(complexityBucket)) {
        patternIndex.indexes.byComplexity.set(complexityBucket, new Set());
      }
      patternIndex.indexes.byComplexity.get(complexityBucket).add(pattern.id);
      
      // Index by tags for semantic search
      pattern.tags.forEach(tag => {
        if (!patternIndex.indexes.byTags.has(tag)) {
          patternIndex.indexes.byTags.set(tag, new Set());
        }
        patternIndex.indexes.byTags.get(tag).add(pattern.id);
      });
    });
    
    // Sort by performance
    patternIndex.indexes.byPerformance = patterns
      .sort((a, b) => performanceTracker.calculatePatternScore(b.id) - 
                      performanceTracker.calculatePatternScore(a.id))
      .map(p => p.id);
  },
  
  // Update indexes incrementally
  updateIndex: (pattern, metric, value) => {
    if (metric === 'performance') {
      // Re-sort performance index using binary search insertion
      const score = performanceTracker.calculatePatternScore(pattern);
      const index = binarySearchPosition(patternIndex.indexes.byPerformance, score);
      patternIndex.indexes.byPerformance.splice(index, 0, pattern);
    }
  }
};
```

### Fast Pattern Selection Algorithm
```javascript
const optimizedPatternSelector = {
  // Cache for recent selections
  selectionCache: new LRUCache(1000),
  
  // Bloom filter for quick negative lookups
  bloomFilter: new BloomFilter(10000, 4),
  
  // Optimized selection with O(log n) complexity
  selectPattern: (task) => {
    // Check cache first
    const cacheKey = generateTaskFingerprint(task);
    if (selectionCache.has(cacheKey)) {
      return selectionCache.get(cacheKey);
    }
    
    // Use indexes for fast filtering
    const candidates = new Set();
    
    // 1. Filter by domain (O(1) lookup)
    const domainPatterns = patternIndex.indexes.byDomain.get(task.domain) || new Set();
    
    // 2. Filter by complexity range (O(1) lookup)
    const complexityBucket = Math.floor(task.complexity / 5) * 5;
    const complexityPatterns = new Set([
      ...(patternIndex.indexes.byComplexity.get(complexityBucket) || []),
      ...(patternIndex.indexes.byComplexity.get(complexityBucket - 5) || []),
      ...(patternIndex.indexes.byComplexity.get(complexityBucket + 5) || [])
    ]);
    
    // 3. Intersection of filters
    for (const pattern of domainPatterns) {
      if (complexityPatterns.has(pattern)) {
        candidates.add(pattern);
      }
    }
    
    // 4. Score and rank candidates
    const scored = Array.from(candidates)
      .map(pattern => ({
        pattern,
        score: calculatePatternFitScore(pattern, task)
      }))
      .sort((a, b) => b.score - a.score);
    
    // 5. Select top candidate(s)
    const selected = scored.slice(0, task.complexity > 15 ? 3 : 1)
      .map(s => s.pattern);
    
    // Cache the result
    selectionCache.set(cacheKey, selected);
    
    return selected;
  }
};
```

### Pattern Search Capabilities
```javascript
const patternSearch = {
  // Trie for prefix search
  trie: new PatternTrie(),
  
  // Inverted index for full-text search
  invertedIndex: new Map(),
  
  // Vector embeddings for semantic search
  embeddings: new Map(),
  
  // Multi-modal search interface
  search: (query, options = {}) => {
    const results = {
      exact: [],
      fuzzy: [],
      semantic: []
    };
    
    // 1. Exact match using hash lookup
    if (patternSearch.bloomFilter.has(query)) {
      results.exact = patternSearch.findExactMatches(query);
    }
    
    // 2. Prefix search using trie
    if (options.prefix) {
      results.fuzzy = patternSearch.trie.search(query);
    }
    
    // 3. Semantic search using embeddings
    if (options.semantic) {
      const queryEmbedding = generateEmbedding(query);
      results.semantic = patternSearch.findSimilarByEmbedding(queryEmbedding, options.threshold || 0.8);
    }
    
    // 4. Tag-based search
    if (options.tags) {
      const tagResults = query.split(' ')
        .map(tag => patternIndex.indexes.byTags.get(tag) || new Set())
        .reduce((acc, set) => new Set([...acc, ...set]));
      results.tags = Array.from(tagResults);
    }
    
    // Merge and rank results
    return rankSearchResults(results, query);
  },
  
  // Efficient similarity search
  findSimilarByEmbedding: (embedding, threshold) => {
    const similarities = [];
    
    // Use approximate nearest neighbor for large datasets
    if (patternSearch.embeddings.size > 1000) {
      return patternSearch.annIndex.search(embedding, 10);
    }
    
    // Exact search for smaller datasets
    for (const [pattern, patternEmbedding] of patternSearch.embeddings) {
      const similarity = cosineSimilarity(embedding, patternEmbedding);
      if (similarity >= threshold) {
        similarities.push({ pattern, similarity });
      }
    }
    
    return similarities
      .sort((a, b) => b.similarity - a.similarity)
      .slice(0, 10);
  }
};
```

### Memory-Efficient Pattern Storage
```javascript
const patternStorage = {
  // Lazy loading for large pattern libraries
  lazyLoad: {
    loaded: new Set(),
    loading: new Map(),
    
    getPattern: async (patternId) => {
      if (patternStorage.lazyLoad.loaded.has(patternId)) {
        return patternCache.get(patternId);
      }
      
      if (patternStorage.lazyLoad.loading.has(patternId)) {
        return patternStorage.lazyLoad.loading.get(patternId);
      }
      
      const loadPromise = loadPatternFromDisk(patternId);
      patternStorage.lazyLoad.loading.set(patternId, loadPromise);
      
      const pattern = await loadPromise;
      patternCache.set(patternId, pattern);
      patternStorage.lazyLoad.loaded.add(patternId);
      patternStorage.lazyLoad.loading.delete(patternId);
      
      return pattern;
    }
  },
  
  // Pattern compression for memory efficiency
  compress: (pattern) => {
    return {
      id: pattern.id,
      metadata: pattern.metadata,
      compressedContent: zlib.gzipSync(JSON.stringify(pattern.content))
    };
  },
  
  decompress: (compressed) => {
    return {
      ...compressed,
      content: JSON.parse(zlib.gunzipSync(compressed.compressedContent))
    };
  }
};
```

### Distributed Pattern Management
```javascript
const distributedPatterns = {
  // Sharding for horizontal scaling
  shards: new Map(),
  
  getShardForPattern: (patternId) => {
    const hash = createHash('md5').update(patternId).digest('hex');
    const shardIndex = parseInt(hash.substring(0, 2), 16) % distributedPatterns.shards.size;
    return Array.from(distributedPatterns.shards.values())[shardIndex];
  },
  
  // Pattern replication for high availability
  replicationFactor: 3,
  
  replicatePattern: async (pattern) => {
    const primaryShard = distributedPatterns.getShardForPattern(pattern.id);
    const replicas = selectReplicaShards(primaryShard, distributedPatterns.replicationFactor - 1);
    
    await Promise.all([
      primaryShard.store(pattern),
      ...replicas.map(shard => shard.storeReplica(pattern))
    ]);
  }
};
```

## Continuous Improvement

### Adaptive Learning System
```javascript
const adaptiveLearning = {
  // Machine learning model for pattern selection
  model: {
    predict: (taskFeatures) => {
      // Use historical data to predict best pattern
      return mlModel.predict(taskFeatures);
    },
    
    update: (taskFeatures, selectedPattern, outcome) => {
      // Update model with new data point
      mlModel.train({
        input: taskFeatures,
        output: { pattern: selectedPattern, success: outcome }
      });
    }
  },
  
  // A/B testing for pattern effectiveness
  abTesting: {
    experiments: new Map(),
    
    selectVariant: (task) => {
      const experiment = findActiveExperiment(task.type);
      if (!experiment) return null;
      
      // Use epsilon-greedy strategy
      if (Math.random() < 0.1) {
        return experiment.variants[Math.floor(Math.random() * experiment.variants.length)];
      }
      
      return experiment.variants.reduce((best, variant) => 
        variant.performance > best.performance ? variant : best
      );
    }
  },
  
  // Pattern evolution tracking
  evolution: {
    track: (pattern, performance) => {
      // Update pattern lifecycle
      patternLifecycle.updateMetrics(pattern.id, performance);
      
      // Check if pattern needs evolution
      if (performance.score < 0.6) {
        const evolved = adaptivePatternGeneration.evolve(pattern, performance.feedback);
        patternLifecycle.registerEvolution(pattern.id, evolved.id);
        return evolved;
      }
      
      return pattern;
    }
  }
};
```

### Learning Integration
- Document successful pattern combinations with detailed metrics
- Update complexity scoring based on outcomes using regression analysis
- Refine compatibility matrix with experience using collaborative filtering
- Share insights across the agent network using federated learning
- Implement automated pattern discovery from successful executions
- Use reinforcement learning for continuous optimization

## Integration with Adaptive Pattern Generation

### Pattern Creation Triggers
```javascript
const patternCreationTriggers = {
  conditions: [
    "No existing pattern matches task requirements (fitness < 0.7)",
    "Task complexity exceeds current pattern capabilities",
    "Novel domain or problem type detected",
    "User explicitly requests new approach"
  ],
  
  evaluate: (task) => {
    const triggers = {
      noMatch: !findSuitablePattern(task),
      tooComplex: task.complexity > maxPatternComplexity,
      novelDomain: !domainPatterns.has(task.domain),
      userRequest: task.metadata?.requestNewApproach
    };
    
    return Object.values(triggers).some(triggered => triggered);
  }
};
```

## Integration with Pattern Lifecycle Management

### Health-Aware Selection
```javascript
const healthAwareSelection = {
  preFilter: (patterns) => {
    return patterns.filter(pattern => {
      const health = patternLifecycle.getHealth(pattern.id);
      return health.status === 'healthy' || 
             (health.status === 'evolving' && health.reliability > 0.8);
    });
  },
  
  considerEvolution: (pattern) => {
    const lifecycle = patternLifecycle.getLifecycleStage(pattern.id);
    
    if (lifecycle.stage === 'mature' && lifecycle.evolutionReady) {
      // Pattern is ready for evolution
      return {
        usePattern: pattern,
        scheduleEvolution: true,
        evolutionPriority: lifecycle.evolutionUrgency
      };
    }
    
    return { usePattern: pattern, scheduleEvolution: false };
  }
};
```

---

*Meta-Reasoning Selector v1.0 | Dynamic pattern adaptation | Cognitive flexibility framework*