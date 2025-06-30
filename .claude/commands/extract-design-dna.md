# Extract Design DNA Command

Analyze inspiration images and extract comprehensive design tokens using visual DNA methodology.

## Command Usage
```bash
clause --project UIDesignOrchestrator/project:extract-design-dna "[images or urls]"
```

## Process Flow

### 1. Image Analysis Phase
```
<pondering>
Analyzing visual elements across provided inspiration...

COLOR STORY:
- Primary: Deep ocean blue (#0047AB) - trust, depth, professionalism
- Secondary: Warm coral (#FF6B6B) - energy, approachability
- Neutrals: Cool grays with slight blue undertone
- Accent: Golden yellow (#FFD93D) - optimism, attention

TYPOGRAPHY PERSONALITY:
- Headers: Bold geometric sans (similar to Futura)
- Body: Humanist sans (like Inter) for readability
- Display: Custom rounded for friendliness
- Hierarchy: Clear 1.5x scale progression

SPATIAL RHYTHM:
- Base unit: 8px grid system
- Component padding: 24px (3 units)
- Section spacing: 64px (8 units)
- Consistent negative space usage

SHAPE LANGUAGE:
- Rounded corners: 8px standard, 16px for cards
- Geometric foundations with organic accents
- Circular elements for user avatars
- Subtle shadows for depth (0 2px 8px rgba(0,0,0,0.1))

MOTION SIGNATURE:
- Ease-out curves for natural feel
- 200ms standard transition
- Subtle scale on hover (1.02)
- Smooth color transitions
</pondering>
```

### 2. Pattern Recognition
```javascript
const extractedPatterns = {
  visual_hierarchy: {
    primary: "Size + Color contrast",
    secondary: "Spacing + Weight",
    tertiary: "Subtle borders"
  },
  
  interaction_patterns: {
    hover: "Lift + Brighten",
    active: "Depress + Darken",
    focus: "Ring + Scale"
  },
  
  layout_systems: {
    grid: "12 column with 24px gutters",
    breakpoints: [320, 768, 1024, 1440],
    container: "Max 1280px centered"
  }
};
```

### 3. Token Generation
```json
{
  "design_dna": {
    "identity": {
      "personality": ["Modern", "Approachable", "Trustworthy"],
      "energy_level": 0.7,
      "formality": 0.6
    },
    
    "colors": {
      "primary": {
        "base": "#0047AB",
        "light": "#3366CC",
        "dark": "#002F6C",
        "contrast": "#FFFFFF"
      },
      "semantic": {
        "success": "#00AA55",
        "warning": "#FFAA00",
        "error": "#FF3333",
        "info": "#0099CC"
      },
      "neutrals": {
        "50": "#F8FAFC",
        "100": "#F1F5F9",
        "200": "#E2E8F0",
        "300": "#CBD5E1",
        "400": "#94A3B8",
        "500": "#64748B",
        "600": "#475569",
        "700": "#334155",
        "800": "#1E293B",
        "900": "#0F172A"
      }
    },
    
    "typography": {
      "fonts": {
        "heading": "'Futura PT', 'Century Gothic', sans-serif",
        "body": "'Inter', -apple-system, sans-serif",
        "mono": "'JetBrains Mono', 'Consolas', monospace"
      },
      "scale": {
        "xs": "0.75rem",
        "sm": "0.875rem",
        "base": "1rem",
        "lg": "1.125rem",
        "xl": "1.25rem",
        "2xl": "1.5rem",
        "3xl": "1.875rem",
        "4xl": "2.25rem",
        "5xl": "3rem"
      }
    },
    
    "spacing": {
      "base_unit": "8px",
      "scale": [0, 0.5, 1, 1.5, 2, 3, 4, 5, 6, 8, 10, 12, 16, 20, 24, 32],
      "component_padding": "24px",
      "section_spacing": "64px"
    },
    
    "effects": {
      "shadows": {
        "sm": "0 1px 2px rgba(0, 0, 0, 0.05)",
        "default": "0 2px 8px rgba(0, 0, 0, 0.1)",
        "lg": "0 10px 25px rgba(0, 0, 0, 0.15)"
      },
      "radius": {
        "sm": "4px",
        "default": "8px",
        "lg": "16px",
        "full": "9999px"
      },
      "transitions": {
        "fast": "150ms ease-out",
        "default": "200ms ease-out",
        "slow": "300ms ease-out"
      }
    }
  }
}
```

### 4. Style Guide Preview
```html
<!-- Generated preview of extracted design DNA -->
<div class="dna-preview">
  <section class="colors">
    <h2>Extracted Color Palette</h2>
    <div class="color-grid">
      <!-- Color swatches with hex values -->
    </div>
  </section>
  
  <section class="typography">
    <h2>Typography System</h2>
    <div class="type-specimens">
      <!-- Font samples at different sizes -->
    </div>
  </section>
  
  <section class="components">
    <h2>Component Examples</h2>
    <div class="component-samples">
      <!-- Buttons, cards, inputs using extracted DNA -->
    </div>
  </section>
</div>
```

## Integration Points

### With Style Guide Expert
```javascript
// Handoff extracted DNA for system creation
const handoff = {
  command: "create-design-system",
  data: extractedDNA,
  instructions: "Build comprehensive system from DNA"
};
```

### With UI Generator
```javascript
// Use DNA for consistent component creation
const componentConfig = {
  tokens: extractedDNA,
  variations: ["conservative", "modern", "bold"],
  maintainDNA: true
};
```

## Advanced Options

### Multi-Source Extraction
```bash
# Analyze multiple inspiration sources
clause --project UIDesignOrchestrator/project:extract-design-dna \
  "dribbble-shot-1.png behance-project.url figma-community.link"
```

### Weighted Analysis
```javascript
// Assign importance to different sources
const sources = [
  { image: "primary-inspiration.jpg", weight: 0.5 },
  { image: "secondary-style.png", weight: 0.3 },
  { image: "accent-details.png", weight: 0.2 }
];
```

### DNA Comparison
```javascript
// Compare extracted DNA with existing brand
const comparison = {
  alignment: calculateAlignment(extractedDNA, brandGuidelines),
  conflicts: identifyConflicts(extractedDNA, currentSystem),
  opportunities: findOpportunities(extractedDNA, competitors)
};
```

## Output Formats

### JSON Export
Complete design tokens in standard format

### Figma Tokens
Ready for design tool import

### CSS Variables
```css
:root {
  /* Extracted design DNA as CSS custom properties */
  --color-primary: #0047AB;
  --font-heading: 'Futura PT', sans-serif;
  --spacing-unit: 8px;
  /* ... */
}
```

### Tailwind Config
```javascript
module.exports = {
  theme: {
    extend: {
      colors: extractedDNA.colors,
      fontFamily: extractedDNA.typography.fonts,
      spacing: extractedDNA.spacing.scale
    }
  }
}
```

---

*Extract Design DNA v1.0 | Visual analysis command | Style extraction specialist*