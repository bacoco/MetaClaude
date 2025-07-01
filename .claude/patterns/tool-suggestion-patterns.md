# Tool Suggestion Patterns

Proactive tool recommendation framework that detects missed opportunities and suggests optimal tool usage without being intrusive.

## Overview

This pattern framework monitors internal reasoning processes to identify when conceptual operations could be replaced with concrete tool usage. It provides intelligent, context-aware suggestions that enhance efficiency while maintaining a natural conversational flow.

## Core Detection Algorithms

### Missed Opportunity Detection

```javascript
const missedOpportunityDetector = {
  patterns: {
    // Pattern: Describing file content instead of reading it
    fileContentGuessing: {
      triggers: [
        /(?:probably|likely|might|should)\s+(?:contain|have|include)/i,
        /(?:assuming|expect|imagine)\s+the\s+file/i,
        /typical(?:ly)?\s+(?:this|these)\s+file(?:s)?/i,
        /standard\s+(?:structure|format|content)/i
      ],
      detection: (reasoning) => {
        return {
          matched: patterns.some(p => p.test(reasoning)),
          suggestion: "I notice I'm making assumptions about file content. Let me read the actual file to ensure accuracy.",
          tool: "read_file",
          priority: "high"
        };
      }
    },

    // Pattern: Manually iterating when batch operations exist
    inefficientIteration: {
      triggers: [
        /for\s+each\s+(?:file|component|item)/i,
        /(?:first|then|next)\s+I(?:'ll|ll|will)\s+(?:create|write|save)/i,
        /one\s+by\s+one/i,
        /(?:multiple|several)\s+similar\s+(?:files|operations)/i
      ],
      detection: (reasoning) => {
        return {
          matched: patterns.some(p => p.test(reasoning)),
          suggestion: "I could use batch operations to handle multiple files more efficiently.",
          tool: "batch_write_files",
          priority: "medium"
        };
      }
    },

    // Pattern: Describing search process instead of using search tool
    manualSearching: {
      triggers: [
        /look(?:ing)?\s+for\s+(?:patterns|instances|occurrences)/i,
        /find(?:ing)?\s+(?:all|where|instances)/i,
        /search(?:ing)?\s+(?:through|across|in)/i,
        /scan(?:ning)?\s+(?:the|for|through)\s+(?:code|files)/i
      ],
      detection: (reasoning) => {
        return {
          matched: patterns.some(p => p.test(reasoning)),
          suggestion: "I should use the search tool to find these patterns systematically.",
          tool: "search_file_content",
          priority: "high"
        };
      }
    },

    // Pattern: Imagining project structure
    structureAssumptions: {
      triggers: [
        /typical\s+(?:project|folder)\s+structure/i,
        /(?:probably|likely)\s+organized\s+(?:as|like)/i,
        /standard\s+(?:layout|organization)/i,
        /(?:assume|expect)\s+(?:src|components|lib)\s+folder/i
      ],
      detection: (reasoning) => {
        return {
          matched: patterns.some(p => p.test(reasoning)),
          suggestion: "Let me check the actual project structure instead of assuming.",
          tool: "list_files",
          priority: "high"
        };
      }
    },

    // Pattern: Mental calculations that could use system tools
    internalProcessing: {
      triggers: [
        /calculat(?:e|ing)\s+(?:dependencies|requirements)/i,
        /determin(?:e|ing)\s+(?:compatibility|versions)/i,
        /check(?:ing)?\s+if\s+(?:installed|available)/i,
        /verify(?:ing)?\s+(?:setup|configuration)/i
      ],
      detection: (reasoning) => {
        return {
          matched: patterns.some(p => p.test(reasoning)),
          suggestion: "I can verify this directly using system commands.",
          tool: "run_shell_command",
          priority: "medium"
        };
      }
    }
  },

  analyze: function(internalReasoning) {
    const detectedOpportunities = [];
    
    for (const [patternName, pattern] of Object.entries(this.patterns)) {
      const result = pattern.detection(internalReasoning);
      if (result.matched) {
        detectedOpportunities.push({
          pattern: patternName,
          ...result
        });
      }
    }
    
    return detectedOpportunities.sort((a, b) => 
      this.priorityWeight[b.priority] - this.priorityWeight[a.priority]
    );
  },

  priorityWeight: {
    high: 3,
    medium: 2,
    low: 1
  }
};
```

### Task-Tool Pattern Matching

```javascript
const taskToolMatcher = {
  // Map common task patterns to appropriate tools
  taskPatterns: {
    fileAnalysis: {
      keywords: ['analyze', 'review', 'examine', 'inspect', 'understand'],
      context: ['file', 'component', 'code', 'implementation'],
      suggestedTools: ['read_file', 'search_file_content'],
      confidence: 0.9
    },

    contentGeneration: {
      keywords: ['create', 'generate', 'build', 'design', 'implement'],
      context: ['component', 'file', 'configuration', 'system'],
      suggestedTools: ['write_file'],
      confidence: 0.85
    },

    systemOperation: {
      keywords: ['install', 'run', 'execute', 'build', 'test', 'deploy'],
      context: ['package', 'command', 'script', 'process'],
      suggestedTools: ['run_shell_command'],
      confidence: 0.95
    },

    projectExploration: {
      keywords: ['explore', 'discover', 'map', 'understand', 'navigate'],
      context: ['structure', 'organization', 'layout', 'architecture'],
      suggestedTools: ['list_files', 'search_file_content'],
      confidence: 0.8
    }
  },

  match: function(userRequest) {
    const matches = [];
    
    for (const [taskType, pattern] of Object.entries(this.taskPatterns)) {
      const keywordMatch = pattern.keywords.some(kw => 
        userRequest.toLowerCase().includes(kw)
      );
      const contextMatch = pattern.context.some(ctx => 
        userRequest.toLowerCase().includes(ctx)
      );
      
      if (keywordMatch && contextMatch) {
        matches.push({
          taskType,
          tools: pattern.suggestedTools,
          confidence: pattern.confidence,
          suggestion: this.generateSuggestion(taskType, pattern.suggestedTools)
        });
      }
    }
    
    return matches.sort((a, b) => b.confidence - a.confidence);
  },

  generateSuggestion: function(taskType, tools) {
    const suggestions = {
      fileAnalysis: `I'll use ${tools.join(' and ')} to examine the actual implementation.`,
      contentGeneration: `After generating the content, I'll save it using ${tools[0]}.`,
      systemOperation: `I'll execute this using ${tools[0]} for direct system feedback.`,
      projectExploration: `Let me explore the project structure using ${tools.join(' and ')}.`
    };
    
    return suggestions[taskType];
  }
};
```

## Explicit Tool Mapping

### Comprehensive Detection Pattern to Tool Mapping

| Detection Pattern | Trigger Keywords | Suggested Tool | Priority | Example Usage | Alternative Approach |
|-------------------|------------------|----------------|----------|---------------|---------------------|
| File Content Assumptions | "probably contains", "likely has", "should include" | `read_file()` | High | `read_file("config.json")` | None - always read |
| Manual Iteration | "for each file", "one by one", "then next" | `batch_operations()` | Medium | `batch_write_files(fileList)` | Sequential if dependencies |
| Structure Guessing | "typical structure", "probably organized" | `list_files()` | High | `list_files("./src")` | None - always check |
| Content Search | "looking for", "find instances", "search through" | `search_file_content()` | High | `search_file_content("pattern", "*.js")` | `grep` via shell |
| System Verification | "check if installed", "verify setup" | `run_shell_command()` | Medium | `run_shell_command("npm -v")` | Parse package files |
| File Existence | "if file exists", "check for file" | `list_files()` | High | `list_files("./").includes("file.md")` | None |
| Content Analysis | "analyze code", "review implementation" | `read_file()` → analyze | High | Read then process | None |
| Bulk Updates | "update all", "modify every" | `batch_edit_files()` | High | `batch_edit_files(edits)` | Loop with edit_file |
| Performance Check | "measure time", "check speed" | `run_shell_command()` | Low | `run_shell_command("time command")` | Internal timing |
| Dependency Check | "required packages", "missing imports" | `read_file()` + `run_shell_command()` | Medium | Check package.json + npm | Parse only |

### Context-Specific Tool Selection

| Context | Default Tool Choice | When to Override |
|---------|-------------------|------------------|
| Initial project exploration | `list_files()` → `read_file("README.md")` | If specific entry point known |
| Code modification | `read_file()` → `edit_file()` | `write_file()` for new files |
| Validation | `run_shell_command("npm test")` | Internal validation for simple checks |
| Search operations | `search_file_content()` | `read_file()` if single file |
| Batch operations | Batch variants of tools | Individual tools if < 3 items |

### Tool Combination Patterns

| Scenario | Tool Sequence | Purpose |
|----------|---------------|---------|
| Safe file update | `read_file()` → verify → `edit_file()` | Prevent overwrites |
| Project analysis | `list_files()` → `read_file(multiple)` → analyze | Complete understanding |
| Refactoring | `search_file_content()` → `batch_edit_files()` | Systematic changes |
| Deployment prep | `run_shell_command("build")` → `list_files("dist")` | Verify output |
| Debug investigation | `read_file()` → `search_file_content()` → `run_shell_command()` | Multi-angle analysis |

### Confidence-Based Tool Suggestions

| Confidence Level | Suggestion Approach | Example |
|-----------------|---------------------|----------|
| 🟢 High (>0.8) | Direct recommendation | "I'll use `read_file()` to check the actual content" |
| 🟡 Medium (0.5-0.8) | Gentle suggestion | "It might be more efficient to use `batch_operations()`" |
| 🟠 Low (0.3-0.5) | Optional mention | "Consider using `search_file_content()` if looking for patterns" |
| 🔴 Very Low (<0.3) | No suggestion | Continue with current approach |

## Self-Correction Mechanisms

### Real-Time Correction

```javascript
const selfCorrectionEngine = {
  // Monitor ongoing responses for correction opportunities
  monitors: {
    assumptionDetector: {
      check: (response) => {
        const assumptionPhrases = [
          'I assume', 'probably', 'typically', 'usually', 'should be',
          'might be', 'likely', 'standard practice', 'common pattern'
        ];
        
        return assumptionPhrases.some(phrase => 
          response.toLowerCase().includes(phrase)
        );
      },
      
      correct: (context) => {
        return {
          detection: "I'm making an assumption that I could verify.",
          action: "Let me check this directly instead of assuming.",
          tool: this.selectVerificationTool(context)
        };
      }
    },

    inefficiencyDetector: {
      check: (actions) => {
        // Detect repeated similar operations
        const similarOps = this.findSimilarOperations(actions);
        return similarOps.length > 2;
      },
      
      correct: (actions) => {
        return {
          detection: "I'm performing similar operations repeatedly.",
          action: "I should batch these operations for efficiency.",
          tool: this.selectBatchTool(actions)
        };
      }
    },

    accuracyGuard: {
      check: (statement) => {
        const uncertainPhrases = [
          'if I recall correctly', 'from what I remember',
          'based on common patterns', 'in most cases'
        ];
        
        return uncertainPhrases.some(phrase => 
          statement.toLowerCase().includes(phrase)
        );
      },
      
      correct: () => {
        return {
          detection: "I'm relying on general knowledge instead of specific data.",
          action: "Let me verify this with actual project information.",
          tool: "read_file or search_file_content"
        };
      }
    }
  },

  applyCorrections: function(response, context) {
    let correctedResponse = response;
    const corrections = [];
    
    for (const [name, monitor] of Object.entries(this.monitors)) {
      if (monitor.check(response)) {
        const correction = monitor.correct(context);
        corrections.push(correction);
      }
    }
    
    return { correctedResponse, corrections };
  }
};
```

### Proactive Intervention

```javascript
const proactiveInterventions = {
  // Intervention strategies that maintain conversational flow
  strategies: {
    gentle: {
      template: "I notice {observation}. Would it be helpful if I {action}?",
      threshold: 0.6
    },
    
    informative: {
      template: "I could {action} to {benefit}. Shall I do that?",
      threshold: 0.7
    },
    
    efficient: {
      template: "Actually, let me {action} - it'll be more accurate.",
      threshold: 0.8
    },
    
    corrective: {
      template: "Wait, I should {action} instead of {current}. Let me do that.",
      threshold: 0.9
    }
  },

  selectIntervention: function(confidence, context) {
    // Choose intervention based on confidence and context
    if (confidence >= 0.9) return this.strategies.corrective;
    if (confidence >= 0.8) return this.strategies.efficient;
    if (confidence >= 0.7) return this.strategies.informative;
    return this.strategies.gentle;
  },

  craft: function(observation, suggestedAction, benefit, confidence) {
    const strategy = this.selectIntervention(confidence);
    
    return strategy.template
      .replace('{observation}', observation)
      .replace('{action}', suggestedAction)
      .replace('{benefit}', benefit)
      .replace('{current}', 'making assumptions');
  }
};
```

## Learning and Adaptation

### Usage Pattern Learning

```javascript
const patternLearning = {
  // Track and learn from tool usage patterns
  usageHistory: {
    recordUsage: function(context, toolUsed, outcome) {
      return {
        timestamp: Date.now(),
        context: {
          userRequest: context.request,
          taskType: context.taskType,
          complexity: context.complexity
        },
        tool: toolUsed,
        outcome: {
          success: outcome.success,
          efficiency: outcome.efficiency,
          userSatisfaction: outcome.satisfaction
        }
      };
    },
    
    analyzePatterns: function(history) {
      // Identify successful patterns
      const successfulPatterns = history.filter(h => 
        h.outcome.success && h.outcome.efficiency > 0.8
      );
      
      // Extract common contexts
      const contextClusters = this.clusterByContext(successfulPatterns);
      
      // Generate learned patterns
      return contextClusters.map(cluster => ({
        context: cluster.commonContext,
        preferredTool: cluster.mostUsedTool,
        confidence: cluster.successRate,
        conditions: cluster.conditions
      }));
    }
  },

  adaptiveThresholds: {
    // Adjust suggestion thresholds based on user feedback
    initial: {
      suggestionConfidence: 0.7,
      interventionFrequency: 0.3,
      correctionAggressiveness: 0.5
    },
    
    adjust: function(feedback) {
      if (feedback.tooIntrusive) {
        this.current.interventionFrequency *= 0.8;
        this.current.correctionAggressiveness *= 0.9;
      }
      
      if (feedback.missedOpportunities) {
        this.current.suggestionConfidence *= 0.9;
        this.current.interventionFrequency *= 1.1;
      }
      
      if (feedback.helpful) {
        // Gradually increase confidence in current settings
        this.current.suggestionConfidence = Math.min(
          this.current.suggestionConfidence * 1.05, 0.95
        );
      }
    }
  },

  contextualMemory: {
    // Remember user preferences per project/context
    store: function(projectContext, preferences) {
      return {
        project: projectContext,
        preferences: {
          prefersBatchOperations: preferences.batch,
          likesProactiveSuggestions: preferences.proactive,
          toolComfortLevel: preferences.toolExperience
        },
        lastUpdated: Date.now()
      };
    },
    
    retrieve: function(projectContext) {
      // Return stored preferences or defaults
      return this.memory[projectContext] || this.defaults;
    }
  }
};
```

## Integration with Reasoning Selector

### Reasoning-Tool Bridge

```javascript
const reasoningToolIntegration = {
  // Hook into reasoning-selector.md's pattern selection
  enhancePatternSelection: function(selectedPattern, taskAnalysis) {
    // Augment pattern with tool suggestions
    const toolOpportunities = this.identifyToolOpportunities(
      selectedPattern,
      taskAnalysis
    );
    
    return {
      ...selectedPattern,
      toolGuidance: {
        required: toolOpportunities.filter(t => t.priority === 'required'),
        recommended: toolOpportunities.filter(t => t.priority === 'recommended'),
        optional: toolOpportunities.filter(t => t.priority === 'optional')
      },
      toolCheckpoints: this.createToolCheckpoints(selectedPattern)
    };
  },

  createToolCheckpoints: function(pattern) {
    // Define points in the pattern where tool usage should be considered
    const checkpoints = {
      'PASE': {
        ponder: "Before pondering, check if data exists to read",
        analyze: "Use search tools for pattern analysis",
        synthesize: "Prepare file writes for synthesis outputs",
        execute: "Use system commands for execution"
      },
      'OBSERVE-EXTRACT-SYNTHESIZE': {
        observe: "Use read_file to observe actual content",
        extract: "Use search_file_content for pattern extraction",
        synthesize: "Prepare write_file for synthesis results"
      }
    };
    
    return checkpoints[pattern.name] || {};
  },

  injectToolAwareness: function(reasoning) {
    // Add tool-awareness to any reasoning pattern
    return {
      ...reasoning,
      toolCheck: async (step) => {
        const opportunities = missedOpportunityDetector.analyze(step);
        if (opportunities.length > 0) {
          return {
            suggestion: opportunities[0].suggestion,
            tool: opportunities[0].tool,
            integrate: true
          };
        }
        return null;
      }
    };
  }
};
```

### Meta-Reasoning Enhancement

```javascript
const metaReasoningEnhancement = {
  // Enhance meta-reasoning with tool awareness
  toolComplexityFactors: {
    // Additional complexity factors for tool decisions
    toolAvailability: {
      allToolsAvailable: 1,
      limitedTools: 3,
      noTools: 5
    },
    
    dataAccessibility: {
      directAccess: 1,
      requiresSearch: 3,
      requiresGeneration: 5
    },
    
    operationMode: {
      readOnly: 1,
      readWrite: 3,
      systemChanges: 5
    }
  },

  enhanceComplexityAnalysis: function(originalAnalysis) {
    return {
      ...originalAnalysis,
      toolFactors: this.assessToolFactors(),
      adjustedScore: this.calculateAdjustedScore(originalAnalysis),
      toolStrategy: this.determineToolStrategy(originalAnalysis)
    };
  },

  determineToolStrategy: function(analysis) {
    if (analysis.adjustedScore > 20) {
      return {
        approach: "tool-heavy",
        rationale: "Complex task requires extensive tool usage",
        checkpoints: "frequent",
        batching: "aggressive"
      };
    } else if (analysis.adjustedScore > 10) {
      return {
        approach: "tool-assisted",
        rationale: "Moderate complexity benefits from tool support",
        checkpoints: "periodic",
        batching: "opportunistic"
      };
    } else {
      return {
        approach: "tool-light",
        rationale: "Simple task with minimal tool requirements",
        checkpoints: "as-needed",
        batching: "minimal"
      };
    }
  }
};
```

## Practical Implementation Examples

### Example 1: File Analysis Suggestion

```javascript
// User: "Analyze the Button component and suggest improvements"

// Internal reasoning detection:
"Looking at typical Button component patterns..." // DETECTED!

// Proactive suggestion:
{
  intervention: "I notice I'm thinking about typical patterns. Let me read your actual Button component to give specific suggestions.",
  action: () => read_file("src/components/Button.jsx"),
  confidence: 0.9
}

// Natural flow:
"I'll analyze your Button component for improvements. Let me first read the current implementation...

*Reading src/components/Button.jsx...*

Now I can see your specific implementation. Based on your actual code, here are my suggestions..."
```

### Example 2: Batch Operation Detection

```javascript
// User: "Create header, footer, and sidebar components"

// Internal reasoning detection:
"First I'll create the header, then the footer..." // DETECTED!

// Proactive suggestion:
{
  intervention: "I'll create all three components efficiently using batch operations.",
  action: () => batchWriteFiles([
    { path: "Header.jsx", content: headerCode },
    { path: "Footer.jsx", content: footerCode },
    { path: "Sidebar.jsx", content: sidebarCode }
  ]),
  confidence: 0.85
}

// Natural flow:
"I'll create all three components for you. Since these are related layout components, I'll generate them with consistent patterns and save them all at once for efficiency."
```

### Example 3: Search Pattern Recognition

```javascript
// User: "Find all places where we're using inline styles"

// Internal reasoning detection:
"I would need to check each component..." // DETECTED!

// Proactive suggestion:
{
  intervention: "I'll search for inline style patterns across your entire codebase.",
  action: () => search_file_content('style={{', 'src/'),
  confidence: 0.95
}

// Natural flow:
"I'll search for all inline styles in your codebase. This will help us identify where styling improvements can be made.

*Searching for inline style patterns...*

I found 23 instances of inline styles across 8 files. Here's the breakdown..."
```

### Example 4: Assumption Correction

```javascript
// User: "Set up Tailwind CSS"

// Internal reasoning detection:
"Assuming you have a standard React setup..." // DETECTED!

// Self-correction:
{
  intervention: "Actually, let me check your project setup first to ensure compatibility.",
  action: () => [
    read_file("package.json"),
    list_files("./")
  ],
  confidence: 0.9
}

// Natural flow:
"I'll help you set up Tailwind CSS. First, let me check your current project configuration to ensure a smooth setup.

*Checking project structure and dependencies...*

I see you're using Next.js with TypeScript. I'll configure Tailwind with the appropriate settings for your setup."
```

## Configuration and Customization

### User Preference Profiles

```javascript
const userProfiles = {
  proactive: {
    suggestionThreshold: 0.6,
    interventionStyle: 'efficient',
    batchingPreference: 'aggressive',
    toolSuggestionFrequency: 'high'
  },
  
  balanced: {
    suggestionThreshold: 0.75,
    interventionStyle: 'informative',
    batchingPreference: 'moderate',
    toolSuggestionFrequency: 'medium'
  },
  
  minimal: {
    suggestionThreshold: 0.9,
    interventionStyle: 'gentle',
    batchingPreference: 'conservative',
    toolSuggestionFrequency: 'low'
  }
};
```

### Dynamic Adjustment

```javascript
const dynamicAdjustment = {
  // Adjust behavior based on user reactions
  signals: {
    positive: ['yes', 'sure', 'go ahead', 'perfect', 'thanks'],
    negative: ['no', 'skip', 'just show', "don't", 'unnecessary'],
    neutral: ['okay', 'fine', 'alright']
  },
  
  adjust: function(userResponse, currentProfile) {
    const sentiment = this.analyzeSentiment(userResponse);
    
    if (sentiment === 'positive') {
      // Gradually increase proactivity
      currentProfile.suggestionThreshold *= 0.95;
      currentProfile.toolSuggestionFrequency = this.increaseFrequency(
        currentProfile.toolSuggestionFrequency
      );
    } else if (sentiment === 'negative') {
      // Reduce intrusiveness
      currentProfile.suggestionThreshold *= 1.1;
      currentProfile.toolSuggestionFrequency = this.decreaseFrequency(
        currentProfile.toolSuggestionFrequency
      );
    }
    
    return currentProfile;
  }
};
```

## Performance Optimization

### Suggestion Caching

```javascript
const suggestionCache = {
  // Cache common patterns to reduce computation
  cache: new Map(),
  
  key: (context) => {
    return `${context.taskType}-${context.pattern}-${context.tools.join(',')}`;
  },
  
  get: function(context) {
    const key = this.key(context);
    if (this.cache.has(key)) {
      const cached = this.cache.get(key);
      if (Date.now() - cached.timestamp < 3600000) { // 1 hour
        return cached.suggestion;
      }
    }
    return null;
  },
  
  set: function(context, suggestion) {
    const key = this.key(context);
    this.cache.set(key, {
      suggestion,
      timestamp: Date.now()
    });
  }
};
```

### Batch Detection

```javascript
const batchDetection = {
  // Optimize detection for multiple operations
  detectBatchOpportunities: function(operations) {
    const groups = this.groupSimilarOperations(operations);
    
    return groups
      .filter(group => group.length >= 2)
      .map(group => ({
        operations: group,
        tool: this.selectBatchTool(group),
        benefit: this.calculateBenefit(group),
        suggestion: this.craftBatchSuggestion(group)
      }));
  },
  
  calculateBenefit: function(operations) {
    // Time saved = (individual time * count) - batch time
    const individualTime = operations.length * 100; // ms per operation
    const batchTime = 150; // ms for batch
    const saved = individualTime - batchTime;
    
    return {
      timeSaved: saved,
      efficiency: saved / individualTime,
      worthBatching: saved > 200 // 200ms threshold
    };
  }
};
```

## Monitoring and Analytics

### Effectiveness Tracking

```javascript
const effectivenessTracking = {
  metrics: {
    suggestionAcceptance: 0,
    toolUsageIncrease: 0,
    efficiencyImprovement: 0,
    userSatisfaction: 0
  },
  
  track: function(event) {
    if (event.type === 'suggestion_accepted') {
      this.metrics.suggestionAcceptance++;
      this.updateAcceptanceRate();
    }
    
    if (event.type === 'tool_used') {
      this.metrics.toolUsageIncrease++;
      this.calculateUsageGrowth();
    }
    
    if (event.type === 'task_completed') {
      this.metrics.efficiencyImprovement = 
        this.calculateEfficiency(event.duration, event.toolsUsed);
    }
  },
  
  generateReport: function() {
    return {
      acceptanceRate: this.metrics.suggestionAcceptance / this.totalSuggestions,
      toolUsageGrowth: this.metrics.toolUsageIncrease / this.baseline,
      averageEfficiencyGain: this.metrics.efficiencyImprovement,
      overallEffectiveness: this.calculateOverallScore()
    };
  }
};
```

---

*Tool Suggestion Patterns v1.0 | Proactive assistance framework | Non-intrusive optimization*