# Fuse Style Concept Command

Combine extracted design DNA with app concept to create cohesive, branded MVP designs using vibe design methodology.

## Command Usage
```bash
clause --project UIDesignOrchestrator/project:fuse-style-concept
```

## Prerequisites
- Completed `extract-design-dna` analysis
- Completed `generate-mvp-concept` definition

## Fusion Process

### 1. Vibe Mapping
```
<pontificating>
Merging visual DNA with functional requirements...

BRAND-FEATURE ALIGNMENT:
- Ocean blue (#0047AB) → Trust for financial features
- Coral accent (#FF6B6B) → CTAs and success states  
- Rounded corners (8px) → Approachable interface
- Geometric typography → Professional clarity

EMOTIONAL JOURNEY MAPPING:
Landing (Curiosity) → Cool blues, open space
Onboarding (Trust) → Warm accents, clear progress
Dashboard (Confidence) → Balanced palette, strong hierarchy
Success (Delight) → Celebration colors, micro-animations

INTERACTION PERSONALITY:
- Hover: Subtle lift with shadow (0 4px 12px)
- Click: Satisfying depress animation
- Loading: Smooth skeleton screens
- Transitions: 200ms ease-out consistency
</pontificating>
```

### 2. Component DNA Fusion
```javascript
const fusedComponents = {
  buttons: {
    primary: {
      base: extractedDNA.colors.primary.base,
      hover: extractedDNA.colors.primary.dark,
      padding: `${extractedDNA.spacing.unit * 2}px ${extractedDNA.spacing.unit * 4}px`,
      borderRadius: extractedDNA.effects.radius.default,
      fontWeight: 600,
      transition: extractedDNA.effects.transitions.default
    },
    secondary: {
      base: "transparent",
      border: `2px solid ${extractedDNA.colors.primary.base}`,
      color: extractedDNA.colors.primary.base,
      hover: {
        background: `${extractedDNA.colors.primary.base}10`,
        borderColor: extractedDNA.colors.primary.dark
      }
    }
  },
  
  cards: {
    background: extractedDNA.colors.neutrals["50"],
    border: `1px solid ${extractedDNA.colors.neutrals["200"]}`,
    shadow: extractedDNA.effects.shadows.default,
    padding: extractedDNA.spacing.component_padding,
    hover: {
      shadow: extractedDNA.effects.shadows.lg,
      transform: "translateY(-2px)"
    }
  },
  
  forms: {
    input: {
      height: "48px",
      padding: `0 ${extractedDNA.spacing.unit * 2}px`,
      border: `2px solid ${extractedDNA.colors.neutrals["300"]}`,
      focus: {
        borderColor: extractedDNA.colors.primary.base,
        shadow: `0 0 0 3px ${extractedDNA.colors.primary.base}20`
      }
    }
  }
};
```

### 3. Screen-Specific Styling
```javascript
const screenStyles = {
  landing: {
    hero: {
      gradient: `linear-gradient(135deg, ${dna.colors.primary.base}10 0%, ${dna.colors.secondary}10 100%)`,
      pattern: "subtle-geometric-overlay",
      spacing: "generous-breathing-room"
    },
    features: {
      cards: "lifted-with-icon-accent",
      layout: "asymmetric-grid",
      animation: "stagger-fade-in"
    }
  },
  
  dashboard: {
    layout: {
      sidebar: {
        background: dna.colors.neutrals["900"],
        accent: dna.colors.primary.light,
        width: "260px"
      },
      main: {
        background: dna.colors.neutrals["50"],
        padding: dna.spacing.section_spacing
      }
    },
    widgets: {
      stats: "big-number-emphasis",
      charts: "branded-color-scheme",
      tables: "zebra-stripe-subtle"
    }
  },
  
  onboarding: {
    progress: {
      track: dna.colors.neutrals["200"],
      fill: dna.colors.primary.base,
      animation: "smooth-fill"
    },
    illustrations: {
      style: "line-art-with-brand-accent",
      placement: "right-side-desktop-top-mobile"
    }
  }
};
```

### 4. Responsive Vibe Adaptation
```css
/* Mobile-first vibe adjustments */
.component {
  /* Mobile: Compact and focused */
  padding: calc(var(--spacing-unit) * 2);
  font-size: var(--text-base);
  
  /* Tablet: Breathing room */
  @media (min-width: 768px) {
    padding: calc(var(--spacing-unit) * 3);
    font-size: var(--text-lg);
  }
  
  /* Desktop: Full expression */
  @media (min-width: 1024px) {
    padding: var(--spacing-component);
    display: grid;
    gap: var(--spacing-unit-4);
  }
}

/* Dark mode vibe shift */
@media (prefers-color-scheme: dark) {
  :root {
    --vibe-shift: darker-mysterious;
    --color-primary: var(--color-primary-light);
    --shadow-strength: 0.3;
  }
}
```

### 5. Motion Language
```javascript
const motionDNA = {
  microInteractions: {
    buttons: {
      hover: "scale(1.02) translateY(-1px)",
      active: "scale(0.98)",
      disabled: "opacity(0.5) cursor-not-allowed"
    },
    cards: {
      hover: "translateY(-4px) shadow-increase",
      click: "scale(0.98) shadow-decrease"
    },
    inputs: {
      focus: "border-color-transition shadow-appear",
      error: "shake-animation red-flash"
    }
  },
  
  pageTransitions: {
    fadeIn: {
      initial: { opacity: 0, y: 20 },
      animate: { opacity: 1, y: 0 },
      duration: 0.3
    },
    slideIn: {
      initial: { x: -20, opacity: 0 },
      animate: { x: 0, opacity: 1 },
      duration: 0.4
    }
  },
  
  loadingStates: {
    skeleton: "shimmer-animation",
    spinner: "branded-color-rotation",
    progress: "smooth-fill-animation"
  }
};
```

## Output Examples

### Fused Dashboard
```html
<!-- Dashboard with DNA-infused styling -->
<div class="dashboard-container bg-neutral-50 dark:bg-neutral-900 min-h-screen">
  <!-- Branded Sidebar -->
  <aside class="w-64 bg-white dark:bg-neutral-800 border-r border-neutral-200 dark:border-neutral-700">
    <div class="p-6">
      <div class="flex items-center space-x-3">
        <div class="w-10 h-10 bg-primary-100 rounded-lg flex items-center justify-center">
          <svg class="w-6 h-6 text-primary-600">...</svg>
        </div>
        <span class="text-xl font-semibold text-neutral-900 dark:text-white">
          AppName
        </span>
      </div>
    </div>
    
    <!-- Navigation with DNA styling -->
    <nav class="px-4 pb-6">
      <ul class="space-y-1">
        <li>
          <a href="#" class="flex items-center px-4 py-2.5 text-sm font-medium rounded-lg
                           text-primary-600 bg-primary-50 dark:bg-primary-900/20">
            <svg class="mr-3 w-5 h-5">...</svg>
            Dashboard
          </a>
        </li>
        <!-- More nav items with consistent DNA -->
      </ul>
    </nav>
  </aside>
  
  <!-- Main Content Area -->
  <main class="flex-1 p-8">
    <!-- Stats Cards with Brand Colors -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
      <div class="bg-white dark:bg-neutral-800 p-6 rounded-xl shadow-sm 
                  hover:shadow-md transition-shadow duration-200">
        <div class="flex items-center justify-between mb-4">
          <div class="w-12 h-12 bg-primary-100 dark:bg-primary-900/20 
                      rounded-lg flex items-center justify-center">
            <svg class="w-6 h-6 text-primary-600">...</svg>
          </div>
          <span class="text-sm font-medium text-green-600 flex items-center">
            <svg class="w-4 h-4 mr-1">...</svg>
            +12%
          </span>
        </div>
        <h3 class="text-2xl font-bold text-neutral-900 dark:text-white">
          $48,295
        </h3>
        <p class="text-sm text-neutral-600 dark:text-neutral-400 mt-1">
          Total Revenue
        </p>
      </div>
      <!-- More stat cards -->
    </div>
    
    <!-- Content sections with DNA-based spacing and styling -->
  </main>
</div>
```

### Fused Onboarding Flow
```jsx
// Onboarding with personality-infused design
const OnboardingStep = ({ step, total }) => (
  <div className="min-h-screen bg-gradient-to-br from-primary-50 to-secondary-50 
                  dark:from-neutral-900 dark:to-neutral-800 flex items-center justify-center p-6">
    <div className="max-w-2xl w-full">
      {/* Progress Indicator with Brand Colors */}
      <div className="mb-8">
        <div className="flex items-center justify-between mb-2">
          <span className="text-sm font-medium text-neutral-600 dark:text-neutral-400">
            Step {step} of {total}
          </span>
          <span className="text-sm font-medium text-primary-600">
            {Math.round((step / total) * 100)}% Complete
          </span>
        </div>
        <div className="h-2 bg-neutral-200 dark:bg-neutral-700 rounded-full overflow-hidden">
          <div 
            className="h-full bg-gradient-to-r from-primary-500 to-primary-600 
                       transition-all duration-500 ease-out"
            style={{ width: `${(step / total) * 100}%` }}
          />
        </div>
      </div>
      
      {/* Content Card with DNA Styling */}
      <div className="bg-white dark:bg-neutral-800 rounded-2xl shadow-xl p-8 md:p-12">
        <div className="text-center mb-8">
          <div className="w-20 h-20 bg-primary-100 dark:bg-primary-900/20 
                          rounded-2xl flex items-center justify-center mx-auto mb-6">
            <svg className="w-10 h-10 text-primary-600">...</svg>
          </div>
          <h2 className="text-3xl font-bold text-neutral-900 dark:text-white mb-3">
            Welcome to AppName
          </h2>
          <p className="text-lg text-neutral-600 dark:text-neutral-400">
            Let's get you set up in just a few steps
          </p>
        </div>
        
        {/* Form with DNA Input Styling */}
        <form className="space-y-6">
          <div>
            <label className="block text-sm font-medium text-neutral-700 
                            dark:text-neutral-300 mb-2">
              What should we call you?
            </label>
            <input
              type="text"
              className="w-full px-4 py-3 rounded-lg border-2 border-neutral-300 
                         dark:border-neutral-600 dark:bg-neutral-700
                         focus:border-primary-500 focus:ring-4 focus:ring-primary-500/20
                         transition-all duration-200"
              placeholder="Enter your name"
            />
          </div>
          
          {/* Action Buttons with Brand Styling */}
          <div className="flex gap-4 pt-4">
            <button
              type="button"
              className="flex-1 px-6 py-3 rounded-lg font-medium
                         text-neutral-700 dark:text-neutral-300 
                         bg-neutral-100 dark:bg-neutral-700
                         hover:bg-neutral-200 dark:hover:bg-neutral-600
                         transition-colors duration-200"
            >
              Back
            </button>
            <button
              type="submit"
              className="flex-1 px-6 py-3 rounded-lg font-medium
                         text-white bg-primary-600 
                         hover:bg-primary-700 active:bg-primary-800
                         transition-colors duration-200
                         shadow-lg shadow-primary-600/25"
            >
              Continue
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
);
```

## Tool Integration

| Step | Action | Tool to Use | Purpose |
|------|--------|-------------|----------|
| 1. Load DNA | Get extracted tokens | `read_file("design-tokens.json")` | Access visual DNA |
| 2. Load concept | Get MVP definition | `read_file("mvp-concept.json")` | Access app structure |
| 3. Fuse internally | Combine DNA + concept | None | Mental synthesis |
| 4. Generate preview | Create examples | None (in response) | Show fusion results |
| 5. Save fusion | Store combined system | `write_file("fused-design.json")` (if requested) | Persist fusion |
| 6. Create mockups | Generate UI samples | `write_file` multiple | Save example screens |

### Tool Usage Examples
```javascript
// Step 1-2: Load both inputs
const designDNA = JSON.parse(read_file("design-system/tokens.json"));
const mvpConcept = JSON.parse(read_file("project/mvp-concept.json"));

// Step 3-4: Internal fusion and presentation
const fusedDesign = fuseStyleWithConcept(designDNA, mvpConcept);
presentFusionResults(fusedDesign);

// Step 5: Save fusion output
if (userWantsSave) {
  write_file("design-system/fused-design.json", JSON.stringify(fusedDesign, null, 2));
}

// Step 6: Generate example implementations
if (userWantsExamples) {
  fusedDesign.screens.forEach((screen) => {
    write_file(`mockups/${screen.name}.jsx`, generateScreenCode(screen));
  });
}
```

## Fusion Quality Checklist

### Visual Consistency
- [ ] All colors from extracted DNA palette
- [ ] Typography follows DNA hierarchy
- [ ] Spacing uses DNA grid system
- [ ] Border radius consistent with DNA

### Functional Alignment
- [ ] MVP features properly styled
- [ ] User flows visually guided
- [ ] Interactive states defined
- [ ] Responsive behavior planned

### Emotional Resonance
- [ ] Brand personality expressed
- [ ] Target audience appeal
- [ ] Consistent mood throughout
- [ ] Micro-interactions support vibe

### Technical Implementation
- [ ] Tokens properly applied
- [ ] Dark mode considered
- [ ] Performance optimized
- [ ] Accessibility maintained

---

*Fuse Style Concept v1.0 | DNA application command | Vibe design fusion*