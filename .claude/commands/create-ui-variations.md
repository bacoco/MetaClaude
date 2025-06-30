# Create UI Variations Command

Generate multiple UI screen variations using parallel design approaches for comprehensive exploration and A/B testing.

## Command Usage
```bash
clause --project UIDesignOrchestrator/project:create-ui-variations "screens to design"
```

## Variation Strategy

### 1. Five Variation Archetypes
```javascript
const variationArchetypes = {
  conservative: {
    philosophy: "Proven patterns, familiar layouts",
    characteristics: [
      "Traditional navigation",
      "Standard color usage",
      "Conventional spacing",
      "Expected interactions"
    ],
    target: "Risk-averse users, enterprise"
  },
  
  modern: {
    philosophy: "Current trends, clean aesthetics",
    characteristics: [
      "Minimalist approach",
      "Card-based layouts",
      "Generous whitespace",
      "Subtle animations"
    ],
    target: "Tech-savvy professionals"
  },
  
  experimental: {
    philosophy: "Push boundaries, unique solutions",
    characteristics: [
      "Asymmetric layouts",
      "Bold color combinations",
      "Innovative navigation",
      "Playful interactions"
    ],
    target: "Early adopters, creatives"
  },
  
  minimal: {
    philosophy: "Extreme reduction, essential only",
    characteristics: [
      "Maximum whitespace",
      "Monochromatic palette",
      "Typography focus",
      "Hidden complexity"
    ],
    target: "Design purists, focus seekers"
  },
  
  bold: {
    philosophy: "High impact, memorable design",
    characteristics: [
      "Strong color contrasts",
      "Large typography",
      "Dynamic layouts",
      "Dramatic effects"
    ],
    target: "Young audience, brands"
  }
};
```

### 2. Screen-Specific Variations

#### Dashboard Variations
```html
<!-- Variation 1: Conservative -->
<div class="dashboard-conservative">
  <!-- Traditional top nav -->
  <nav class="bg-gray-800 text-white px-4 py-3">
    <div class="flex justify-between items-center">
      <h1 class="text-xl font-semibold">Dashboard</h1>
      <div class="flex space-x-6">
        <a href="#" class="hover:text-gray-300">Reports</a>
        <a href="#" class="hover:text-gray-300">Analytics</a>
        <a href="#" class="hover:text-gray-300">Settings</a>
      </div>
    </div>
  </nav>
  
  <!-- Standard grid layout -->
  <div class="p-6">
    <div class="grid grid-cols-4 gap-4 mb-6">
      <!-- KPI cards in traditional layout -->
    </div>
    <div class="grid grid-cols-3 gap-6">
      <!-- Charts and tables -->
    </div>
  </div>
</div>

<!-- Variation 2: Modern -->
<div class="dashboard-modern">
  <!-- Sidebar navigation -->
  <div class="flex h-screen bg-gray-50">
    <aside class="w-64 bg-white shadow-sm">
      <!-- Minimal icon + text nav -->
    </aside>
    <main class="flex-1 p-8">
      <!-- Card-based widgets with shadows -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div class="lg:col-span-2 space-y-6">
          <!-- Primary content cards -->
        </div>
        <div class="space-y-6">
          <!-- Secondary widgets -->
        </div>
      </div>
    </main>
  </div>
</div>

<!-- Variation 3: Experimental -->
<div class="dashboard-experimental">
  <!-- Floating nav bubbles -->
  <nav class="fixed top-4 left-4 z-50">
    <div class="flex space-x-2">
      <button class="w-12 h-12 rounded-full bg-purple-500 text-white shadow-lg">
        <!-- Animated icon -->
      </button>
      <!-- More floating actions -->
    </div>
  </nav>
  
  <!-- Asymmetric masonry layout -->
  <div class="p-8 bg-gradient-to-br from-purple-50 to-pink-50">
    <div class="masonry columns-1 md:columns-2 lg:columns-3 gap-6">
      <!-- Varied height cards with glassmorphism -->
    </div>
  </div>
</div>

<!-- Variation 4: Minimal -->
<div class="dashboard-minimal">
  <!-- Almost invisible nav -->
  <nav class="px-8 py-6 flex justify-between items-center">
    <h1 class="text-sm text-gray-400">Dashboard</h1>
    <button class="text-gray-400 hover:text-gray-600">
      <svg class="w-5 h-5"><!-- Menu icon --></svg>
    </button>
  </nav>
  
  <!-- Single focus metric -->
  <main class="px-8 py-16 max-w-4xl mx-auto">
    <div class="text-center mb-16">
      <h2 class="text-6xl font-light text-gray-900">$127,350</h2>
      <p class="text-gray-500 mt-2">Total Revenue This Month</p>
    </div>
    <!-- Minimal data visualization -->
  </main>
</div>

<!-- Variation 5: Bold -->
<div class="dashboard-bold">
  <!-- Full-width gradient header -->
  <header class="bg-gradient-to-r from-orange-500 to-pink-500 p-8">
    <h1 class="text-4xl font-black text-white">DASHBOARD</h1>
  </header>
  
  <!-- High contrast sections -->
  <div class="bg-black text-white p-8">
    <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
      <!-- Neon-bordered cards -->
      <div class="border-4 border-orange-500 p-6 hover:border-pink-500 transition-colors">
        <!-- Bold metrics -->
      </div>
    </div>
  </div>
</div>
```

#### Form Variations
```jsx
// Variation approaches for forms
const formVariations = {
  conservative: (
    <form class="max-w-md mx-auto p-6 bg-white rounded shadow">
      <h2 class="text-xl font-semibold mb-4">Sign Up</h2>
      <div class="mb-4">
        <label class="block text-gray-700 mb-2">Email</label>
        <input type="email" class="w-full px-3 py-2 border rounded" />
      </div>
      <button class="w-full bg-blue-500 text-white py-2 rounded">
        Submit
      </button>
    </form>
  ),
  
  modern: (
    <form class="max-w-md mx-auto">
      <div class="bg-white rounded-2xl shadow-xl p-8">
        <h2 class="text-2xl font-bold mb-6">Create Account</h2>
        <div class="space-y-6">
          <div class="relative">
            <input type="email" placeholder=" " class="peer w-full px-4 py-3 border-2 rounded-lg" />
            <label class="absolute left-4 top-3 transition-all peer-placeholder-shown:top-3 peer-focus:-top-6">
              Email
            </label>
          </div>
        </div>
      </div>
    </form>
  ),
  
  experimental: (
    <form class="min-h-screen bg-gradient-to-br from-purple-400 to-pink-400 flex items-center">
      <div class="mx-auto p-8 glassmorphism">
        <input type="email" class="bg-transparent border-b-2 border-white text-white placeholder-white/70" />
        <button class="mt-8 px-8 py-3 bg-white/20 backdrop-blur rounded-full">
          Continue →
        </button>
      </div>
    </form>
  ),
  
  minimal: (
    <form class="h-screen flex items-center justify-center">
      <div class="text-center">
        <input type="email" class="text-3xl font-light border-0 border-b text-center" placeholder="your@email.com" />
        <button class="block mx-auto mt-8 text-sm text-gray-500 hover:text-gray-900">
          Continue
        </button>
      </div>
    </form>
  ),
  
  bold: (
    <form class="bg-black text-white p-12">
      <h1 class="text-6xl font-black mb-8 text-transparent bg-clip-text bg-gradient-to-r from-yellow-400 to-red-400">
        JOIN US
      </h1>
      <input type="email" class="w-full bg-transparent border-4 border-yellow-400 p-4 text-2xl" />
      <button class="mt-6 bg-gradient-to-r from-yellow-400 to-red-400 text-black font-black px-12 py-4 text-xl">
        SIGN UP NOW
      </button>
    </form>
  )
};
```

### 3. Mobile Variations
```javascript
const mobileVariations = {
  conservative: {
    navigation: "Bottom tab bar",
    layout: "List view with dividers",
    interactions: "Standard iOS/Android patterns"
  },
  
  modern: {
    navigation: "Gesture-based with bottom sheet",
    layout: "Card stack with snap scrolling",
    interactions: "Smooth transitions, haptic feedback"
  },
  
  experimental: {
    navigation: "Floating action bubbles",
    layout: "Horizontal scrolling sections",
    interactions: "3D transforms, parallax effects"
  },
  
  minimal: {
    navigation: "Hidden until swipe",
    layout: "Single column, large tap targets",
    interactions: "Subtle, almost invisible"
  },
  
  bold: {
    navigation: "Full-screen overlays",
    layout: "Edge-to-edge imagery",
    interactions: "Dramatic page transitions"
  }
};
```

### 4. Component Variation Matrix
```javascript
const componentMatrix = {
  button: {
    conservative: "px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600",
    modern: "px-6 py-3 bg-gradient-to-r from-blue-500 to-blue-600 text-white rounded-lg shadow-lg",
    experimental: "px-8 py-4 bg-black text-white skew-x-12 hover:skew-x-0 transition-transform",
    minimal: "text-gray-600 hover:text-gray-900 underline-offset-4 hover:underline",
    bold: "px-8 py-4 bg-red-600 text-white text-xl font-black uppercase tracking-wider"
  },
  
  card: {
    conservative: "bg-white border rounded p-4 shadow-sm",
    modern: "bg-white rounded-xl p-6 shadow-xl hover:shadow-2xl transition-shadow",
    experimental: "bg-gradient-to-br from-purple-400/10 to-pink-400/10 backdrop-blur rounded-3xl p-8",
    minimal: "py-8 border-b",
    bold: "bg-black text-white p-8 border-4 border-yellow-400"
  }
};
```

## Parallel Generation Process

### Automated Variation Creation
```javascript
async function generateVariations(screenType, requirements) {
  const variations = await Promise.all([
    generateConservative(screenType, requirements),
    generateModern(screenType, requirements),
    generateExperimental(screenType, requirements),
    generateMinimal(screenType, requirements),
    generateBold(screenType, requirements)
  ]);
  
  return {
    screenType,
    timestamp: Date.now(),
    variations: variations.map((v, i) => ({
      id: `var-${i + 1}`,
      archetype: Object.keys(variationArchetypes)[i],
      code: v.code,
      preview: v.preview,
      metrics: analyzeVariation(v)
    }))
  };
}
```

### Variation Analysis
```javascript
function analyzeVariation(variation) {
  return {
    accessibility: {
      score: checkWCAGCompliance(variation),
      issues: findA11yIssues(variation)
    },
    performance: {
      estimatedSize: calculateSize(variation),
      complexity: measureComplexity(variation)
    },
    usability: {
      clickTargets: analyzeClickTargets(variation),
      readability: checkReadability(variation)
    }
  };
}
```

## Output Format

### Variation Gallery
```html
<!-- Interactive variation comparison -->
<div class="variation-gallery">
  <div class="controls mb-8">
    <button onclick="showAll()">Show All</button>
    <button onclick="showSideBySide()">Side by Side</button>
    <button onclick="showOverlay()">Overlay Compare</button>
  </div>
  
  <div class="variations grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
    <!-- Variation 1: Conservative -->
    <div class="variation-card">
      <h3 class="text-lg font-semibold mb-2">Conservative</h3>
      <div class="preview mb-4">
        <!-- Live preview iframe -->
      </div>
      <div class="metrics text-sm text-gray-600">
        <p>Accessibility: 98/100</p>
        <p>Target Audience: Enterprise</p>
      </div>
      <div class="actions mt-4">
        <button class="text-blue-600">View Code</button>
        <button class="text-blue-600">Test Drive</button>
      </div>
    </div>
    
    <!-- More variations... -->
  </div>
</div>
```

### Variation Comparison
```javascript
const comparisonData = {
  metrics: {
    conservative: { a11y: 98, performance: 95, innovation: 60 },
    modern: { a11y: 92, performance: 88, innovation: 75 },
    experimental: { a11y: 85, performance: 80, innovation: 95 },
    minimal: { a11y: 96, performance: 98, innovation: 70 },
    bold: { a11y: 88, performance: 82, innovation: 90 }
  },
  
  recommendations: {
    forEnterprise: "conservative",
    forStartup: "modern",
    forCreativeAgency: "experimental",
    forMobile: "minimal",
    forYouthBrand: "bold"
  }
};
```

## Best Practices

### When to Use Each Variation
```yaml
conservative:
  use_when:
    - Enterprise applications
    - Financial services
    - Government projects
    - Accessibility is paramount
    
modern:
  use_when:
    - SaaS products
    - Professional tools
    - B2B applications
    - Tech-savvy audience
    
experimental:
  use_when:
    - Creative industries
    - Portfolio sites
    - Innovation showcases
    - Differentiation needed
    
minimal:
  use_when:
    - Content-focused sites
    - Reading applications
    - Meditation/focus apps
    - Sophisticated audience
    
bold:
  use_when:
    - Youth brands
    - Entertainment
    - Marketing campaigns
    - Attention-grabbing needed
```

---

*Create UI Variations v1.0 | Parallel design generation | Comprehensive exploration*