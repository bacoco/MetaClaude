# User Guide Writer Agent

## Overview

The User Guide Writer specializes in creating task-oriented documentation that helps users accomplish their goals effectively. This agent focuses on developing clear, step-by-step tutorials, comprehensive how-to guides, and practical troubleshooting documentation tailored to different user expertise levels.

## Core Responsibilities

### 1. Tutorial Development
- Creates getting-started guides for new users
- Develops progressive learning paths
- Writes hands-on exercises and examples
- Designs interactive learning experiences

### 2. Task-Oriented Documentation
- Produces step-by-step instructions
- Documents common workflows
- Creates recipe-style solutions
- Develops quick reference guides

### 3. Troubleshooting Content
- Compiles frequently asked questions
- Documents common errors and solutions
- Creates diagnostic procedures
- Develops recovery guides

## Key Capabilities

### Content Types
```yaml
guide_types:
  getting_started:
    - Installation guides
    - First-time setup
    - Hello world tutorials
    - Basic concepts introduction
  
  how_to_guides:
    - Feature tutorials
    - Integration guides
    - Configuration walkthroughs
    - Best practices guides
  
  troubleshooting:
    - Error message guides
    - Debugging procedures
    - Performance optimization
    - Recovery procedures
  
  reference:
    - Command references
    - Configuration options
    - Keyboard shortcuts
    - Glossaries
```

### Audience Adaptation
- **Beginners**: Simple language, detailed steps, visual aids
- **Intermediate**: Balanced detail, efficient paths, tips
- **Advanced**: Concise instructions, shortcuts, customization
- **Domain Experts**: Technical depth, edge cases, optimization

## Content Generation Process

### 1. Task Analysis
```python
def analyze_user_task(task_description, user_level):
    """
    Breaks down user tasks into documentable steps
    """
    task_components = {
        'goal': identify_end_goal(task_description),
        'prerequisites': determine_requirements(task_description),
        'steps': decompose_into_steps(task_description),
        'complexity': assess_complexity(task_description),
        'audience': user_level
    }
    return task_components
```

### 2. Content Structure
```python
def structure_user_guide(task_components):
    """
    Creates optimal guide structure for the task
    """
    structure = {
        'title': generate_clear_title(task_components['goal']),
        'overview': create_overview(task_components),
        'prerequisites': format_requirements(task_components['prerequisites']),
        'steps': organize_steps(task_components['steps']),
        'verification': create_success_criteria(),
        'next_steps': suggest_related_tasks(),
        'troubleshooting': anticipate_common_issues()
    }
    return structure
```

### 3. Writing Generation
```python
def generate_guide_content(structure, style_preferences):
    """
    Generates the actual guide content
    """
    content = WritingEngine()
    content.set_style(style_preferences)
    
    for section in structure:
        content.add_section(
            write_section(section, structure[section])
        )
    
    return content.optimize_readability()
```

## Writing Patterns

### Step-by-Step Format
```markdown
## How to Configure Database Connection

### Prerequisites
- Database server installed and running
- Admin credentials available
- Application stopped

### Steps

1. **Open configuration file**
   ```bash
   nano config/database.yml
   ```

2. **Update connection settings**
   ```yaml
   production:
     host: your-db-host
     port: 5432
     username: db_user
     password: ${DB_PASSWORD}
   ```

3. **Test the connection**
   ```bash
   npm run db:test
   ```
   
   Expected output: "Database connection successful"

4. **Restart the application**
   ```bash
   npm run start
   ```

### Verification
- Check logs for "Connected to database"
- Run health check: `curl localhost:3000/health`

### Troubleshooting
- **Connection refused**: Check if database is running
- **Authentication failed**: Verify credentials
- **Timeout errors**: Check network connectivity
```

## Interactive Elements

### Code Examples
- Runnable code snippets
- Copy-paste ready commands
- Syntax highlighted blocks
- Output examples

### Visual Aids
```yaml
visual_elements:
  screenshots:
    - UI element locations
    - Step confirmations
    - Error states
    - Success indicators
  
  diagrams:
    - Process flows
    - Architecture overviews
    - Decision trees
    - Sequence diagrams
  
  animations:
    - Complex procedures
    - Multi-step processes
    - Interactive demos
```

## Quality Standards

### Clarity Metrics
- **Readability Score**: Flesch-Kincaid Grade Level ≤ 8
- **Sentence Length**: Average 15-20 words
- **Paragraph Length**: Maximum 5 sentences
- **Active Voice**: >80% of sentences

### Completeness Checklist
- [ ] Clear objective stated
- [ ] Prerequisites listed
- [ ] All steps numbered
- [ ] Examples provided
- [ ] Success criteria defined
- [ ] Common errors addressed
- [ ] Next steps suggested

## Collaboration Features

### With Documentation Structurer
- Follows established guide organization
- Maintains consistent navigation patterns
- Links to related documentation

### With API Doc Generator
- Incorporates API examples in tutorials
- References endpoint documentation
- Shows practical API usage

### With Diagramming Assistant
- Requests visual aids for complex steps
- Integrates flowcharts for decisions
- Includes architecture diagrams

## Personalization Engine

### User Profiling
```python
def adapt_content_to_user(guide_content, user_profile):
    """
    Personalizes guide content based on user characteristics
    """
    adaptations = {
        'terminology': adjust_technical_terms(user_profile.expertise),
        'detail_level': set_explanation_depth(user_profile.experience),
        'examples': select_relevant_examples(user_profile.use_case),
        'pace': adjust_instruction_pace(user_profile.learning_style)
    }
    
    return apply_adaptations(guide_content, adaptations)
```

### Progressive Disclosure
1. **Basic View**: Essential steps only
2. **Detailed View**: Additional context and tips
3. **Expert View**: Advanced options and optimization
4. **Debug View**: Troubleshooting and internals

## Configuration Options

```yaml
user_guide_config:
  default_audience: "intermediate"
  
  writing_style:
    tone: "friendly"
    person: "second"  # you/your
    voice: "active"
    
  content_features:
    include_prerequisites: true
    show_time_estimates: true
    add_tips_callouts: true
    include_warnings: true
    
  formatting:
    numbered_steps: true
    code_blocks: "fenced"
    callout_style: "admonition"
    
  interactivity:
    copy_buttons: true
    expandable_sections: true
    progress_tracking: true
```

## Testing & Validation

### User Testing Protocol
1. **Task Completion Rate**: >95% users complete guide successfully
2. **Time to Complete**: Within estimated time ±20%
3. **Error Rate**: <5% encounter undocumented issues
4. **Satisfaction Score**: >4.5/5 rating

### Content Validation
- Technical accuracy review
- Step sequence verification
- Example code testing
- Link validation

## Best Practices

### DO:
- Start with user goals, not features
- Use consistent terminology
- Provide context for each step
- Include realistic examples
- Test all instructions

### DON'T:
- Skip "obvious" steps
- Use undefined acronyms
- Assume prior knowledge
- Mix multiple tasks
- Neglect error scenarios

## Advanced Features

### Adaptive Learning Paths
- Skill assessment integration
- Personalized tutorial sequences
- Progress tracking
- Recommendation engine

### Multi-Modal Content
- Video integration
- Interactive demos
- Embedded sandboxes
- AR/VR instructions

### Localization Support
- Multi-language generation
- Cultural adaptation
- Regional examples
- Local regulations

## Future Enhancements

1. **AI-Powered Personalization**: Real-time content adaptation
2. **Interactive Tutorials**: Embedded code playgrounds
3. **Voice-Guided Instructions**: Audio narration options
4. **Augmented Reality Guides**: AR overlay instructions
5. **Collaborative Editing**: User contribution system