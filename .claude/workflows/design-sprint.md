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

### Day 1 Reflection
```
*Evening reflection on Understanding:*

Problem Clarity (Score each 1-5):
- Challenge Understanding: Is the problem crystal clear to everyone? [Score: __/5]
- Root Cause Identification: Did we uncover real problems or just symptoms? [Score: __/5]
- User Focus: Are we solving for the right users? [Score: __/5]
Clarity Score: [Average]/5

Sprint Questions (Score each 1-5):
- Question Specificity: Are questions specific and answerable? [Score: __/5]
- Decision Guidance: Will answers genuinely guide our decisions? [Score: __/5]
- Assumption Validation: Have we identified key assumptions? [Score: __/5]
Questions Score: [Average]/5

Team Alignment (Score each 1-5):
- Shared Understanding: Does everyone see the same problem? [Score: __/5]
- Energy Level: Is the team energized and engaged? [Score: __/5]
- Focus Agreement: Are we aligned on the target? [Score: __/5]
Alignment Score: [Average]/5

Overall Day 1 Score: [Total Average]/5
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

### Day 2 Reflection
```
*Evening reflection on Divergence:*

Creative Output (Score each 1-5):
- Solution Diversity: Did we push beyond obvious solutions? [Score: __/5]
- Innovation Level: What surprised us in the sketches? [Score: __/5]
- Boldness Factor: Are we being ambitious enough? [Score: __/5]
Creativity Score: [Average]/5

Idea Quality (Score each 1-5):
- Problem Addressing: Do solutions tackle the core problem? [Score: __/5]
- Excitement Level: Which ideas generate most enthusiasm? [Score: __/5]
- Pattern Recognition: What themes emerged across sketches? [Score: __/5]
Quality Score: [Average]/5

Exploration Breadth (Score each 1-5):
- Perspective Variety: Did we explore different angles? [Score: __/5]
- Feasibility Range: Mix of safe and ambitious ideas? [Score: __/5]
- User-Centeredness: Are solutions user-focused? [Score: __/5]
Exploration Score: [Average]/5

Overall Day 2 Score: [Total Average]/5
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

### Day 3 Reflection
```
*Evening reflection on Decision:*

Decision Quality (Score each 1-5):
- User-Driven Choice: Did we choose based on user needs? [Score: __/5]
- Storyboard Clarity: Is our storyboard testable and clear? [Score: __/5]
- Risk Identification: Have we identified key uncertainties? [Score: __/5]
Decision Score: [Average]/5

Team Alignment (Score each 1-5):
- Direction Buy-In: Is everyone committed to the direction? [Score: __/5]
- Concerns Addressed: Have we resolved major concerns? [Score: __/5]
- Prototype Confidence: Are we ready for tomorrow? [Score: __/5]
Alignment Score: [Average]/5

Process Effectiveness (Score each 1-5):
- Voting Fairness: Was the selection process democratic? [Score: __/5]
- Time Management: Did we stay on schedule? [Score: __/5]
- Decision Rationale: Is our reasoning documented? [Score: __/5]
Process Score: [Average]/5

Overall Day 3 Score: [Total Average]/5
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

### Day 4 Reflection
```
*Evening reflection on Prototyping:*

Prototype Readiness (Score each 1-5):
- Realism Level: Does it feel real enough to test? [Score: __/5]
- Flow Completeness: Are all critical paths represented? [Score: __/5]
- Quality Trade-offs: Were the right corners cut? [Score: __/5]
Readiness Score: [Average]/5

Test Preparation (Score each 1-5):
- Test Focus: Are we testing the right things? [Score: __/5]
- Script Neutrality: Is our interview script unbiased? [Score: __/5]
- Learning Goals: Are objectives clearly defined? [Score: __/5]
Preparation Score: [Average]/5

Execution Quality (Score each 1-5):
- Speed vs Quality: Did we balance well? [Score: __/5]
- Team Coordination: How well did we collaborate? [Score: __/5]
- Asset Quality: Are visuals and copy adequate? [Score: __/5]
Execution Score: [Average]/5

Overall Day 4 Score: [Total Average]/5
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

### Sprint Reflection
```
*End-of-sprint comprehensive reflection:*

Sprint Success (Score each 1-5):
- Questions Answered: Did we answer our sprint questions? [Score: __/5]
- Path Clarity: Is the way forward now clear? [Score: __/5]
- ROI Achievement: Was the time investment worthwhile? [Score: __/5]
Success Score: [Average]/5

Process Evaluation (Score each 1-5):
- Day Productivity: Which days were most effective? [Score: __/5]
- Time Efficiency: Did we minimize waste? [Score: __/5]
- Team Collaboration: How well did we work together? [Score: __/5]
Process Score: [Average]/5

Key Insights (Score each 1-5):
- Surprise Factor: What unexpected learnings emerged? [Score: __/5]
- Assumption Testing: Which beliefs were challenged? [Score: __/5]
- Opportunity Discovery: What new paths opened? [Score: __/5]
Insights Score: [Average]/5

Next Steps Clarity (Score each 1-5):
- Direction Confidence: Clear on iterate/pivot/proceed? [Score: __/5]
- Action Specificity: Are next steps concrete? [Score: __/5]
- Ownership Clarity: Is accountability defined? [Score: __/5]
Clarity Score: [Average]/5

Overall Sprint Score: [Total Average]/5

Key Takeaways:
- Most Valuable Day: ____________
- Biggest Learning: ____________
- Next Sprint Focus: ____________
```

## Feedback Interpretation

### Sprint Feedback Analysis
```javascript
const interpretSprintFeedback = {
  patterns: {
    identify: (testResults) => {
      // Look for recurring themes across testers
      const themes = extractThemes(testResults);
      return {
        consistent: themes.filter(t => t.frequency > 0.6),
        split: themes.filter(t => t.frequency > 0.3 && t.frequency <= 0.6),
        outlier: themes.filter(t => t.frequency <= 0.3)
      };
    },
    
    prioritize: (patterns) => ({
      mustFix: patterns.consistent.filter(p => p.impact === 'blocker'),
      shouldFix: patterns.consistent.filter(p => p.impact === 'major'),
      consider: patterns.split,
      monitor: patterns.outlier
    })
  },
  
  decisions: {
    iterate: {
      when: 'Major usability issues or concept rejection',
      action: 'Plan iteration sprint with new approach'
    },
    refine: {
      when: 'Good concept but needs polish',
      action: 'Move to detailed design with fixes'
    },
    pivot: {
      when: 'Fundamental problem with direction',
      action: 'Return to problem definition'
    },
    proceed: {
      when: 'Strong validation with minor issues',
      action: 'Move to full implementation'
    }
  },
  
  communication: {
    toTeam: 'Detailed findings with video clips',
    toStakeholders: 'Executive summary with recommendations',
    toDesigners: 'Specific design improvements needed',
    toDevelopers: 'Technical feasibility concerns raised'
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