# Clarification Templates Pattern

Specialist-specific templates for seeking clarification when user requirements are ambiguous or incomplete.

## Overview

This pattern provides structured question templates for each specialist role, ensuring Claude asks the right questions at the right time to deliver optimal design solutions.

## General Clarification Principles

1. **Be Specific**: Ask about concrete details, not abstract concepts
2. **Offer Options**: Provide examples to help users articulate preferences
3. **Stay Relevant**: Only ask questions pertinent to the current task
4. **Batch Questions**: Group related clarifications to minimize back-and-forth
5. **Provide Context**: Explain why the information matters

## Specialist-Specific Templates

### Design Analyst Clarifications

**When analyzing inspiration sources:**
```
"To extract the most relevant design DNA, I need to understand:

1. **Context**: What aspects of these designs appeal to you most?
   - Color palette and mood
   - Layout and structure  
   - Typography and hierarchy
   - Interactive elements
   - Overall feeling

2. **Application**: How will we apply these inspirations?
   - Direct adaptation (stay very close)
   - Loose inspiration (general direction)
   - Selective elements (specific features)

3. **Constraints**: Any elements we should avoid?
   - Colors that conflict with brand
   - Styles that don't fit audience
   - Patterns that won't scale"
```

**When patterns are unclear:**
```
"I see multiple design directions in your inspiration. To focus my analysis:

- Which example best represents your ideal outcome?
- Are there specific elements from each we should combine?
- What's the primary emotion you want to convey?"
```

### Style Guide Expert Clarifications

**When creating design systems:**
```
"To build an effective design system, I need clarity on:

1. **Scale & Scope**:
   - Single product or multi-product system?
   - Web only, mobile only, or cross-platform?
   - How many designers/developers will use this?

2. **Technical Context**:
   - Existing framework (React, Vue, vanilla)?
   - CSS approach (Tailwind, CSS-in-JS, Sass)?
   - Build tools and deployment process?

3. **Flexibility Needs**:
   - Strict consistency or creative freedom?
   - How often will the system evolve?
   - Theming/white-label requirements?"
```

**When tokens are ambiguous:**
```
"For your design tokens, please specify:

- **Colors**: Do you have existing brand colors? RGB/HEX values?
- **Typography**: Preferred fonts or categories (serif, sans-serif)?
- **Spacing**: Comfortable with 8px grid or prefer different base?"
```

### UI Generator Clarifications

**When requirements are vague:**
```
"To create the perfect UI for your needs:

1. **Functionality**:
   - What actions can users take here?
   - What information must be displayed?
   - Any specific interactions needed?

2. **Style Direction**:
   - Modern & minimal
   - Rich & detailed
   - Playful & bold
   - Professional & conservative
   - Custom (describe)

3. **Technical Requirements**:
   - Responsive breakpoints needed?
   - Dark mode support?
   - Animation preferences?
   - Loading states required?"
```

**When creating variations:**
```
"For the variations you'd like to see:

- How different should they be? (subtle vs dramatic)
- Any specific directions to explore?
- Preferences to definitely include/avoid?"
```

### UX Researcher Clarifications

**When defining user personas:**
```
"To create accurate user personas, please share:

1. **Target Audience**:
   - Primary user demographics?
   - Professional or consumer focus?
   - Technical skill level?

2. **User Context**:
   - Where/when do they use this?
   - What are they trying to accomplish?
   - What frustrates them currently?

3. **Business Goals**:
   - How do you measure success?
   - Key behaviors to encourage?
   - Conversion goals?"
```

**When mapping journeys:**
```
"For the user journey map:

- Starting point: How do users discover you?
- Key decisions: What choices do they face?
- Success metric: What's the ideal outcome?
- Current pain points: Where do users struggle?"
```

### Brand Strategist Clarifications

**When developing brand identity:**
```
"To craft a compelling brand strategy:

1. **Brand Foundation**:
   - What's your company's mission?
   - What makes you different?
   - Who are your main competitors?

2. **Personality & Voice**:
   - If your brand was a person, how would you describe them?
   - Formal or casual communication?
   - Serious or playful tone?

3. **Emotional Goals**:
   - How should people feel when they interact with your brand?
   - What perception do you want to create?
   - Any associations to avoid?"
```

**When visual direction is unclear:**
```
"For your brand's visual identity:

- Industry conventions to follow or break?
- Existing equity to preserve?
- Cultural considerations?
- Future flexibility needs?"
```

### Accessibility Auditor Clarifications

**When compliance level is unspecified:**
```
"For accessibility compliance:

1. **Required Level**:
   - WCAG A (minimum legal)
   - WCAG AA (standard recommendation)
   - WCAG AAA (maximum inclusion)
   - Custom requirements?

2. **User Needs**:
   - Known users with disabilities?
   - Assistive technologies in use?
   - Specific accommodations required?

3. **Technical Context**:
   - Existing codebase or new build?
   - Framework limitations?
   - Testing tools available?"
```

**When audit scope is unclear:**
```
"What should the accessibility audit cover?

- Full site/app review
- Specific user flows
- Component library audit
- New feature check
- Remediation priorities"
```

## Context-Aware Clarification

### Project Phase Templates

**During Discovery:**
```
"I'm in the discovery phase and need to understand:
- Your vision for this project
- Key constraints or requirements
- Success criteria
- Timeline expectations"
```

**During Design:**
```
"As I'm designing, I need clarification on:
- Specific functionality requirements
- Style preferences
- Content that will be included
- Technical constraints"
```

**During Iteration:**
```
"To refine this effectively:
- What specifically isn't working?
- Which elements do you like?
- How far should I push changes?
- Priority order for fixes?"
```

**During Handoff:**
```
"For smooth handoff:
- Who will implement this?
- What format do they need?
- Documentation requirements?
- Questions about feasibility?"
```

## Question Bundling Strategies

### Efficient Information Gathering

**Good (Bundled):**
```
"To move forward effectively, I need to clarify:

1. Target audience: Who is this for?
2. Visual style: Modern or traditional?
3. Key features: What must be included?
4. Timeline: When do you need this?

This helps me create the right solution first time."
```

**Avoid (Scattered):**
```
"Who is your target audience?"
[waits for response]
"What style do you prefer?"
[waits for response]
"What features do you need?"
[etc.]
```

## Decision Helper Templates

### When Users Are Unsure

**Style Decision Helper:**
```
"Let me help narrow down the style direction:

Option A: Clean & Minimal
- Lots of whitespace
- Simple color palette
- Focus on content

Option B: Rich & Engaging
- Visual interest
- Multiple colors
- Interactive elements

Option C: Bold & Modern
- Strong contrasts
- Cutting-edge feel
- Memorable design

Which direction feels right for your brand?"
```

**Feature Priority Helper:**
```
"Let's prioritize features for the MVP:

Must Have:
- [Feature 1]
- [Feature 2]

Nice to Have:
- [Feature 3]
- [Feature 4]

Future Consideration:
- [Feature 5]
- [Feature 6]

Does this align with your vision?"
```

## Fallback Templates

### When No Response

**Gentle Follow-up:**
```
"I want to ensure I create exactly what you need. 
Would you prefer I:

1. Make reasonable assumptions and show you options
2. Start with industry standards you can customize
3. Wait for specific direction

Just let me know how you'd like to proceed!"
```

**Moving Forward:**
```
"To keep momentum, I'll proceed with:
- Industry best practices
- Common patterns for your use case
- Assumptions I can revise later

I'll note where I've made assumptions so we can adjust as needed."
```

## Cultural Sensitivity

### International Projects
```
"For your global audience:
- Primary markets/languages?
- Cultural symbols to embrace/avoid?
- Local compliance requirements?
- Regional design preferences?"
```

### Inclusive Design
```
"To ensure inclusive design:
- Diversity representation needs?
- Language accessibility?
- Cultural color meanings?
- Iconography considerations?"
```

---

*Clarification Templates v1.0 | Specialist-specific question frameworks*