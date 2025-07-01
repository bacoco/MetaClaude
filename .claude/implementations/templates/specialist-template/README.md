# Specialist Template

This directory provides a starting template for creating new MetaClaude specialists.

## Directory Structure

```
specialist-template/
├── README.md           # This file - replace with your specialist's README
├── agents/            # Agent definitions
│   └── .gitkeep      # Remove after adding agents
├── workflows/         # Workflow definitions  
│   └── .gitkeep      # Remove after adding workflows
├── docs/             # Additional documentation
│   └── .gitkeep      # Remove after adding docs
└── examples/         # Usage examples
    └── .gitkeep      # Remove after adding examples
```

## Creating a New Specialist

1. **Copy this template**:
   ```bash
   cp -r specialist-template/ [your-specialist-name]/
   ```

2. **Define your agents**:
   - Use `../agent-template.md` as a starting point
   - Create one file per agent in the `agents/` directory
   - Name files descriptively (e.g., `requirements-analyst.md`)

3. **Define your workflows**:
   - Use `../workflow-template.md` as a starting point
   - Create one file per workflow in the `workflows/` directory
   - Consider both simple and complex workflow patterns

4. **Update the README**:
   - Replace this file with your specialist's README
   - Use `../README-template.md` as a guide
   - Include clear examples and use cases

5. **Add documentation**:
   - `setup-guide.md`: Installation and configuration
   - `api-reference.md`: Detailed command/function reference
   - `customization.md`: How to extend or modify

6. **Provide examples**:
   - Create subdirectories for different example scenarios
   - Include sample inputs and expected outputs
   - Add configuration files where relevant

## Integration Checklist

- [ ] Specialist follows MetaClaude cognitive patterns
- [ ] Agents have clear, distinct roles
- [ ] Workflows are well-defined with error handling
- [ ] Memory operations are documented
- [ ] Tool dependencies are specified
- [ ] Integration points with other specialists are defined
- [ ] Examples demonstrate key use cases
- [ ] Documentation is comprehensive
- [ ] Testing procedures are included

## Next Steps

After creating your specialist:

1. Test thoroughly with example scenarios
2. Document any discovered edge cases
3. Create integration tests with other specialists
4. Update the main implementations README
5. Submit for review

---

*Specialist Template v1.0.0 | MetaClaude Framework*