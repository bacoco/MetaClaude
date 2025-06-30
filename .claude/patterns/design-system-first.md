# Design System First Pattern

Systematic approach to UI design starting with comprehensive token and component system creation.

## Pattern Overview

Design System First ensures consistency, scalability, and efficiency by establishing a complete design language before creating specific screens.

```
TOKENS → COMPONENTS → PATTERNS → TEMPLATES → PAGES
```

## Foundation: Token Architecture

### 1. Primitive Tokens
```javascript
const primitiveTokens = {
  // Raw values - the source of truth
  colors: {
    blue: {
      50: '#eff6ff',
      100: '#dbeafe',
      200: '#bfdbfe',
      300: '#93c5fd',
      400: '#60a5fa',
      500: '#3b82f6',
      600: '#2563eb',
      700: '#1d4ed8',
      800: '#1e40af',
      900: '#1e3a8a',
      950: '#172554'
    },
    gray: generateNeutralScale('#6B7280'),
    red: generateColorScale('#EF4444'),
    green: generateColorScale('#10B981'),
    yellow: generateColorScale('#F59E0B')
  },
  
  spacing: {
    base: 4,
    scale: [0, 0.25, 0.5, 0.75, 1, 1.5, 2, 3, 4, 5, 6, 8, 10, 12, 16, 20, 24, 32, 40, 48, 56, 64]
  },
  
  typography: {
    fonts: {
      sans: ['Inter', '-apple-system', 'system-ui', 'sans-serif'],
      serif: ['Merriweather', 'Georgia', 'serif'],
      mono: ['JetBrains Mono', 'Consolas', 'monospace']
    },
    sizes: {
      scale: 1.25, // Major third
      base: 16
    },
    weights: [300, 400, 500, 600, 700, 800],
    lineHeights: [1, 1.25, 1.375, 1.5, 1.625, 2]
  },
  
  borders: {
    widths: [0, 1, 2, 4],
    radii: [0, 2, 4, 6, 8, 12, 16, 24, 9999]
  },
  
  shadows: {
    depths: generateShadowScale()
  },
  
  animation: {
    durations: [0, 75, 100, 150, 200, 300, 500, 700, 1000],
    easings: {
      linear: 'linear',
      in: 'cubic-bezier(0.4, 0, 1, 1)',
      out: 'cubic-bezier(0, 0, 0.2, 1)',
      inOut: 'cubic-bezier(0.4, 0, 0.2, 1)'
    }
  }
};
```

### 2. Semantic Tokens
```javascript
const semanticTokens = {
  // Meaningful aliases that reference primitives
  colors: {
    background: {
      primary: '{colors.gray.50}',
      secondary: '{colors.gray.100}',
      tertiary: '{colors.gray.200}',
      inverse: '{colors.gray.900}'
    },
    
    foreground: {
      primary: '{colors.gray.900}',
      secondary: '{colors.gray.700}',
      tertiary: '{colors.gray.500}',
      inverse: '{colors.gray.50}'
    },
    
    brand: {
      primary: '{colors.blue.600}',
      secondary: '{colors.blue.700}',
      tertiary: '{colors.blue.500}'
    },
    
    feedback: {
      error: '{colors.red.600}',
      warning: '{colors.yellow.600}',
      success: '{colors.green.600}',
      info: '{colors.blue.600}'
    },
    
    interactive: {
      default: '{colors.brand.primary}',
      hover: '{colors.brand.secondary}',
      active: '{colors.brand.tertiary}',
      disabled: '{colors.gray.400}'
    }
  },
  
  typography: {
    heading: {
      '2xl': {
        fontFamily: '{typography.fonts.sans}',
        fontSize: '{typography.sizes.scale}^7 * {typography.sizes.base}',
        fontWeight: '{typography.weights.700}',
        lineHeight: '{typography.lineHeights.1.25}',
        letterSpacing: '-0.02em'
      },
      xl: generateTypographyScale('xl'),
      lg: generateTypographyScale('lg'),
      md: generateTypographyScale('md'),
      sm: generateTypographyScale('sm')
    },
    
    body: {
      lg: {
        fontFamily: '{typography.fonts.sans}',
        fontSize: '{typography.sizes.scale}^1 * {typography.sizes.base}',
        fontWeight: '{typography.weights.400}',
        lineHeight: '{typography.lineHeights.1.625}'
      },
      md: generateTypographyScale('body-md'),
      sm: generateTypographyScale('body-sm')
    }
  },
  
  spacing: {
    layout: {
      xs: '{spacing.base} * {spacing.scale[2]}',
      sm: '{spacing.base} * {spacing.scale[4]}',
      md: '{spacing.base} * {spacing.scale[6]}',
      lg: '{spacing.base} * {spacing.scale[8]}',
      xl: '{spacing.base} * {spacing.scale[12]}',
      '2xl': '{spacing.base} * {spacing.scale[16]}'
    },
    
    component: {
      padding: {
        button: '{spacing.layout.sm} {spacing.layout.md}',
        card: '{spacing.layout.md}',
        input: '{spacing.layout.sm} {spacing.layout.md}'
      },
      gap: {
        tight: '{spacing.layout.xs}',
        default: '{spacing.layout.sm}',
        loose: '{spacing.layout.md}'
      }
    }
  }
};
```

### 3. Component Tokens
```javascript
const componentTokens = {
  button: {
    sizes: {
      sm: {
        height: '32px',
        paddingX: '{spacing.layout.sm}',
        fontSize: '{typography.body.sm.fontSize}',
        iconSize: '16px'
      },
      md: {
        height: '40px',
        paddingX: '{spacing.layout.md}',
        fontSize: '{typography.body.md.fontSize}',
        iconSize: '20px'
      },
      lg: {
        height: '48px',
        paddingX: '{spacing.layout.lg}',
        fontSize: '{typography.body.lg.fontSize}',
        iconSize: '24px'
      }
    },
    
    variants: {
      primary: {
        background: '{colors.interactive.default}',
        color: '#FFFFFF',
        border: 'transparent',
        hover: {
          background: '{colors.interactive.hover}'
        },
        active: {
          background: '{colors.interactive.active}'
        }
      },
      secondary: generateButtonVariant('secondary'),
      tertiary: generateButtonVariant('tertiary'),
      danger: generateButtonVariant('danger')
    }
  },
  
  input: {
    sizes: generateComponentSizes('input'),
    states: {
      default: {
        borderColor: '{colors.gray.300}',
        background: '{colors.background.primary}',
        color: '{colors.foreground.primary}'
      },
      hover: {
        borderColor: '{colors.gray.400}'
      },
      focus: {
        borderColor: '{colors.brand.primary}',
        shadow: '0 0 0 3px {colors.brand.primary}20'
      },
      error: {
        borderColor: '{colors.feedback.error}',
        shadow: '0 0 0 3px {colors.feedback.error}20'
      }
    }
  }
};
```

## Component Architecture

### Base Component System
```typescript
// Base component interface
interface BaseComponent<T = {}> {
  variant?: 'primary' | 'secondary' | 'tertiary';
  size?: 'sm' | 'md' | 'lg';
  className?: string;
  children?: React.ReactNode;
}

// Component factory
function createComponent<P extends BaseComponent>(
  name: string,
  styles: ComponentStyles,
  Component: React.FC<P>
) {
  const StyledComponent = React.forwardRef<HTMLElement, P>((props, ref) => {
    const { variant = 'primary', size = 'md', className, ...rest } = props;
    
    const classes = cn(
      styles.base,
      styles.variants[variant],
      styles.sizes[size],
      className
    );
    
    return <Component ref={ref} className={classes} {...rest} />;
  });
  
  StyledComponent.displayName = name;
  return StyledComponent;
}
```

### Component Hierarchy
```
Foundation Components (Atoms)
├── Button
├── Input
├── Label
├── Icon
├── Spinner
├── Badge
└── Avatar

Composite Components (Molecules)
├── FormField (Label + Input + Error)
├── ButtonGroup
├── InputGroup
├── Card
├── Alert
└── Modal

Pattern Components (Organisms)
├── Form
├── DataTable
├── Navigation
├── Hero
├── FeatureGrid
└── Testimonial

Template Components
├── PageLayout
├── DashboardLayout
├── AuthLayout
└── MarketingLayout
```

### Component Creation Pattern
```jsx
// 1. Define component tokens
const cardTokens = {
  padding: componentTokens.card.padding,
  borderRadius: primitiveTokens.borders.radii[4],
  shadow: {
    default: primitiveTokens.shadows.depths[1],
    hover: primitiveTokens.shadows.depths[2]
  },
  background: semanticTokens.colors.background.primary,
  border: semanticTokens.colors.gray[200]
};

// 2. Create component styles
const cardStyles = {
  base: `
    p-${cardTokens.padding}
    rounded-${cardTokens.borderRadius}
    bg-${cardTokens.background}
    border border-${cardTokens.border}
    shadow-${cardTokens.shadow.default}
    hover:shadow-${cardTokens.shadow.hover}
    transition-shadow duration-200
  `,
  variants: {
    elevated: 'shadow-lg border-0',
    outlined: 'shadow-none border-2',
    ghost: 'shadow-none border-0 bg-transparent'
  }
};

// 3. Implement component
const Card = createComponent('Card', cardStyles, ({ children, ...props }) => (
  <div {...props}>{children}</div>
));

// 4. Document usage
/**
 * Card Component
 * 
 * @example
 * <Card variant="elevated">
 *   <Card.Header>
 *     <Card.Title>Title</Card.Title>
 *   </Card.Header>
 *   <Card.Body>Content</Card.Body>
 * </Card>
 */
```

## System Patterns

### Responsive System
```javascript
const responsiveSystem = {
  breakpoints: {
    sm: 640,
    md: 768,
    lg: 1024,
    xl: 1280,
    '2xl': 1536
  },
  
  // Responsive token values
  spacing: {
    section: {
      base: spacing.layout.md,
      sm: spacing.layout.lg,
      md: spacing.layout.xl,
      lg: spacing.layout['2xl']
    }
  },
  
  // Responsive component props
  components: {
    container: {
      maxWidth: {
        sm: '640px',
        md: '768px',
        lg: '1024px',
        xl: '1280px'
      },
      padding: {
        base: spacing.layout.md,
        md: spacing.layout.lg,
        lg: spacing.layout.xl
      }
    }
  }
};
```

### Theme System
```javascript
const themeSystem = {
  modes: {
    light: {
      colors: semanticTokens.colors
    },
    dark: {
      colors: {
        background: {
          primary: primitiveTokens.colors.gray[900],
          secondary: primitiveTokens.colors.gray[800],
          tertiary: primitiveTokens.colors.gray[700]
        },
        foreground: {
          primary: primitiveTokens.colors.gray[50],
          secondary: primitiveTokens.colors.gray[200],
          tertiary: primitiveTokens.colors.gray[400]
        }
      }
    }
  },
  
  // Theme-aware component
  useTheme: () => {
    const [mode, setMode] = useState('light');
    const theme = themeSystem.modes[mode];
    
    return {
      theme,
      mode,
      toggleMode: () => setMode(m => m === 'light' ? 'dark' : 'light')
    };
  }
};
```

## Implementation Workflow

### Step 1: Token Generation
```javascript
// Generate complete token system from brand
async function generateTokenSystem(brand) {
  const analysis = await analyzeBrand(brand);
  
  return {
    primitives: generatePrimitives(analysis),
    semantic: generateSemantics(analysis),
    components: generateComponentTokens(analysis)
  };
}
```

### Step 2: Component Library
```javascript
// Build component library from tokens
async function buildComponentLibrary(tokens) {
  const components = [];
  
  // Generate each component type
  for (const componentType of componentTypes) {
    const component = await generateComponent(componentType, tokens);
    components.push(component);
  }
  
  // Generate documentation
  const docs = await generateDocumentation(components, tokens);
  
  return {
    components,
    tokens,
    docs
  };
}
```

### Step 3: Pattern Creation
```javascript
// Create reusable patterns from components
function createPatterns(components) {
  return {
    forms: {
      login: createLoginPattern(components),
      registration: createRegistrationPattern(components),
      checkout: createCheckoutPattern(components)
    },
    
    navigation: {
      header: createHeaderPattern(components),
      sidebar: createSidebarPattern(components),
      breadcrumb: createBreadcrumbPattern(components)
    },
    
    content: {
      hero: createHeroPattern(components),
      features: createFeaturesPattern(components),
      testimonials: createTestimonialsPattern(components)
    }
  };
}
```

### Step 4: Page Assembly
```javascript
// Assemble pages from patterns
function assemblePage(template, patterns, content) {
  return template({
    header: patterns.navigation.header(content.nav),
    hero: patterns.content.hero(content.hero),
    features: patterns.content.features(content.features),
    footer: patterns.navigation.footer(content.footer)
  });
}
```

## Quality Assurance

### System Validation
```javascript
const validateDesignSystem = {
  tokens: {
    checkCompleteness: (tokens) => {
      const required = ['colors', 'typography', 'spacing', 'borders'];
      return required.every(key => tokens[key]);
    },
    
    checkConsistency: (tokens) => {
      // Verify token relationships
      return validateTokenRelationships(tokens);
    },
    
    checkScalability: (tokens) => {
      // Ensure systematic progression
      return validateScales(tokens);
    }
  },
  
  components: {
    checkCoverage: (components) => {
      const required = ['Button', 'Input', 'Card', 'Modal'];
      return required.every(name => 
        components.some(c => c.name === name)
      );
    },
    
    checkAPI: (components) => {
      // Verify consistent component APIs
      return components.every(c => 
        c.props.includes('variant') && 
        c.props.includes('size')
      );
    }
  }
};
```

## Benefits & Outcomes

### Consistency Benefits
- Every UI element follows the same rules
- Predictable behavior across the application
- Reduced cognitive load for users
- Easier onboarding for new developers

### Efficiency Benefits
- Rapid UI development from existing components
- Reduced decision fatigue
- Parallel development possible
- Easy maintenance and updates

### Scalability Benefits
- New features use existing patterns
- Easy to add new themes or brands
- Simple to extend component library
- Clear governance model

---

*Design System First v1.0 | Systematic design approach | Token-based architecture*