# Iterate Designs Command

Create focused design iterations based on specific feedback, user testing results, or performance metrics.

## Command Usage
```bash
clause --project UIDesignOrchestrator/project:iterate-designs "feedback or focus area"
```

## Iteration Framework

### 1. Feedback Analysis
```javascript
const feedbackProcessor = {
  categorize(feedback) {
    return {
      visual: extractVisualFeedback(feedback),
      functional: extractFunctionalFeedback(feedback),
      emotional: extractEmotionalFeedback(feedback),
      technical: extractTechnicalFeedback(feedback)
    };
  },
  
  prioritize(categories) {
    return categories.sort((a, b) => {
      // Priority: Critical > High > Medium > Low
      const priorityMap = { critical: 4, high: 3, medium: 2, low: 1 };
      return priorityMap[b.priority] - priorityMap[a.priority];
    });
  },
  
  actionable(feedback) {
    return {
      specific: "Button too small" → "Increase button size to 44px minimum",
      vague: "Doesn't feel right" → "Analyze emotional design elements",
      metric: "20% drop-off" → "Simplify flow, reduce cognitive load"
    };
  }
};
```

### 2. Iteration Types

#### Visual Refinement
```css
/* Before: User feedback "Too harsh, hard to read" */
.card-before {
  background: #FFFFFF;
  border: 1px solid #000000;
  color: #000000;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.3);
}

/* After: Softened with better contrast */
.card-after {
  background: #FAFAFA;
  border: 1px solid #E5E5E5;
  color: #1A1A1A;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  /* Added: Subtle warmth */
  background: linear-gradient(180deg, #FAFAFA 0%, #F5F5F5 100%);
}

/* Micro-adjustments for perceived improvement */
.refined {
  /* Slightly increased line height for readability */
  line-height: 1.5 → 1.6;
  
  /* Softened corners based on "too sharp" feedback */
  border-radius: 4px → 8px;
  
  /* Better touch targets from mobile testing */
  padding: 8px → 12px;
  
  /* Improved focus states from accessibility feedback */
  &:focus {
    outline: 2px solid #000 → 3px solid #0066FF;
    outline-offset: 2px → 3px;
  }
}
```

#### Functional Improvements
```javascript
// Before: Complex multi-step process
const checkoutFlowV1 = {
  steps: ['Cart', 'Info', 'Shipping', 'Payment', 'Review', 'Confirm'],
  averageCompletion: '67%',
  dropOffPoints: ['Shipping', 'Payment']
};

// After: Simplified based on user testing
const checkoutFlowV2 = {
  steps: ['Cart', 'Checkout', 'Confirm'],
  improvements: {
    combined: ['Info + Shipping', 'Payment + Review'],
    autofill: 'Smart address detection',
    express: 'One-click for returning users'
  },
  expectedCompletion: '85%+'
};

// Progressive disclosure iteration
const formIterationV2 = {
  initial: 'Show only essential fields',
  progressive: 'Reveal optional fields on demand',
  smart: 'Pre-fill based on user history',
  validation: 'Inline, friendly error messages'
};
```

#### Emotional Design Tuning
```javascript
const emotionalIterations = {
  trust: {
    before: "Generic success message",
    after: "Great! Your data is safely saved and encrypted 🔒",
    changes: ["Added security indicator", "Warmer tone", "Specific assurance"]
  },
  
  delight: {
    before: "static confirmation",
    after: "animated celebration with confetti",
    changes: ["Micro-animation", "Positive reinforcement", "Memorable moment"]
  },
  
  calm: {
    before: "Red error messages everywhere",
    after: "Gentle yellow warnings with helpful tips",
    changes: ["Softer colors", "Helpful tone", "Solution-focused"]
  }
};
```

### 3. A/B Test Iterations
```javascript
const abTestIterations = {
  variant_a: {
    hypothesis: "Larger CTA buttons increase conversion",
    changes: {
      buttonSize: "h-10 → h-12",
      buttonText: "Get Started → Start Free Trial",
      buttonColor: "bg-blue-500 → bg-green-500"
    }
  },
  
  variant_b: {
    hypothesis: "Social proof near CTA improves trust",
    changes: {
      addedElements: ["5-star rating", "10,000+ users", "testimonial quote"],
      layout: "CTA moved below social proof",
      emphasis: "Subtle animation on stats"
    }
  },
  
  measurement: {
    metrics: ["Click-through rate", "Conversion rate", "Time to decision"],
    duration: "2 weeks",
    sampleSize: "1000 users per variant"
  }
};
```

### 4. Performance Iterations
```javascript
// Before: Heavy component with poor performance
const HeavyDashboardV1 = () => (
  <div className="dashboard">
    {/* All widgets load immediately */}
    <StatsWidget data={fullDataSet} />
    <ChartsWidget data={fullDataSet} />
    <TableWidget data={fullDataSet} />
    <ActivityFeed data={fullDataSet} />
  </div>
);

// After: Optimized based on performance feedback
const OptimizedDashboardV2 = () => {
  const [visibleWidgets, setVisibleWidgets] = useState(['stats']);
  
  return (
    <div className="dashboard">
      {/* Critical content loads first */}
      <StatsWidget data={summaryData} />
      
      {/* Progressive loading */}
      <LazyLoad height={400} once>
        <ChartsWidget data={chartData} />
      </LazyLoad>
      
      {/* Virtualized for performance */}
      <VirtualizedTable
        data={tableData}
        rowHeight={50}
        overscan={5}
      />
      
      {/* Paginated to reduce load */}
      <ActivityFeed
        data={activityData}
        pageSize={20}
        loadMore={loadMoreActivities}
      />
    </div>
  );
};
```

### 5. Accessibility Iterations
```html
<!-- Before: Accessibility issues identified -->
<div class="card" onclick="handleClick()">
  <img src="product.jpg">
  <div class="price">$99</div>
  <div class="red-text">On Sale!</div>
</div>

<!-- After: Fully accessible iteration -->
<article class="card" role="article" aria-label="Product card">
  <button 
    class="card-interactive-area"
    aria-label="View product details for Premium Widget"
    onclick="handleClick()"
  >
    <img src="product.jpg" alt="Premium Widget - Stainless steel construction">
    <div class="price" aria-label="Price">$99</div>
    <div class="sale-indicator" aria-label="On sale">
      <svg aria-hidden="true" class="icon-sale">...</svg>
      <span>On Sale!</span>
    </div>
  </button>
</article>
```

## Iteration Workflow

### 1. Gather Feedback
```javascript
const feedbackSources = {
  userTesting: {
    method: "Moderated sessions",
    participants: 8,
    findings: ["Navigation confusion", "CTA not prominent", "Trust concerns"]
  },
  
  analytics: {
    heatmaps: "Low engagement on key features",
    funnels: "30% drop at payment step",
    timeOnTask: "2x longer than expected"
  },
  
  stakeholder: {
    business: "Need higher conversion",
    design: "Brand not coming through",
    engineering: "Performance concerns"
  },
  
  support: {
    tickets: "Common user confusion points",
    features: "Most requested improvements"
  }
};
```

### 2. Prioritize Changes
```javascript
const priorityMatrix = {
  highImpactLowEffort: [
    "Increase button size",
    "Improve error messages",
    "Add loading states"
  ],
  
  highImpactHighEffort: [
    "Redesign checkout flow",
    "Implement design system",
    "Add personalization"
  ],
  
  lowImpactLowEffort: [
    "Update microcopy",
    "Adjust spacing",
    "Refine animations"
  ],
  
  lowImpactHighEffort: [
    "Consider for future",
    "Evaluate necessity"
  ]
};
```

### 3. Create Iterations
```javascript
const iterationSprints = {
  sprint1: {
    focus: "Quick wins from user feedback",
    changes: [
      "Increase all CTAs to 48px height",
      "Add hover states to all interactive elements",
      "Improve form error messages"
    ],
    duration: "1 week"
  },
  
  sprint2: {
    focus: "Flow optimization",
    changes: [
      "Simplify checkout from 6 to 3 steps",
      "Add progress indicators",
      "Implement auto-save"
    ],
    duration: "2 weeks"
  },
  
  sprint3: {
    focus: "Polish and delight",
    changes: [
      "Add micro-animations",
      "Refine color palette",
      "Implement dark mode"
    ],
    duration: "1 week"
  }
};
```

### 4. Validation Method
```javascript
const validateIterations = {
  before: captureBaselineMetrics(),
  
  during: {
    qualitative: "User interviews during testing",
    quantitative: "A/B test metrics tracking",
    heuristic: "Expert review against principles"
  },
  
  after: {
    compare: "Baseline vs. iteration metrics",
    statistical: "Significance testing",
    business: "Impact on KPIs"
  },
  
  decision: {
    ship: "Significant improvement shown",
    iterate: "Promising but needs refinement",
    revert: "No improvement or regression"
  }
};
```

## Output Format

### Iteration Documentation
```markdown
# Design Iteration Report

## Iteration Summary
- **Version**: 2.3
- **Date**: 2024-01-20
- **Focus**: Checkout flow optimization
- **Based on**: User testing session #5

## Changes Made

### High Priority
1. **Simplified Checkout** 
   - Reduced from 6 to 3 steps
   - Combined shipping + payment
   - Added express checkout option
   
2. **Improved Error Handling**
   - Inline validation with helpful messages
   - Clear recovery paths
   - Prevented common mistakes

### Medium Priority
1. **Visual Refinements**
   - Increased contrast for readability
   - Larger touch targets (44px → 48px)
   - Consistent spacing system

## Results
- **Conversion**: +18% (67% → 85%)
- **Time to Complete**: -40% (5.2min → 3.1min)
- **Error Rate**: -60% (15% → 6%)
- **User Satisfaction**: +22 NPS points

## Next Steps
- Monitor metrics for 2 weeks
- Gather additional feedback
- Plan mobile-specific optimizations
```

## Tool Integration

| Step | Action | Tool to Use | Purpose |
|------|--------|-------------|----------|
| 1. Load current | Get existing design | `read_file("Component.jsx")` | Baseline version |
| 2. Apply feedback | Process changes | None (internal) | Generate improvements |
| 3. Show changes | Present iteration | None (in response) | Display new version |
| 4. Save iteration | Store new version | `write_file("Component-v2.jsx")` | Version control |
| 5. Update original | Replace if approved | `write_file("Component.jsx")` | Apply changes |
| 6. Document changes | Create changelog | `write_file("CHANGELOG.md", changes)` | Track evolution |

### Tool Usage Examples
```javascript
// Step 1: Load current design
const currentDesign = read_file("src/components/Dashboard.jsx");
const currentStyles = read_file("src/styles/dashboard.css");

// Step 2-3: Apply feedback and present
const iteration = applyFeedback(currentDesign, userFeedback);
presentIterationChanges(iteration);

// Step 4: Save as new version
if (userWantsVersioning) {
  const version = getNextVersion();
  write_file(`src/components/Dashboard-v${version}.jsx`, iteration.code);
  write_file(`src/styles/dashboard-v${version}.css`, iteration.styles);
}

// Step 5: Update original if approved
if (userApprovesChanges) {
  write_file("src/components/Dashboard.jsx", iteration.code);
  write_file("src/styles/dashboard.css", iteration.styles);
}

// Step 6: Document the iteration
const changelog = generateChangeLog(currentDesign, iteration);
appendToFile("CHANGELOG.md", changelog);
```

### Visual Comparison
```html
<!-- Before/After comparison tool -->
<div class="iteration-comparison">
  <div class="slider-container">
    <div class="before">
      <!-- Original design -->
    </div>
    <div class="after">
      <!-- Iterated design -->
    </div>
    <input type="range" class="slider" />
  </div>
  
  <div class="changes-list">
    <h3>Key Changes</h3>
    <ul>
      <li>✅ Increased button size by 20%</li>
      <li>✅ Improved color contrast (4.5:1 → 7:1)</li>
      <li>✅ Added loading states</li>
      <li>✅ Simplified form to 3 fields</li>
    </ul>
  </div>
</div>
```

---

*Iterate Designs v1.0 | Feedback-driven refinement | Continuous improvement*