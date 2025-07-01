# Getting Started with MetaClaude

## What is MetaClaude?

MetaClaude is a cognitive framework that enhances Claude with:
- Self-aware reasoning patterns
- Multi-agent orchestration
- Adaptive learning capabilities
- Domain-specific implementations

## Quick Start

### Using the UI Designer Implementation

The UI Designer is currently the primary implementation available. To use it:

```
"I want to create a modern dashboard design using the UI Designer implementation"
```

Or simply:

```
"Design a mobile app for task management"
```

MetaClaude will automatically engage the UI Designer implementation.

### Key Commands

#### Design Workflows
- `"Run a design sprint for [product]"` - 5-day rapid design process
- `"Create a complete UI project for [product]"` - Full 7-week process
- `"Generate an MVP design for [idea]"` - Quick 72-hour MVP

#### Specific Tasks
- `"Extract design DNA from [inspiration source]"` - Analyze visual patterns
- `"Create UI variations for [screen/feature]"` - Generate multiple options
- `"Audit accessibility for [design]"` - Check WCAG compliance
- `"Develop brand identity for [company]"` - Complete brand strategy

## Understanding the Architecture

### Cognitive Patterns
MetaClaude uses reusable thinking patterns:
- **Analytical**: Breaking down complex problems
- **Creative**: Generating innovative solutions
- **Strategic**: Long-term planning
- **Adaptive**: Context-aware responses

### Agent Orchestration
Specialized agents work together:
- **Orchestrator**: Coordinates all activities
- **Specialists**: Domain experts (6 for UI Designer)
- **Parallel Processing**: Multiple agents work simultaneously
- **Result Synthesis**: Intelligent combination of outputs

## Specialist Implementations

MetaClaude includes multiple specialist implementations, each designed for specific domains. While UI Designer Claude is the primary focus, understanding all available specialists helps you leverage the full power of the framework.

### Available Specialists

#### UI Designer Claude (Primary)
The flagship implementation with 6 specialized agents:
- **Visual Designer**: Creates stunning visual designs and interfaces
- **UX Researcher**: Conducts user research and validates design decisions
- **Interaction Designer**: Designs micro-interactions and animations
- **Design Systems Architect**: Builds scalable component libraries
- **Brand Strategist**: Develops cohesive brand identities
- **Accessibility Specialist**: Ensures WCAG compliance and inclusive design

**When to use**: Any UI/UX design task, from simple mockups to complete design systems

#### Code Expert Claude
Advanced programming assistant with deep language expertise:
```
"Optimize this React component for performance"
"Create a type-safe API client in TypeScript"
"Review this code for security vulnerabilities"
```

**When to use**: Complex coding challenges, architecture decisions, code reviews

#### Data Analyst Claude
Specialized in data analysis and visualization:
```
"Analyze user behavior patterns from this dataset"
"Create a dashboard showing key business metrics"
"Identify anomalies in time series data"
```

**When to use**: Data exploration, statistical analysis, creating data visualizations

#### Creative Writer Claude
Expert in creative and technical writing:
```
"Write compelling microcopy for onboarding flow"
"Create user documentation for our API"
"Develop a content strategy for our blog"
```

**When to use**: Content creation, documentation, marketing copy

#### Research Scholar Claude
Academic-level research and analysis:
```
"Research current trends in sustainable design"
"Compare different authentication methods"
"Analyze competitor strategies in fintech"
```

**When to use**: Market research, competitive analysis, technical research

#### Project Manager Claude
Orchestrates complex projects and workflows:
```
"Create a project plan for mobile app development"
"Identify risks in our current timeline"
"Optimize team resource allocation"
```

**When to use**: Project planning, team coordination, risk management

### Exploring Specialist Capabilities

#### Quick Discovery Commands
```
# Learn about a specific specialist
"What can the Visual Designer help me with?"
"Show me examples of Design Systems Architect work"

# Compare specialists
"Should I use UX Researcher or Research Scholar for user interviews?"
"What's the difference between Visual Designer and Brand Strategist?"

# Request specific expertise
"I need the Accessibility Specialist to audit my design"
"Have the Interaction Designer create micro-animations"
```

#### Combining Specialists
MetaClaude automatically orchestrates multiple specialists when needed:
```
"Create a data dashboard with great UX and accessibility"
# Engages: Data Analyst + Visual Designer + Accessibility Specialist

"Design and document a component library"
# Engages: Design Systems Architect + Creative Writer + Code Expert
```

### Common Specialist Tasks

#### UI/UX Design Flow
```bash
# Research phase
"UX Researcher: Analyze target audience for fitness app"

# Design phase
"Visual Designer: Create 3 homepage concepts"

# Interaction phase
"Interaction Designer: Add delightful micro-interactions"

# Accessibility check
"Accessibility Specialist: Audit designs for WCAG AAA"
```

#### Full-Stack Development
```bash
# Architecture
"Code Expert: Design scalable microservices architecture"

# Implementation
"Create React components from these designs"

# Documentation
"Creative Writer: Document API endpoints"

# Analysis
"Data Analyst: Create performance monitoring dashboard"
```

#### Brand Development
```bash
# Strategy
"Brand Strategist: Develop brand personality for eco startup"

# Visual Identity
"Visual Designer: Create logo and color palette"

# Content
"Creative Writer: Develop brand voice guidelines"

# Research
"Research Scholar: Analyze competitor branding"
```

### Advanced Specialist Integration

#### Memory-Driven Coordination
Specialists share context through MetaClaude's memory:
```
"Visual Designer: Create initial concepts and store in memory"
"Brand Strategist: Review stored concepts and suggest improvements"
"Design Systems Architect: Build components from approved concepts"
```

#### Parallel Specialist Execution
Request multiple specialists simultaneously:
```
"I need:
- Visual Designer to create landing page
- Creative Writer to write copy
- Accessibility Specialist to ensure compliance
- Code Expert to implement in React"
```

#### Specialist Handoffs
Seamless transitions between specialists:
```
"Start with UX research, then move to visual design, finally create code"
```

### Implementation Directory Reference

For detailed information about each specialist's capabilities, review the implementations directory:

- `/implementations/ui-designer/` - Complete UI Designer implementation
- `/implementations/code-expert/` - Programming and architecture specialist
- `/implementations/data-analyst/` - Data analysis and visualization
- `/implementations/creative-writer/` - Content and documentation
- `/implementations/research-scholar/` - Academic research capabilities
- `/implementations/project-manager/` - Project orchestration

Each directory contains:
- `README.md` - Detailed capability description
- `agents/` - Individual agent configurations
- `workflows/` - Pre-built workflow templates
- `examples/` - Sample outputs and use cases

### Choosing the Right Specialist

| Task Type | Primary Specialist | Supporting Specialists |
|-----------|-------------------|----------------------|
| Mobile App Design | Visual Designer | UX Researcher, Accessibility |
| Design System | Design Systems Architect | Visual Designer, Code Expert |
| Brand Identity | Brand Strategist | Visual Designer, Creative Writer |
| User Research | UX Researcher | Research Scholar, Data Analyst |
| Documentation | Creative Writer | Design Systems Architect |
| Code Review | Code Expert | Project Manager |
| Data Visualization | Data Analyst | Visual Designer |

### Quick Specialist Commands

```bash
# UI Design Tasks
"@visual-designer Create modern dashboard layout"
"@ux-researcher Validate user flow with testing"
"@interaction Add smooth transitions between states"
"@design-systems Build token-based color system"
"@brand Create cohesive visual identity"
"@accessibility Check color contrast ratios"

# Development Tasks
"@code-expert Optimize React performance"
"@data-analyst Visualize user metrics"
"@project-manager Create sprint plan"

# Content Tasks
"@creative-writer Write onboarding copy"
"@research-scholar Research design trends"
```

## Best Practices

### 1. Be Specific About Context
```
Good: "Design a fitness app for seniors with large touch targets and high contrast"
Better: "Design a fitness tracking app for adults 65+ with mobility limitations, focusing on simple daily exercises, medication reminders, and emergency contacts"
```

### 2. Leverage Workflows
Instead of asking for individual tasks, use complete workflows:
```
"Run a design sprint for a meal planning app that reduces food waste"
```

### 3. Iterate Based on Feedback
MetaClaude learns from your feedback:
```
"The designs look good but need more whitespace and larger fonts"
```

### 4. Use Natural Language
No need for special syntax - just describe what you want:
```
"I need a modern, minimalist design for a meditation app with calming colors"
```

## Common Use Cases

### Startup MVP
```
"Create an MVP design for a B2B SaaS platform that helps small businesses manage inventory"
```

### Redesign Project
```
"Modernize the UI for a legacy financial dashboard while maintaining familiarity for existing users"
```

### Design System
```
"Create a complete design system for a healthcare startup focused on telemedicine"
```

### Brand Development
```
"Develop a brand identity for an eco-friendly fashion brand targeting millennials"
```

## Advanced Features

### Memory and Learning
MetaClaude remembers context within sessions:
- Design decisions persist
- Patterns are recognized
- Preferences are learned

### Parallel Generation
Request multiple variations:
```
"Create 5 different homepage designs with varying levels of visual complexity"
```

### Cross-Functional Integration
Combine different specialties:
```
"Design a dashboard that balances data density (UX) with brand personality (Brand) and accessibility (A11y)"
```

## Troubleshooting

### If results aren't what you expected:
1. Provide more context about your goals
2. Specify any constraints or requirements
3. Share examples of what you like/dislike
4. Ask for specific adjustments

### If the process seems slow:
- Break down complex requests into phases
- Use predefined workflows when possible
- Focus on one major goal at a time

## Next Steps

1. **Try a Simple Task**: Start with extracting design DNA from an image
2. **Run a Workflow**: Try a design sprint for a simple app idea
3. **Explore Specialists**: 
   - Ask "What specialists are available?" to see all options
   - Try "@visual-designer Show me your capabilities"
   - Combine specialists: "Use Visual Designer and Code Expert to create a React component"
4. **Discover Implementations**: Browse `/implementations/` directory for detailed examples
5. **Build Something Real**: Create a complete design system with multiple specialists

## Need Help?

Ask MetaClaude:
```
"What can you help me design?"
"Explain how the design process works"
"Show me examples of what you can create"
"What specialists are available?"
"Which specialist should I use for [task]?"
"How do specialists work together?"
```

### Specialist-Specific Help
```
"@visual-designer What's your design philosophy?"
"@code-expert What languages do you support?"
"@data-analyst What visualizations can you create?"
"Compare UI Designer and Code Expert capabilities"
```

MetaClaude is designed to be intuitive - just describe what you need and let the cognitive framework handle the complexity. The specialist implementations work seamlessly together to deliver comprehensive solutions.