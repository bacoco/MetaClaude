# Customization Guide

Comprehensive guide for customizing and extending the UI Designer Orchestrator to meet specific needs.

## Table of Contents

1. [Customizing Specialists](#customizing-specialists)
2. [Creating Custom Commands](#creating-custom-commands)
3. [Building Custom Workflows](#building-custom-workflows)
4. [Extending Memory Systems](#extending-memory-systems)
5. [Custom Patterns](#custom-patterns)
6. [Integration Development](#integration-development)
7. [Advanced Customization](#advanced-customization)

---

## Customizing Specialists

### Modifying Existing Specialists

Each specialist can be customized by editing their configuration files in `.claude/specialists/`.

#### Example: Customizing the UI Generator

```markdown
# .claude/specialists/ui-generator-custom.md

# UI Generator - Custom Configuration

## Base Configuration
[Include original configuration]

## Custom Additions

### Company-Specific Components
When generating UI components, always include:
- CompanyLogo component in headers
- CustomFooter with legal links
- BrandedButton with specific hover states

### Design Constraints
- Maximum 3 colors per screen
- Minimum 16px font size
- 60px header height (fixed)
- Custom spacing scale: [0, 4, 8, 16, 24, 32, 48, 64]

### Technology Stack
Prefer these technologies:
- React with TypeScript
- Styled-components over Tailwind
- Framer Motion for animations
- Custom icon library: @company/icons
```

#### Applying Custom Configuration

```bash
# Replace default with custom specialist
mv .claude/specialists/ui-generator.md .claude/specialists/ui-generator-original.md
mv .claude/specialists/ui-generator-custom.md .claude/specialists/ui-generator.md
```

```
# Use the UI Designer with custom specialist
"Create a dashboard using the custom UI generator configuration"
```

### Creating New Specialists

#### Template for New Specialist

```markdown
# .claude/specialists/motion-designer.md

# Motion Designer

Specialist in creating animations, transitions, and micro-interactions for UI designs.

## Role Definition

You are the Motion Designer, responsible for:
- Creating smooth, purposeful animations
- Defining motion principles for brand consistency
- Optimizing performance of animations
- Ensuring accessibility in motion design

## Capabilities

### Animation Types
- Micro-interactions (hover, click, focus)
- Page transitions
- Loading states
- Data visualizations
- Scroll-triggered animations

### Tools & Output
- CSS animations
- JavaScript animation libraries
- Lottie files
- After Effects exports
- Motion documentation

## Integration with Other Specialists
- Receive designs from UI Generator
- Collaborate with Accessibility Auditor
- Align with Brand Strategist on motion personality
```

---

## Creating Custom Commands

### Command Structure

Create new commands in `.claude/commands/` directory:

```markdown
# .claude/commands/generate-email-templates.md

# Generate Email Templates Command

Create responsive email templates consistent with brand design system.

## Command Usage
\`\`\`
"Generate email templates for [template types]"
\`\`\`

## Process Flow

### 1. Template Analysis
\`\`\`javascript
const analyzeEmailRequirements = (request) => {
  return {
    types: extractTemplateTypes(request),
    brand: loadBrandGuidelines(),
    constraints: {
      maxWidth: 600,
      supportedClients: ['Gmail', 'Outlook', 'Apple Mail'],
      fallbacks: true
    }
  };
};
\`\`\`

### 2. Generation Process
[Implementation details]

### 3. Output Format
- HTML email templates
- Text fallbacks
- Image assets
- Testing checklist
```

### Registering Custom Commands

Add to `.claude/settings.json`:

```json
{
  "custom_commands": {
    "generate-email-templates": {
      "path": "commands/generate-email-templates.md",
      "description": "Generate responsive email templates",
      "category": "generation"
    }
  }
}
```

### Complex Command Example

```markdown
# .claude/commands/design-review.md

# Design Review Command

Automated design review comparing against standards.

## Implementation

\`\`\`javascript
const designReview = async (designs) => {
  const checks = [
    checkBrandCompliance(designs),
    checkAccessibility(designs),
    checkPerformance(designs),
    checkConsistency(designs)
  ];
  
  const results = await Promise.all(checks);
  
  return {
    score: calculateScore(results),
    issues: extractIssues(results),
    recommendations: generateRecommendations(results),
    report: generateReport(results)
  };
};
\`\`\`

## Integration Points
- Uses Brand Guidelines from memory
- Leverages Accessibility Auditor
- Generates actionable feedback
```

---

## Building Custom Workflows

### Workflow Template

```markdown
# .claude/workflows/startup-mvp.md

# Startup MVP Workflow

Rapid MVP design for startups with limited time and resources.

## Workflow Overview

\`\`\`
VALIDATE → DESIGN → TEST → SHIP
  ↑                         ↓
  └──── PIVOT IF NEEDED ────┘
\`\`\`

## Duration: 10 days

### Day 1-2: Rapid Validation
\`\`\`javascript
const validation = {
  activities: [
    'Competitor analysis',
    'User interviews (5)',
    'Problem validation'
  ],
  deliverables: [
    'Problem statement',
    'Target user profile',
    'Core value prop'
  ]
};
\`\`\`

### Day 3-5: Design Sprint
[Design phase details]

### Day 6-7: Build Prototype
[Prototype details]

### Day 8-9: User Testing
[Testing details]

### Day 10: Ship Decision
[Decision framework]
```

### Combining Existing Workflows

```javascript
// .claude/workflows/enterprise-transformation.md

const enterpriseTransformation = {
  phases: [
    {
      name: 'Assessment',
      workflow: 'ui-optimization-cycle',
      duration: '2 weeks',
      focus: 'Current state analysis'
    },
    {
      name: 'Strategy',
      workflow: 'brand-identity-creation',
      duration: '3 weeks',
      focus: 'Future vision'
    },
    {
      name: 'System Design',
      workflow: 'design-system-first',
      duration: '4 weeks',
      focus: 'Scalable foundation'
    },
    {
      name: 'Implementation',
      workflow: 'complete-ui-project',
      duration: '8 weeks',
      focus: 'Phased rollout'
    }
  ]
};
```

---

## Extending Memory Systems

### Custom Memory Categories

```javascript
// .claude/memory/client-preferences.md

# Client Preferences Memory

Store client-specific preferences and requirements.

## Memory Structure

\`\`\`json
{
  "clients": {
    "client_001": {
      "name": "ACME Corp",
      "preferences": {
        "colors": {
          "restricted": ["red", "green"],
          "preferred": ["blue", "gray"]
        },
        "imagery": {
          "style": "Abstract only",
          "avoid": ["People", "Faces"]
        },
        "tone": {
          "formality": "High",
          "technicality": "Medium"
        }
      },
      "compliance": {
        "standards": ["WCAG AA", "Section 508"],
        "regulations": ["GDPR", "CCPA"]
      },
      "stakeholders": {
        "primary": "John Doe <john@acme.com>",
        "approvers": ["Jane Smith", "Bob Johnson"]
      }
    }
  }
}
\`\`\`

## Query Interface

\`\`\`javascript
// Get client preferences
memory.get('clients.client_001.preferences');

// Update preferences
memory.set('clients.client_001.preferences.colors.preferred', ['blue', 'teal']);

// Find clients with specific requirements
memory.query('clients.*', { 
  'compliance.standards': { includes: 'WCAG AA' } 
});
\`\`\`
```

### Memory Plugins

```javascript
// .claude/memory/plugins/analytics-tracker.js

const analyticsTracker = {
  track: async (event, data) => {
    const entry = {
      timestamp: new Date().toISOString(),
      event,
      data,
      session: getCurrentSession()
    };
    
    await memory.append('analytics.events', entry);
    
    // Real-time analysis
    if (event === 'design_completed') {
      await updateDesignMetrics(data);
    }
  },
  
  report: async (period) => {
    const events = await memory.get('analytics.events');
    return generateReport(events, period);
  }
};
```

---

## Custom Patterns

### Creating Pattern Templates

```markdown
# .claude/patterns/mobile-first-workflow.md

# Mobile First Workflow Pattern

Design methodology prioritizing mobile experience before scaling to desktop.

## Pattern Overview

\`\`\`
MOBILE CORE → TABLET ENHANCE → DESKTOP EXPAND
\`\`\`

## Implementation

### Stage 1: Mobile Core (320-768px)
\`\`\`javascript
const mobileFirst = {
  constraints: {
    viewport: { min: 320, max: 768 },
    touch: { minTarget: 44 },
    performance: { maxPageWeight: '500KB' }
  },
  
  priorities: [
    'Essential features only',
    'Vertical layout',
    'Thumb-friendly navigation',
    'Offline capability'
  ]
};
\`\`\`

### Stage 2: Tablet Enhancement
[Tablet details]

### Stage 3: Desktop Expansion
[Desktop details]
```

### Pattern Composition

```javascript
// Combining multiple patterns
const hybridPattern = {
  base: 'mobile-first-workflow',
  enhance: ['vibe-design-workflow', 'user-research-driven'],
  
  execution: async (project) => {
    // Mobile-first approach
    const mobile = await mobileFirstPattern(project);
    
    // Apply vibe design to mobile
    const mobileVibe = await vibePattern(mobile);
    
    // Validate with users
    const validated = await userResearchPattern(mobileVibe);
    
    return scaleToLargerScreens(validated);
  }
};
```

---

## Integration Development

### External Tool Integration

```javascript
// .claude/integrations/figma-sync.js

const figmaIntegration = {
  export: async (designs) => {
    const figmaFile = await createFigmaFile(designs);
    
    // Convert designs to Figma format
    const frames = designs.map(design => ({
      name: design.name,
      width: design.dimensions.width,
      height: design.dimensions.height,
      elements: convertToFigmaElements(design.elements)
    }));
    
    // Upload to Figma
    const result = await figmaAPI.createFrames(figmaFile, frames);
    
    return {
      fileUrl: result.url,
      fileId: result.id
    };
  },
  
  import: async (figmaUrl) => {
    const file = await figmaAPI.getFile(figmaUrl);
    return convertFigmaToDesigns(file);
  }
};
```

### API Endpoints

```javascript
// .claude/api/design-service.js

const designAPI = {
  endpoints: {
    '/generate': async (req) => {
      const { prompt, options } = req.body;
      
      // Use orchestrator
      const result = await uiDesigner.generate(
        prompt,
        options
      );
      
      return {
        designs: result.designs,
        tokens: result.tokens,
        documentation: result.docs
      };
    },
    
    '/iterate': async (req) => {
      const { designId, feedback } = req.body;
      
      const result = await uiDesigner.iterateDesigns(
        feedback
      );
      
      return result;
    }
  }
};
```

---

## Advanced Customization

### Custom UI Generator Rules

```javascript
// .claude/config/generation-rules.js

const customGenerationRules = {
  // Company-specific patterns
  patterns: {
    headers: {
      structure: 'logo-left navigation-center actions-right',
      height: { min: 60, max: 80 },
      sticky: 'always',
      background: 'solid-color no-gradients'
    },
    
    forms: {
      validation: 'inline-immediate',
      labels: 'always-visible',
      errors: 'below-field red-text',
      submit: 'full-width-mobile right-align-desktop'
    }
  },
  
  // Forbidden patterns
  avoid: [
    'hamburger-menu-desktop',
    'infinite-scroll',
    'auto-playing-videos',
    'popup-modals-on-load'
  ],
  
  // Performance budgets
  performance: {
    images: { maxSize: '200KB', format: 'webp' },
    fonts: { maxCustom: 2 },
    animations: { maxDuration: '300ms' }
  }
};
```

### Orchestration Overrides

```javascript
// .claude/config/orchestration.js

const orchestrationConfig = {
  // Change default specialist assignments
  specialistMapping: {
    'e-commerce': ['ux-researcher', 'conversion-optimizer', 'ui-generator'],
    'dashboard': ['data-viz-expert', 'ui-generator', 'performance-optimizer'],
    'marketing': ['brand-strategist', 'copywriter', 'ui-generator']
  },
  
  // Custom parallel execution
  parallelization: {
    maxAgents: 8,
    strategy: 'resource-aware',
    prioritization: 'user-impact'
  },
  
  // Quality gates
  qualityChecks: {
    required: ['accessibility', 'performance', 'brand-compliance'],
    optional: ['seo', 'internationalization'],
    thresholds: {
      accessibility: 95,
      performance: 90,
      brandCompliance: 100
    }
  }
};
```

### Plugin System

```javascript
// .claude/plugins/custom-validator.js

class CustomValidator {
  constructor(rules) {
    this.rules = rules;
  }
  
  async validate(design) {
    const results = await Promise.all(
      this.rules.map(rule => rule.check(design))
    );
    
    return {
      passed: results.every(r => r.passed),
      violations: results.filter(r => !r.passed),
      warnings: results.filter(r => r.warning)
    };
  }
}

// Register plugin
orchestrator.registerPlugin('validator', new CustomValidator(customRules));
```

### Environment-Specific Configurations

```javascript
// .claude/config/environments.js

const environments = {
  development: {
    memory: { cache: false },
    logging: { level: 'debug' },
    parallelization: { maxAgents: 3 }
  },
  
  staging: {
    memory: { cache: true, ttl: 3600 },
    logging: { level: 'info' },
    parallelization: { maxAgents: 5 }
  },
  
  production: {
    memory: { cache: true, ttl: 86400 },
    logging: { level: 'error' },
    parallelization: { maxAgents: 10 },
    monitoring: { enabled: true }
  }
};

// Apply based on environment
const config = environments[process.env.UI_ORCHESTRATOR_ENV || 'development'];
```

---

## Best Practices for Customization

### 1. Version Control

```bash
# Track customizations separately
git init .claude-custom
git add .
git commit -m "Initial customizations"

# Create branches for experiments
git checkout -b experiment/new-workflow
```

### 2. Testing Customizations

```javascript
// .claude/tests/custom-specialist.test.js

const testCustomSpecialist = async () => {
  const testCases = [
    {
      input: 'Create button',
      expected: 'Uses company branded button'
    },
    {
      input: 'Generate form',
      expected: 'Includes custom validation'
    }
  ];
  
  for (const test of testCases) {
    const result = await orchestrator.execute(test.input);
    assert(result.includes(test.expected));
  }
};
```

### 3. Documentation

```markdown
# Custom Configuration Documentation

## Overview
Document all customizations for team reference

## Custom Specialists
- motion-designer: Added for animation needs
- conversion-optimizer: E-commerce focus

## Custom Commands
- generate-email-templates: Email design automation
- design-review: Automated QA process

## Modified Workflows
- startup-mvp: 10-day rapid process
- enterprise-transformation: 17-week comprehensive
```

### 4. Maintenance

```
# Regular updates
"Check for UI Designer updates"

# Validate customizations still work
"Validate all custom configurations for the UI Designer"

# Backup configurations
"Create a backup of UI Designer configurations to custom-backup.tar.gz"
```

---

*Customization Guide v1.0 | Extend and adapt | Your workflow, your way*