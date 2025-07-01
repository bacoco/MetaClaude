# Contextual Learning Pattern

Advanced context-aware preference learning system that prevents inappropriate generalization across unrelated contexts.

## Context Hierarchy Architecture

### Hierarchical Levels

```javascript
const contextHierarchy = {
  levels: {
    global: {
      scope: "Cross-project universals",
      inheritance: "None (root level)",
      examples: ["Accessibility standards", "Performance requirements"],
      persistence: "Permanent until explicitly changed"
    },
    
    project: {
      scope: "Single project boundaries",
      inheritance: "Inherits from global, overrides when specified",
      examples: ["Brand colors", "Design system", "Target audience"],
      persistence: "Project lifetime"
    },
    
    feature: {
      scope: "Specific feature or component type",
      inheritance: "Inherits from project, selective override",
      examples: ["Dashboard preferences", "Form styles", "Navigation patterns"],
      persistence: "Feature development cycle"
    },
    
    task: {
      scope: "Current working session",
      inheritance: "Inherits from feature, temporary overrides",
      examples: ["Current iteration preferences", "Active experiments"],
      persistence: "Session only"
    }
  },
  
  boundaries: {
    hard: ["Different projects", "Different user segments", "Different platforms"],
    soft: ["Component variations", "Time-based changes", "A/B testing"],
    permeable: ["Style refinements", "Incremental improvements", "Minor adjustments"]
  }
};
```

### Context Detection Engine

```javascript
const contextDetector = {
  analyze: (currentState) => {
    return {
      project: detectProject(currentState),
      feature: detectFeature(currentState),
      userSegment: detectUserSegment(currentState),
      platform: detectPlatform(currentState),
      designPhase: detectPhase(currentState),
      explicitContext: parseExplicitContext(currentState)
    };
  },
  
  signals: {
    project: {
      explicit: ["project name", "brand", "client", "app name"],
      implicit: ["file structure", "naming conventions", "technology stack"],
      environmental: ["directory path", "git repository", "config files"]
    },
    
    feature: {
      explicit: ["component name", "page type", "feature description"],
      implicit: ["UI patterns", "data types", "interaction models"],
      derived: ["parent components", "usage context", "dependencies"]
    },
    
    platform: {
      explicit: ["mobile", "desktop", "tablet", "watch"],
      implicit: ["viewport constraints", "interaction methods", "performance limits"],
      technical: ["framework limitations", "device capabilities", "OS conventions"]
    }
  },
  
  confidence: {
    calculate: (signals) => {
      const weights = {
        explicit: 0.9,
        implicit: 0.6,
        environmental: 0.7,
        derived: 0.5
      };
      
      return signals.reduce((confidence, signal) => {
        return confidence + (weights[signal.type] * signal.strength);
      }, 0) / signals.length;
    }
  }
};
```

## Preference Scoping Rules

### Scope Definition System

```javascript
const scopingRules = {
  preference_categories: {
    universal: {
      description: "Apply everywhere unless explicitly overridden",
      examples: ["Accessibility compliance", "Performance targets"],
      propagation: "Downward to all contexts",
      override_requirement: "Explicit contradiction"
    },
    
    contextual: {
      description: "Apply only within detected context boundaries",
      examples: ["Dashboard data density", "Landing page spaciousness"],
      propagation: "Limited to matching contexts",
      override_requirement: "Different context detection"
    },
    
    experimental: {
      description: "Apply only to current task/session",
      examples: ["Trying new color", "Testing layout variation"],
      propagation: "No propagation",
      override_requirement: "None - expires naturally"
    },
    
    excluded: {
      description: "Explicitly marked as non-generalizable",
      examples: ["One-off client request", "Temporary workaround"],
      propagation: "Never propagates",
      override_requirement: "Not applicable"
    }
  },
  
  boundary_enforcement: {
    strict: {
      trigger: "Context mismatch > 0.7",
      action: "Block preference application",
      example: "Dashboard density preference blocked from landing page"
    },
    
    flexible: {
      trigger: "Context similarity 0.3-0.7",
      action: "Apply with confidence penalty",
      example: "Button style preference applied tentatively to new component"
    },
    
    permissive: {
      trigger: "Context similarity > 0.7",
      action: "Apply with full confidence",
      example: "Color preference applied across similar marketing pages"
    }
  }
};
```

### Context Comparison Algorithm

```javascript
const contextComparison = {
  calculateSimilarity: (context1, context2) => {
    const dimensions = {
      project: {
        weight: 0.4,
        compare: (c1, c2) => {
          if (c1.project === c2.project) return 1.0;
          if (c1.client === c2.client) return 0.6;
          if (c1.industry === c2.industry) return 0.3;
          return 0.0;
        }
      },
      
      feature: {
        weight: 0.3,
        compare: (c1, c2) => {
          const typeMatch = c1.componentType === c2.componentType ? 0.8 : 0.0;
          const purposeMatch = calculatePurposeSimilarity(c1.purpose, c2.purpose);
          return (typeMatch + purposeMatch) / 2;
        }
      },
      
      audience: {
        weight: 0.2,
        compare: (c1, c2) => {
          const segmentMatch = c1.userSegment === c2.userSegment ? 1.0 : 0.2;
          const platformMatch = c1.platform === c2.platform ? 0.8 : 0.3;
          return (segmentMatch * 0.7 + platformMatch * 0.3);
        }
      },
      
      design_phase: {
        weight: 0.1,
        compare: (c1, c2) => {
          const phaseMap = {
            'exploration': ['exploration', 'ideation'],
            'refinement': ['refinement', 'iteration'],
            'production': ['production', 'final']
          };
          
          return phaseMap[c1.phase]?.includes(c2.phase) ? 0.8 : 0.2;
        }
      }
    };
    
    let similarity = 0;
    for (const [dim, config] of Object.entries(dimensions)) {
      similarity += config.weight * config.compare(context1, context2);
    }
    
    return {
      score: similarity,
      dimensions: Object.entries(dimensions).map(([name, config]) => ({
        name,
        score: config.compare(context1, context2),
        weight: config.weight
      }))
    };
  }
};
```

## Context Inheritance Patterns

### Inheritance Rules Engine

```javascript
const inheritanceEngine = {
  rules: {
    direct_inheritance: {
      condition: "Child context has no specific preference",
      action: "Inherit from immediate parent",
      example: "Feature inherits project's color scheme"
    },
    
    selective_inheritance: {
      condition: "Child context has partial preferences",
      action: "Merge with parent, child takes precedence",
      example: "Dashboard keeps brand colors but overrides spacing"
    },
    
    blocked_inheritance: {
      condition: "Child context explicitly blocks inheritance",
      action: "Use only child context preferences",
      example: "Email template ignores website styling"
    },
    
    conditional_inheritance: {
      condition: "Inheritance depends on similarity threshold",
      action: "Apply parent preferences based on context match",
      example: "Marketing pages inherit from each other but not from app"
    }
  },
  
  merging_strategy: {
    cascade: (contexts) => {
      // Start with global, overlay each level
      let merged = {...contexts.global};
      
      if (contexts.project) {
        merged = mergeWithStrategy(merged, contexts.project, 'overlay');
      }
      
      if (contexts.feature) {
        merged = mergeWithStrategy(merged, contexts.feature, 'selective');
      }
      
      if (contexts.task) {
        merged = mergeWithStrategy(merged, contexts.task, 'override');
      }
      
      return merged;
    },
    
    strategies: {
      overlay: "Child completely replaces parent values",
      selective: "Child replaces only specified values",
      override: "Child temporarily overrides without persistence",
      blend: "Weighted combination of parent and child"
    }
  }
};
```

### Smart Inheritance Examples

```javascript
const inheritanceExamples = {
  appropriate_inheritance: {
    scenario: "E-commerce project with multiple page types",
    contexts: {
      project: {
        name: "ShopFlow",
        preferences: {
          colors: { primary: "#2C3E50", secondary: "#E74C3C" },
          typography: { heading: "Montserrat", body: "Open Sans" },
          spacing: { unit: 8, scale: 1.25 }
        }
      },
      
      feature_product_page: {
        inherits: ["colors", "typography"],
        overrides: {
          spacing: { unit: 8, scale: 1.5 }, // More spacious
          layout: "image-focused"
        }
      },
      
      feature_checkout: {
        inherits: ["colors", "typography"],
        overrides: {
          spacing: { unit: 8, scale: 1.0 }, // More compact
          layout: "form-focused"
        }
      }
    }
  },
  
  prevented_inheritance: {
    scenario: "Marketing site vs Application dashboard",
    contexts: {
      marketing_site: {
        preferences: {
          density: "spacious",
          imagery: "hero-focused",
          animations: "elaborate"
        }
      },
      
      app_dashboard: {
        preferences: {
          density: "compact",
          imagery: "data-focused",
          animations: "subtle"
        },
        inheritance_block: ["density", "imagery", "animations"]
      }
    },
    
    result: "Dashboard preferences don't inherit marketing site patterns"
  }
};
```

## Safeguards Against Over-Generalization

### Generalization Prevention System

```javascript
const generalizationSafeguards = {
  detection_mechanisms: {
    context_boundary_detection: {
      method: "Monitor context switches",
      triggers: [
        "Project name change",
        "Directory structure change",
        "Technology stack change",
        "User segment change"
      ],
      action: "Reset confidence scores, require reconfirmation"
    },
    
    preference_conflict_detection: {
      method: "Compare new preferences with existing",
      triggers: [
        "Contradictory preferences in similar contexts",
        "Rapid preference changes",
        "Context-specific corrections"
      ],
      action: "Increase context specificity requirements"
    },
    
    statistical_anomaly_detection: {
      method: "Track preference application success rate",
      triggers: [
        "Success rate < 70% in new context",
        "Multiple corrections required",
        "User frustration signals"
      ],
      action: "Quarantine preference to original context"
    }
  },
  
  prevention_strategies: {
    confidence_decay: {
      description: "Reduce confidence when crossing context boundaries",
      formula: (baseConfidence, contextSimilarity) => {
        return baseConfidence * Math.pow(contextSimilarity, 2);
      },
      example: "0.9 confidence * 0.5 similarity² = 0.225 confidence"
    },
    
    explicit_confirmation: {
      description: "Require confirmation for cross-context application",
      threshold: 0.5,
      prompt: "I notice you preferred X in context Y. Should I apply this here too?"
    },
    
    contextual_quarantine: {
      description: "Limit preference to specific contexts initially",
      duration: "Until 3 successful applications in different contexts",
      expansion_criteria: "User confirmation or implicit acceptance"
    }
  }
};
```

### Context Bleeding Prevention

```javascript
const bleedingPrevention = {
  isolation_mechanisms: {
    namespace_isolation: {
      implementation: "Prefix preferences with context path",
      example: "dashboard.navigation.density vs landing.hero.density",
      benefit: "Clear separation of unrelated preferences"
    },
    
    similarity_threshold: {
      implementation: "Require minimum context match for preference sharing",
      threshold: 0.7,
      calculation: "weighted_context_similarity(source, target)",
      benefit: "Prevents unrelated contexts from sharing preferences"
    },
    
    explicit_boundaries: {
      implementation: "User-defined context boundaries",
      examples: [
        "BOUNDARY: marketing_site | application",
        "BOUNDARY: consumer_facing | internal_tools",
        "BOUNDARY: mobile_app | desktop_app"
      ],
      benefit: "Absolute prevention of cross-boundary bleeding"
    }
  },
  
  recovery_mechanisms: {
    preference_rollback: {
      trigger: "Multiple corrections in new context",
      action: "Revert to context-free state",
      user_signal: "Subtle acknowledgment of context difference"
    },
    
    context_clarification: {
      trigger: "Ambiguous context detection",
      action: "Request minimal context clarification",
      example: "Is this for the marketing site or the application?"
    },
    
    learning_reset: {
      trigger: "User explicitly states context change",
      action: "Clear inappropriate preferences",
      example: "Now working on mobile app → clear desktop preferences"
    }
  }
};
```

## Integration with Feedback Automation

### Feedback Context Enrichment

```javascript
const feedbackContextIntegration = {
  enrich_feedback: (feedback, currentContext) => {
    return {
      ...feedback,
      context: {
        hierarchy: detectContextHierarchy(currentContext),
        confidence: calculateContextConfidence(currentContext),
        boundaries: identifyNearestBoundaries(currentContext),
        inheritance_chain: buildInheritanceChain(currentContext)
      },
      
      application_scope: determineScope(feedback, currentContext),
      
      propagation_rules: {
        can_propagate_to: calculatePropagationTargets(feedback, currentContext),
        blocked_contexts: identifyBlockedContexts(feedback, currentContext),
        confidence_modifiers: computeConfidenceModifiers(feedback, currentContext)
      }
    };
  },
  
  modify_learning_behavior: (feedbackProcessor, contextEngine) => {
    feedbackProcessor.beforeStore = (feedback) => {
      const enriched = contextEngine.enrich(feedback);
      
      // Modify storage based on context
      if (enriched.application_scope === 'contextual') {
        feedback.storage_key = `${enriched.context.path}.${feedback.preference_type}`;
      }
      
      return enriched;
    };
    
    feedbackProcessor.beforeApply = (preference, targetContext) => {
      const similarity = contextEngine.compare(preference.source_context, targetContext);
      
      if (similarity.score < contextEngine.threshold) {
        return null; // Don't apply
      }
      
      return {
        ...preference,
        confidence: preference.confidence * similarity.score
      };
    };
  }
};
```

### Contextual Memory Updates

```javascript
const contextualMemoryIntegration = {
  update_patterns: {
    scoped_update: {
      trigger: "Feedback with clear context",
      action: (feedback, context) => {
        const memoryPath = buildContextualPath(context);
        const scopedPreference = {
          ...feedback.preference,
          context: context,
          scope: determineScopeFromContext(context),
          inheritance: determineInheritanceRules(context)
        };
        
        updateMemoryAtPath(memoryPath, scopedPreference);
      }
    },
    
    hierarchical_update: {
      trigger: "Preference confirmed across multiple contexts",
      action: (preference, contexts) => {
        const commonAncestor = findCommonAncestor(contexts);
        const generalizedPreference = {
          ...preference,
          scope: commonAncestor.level,
          confirmed_contexts: contexts,
          confidence: calculateGeneralizationConfidence(contexts)
        };
        
        promoteToHigherScope(generalizedPreference, commonAncestor);
      }
    }
  },
  
  memory_structure: {
    contextual_preferences: {
      global: {
        accessibility: { high_contrast: true, min_font_size: 16 },
        performance: { max_bundle_size: "500kb", lazy_load_images: true }
      },
      
      projects: {
        "ecommerce_site": {
          inherits: ["global"],
          overrides: {
            brand: { colors: {...}, typography: {...} },
            patterns: { product_cards: {...}, checkout_flow: {...} }
          },
          
          features: {
            "product_listing": {
              density: "compact",
              grid_columns: { desktop: 4, tablet: 3, mobile: 2 }
            },
            "checkout": {
              density: "comfortable",
              progressive_disclosure: true
            }
          }
        }
      }
    }
  }
};
```

## Practical Examples

### Example 1: Dashboard vs Landing Page

```javascript
const dashboardVsLandingExample = {
  scenario: "User working on analytics dashboard, then switches to marketing landing page",
  
  contexts: {
    dashboard: {
      type: "application_interface",
      audience: "internal_users",
      purpose: "data_visualization",
      learned_preferences: {
        density: "high",
        color_usage: "categorical_distinction",
        spacing: "compact",
        typography: "data_optimized"
      }
    },
    
    landing_page: {
      type: "marketing_interface",
      audience: "potential_customers",
      purpose: "conversion",
      learned_preferences: {
        density: "low",
        color_usage: "brand_emphasis",
        spacing: "generous",
        typography: "readable_emotional"
      }
    }
  },
  
  prevention_mechanism: {
    context_switch_detection: "Identified major context change",
    similarity_score: 0.15, // Very low
    action_taken: "Blocked dashboard preferences from applying",
    result: "Landing page uses appropriate marketing-focused defaults"
  }
};
```

### Example 2: Mobile vs Desktop Preferences

```javascript
const platformContextExample = {
  scenario: "Responsive design with platform-specific preferences",
  
  preference_learning: {
    mobile_context: {
      detected_via: ["viewport_width", "touch_events", "device_type"],
      preferences: {
        navigation: "bottom_tabs",
        interaction: "swipe_gestures",
        information_density: "progressive_disclosure"
      }
    },
    
    desktop_context: {
      detected_via: ["viewport_width", "mouse_events", "device_type"],
      preferences: {
        navigation: "sidebar_menu",
        interaction: "hover_states",
        information_density: "comprehensive_display"
      }
    }
  },
  
  inheritance_blocked: [
    "navigation_pattern",
    "interaction_model",
    "density_preferences"
  ],
  
  inheritance_allowed: [
    "brand_colors",
    "typography_scale",
    "content_tone"
  ]
};
```

### Example 3: Feature Evolution

```javascript
const featureEvolutionExample = {
  scenario: "E-commerce site adding new features over time",
  
  evolution_path: {
    phase1: {
      context: "product_catalog",
      learned: { card_style: "minimal", grid_density: "comfortable" }
    },
    
    phase2: {
      context: "shopping_cart",
      attempted_inheritance: ["card_style", "grid_density"],
      result: {
        card_style: "inherited_with_modification",
        grid_density: "rejected_used_compact_instead"
      }
    },
    
    phase3: {
      context: "user_wishlist",
      smart_inheritance: {
        recognized_similarity_to: "product_catalog",
        similarity_score: 0.85,
        inherited: ["card_style", "grid_density"],
        confidence: 0.85 * 0.9 // similarity * original_confidence
      }
    }
  }
};
```

## Context Boundary Detection

### Boundary Types and Detection

```javascript
const boundaryDetection = {
  boundary_types: {
    hard_boundaries: {
      definition: "Absolute context separation",
      examples: [
        "Different client projects",
        "B2B vs B2C applications",
        "Marketing site vs SaaS application"
      ],
      detection_signals: [
        "Different repository",
        "Different brand guidelines",
        "Different target audience",
        "Different business goals"
      ],
      enforcement: "Complete preference isolation"
    },
    
    soft_boundaries: {
      definition: "Partial context separation",
      examples: [
        "Different features in same app",
        "Different user roles",
        "Different device types"
      ],
      detection_signals: [
        "Different URL patterns",
        "Different component hierarchies",
        "Different data types",
        "Different interaction patterns"
      ],
      enforcement: "Selective preference inheritance"
    },
    
    permeable_boundaries: {
      definition: "Minimal context separation",
      examples: [
        "Different pages of same type",
        "Variations of same component",
        "Different states of same feature"
      ],
      detection_signals: [
        "Similar component structure",
        "Same design system",
        "Same user flow",
        "Minor variations only"
      ],
      enforcement: "Full preference inheritance with confidence adjustment"
    }
  },
  
  detection_algorithm: {
    analyze_transition: (fromContext, toContext) => {
      const signals = {
        structural: compareStructure(fromContext, toContext),
        semantic: comparePurpose(fromContext, toContext),
        visual: compareDesignLanguage(fromContext, toContext),
        technical: compareTechStack(fromContext, toContext)
      };
      
      const boundaryStrength = calculateBoundaryStrength(signals);
      
      return {
        type: categorizeBoundary(boundaryStrength),
        confidence: boundaryStrength.confidence,
        reasoning: explainBoundaryDetection(signals),
        recommendation: suggestPreferenceHandling(boundaryStrength)
      };
    }
  }
};
```

## Performance Optimization

### Efficient Context Tracking

```javascript
const contextPerformance = {
  caching_strategy: {
    context_cache: new Map(), // LRU cache for context calculations
    similarity_cache: new Map(), // Cache context comparisons
    inheritance_cache: new Map(), // Cache inheritance chains
    
    cache_invalidation: {
      triggers: ["context_update", "preference_change", "time_based"],
      strategy: "selective_invalidation",
      ttl: 3600000 // 1 hour
    }
  },
  
  lazy_evaluation: {
    context_detection: "Only when needed for preference application",
    similarity_calculation: "Only when crossing potential boundaries",
    inheritance_resolution: "Only when accessing preferences"
  },
  
  batch_operations: {
    preference_application: "Group similar contexts for bulk application",
    context_analysis: "Analyze multiple signals simultaneously",
    memory_updates: "Batch write context-scoped preferences"
  }
};
```

## Integration Points

### System-Wide Integration

```javascript
const systemIntegration = {
  with_feedback_automation: {
    before_processing: enrichWithContext,
    during_categorization: applyScopingRules,
    before_storage: determineContextualPath,
    during_application: checkContextBoundaries
  },
  
  with_memory_operations: {
    structure: "Hierarchical context-aware storage",
    retrieval: "Context-filtered preference lookup",
    updates: "Scoped memory modifications"
  },
  
  with_reasoning_patterns: {
    context_aware_reasoning: "Select patterns based on context",
    preference_informed_logic: "Adjust reasoning for learned preferences"
  },
  
  with_tool_usage: {
    context_based_tool_selection: "Choose tools appropriate for context",
    preference_based_parameters: "Adjust tool parameters per context"
  }
};
```

---

*Contextual Learning v1.0 | Context-aware preference system | Prevents over-generalization*