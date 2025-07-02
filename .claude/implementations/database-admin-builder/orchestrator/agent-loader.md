# Dynamic Agent Loader System

## Purpose
Intelligent agent loading system that optimizes context usage by loading only necessary parts of agents and managing their lifecycle.

## Agent Structure Format

### Optimized Agent File Structure
```yaml
# Each agent split into multiple files:
agents/
  team-name/
    agent-name/
      core.md          # 50-100 lines - Essential prompt
      summary.md       # 10 lines - Quick description
      implementations/ # Full code examples (loaded on demand)
        javascript.md
        typescript.md
        python.md
      patterns.md      # Common patterns (loaded on demand)
      examples.md      # Usage examples (loaded on demand)
```

## Agent Loader Implementation

```javascript
class AgentLoader {
  constructor() {
    this.loadedAgents = new Map();
    this.agentMetadata = new Map();
    this.contextTracker = new ContextTracker();
  }

  // Load only agent summary for planning
  async loadSummary(agentPath) {
    const summaryPath = `${agentPath}/summary.md`;
    const summary = await this.readFile(summaryPath);
    
    return {
      name: this.extractAgentName(agentPath),
      description: summary,
      contextSize: 10, // Summary is always ~10 lines
      capabilities: this.parseCapabilities(summary),
      dependencies: this.parseDependencies(summary)
    };
  }

  // Load core agent prompt
  async loadCore(agentPath) {
    if (this.loadedAgents.has(agentPath)) {
      return this.loadedAgents.get(agentPath);
    }

    const corePath = `${agentPath}/core.md`;
    const core = await this.readFile(corePath);
    
    // Track context usage
    this.contextTracker.add(agentPath, core.length);
    
    // Cache loaded agent
    this.loadedAgents.set(agentPath, core);
    
    return core;
  }

  // Load specific implementation
  async loadImplementation(agentPath, language) {
    const implPath = `${agentPath}/implementations/${language}.md`;
    
    // Check if we have context space
    const implSize = await this.getFileSize(implPath);
    if (!this.contextTracker.canLoad(implSize)) {
      throw new ContextLimitError('Cannot load implementation - context limit reached');
    }
    
    return await this.readFile(implPath);
  }

  // Unload agent to free context
  async unload(agentPath) {
    if (this.loadedAgents.has(agentPath)) {
      const agent = this.loadedAgents.get(agentPath);
      this.contextTracker.remove(agentPath, agent.length);
      this.loadedAgents.delete(agentPath);
    }
  }

  // Batch load multiple agents efficiently
  async batchLoad(agentPaths, loadType = 'core') {
    const results = new Map();
    
    // Sort by priority and size
    const sorted = await this.sortByEfficiency(agentPaths);
    
    for (const path of sorted) {
      try {
        if (loadType === 'summary') {
          results.set(path, await this.loadSummary(path));
        } else if (loadType === 'core') {
          results.set(path, await this.loadCore(path));
        }
      } catch (error) {
        console.error(`Failed to load ${path}:`, error);
        results.set(path, null);
      }
    }
    
    return results;
  }
}
```

## Context Tracker

```javascript
class ContextTracker {
  constructor(maxContext = 50000) {
    this.maxContext = maxContext;
    this.currentUsage = 0;
    this.usageMap = new Map();
    this.history = [];
  }

  add(id, size) {
    if (this.currentUsage + size > this.maxContext) {
      throw new ContextLimitError(
        `Would exceed context limit: ${this.currentUsage + size}/${this.maxContext}`
      );
    }
    
    this.usageMap.set(id, size);
    this.currentUsage += size;
    this.history.push({ action: 'add', id, size, timestamp: Date.now() });
  }

  remove(id, size) {
    if (this.usageMap.has(id)) {
      this.currentUsage -= this.usageMap.get(id);
      this.usageMap.delete(id);
      this.history.push({ action: 'remove', id, size, timestamp: Date.now() });
    }
  }

  canLoad(size) {
    return this.currentUsage + size <= this.maxContext * 0.9; // 90% safety margin
  }

  getStatus() {
    return {
      current: this.currentUsage,
      max: this.maxContext,
      percentage: (this.currentUsage / this.maxContext) * 100,
      loaded: Array.from(this.usageMap.keys()),
      available: this.maxContext - this.currentUsage
    };
  }

  // Emergency cleanup - remove largest items first
  emergencyCleanup(targetSize) {
    const sorted = Array.from(this.usageMap.entries())
      .sort(([, a], [, b]) => b - a);
    
    let freed = 0;
    const removed = [];
    
    for (const [id, size] of sorted) {
      if (freed >= targetSize) break;
      this.remove(id, size);
      removed.push(id);
      freed += size;
    }
    
    return removed;
  }
}
```

## Smart Loading Strategies

### Lazy Loading Pattern
```javascript
class LazyAgentLoader extends AgentLoader {
  async loadWithPatterns(agentPath, options = {}) {
    // Always load core first
    const core = await this.loadCore(agentPath);
    
    // Conditionally load extras based on need
    const extras = {};
    
    if (options.needsImplementation) {
      try {
        extras.implementation = await this.loadImplementation(
          agentPath, 
          options.language || 'javascript'
        );
      } catch (error) {
        console.warn('Could not load implementation:', error);
      }
    }
    
    if (options.needsPatterns) {
      try {
        extras.patterns = await this.loadPatterns(agentPath);
      } catch (error) {
        console.warn('Could not load patterns:', error);
      }
    }
    
    return { core, ...extras };
  }
}
```

### Predictive Loading
```javascript
class PredictiveLoader extends LazyAgentLoader {
  constructor() {
    super();
    this.predictions = new Map();
  }

  // Predict which agents will be needed based on request
  predictAgents(userRequest) {
    const predictions = [];
    
    // Keywords to agent mapping
    const keywordMap = {
      'authentication': ['auth-builder', 'access-control-manager'],
      'api': ['api-generator', 'validation-engineer'],
      'dashboard': ['dashboard-designer', 'table-builder'],
      'security': ['encryption-specialist', 'vulnerability-scanner'],
      'performance': ['query-optimizer', 'performance-optimizer']
    };
    
    // Analyze request for keywords
    const requestLower = userRequest.toLowerCase();
    for (const [keyword, agents] of Object.entries(keywordMap)) {
      if (requestLower.includes(keyword)) {
        predictions.push(...agents);
      }
    }
    
    // Store predictions for preloading
    this.predictions.set(userRequest, predictions);
    
    return predictions;
  }

  // Preload predicted agents in background
  async preload(userRequest) {
    const predicted = this.predictAgents(userRequest);
    
    // Load summaries in parallel (low context cost)
    const summaries = await Promise.all(
      predicted.map(agent => this.loadSummary(`agents/${agent}`))
    );
    
    return summaries;
  }
}
```

## Agent Registry

### Central Registry for All Agents
```javascript
const AGENT_REGISTRY = {
  'analysis-team': {
    'requirements-interpreter': {
      coreSize: 100,
      fullSize: 800,
      priority: 'high',
      dependencies: [],
      capabilities: ['parse_requirements', 'extract_features']
    },
    'schema-analyzer': {
      coreSize: 120,
      fullSize: 700,
      priority: 'high',
      dependencies: ['database_connection'],
      capabilities: ['analyze_schema', 'detect_relationships']
    },
    // ... other agents
  },
  
  'backend-team': {
    'api-generator': {
      coreSize: 150,
      fullSize: 900,
      priority: 'high',
      dependencies: ['schema'],
      capabilities: ['generate_rest_api', 'generate_graphql']
    },
    // ... other agents
  },
  
  // ... other teams
};

// Get agent metadata without loading
function getAgentMetadata(agentName) {
  for (const [team, agents] of Object.entries(AGENT_REGISTRY)) {
    if (agents[agentName]) {
      return {
        team,
        ...agents[agentName],
        path: `agents/${team}/${agentName}`
      };
    }
  }
  return null;
}
```

## Usage Examples

### Basic Loading
```javascript
const loader = new AgentLoader();

// Load just summary for planning
const summary = await loader.loadSummary('agents/analysis-team/schema-analyzer');

// Load core for execution
const core = await loader.loadCore('agents/backend-team/api-generator');

// Check context status
console.log(loader.contextTracker.getStatus());
// { current: 270, max: 50000, percentage: 0.54, available: 49730 }
```

### Batch Loading with Context Management
```javascript
const loader = new PredictiveLoader();

// Predict and preload
const request = "Build API with authentication and dashboard";
await loader.preload(request);

// Execute phase with batch loading
const phase1Agents = [
  'agents/analysis-team/requirements-interpreter',
  'agents/analysis-team/schema-analyzer'
];

const agents = await loader.batchLoad(phase1Agents, 'core');

// Execute agents...

// Cleanup after phase
for (const agentPath of phase1Agents) {
  await loader.unload(agentPath);
}
```

### Emergency Context Management
```javascript
const loader = new AgentLoader();

try {
  // Try to load large agent
  await loader.loadCore('agents/security-team/encryption-specialist');
} catch (error) {
  if (error instanceof ContextLimitError) {
    // Free up space by removing least recently used
    const removed = loader.contextTracker.emergencyCleanup(1000);
    console.log('Removed agents to free space:', removed);
    
    // Retry
    await loader.loadCore('agents/security-team/encryption-specialist');
  }
}
```

## Performance Optimizations

### Caching Strategy
```javascript
class CachedAgentLoader extends AgentLoader {
  constructor() {
    super();
    this.cache = new LRUCache({ maxSize: 20 });
  }

  async loadCore(agentPath) {
    // Check cache first
    if (this.cache.has(agentPath)) {
      return this.cache.get(agentPath);
    }

    const core = await super.loadCore(agentPath);
    this.cache.set(agentPath, core);
    return core;
  }
}
```

### Parallel Loading with Rate Limiting
```javascript
async function loadAgentsParallel(agentPaths, loader, maxConcurrent = 3) {
  const results = [];
  
  for (let i = 0; i < agentPaths.length; i += maxConcurrent) {
    const batch = agentPaths.slice(i, i + maxConcurrent);
    const batchResults = await Promise.all(
      batch.map(path => loader.loadCore(path))
    );
    results.push(...batchResults);
  }
  
  return results;
}
```

---

*Dynamic Agent Loader v1.0 | Context-aware loading | Performance optimized*