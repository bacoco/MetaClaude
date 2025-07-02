# Full Admin Panel Generation Workflow

## Overview
Complete workflow for generating a production-ready admin panel from database schema using optimized agent orchestration and context management.

## Workflow Definition

```javascript
export const FullAdminGenerationWorkflow = {
  name: 'full-admin-generation',
  description: 'Generate complete admin panel with all features',
  
  phases: [
    {
      id: 'analyze',
      name: 'Requirements & Schema Analysis',
      parallel: false,
      agents: [
        { name: 'requirements-interpreter', type: 'core' },
        { name: 'schema-analyzer', type: 'core' },
        { name: 'relationship-mapper', type: 'core' }
      ],
      contextBudget: 800,
      timeout: 60000,
      outputs: ['requirements', 'schema', 'relationships']
    },
    
    {
      id: 'backend',
      name: 'Backend Generation',
      parallel: true,
      dependencies: ['analyze'],
      agents: [
        { name: 'api-generator', type: 'core' },
        { name: 'auth-builder', type: 'core' },
        { name: 'query-optimizer', type: 'summary' },
        { name: 'validation-engineer', type: 'core' }
      ],
      contextBudget: 1500,
      timeout: 120000,
      outputs: ['api', 'auth', 'queries', 'validation']
    },
    
    {
      id: 'frontend',
      name: 'Frontend Generation',
      parallel: true,
      dependencies: ['backend'],
      agents: [
        { name: 'ui-component-builder', type: 'core' },
        { name: 'table-builder', type: 'core' },
        { name: 'form-generator', type: 'core' },
        { name: 'dashboard-designer', type: 'summary' }
      ],
      contextBudget: 1500,
      timeout: 120000,
      outputs: ['components', 'tables', 'forms', 'dashboard']
    },
    
    {
      id: 'security',
      name: 'Security Implementation',
      parallel: false,
      dependencies: ['backend', 'frontend'],
      agents: [
        { name: 'access-control-manager', type: 'core' },
        { name: 'audit-logger', type: 'summary' }
      ],
      contextBudget: 800,
      timeout: 60000,
      outputs: ['rbac', 'audit']
    },
    
    {
      id: 'enhance',
      name: 'Enhancement Features',
      parallel: true,
      dependencies: ['frontend'],
      agents: [
        { name: 'search-implementer', type: 'summary' },
        { name: 'export-manager', type: 'summary' },
        { name: 'performance-optimizer', type: 'summary' }
      ],
      contextBudget: 1000,
      timeout: 90000,
      outputs: ['search', 'export', 'optimizations']
    }
  ],
  
  totalContextBudget: 5600,
  maxExecutionTime: 300000 // 5 minutes
};
```

## Execution Implementation

```javascript
class AdminGenerationExecutor {
  constructor(orchestrator, memory, agentLoader) {
    this.orchestrator = orchestrator;
    this.memory = memory;
    this.agentLoader = agentLoader;
    this.results = {};
  }

  async execute(userRequest, workflow = FullAdminGenerationWorkflow) {
    console.log(`Starting ${workflow.name} workflow...`);
    
    const startTime = Date.now();
    const executionPlan = this.createExecutionPlan(userRequest, workflow);
    
    try {
      // Execute each phase
      for (const phase of workflow.phases) {
        await this.executePhase(phase, executionPlan);
      }
      
      // Generate final output
      const output = await this.assembleOutput();
      
      const executionTime = Date.now() - startTime;
      console.log(`Workflow completed in ${executionTime}ms`);
      
      return {
        success: true,
        output,
        metrics: {
          executionTime,
          contextUsed: this.agentLoader.contextTracker.currentUsage,
          phasesCompleted: Object.keys(this.results).length
        }
      };
      
    } catch (error) {
      console.error('Workflow failed:', error);
      return {
        success: false,
        error: error.message,
        partialResults: this.results,
        completedPhases: Object.keys(this.results)
      };
    }
  }

  async executePhase(phase, executionPlan) {
    console.log(`Executing phase: ${phase.name}`);
    
    // Check dependencies
    if (phase.dependencies) {
      for (const dep of phase.dependencies) {
        if (!this.results[dep]) {
          throw new Error(`Missing dependency: ${dep}`);
        }
      }
    }
    
    // Get context from dependencies
    const context = await this.memory.getPhaseContext(
      phase.id,
      phase.dependencies || []
    );
    
    // Load required agents
    const agents = await this.loadPhaseAgents(phase.agents);
    
    // Execute agents (parallel or sequential)
    let phaseResults;
    if (phase.parallel) {
      phaseResults = await this.executeParallel(agents, context);
    } else {
      phaseResults = await this.executeSequential(agents, context);
    }
    
    // Store results in memory
    await this.memory.storePhaseResult(phase.id, phaseResults);
    this.results[phase.id] = phaseResults;
    
    // Unload agents to free context
    await this.unloadAgents(agents);
    
    console.log(`Phase ${phase.name} completed`);
  }

  async loadPhaseAgents(agentConfigs) {
    const loaded = [];
    
    for (const config of agentConfigs) {
      const agentPath = this.getAgentPath(config.name);
      
      if (config.type === 'core') {
        const agent = await this.agentLoader.loadCore(agentPath);
        loaded.push({ name: config.name, type: 'core', content: agent });
      } else if (config.type === 'summary') {
        const summary = await this.agentLoader.loadSummary(agentPath);
        loaded.push({ name: config.name, type: 'summary', content: summary });
      }
    }
    
    return loaded;
  }

  async executeParallel(agents, context) {
    const promises = agents.map(agent => 
      this.executeAgent(agent, context)
    );
    
    const results = await Promise.all(promises);
    
    // Merge results
    return results.reduce((merged, result, index) => {
      merged[agents[index].name] = result;
      return merged;
    }, {});
  }

  async executeSequential(agents, context) {
    const results = {};
    
    for (const agent of agents) {
      // Pass previous results as additional context
      const enrichedContext = {
        ...context,
        previousResults: results
      };
      
      results[agent.name] = await this.executeAgent(agent, enrichedContext);
    }
    
    return results;
  }

  async executeAgent(agent, context) {
    // Simulate agent execution
    // In real implementation, this would use the agent's prompt
    // with the context to generate appropriate output
    
    console.log(`  Running ${agent.name}...`);
    
    // Agent-specific logic based on name
    switch (agent.name) {
      case 'requirements-interpreter':
        return this.interpretRequirements(context);
        
      case 'schema-analyzer':
        return this.analyzeSchema(context);
        
      case 'api-generator':
        return this.generateAPI(context);
        
      case 'table-builder':
        return this.buildTables(context);
        
      // ... other agents
      
      default:
        return { 
          status: 'completed',
          agent: agent.name,
          timestamp: Date.now()
        };
    }
  }

  interpretRequirements(context) {
    return {
      entities: ['users', 'products', 'orders'],
      features: {
        crud: true,
        search: true,
        export: true,
        bulkOperations: true
      },
      security: {
        authentication: 'jwt',
        authorization: 'rbac',
        twoFactor: false
      },
      ui: {
        framework: 'react',
        styling: 'tailwind',
        responsive: true
      }
    };
  }

  analyzeSchema(context) {
    return {
      tables: [
        {
          name: 'users',
          fields: [
            { name: 'id', type: 'uuid', primaryKey: true },
            { name: 'email', type: 'string', unique: true },
            { name: 'password', type: 'string' },
            { name: 'role', type: 'enum', values: ['admin', 'user'] }
          ]
        },
        // ... other tables
      ],
      relationships: [
        { from: 'orders.user_id', to: 'users.id', type: 'many-to-one' }
      ]
    };
  }

  async assembleOutput() {
    return {
      backend: {
        api: this.results.backend?.['api-generator'],
        auth: this.results.backend?.['auth-builder'],
        database: {
          queries: this.results.backend?.['query-optimizer'],
          migrations: this.results.analyze?.['schema-analyzer']?.migrations
        }
      },
      frontend: {
        components: this.results.frontend?.['ui-component-builder'],
        tables: this.results.frontend?.['table-builder'],
        forms: this.results.frontend?.['form-generator'],
        dashboard: this.results.frontend?.['dashboard-designer']
      },
      security: {
        rbac: this.results.security?.['access-control-manager'],
        audit: this.results.security?.['audit-logger']
      },
      enhancements: {
        search: this.results.enhance?.['search-implementer'],
        export: this.results.enhance?.['export-manager'],
        performance: this.results.enhance?.['performance-optimizer']
      },
      deployment: {
        docker: this.generateDockerConfig(),
        environment: this.generateEnvTemplate()
      }
    };
  }
}
```

## Usage Example

```javascript
// Initialize components
const orchestrator = new DatabaseAdminOrchestrator();
const memory = new ContextMemory();
const agentLoader = new AgentLoader();

// Create executor
const executor = new AdminGenerationExecutor(orchestrator, memory, agentLoader);

// Execute workflow
const request = {
  prompt: "Generate admin panel for e-commerce platform",
  database: {
    type: 'postgresql',
    connectionString: 'postgresql://localhost/ecommerce'
  },
  features: ['users', 'products', 'orders', 'analytics'],
  framework: 'react',
  ui: 'material-ui',
  security: 'enterprise'
};

const result = await executor.execute(request);

if (result.success) {
  console.log('Admin panel generated successfully!');
  console.log(`Context used: ${result.metrics.contextUsed} tokens`);
  console.log(`Execution time: ${result.metrics.executionTime}ms`);
  
  // Save generated files
  await saveGeneratedFiles(result.output);
} else {
  console.error('Generation failed:', result.error);
  console.log('Completed phases:', result.completedPhases);
}
```

## Error Recovery

```javascript
class ResilientExecutor extends AdminGenerationExecutor {
  async executePhase(phase, executionPlan) {
    const maxRetries = 3;
    let lastError;
    
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await super.executePhase(phase, executionPlan);
      } catch (error) {
        lastError = error;
        console.warn(`Phase ${phase.name} failed (attempt ${attempt}):`, error.message);
        
        if (error.type === 'CONTEXT_LIMIT') {
          // Reduce agent set and retry
          phase.agents = this.reduceAgents(phase.agents);
        } else if (error.type === 'TIMEOUT') {
          // Increase timeout
          phase.timeout *= 1.5;
        }
        
        // Exponential backoff
        await new Promise(resolve => setTimeout(resolve, Math.pow(2, attempt) * 1000));
      }
    }
    
    // All retries failed
    throw lastError;
  }

  reduceAgents(agents) {
    // Keep only core agents, remove summaries
    return agents.filter(a => a.type === 'core').slice(0, 2);
  }
}
```

## Performance Monitoring

```javascript
class MonitoredWorkflow {
  constructor(executor) {
    this.executor = executor;
    this.metrics = [];
  }

  async execute(request) {
    const monitor = {
      phases: {},
      contextUsage: [],
      memoryUsage: []
    };

    // Hook into phase execution
    this.executor.onPhaseStart = (phase) => {
      monitor.phases[phase.id] = {
        startTime: Date.now(),
        contextBefore: this.executor.agentLoader.contextTracker.currentUsage
      };
    };

    this.executor.onPhaseComplete = (phase) => {
      const phaseMetrics = monitor.phases[phase.id];
      phaseMetrics.endTime = Date.now();
      phaseMetrics.duration = phaseMetrics.endTime - phaseMetrics.startTime;
      phaseMetrics.contextAfter = this.executor.agentLoader.contextTracker.currentUsage;
      phaseMetrics.contextUsed = phaseMetrics.contextAfter - phaseMetrics.contextBefore;
      
      console.log(`Phase ${phase.id} metrics:`, {
        duration: `${phaseMetrics.duration}ms`,
        contextUsed: phaseMetrics.contextUsed,
        agents: phase.agents.length
      });
    };

    const result = await this.executor.execute(request);
    
    return {
      ...result,
      monitoring: monitor
    };
  }
}
```

---

*Full Admin Generation Workflow v1.0 | Optimized orchestration | Context-aware execution*