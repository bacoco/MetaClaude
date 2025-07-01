# Design System Example: Cosmos UI

Complete example of creating a comprehensive design system from scratch using UI Designer Orchestrator.

## Project Overview

**System Name**: Cosmos UI  
**Type**: Multi-platform Design System  
**Target**: Startup scaling from 10 to 100+ products  
**Timeline**: 4 weeks  

## Step 1: Design System Strategy

```
"Create a scalable design system called Cosmos UI for a growing startup that needs consistency across web, mobile, and marketing materials"
```

### Initial Requirements
```yaml
scope:
  platforms:
    - Web (React)
    - Mobile (React Native)
    - Marketing (Static sites)
  
  products:
    - Main application
    - Marketing website
    - Mobile app
    - Email templates
    - Documentation
  
  constraints:
    - Must support theming
    - Accessibility WCAG AA minimum
    - Performance budget: <50KB CSS
    - Open source friendly
```

## Step 2: Foundation Research

### Brand Discovery Command
```
"Research design systems from successful startups like Stripe, Linear, Vercel, and Shopify to extract best practices"
```

### Key Insights
```json
{
  "bestPractices": {
    "Stripe": "Exceptional documentation and API design",
    "Linear": "Cohesive visual language across all touchpoints",
    "Vercel": "Developer-friendly implementation",
    "Shopify": "Scalable token architecture"
  },
  "principles": [
    "Clarity over cleverness",
    "Consistency at scale",
    "Performance by default",
    "Accessibility built-in",
    "Developer ergonomics"
  ]
}
```

## Step 3: Token Architecture

### Command
```
"Create systematic token architecture for Cosmos UI with primitive, semantic, and component levels using the design system first pattern"
```

### Generated Token System

```javascript
// cosmos-tokens.js
export const tokens = {
  // Level 1: Primitives (Raw values)
  primitives: {
    // Color Primitives
    colors: {
      neutral: {
        0: '#FFFFFF',
        50: '#FAFAFA',
        100: '#F4F4F5',
        200: '#E4E4E7',
        300: '#D4D4D8',
        400: '#A1A1AA',
        500: '#71717A',
        600: '#52525B',
        700: '#3F3F46',
        800: '#27272A',
        900: '#18181B',
        1000: '#000000'
      },
      blue: {
        50: '#EFF6FF',
        100: '#DBEAFE',
        200: '#BFDBFE',
        300: '#93C5FD',
        400: '#60A5FA',
        500: '#3B82F6',
        600: '#2563EB',
        700: '#1D4ED8',
        800: '#1E40AF',
        900: '#1E3A8A'
      },
      green: {
        50: '#F0FDF4',
        100: '#DCFCE7',
        200: '#BBF7D0',
        300: '#86EFAC',
        400: '#4ADE80',
        500: '#22C55E',
        600: '#16A34A',
        700: '#15803D',
        800: '#166534',
        900: '#14532D'
      },
      // ... more color scales
    },
    
    // Typography Primitives
    typography: {
      families: {
        sans: '"Inter", -apple-system, BlinkMacSystemFont, sans-serif',
        mono: '"Fira Code", "Consolas", monospace'
      },
      sizes: {
        xs: '0.75rem',    // 12px
        sm: '0.875rem',   // 14px
        base: '1rem',     // 16px
        lg: '1.125rem',   // 18px
        xl: '1.25rem',    // 20px
        '2xl': '1.5rem',  // 24px
        '3xl': '1.875rem', // 30px
        '4xl': '2.25rem', // 36px
        '5xl': '3rem',    // 48px
        '6xl': '3.75rem', // 60px
        '7xl': '4.5rem',  // 72px
      },
      weights: {
        normal: 400,
        medium: 500,
        semibold: 600,
        bold: 700
      },
      lineHeights: {
        none: '1',
        tight: '1.25',
        snug: '1.375',
        normal: '1.5',
        relaxed: '1.625',
        loose: '2'
      }
    },
    
    // Spacing Primitives  
    spacing: {
      px: '1px',
      0: '0',
      0.5: '0.125rem',  // 2px
      1: '0.25rem',     // 4px
      1.5: '0.375rem',  // 6px
      2: '0.5rem',      // 8px
      2.5: '0.625rem',  // 10px
      3: '0.75rem',     // 12px
      3.5: '0.875rem',  // 14px
      4: '1rem',        // 16px
      5: '1.25rem',     // 20px
      6: '1.5rem',      // 24px
      7: '1.75rem',     // 28px
      8: '2rem',        // 32px
      9: '2.25rem',     // 36px
      10: '2.5rem',     // 40px
      11: '2.75rem',    // 44px
      12: '3rem',       // 48px
      14: '3.5rem',     // 56px
      16: '4rem',       // 64px
      20: '5rem',       // 80px
      24: '6rem',       // 96px
      28: '7rem',       // 112px
      32: '8rem',       // 128px
      36: '9rem',       // 144px
      40: '10rem',      // 160px
      44: '11rem',      // 176px
      48: '12rem',      // 192px
      52: '13rem',      // 208px
      56: '14rem',      // 224px
      60: '15rem',      // 240px
      64: '16rem',      // 256px
      72: '18rem',      // 288px
      80: '20rem',      // 320px
      96: '24rem'       // 384px
    },
    
    // Effect Primitives
    effects: {
      shadows: {
        xs: '0 1px 2px 0 rgb(0 0 0 / 0.05)',
        sm: '0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1)',
        md: '0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)',
        lg: '0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)',
        xl: '0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1)',
        '2xl': '0 25px 50px -12px rgb(0 0 0 / 0.25)',
        inner: 'inset 0 2px 4px 0 rgb(0 0 0 / 0.05)'
      },
      radii: {
        none: '0',
        sm: '0.125rem',
        md: '0.375rem',
        lg: '0.5rem',
        xl: '0.75rem',
        '2xl': '1rem',
        '3xl': '1.5rem',
        full: '9999px'
      }
    }
  },
  
  // Level 2: Semantic Tokens (Meaningful names)
  semantic: {
    colors: {
      // Backgrounds
      background: {
        primary: '{colors.neutral.0}',
        secondary: '{colors.neutral.50}',
        tertiary: '{colors.neutral.100}',
        inverse: '{colors.neutral.900}'
      },
      
      // Surfaces  
      surface: {
        primary: '{colors.neutral.0}',
        secondary: '{colors.neutral.50}',
        tertiary: '{colors.neutral.100}',
        inverse: '{colors.neutral.800}'
      },
      
      // Text
      text: {
        primary: '{colors.neutral.900}',
        secondary: '{colors.neutral.600}',
        tertiary: '{colors.neutral.500}',
        inverse: '{colors.neutral.0}',
        disabled: '{colors.neutral.400}'
      },
      
      // Interactive
      interactive: {
        primary: '{colors.blue.600}',
        primaryHover: '{colors.blue.700}',
        primaryActive: '{colors.blue.800}',
        secondary: '{colors.neutral.200}',
        secondaryHover: '{colors.neutral.300}',
        secondaryActive: '{colors.neutral.400}'
      },
      
      // Feedback
      feedback: {
        success: '{colors.green.600}',
        warning: '{colors.amber.600}',
        error: '{colors.red.600}',
        info: '{colors.blue.600}'
      }
    },
    
    typography: {
      // Display
      display: {
        large: {
          fontFamily: '{typography.families.sans}',
          fontSize: '{typography.sizes.6xl}',
          fontWeight: '{typography.weights.bold}',
          lineHeight: '{typography.lineHeights.tight}',
          letterSpacing: '-0.02em'
        },
        medium: {
          fontFamily: '{typography.families.sans}',
          fontSize: '{typography.sizes.5xl}',
          fontWeight: '{typography.weights.bold}',
          lineHeight: '{typography.lineHeights.tight}',
          letterSpacing: '-0.02em'
        },
        small: {
          fontFamily: '{typography.families.sans}',
          fontSize: '{typography.sizes.4xl}',
          fontWeight: '{typography.weights.semibold}',
          lineHeight: '{typography.lineHeights.tight}',
          letterSpacing: '-0.01em'
        }
      },
      
      // Headings
      heading: {
        h1: {
          fontFamily: '{typography.families.sans}',
          fontSize: '{typography.sizes.3xl}',
          fontWeight: '{typography.weights.bold}',
          lineHeight: '{typography.lineHeights.tight}'
        },
        h2: {
          fontFamily: '{typography.families.sans}',
          fontSize: '{typography.sizes.2xl}',
          fontWeight: '{typography.weights.semibold}',
          lineHeight: '{typography.lineHeights.tight}'
        },
        h3: {
          fontFamily: '{typography.families.sans}',
          fontSize: '{typography.sizes.xl}',
          fontWeight: '{typography.weights.semibold}',
          lineHeight: '{typography.lineHeights.snug}'
        },
        h4: {
          fontFamily: '{typography.families.sans}',
          fontSize: '{typography.sizes.lg}',
          fontWeight: '{typography.weights.semibold}',
          lineHeight: '{typography.lineHeights.snug}'
        }
      },
      
      // Body
      body: {
        large: {
          fontFamily: '{typography.families.sans}',
          fontSize: '{typography.sizes.lg}',
          fontWeight: '{typography.weights.normal}',
          lineHeight: '{typography.lineHeights.relaxed}'
        },
        medium: {
          fontFamily: '{typography.families.sans}',
          fontSize: '{typography.sizes.base}',
          fontWeight: '{typography.weights.normal}',
          lineHeight: '{typography.lineHeights.normal}'
        },
        small: {
          fontFamily: '{typography.families.sans}',
          fontSize: '{typography.sizes.sm}',
          fontWeight: '{typography.weights.normal}',
          lineHeight: '{typography.lineHeights.normal}'
        }
      }
    },
    
    spacing: {
      page: {
        margin: '{spacing.8}',
        maxWidth: '80rem'
      },
      section: {
        paddingX: '{spacing.6}',
        paddingY: '{spacing.16}',
        gap: '{spacing.12}'
      },
      component: {
        padding: '{spacing.4}',
        gap: '{spacing.3}'
      }
    }
  },
  
  // Level 3: Component Tokens
  components: {
    button: {
      base: {
        fontFamily: '{typography.families.sans}',
        fontWeight: '{typography.weights.medium}',
        borderRadius: '{effects.radii.lg}',
        transitionDuration: '150ms',
        transitionTimingFunction: 'ease-in-out'
      },
      sizes: {
        sm: {
          fontSize: '{typography.sizes.sm}',
          paddingX: '{spacing.3}',
          paddingY: '{spacing.1.5}',
          height: '{spacing.8}'
        },
        md: {
          fontSize: '{typography.sizes.base}',
          paddingX: '{spacing.4}',
          paddingY: '{spacing.2}',
          height: '{spacing.10}'
        },
        lg: {
          fontSize: '{typography.sizes.lg}',
          paddingX: '{spacing.6}',
          paddingY: '{spacing.3}',
          height: '{spacing.12}'
        }
      },
      variants: {
        primary: {
          background: '{colors.interactive.primary}',
          color: '{colors.neutral.0}',
          borderColor: 'transparent',
          hover: {
            background: '{colors.interactive.primaryHover}'
          },
          active: {
            background: '{colors.interactive.primaryActive}'
          },
          disabled: {
            background: '{colors.neutral.300}',
            color: '{colors.neutral.500}'
          }
        },
        secondary: {
          background: '{colors.interactive.secondary}',
          color: '{colors.text.primary}',
          borderColor: '{colors.neutral.300}',
          hover: {
            background: '{colors.interactive.secondaryHover}'
          }
        },
        ghost: {
          background: 'transparent',
          color: '{colors.text.primary}',
          borderColor: 'transparent',
          hover: {
            background: '{colors.neutral.100}'
          }
        }
      }
    },
    
    input: {
      base: {
        fontFamily: '{typography.families.sans}',
        fontSize: '{typography.sizes.base}',
        borderRadius: '{effects.radii.lg}',
        borderWidth: '1px',
        transitionDuration: '150ms'
      },
      sizes: {
        sm: {
          paddingX: '{spacing.3}',
          paddingY: '{spacing.1.5}',
          height: '{spacing.8}'
        },
        md: {
          paddingX: '{spacing.3}',
          paddingY: '{spacing.2}',
          height: '{spacing.10}'
        },
        lg: {
          paddingX: '{spacing.4}',
          paddingY: '{spacing.3}',
          height: '{spacing.12}'
        }
      },
      states: {
        default: {
          background: '{colors.surface.primary}',
          borderColor: '{colors.neutral.300}',
          color: '{colors.text.primary}'
        },
        hover: {
          borderColor: '{colors.neutral.400}'
        },
        focus: {
          borderColor: '{colors.interactive.primary}',
          outline: '2px solid {colors.interactive.primary}',
          outlineOffset: '2px'
        },
        disabled: {
          background: '{colors.neutral.50}',
          borderColor: '{colors.neutral.200}',
          color: '{colors.text.disabled}'
        },
        error: {
          borderColor: '{colors.feedback.error}'
        }
      }
    },
    
    card: {
      base: {
        borderRadius: '{effects.radii.xl}',
        background: '{colors.surface.primary}',
        borderWidth: '1px',
        borderColor: '{colors.neutral.200}'
      },
      padding: {
        sm: '{spacing.4}',
        md: '{spacing.6}',
        lg: '{spacing.8}'
      },
      shadow: {
        none: 'none',
        sm: '{effects.shadows.sm}',
        md: '{effects.shadows.md}',
        lg: '{effects.shadows.lg}'
      }
    }
  }
};
```

## Step 4: Component Library

### Component Generation Command
```
"Generate a complete component library for Cosmos UI with all essential components"
```

### Generated Components

#### Button Component
```jsx
// Button.tsx
import React from 'react';
import { cva, type VariantProps } from 'class-variance-authority';
import { cn } from '@/utils/cn';

const buttonVariants = cva(
  // Base styles
  'inline-flex items-center justify-center font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50',
  {
    variants: {
      variant: {
        primary:
          'bg-primary text-primary-foreground hover:bg-primary/90 active:bg-primary/80',
        secondary:
          'bg-secondary text-secondary-foreground hover:bg-secondary/80',
        outline:
          'border border-input bg-background hover:bg-accent hover:text-accent-foreground',
        ghost:
          'hover:bg-accent hover:text-accent-foreground',
        link:
          'text-primary underline-offset-4 hover:underline',
        destructive:
          'bg-destructive text-destructive-foreground hover:bg-destructive/90',
      },
      size: {
        sm: 'h-8 px-3 text-xs rounded-md',
        md: 'h-10 px-4 py-2 text-sm rounded-lg',
        lg: 'h-12 px-8 text-base rounded-lg',
        icon: 'h-10 w-10 rounded-lg',
      },
    },
    defaultVariants: {
      variant: 'primary',
      size: 'md',
    },
  }
);

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  loading?: boolean;
  leftIcon?: React.ReactNode;
  rightIcon?: React.ReactNode;
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ 
    className, 
    variant, 
    size, 
    loading, 
    leftIcon, 
    rightIcon, 
    children, 
    disabled,
    ...props 
  }, ref) => {
    return (
      <button
        className={cn(buttonVariants({ variant, size, className }))}
        ref={ref}
        disabled={disabled || loading}
        {...props}
      >
        {loading && (
          <svg
            className="mr-2 h-4 w-4 animate-spin"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
          >
            <circle
              className="opacity-25"
              cx="12"
              cy="12"
              r="10"
              stroke="currentColor"
              strokeWidth="4"
            />
            <path
              className="opacity-75"
              fill="currentColor"
              d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"
            />
          </svg>
        )}
        {!loading && leftIcon && (
          <span className="mr-2">{leftIcon}</span>
        )}
        {children}
        {!loading && rightIcon && (
          <span className="ml-2">{rightIcon}</span>
        )}
      </button>
    );
  }
);

Button.displayName = 'Button';

export { Button, buttonVariants };
```

#### Form Components
```jsx
// Input.tsx
import React from 'react';
import { cn } from '@/utils/cn';

export interface InputProps
  extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  hint?: string;
  leftIcon?: React.ReactNode;
  rightIcon?: React.ReactNode;
}

const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ 
    className, 
    type, 
    label, 
    error, 
    hint, 
    leftIcon, 
    rightIcon, 
    id,
    ...props 
  }, ref) => {
    const inputId = id || `input-${Math.random().toString(36).substr(2, 9)}`;
    
    return (
      <div className="w-full">
        {label && (
          <label
            htmlFor={inputId}
            className="block text-sm font-medium text-gray-700 mb-1"
          >
            {label}
          </label>
        )}
        
        <div className="relative">
          {leftIcon && (
            <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
              {leftIcon}
            </div>
          )}
          
          <input
            type={type}
            id={inputId}
            className={cn(
              'flex h-10 w-full rounded-lg border border-input bg-background px-3 py-2 text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50',
              leftIcon && 'pl-10',
              rightIcon && 'pr-10',
              error && 'border-destructive focus-visible:ring-destructive',
              className
            )}
            ref={ref}
            aria-invalid={!!error}
            aria-describedby={
              error ? `${inputId}-error` : hint ? `${inputId}-hint` : undefined
            }
            {...props}
          />
          
          {rightIcon && (
            <div className="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none">
              {rightIcon}
            </div>
          )}
        </div>
        
        {hint && !error && (
          <p id={`${inputId}-hint`} className="mt-1 text-sm text-muted-foreground">
            {hint}
          </p>
        )}
        
        {error && (
          <p id={`${inputId}-error`} className="mt-1 text-sm text-destructive">
            {error}
          </p>
        )}
      </div>
    );
  }
);

Input.displayName = 'Input';

export { Input };
```

## Step 5: Documentation Site

### Documentation Generation
```
"Create comprehensive documentation site for Cosmos UI design system with interactive examples"
```

### Generated Documentation Structure
```
cosmos-docs/
├── pages/
│   ├── index.mdx          # Introduction
│   ├── getting-started.mdx # Installation & setup
│   ├── principles.mdx      # Design principles
│   ├── tokens/
│   │   ├── colors.mdx
│   │   ├── typography.mdx
│   │   ├── spacing.mdx
│   │   └── effects.mdx
│   ├── components/
│   │   ├── button.mdx
│   │   ├── input.mdx
│   │   ├── card.mdx
│   │   └── ...
│   ├── patterns/
│   │   ├── forms.mdx
│   │   ├── navigation.mdx
│   │   └── data-display.mdx
│   └── resources/
│       ├── figma.mdx
│       ├── changelog.mdx
│       └── migration.mdx
├── components/
│   ├── ColorPalette.tsx
│   ├── TypeScale.tsx
│   ├── SpacingDemo.tsx
│   └── ComponentPlayground.tsx
└── theme.config.tsx
```

### Interactive Documentation Features
```jsx
// ComponentPlayground.tsx
import { Button } from '@cosmos-ui/react';
import { LiveProvider, LiveEditor, LiveError, LivePreview } from 'react-live';

const ComponentPlayground = ({ code, scope }) => {
  return (
    <LiveProvider code={code} scope={scope}>
      <div className="playground">
        <div className="preview-pane">
          <LivePreview />
          <LiveError />
        </div>
        <div className="code-editor">
          <LiveEditor />
        </div>
      </div>
    </LiveProvider>
  );
};

// Usage in documentation
<ComponentPlayground
  code={`
    <div className="flex gap-4">
      <Button variant="primary">Primary</Button>
      <Button variant="secondary">Secondary</Button>
      <Button variant="outline">Outline</Button>
      <Button variant="ghost">Ghost</Button>
    </div>
  `}
  scope={{ Button }}
/>
```

## Step 6: Multi-Platform Support

### Platform Packages
```bash
cosmos-ui/
├── packages/
│   ├── core/              # Core tokens & utilities
│   ├── react/             # React components
│   ├── react-native/      # React Native components
│   ├── vue/               # Vue components
│   ├── css/               # CSS-only version
│   └── figma/             # Figma plugin
├── apps/
│   ├── docs/              # Documentation site
│   ├── playground/        # Component playground
│   └── examples/          # Example apps
└── tools/
    ├── token-builder/     # Token generation
    ├── component-generator/ # Component scaffolding
    └── theme-creator/     # Visual theme builder
```

### React Native Implementation
```jsx
// packages/react-native/src/Button.tsx
import React from 'react';
import {
  TouchableOpacity,
  Text,
  StyleSheet,
  ActivityIndicator,
  View,
} from 'react-native';
import { tokens } from '@cosmos-ui/core';

interface ButtonProps {
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  onPress?: () => void;
  loading?: boolean;
  disabled?: boolean;
  children: React.ReactNode;
}

export const Button: React.FC<ButtonProps> = ({
  variant = 'primary',
  size = 'md',
  onPress,
  loading,
  disabled,
  children,
}) => {
  const styles = getStyles(variant, size);
  
  return (
    <TouchableOpacity
      style={[
        styles.button,
        disabled && styles.disabled,
      ]}
      onPress={onPress}
      disabled={disabled || loading}
      activeOpacity={0.7}
    >
      {loading ? (
        <ActivityIndicator
          color={variant === 'primary' ? '#FFFFFF' : tokens.colors.primary}
        />
      ) : (
        <Text style={styles.text}>{children}</Text>
      )}
    </TouchableOpacity>
  );
};

const getStyles = (variant: string, size: string) =>
  StyleSheet.create({
    button: {
      paddingHorizontal: tokens.spacing[sizeMap[size].px],
      paddingVertical: tokens.spacing[sizeMap[size].py],
      borderRadius: tokens.radii.lg,
      backgroundColor: variantMap[variant].bg,
      borderWidth: variantMap[variant].border ? 1 : 0,
      borderColor: variantMap[variant].borderColor,
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'center',
    },
    text: {
      fontSize: sizeMap[size].fontSize,
      fontWeight: '500',
      color: variantMap[variant].color,
    },
    disabled: {
      opacity: 0.5,
    },
  });
```

## Step 7: Theming System

### Theme Configuration
```javascript
// theme.config.js
export const createTheme = (overrides = {}) => {
  return {
    ...tokens,
    ...overrides,
    
    // Computed values
    computed: {
      // Semantic color generation
      colors: generateSemanticColors(overrides.colors || tokens.colors),
      
      // Responsive spacing
      spacing: generateResponsiveSpacing(overrides.spacing || tokens.spacing),
      
      // Component variants
      components: generateComponentVariants(overrides.components || tokens.components),
    },
  };
};

// Dark theme
export const darkTheme = createTheme({
  semantic: {
    colors: {
      background: {
        primary: tokens.primitives.colors.neutral[900],
        secondary: tokens.primitives.colors.neutral[800],
        tertiary: tokens.primitives.colors.neutral[700],
      },
      text: {
        primary: tokens.primitives.colors.neutral[50],
        secondary: tokens.primitives.colors.neutral[400],
        tertiary: tokens.primitives.colors.neutral[500],
      },
    },
  },
});

// Brand themes
export const brandThemes = {
  ocean: createTheme({
    primitives: {
      colors: {
        blue: generateColorScale('#006994'),
      },
    },
  }),
  
  forest: createTheme({
    primitives: {
      colors: {
        green: generateColorScale('#0F4C3A'),
      },
    },
  }),
};
```

## Step 8: Tooling & Automation

### Component Generator CLI
```bash
# Generate new component
npx cosmos-ui generate component Card

# Output:
# ✓ Created packages/react/src/Card.tsx
# ✓ Created packages/react/src/Card.test.tsx
# ✓ Created packages/react/src/Card.stories.tsx
# ✓ Created packages/react-native/src/Card.tsx
# ✓ Updated packages/react/src/index.ts
# ✓ Created docs/pages/components/card.mdx
```

### Visual Regression Testing
```javascript
// .circleci/config.yml
version: 2.1
jobs:
  visual-tests:
    docker:
      - image: circleci/node:14-browsers
    steps:
      - checkout
      - run: npm install
      - run: npm run build-storybook
      - run: npx percy snapshot storybook-static

workflows:
  visual-testing:
    jobs:
      - visual-tests:
          filters:
            branches:
              only:
                - main
                - /^release-.*/
```

## Step 9: Adoption & Governance

### Usage Analytics
```javascript
// Track component usage
import { trackComponentUsage } from '@cosmos-ui/analytics';

export const Button = React.forwardRef((props, ref) => {
  React.useEffect(() => {
    trackComponentUsage('Button', {
      variant: props.variant,
      size: props.size,
    });
  }, []);
  
  // Component implementation...
});
```

### Contribution Guidelines
```markdown
# Contributing to Cosmos UI

## Design Tokens
- All new tokens must be approved by design system team
- Tokens must follow naming convention
- Include migration guide for breaking changes

## Components
- Must include:
  - TypeScript types
  - Unit tests (>90% coverage)
  - Storybook stories
  - Documentation
  - Accessibility tests
  - Visual regression tests

## Review Process
1. Design review for visual changes
2. Code review for implementation
3. Accessibility review
4. Performance review for bundle size impact
```

## Project Outcomes

### Metrics
- **Component Coverage**: 45 components across 3 platforms
- **Adoption Rate**: 87% of products using Cosmos UI
- **Development Speed**: 3x faster UI development
- **Consistency Score**: 94% design compliance
- **Bundle Size**: 42KB gzipped (core + components)

### Success Stories

> "Cosmos UI transformed how we build products. What used to take weeks 
> now takes days, and everything looks cohesive."
> — *Engineering Lead*

> "The documentation is incredible. New developers can start 
> building immediately without asking questions."
> — *Frontend Developer*

### ROI Analysis
- **Time Saved**: 500+ developer hours/month
- **Design Debt**: Reduced by 78%
- **Support Tickets**: UI-related issues down 65%
- **Onboarding Time**: New developers productive in 1 day vs 1 week

## Running This Example

```bash
# Navigate to example
cd UIDesignerClaude/examples/design-system-example
```

### Initialize and build the design system with Claude Code:

```
# Initialize design system project
"Create a brand identity workflow for Cosmos UI Design System"

# Generate complete system
"Generate the complete design system architecture using the design system first pattern"

# Create documentation
"Generate documentation site for Cosmos UI"
```

## Extending the System

### Adding New Components
```
# Use the component generator
"Add a DatePicker component to Cosmos UI following existing patterns"
```

### Creating Themes
```
# Generate theme variations
"Create ocean and forest theme variations for Cosmos UI"
```

### Platform Extensions
```
# Add new platform support
"Extend Cosmos UI to support Flutter with equivalent components"
```

---

*Design System Example v1.0 | Cosmos UI | Scalable multi-platform design system*