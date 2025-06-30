# Design Preferences Memory

Persistent storage for design preferences, patterns, and style decisions across projects and sessions.

## Access Instructions

### When to Access This Memory
- At the start of any visual design task
- When generating UI variations or components
- Before making color, typography, or layout decisions
- When ensuring consistency across designs

### How to Recall This Information
```
"Accessing stored design preferences...
Previous selections indicate preference for [style characteristics].
Applying established patterns: [specific patterns].
Maintaining consistency with [previous decisions]."
```

### How to Update This Memory
```
"I'll remember your preference for [specific design choice].
This has been noted in design preferences and will be applied to:
- Future component variations
- Color and typography decisions
- Layout and spacing patterns"
```

## Memory Structure

```json
{
  "preferences": {
    "global": {
      "colorSchemes": {
        "preferred": ["Blue-based", "High contrast", "Minimal palette"],
        "avoided": ["Neon", "Low contrast", "Busy patterns"],
        "accessibility": {
          "colorBlindSafe": true,
          "minContrast": 4.5,
          "darkModeRequired": true
        }
      },
      
      "typography": {
        "headerFont": {
          "preferred": ["Inter", "SF Pro", "Helvetica Neue"],
          "style": "Sans-serif, clean, modern",
          "weights": [400, 600, 700]
        },
        "bodyFont": {
          "preferred": ["Inter", "System UI"],
          "size": {
            "min": 16,
            "comfortable": 18,
            "lineHeight": 1.6
          }
        },
        "scale": {
          "type": "Major Third",
          "ratio": 1.25
        }
      },
      
      "spacing": {
        "system": "8px grid",
        "preferences": {
          "tight": false,
          "generous": true,
          "consistent": true
        },
        "patterns": {
          "componentPadding": 24,
          "sectionSpacing": 64,
          "elementGap": 16
        }
      },
      
      "interactions": {
        "animations": {
          "preferred": true,
          "duration": "200-300ms",
          "easing": "ease-out",
          "types": ["Subtle", "Purposeful", "Smooth"]
        },
        "feedback": {
          "hover": "Subtle lift or color shift",
          "click": "Brief scale down",
          "loading": "Skeleton screens preferred"
        }
      }
    },
    
    "projectSpecific": {
      "project_123": {
        "name": "SaaS Dashboard",
        "established": "2024-01-15",
        "theme": {
          "personality": ["Professional", "Efficient", "Trustworthy"],
          "colorOverrides": {
            "primary": "#0066CC",
            "secondary": "#00AA55"
          },
          "componentStyles": {
            "cards": "Flat with subtle shadow",
            "buttons": "Rounded corners (6px)",
            "inputs": "Outlined style"
          }
        }
      },
      
      "project_124": {
        "name": "E-commerce Mobile",
        "established": "2024-01-18",
        "theme": {
          "personality": ["Friendly", "Vibrant", "Accessible"],
          "mobileFirst": true,
          "touchTargets": {
            "minimum": 48,
            "comfortable": 56
          }
        }
      }
    },
    
    "userPatterns": {
      "observedPreferences": {
        "colorChoices": {
          "blue": { count: 45, success: 0.89 },
          "green": { count: 23, success: 0.91 },
          "red": { count: 12, success: 0.67 }
        },
        "layoutChoices": {
          "sidebar": { count: 34, success: 0.88 },
          "topNav": { count: 28, success: 0.82 },
          "hybrid": { count: 15, success: 0.93 }
        },
        "densityPreferences": {
          "spacious": { selected: 67, rating: 4.5 },
          "compact": { selected: 23, rating: 3.8 },
          "cozy": { selected: 45, rating: 4.2 }
        }
      }
    }
  },
  
  "patterns": {
    "successful": [
      {
        "id": "pattern_001",
        "name": "Card-based Dashboard",
        "usage": 12,
        "satisfaction": 4.7,
        "elements": {
          "layout": "Grid with consistent gaps",
          "cards": "White bg, subtle shadow, 8px radius",
          "metrics": "Large number, small label above"
        }
      },
      {
        "id": "pattern_002",
        "name": "Progressive Onboarding",
        "usage": 8,
        "satisfaction": 4.8,
        "elements": {
          "steps": "3-5 maximum",
          "progress": "Linear indicator at top",
          "skippable": "Always provide skip option"
        }
      }
    ],
    
    "avoided": [
      {
        "pattern": "Hamburger menu on desktop",
        "reason": "Poor discoverability",
        "alternatives": ["Visible navigation", "Mega menu"]
      },
      {
        "pattern": "Infinite scroll for critical content",
        "reason": "Accessibility issues",
        "alternatives": ["Pagination", "Load more button"]
      }
    ]
  },
  
  "decisions": {
    "documented": [
      {
        "date": "2024-01-10",
        "decision": "Always use blue for primary actions",
        "rationale": "Highest conversion in A/B tests",
        "evidence": "15% higher CTR than green"
      },
      {
        "date": "2024-01-12",
        "decision": "Minimum 44px touch targets",
        "rationale": "Accessibility and mobile UX",
        "evidence": "Reduced mis-taps by 73%"
      }
    ]
  }
}
```

## Preference Learning

### Pattern Recognition
```javascript
const learnPreferences = {
  trackChoice: async (category, choice, outcome) => {
    const path = `preferences.userPatterns.observedPreferences.${category}.${choice}`;
    const current = await memory.get(path) || { count: 0, success: 0 };
    
    const updated = {
      count: current.count + 1,
      success: outcome.success 
        ? (current.success * current.count + 1) / (current.count + 1)
        : (current.success * current.count) / (current.count + 1)
    };
    
    await memory.set(path, updated);
    
    // Adapt future suggestions
    if (updated.count > 10 && updated.success > 0.8) {
      await promoteToPreferred(category, choice);
    }
  },
  
  analyzePatterns: async () => {
    const patterns = await memory.get('preferences.userPatterns');
    
    return {
      strongPreferences: filterHighSuccess(patterns),
      emergingTrends: identifyTrends(patterns),
      recommendations: generateRecommendations(patterns)
    };
  }
};
```

### Adaptive Defaults
```javascript
const adaptiveDefaults = {
  getDefaults: async (context) => {
    const global = await memory.get('preferences.global');
    const patterns = await memory.get('preferences.patterns.successful');
    const specific = await memory.get(`preferences.projectSpecific.${context.projectId}`);
    
    return merge(
      global,
      filterRelevantPatterns(patterns, context),
      specific
    );
  },
  
  suggestBased: async (elementType) => {
    const history = await memory.get(`preferences.userPatterns.observedPreferences.${elementType}`);
    
    return Object.entries(history)
      .sort((a, b) => (b[1].success * b[1].count) - (a[1].success * a[1].count))
      .slice(0, 3)
      .map(([choice, data]) => ({
        suggestion: choice,
        confidence: data.success,
        usage: data.count
      }));
  }
};
```

## Style Evolution

### Version Control
```javascript
const styleVersioning = {
  checkpoint: async (projectId, description) => {
    const current = await memory.get(`preferences.projectSpecific.${projectId}`);
    const version = {
      id: generateVersionId(),
      timestamp: new Date().toISOString(),
      description,
      snapshot: current
    };
    
    await memory.append(`preferences.history.${projectId}`, version);
    return version.id;
  },
  
  rollback: async (projectId, versionId) => {
    const history = await memory.get(`preferences.history.${projectId}`);
    const version = history.find(v => v.id === versionId);
    
    if (version) {
      await memory.set(`preferences.projectSpecific.${projectId}`, version.snapshot);
      return { success: true, rolled_back_to: version };
    }
    
    return { success: false, error: 'Version not found' };
  }
};
```

## Integration Patterns

### With Design Commands
```javascript
const preferenceIntegration = {
  beforeGeneration: async (command, params) => {
    const defaults = await adaptiveDefaults.getDefaults(params.context);
    
    return {
      ...params,
      styleHints: defaults,
      avoidPatterns: await memory.get('preferences.patterns.avoided')
    };
  },
  
  afterGeneration: async (command, result, feedback) => {
    if (feedback.selected) {
      await learnPreferences.trackChoice(
        command,
        result.variant,
        { success: true }
      );
    }
  }
};
```

### Cross-Project Intelligence
```javascript
const crossProjectLearning = {
  shareSuccessfulPatterns: async (pattern, sourceProject) => {
    const success = {
      ...pattern,
      sourceProject,
      sharedDate: new Date().toISOString()
    };
    
    await memory.append('preferences.patterns.successful', success);
    
    // Notify other active projects
    await notifyProjects({
      event: 'new-successful-pattern',
      pattern: success
    });
  },
  
  findSimilarProjects: async (projectProfile) => {
    const allProjects = await memory.get('preferences.projectSpecific');
    
    return Object.entries(allProjects)
      .map(([id, project]) => ({
        id,
        ...project,
        similarity: calculateSimilarity(projectProfile, project)
      }))
      .filter(p => p.similarity > 0.7)
      .sort((a, b) => b.similarity - a.similarity);
  }
};
```

## Preference Queries

### Common Operations
```javascript
// Get preferred colors for a project
memory.get('preferences.projectSpecific.project_123.theme.colorOverrides');

// Find all successful patterns using cards
memory.query('preferences.patterns.successful', { 
  'elements.cards': { exists: true } 
});

// Get animation preferences
memory.get('preferences.global.interactions.animations');

// Find avoided patterns with alternatives
memory.map('preferences.patterns.avoided', pattern => ({
  avoid: pattern.pattern,
  use: pattern.alternatives
}));
```

## Maintenance

### Preference Cleanup
```javascript
const cleanupPreferences = {
  removeOutdated: async () => {
    const sixMonthsAgo = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);
    
    const patterns = await memory.get('preferences.patterns');
    const filtered = patterns.filter(p => 
      new Date(p.lastUsed) > sixMonthsAgo
    );
    
    await memory.set('preferences.patterns', filtered);
  },
  
  consolidateSimilar: async () => {
    const patterns = await memory.get('preferences.patterns.successful');
    const consolidated = groupBySimilarity(patterns, 0.85);
    
    await memory.set('preferences.patterns.successful', consolidated);
  }
};
```

---

*Design Preferences Memory v1.0 | Adaptive style learning | Cross-project intelligence*