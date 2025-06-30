# Design Sprint Workflow

5-day intensive design process based on Google Ventures methodology, accelerated with AI-powered multi-agent orchestration.

## Sprint Overview

```
MONDAY: Understand
TUESDAY: Diverge  
WEDNESDAY: Decide
THURSDAY: Prototype
FRIDAY: Test
```

## Pre-Sprint Preparation

```javascript
const sprintPrep = {
  timeline: '1 week before',
  
  tasks: {
    recruiting: {
      participants: 'Schedule 5 test users for Friday',
      team: 'Confirm 5-7 sprint team members',
      decider: 'Ensure key decision maker availability'
    },
    
    research: {
      background: 'Compile existing research',
      analytics: 'Gather usage data',
      competitive: 'Quick competitor scan'
    },
    
    logistics: {
      space: 'Book sprint room all week',
      supplies: 'Whiteboards, sticky notes, markers',
      digital: 'Miro/FigJam board setup'
    }
  },
  
  agents: {
    preparation: ['ux-researcher', 'brand-strategist'],
    coordinator: 'workflow-dispatcher'
  }
};
```

## Day 1: Monday - Understand

### Morning: Problem Definition
```javascript
const monday = {
  morning: {
    duration: '9:00 AM - 12:30 PM',
    
    activities: [
      {
        time: '9:00-9:30',
        activity: 'Sprint Kickoff',
        lead: 'design-orchestrator',
        output: 'Shared understanding of challenge'
      },
      {
        time: '9:30-10:30',
        activity: 'Long-term Goal & Sprint Questions',
        process: async () => {
          const goal = await defineLongTermGoal();
          const questions = await generateSprintQuestions();
          const metrics = await defineSuccessMetrics();
          
          return {
            goal: '2-year optimistic goal',
            questions: 'Can we... questions',
            metrics: 'Measurable outcomes'
          };
        }
      },
      {
        time: '10:30-12:30',
        activity: 'Expert Interviews',
        specialists: ['ux-researcher', 'brand-strategist'],
        interviews: [
          'Customer service (20 min)',
          'Sales team (20 min)',
          'Technical lead (20 min)',
          'Analytics expert (20 min)',
          'Previous customers (40 min)'
        ],
        output: 'How Might We notes'
      }
    ]
  },
  
  afternoon: {
    duration: '1:30 PM - 5:00 PM',
    
    activities: [
      {
        time: '1:30-3:00',
        activity: 'Map Creation',
        lead: 'ux-researcher',
        process: async () => {
          // Create customer journey map
          const actors = identifyActors();
          const steps = mapJourneySteps();
          const touchpoints = identifyTouchpoints();
          
          return createJourneyMap({
            actors,
            steps,
            touchpoints,
            format: 'End-to-end experience'
          });
        }
      },
      {
        time: '3:00-4:00',
        activity: 'HMW Clustering',
        process: 'Organize How Might We notes into themes'
      },
      {
        time: '4:00-5:00',
        activity: 'Target Selection',
        decider: true,
        output: 'Specific moment in journey to focus on'
      }
    ]
  },
  
  aiAcceleration: {
    overnight: async () => {
      // AI processes day's insights
      const insights = await analyzeHMWNotes();
      const patterns = await identifyPatterns();
      const opportunities = await generateOpportunities();
      
      return prepareForTuesday({
        insights,
        patterns,
        opportunities
      });
    }
  }
};
```

## Day 2: Tuesday - Diverge

### Ideation & Sketching
```javascript
const tuesday = {
  morning: {
    duration: '9:00 AM - 12:30 PM',
    
    activities: [
      {
        time: '9:00-10:00',
        activity: 'Lightning Demos',
        lead: 'design-analyst',
        process: async () => {
          // AI-enhanced inspiration
          const demos = await gatherInspiration({
            sources: ['Competitors', 'Analogous industries', 'Best-in-class'],
            count: 10,
            time: '3 minutes each'
          });
          
          return extractDesignDNA(demos);
        }
      },
      {
        time: '10:00-12:30',
        activity: 'Sketch Session',
        parallel: true,
        agents: [
          'ui-generator',
          'brand-strategist',
          'design-analyst'
        ],
        humanTeam: 'Simultaneous sketching',
        
        exercises: [
          {
            name: 'Notes',
            duration: '20 min',
            output: 'Key ideas capture'
          },
          {
            name: 'Ideas',
            duration: '20 min',
            output: 'Rough concepts'
          },
          {
            name: 'Crazy 8s',
            duration: '8 min',
            output: '8 variations in 8 minutes'
          },
          {
            name: 'Solution Sketch',
            duration: '90 min',
            output: '3-panel storyboard'
          }
        ]
      }
    ]
  },
  
  afternoon: {
    duration: '1:30 PM - 5:00 PM',
    
    activities: [
      {
        time: '1:30-3:00',
        activity: 'AI Concept Generation',
        pattern: 'parallel-ui-generation',
        process: async () => {
          // Generate variations based on morning sketches
          const concepts = await createUIVariations({
            inspiration: morningDemo,
            sketches: teamSketches,
            target: mondayTarget,
            variations: 10
          });
          
          return rankConcepts(concepts);
        }
      },
      {
        time: '3:00-5:00',
        activity: 'Concept Refinement',
        specialists: ['ui-generator', 'style-guide-expert'],
        output: 'Polished solution sketches'
      }
    ]
  }
};
```

## Day 3: Wednesday - Decide

### Critique & Selection
```javascript
const wednesday = {
  morning: {
    duration: '9:00 AM - 12:30 PM',
    
    activities: [
      {
        time: '9:00-10:00',
        activity: 'Art Museum',
        setup: 'Display all sketches and concepts',
        silentReview: true,
        voting: {
          heatMap: 'Dot voting on interesting parts',
          speedCritique: '3 min discussion per concept'
        }
      },
      {
        time: '10:00-11:30',
        activity: 'Straw Poll & Supervote',
        process: async () => {
          const votes = collectStrawPoll();
          const discussion = facilitateDebate();
          const decision = deciderSupervote();
          
          return {
            winner: decision.concept,
            rationale: decision.reasoning,
            elements: decision.mustInclude
          };
        }
      },
      {
        time: '11:30-12:30',
        activity: 'Storyboard Creation',
        lead: 'ux-researcher',
        output: 'Step-by-step prototype plan'
      }
    ]
  },
  
  afternoon: {
    duration: '1:30 PM - 5:00 PM',
    
    activities: [
      {
        time: '1:30-3:00',
        activity: 'Design System Setup',
        specialist: 'style-guide-expert',
        command: 'export-design-system',
        process: async () => {
          // Quick design system for prototype
          const dna = await extractDesignDNA(winningConcept);
          const tokens = await generateQuickTokens(dna);
          const components = await createEssentialComponents(tokens);
          
          return {
            colors: tokens.colors,
            typography: tokens.typography,
            components: components.essential
          };
        }
      },
      {
        time: '3:00-5:00',
        activity: 'Prototype Planning',
        tasks: [
          'Assign prototype scenes',
          'Gather/create assets',
          'Set up prototype tools',
          'Create task list for Thursday'
        ]
      }
    ]
  }
};
```

## Day 4: Thursday - Prototype

### Rapid Prototype Creation
```javascript
const thursday = {
  allDay: {
    duration: '9:00 AM - 6:00 PM',
    mode: 'Heads down production',
    
    orchestration: {
      pattern: 'parallel-ui-generation',
      
      agents: {
        'ui-generator': {
          tasks: ['Create all screens', 'Implement interactions'],
          count: 3 // Multiple instances
        },
        'style-guide-expert': {
          tasks: ['Ensure consistency', 'Polish visuals']
        },
        'ux-researcher': {
          tasks: ['Write realistic copy', 'Create test script']
        },
        'accessibility-auditor': {
          tasks: ['Quick a11y check', 'Fix critical issues']
        }
      }
    },
    
    timeline: [
      {
        time: '9:00-10:00',
        phase: 'Asset Preparation',
        parallel: true,
        tasks: [
          'Generate logos/icons',
          'Create placeholder content',
          'Set up prototype file'
        ]
      },
      {
        time: '10:00-2:00',
        phase: 'Screen Creation',
        command: 'create-ui-variations',
        process: async () => {
          const screens = storyboard.scenes;
          
          // Parallel screen generation
          const createdScreens = await Promise.all(
            screens.map(screen => 
              generateScreen({
                spec: screen,
                designSystem: wednesdaySystem,
                fidelity: 'high-enough'
              })
            )
          );
          
          return linkScreens(createdScreens);
        }
      },
      {
        time: '2:00-4:00',
        phase: 'Interaction & Polish',
        tasks: [
          'Add micro-interactions',
          'Create transitions',
          'Polish key moments'
        ]
      },
      {
        time: '4:00-5:00',
        phase: 'Trial Run',
        activity: 'Test with team member',
        fixes: 'Address critical issues only'
      },
      {
        time: '5:00-6:00',
        phase: 'Test Preparation',
        outputs: [
          'Interview script',
          'Test device setup',
          'Recording preparation'
        ]
      }
    ]
  },
  
  qualityBar: {
    principle: 'Good enough to test, not perfect',
    focus: 'Core flow functionality',
    ignore: ['Edge cases', 'Error states', 'Perfection']
  }
};
```

## Day 5: Friday - Test

### User Testing & Learning
```javascript
const friday = {
  morning: {
    duration: '9:00 AM - 12:30 PM',
    
    setup: {
      rooms: {
        testing: 'User + Interviewer',
        observation: 'Team watching stream'
      },
      
      schedule: {
        slots: 5,
        duration: '60 min each',
        break: '30 min between'
      }
    },
    
    protocol: {
      interviewer: 'ux-researcher',
      
      script: {
        warmup: '5 min friendly chat',
        context: '5 min background',
        tasks: '40 min prototype testing',
        debrief: '10 min feedback'
      },
      
      observation: async (session) => {
        const observers = ['design-orchestrator', 'brand-strategist'];
        
        return {
          notes: captureObservations(session),
          patterns: identifyPatterns(session),
          quotes: extractKeyQuotes(session)
        };
      }
    }
  },
  
  afternoon: {
    duration: '1:30 PM - 5:00 PM',
    
    activities: [
      {
        time: '1:30-3:00',
        activity: 'Pattern Identification',
        lead: 'ux-researcher',
        process: async () => {
          const allSessions = await compileTestResults();
          
          return {
            successes: identifyWhatWorked(allSessions),
            failures: identifyWhatFailed(allSessions),
            surprises: identifyUnexpected(allSessions),
            patterns: extractCommonThemes(allSessions)
          };
        }
      },
      {
        time: '3:00-4:00',
        activity: 'Learning Synthesis',
        outputs: [
          'Key learnings document',
          'Go/No-go decision',
          'Next steps plan'
        ]
      },
      {
        time: '4:00-5:00',
        activity: 'Next Sprint Planning',
        decisions: [
          'Iterate on same problem?',
          'Move to next phase?',
          'Need more research?'
        ]
      }
    ]
  },
  
  postSprint: {
    immediate: {
      share: 'Send results to stakeholders',
      archive: 'Save all artifacts',
      schedule: 'Plan follow-up'
    },
    
    nextWeek: async () => {
      if (decision === 'iterate') {
        return planIterationSprint();
      } else if (decision === 'proceed') {
        return transitionToFullProject();
      } else {
        return planAdditionalResearch();
      }
    }
  }
};
```

## AI Acceleration Features

### Overnight Processing
```javascript
const overnightAI = {
  monday: {
    input: 'HMW notes and journey map',
    processing: [
      'Pattern analysis',
      'Opportunity identification',
      'Analogous solution finding'
    ],
    output: 'Inspiration package for Tuesday'
  },
  
  tuesday: {
    input: 'Sketches and concepts',
    processing: [
      'Visual analysis',
      'Concept expansion',
      'Variation generation'
    ],
    output: 'Enhanced concepts for Wednesday'
  },
  
  wednesday: {
    input: 'Winning concept and storyboard',
    processing: [
      'Asset generation',
      'Copy writing',
      'Interaction planning'
    ],
    output: 'Prototype assets for Thursday'
  },
  
  thursday: {
    input: 'Completed prototype',
    processing: [
      'Accessibility check',
      'Flow optimization',
      'Test script refinement'
    ],
    output: 'Polished prototype for Friday'
  }
};
```

### Real-time Enhancement
```javascript
const realtimeAI = {
  sketching: {
    agent: 'ui-generator',
    mode: 'Follow along with human sketches',
    output: 'Enhanced digital versions'
  },
  
  voting: {
    agent: 'design-analyst',
    mode: 'Analyze voting patterns',
    output: 'Insights on preferences'
  },
  
  prototyping: {
    agents: ['ui-generator', 'style-guide-expert'],
    mode: 'Parallel creation',
    output: 'Rapid screen generation'
  },
  
  testing: {
    agent: 'ux-researcher',
    mode: 'Real-time analysis',
    output: 'Live pattern identification'
  }
};
```

## Sprint Artifacts

### Daily Outputs
```javascript
const sprintArtifacts = {
  monday: {
    longTermGoal: 'text',
    sprintQuestions: 'list',
    journeyMap: 'visual',
    targetMoment: 'highlighted area',
    hmwNotes: 'categorized sticky notes'
  },
  
  tuesday: {
    lightningDemos: 'screenshots with notes',
    sketches: 'individual concept drawings',
    aiConcepts: 'digital variations'
  },
  
  wednesday: {
    votingResults: 'heat map photo',
    winningConcept: 'selected sketch',
    storyboard: '6-12 panel flow',
    designSystem: 'quick style guide'
  },
  
  thursday: {
    prototype: 'Interactive Figma/similar',
    testScript: 'Interview guide',
    testTasks: 'Specific actions'
  },
  
  friday: {
    testRecordings: 'Video sessions',
    observationNotes: 'Structured findings',
    patternAnalysis: 'Themed insights',
    decisionDocument: 'Go/no-go with rationale'
  }
};
```

## Success Metrics

```javascript
const sprintSuccess = {
  process: {
    participation: 'Full team engagement',
    timeboxing: 'Activities completed on time',
    decisionMaking: 'Clear decisions made'
  },
  
  outcome: {
    prototypeQuality: 'Testable core flow',
    testInsights: 'Clear patterns identified',
    teamAlignment: 'Shared understanding',
    nextSteps: 'Defined action plan'
  },
  
  efficiency: {
    conceptsGenerated: '> 20 unique ideas',
    prototypeTime: '< 8 hours',
    userFeedback: '5 completed sessions'
  }
};
```

## Sprint Variations

### Remote Sprint
```javascript
const remoteSprint = {
  tools: {
    collaboration: 'Miro/FigJam',
    video: 'Zoom/Meet',
    prototype: 'Figma',
    testing: 'Remote testing tools'
  },
  
  adjustments: {
    timing: 'Account for time zones',
    breaks: 'More frequent, shorter',
    activities: 'Adapted for digital'
  }
};
```

### Mini Sprint (3 days)
```javascript
const miniSprint = {
  day1: 'Understand + Sketch',
  day2: 'Decide + Prototype',
  day3: 'Test + Learn',
  
  compressions: [
    'Shorter activities',
    'Fewer test users (3)',
    'Lower fidelity prototype'
  ]
};
```

---

*Design Sprint v1.0 | 5-day intensive process | AI-accelerated methodology*