# Brand Guidelines Memory

Persistent storage for brand identity standards, visual guidelines, and brand evolution tracking.

## Memory Structure

```json
{
  "brands": {
    "brand_001": {
      "identity": {
        "name": "TechFlow",
        "tagline": "Streamline Your Digital Life",
        "established": "2024-01-15",
        "lastUpdated": "2024-01-20",
        "version": "2.0"
      },
      
      "foundation": {
        "mission": "Empower professionals with intuitive digital tools",
        "vision": "A world where technology amplifies human potential",
        "values": [
          "Simplicity in complexity",
          "User empowerment",
          "Continuous innovation",
          "Inclusive design"
        ],
        "personality": {
          "archetype": "The Sage Creator",
          "traits": {
            "primary": ["Intelligent", "Approachable", "Reliable"],
            "secondary": ["Innovative", "Efficient"],
            "never": ["Complicated", "Cold", "Exclusive"]
          }
        }
      },
      
      "visual": {
        "logo": {
          "primary": {
            "file": "logo-primary.svg",
            "usage": "Default on light backgrounds",
            "clearSpace": "2x height on all sides",
            "minSize": "120px web, 30mm print"
          },
          "variations": [
            {
              "type": "icon-only",
              "file": "logo-icon.svg",
              "usage": "Small spaces, app icons"
            },
            {
              "type": "wordmark",
              "file": "logo-wordmark.svg",
              "usage": "When icon is elsewhere"
            }
          ],
          "forbidden": [
            "Stretching or squashing",
            "Rotating",
            "Adding effects",
            "Changing colors"
          ]
        },
        
        "colors": {
          "primary": {
            "techBlue": {
              "hex": "#0066FF",
              "rgb": "0, 102, 255",
              "cmyk": "100, 60, 0, 0",
              "pantone": "2728 C",
              "usage": "Primary actions, headers, links",
              "variations": {
                "light": "#E6F0FF",
                "dark": "#0052CC"
              }
            }
          },
          "secondary": {
            "growthGreen": {
              "hex": "#00D4AA",
              "usage": "Success states, positive actions"
            },
            "warmCoral": {
              "hex": "#FF6B6B",
              "usage": "Accents, attention, warmth"
            }
          },
          "neutrals": {
            "scale": [
              { "name": "neutral-50", "hex": "#FAFAFA" },
              { "name": "neutral-100", "hex": "#F5F5F5" },
              { "name": "neutral-200", "hex": "#E5E5E5" },
              { "name": "neutral-300", "hex": "#D4D4D4" },
              { "name": "neutral-400", "hex": "#A3A3A3" },
              { "name": "neutral-500", "hex": "#737373" },
              { "name": "neutral-600", "hex": "#525252" },
              { "name": "neutral-700", "hex": "#404040" },
              { "name": "neutral-800", "hex": "#262626" },
              { "name": "neutral-900", "hex": "#171717" }
            ]
          },
          "semantic": {
            "error": "#DC2626",
            "warning": "#F59E0B",
            "info": "#3B82F6",
            "success": "#10B981"
          }
        },
        
        "typography": {
          "primary": {
            "family": "Inter",
            "fallback": "-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
            "weights": [400, 500, 600, 700],
            "usage": "All text except code"
          },
          "display": {
            "family": "Inter Display",
            "weights": [700, 800],
            "usage": "Large headlines only"
          },
          "mono": {
            "family": "JetBrains Mono",
            "usage": "Code, technical content"
          },
          "hierarchy": {
            "h1": { "size": 48, "weight": 700, "lineHeight": 1.2 },
            "h2": { "size": 36, "weight": 700, "lineHeight": 1.3 },
            "h3": { "size": 28, "weight": 600, "lineHeight": 1.4 },
            "h4": { "size": 24, "weight": 600, "lineHeight": 1.4 },
            "h5": { "size": 20, "weight": 600, "lineHeight": 1.5 },
            "body": { "size": 16, "weight": 400, "lineHeight": 1.6 },
            "small": { "size": 14, "weight": 400, "lineHeight": 1.5 }
          }
        },
        
        "imagery": {
          "photography": {
            "style": "Natural lighting, authentic moments",
            "subjects": "Diverse professionals in real environments",
            "treatment": "Slight desaturation, cool tones",
            "avoid": "Stock photos, staged scenes"
          },
          "illustrations": {
            "style": "Geometric, minimal, purposeful",
            "colors": "Limited to brand palette",
            "usage": "Empty states, onboarding, features"
          },
          "icons": {
            "style": "Outlined, 2px stroke",
            "set": "Custom based on Lucide",
            "sizes": [16, 20, 24, 32, 48]
          }
        },
        
        "patterns": {
          "graphic": {
            "gridPattern": {
              "description": "Subtle dot grid",
              "usage": "Backgrounds, empty states",
              "opacity": 0.05
            },
            "wavePattern": {
              "description": "Flowing lines suggesting data flow",
              "usage": "Hero sections, dividers"
            }
          }
        }
      },
      
      "voice": {
        "principles": [
          "Clear over clever",
          "Human over corporate",
          "Helpful over salesy",
          "Confident not arrogant"
        ],
        "tone": {
          "default": "Professional yet approachable",
          "variations": {
            "error": "Understanding and helpful",
            "success": "Warm and encouraging",
            "onboarding": "Friendly and patient",
            "marketing": "Confident and inspiring"
          }
        },
        "vocabulary": {
          "use": ["Streamline", "Empower", "Intuitive", "Seamless"],
          "avoid": ["Leverage", "Synergy", "Disrupt", "Revolutionary"]
        },
        "examples": {
          "cta": {
            "good": "Start your free trial",
            "bad": "Sign up now!!!"
          },
          "error": {
            "good": "We couldn't find that page. Let's get you back on track.",
            "bad": "Error 404: Page not found"
          }
        }
      },
      
      "applications": {
        "digital": {
          "website": {
            "grid": "12 column, 24px gutter",
            "maxWidth": 1280,
            "breakpoints": [320, 768, 1024, 1280]
          },
          "email": {
            "template": "Single column, 600px max",
            "headerHeight": 80,
            "footerStyle": "Minimal with social links"
          },
          "social": {
            "templates": {
              "post": "1080x1080",
              "story": "1080x1920",
              "cover": "1920x1080"
            }
          }
        },
        "print": {
          "businessCard": {
            "size": "3.5 x 2 inches",
            "paper": "Matte, 16pt",
            "finish": "Spot UV on logo"
          },
          "letterhead": {
            "margins": "1 inch all sides",
            "logoPlacement": "Top left"
          }
        }
      },
      
      "evolution": {
        "history": [
          {
            "version": "1.0",
            "date": "2023-06-15",
            "changes": ["Initial brand creation"],
            "rationale": "Company launch"
          },
          {
            "version": "2.0",
            "date": "2024-01-15",
            "changes": [
              "Refined color palette",
              "Updated typography to Inter",
              "Simplified logo"
            ],
            "rationale": "Market feedback and modernization"
          }
        ]
      }
    }
  },
  
  "activeBrand": "brand_001",
  
  "compliance": {
    "checkpoints": [
      {
        "date": "2024-01-20",
        "reviewer": "brand-strategist",
        "score": 94,
        "issues": [
          "Some social posts using off-brand colors",
          "Email templates need updating"
        ]
      }
    ],
    "monitoring": {
      "frequency": "Weekly",
      "automated": true,
      "alerts": ["Major violations", "Repeated misuse"]
    }
  }
}
```

## Brand Management

### Brand Creation
```javascript
const createBrand = async (brandData) => {
  const brandId = generateBrandId();
  
  const brand = {
    identity: {
      ...brandData.identity,
      established: new Date().toISOString(),
      version: "1.0"
    },
    foundation: brandData.foundation,
    visual: processVisualAssets(brandData.visual),
    voice: brandData.voice,
    applications: generateApplicationTemplates(brandData),
    evolution: {
      history: [{
        version: "1.0",
        date: new Date().toISOString(),
        changes: ["Initial brand creation"],
        rationale: brandData.rationale || "New brand launch"
      }]
    }
  };
  
  await memory.set(`brands.${brandId}`, brand);
  
  // Set as active if first brand
  const existingBrands = await memory.get('brands');
  if (Object.keys(existingBrands).length === 1) {
    await memory.set('activeBrand', brandId);
  }
  
  return { brandId, brand };
};
```

### Brand Updates
```javascript
const updateBrand = async (brandId, updates, rationale) => {
  const current = await memory.get(`brands.${brandId}`);
  const version = incrementVersion(current.identity.version);
  
  const updated = deepMerge(current, updates);
  updated.identity.version = version;
  updated.identity.lastUpdated = new Date().toISOString();
  
  // Add to evolution history
  updated.evolution.history.push({
    version,
    date: new Date().toISOString(),
    changes: describeChanges(current, updates),
    rationale
  });
  
  await memory.set(`brands.${brandId}`, updated);
  
  // Notify systems of brand update
  await notifyBrandUpdate(brandId, updates);
  
  return updated;
};
```

## Brand Enforcement

### Compliance Checking
```javascript
const checkCompliance = {
  automated: async (design) => {
    const activeBrand = await getActiveBrand();
    
    const checks = {
      colors: await validateColors(design, activeBrand.visual.colors),
      typography: await validateTypography(design, activeBrand.visual.typography),
      spacing: await validateSpacing(design, activeBrand.visual),
      logos: await validateLogoUsage(design, activeBrand.visual.logo)
    };
    
    const score = calculateComplianceScore(checks);
    const issues = extractIssues(checks);
    
    return {
      score,
      passed: score >= 90,
      issues,
      recommendations: generateFixes(issues)
    };
  },
  
  manual: async (review) => {
    const checkpoint = {
      date: new Date().toISOString(),
      reviewer: review.reviewer,
      score: review.score,
      issues: review.issues,
      actions: review.recommendedActions
    };
    
    await memory.append('compliance.checkpoints', checkpoint);
    
    if (review.score < 80) {
      await triggerComplianceAlert(checkpoint);
    }
    
    return checkpoint;
  }
};
```

### Brand Application
```javascript
const applyBrand = {
  toComponent: async (component, brandId) => {
    const brand = await memory.get(`brands.${brandId || 'activeBrand'}`);
    
    return {
      ...component,
      styles: {
        colors: mapToBrandColors(component.styles, brand.visual.colors),
        typography: applyBrandTypography(component.styles, brand.visual.typography),
        spacing: alignToBrandGrid(component.styles, brand.visual)
      },
      attributes: {
        ...component.attributes,
        'data-brand': brand.identity.name,
        'data-brand-version': brand.identity.version
      }
    };
  },
  
  toContent: async (content, context) => {
    const brand = await getActiveBrand();
    const tone = brand.voice.tone[context] || brand.voice.tone.default;
    
    return {
      text: applyVoiceAndTone(content.text, brand.voice, tone),
      formatting: applyBrandFormatting(content, brand)
    };
  }
};
```

## Brand Intelligence

### Usage Analytics
```javascript
const brandAnalytics = {
  trackUsage: async (element, context) => {
    const usage = {
      element,
      context,
      timestamp: new Date().toISOString(),
      brand: await memory.get('activeBrand'),
      compliant: await quickComplianceCheck(element)
    };
    
    await memory.append('analytics.usage', usage);
    
    // Learn from usage patterns
    if (usage.compliant) {
      await reinforcePattern(element);
    } else {
      await flagForReview(element, context);
    }
  },
  
  generateReport: async (period) => {
    const usage = await memory.get('analytics.usage');
    const filtered = filterByPeriod(usage, period);
    
    return {
      totalUsage: filtered.length,
      complianceRate: calculateComplianceRate(filtered),
      commonViolations: identifyCommonViolations(filtered),
      recommendations: generateRecommendations(filtered)
    };
  }
};
```

### Multi-Brand Support
```javascript
const multiBrand = {
  switchBrand: async (brandId) => {
    const exists = await memory.get(`brands.${brandId}`);
    if (!exists) {
      throw new Error(`Brand ${brandId} not found`);
    }
    
    await memory.set('activeBrand', brandId);
    await clearBrandCache();
    await notifyBrandSwitch(brandId);
    
    return exists;
  },
  
  compareBrands: async (brandIds) => {
    const brands = await Promise.all(
      brandIds.map(id => memory.get(`brands.${id}`))
    );
    
    return {
      similarities: findSimilarities(brands),
      differences: highlightDifferences(brands),
      consolidationOpportunities: suggestConsolidation(brands)
    };
  }
};
```

## Query Interface

### Common Queries
```javascript
// Get active brand colors
memory.get('brands.[activeBrand].visual.colors');

// Find all brands using specific color
memory.query('brands.*.visual.colors.primary', { 
  'hex': '#0066FF' 
});

// Get brand evolution history
memory.get('brands.brand_001.evolution.history');

// Check compliance score trend
memory.aggregate('compliance.checkpoints', {
  groupBy: 'month',
  calculate: 'average',
  field: 'score'
});
```

## Maintenance

### Brand Archival
```javascript
const archiveBrand = async (brandId, reason) => {
  const brand = await memory.get(`brands.${brandId}`);
  
  // Move to archive
  await memory.set(`archive.brands.${brandId}`, {
    ...brand,
    archivedDate: new Date().toISOString(),
    archivedReason: reason
  });
  
  // Remove from active brands
  await memory.delete(`brands.${brandId}`);
  
  // Update active brand if necessary
  if (await memory.get('activeBrand') === brandId) {
    const remainingBrands = await memory.get('brands');
    const newActive = Object.keys(remainingBrands)[0];
    await memory.set('activeBrand', newActive || null);
  }
};
```

---

*Brand Guidelines Memory v1.0 | Brand identity storage | Compliance tracking*