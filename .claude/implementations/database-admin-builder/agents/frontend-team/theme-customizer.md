# Theme Customizer Agent

## Purpose
Creates flexible, brand-aligned theming systems for admin panels by generating customizable design tokens, component styles, and visual configurations that ensure consistency while allowing for easy customization and white-labeling.

## Capabilities

### Theme Components
- Color schemes (light/dark modes)
- Typography systems
- Spacing scales
- Border radius tokens
- Shadow systems
- Animation presets
- Icon sets
- Component variants
- Responsive breakpoints
- Grid systems

### Customization Features
- Real-time theme preview
- Visual theme builder
- Brand color extraction
- Accessibility compliance
- Theme import/export
- Multi-tenant theming
- Seasonal themes
- A/B testing themes
- Performance optimization

### Framework Support
- CSS custom properties
- Tailwind CSS config
- Material-UI themes
- Ant Design tokens
- Bootstrap variables
- Styled Components
- Emotion themes
- CSS-in-JS systems

## Theme Generation Strategy

### Intelligent Theme Builder
```typescript
interface ThemeGenerator {
  generateTheme(brand: BrandConfig, preferences: ThemePreferences): Theme {
    const theme: Theme = {
      id: this.generateThemeId(brand),
      name: brand.name || 'Custom Theme',
      version: '1.0.0',
      colors: this.generateColorSystem(brand.primaryColor, preferences),
      typography: this.generateTypographySystem(brand.font, preferences),
      spacing: this.generateSpacingScale(preferences.density),
      borders: this.generateBorderSystem(preferences.style),
      shadows: this.generateShadowSystem(preferences.depth),
      animations: this.generateAnimationPresets(preferences.motion),
      components: this.generateComponentStyles(preferences),
      utilities: this.generateUtilityClasses()
    };
    
    // Ensure accessibility
    this.ensureAccessibility(theme);
    
    // Optimize for performance
    this.optimizeTheme(theme);
    
    return theme;
  }
  
  generateColorSystem(primaryColor: string, preferences: ThemePreferences): ColorSystem {
    const primary = this.parseColor(primaryColor);
    
    return {
      // Primary palette
      primary: {
        50: this.lighten(primary, 0.95),
        100: this.lighten(primary, 0.9),
        200: this.lighten(primary, 0.8),
        300: this.lighten(primary, 0.6),
        400: this.lighten(primary, 0.3),
        500: primary,
        600: this.darken(primary, 0.1),
        700: this.darken(primary, 0.3),
        800: this.darken(primary, 0.5),
        900: this.darken(primary, 0.7),
        950: this.darken(primary, 0.85)
      },
      
      // Secondary palette (complementary)
      secondary: this.generateComplementaryPalette(primary),
      
      // Accent palette (triadic)
      accent: this.generateTriadicPalette(primary),
      
      // Neutral palette
      neutral: this.generateNeutralPalette(primary),
      
      // Semantic colors
      semantic: {
        success: this.generateSemanticColor('#10b981', preferences),
        warning: this.generateSemanticColor('#f59e0b', preferences),
        error: this.generateSemanticColor('#ef4444', preferences),
        info: this.generateSemanticColor('#3b82f6', preferences)
      },
      
      // Surface colors
      surface: {
        background: preferences.mode === 'dark' ? '#0a0a0a' : '#ffffff',
        foreground: preferences.mode === 'dark' ? '#fafafa' : '#0a0a0a',
        card: preferences.mode === 'dark' ? '#1a1a1a' : '#ffffff',
        cardForeground: preferences.mode === 'dark' ? '#fafafa' : '#0a0a0a',
        popover: preferences.mode === 'dark' ? '#1a1a1a' : '#ffffff',
        popoverForeground: preferences.mode === 'dark' ? '#fafafa' : '#0a0a0a',
        border: preferences.mode === 'dark' ? '#2a2a2a' : '#e5e7eb',
        input: preferences.mode === 'dark' ? '#2a2a2a' : '#e5e7eb',
        ring: primary
      },
      
      // Special surfaces
      special: {
        muted: preferences.mode === 'dark' ? '#262626' : '#f3f4f6',
        mutedForeground: preferences.mode === 'dark' ? '#a3a3a3' : '#6b7280',
        destructive: '#ef4444',
        destructiveForeground: '#fafafa'
      }
    };
  }
  
  generateTypographySystem(brandFont?: string, preferences?: ThemePreferences): TypographySystem {
    const baseFont = brandFont || 'Inter';
    const monoFont = 'JetBrains Mono';
    
    return {
      fonts: {
        sans: `"${baseFont}", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`,
        serif: `"Merriweather", "Georgia", serif`,
        mono: `"${monoFont}", "Fira Code", "Courier New", monospace`
      },
      
      sizes: {
        xs: '0.75rem',    // 12px
        sm: '0.875rem',   // 14px
        base: '1rem',     // 16px
        lg: '1.125rem',   // 18px
        xl: '1.25rem',    // 20px
        '2xl': '1.5rem',  // 24px
        '3xl': '1.875rem',// 30px
        '4xl': '2.25rem', // 36px
        '5xl': '3rem',    // 48px
        '6xl': '3.75rem', // 60px
        '7xl': '4.5rem',  // 72px
        '8xl': '6rem',    // 96px
        '9xl': '8rem'     // 128px
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
        black: 900
      },
      
      lineHeights: {
        none: 1,
        tight: 1.25,
        snug: 1.375,
        normal: 1.5,
        relaxed: 1.625,
        loose: 2
      },
      
      letterSpacing: {
        tighter: '-0.05em',
        tight: '-0.025em',
        normal: '0em',
        wide: '0.025em',
        wider: '0.05em',
        widest: '0.1em'
      },
      
      // Predefined text styles
      styles: {
        h1: {
          fontSize: '2.25rem',
          lineHeight: 1.25,
          fontWeight: 700,
          letterSpacing: '-0.025em'
        },
        h2: {
          fontSize: '1.875rem',
          lineHeight: 1.25,
          fontWeight: 600,
          letterSpacing: '-0.025em'
        },
        h3: {
          fontSize: '1.5rem',
          lineHeight: 1.375,
          fontWeight: 600
        },
        h4: {
          fontSize: '1.25rem',
          lineHeight: 1.375,
          fontWeight: 600
        },
        h5: {
          fontSize: '1.125rem',
          lineHeight: 1.5,
          fontWeight: 600
        },
        h6: {
          fontSize: '1rem',
          lineHeight: 1.5,
          fontWeight: 600
        },
        body: {
          fontSize: '1rem',
          lineHeight: 1.5,
          fontWeight: 400
        },
        bodySmall: {
          fontSize: '0.875rem',
          lineHeight: 1.5,
          fontWeight: 400
        },
        caption: {
          fontSize: '0.75rem',
          lineHeight: 1.5,
          fontWeight: 400
        },
        button: {
          fontSize: '0.875rem',
          lineHeight: 1.25,
          fontWeight: 500,
          letterSpacing: '0.025em',
          textTransform: 'none'
        },
        code: {
          fontFamily: 'mono',
          fontSize: '0.875rem',
          lineHeight: 1.5
        }
      }
    };
  }
  
  generateSpacingScale(density: 'compact' | 'normal' | 'comfortable'): SpacingScale {
    const baseUnit = density === 'compact' ? 4 : density === 'comfortable' ? 6 : 5;
    
    return {
      0: '0',
      px: '1px',
      0.5: `${baseUnit * 0.125}px`,
      1: `${baseUnit * 0.25}px`,
      1.5: `${baseUnit * 0.375}px`,
      2: `${baseUnit * 0.5}px`,
      2.5: `${baseUnit * 0.625}px`,
      3: `${baseUnit * 0.75}px`,
      3.5: `${baseUnit * 0.875}px`,
      4: `${baseUnit}px`,
      5: `${baseUnit * 1.25}px`,
      6: `${baseUnit * 1.5}px`,
      7: `${baseUnit * 1.75}px`,
      8: `${baseUnit * 2}px`,
      9: `${baseUnit * 2.25}px`,
      10: `${baseUnit * 2.5}px`,
      11: `${baseUnit * 2.75}px`,
      12: `${baseUnit * 3}px`,
      14: `${baseUnit * 3.5}px`,
      16: `${baseUnit * 4}px`,
      20: `${baseUnit * 5}px`,
      24: `${baseUnit * 6}px`,
      28: `${baseUnit * 7}px`,
      32: `${baseUnit * 8}px`,
      36: `${baseUnit * 9}px`,
      40: `${baseUnit * 10}px`,
      44: `${baseUnit * 11}px`,
      48: `${baseUnit * 12}px`,
      52: `${baseUnit * 13}px`,
      56: `${baseUnit * 14}px`,
      60: `${baseUnit * 15}px`,
      64: `${baseUnit * 16}px`,
      72: `${baseUnit * 18}px`,
      80: `${baseUnit * 20}px`,
      96: `${baseUnit * 24}px`
    };
  }
}
```

### CSS Custom Properties Implementation
```css
/* Generated theme CSS variables */
:root {
  /* Colors */
  --color-primary-50: #eff6ff;
  --color-primary-100: #dbeafe;
  --color-primary-200: #bfdbfe;
  --color-primary-300: #93bbfc;
  --color-primary-400: #60a5fa;
  --color-primary-500: #3b82f6;
  --color-primary-600: #2563eb;
  --color-primary-700: #1d4ed8;
  --color-primary-800: #1e40af;
  --color-primary-900: #1e3a8a;
  --color-primary-950: #172554;
  
  /* Semantic colors */
  --color-background: #ffffff;
  --color-foreground: #0a0a0a;
  --color-card: #ffffff;
  --color-card-foreground: #0a0a0a;
  --color-popover: #ffffff;
  --color-popover-foreground: #0a0a0a;
  --color-border: #e5e7eb;
  --color-input: #e5e7eb;
  --color-ring: var(--color-primary-500);
  
  --color-success: #10b981;
  --color-success-foreground: #ffffff;
  --color-warning: #f59e0b;
  --color-warning-foreground: #ffffff;
  --color-error: #ef4444;
  --color-error-foreground: #ffffff;
  --color-info: #3b82f6;
  --color-info-foreground: #ffffff;
  
  /* Typography */
  --font-sans: "Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  --font-mono: "JetBrains Mono", "Fira Code", monospace;
  
  /* Font sizes */
  --text-xs: 0.75rem;
  --text-sm: 0.875rem;
  --text-base: 1rem;
  --text-lg: 1.125rem;
  --text-xl: 1.25rem;
  --text-2xl: 1.5rem;
  --text-3xl: 1.875rem;
  --text-4xl: 2.25rem;
  --text-5xl: 3rem;
  
  /* Spacing */
  --spacing-0: 0;
  --spacing-px: 1px;
  --spacing-0-5: 0.125rem;
  --spacing-1: 0.25rem;
  --spacing-2: 0.5rem;
  --spacing-3: 0.75rem;
  --spacing-4: 1rem;
  --spacing-5: 1.25rem;
  --spacing-6: 1.5rem;
  --spacing-8: 2rem;
  --spacing-10: 2.5rem;
  --spacing-12: 3rem;
  --spacing-16: 4rem;
  --spacing-20: 5rem;
  --spacing-24: 6rem;
  
  /* Border radius */
  --radius-none: 0;
  --radius-sm: 0.125rem;
  --radius-base: 0.25rem;
  --radius-md: 0.375rem;
  --radius-lg: 0.5rem;
  --radius-xl: 0.75rem;
  --radius-2xl: 1rem;
  --radius-3xl: 1.5rem;
  --radius-full: 9999px;
  
  /* Shadows */
  --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  --shadow-base: 0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1);
  --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
  --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);
  --shadow-xl: 0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1);
  --shadow-2xl: 0 25px 50px -12px rgb(0 0 0 / 0.25);
  --shadow-inner: inset 0 2px 4px 0 rgb(0 0 0 / 0.05);
  
  /* Transitions */
  --transition-fast: 150ms ease-in-out;
  --transition-base: 250ms ease-in-out;
  --transition-slow: 350ms ease-in-out;
  
  /* Z-index scale */
  --z-0: 0;
  --z-10: 10;
  --z-20: 20;
  --z-30: 30;
  --z-40: 40;
  --z-50: 50;
  --z-dropdown: 1000;
  --z-sticky: 1020;
  --z-fixed: 1030;
  --z-modal-backdrop: 1040;
  --z-modal: 1050;
  --z-popover: 1060;
  --z-tooltip: 1070;
  --z-notification: 1080;
}

/* Dark mode */
[data-theme="dark"] {
  --color-background: #0a0a0a;
  --color-foreground: #fafafa;
  --color-card: #1a1a1a;
  --color-card-foreground: #fafafa;
  --color-popover: #1a1a1a;
  --color-popover-foreground: #fafafa;
  --color-border: #2a2a2a;
  --color-input: #2a2a2a;
  
  /* Adjust shadows for dark mode */
  --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.25);
  --shadow-base: 0 1px 3px 0 rgb(0 0 0 / 0.3), 0 1px 2px -1px rgb(0 0 0 / 0.3);
  --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.3), 0 2px 4px -2px rgb(0 0 0 / 0.3);
  --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.3), 0 4px 6px -4px rgb(0 0 0 / 0.3);
  --shadow-xl: 0 20px 25px -5px rgb(0 0 0 / 0.3), 0 8px 10px -6px rgb(0 0 0 / 0.3);
  --shadow-2xl: 0 25px 50px -12px rgb(0 0 0 / 0.5);
}

/* High contrast mode */
@media (prefers-contrast: high) {
  :root {
    --color-border: #000000;
    --color-ring: var(--color-primary-700);
  }
  
  [data-theme="dark"] {
    --color-border: #ffffff;
    --color-ring: var(--color-primary-300);
  }
}

/* Reduced motion */
@media (prefers-reduced-motion: reduce) {
  :root {
    --transition-fast: 0ms;
    --transition-base: 0ms;
    --transition-slow: 0ms;
  }
}
```

### React Theme Provider
```tsx
import React, { createContext, useContext, useState, useEffect } from 'react';
import { Theme, ThemeConfig, ColorScheme } from '@/types/theme';

interface ThemeContextValue {
  theme: Theme;
  colorScheme: ColorScheme;
  setColorScheme: (scheme: ColorScheme) => void;
  updateTheme: (updates: Partial<Theme>) => void;
  resetTheme: () => void;
}

const ThemeContext = createContext<ThemeContextValue | undefined>(undefined);

export const ThemeProvider: React.FC<{
  defaultTheme?: Theme;
  storageKey?: string;
  children: React.ReactNode;
}> = ({ 
  defaultTheme = generateDefaultTheme(),
  storageKey = 'admin-theme',
  children 
}) => {
  const [theme, setTheme] = useState<Theme>(() => {
    // Load theme from storage
    const stored = localStorage.getItem(storageKey);
    if (stored) {
      try {
        return JSON.parse(stored);
      } catch (e) {
        console.error('Failed to parse stored theme:', e);
      }
    }
    return defaultTheme;
  });
  
  const [colorScheme, setColorScheme] = useState<ColorScheme>(() => {
    // Check system preference
    if (window.matchMedia('(prefers-color-scheme: dark)').matches) {
      return 'dark';
    }
    return 'light';
  });
  
  // Apply theme to DOM
  useEffect(() => {
    const root = document.documentElement;
    
    // Apply color scheme
    root.setAttribute('data-theme', colorScheme);
    
    // Apply CSS variables
    Object.entries(theme.cssVars).forEach(([key, value]) => {
      root.style.setProperty(key, value);
    });
    
    // Apply font imports
    if (theme.fonts.imports) {
      const fontLink = document.getElementById('theme-fonts') || 
        document.createElement('link');
      fontLink.id = 'theme-fonts';
      fontLink.rel = 'stylesheet';
      fontLink.href = theme.fonts.imports;
      document.head.appendChild(fontLink);
    }
    
    // Save to storage
    localStorage.setItem(storageKey, JSON.stringify(theme));
  }, [theme, colorScheme, storageKey]);
  
  // Listen for system color scheme changes
  useEffect(() => {
    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
    const handleChange = (e: MediaQueryListEvent) => {
      setColorScheme(e.matches ? 'dark' : 'light');
    };
    
    mediaQuery.addEventListener('change', handleChange);
    return () => mediaQuery.removeEventListener('change', handleChange);
  }, []);
  
  const updateTheme = (updates: Partial<Theme>) => {
    setTheme(prev => ({
      ...prev,
      ...updates,
      cssVars: {
        ...prev.cssVars,
        ...generateCssVars(updates)
      }
    }));
  };
  
  const resetTheme = () => {
    setTheme(defaultTheme);
    localStorage.removeItem(storageKey);
  };
  
  return (
    <ThemeContext.Provider
      value={{
        theme,
        colorScheme,
        setColorScheme,
        updateTheme,
        resetTheme
      }}
    >
      {children}
    </ThemeContext.Provider>
  );
};

export const useTheme = () => {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error('useTheme must be used within a ThemeProvider');
  }
  return context;
};

// Theme customizer component
export const ThemeCustomizer: React.FC = () => {
  const { theme, updateTheme, resetTheme } = useTheme();
  const [isOpen, setIsOpen] = useState(false);
  const [activeTab, setActiveTab] = useState<'colors' | 'typography' | 'spacing'>('colors');
  
  return (
    <>
      <button
        onClick={() => setIsOpen(true)}
        className="fixed bottom-4 right-4 p-3 rounded-full bg-primary-500 text-white shadow-lg hover:bg-primary-600 transition-colors"
        aria-label="Open theme customizer"
      >
        <PaletteIcon className="w-6 h-6" />
      </button>
      
      <Sheet open={isOpen} onOpenChange={setIsOpen}>
        <SheetContent side="right" className="w-[400px] overflow-y-auto">
          <SheetHeader>
            <SheetTitle>Theme Customizer</SheetTitle>
          </SheetHeader>
          
          <Tabs value={activeTab} onValueChange={setActiveTab} className="mt-6">
            <TabsList className="grid w-full grid-cols-3">
              <TabsTrigger value="colors">Colors</TabsTrigger>
              <TabsTrigger value="typography">Typography</TabsTrigger>
              <TabsTrigger value="spacing">Spacing</TabsTrigger>
            </TabsList>
            
            <TabsContent value="colors" className="space-y-6">
              <div>
                <h3 className="text-sm font-medium mb-3">Primary Color</h3>
                <div className="flex items-center gap-3">
                  <input
                    type="color"
                    value={theme.colors.primary[500]}
                    onChange={(e) => {
                      const newPalette = generateColorPalette(e.target.value);
                      updateTheme({
                        colors: {
                          ...theme.colors,
                          primary: newPalette
                        }
                      });
                    }}
                    className="w-12 h-12 rounded cursor-pointer"
                  />
                  <Input
                    value={theme.colors.primary[500]}
                    onChange={(e) => {
                      const newPalette = generateColorPalette(e.target.value);
                      updateTheme({
                        colors: {
                          ...theme.colors,
                          primary: newPalette
                        }
                      });
                    }}
                    placeholder="#3b82f6"
                  />
                  <ColorPicker
                    color={theme.colors.primary[500]}
                    onChange={(color) => {
                      const newPalette = generateColorPalette(color);
                      updateTheme({
                        colors: {
                          ...theme.colors,
                          primary: newPalette
                        }
                      });
                    }}
                  />
                </div>
                
                {/* Color palette preview */}
                <div className="grid grid-cols-11 gap-1 mt-3">
                  {Object.entries(theme.colors.primary).map(([key, value]) => (
                    <div
                      key={key}
                      className="aspect-square rounded"
                      style={{ backgroundColor: value }}
                      title={`${key}: ${value}`}
                    />
                  ))}
                </div>
              </div>
              
              <div>
                <h3 className="text-sm font-medium mb-3">Semantic Colors</h3>
                <div className="space-y-3">
                  {Object.entries(theme.colors.semantic).map(([key, value]) => (
                    <div key={key} className="flex items-center justify-between">
                      <label className="text-sm capitalize">{key}</label>
                      <div className="flex items-center gap-2">
                        <input
                          type="color"
                          value={value.DEFAULT}
                          onChange={(e) => {
                            updateTheme({
                              colors: {
                                ...theme.colors,
                                semantic: {
                                  ...theme.colors.semantic,
                                  [key]: generateSemanticColor(e.target.value)
                                }
                              }
                            });
                          }}
                          className="w-8 h-8 rounded cursor-pointer"
                        />
                        <span className="text-xs text-muted-foreground">
                          {value.DEFAULT}
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
              
              <div>
                <h3 className="text-sm font-medium mb-3">Border Radius</h3>
                <RadioGroup
                  value={theme.borderRadius.base}
                  onValueChange={(value) => {
                    updateTheme({
                      borderRadius: generateBorderRadiusScale(value)
                    });
                  }}
                >
                  <div className="grid grid-cols-2 gap-3">
                    {['none', 'sm', 'md', 'lg', 'xl', '2xl'].map(size => (
                      <label
                        key={size}
                        className="flex items-center space-x-2 cursor-pointer"
                      >
                        <RadioGroupItem value={size} />
                        <div className="flex-1">
                          <div
                            className="w-full h-12 bg-primary-100 border-2 border-primary-500"
                            style={{
                              borderRadius: getBorderRadiusValue(size)
                            }}
                          />
                          <span className="text-xs text-muted-foreground mt-1">
                            {size}
                          </span>
                        </div>
                      </label>
                    ))}
                  </div>
                </RadioGroup>
              </div>
            </TabsContent>
            
            <TabsContent value="typography" className="space-y-6">
              <div>
                <h3 className="text-sm font-medium mb-3">Font Family</h3>
                <Select
                  value={theme.typography.fontFamily.sans}
                  onValueChange={(value) => {
                    updateTheme({
                      typography: {
                        ...theme.typography,
                        fontFamily: {
                          ...theme.typography.fontFamily,
                          sans: value
                        }
                      }
                    });
                  }}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {[
                      'Inter',
                      'Roboto',
                      'Open Sans',
                      'Lato',
                      'Poppins',
                      'Montserrat',
                      'Raleway',
                      'Source Sans Pro',
                      'Nunito',
                      'Work Sans'
                    ].map(font => (
                      <SelectItem key={font} value={font}>
                        <span style={{ fontFamily: font }}>{font}</span>
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              
              <div>
                <h3 className="text-sm font-medium mb-3">Base Font Size</h3>
                <Slider
                  value={[parseInt(theme.typography.fontSize.base)]}
                  onValueChange={([value]) => {
                    updateTheme({
                      typography: {
                        ...theme.typography,
                        fontSize: generateFontSizeScale(value)
                      }
                    });
                  }}
                  min={14}
                  max={20}
                  step={1}
                  className="w-full"
                />
                <div className="flex justify-between text-xs text-muted-foreground mt-1">
                  <span>14px</span>
                  <span>{theme.typography.fontSize.base}</span>
                  <span>20px</span>
                </div>
              </div>
              
              <div>
                <h3 className="text-sm font-medium mb-3">Type Scale</h3>
                <div className="space-y-2">
                  {Object.entries(theme.typography.fontSize).map(([key, value]) => (
                    <div
                      key={key}
                      className="flex items-center justify-between py-2"
                    >
                      <span
                        className="font-medium"
                        style={{ fontSize: value }}
                      >
                        {key}
                      </span>
                      <span className="text-xs text-muted-foreground">
                        {value}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            </TabsContent>
            
            <TabsContent value="spacing" className="space-y-6">
              <div>
                <h3 className="text-sm font-medium mb-3">Spacing Unit</h3>
                <RadioGroup
                  value={theme.spacing.unit}
                  onValueChange={(value) => {
                    updateTheme({
                      spacing: generateSpacingScale(value)
                    });
                  }}
                >
                  <div className="space-y-2">
                    {[
                      { value: '4', label: 'Compact (4px base)' },
                      { value: '5', label: 'Normal (5px base)' },
                      { value: '6', label: 'Comfortable (6px base)' },
                      { value: '8', label: 'Spacious (8px base)' }
                    ].map(option => (
                      <label
                        key={option.value}
                        className="flex items-center space-x-2 cursor-pointer"
                      >
                        <RadioGroupItem value={option.value} />
                        <span className="text-sm">{option.label}</span>
                      </label>
                    ))}
                  </div>
                </RadioGroup>
              </div>
              
              <div>
                <h3 className="text-sm font-medium mb-3">Spacing Scale</h3>
                <div className="space-y-2">
                  {Object.entries(theme.spacing.scale).slice(0, 12).map(([key, value]) => (
                    <div
                      key={key}
                      className="flex items-center justify-between"
                    >
                      <span className="text-sm text-muted-foreground">
                        {key}
                      </span>
                      <div className="flex items-center gap-2">
                        <div
                          className="bg-primary-200 h-4"
                          style={{ width: value }}
                        />
                        <span className="text-xs text-muted-foreground w-12">
                          {value}
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </TabsContent>
          </Tabs>
          
          <div className="flex gap-3 mt-8">
            <Button
              variant="outline"
              onClick={resetTheme}
              className="flex-1"
            >
              Reset to Default
            </Button>
            <Button
              onClick={() => {
                // Export theme
                const themeData = JSON.stringify(theme, null, 2);
                const blob = new Blob([themeData], { type: 'application/json' });
                const url = URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                a.download = 'admin-theme.json';
                a.click();
                URL.revokeObjectURL(url);
              }}
              className="flex-1"
            >
              Export Theme
            </Button>
          </div>
        </SheetContent>
      </Sheet>
    </>
  );
};
```

### Vue.js Theme System
```vue
<template>
  <div class="theme-provider">
    <slot />
    
    <!-- Theme customizer -->
    <Teleport to="body">
      <button
        @click="customizerOpen = true"
        class="theme-customizer-trigger"
        aria-label="Open theme customizer"
      >
        <PaletteIcon />
      </button>
      
      <Transition name="slide">
        <div v-if="customizerOpen" class="theme-customizer">
          <div class="customizer-header">
            <h2>Theme Customizer</h2>
            <button @click="customizerOpen = false">
              <XIcon />
            </button>
          </div>
          
          <div class="customizer-tabs">
            <button
              v-for="tab in tabs"
              :key="tab.id"
              @click="activeTab = tab.id"
              :class="{ active: activeTab === tab.id }"
              class="tab-button"
            >
              {{ tab.label }}
            </button>
          </div>
          
          <div class="customizer-content">
            <!-- Colors tab -->
            <div v-if="activeTab === 'colors'" class="tab-content">
              <div class="form-group">
                <label>Primary Color</label>
                <div class="color-input-group">
                  <input
                    type="color"
                    v-model="theme.colors.primary"
                    @input="updatePrimaryColor"
                  />
                  <input
                    type="text"
                    v-model="theme.colors.primary"
                    @input="updatePrimaryColor"
                    placeholder="#3b82f6"
                  />
                </div>
                
                <!-- Color palette -->
                <div class="color-palette">
                  <div
                    v-for="(color, shade) in primaryPalette"
                    :key="shade"
                    :style="{ backgroundColor: color }"
                    :title="`${shade}: ${color}`"
                    class="color-swatch"
                  />
                </div>
              </div>
              
              <div class="form-group">
                <label>Color Mode</label>
                <div class="radio-group">
                  <label>
                    <input
                      type="radio"
                      value="light"
                      v-model="colorMode"
                    />
                    Light
                  </label>
                  <label>
                    <input
                      type="radio"
                      value="dark"
                      v-model="colorMode"
                    />
                    Dark
                  </label>
                  <label>
                    <input
                      type="radio"
                      value="system"
                      v-model="colorMode"
                    />
                    System
                  </label>
                </div>
              </div>
              
              <div class="form-group">
                <label>Semantic Colors</label>
                <div class="semantic-colors">
                  <div
                    v-for="(color, type) in theme.colors.semantic"
                    :key="type"
                    class="semantic-color-row"
                  >
                    <span>{{ type }}</span>
                    <div class="color-input-small">
                      <input
                        type="color"
                        :value="color"
                        @input="updateSemanticColor(type, $event.target.value)"
                      />
                      <span>{{ color }}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            
            <!-- Typography tab -->
            <div v-if="activeTab === 'typography'" class="tab-content">
              <div class="form-group">
                <label>Font Family</label>
                <select v-model="theme.typography.fontFamily">
                  <option
                    v-for="font in availableFonts"
                    :key="font"
                    :value="font"
                    :style="{ fontFamily: font }"
                  >
                    {{ font }}
                  </option>
                </select>
              </div>
              
              <div class="form-group">
                <label>Base Font Size</label>
                <div class="slider-group">
                  <input
                    type="range"
                    v-model.number="baseFontSize"
                    @input="updateFontSizes"
                    min="14"
                    max="20"
                    step="1"
                  />
                  <span>{{ baseFontSize }}px</span>
                </div>
              </div>
              
              <div class="form-group">
                <label>Type Scale</label>
                <div class="type-scale-preview">
                  <div
                    v-for="(size, key) in theme.typography.sizes"
                    :key="key"
                    class="type-scale-row"
                  >
                    <span
                      :style="{ fontSize: size }"
                      class="type-sample"
                    >
                      {{ key }}
                    </span>
                    <span class="type-size">{{ size }}</span>
                  </div>
                </div>
              </div>
            </div>
            
            <!-- Spacing tab -->
            <div v-if="activeTab === 'spacing'" class="tab-content">
              <div class="form-group">
                <label>Spacing Density</label>
                <div class="radio-group">
                  <label>
                    <input
                      type="radio"
                      value="compact"
                      v-model="spacingDensity"
                      @change="updateSpacing"
                    />
                    Compact
                  </label>
                  <label>
                    <input
                      type="radio"
                      value="normal"
                      v-model="spacingDensity"
                      @change="updateSpacing"
                    />
                    Normal
                  </label>
                  <label>
                    <input
                      type="radio"
                      value="comfortable"
                      v-model="spacingDensity"
                      @change="updateSpacing"
                    />
                    Comfortable
                  </label>
                </div>
              </div>
              
              <div class="form-group">
                <label>Border Radius</label>
                <div class="radius-preview">
                  <div
                    v-for="radius in borderRadiusOptions"
                    :key="radius.value"
                    @click="theme.borderRadius = radius.value"
                    :class="{ active: theme.borderRadius === radius.value }"
                    class="radius-option"
                  >
                    <div
                      class="radius-box"
                      :style="{ borderRadius: radius.preview }"
                    />
                    <span>{{ radius.label }}</span>
                  </div>
                </div>
              </div>
              
              <div class="form-group">
                <label>Shadow Depth</label>
                <div class="shadow-preview">
                  <div
                    v-for="(shadow, key) in theme.shadows"
                    :key="key"
                    class="shadow-row"
                  >
                    <div
                      class="shadow-box"
                      :style="{ boxShadow: shadow }"
                    />
                    <span>{{ key }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
          
          <div class="customizer-actions">
            <button @click="resetTheme" class="btn-secondary">
              Reset
            </button>
            <button @click="exportTheme" class="btn-primary">
              Export
            </button>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted, provide } from 'vue';
import { useColorMode } from '@vueuse/core';
import type { Theme, ColorMode } from '@/types/theme';

interface Props {
  defaultTheme?: Theme;
  storageKey?: string;
}

const props = withDefaults(defineProps<Props>(), {
  storageKey: 'admin-theme'
});

const emit = defineEmits(['theme-change']);

// State
const theme = ref<Theme>(loadTheme() || generateDefaultTheme());
const customizerOpen = ref(false);
const activeTab = ref<'colors' | 'typography' | 'spacing'>('colors');
const colorMode = useColorMode();
const baseFontSize = ref(16);
const spacingDensity = ref<'compact' | 'normal' | 'comfortable'>('normal');

// Computed
const primaryPalette = computed(() => 
  generateColorPalette(theme.value.colors.primary)
);

const tabs = [
  { id: 'colors', label: 'Colors' },
  { id: 'typography', label: 'Typography' },
  { id: 'spacing', label: 'Spacing' }
];

const availableFonts = [
  'Inter',
  'Roboto',
  'Open Sans',
  'Lato',
  'Poppins',
  'Montserrat',
  'Raleway',
  'Source Sans Pro',
  'Nunito',
  'Work Sans'
];

const borderRadiusOptions = [
  { value: 'none', label: 'None', preview: '0' },
  { value: 'sm', label: 'Small', preview: '0.125rem' },
  { value: 'md', label: 'Medium', preview: '0.375rem' },
  { value: 'lg', label: 'Large', preview: '0.5rem' },
  { value: 'xl', label: 'Extra Large', preview: '0.75rem' },
  { value: 'full', label: 'Full', preview: '9999px' }
];

// Methods
function loadTheme(): Theme | null {
  const stored = localStorage.getItem(props.storageKey);
  if (stored) {
    try {
      return JSON.parse(stored);
    } catch (e) {
      console.error('Failed to parse stored theme:', e);
    }
  }
  return null;
}

function saveTheme() {
  localStorage.setItem(props.storageKey, JSON.stringify(theme.value));
}

function applyTheme() {
  const root = document.documentElement;
  
  // Apply CSS variables
  Object.entries(flattenTheme(theme.value)).forEach(([key, value]) => {
    root.style.setProperty(`--${key}`, value);
  });
  
  // Apply font
  if (theme.value.typography.fontFamily) {
    loadGoogleFont(theme.value.typography.fontFamily);
  }
  
  emit('theme-change', theme.value);
}

function updatePrimaryColor(color: string) {
  const palette = generateColorPalette(color);
  theme.value.colors.primary = color;
  theme.value.colors.primaryPalette = palette;
  applyTheme();
}

function updateSemanticColor(type: string, color: string) {
  theme.value.colors.semantic[type] = color;
  applyTheme();
}

function updateFontSizes() {
  theme.value.typography.sizes = generateFontSizeScale(baseFontSize.value);
  applyTheme();
}

function updateSpacing() {
  theme.value.spacing = generateSpacingScale(spacingDensity.value);
  applyTheme();
}

function resetTheme() {
  theme.value = generateDefaultTheme();
  applyTheme();
  saveTheme();
}

function exportTheme() {
  const data = JSON.stringify(theme.value, null, 2);
  const blob = new Blob([data], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `${props.storageKey}.json`;
  a.click();
  URL.revokeObjectURL(url);
}

// Watchers
watch(theme, () => {
  applyTheme();
  saveTheme();
}, { deep: true });

watch(colorMode, (mode) => {
  theme.value.colorMode = mode;
});

// Lifecycle
onMounted(() => {
  applyTheme();
});

// Provide theme to children
provide('theme', theme);
provide('updateTheme', (updates: Partial<Theme>) => {
  Object.assign(theme.value, updates);
});

// Helper functions
function generateColorPalette(baseColor: string) {
  // Implementation to generate color shades
  const color = parseColor(baseColor);
  return {
    50: lighten(color, 0.95),
    100: lighten(color, 0.9),
    200: lighten(color, 0.8),
    300: lighten(color, 0.6),
    400: lighten(color, 0.3),
    500: baseColor,
    600: darken(color, 0.1),
    700: darken(color, 0.3),
    800: darken(color, 0.5),
    900: darken(color, 0.7),
    950: darken(color, 0.85)
  };
}

function generateFontSizeScale(base: number) {
  const scale = 1.25; // Major third scale
  return {
    xs: `${base * Math.pow(scale, -2)}px`,
    sm: `${base * Math.pow(scale, -1)}px`,
    base: `${base}px`,
    lg: `${base * Math.pow(scale, 1)}px`,
    xl: `${base * Math.pow(scale, 2)}px`,
    '2xl': `${base * Math.pow(scale, 3)}px`,
    '3xl': `${base * Math.pow(scale, 4)}px`,
    '4xl': `${base * Math.pow(scale, 5)}px`,
    '5xl': `${base * Math.pow(scale, 6)}px`
  };
}

function generateSpacingScale(density: 'compact' | 'normal' | 'comfortable') {
  const base = density === 'compact' ? 4 : density === 'comfortable' ? 6 : 5;
  const scale: Record<string, string> = {};
  
  for (let i = 0; i <= 20; i++) {
    scale[i] = `${base * i * 0.25}px`;
  }
  
  return scale;
}

function flattenTheme(obj: any, prefix = ''): Record<string, string> {
  const result: Record<string, string> = {};
  
  for (const [key, value] of Object.entries(obj)) {
    const newKey = prefix ? `${prefix}-${key}` : key;
    
    if (typeof value === 'object' && value !== null) {
      Object.assign(result, flattenTheme(value, newKey));
    } else {
      result[newKey] = String(value);
    }
  }
  
  return result;
}

function loadGoogleFont(fontFamily: string) {
  const link = document.createElement('link');
  link.href = `https://fonts.googleapis.com/css2?family=${fontFamily.replace(' ', '+')}:wght@300;400;500;600;700&display=swap`;
  link.rel = 'stylesheet';
  document.head.appendChild(link);
}
</script>

<style scoped>
.theme-customizer-trigger {
  position: fixed;
  bottom: 1rem;
  right: 1rem;
  width: 3rem;
  height: 3rem;
  border-radius: 50%;
  background: var(--color-primary-500);
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: var(--shadow-lg);
  cursor: pointer;
  transition: all var(--transition-base);
}

.theme-customizer-trigger:hover {
  background: var(--color-primary-600);
  transform: scale(1.05);
}

.theme-customizer {
  position: fixed;
  top: 0;
  right: 0;
  bottom: 0;
  width: 400px;
  background: var(--color-background);
  border-left: 1px solid var(--color-border);
  box-shadow: var(--shadow-xl);
  z-index: var(--z-modal);
  overflow-y: auto;
}

.color-palette {
  display: grid;
  grid-template-columns: repeat(11, 1fr);
  gap: 0.25rem;
  margin-top: 0.75rem;
}

.color-swatch {
  aspect-ratio: 1;
  border-radius: var(--radius-sm);
  cursor: pointer;
  transition: transform var(--transition-fast);
}

.color-swatch:hover {
  transform: scale(1.1);
}

.type-scale-preview {
  space-y: 0.5rem;
}

.type-scale-row {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  padding: 0.5rem 0;
}

.type-sample {
  font-weight: 500;
}

.type-size {
  font-size: var(--text-xs);
  color: var(--color-muted-foreground);
}

.radius-preview {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1rem;
}

.radius-option {
  text-align: center;
  cursor: pointer;
  padding: 0.5rem;
  border-radius: var(--radius-md);
  transition: all var(--transition-fast);
}

.radius-option:hover,
.radius-option.active {
  background: var(--color-primary-100);
}

.radius-box {
  width: 100%;
  height: 3rem;
  background: var(--color-primary-200);
  border: 2px solid var(--color-primary-500);
  margin-bottom: 0.25rem;
}

.shadow-preview {
  space-y: 1rem;
}

.shadow-row {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.shadow-box {
  width: 4rem;
  height: 2rem;
  background: var(--color-background);
  border-radius: var(--radius-md);
}

/* Transitions */
.slide-enter-active,
.slide-leave-active {
  transition: transform var(--transition-base);
}

.slide-enter-from,
.slide-leave-to {
  transform: translateX(100%);
}
</style>
```

### Theme Templates
```typescript
// Pre-built theme templates
export const themeTemplates = {
  // Modern Blue (Default)
  modernBlue: {
    name: 'Modern Blue',
    colors: {
      primary: '#3b82f6',
      secondary: '#8b5cf6',
      accent: '#06b6d4'
    },
    style: 'modern',
    borderRadius: 'md',
    density: 'normal'
  },
  
  // Enterprise Gray
  enterpriseGray: {
    name: 'Enterprise Gray',
    colors: {
      primary: '#6b7280',
      secondary: '#4b5563',
      accent: '#3b82f6'
    },
    style: 'professional',
    borderRadius: 'sm',
    density: 'compact'
  },
  
  // Vibrant Purple
  vibrantPurple: {
    name: 'Vibrant Purple',
    colors: {
      primary: '#8b5cf6',
      secondary: '#ec4899',
      accent: '#f59e0b'
    },
    style: 'playful',
    borderRadius: 'lg',
    density: 'comfortable'
  },
  
  // Nature Green
  natureGreen: {
    name: 'Nature Green',
    colors: {
      primary: '#10b981',
      secondary: '#059669',
      accent: '#f59e0b'
    },
    style: 'organic',
    borderRadius: 'xl',
    density: 'comfortable'
  },
  
  // Midnight Dark
  midnightDark: {
    name: 'Midnight Dark',
    colors: {
      primary: '#6366f1',
      secondary: '#8b5cf6',
      accent: '#06b6d4'
    },
    style: 'dark',
    borderRadius: 'md',
    density: 'normal',
    forceDarkMode: true
  },
  
  // Minimalist White
  minimalistWhite: {
    name: 'Minimalist White',
    colors: {
      primary: '#000000',
      secondary: '#374151',
      accent: '#3b82f6'
    },
    style: 'minimal',
    borderRadius: 'none',
    density: 'normal',
    forceLightMode: true
  }
};

// Accessibility themes
export const accessibilityThemes = {
  highContrast: {
    name: 'High Contrast',
    colors: {
      primary: '#000000',
      secondary: '#ffffff',
      background: '#ffffff',
      foreground: '#000000',
      border: '#000000'
    },
    borderWidth: '2px',
    focusRingWidth: '4px'
  },
  
  colorBlindSafe: {
    name: 'Color Blind Safe',
    colors: {
      primary: '#0173B2',
      secondary: '#DE8F05',
      success: '#029E73',
      warning: '#CC78BC',
      error: '#CA0020',
      info: '#0173B2'
    }
  },
  
  largeText: {
    name: 'Large Text',
    typography: {
      baseSize: 18,
      scale: 1.333
    },
    spacing: 'comfortable'
  }
};
```

## Integration Points
- Works with all Frontend Team agents for consistent styling
- Provides design tokens to UI Component Builder
- Coordinates with Dashboard Designer for layout theming
- Integrates with Access Control Manager for role-based themes
- Exports configurations for Build Tool integration

## Best Practices
1. Always maintain WCAG AA color contrast ratios
2. Provide both light and dark mode options
3. Use semantic color naming for flexibility
4. Keep theme switching instant without reload
5. Support CSS custom properties for runtime changes
6. Optimize theme size for performance
7. Allow partial theme overrides
8. Version themes for backward compatibility
9. Test themes across different screens
10. Document theme customization options