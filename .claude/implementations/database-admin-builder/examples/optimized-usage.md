# Database Admin Builder - Optimized Usage Examples

## Overview
This guide demonstrates how to use the optimized Database Admin Builder system that manages context efficiently through dynamic agent loading, memory compression, and intelligent orchestration.

## Basic Usage Example

### 1. Simple E-Commerce Admin Panel

```javascript
import { DatabaseAdminBuilder } from '@claude-flow/database-admin-builder';

// Initialize the builder with optimized settings
const builder = new DatabaseAdminBuilder({
  contextLimit: 50000,      // Conservative limit
  compressionEnabled: true,  // Enable memory compression
  parallelExecution: true    // Enable parallel agent execution
});

// Simple request
const result = await builder.generate({
  prompt: "Create admin panel for my e-commerce store",
  database: "postgresql://localhost/shop",
  features: ["products", "orders", "customers"]
});

console.log(`Generated in ${result.metrics.executionTime}ms`);
console.log(`Context used: ${result.metrics.contextUsed}/${result.metrics.contextLimit}`);
```

### 2. Enterprise Admin Panel with Advanced Features

```javascript
// Complex request with specific requirements
const enterpriseResult = await builder.generate({
  prompt: "Build enterprise admin dashboard with multi-tenancy",
  database: {
    type: "postgresql",
    connection: process.env.DATABASE_URL,
    ssl: true
  },
  requirements: {
    features: [
      "multi-tenant-isolation",
      "role-based-access-control",
      "audit-logging",
      "data-export",
      "real-time-analytics",
      "api-documentation"
    ],
    security: {
      authentication: "oauth2",
      authorization: "rbac",
      encryption: "aes-256",
      compliance: ["gdpr", "hipaa"]
    },
    ui: {
      framework: "react",
      components: "material-ui",
      theme: "dark-mode-support",
      responsive: true,
      accessibility: "wcag-aaa"
    }
  },
  optimization: {
    targetUsers: 10000,
    expectedDataSize: "1TB",
    caching: "redis",
    cdn: true
  }
});
```

## Context Management Examples

### 3. Monitoring Context Usage

```javascript
const builder = new DatabaseAdminBuilder({
  onContextChange: (usage) => {
    console.log(`Context: ${usage.current}/${usage.max} (${usage.percentage}%)`);
    console.log(`Loaded agents: ${usage.loadedAgents.join(', ')}`);
  }
});

// Execute with monitoring
const result = await builder.generate({
  prompt: "Generate CRM admin panel",
  database: "mysql://localhost/crm",
  debug: true  // Enable detailed logging
});

// Context usage breakdown
console.log('Context usage by phase:');
result.metrics.phaseMetrics.forEach(phase => {
  console.log(`- ${phase.name}: ${phase.contextUsed} tokens`);
});
```

### 4. Custom Context Limits

```javascript
// For limited environments (e.g., edge deployments)
const limitedBuilder = new DatabaseAdminBuilder({
  contextLimit: 25000,  // Half the normal limit
  agentLoadingStrategy: 'minimal',  // Load only essential agents
  compressionLevel: 'aggressive'    // Maximum compression
});

// Will automatically adjust execution strategy
const result = await limitedBuilder.generate({
  prompt: "Basic admin panel for blog",
  database: "sqlite://blog.db",
  features: ["posts", "comments", "users"]
});
```

## Advanced Orchestration Examples

### 5. Custom Workflow Definition

```javascript
// Define custom workflow for specific use case
const customWorkflow = {
  name: 'rapid-prototype',
  phases: [
    {
      id: 'quick-analysis',
      agents: ['requirements-interpreter', 'schema-analyzer'],
      parallel: false,
      contextBudget: 500
    },
    {
      id: 'mvp-generation',
      agents: ['api-generator', 'ui-component-builder'],
      parallel: true,
      contextBudget: 1000
    }
  ],
  totalContextBudget: 1500
};

const builder = new DatabaseAdminBuilder();
const result = await builder.generateWithWorkflow({
  prompt: "Quick MVP admin for startup",
  database: "postgresql://localhost/startup",
  workflow: customWorkflow
});
```

### 6. Phased Execution with Checkpoints

```javascript
const builder = new DatabaseAdminBuilder({
  enableCheckpoints: true
});

// Start generation
const session = await builder.startSession({
  prompt: "Complex financial admin system",
  database: "postgresql://localhost/finance"
});

// Execute phase by phase with ability to review
const phases = ['analysis', 'backend', 'frontend', 'security', 'enhancement'];

for (const phase of phases) {
  const phaseResult = await session.executePhase(phase);
  
  console.log(`Phase ${phase} completed:`);
  console.log(`- Agents used: ${phaseResult.agentsUsed.join(', ')}`);
  console.log(`- Context used: ${phaseResult.contextUsed}`);
  console.log(`- Outputs: ${Object.keys(phaseResult.outputs).join(', ')}`);
  
  // Optional: Review and modify before continuing
  if (phase === 'backend') {
    // Modify API endpoints before frontend generation
    phaseResult.outputs.api.endpoints.push({
      method: 'POST',
      path: '/api/custom/webhook'
    });
  }
}

// Finalize and get complete result
const finalResult = await session.complete();
```

## Memory Management Examples

### 7. Persistent Sessions with Memory

```javascript
// Create a session that persists memory across multiple generations
const sessionBuilder = new DatabaseAdminBuilder({
  persistentMemory: true,
  memoryStoragePath: './admin-builder-sessions'
});

// First generation
await sessionBuilder.generate({
  sessionId: 'my-project',
  prompt: "User management module",
  database: "postgresql://localhost/app"
});

// Second generation uses previous context
await sessionBuilder.generate({
  sessionId: 'my-project',
  prompt: "Add product catalog module",
  reuseContext: true  // Reuses schema analysis from previous run
});

// View memory usage
const memoryStats = sessionBuilder.getMemoryStats('my-project');
console.log('Session memory:', memoryStats);
```

### 8. Memory Optimization Strategies

```javascript
const builder = new DatabaseAdminBuilder({
  memoryStrategy: {
    compression: 'smart',     // Compress based on content type
    eviction: 'lru',         // Least recently used
    maxPhaseMemory: 2000,    // Max memory per phase
    criticalPhases: ['schema', 'requirements']  // Never evict these
  }
});

// Memory-intensive operation
const result = await builder.generate({
  prompt: "Enterprise ERP system with 200+ tables",
  database: "oracle://localhost/erp",
  memoryOptimization: {
    splitLargeTables: true,    // Process large schemas in chunks
    incrementalGeneration: true // Generate code incrementally
  }
});
```

## Error Handling and Recovery

### 9. Graceful Degradation

```javascript
const builder = new DatabaseAdminBuilder({
  errorRecovery: {
    contextLimitStrategy: 'reduce-features',  // Disable non-critical features
    agentFailureStrategy: 'use-fallback',    // Use simpler agents
    maxRetries: 3
  }
});

try {
  const result = await builder.generate({
    prompt: "Admin panel with all features",
    database: "postgresql://localhost/app",
    features: ["everything"]  // Will gracefully reduce if needed
  });
  
  if (result.warnings.length > 0) {
    console.log('Generation completed with warnings:');
    result.warnings.forEach(w => console.log(`- ${w}`));
  }
} catch (error) {
  console.error('Generation failed:', error.message);
  console.log('Partial results:', error.partialResults);
}
```

### 10. Context Overflow Handling

```javascript
const builder = new DatabaseAdminBuilder({
  onContextOverflow: async (overflow) => {
    console.log(`Context overflow by ${overflow.amount} tokens`);
    console.log('Suggested actions:', overflow.suggestions);
    
    // Automatic recovery
    return {
      action: 'reduce',
      reduceBy: ['nice-to-have-features', 'advanced-analytics']
    };
  }
});

const result = await builder.generate({
  prompt: "Kitchen sink admin panel with every possible feature",
  database: "postgresql://localhost/everything"
});
```

## Performance Optimization Examples

### 11. Parallel Agent Execution

```javascript
const builder = new DatabaseAdminBuilder({
  parallelism: {
    maxConcurrentAgents: 4,
    batchSize: 2,
    priorityQueue: true
  }
});

// Executes multiple agents simultaneously
const result = await builder.generate({
  prompt: "High-performance admin dashboard",
  database: "postgresql://localhost/perf",
  performance: {
    parallelizeIndependentAgents: true,
    cacheAgentOutputs: true,
    reuseCommonPatterns: true
  }
});

// Performance report
console.log('Parallel execution metrics:');
console.log(`- Total time: ${result.metrics.totalTime}ms`);
console.log(`- Parallel speedup: ${result.metrics.parallelSpeedup}x`);
console.log(`- Agent utilization: ${result.metrics.agentUtilization}%`);
```

### 12. Streaming Generation

```javascript
// Stream results as they're generated
const builder = new DatabaseAdminBuilder({
  streaming: true
});

const stream = builder.generateStream({
  prompt: "Real-time admin dashboard",
  database: "postgresql://localhost/stream"
});

stream.on('phase', (phase) => {
  console.log(`Starting phase: ${phase.name}`);
});

stream.on('agent', (agent) => {
  console.log(`Agent ${agent.name} completed`);
});

stream.on('output', (output) => {
  console.log(`Generated: ${output.type}`);
  // Can start using outputs immediately
  if (output.type === 'api-endpoints') {
    startBackendServer(output.data);
  }
});

stream.on('complete', (result) => {
  console.log('Generation complete!');
});
```

## Integration Examples

### 13. CI/CD Pipeline Integration

```javascript
// GitHub Actions example
const builder = new DatabaseAdminBuilder({
  ci: true,  // Optimized for CI environments
  output: {
    format: 'structured',
    path: './generated-admin',
    gitignore: true
  }
});

const result = await builder.generate({
  prompt: "Admin panel from schema.sql",
  database: "schema://./database/schema.sql",
  validation: {
    linting: true,
    typecheck: true,
    tests: 'unit'
  }
});

// Exit with appropriate code
process.exit(result.success ? 0 : 1);
```

### 14. IDE Plugin Usage

```javascript
// VSCode extension example
const builder = new DatabaseAdminBuilder({
  ide: 'vscode',
  interactive: true
});

// Interactive generation with previews
const session = builder.createInteractiveSession({
  workspace: vscode.workspace.rootPath,
  database: await detectDatabase()
});

// Generate with live preview
session.on('preview', (preview) => {
  vscode.window.showWebviewPanel('Admin Preview', preview.html);
});

await session.start();
```

## Best Practices Summary

```javascript
// Optimal configuration for most use cases
const builder = new DatabaseAdminBuilder({
  // Context Management
  contextLimit: 50000,
  compressionEnabled: true,
  
  // Performance
  parallelExecution: true,
  caching: true,
  
  // Error Handling
  errorRecovery: {
    contextLimitStrategy: 'reduce-features',
    maxRetries: 3
  },
  
  // Memory
  memoryStrategy: {
    compression: 'smart',
    eviction: 'lru'
  },
  
  // Monitoring
  metrics: true,
  debug: process.env.NODE_ENV === 'development'
});

// Use with confidence
const result = await builder.generate({
  prompt: "Your admin panel requirements here",
  database: "your-database-connection"
});
```

---

*Optimized Database Admin Builder Examples v1.0 | Efficient context usage | Production-ready patterns*