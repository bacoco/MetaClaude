# Reasoning Patterns

Explicit metacognitive directives to guide Claude's internal thought processes during UI/UX design tasks.

## Overview

This pattern provides structured reasoning frameworks that Claude should follow internally when processing design requests. These directives make thinking more explicit, systematic, and consistent.

## Core Reasoning Framework

### The PASE Method (Ponder → Analyze → Synthesize → Execute)

**Complexity Rating**: Moderate to Complex (Best for scores 12-20)
**Combination Compatibility**: Works well with all specialist patterns as an overarching framework
**Adaptation Hooks**: Can be shortened (AS-E) for simple tasks or expanded (P-A-S-E-R: +Reflect) for complex ones

```
1. PONDER: First, deeply consider the request
   - What is the user really asking for?
   - What are the implicit needs beyond the explicit request?
   - What context or constraints should influence the approach?
   [Adaptation Hook: Skip for routine tasks, extend for novel challenges]

2. ANALYZE: Then, break down the components
   - What are the key elements to address?
   - What patterns or precedents apply?
   - What are the potential challenges or conflicts?
   [Adaptation Hook: Parallelize with specialist patterns for efficiency]

3. SYNTHESIZE: Next, combine insights into a solution
   - How do the elements work together?
   - What's the optimal approach given all factors?
   - What trade-offs am I making and why?
   [Adaptation Hook: Iterate if initial synthesis reveals new complexities]

4. EXECUTE: Finally, implement with confidence
   - Apply the synthesized solution
   - Maintain consistency throughout
   - Validate against original goals
   [Adaptation Hook: Add reflection loop for learning]
```

## Specialist-Specific Reasoning Patterns

### Design Analyst Reasoning

**Complexity Rating**: Simple to Moderate (Best for scores 6-15)
**Combination Compatibility**: Pairs well with Style Guide Expert, feeds into UI Generator
**Adaptation Hooks**: Can add depth analysis for complex systems, or quick scan for simple reviews

```
When analyzing designs, I must:

1. *OBSERVE* without judgment
   - "I see [specific visual elements]"
   - "I notice [patterns and relationships]"
   - "I detect [emotional qualities]"
   [Adaptation Hook: Add quantitative analysis for data-driven insights]

2. *EXTRACT* underlying principles
   - "This suggests [design principle]"
   - "The pattern indicates [intent]"
   - "The consistency reveals [system]"
   [Adaptation Hook: Cross-reference with design trends for context]

3. *SYNTHESIZE* into actionable tokens
   - "Therefore, the color system is..."
   - "This translates to spacing of..."
   - "The resulting tokens should be..."
   [Adaptation Hook: Generate multiple token variations for A/B testing]
```

### UI Generator Reasoning

**Complexity Rating**: Moderate (Best for scores 8-18)
**Combination Compatibility**: Follows Design Analyst, works with UX Researcher insights
**Adaptation Hooks**: Scale variations from 3 to 10+ for complex projects

```
When creating interfaces, I must:

1. *CONSIDER* the user's journey
   - "The user needs to [primary goal]"
   - "They might struggle with [pain point]"
   - "Success looks like [outcome]"
   [Adaptation Hook: Add persona-specific variations for targeted design]

2. *EXPLORE* multiple approaches
   - "Option A emphasizes [quality]"
   - "Option B prioritizes [different quality]"
   - "Option C takes a [different angle]"
   [Adaptation Hook: Generate 5-10 options for complex explorations]

3. *REFINE* based on constraints
   - "Given the brand guidelines..."
   - "Considering accessibility requirements..."
   - "Within technical limitations..."
   [Adaptation Hook: Add performance optimization for high-traffic interfaces]
```

### Style Guide Expert Reasoning

**Complexity Rating**: Moderate to Complex (Best for scores 10-20)
**Combination Compatibility**: Essential foundation for all other patterns
**Adaptation Hooks**: Simplify for MVPs, expand for enterprise systems

```
When building design systems, I must:

1. *ESTABLISH* foundational principles
   - "The core design values are..."
   - "The system must scale to..."
   - "Consistency means..."
   [Adaptation Hook: Add brand evolution considerations for long-term thinking]

2. *STRUCTURE* systematic relationships
   - "Colors relate through..."
   - "Typography scales by..."
   - "Spacing follows..."
   [Adaptation Hook: Include mathematical ratios for precise systems]

3. *DOCUMENT* with clarity
   - "Developers need to know..."
   - "Designers should understand..."
   - "The rationale is..."
   [Adaptation Hook: Generate interactive documentation for complex systems]
```

### UX Researcher Reasoning

**Complexity Rating**: Simple to Complex (Best for scores 5-20)
**Combination Compatibility**: Feeds all other patterns, especially UI Generator
**Adaptation Hooks**: Quick assumptions for MVPs, deep research for critical products

```
When understanding users, I must:

1. *EMPATHIZE* with their situation
   - "From their perspective..."
   - "Their frustrations stem from..."
   - "They're trying to accomplish..."
   [Adaptation Hook: Add quantitative data analysis for data-driven insights]

2. *IDENTIFY* patterns and insights
   - "Across users, I see..."
   - "The common thread is..."
   - "This behavior suggests..."
   [Adaptation Hook: Segment by user types for nuanced understanding]

3. *TRANSLATE* into design decisions
   - "This means we should..."
   - "To address this, the design..."
   - "The implication for UI is..."
   [Adaptation Hook: Create decision matrices for complex trade-offs]
```

### Brand Strategist Reasoning

**Complexity Rating**: Moderate to Complex (Best for scores 12-22)
**Combination Compatibility**: Sets foundation for Design Analyst and Style Guide Expert
**Adaptation Hooks**: Quick positioning for startups, deep strategy for rebrands

```
When developing brand identity, I must:

1. *UNDERSTAND* the essence
   - "At its core, this brand is..."
   - "The emotional truth is..."
   - "The differentiation lies in..."
   [Adaptation Hook: Add competitive analysis for market positioning]

2. *IMAGINE* the expression
   - "This could manifest as..."
   - "Visually, this means..."
   - "The voice would sound like..."
   [Adaptation Hook: Create mood board variations for exploration]

3. *ALIGN* with business goals
   - "This supports the mission by..."
   - "It differentiates because..."
   - "Success metrics would be..."
   [Adaptation Hook: Develop measurement frameworks for brand tracking]
```

### Accessibility Auditor Reasoning

**Complexity Rating**: Simple to Moderate (Best for scores 6-16)
**Combination Compatibility**: Must integrate with all patterns, especially UI Generator
**Adaptation Hooks**: Quick fixes for compliance, comprehensive redesign for inclusion

```
When ensuring inclusion, I must:

1. *EVALUATE* against standards
   - "WCAG requires..."
   - "This falls short because..."
   - "The impact on users is..."
   [Adaptation Hook: Add assistive technology testing for thorough validation]

2. *PRIORITIZE* by severity
   - "Critical issues that block..."
   - "Important problems that hinder..."
   - "Enhancements that improve..."
   [Adaptation Hook: Create user impact scores for better prioritization]

3. *RECOMMEND* practical solutions
   - "The minimal fix is..."
   - "The ideal solution would..."
   - "Implementation steps are..."
   [Adaptation Hook: Provide multiple solution paths based on resources]
```

## Complex Task Reasoning

### For Multi-Step Projects

```
Before beginning a complex project:

1. *MAP* the entire journey
   - "The full scope includes..."
   - "Dependencies are..."
   - "Critical path is..."

2. *SEQUENCE* the activities
   - "First, I must..."
   - "Only then can I..."
   - "Finally, I'll..."

3. *ANTICIPATE* challenges
   - "Potential blockers..."
   - "If X happens, then..."
   - "Fallback plan is..."
```

### For Ambiguous Requests

```
When facing uncertainty:

1. *IDENTIFY* what's unclear
   - "I'm unsure about..."
   - "Multiple interpretations include..."
   - "Key missing information is..."

2. *HYPOTHESIZE* likely intent
   - "Based on context, probably..."
   - "Similar requests usually mean..."
   - "The goal seems to be..."

3. *CLARIFY* proactively
   - "To ensure success, I need..."
   - "Would you prefer X or Y?"
   - "I'm assuming Z, correct?"
```

## Quality Reasoning Patterns

### Before Presenting Solutions

```
Final quality check:

1. *VERIFY* against requirements
   - "Original request was..."
   - "I've addressed by..."
   - "Success criteria met: [checklist]"

2. *VALIDATE* design decisions
   - "I chose X because..."
   - "Alternative Y was rejected due to..."
   - "This optimizes for..."

3. *POLISH* the presentation
   - "Key points to highlight..."
   - "Potential concerns to address..."
   - "Next steps would be..."
```

### After Receiving Feedback

```
Processing user response:

1. *UNDERSTAND* the feedback
   - "They're saying..."
   - "The underlying concern is..."
   - "This suggests they value..."

2. *INTEGRATE* with previous work
   - "This changes my approach to..."
   - "I should preserve..."
   - "New priority is..."

3. *ITERATE* thoughtfully
   - "Specific improvements..."
   - "While maintaining..."
   - "Better achieving..."
```

## Metacognitive Triggers

### When to Engage Deep Reasoning

Use explicit reasoning when:
- **Complexity is high**: Multiple interrelated components
- **Stakes are significant**: Major design decisions
- **Ambiguity exists**: Unclear requirements
- **Innovation needed**: Novel solutions required
- **Learning opportunity**: New patterns to establish

### Reasoning Depth Levels

```
LEVEL 1 - Quick Assessment (< 30 seconds)
"At a glance, this needs..."

LEVEL 2 - Structured Analysis (2-5 minutes)
"Pondering the implications..."
"Analyzing the components..."

LEVEL 3 - Deep Synthesis (5-10 minutes)
"Pontificating on the possibilities..."
"Synthesizing a comprehensive approach..."
```

## Self-Correction Patterns

### Catching Errors

```
Mid-process checks:

1. *PAUSE* and reflect
   - "Am I solving the right problem?"
   - "Have I missed something important?"
   - "Is there a simpler approach?"

2. *ADJUST* if needed
   - "Actually, I should reconsider..."
   - "A better approach would be..."
   - "Let me revise that..."
```

### Learning from Mistakes

```
When things don't work:

1. *ACKNOWLEDGE* honestly
   - "This approach didn't work because..."
   - "I overlooked..."
   - "The assumption that failed was..."

2. *LEARN* for next time
   - "Next time I'll check..."
   - "This teaches me..."
   - "The pattern to remember is..."
```

## Integration with Other Patterns

### With Memory Operations
```
"*Pondering* stored preferences, I recall that..."
"*Analyzing* project history reveals..."
"*Synthesizing* new insights with existing knowledge..."
```

### With Tool Usage
```
"*Considering* the need for persistence, I *must* use write_file..."
"*Analyzing* existing code requires I *must* first read_file..."
```

### With Feedback Processing
```
"*Pondering* this feedback in context..."
"*Analyzing* the emotional tone suggests..."
"*Synthesizing* a response that addresses..."
```

## Dynamic Pattern Selection Integration

### With Reasoning Selector
This file integrates with `reasoning-selector.md` for dynamic adaptation:

```
*Meta-reasoning: Analyzing task complexity...*
- Complexity Score: [calculated score]
- Selected Pattern: [chosen based on analysis]
- Adaptation: [specific modifications for this task]
```

### Pattern Performance Metrics
Each pattern now includes metrics for optimization:

| Pattern | Best Complexity Range | Success Rate | Combination Potential |
|---------|----------------------|--------------|----------------------|
| PASE | 12-20 | High | Universal |
| OBSERVE-EXTRACT-SYNTHESIZE | 6-15 | High | Design-focused |
| CONSIDER-EXPLORE-REFINE | 8-18 | High | Creation-focused |
| EMPATHIZE-IDENTIFY-TRANSLATE | 5-20 | High | Research-focused |
| UNDERSTAND-IMAGINE-ALIGN | 12-22 | Medium | Strategy-focused |
| EVALUATE-PRIORITIZE-RECOMMEND | 6-16 | High | Audit-focused |

### Adaptive Execution Examples

**Simple Task (Score: 7)**
```
*Meta-reasoning: Simple component request detected*
Using: CONSIDER-EXPLORE-REFINE (streamlined version)
- Skip deep pondering
- Generate 3 quick variations
- Apply standard patterns
```

**Complex Task (Score: 18)**
```
*Meta-reasoning: Multi-system integration detected*
Combining patterns:
1. EMPATHIZE-IDENTIFY-TRANSLATE (user needs)
2. PASE (overall framework)
3. OBSERVE-EXTRACT-SYNTHESIZE (pattern analysis)
With iteration loops between phases
```

---

*Reasoning Patterns v2.0 | Enhanced with dynamic selection and adaptation capabilities*