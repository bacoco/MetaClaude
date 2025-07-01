# User Research Driven Pattern

Design methodology that prioritizes user insights, data, and validation throughout the entire design process.

## Pattern Overview

User Research Driven design ensures every design decision is backed by real user data, behavioral insights, and validated assumptions.

```
RESEARCH → INSIGHTS → DESIGN → TEST → ITERATE
    ↑                                      ↓
    └──────────── CONTINUOUS LOOP ─────────┘
```

## Research Framework

### 1. User Research Methods
```javascript
const researchMethods = {
  discovery: {
    interviews: {
      type: 'Qualitative',
      participants: '8-12 users',
      duration: '45-60 minutes',
      output: 'Pain points, needs, goals',
      when: 'Project start, major pivots'
    },
    
    surveys: {
      type: 'Quantitative',
      participants: '100+ users',
      duration: '10-15 minutes',
      output: 'Statistical patterns, preferences',
      when: 'Validation, segmentation'
    },
    
    ethnography: {
      type: 'Observational',
      participants: '5-8 users',
      duration: '2-4 hours',
      output: 'Behavioral patterns, context',
      when: 'Deep understanding needed'
    },
    
    analytics: {
      type: 'Behavioral',
      participants: 'All users',
      duration: 'Continuous',
      output: 'Usage patterns, drop-offs',
      when: 'Always running'
    }
  },
  
  validation: {
    usabilityTesting: {
      type: 'Task-based',
      participants: '5-8 users',
      duration: '30-45 minutes',
      output: 'Task success, pain points',
      when: 'Pre-launch, major changes'
    },
    
    aBTesting: {
      type: 'Comparative',
      participants: 'Statistical sample',
      duration: '2-4 weeks',
      output: 'Performance metrics',
      when: 'Optimization phase'
    },
    
    cardSorting: {
      type: 'Information architecture',
      participants: '15-30 users',
      duration: '20-30 minutes',
      output: 'Mental models, categories',
      when: 'IA design'
    }
  }
};
```

### 2. Research Planning
```javascript
class ResearchPlanner {
  planResearch(projectGoals) {
    const plan = {
      objectives: this.defineObjectives(projectGoals),
      questions: this.formulateQuestions(objectives),
      methods: this.selectMethods(questions),
      timeline: this.createTimeline(methods),
      recruitment: this.planRecruitment(methods)
    };
    
    return plan;
  }
  
  defineObjectives(goals) {
    return {
      primary: 'What core problem are we solving?',
      secondary: [
        'Who experiences this problem?',
        'What are current solutions?',
        'What are the constraints?'
      ],
      success: 'How will we measure success?'
    };
  }
  
  formulateQuestions(objectives) {
    return {
      screening: [
        'Do you currently [use case]?',
        'How often do you [frequency]?',
        'What tools do you use for [task]?'
      ],
      
      interview: {
        opening: 'Tell me about your experience with...',
        specific: 'Walk me through the last time you...',
        pain: 'What\'s the most frustrating part of...',
        ideal: 'If you had a magic wand, how would...'
      },
      
      survey: {
        demographic: generateDemographicQuestions(),
        behavioral: generateBehavioralQuestions(),
        attitudinal: generateAttitudinalQuestions()
      }
    };
  }
}
```

### 3. Data Collection
```javascript
const dataCollection = {
  tools: {
    interviews: {
      recording: 'Zoom, Google Meet',
      transcription: 'Otter.ai, Rev',
      analysis: 'Miro, Dovetail'
    },
    
    surveys: {
      creation: 'Typeform, Google Forms',
      distribution: 'Email, social, in-app',
      analysis: 'SPSS, R, Excel'
    },
    
    analytics: {
      quantitative: 'Google Analytics, Mixpanel',
      qualitative: 'Hotjar, FullStory',
      custom: 'Internal tracking'
    }
  },
  
  protocols: {
    consent: 'Obtain before recording',
    privacy: 'Anonymize personal data',
    storage: 'Secure, time-limited',
    sharing: 'Need-to-know basis'
  }
};
```

## Insight Synthesis

### 1. Affinity Mapping
```javascript
class AffinityMapper {
  mapInsights(rawData) {
    const insights = this.extractInsights(rawData);
    const clusters = this.clusterInsights(insights);
    const themes = this.identifyThemes(clusters);
    
    return {
      themes,
      patterns: this.findPatterns(themes),
      opportunities: this.identifyOpportunities(themes),
      personas: this.derivePersonas(themes)
    };
  }
  
  extractInsights(data) {
    return data.map(item => ({
      quote: item.text,
      user: item.participant,
      context: item.situation,
      emotion: item.sentiment,
      need: this.inferNeed(item)
    }));
  }
  
  clusterInsights(insights) {
    const clusters = {};
    
    insights.forEach(insight => {
      const category = this.categorize(insight);
      if (!clusters[category]) {
        clusters[category] = [];
      }
      clusters[category].push(insight);
    });
    
    return clusters;
  }
}
```

### 2. Persona Development
```javascript
const personaDevelopment = {
  dataRequired: {
    demographic: ['Age', 'Location', 'Occupation', 'Income'],
    psychographic: ['Values', 'Goals', 'Motivations', 'Frustrations'],
    behavioral: ['Usage patterns', 'Preferences', 'Pain points'],
    technographic: ['Devices', 'Platforms', 'Comfort level']
  },
  
  template: {
    name: 'Sarah Chen',
    tagline: 'The Efficiency Seeker',
    demographics: {
      age: 32,
      occupation: 'Product Manager',
      location: 'Urban',
      income: '$90k-120k'
    },
    goals: [
      'Save time on routine tasks',
      'Make data-driven decisions',
      'Advance career'
    ],
    frustrations: [
      'Too many tools to manage',
      'Inconsistent data sources',
      'Manual report creation'
    ],
    behaviors: {
      dailyRoutine: 'Checks metrics first thing',
      toolUsage: 'Power user of shortcuts',
      decisionMaking: 'Relies on data'
    },
    quote: "I need insights, not just numbers"
  }
};
```

### 3. Journey Mapping
```javascript
const journeyMapping = {
  stages: [
    {
      name: 'Awareness',
      userGoal: 'Realize need for solution',
      touchpoints: ['Search', 'Social', 'Word of mouth'],
      emotions: ['Frustrated', 'Hopeful'],
      painPoints: ['Too many options', 'Unclear benefits'],
      opportunities: ['Clear value prop', 'Social proof']
    },
    {
      name: 'Consideration',
      userGoal: 'Evaluate options',
      touchpoints: ['Website', 'Reviews', 'Demo'],
      emotions: ['Analytical', 'Cautious'],
      painPoints: ['Complex pricing', 'Feature overload'],
      opportunities: ['Simple comparison', 'Free trial']
    },
    {
      name: 'Decision',
      userGoal: 'Choose solution',
      touchpoints: ['Pricing page', 'Support', 'Checkout'],
      emotions: ['Committed', 'Anxious'],
      painPoints: ['Hidden costs', 'Complex setup'],
      opportunities: ['Transparency', 'Quick start']
    }
  ],
  
  mapping: (research) => {
    return stages.map(stage => ({
      ...stage,
      insights: extractStageInsights(research, stage),
      designImplications: deriveDesignNeeds(stage)
    }));
  }
};
```

## Design Translation

### 1. Insight to Design
```javascript
const insightToDesign = {
  translate(insight) {
    return {
      insight: insight.text,
      designPrinciple: this.derivePrinciple(insight),
      designSolution: this.proposeSolution(insight),
      successMetric: this.defineMetric(insight)
    };
  },
  
  examples: [
    {
      insight: "Users abandon cart due to unexpected shipping costs",
      principle: "Transparency builds trust",
      solution: "Show shipping calculator on product page",
      metric: "Cart abandonment rate reduction"
    },
    {
      insight: "Power users want keyboard shortcuts",
      principle: "Efficiency for frequent tasks",
      solution: "Comprehensive shortcut system with discovery",
      metric: "Task completion time reduction"
    }
  ]
};
```

### 2. Research-Based Components
```javascript
// Component design based on user research
const ResearchBasedButton = ({ 
  children, 
  variant, 
  size,
  // Research insight: Users often miss small buttons
  minTouchTarget = 44,
  // Research insight: Users need clear feedback
  loadingText = "Processing...",
  // Research insight: Error states confuse users
  errorText = "Try again",
  ...props 
}) => {
  const [state, setState] = useState('default');
  
  // Research-driven styling
  const styles = {
    // Insight: Sufficient contrast needed
    primary: 'bg-blue-600 text-white hover:bg-blue-700',
    // Insight: Secondary actions need distinction
    secondary: 'bg-gray-200 text-gray-900 hover:bg-gray-300',
    // Insight: Destructive actions need warning
    danger: 'bg-red-600 text-white hover:bg-red-700'
  };
  
  return (
    <button
      className={cn(
        styles[variant],
        // Research: Minimum touch target
        'min-h-[44px] min-w-[44px]',
        // Research: Clear focus indicators
        'focus:ring-2 focus:ring-offset-2',
        // Research: Smooth transitions
        'transition-all duration-200'
      )}
      aria-busy={state === 'loading'}
      aria-label={state === 'loading' ? loadingText : undefined}
      {...props}
    >
      {state === 'loading' ? loadingText : children}
    </button>
  );
};
```

### 3. Validation Loops
```javascript
const validationLoop = {
  async validateDesign(design, hypothesis) {
    // 1. Create prototype
    const prototype = await createPrototype(design);
    
    // 2. Define test protocol
    const protocol = {
      tasks: defineTasksFromHypothesis(hypothesis),
      metrics: defineSuccessMetrics(hypothesis),
      participants: recruitParticipants(5)
    };
    
    // 3. Run tests
    const results = await runUsabilityTests(prototype, protocol);
    
    // 4. Analyze results
    const analysis = {
      taskSuccess: calculateSuccessRate(results),
      issues: identifyUsabilityIssues(results),
      insights: extractNewInsights(results)
    };
    
    // 5. Iterate or ship
    return analysis.taskSuccess > 0.8 ? 'ship' : 'iterate';
  }
};
```

## Research-Driven Patterns

### Pattern: Progressive Disclosure
```javascript
// Based on research: Users overwhelmed by too many options
const ProgressiveDisclosure = {
  pattern: 'Show essential, hide advanced',
  
  implementation: {
    initial: 'Core features visible',
    progressive: 'Advanced on demand',
    personalized: 'Learn user preferences'
  },
  
  example: `
    <Form>
      {/* Essential fields */}
      <Input name="email" required />
      <Input name="password" required />
      
      {/* Progressive reveal */}
      <CollapsibleSection title="Advanced options">
        <Input name="timezone" />
        <Input name="language" />
        <Input name="notifications" />
      </CollapsibleSection>
    </Form>
  `,
  
  metrics: {
    completion: 'Form completion rate',
    time: 'Time to complete',
    errors: 'Error rate reduction'
  }
};
```

### Pattern: Contextual Help
```javascript
// Based on research: Users prefer inline help over documentation
const ContextualHelp = {
  pattern: 'Help where and when needed',
  
  triggers: {
    hover: 'Quick tooltips',
    focus: 'Detailed help',
    error: 'Solution-focused',
    firstUse: 'Onboarding tips'
  },
  
  implementation: `
    <FormField>
      <Label>
        API Key
        <HelpIcon 
          tooltip="Find in Settings > Developer"
          article="/help/api-keys"
        />
      </Label>
      <Input 
        name="apiKey"
        onError={(error) => (
          <ErrorHelp>
            {error.code === 'INVALID_FORMAT' 
              ? 'API keys start with "sk_"'
              : 'Check your developer settings'
            }
          </ErrorHelp>
        )}
      />
    </FormField>
  `
};
```

## Measurement Framework

### 1. Success Metrics
```javascript
const successMetrics = {
  behavioral: {
    taskSuccess: {
      definition: 'Users complete intended action',
      measurement: 'Completion rate',
      target: '> 80%'
    },
    
    efficiency: {
      definition: 'Time to complete task',
      measurement: 'Average duration',
      target: '< 2 minutes'
    },
    
    errors: {
      definition: 'Mistakes during task',
      measurement: 'Error rate',
      target: '< 5%'
    }
  },
  
  attitudinal: {
    satisfaction: {
      definition: 'User satisfaction',
      measurement: 'CSAT score',
      target: '> 4.5/5'
    },
    
    ease: {
      definition: 'Perceived ease of use',
      measurement: 'SUS score',
      target: '> 80'
    },
    
    recommendation: {
      definition: 'Would recommend',
      measurement: 'NPS',
      target: '> 50'
    }
  }
};
```

### 2. Continuous Research
```javascript
const continuousResearch = {
  daily: {
    analytics: 'Monitor key metrics',
    support: 'Analyze tickets',
    feedback: 'Review user comments'
  },
  
  weekly: {
    sessions: 'Watch user recordings',
    surveys: 'Send micro-surveys',
    team: 'Share insights'
  },
  
  monthly: {
    interviews: '3-5 user interviews',
    testing: 'Usability test new features',
    report: 'Synthesize findings'
  },
  
  quarterly: {
    personas: 'Update based on data',
    journey: 'Refine journey maps',
    strategy: 'Adjust research focus'
  }
};
```

## Integration Workflow

### Research Integration Pipeline
```javascript
class ResearchIntegration {
  async integrateFindings(research) {
    // 1. Process research data
    const insights = await this.processResearch(research);
    
    // 2. Update design system
    const tokenUpdates = this.deriveTokenChanges(insights);
    const componentUpdates = this.deriveComponentChanges(insights);
    
    // 3. Generate design variations
    const designs = await this.generateDesigns(insights);
    
    // 4. Validate with users
    const validation = await this.validateDesigns(designs);
    
    // 5. Implement winners
    return this.implementValidated(validation);
  }
}
```

---

*User Research Driven v1.0 | Evidence-based design | Continuous validation*