# Export Design System Command

Generate complete design system documentation, tokens, and component libraries in multiple formats.

## Command Usage
```bash
clause --project UIDesignOrchestrator/project:export-design-system "format: [web|mobile|figma|all]"
```

## Export Formats

### 1. Web Platform Exports

#### CSS Variables
```css
/* design-system.css */
:root {
  /* Color Tokens */
  --color-primary-50: #eff6ff;
  --color-primary-100: #dbeafe;
  --color-primary-200: #bfdbfe;
  --color-primary-300: #93c5fd;
  --color-primary-400: #60a5fa;
  --color-primary-500: #3b82f6;
  --color-primary-600: #2563eb;
  --color-primary-700: #1d4ed8;
  --color-primary-800: #1e40af;
  --color-primary-900: #1e3a8a;
  
  /* Semantic Colors */
  --color-background: var(--color-neutral-50);
  --color-surface: var(--color-white);
  --color-text-primary: var(--color-neutral-900);
  --color-text-secondary: var(--color-neutral-600);
  --color-border: var(--color-neutral-200);
  
  /* Typography */
  --font-sans: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
  --font-mono: 'JetBrains Mono', 'Courier New', monospace;
  
  --text-xs: 0.75rem;
  --text-sm: 0.875rem;
  --text-base: 1rem;
  --text-lg: 1.125rem;
  --text-xl: 1.25rem;
  --text-2xl: 1.5rem;
  --text-3xl: 1.875rem;
  --text-4xl: 2.25rem;
  --text-5xl: 3rem;
  
  --leading-none: 1;
  --leading-tight: 1.25;
  --leading-snug: 1.375;
  --leading-normal: 1.5;
  --leading-relaxed: 1.625;
  --leading-loose: 2;
  
  /* Spacing */
  --spacing-px: 1px;
  --spacing-0: 0;
  --spacing-0-5: 0.125rem;
  --spacing-1: 0.25rem;
  --spacing-1-5: 0.375rem;
  --spacing-2: 0.5rem;
  --spacing-2-5: 0.625rem;
  --spacing-3: 0.75rem;
  --spacing-3-5: 0.875rem;
  --spacing-4: 1rem;
  --spacing-5: 1.25rem;
  --spacing-6: 1.5rem;
  --spacing-7: 1.75rem;
  --spacing-8: 2rem;
  --spacing-9: 2.25rem;
  --spacing-10: 2.5rem;
  --spacing-12: 3rem;
  --spacing-14: 3.5rem;
  --spacing-16: 4rem;
  --spacing-20: 5rem;
  --spacing-24: 6rem;
  --spacing-28: 7rem;
  --spacing-32: 8rem;
  
  /* Effects */
  --radius-none: 0;
  --radius-sm: 0.125rem;
  --radius-default: 0.25rem;
  --radius-md: 0.375rem;
  --radius-lg: 0.5rem;
  --radius-xl: 0.75rem;
  --radius-2xl: 1rem;
  --radius-3xl: 1.5rem;
  --radius-full: 9999px;
  
  --shadow-xs: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  --shadow-sm: 0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1);
  --shadow-default: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
  --shadow-md: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);
  --shadow-lg: 0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1);
  --shadow-xl: 0 25px 50px -12px rgb(0 0 0 / 0.25);
  
  /* Animation */
  --duration-fast: 150ms;
  --duration-default: 200ms;
  --duration-slow: 300ms;
  --duration-slower: 500ms;
  
  --ease-default: cubic-bezier(0.4, 0, 0.2, 1);
  --ease-in: cubic-bezier(0.4, 0, 1, 1);
  --ease-out: cubic-bezier(0, 0, 0.2, 1);
  --ease-in-out: cubic-bezier(0.4, 0, 0.2, 1);
}

/* Dark Mode */
@media (prefers-color-scheme: dark) {
  :root {
    --color-background: var(--color-neutral-900);
    --color-surface: var(--color-neutral-800);
    --color-text-primary: var(--color-neutral-50);
    --color-text-secondary: var(--color-neutral-400);
    --color-border: var(--color-neutral-700);
  }
}
```

#### JavaScript/TypeScript Tokens
```typescript
// design-tokens.ts
export const tokens = {
  colors: {
    primary: {
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
    },
    semantic: {
      background: 'var(--color-background)',
      surface: 'var(--color-surface)',
      textPrimary: 'var(--color-text-primary)',
      textSecondary: 'var(--color-text-secondary)',
      border: 'var(--color-border)',
    },
  },
  
  typography: {
    fonts: {
      sans: "'Inter', -apple-system, BlinkMacSystemFont, sans-serif",
      mono: "'JetBrains Mono', 'Courier New', monospace",
    },
    sizes: {
      xs: '0.75rem',
      sm: '0.875rem',
      base: '1rem',
      lg: '1.125rem',
      xl: '1.25rem',
      '2xl': '1.5rem',
      '3xl': '1.875rem',
      '4xl': '2.25rem',
      '5xl': '3rem',
    },
    lineHeights: {
      none: 1,
      tight: 1.25,
      snug: 1.375,
      normal: 1.5,
      relaxed: 1.625,
      loose: 2,
    },
    weights: {
      thin: 100,
      extralight: 200,
      light: 300,
      normal: 400,
      medium: 500,
      semibold: 600,
      bold: 700,
      extrabold: 800,
      black: 900,
    },
  },
  
  spacing: {
    px: '1px',
    0: '0',
    0.5: '0.125rem',
    1: '0.25rem',
    2: '0.5rem',
    3: '0.75rem',
    4: '1rem',
    5: '1.25rem',
    6: '1.5rem',
    8: '2rem',
    10: '2.5rem',
    12: '3rem',
    16: '4rem',
    20: '5rem',
    24: '6rem',
    32: '8rem',
  },
  
  effects: {
    borderRadius: {
      none: '0',
      sm: '0.125rem',
      default: '0.25rem',
      md: '0.375rem',
      lg: '0.5rem',
      xl: '0.75rem',
      '2xl': '1rem',
      '3xl': '1.5rem',
      full: '9999px',
    },
    boxShadow: {
      xs: '0 1px 2px 0 rgb(0 0 0 / 0.05)',
      sm: '0 1px 3px 0 rgb(0 0 0 / 0.1)',
      default: '0 4px 6px -1px rgb(0 0 0 / 0.1)',
      md: '0 10px 15px -3px rgb(0 0 0 / 0.1)',
      lg: '0 20px 25px -5px rgb(0 0 0 / 0.1)',
      xl: '0 25px 50px -12px rgb(0 0 0 / 0.25)',
    },
  },
  
  animation: {
    duration: {
      fast: '150ms',
      default: '200ms',
      slow: '300ms',
      slower: '500ms',
    },
    easing: {
      default: 'cubic-bezier(0.4, 0, 0.2, 1)',
      in: 'cubic-bezier(0.4, 0, 1, 1)',
      out: 'cubic-bezier(0, 0, 0.2, 1)',
      inOut: 'cubic-bezier(0.4, 0, 0.2, 1)',
    },
  },
} as const;

// Type-safe token access
export type ColorToken = keyof typeof tokens.colors.primary;
export type SpacingToken = keyof typeof tokens.spacing;
export type TypographySize = keyof typeof tokens.typography.sizes;
```

#### Tailwind Configuration
```javascript
// tailwind.config.js
const { tokens } = require('./design-tokens');

module.exports = {
  content: ['./src/**/*.{js,jsx,ts,tsx}'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        primary: tokens.colors.primary,
        ...tokens.colors.semantic,
      },
      fontFamily: {
        sans: tokens.typography.fonts.sans,
        mono: tokens.typography.fonts.mono,
      },
      fontSize: tokens.typography.sizes,
      lineHeight: tokens.typography.lineHeights,
      spacing: tokens.spacing,
      borderRadius: tokens.effects.borderRadius,
      boxShadow: tokens.effects.boxShadow,
      transitionDuration: tokens.animation.duration,
      transitionTimingFunction: tokens.animation.easing,
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
  ],
};
```

### 2. Mobile Platform Exports

#### iOS (Swift)
```swift
// DesignSystem.swift
import SwiftUI

public struct DesignSystem {
    // MARK: - Colors
    public struct Colors {
        // Primary Palette
        public static let primary50 = Color(hex: "#eff6ff")
        public static let primary100 = Color(hex: "#dbeafe")
        public static let primary200 = Color(hex: "#bfdbfe")
        public static let primary300 = Color(hex: "#93c5fd")
        public static let primary400 = Color(hex: "#60a5fa")
        public static let primary500 = Color(hex: "#3b82f6")
        public static let primary600 = Color(hex: "#2563eb")
        public static let primary700 = Color(hex: "#1d4ed8")
        public static let primary800 = Color(hex: "#1e40af")
        public static let primary900 = Color(hex: "#1e3a8a")
        
        // Semantic Colors
        public static let background = Color("Background")
        public static let surface = Color("Surface")
        public static let textPrimary = Color("TextPrimary")
        public static let textSecondary = Color("TextSecondary")
        public static let border = Color("Border")
    }
    
    // MARK: - Typography
    public struct Typography {
        public static let largeTitle = Font.system(size: 34, weight: .bold)
        public static let title1 = Font.system(size: 28, weight: .bold)
        public static let title2 = Font.system(size: 22, weight: .semibold)
        public static let title3 = Font.system(size: 20, weight: .semibold)
        public static let headline = Font.system(size: 17, weight: .semibold)
        public static let body = Font.system(size: 17, weight: .regular)
        public static let callout = Font.system(size: 16, weight: .regular)
        public static let subheadline = Font.system(size: 15, weight: .regular)
        public static let footnote = Font.system(size: 13, weight: .regular)
        public static let caption1 = Font.system(size: 12, weight: .regular)
        public static let caption2 = Font.system(size: 11, weight: .regular)
    }
    
    // MARK: - Spacing
    public struct Spacing {
        public static let xxs: CGFloat = 2
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 32
        public static let xxl: CGFloat = 48
        public static let xxxl: CGFloat = 64
    }
    
    // MARK: - Corner Radius
    public struct CornerRadius {
        public static let sm: CGFloat = 4
        public static let md: CGFloat = 8
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 24
        public static let full: CGFloat = .infinity
    }
    
    // MARK: - Shadows
    public struct Shadows {
        public static let sm = Shadow(
            color: Color.black.opacity(0.1),
            radius: 2,
            x: 0,
            y: 1
        )
        
        public static let md = Shadow(
            color: Color.black.opacity(0.1),
            radius: 4,
            x: 0,
            y: 2
        )
        
        public static let lg = Shadow(
            color: Color.black.opacity(0.1),
            radius: 8,
            x: 0,
            y: 4
        )
    }
}

// MARK: - Component Styles
extension View {
    func primaryButton() -> some View {
        self
            .font(DesignSystem.Typography.headline)
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.primary500)
            .cornerRadius(DesignSystem.CornerRadius.md)
    }
    
    func card() -> some View {
        self
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.CornerRadius.lg)
            .shadow(
                color: Color.black.opacity(0.1),
                radius: 4,
                x: 0,
                y: 2
            )
    }
}
```

#### Android (Kotlin/Compose)
```kotlin
// DesignSystem.kt
package com.app.designsystem

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

object DesignSystem {
    // Colors
    object Colors {
        val Primary50 = Color(0xFFEFF6FF)
        val Primary100 = Color(0xFFDBEAFE)
        val Primary200 = Color(0xFFBFDBFE)
        val Primary300 = Color(0xFF93C5FD)
        val Primary400 = Color(0xFF60A5FA)
        val Primary500 = Color(0xFF3B82F6)
        val Primary600 = Color(0xFF2563EB)
        val Primary700 = Color(0xFF1D4ED8)
        val Primary800 = Color(0xFF1E40AF)
        val Primary900 = Color(0xFF1E3A8A)
        
        @Composable
        fun background() = MaterialTheme.colorScheme.background
        
        @Composable
        fun surface() = MaterialTheme.colorScheme.surface
        
        @Composable
        fun onSurface() = MaterialTheme.colorScheme.onSurface
        
        @Composable
        fun onSurfaceVariant() = MaterialTheme.colorScheme.onSurfaceVariant
    }
    
    // Typography
    object Typography {
        val LargeTitle = TextStyle(
            fontSize = 34.sp,
            fontWeight = FontWeight.Bold,
            lineHeight = 40.sp
        )
        
        val Title1 = TextStyle(
            fontSize = 28.sp,
            fontWeight = FontWeight.Bold,
            lineHeight = 34.sp
        )
        
        val Title2 = TextStyle(
            fontSize = 22.sp,
            fontWeight = FontWeight.SemiBold,
            lineHeight = 28.sp
        )
        
        val Headline = TextStyle(
            fontSize = 17.sp,
            fontWeight = FontWeight.SemiBold,
            lineHeight = 22.sp
        )
        
        val Body = TextStyle(
            fontSize = 17.sp,
            fontWeight = FontWeight.Normal,
            lineHeight = 22.sp
        )
        
        val Caption = TextStyle(
            fontSize = 12.sp,
            fontWeight = FontWeight.Normal,
            lineHeight = 16.sp
        )
    }
    
    // Spacing
    object Spacing {
        val xxs = 2.dp
        val xs = 4.dp
        val sm = 8.dp
        val md = 16.dp
        val lg = 24.dp
        val xl = 32.dp
        val xxl = 48.dp
        val xxxl = 64.dp
    }
    
    // Shapes
    object Shapes {
        val small = RoundedCornerShape(4.dp)
        val medium = RoundedCornerShape(8.dp)
        val large = RoundedCornerShape(16.dp)
        val extraLarge = RoundedCornerShape(24.dp)
    }
    
    // Component Defaults
    @Composable
    fun ButtonDefaults() = ButtonDefaults.buttonColors(
        containerColor = Colors.Primary500,
        contentColor = Color.White
    )
    
    @Composable
    fun CardDefaults() = CardDefaults.cardColors(
        containerColor = Colors.surface()
    )
}
```

### 3. Design Tool Exports

#### Figma Tokens (JSON)
```json
{
  "global": {
    "color": {
      "primary": {
        "50": { "value": "#eff6ff", "type": "color" },
        "100": { "value": "#dbeafe", "type": "color" },
        "200": { "value": "#bfdbfe", "type": "color" },
        "300": { "value": "#93c5fd", "type": "color" },
        "400": { "value": "#60a5fa", "type": "color" },
        "500": { "value": "#3b82f6", "type": "color" },
        "600": { "value": "#2563eb", "type": "color" },
        "700": { "value": "#1d4ed8", "type": "color" },
        "800": { "value": "#1e40af", "type": "color" },
        "900": { "value": "#1e3a8a", "type": "color" }
      }
    },
    "typography": {
      "fontFamily": {
        "sans": { "value": "Inter", "type": "fontFamilies" },
        "mono": { "value": "JetBrains Mono", "type": "fontFamilies" }
      },
      "fontSize": {
        "xs": { "value": "12", "type": "fontSizes" },
        "sm": { "value": "14", "type": "fontSizes" },
        "base": { "value": "16", "type": "fontSizes" },
        "lg": { "value": "18", "type": "fontSizes" },
        "xl": { "value": "20", "type": "fontSizes" },
        "2xl": { "value": "24", "type": "fontSizes" },
        "3xl": { "value": "30", "type": "fontSizes" },
        "4xl": { "value": "36", "type": "fontSizes" },
        "5xl": { "value": "48", "type": "fontSizes" }
      }
    },
    "spacing": {
      "xs": { "value": "4", "type": "spacing" },
      "sm": { "value": "8", "type": "spacing" },
      "md": { "value": "16", "type": "spacing" },
      "lg": { "value": "24", "type": "spacing" },
      "xl": { "value": "32", "type": "spacing" },
      "2xl": { "value": "48", "type": "spacing" },
      "3xl": { "value": "64", "type": "spacing" }
    },
    "borderRadius": {
      "sm": { "value": "4", "type": "borderRadius" },
      "md": { "value": "8", "type": "borderRadius" },
      "lg": { "value": "16", "type": "borderRadius" },
      "xl": { "value": "24", "type": "borderRadius" },
      "full": { "value": "999", "type": "borderRadius" }
    }
  }
}
```

### 4. Documentation Export

#### Style Guide HTML
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Design System Documentation</title>
  <link rel="stylesheet" href="design-system.css">
  <style>
    /* Documentation styles */
    .doc-container { max-width: 1200px; margin: 0 auto; padding: 2rem; }
    .color-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 1rem; }
    .color-swatch { border-radius: 8px; overflow: hidden; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
    .color-preview { height: 100px; }
    .color-info { padding: 0.5rem; background: white; }
    .type-specimen { margin: 2rem 0; }
    .component-example { margin: 2rem 0; padding: 2rem; border: 1px solid var(--color-border); border-radius: 8px; }
  </style>
</head>
<body>
  <div class="doc-container">
    <h1>Design System v1.0</h1>
    
    <!-- Colors -->
    <section id="colors">
      <h2>Colors</h2>
      <h3>Primary Palette</h3>
      <div class="color-grid">
        <div class="color-swatch">
          <div class="color-preview" style="background: var(--color-primary-500)"></div>
          <div class="color-info">
            <strong>Primary 500</strong><br>
            <code>#3b82f6</code>
          </div>
        </div>
        <!-- More color swatches -->
      </div>
    </section>
    
    <!-- Typography -->
    <section id="typography">
      <h2>Typography</h2>
      <div class="type-specimen">
        <h1 style="font-size: var(--text-5xl); line-height: var(--leading-tight)">
          Display Text (3rem)
        </h1>
        <h2 style="font-size: var(--text-3xl); line-height: var(--leading-tight)">
          Heading Large (1.875rem)
        </h2>
        <p style="font-size: var(--text-base); line-height: var(--leading-normal)">
          Body text uses the base size of 1rem with normal line height for optimal readability.
        </p>
      </div>
    </section>
    
    <!-- Components -->
    <section id="components">
      <h2>Components</h2>
      
      <div class="component-example">
        <h3>Buttons</h3>
        <button class="btn btn-primary">Primary Button</button>
        <button class="btn btn-secondary">Secondary Button</button>
        <button class="btn btn-tertiary">Tertiary Button</button>
      </div>
      
      <div class="component-example">
        <h3>Form Elements</h3>
        <div class="form-group">
          <label for="example-input">Label</label>
          <input type="text" id="example-input" placeholder="Placeholder text">
          <span class="help-text">Helper text goes here</span>
        </div>
      </div>
    </section>
    
    <!-- Usage Guidelines -->
    <section id="guidelines">
      <h2>Usage Guidelines</h2>
      <h3>Color Usage</h3>
      <ul>
        <li>Primary color for main actions and brand elements</li>
        <li>Neutral colors for text and backgrounds</li>
        <li>Semantic colors for status and feedback</li>
      </ul>
      
      <h3>Spacing System</h3>
      <p>Use the 8px grid system with predefined spacing tokens:</p>
      <ul>
        <li><code>--spacing-1</code> (4px) for tight spacing</li>
        <li><code>--spacing-2</code> (8px) for small gaps</li>
        <li><code>--spacing-4</code> (16px) for standard spacing</li>
        <li><code>--spacing-8</code> (32px) for section spacing</li>
      </ul>
    </section>
  </div>
  
  <script>
    // Interactive documentation features
    document.querySelectorAll('.color-swatch').forEach(swatch => {
      swatch.addEventListener('click', (e) => {
        const code = e.currentTarget.querySelector('code').textContent;
        navigator.clipboard.writeText(code);
        // Show copied feedback
      });
    });
  </script>
</body>
</html>
```

#### Component Library Package
```json
// package.json
{
  "name": "@company/design-system",
  "version": "1.0.0",
  "description": "Company Design System",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "files": [
    "dist",
    "tokens"
  ],
  "exports": {
    ".": "./dist/index.js",
    "./tokens": "./tokens/index.js",
    "./css": "./dist/design-system.css"
  },
  "scripts": {
    "build": "tsc && npm run build:css",
    "build:css": "postcss src/styles.css -o dist/design-system.css",
    "storybook": "storybook dev -p 6006",
    "build-storybook": "storybook build"
  }
}
```

### 5. Export Configuration
```javascript
const exportConfig = {
  formats: {
    web: {
      css: true,
      scss: true,
      js: true,
      ts: true,
      tailwind: true
    },
    mobile: {
      ios: true,
      android: true,
      reactNative: true
    },
    design: {
      figma: true,
      sketch: true,
      adobe: true
    },
    documentation: {
      html: true,
      markdown: true,
      storybook: true
    }
  },
  
  options: {
    includeComponents: true,
    includeExamples: true,
    generateTypes: true,
    darkModeSupport: true,
    prefixTokens: false
  },
  
  output: {
    directory: './design-system-export',
    zip: true,
    timestamp: true
  }
};
```

## Export Process

### Generation Pipeline
```javascript
async function exportDesignSystem(config) {
  const steps = [
    { name: 'Validate tokens', fn: validateTokens },
    { name: 'Generate web assets', fn: generateWebAssets },
    { name: 'Generate mobile assets', fn: generateMobileAssets },
    { name: 'Generate design tools', fn: generateDesignTools },
    { name: 'Generate documentation', fn: generateDocs },
    { name: 'Package output', fn: packageOutput }
  ];
  
  for (const step of steps) {
    console.log(`Executing: ${step.name}`);
    await step.fn(config);
  }
  
  return {
    success: true,
    outputPath: config.output.directory,
    formats: Object.keys(config.formats).filter(f => config.formats[f])
  };
}
```

---

*Export Design System v1.0 | Multi-format export | Complete documentation*