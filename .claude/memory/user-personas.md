# User Personas Memory

Persistent storage for user persona data across design sessions.

## Memory Structure

```json
{
  "personas": {
    "primary": {
      "id": "persona_001",
      "name": "Sarah Chen",
      "archetype": "The Efficient Professional",
      "demographics": {
        "age": 32,
        "occupation": "Product Manager",
        "location": "San Francisco, CA",
        "income": "$95,000-120,000",
        "education": "MBA"
      },
      "psychographics": {
        "values": ["Efficiency", "Growth", "Balance"],
        "motivations": ["Career advancement", "Time savings", "Learning"],
        "frustrations": ["Complexity", "Time waste", "Poor UX"],
        "personality": ["Analytical", "Driven", "Tech-savvy"]
      },
      "behaviors": {
        "technology": {
          "comfort": "Advanced",
          "devices": ["iPhone 14", "MacBook Pro", "iPad"],
          "apps": ["Notion", "Slack", "Linear", "Figma"]
        },
        "workStyle": {
          "schedule": "9-6 with flex",
          "remote": "Hybrid 3 days office",
          "collaboration": "Cross-functional teams"
        },
        "painPoints": {
          "current": [
            "Too many tools to manage",
            "Context switching fatigue",
            "Manual data aggregation"
          ]
        }
      },
      "goals": {
        "immediate": "Streamline daily workflow",
        "shortTerm": "Improve team productivity",
        "longTerm": "Become VP of Product"
      },
      "quotes": [
        "I need insights, not just data",
        "Every minute counts in my day",
        "If it's not intuitive, it's not worth it"
      ],
      "designImplications": {
        "must": ["Quick access", "Keyboard shortcuts", "Mobile sync"],
        "should": ["Customization", "Integration APIs", "Bulk actions"],
        "nice": ["AI assistance", "Predictive features", "Collaboration"]
      }
    },
    
    "secondary": {
      "id": "persona_002",
      "name": "Marcus Johnson",
      "archetype": "The Creative Explorer",
      "demographics": {
        "age": 27,
        "occupation": "Freelance Designer",
        "location": "Austin, TX",
        "income": "$55,000-75,000",
        "education": "BFA Design"
      },
      "psychographics": {
        "values": ["Creativity", "Freedom", "Innovation"],
        "motivations": ["Self-expression", "Client satisfaction", "Skill growth"],
        "frustrations": ["Rigid tools", "Client communication", "Admin tasks"]
      },
      "behaviors": {
        "workStyle": {
          "schedule": "Flexible/project-based",
          "workspace": "Home studio + coffee shops",
          "process": "Iterative and experimental"
        }
      },
      "designImplications": {
        "must": ["Visual flexibility", "Inspiration features", "Easy sharing"],
        "should": ["Version control", "Client portals", "Time tracking"]
      }
    },
    
    "tertiary": {
      "id": "persona_003",
      "name": "Elena Rodriguez",
      "archetype": "The Team Builder",
      "demographics": {
        "age": 45,
        "occupation": "Engineering Director",
        "location": "Chicago, IL",
        "income": "$150,000+",
        "education": "MS Computer Science"
      },
      "behaviors": {
        "leadership": {
          "teamSize": "25 engineers",
          "style": "Servant leadership",
          "priorities": ["Team health", "Delivery", "Innovation"]
        }
      },
      "designImplications": {
        "must": ["Team dashboards", "Permission systems", "Audit trails"],
        "should": ["Resource planning", "Analytics", "Integrations"]
      }
    }
  },
  
  "metadata": {
    "lastUpdated": "2024-01-20T10:30:00Z",
    "project": "UI Designer Orchestrator",
    "version": "1.0",
    "validatedThrough": {
      "interviews": 24,
      "surveys": 156,
      "usabilityTests": 18
    }
  },
  
  "usage": {
    "commands": [
      "memory.get('personas.primary')",
      "memory.update('personas.secondary.behaviors')",
      "memory.query('personas.*.painPoints')"
    ],
    "integration": [
      "Referenced by UI Generator for interface creation",
      "Used by UX Researcher for journey mapping",
      "Consulted by Brand Strategist for voice/tone"
    ]
  }
}
```

## Persona Templates

### Quick Persona Generator
```javascript
const createPersona = {
  minimal: {
    name: "string",
    role: "string",
    keyNeed: "string",
    mainPain: "string"
  },
  
  standard: {
    demographics: ["age", "occupation", "location"],
    psychographics: ["values", "motivations", "frustrations"],
    behaviors: ["daily routine", "tool usage", "decision process"],
    goals: ["immediate", "future"],
    quote: "Memorable statement"
  },
  
  detailed: {
    // All standard fields plus:
    journey: "Detailed user journey",
    ecosystem: "Tools and touchpoints",
    influences: "Decision influencers",
    scenarios: "Usage scenarios"
  }
};
```

## Dynamic Updates

### Learning from Interactions
```javascript
const updatePersona = async (personaId, newData) => {
  const current = await memory.get(`personas.${personaId}`);
  
  const updated = {
    ...current,
    ...newData,
    metadata: {
      ...current.metadata,
      lastUpdated: new Date().toISOString(),
      updateCount: (current.metadata.updateCount || 0) + 1
    }
  };
  
  await memory.set(`personas.${personaId}`, updated);
  
  // Notify dependent systems
  await notifySpecialists(['ux-researcher', 'ui-generator'], {
    event: 'persona-updated',
    personaId,
    changes: newData
  });
};
```

### Persona Evolution
```javascript
const evolvePersona = {
  triggers: [
    "New user research completed",
    "Behavioral pattern changes detected",
    "Market segment shift identified",
    "Product pivot or expansion"
  ],
  
  process: async (trigger, data) => {
    const analysis = await analyzeImpact(trigger, data);
    
    if (analysis.significantChange) {
      const updates = await generateUpdates(analysis);
      await reviewWithStakeholders(updates);
      await applyUpdates(updates);
    }
    
    return logEvolution(trigger, analysis);
  }
};
```

## Cross-Reference System

### Related Memory Links
```javascript
const personaConnections = {
  "persona_001": {
    relatedTo: {
      journeys: ["journey_001", "journey_003"],
      preferences: ["pref_efficiency", "pref_minimal"],
      projects: ["project_dashboard", "project_mobile"]
    }
  },
  
  "persona_002": {
    relatedTo: {
      journeys: ["journey_002"],
      preferences: ["pref_creative", "pref_flexible"],
      projects: ["project_portfolio", "project_collaboration"]
    }
  }
};
```

## Query Interface

### Common Queries
```javascript
// Get all personas for a project
memory.query('personas.*', { project: 'dashboard-redesign' });

// Find personas with specific pain points
memory.query('personas.*.painPoints', { contains: 'time management' });

// Get design implications across all personas
memory.aggregate('personas.*.designImplications.must');

// Find personas by demographic
memory.filter('personas.*', { 
  'demographics.age': { between: [25, 35] },
  'demographics.location': { includes: 'CA' }
});
```

## Maintenance

### Validation Rules
```javascript
const personaValidation = {
  required: ['name', 'demographics.age', 'goals', 'painPoints'],
  
  formats: {
    age: 'number',
    email: 'email',
    income: 'range'
  },
  
  consistency: {
    quotes: 'Must align with personality',
    goals: 'Must address pain points',
    behaviors: 'Must match demographics'
  }
};
```

### Archival Policy
```javascript
const archivalPolicy = {
  active: "Currently referenced in active projects",
  inactive: "No references in 90 days",
  archived: "Moved to cold storage after 180 days",
  
  restoration: "Can restore archived personas within 24 hours"
};
```

---

*User Personas Memory v1.0 | Persistent persona storage | Cross-project intelligence*