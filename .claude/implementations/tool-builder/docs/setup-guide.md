# Tool Builder Setup Guide

## Prerequisites

### System Requirements
- MetaClaude framework v2.0 or higher
- Python 3.8+ (for Python tool generation)
- Node.js 16+ (for JavaScript tool generation)
- Bash 4.0+ (for shell script generation)
- Git for version control
- 4GB RAM minimum, 8GB recommended

### Required Dependencies
```bash
# Python dependencies
pip install pyyaml jinja2 black pytest coverage

# Node.js dependencies
npm install -g eslint prettier jest

# System utilities
apt-get install shellcheck jq  # Debian/Ubuntu
brew install shellcheck jq     # macOS
```

## Installation

### 1. Clone the Tool Builder Module
```bash
cd /path/to/metaclaude/.claude/implementations
git clone <tool-builder-repo> tool-builder
cd tool-builder
```

### 2. Install Tool Builder Dependencies
```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install Python dependencies
pip install -r requirements.txt

# Install Node dependencies
npm install
```

### 3. Configure Tool Builder
```bash
# Copy example configuration
cp config/tool-builder.example.yml config/tool-builder.yml

# Edit configuration
$EDITOR config/tool-builder.yml
```

### 4. Initialize Tool Registry
```bash
# Create necessary directories
mkdir -p generated-tools/{python,javascript,bash}
mkdir -p tool-registry
mkdir -p logs

# Initialize registry files
touch tool-registry/tool-usage-matrix.md
touch tool-registry/tool-suggestion-patterns.md
```

## Configuration

### Tool Builder Configuration File
```yaml
# config/tool-builder.yml
tool_builder:
  version: "1.0.0"
  
  agents:
    requirements_analyst:
      enabled: true
      timeout: 3600  # 1 hour
      max_retries: 3
    
    design_architect:
      enabled: true
      patterns_path: "./patterns"
      templates_path: "./templates"
    
    code_generator:
      enabled: true
      languages:
        - python
        - javascript
        - bash
      output_path: "./generated-tools"
    
    integrator:
      enabled: true
      registry_path: "./tool-registry"
      auto_register: true
    
    validator:
      enabled: true
      test_timeout: 300  # 5 minutes
      coverage_threshold: 80
  
  workflows:
    dynamic_creation:
      enabled: true
      max_concurrent: 3
    
    optimization:
      enabled: true
      analysis_interval: 86400  # 24 hours
  
  monitoring:
    metrics_enabled: true
    metrics_path: "./metrics"
    log_level: "INFO"
    log_path: "./logs"
  
  security:
    sandboxing: true
    code_scanning: true
    dependency_check: true
```

### Environment Variables
```bash
# .env file
export TOOL_BUILDER_HOME=/path/to/tool-builder
export TOOL_BUILDER_CONFIG=$TOOL_BUILDER_HOME/config/tool-builder.yml
export TOOL_BUILDER_LOG_LEVEL=INFO
export METACLAUDE_HOME=/path/to/metaclaude
```

## Verification

### 1. Test Agent Connectivity
```bash
# Test each agent
python scripts/test_agent.py requirements_analyst
python scripts/test_agent.py design_architect
python scripts/test_agent.py code_generator
python scripts/test_agent.py integrator
python scripts/test_agent.py validator
```

### 2. Run Integration Tests
```bash
# Run the test suite
pytest tests/integration/

# Check test coverage
coverage run -m pytest tests/
coverage report
```

### 3. Verify Tool Generation
```bash
# Generate a simple test tool
python scripts/generate_test_tool.py \
  --name "hello_world" \
  --type "utility" \
  --language "python"

# Verify the generated tool
ls generated-tools/python/hello_world/
cat generated-tools/python/hello_world/hello_world.py
```

## Initial Setup Tasks

### 1. Create Tool Templates
```bash
# Navigate to templates directory
cd templates/

# Create basic templates for each language
touch python_tool_template.py.j2
touch javascript_tool_template.js.j2
touch bash_tool_template.sh.j2
```

### 2. Set Up Pattern Library
```bash
# Navigate to patterns directory
cd patterns/

# Create pattern files
touch api_wrapper_pattern.yml
touch data_processor_pattern.yml
touch utility_pattern.yml
```

### 3. Configure Logging
```python
# config/logging_config.py
import logging
import logging.config

LOGGING_CONFIG = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'standard': {
            'format': '%(asctime)s [%(levelname)s] %(name)s: %(message)s'
        },
    },
    'handlers': {
        'file': {
            'level': 'INFO',
            'formatter': 'standard',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': 'logs/tool_builder.log',
            'maxBytes': 10485760,  # 10MB
            'backupCount': 5,
        },
        'console': {
            'level': 'INFO',
            'formatter': 'standard',
            'class': 'logging.StreamHandler',
        },
    },
    'loggers': {
        'tool_builder': {
            'handlers': ['file', 'console'],
            'level': 'INFO',
            'propagate': False,
        },
    },
}

logging.config.dictConfig(LOGGING_CONFIG)
```

## Troubleshooting

### Common Issues

#### Agent Communication Failures
```bash
# Check agent status
python scripts/check_agents.py

# Restart agents
python scripts/restart_agents.py

# Check logs
tail -f logs/tool_builder.log
```

#### Tool Generation Errors
```bash
# Enable debug logging
export TOOL_BUILDER_LOG_LEVEL=DEBUG

# Run with verbose output
python scripts/generate_tool.py --verbose

# Check generated code syntax
python -m py_compile generated-tools/python/*/**.py
```

#### Registry Update Issues
```bash
# Verify registry files exist
ls -la tool-registry/

# Check file permissions
chmod 644 tool-registry/*.md

# Validate registry format
python scripts/validate_registry.py
```

## Next Steps

1. Review the [Integration Guide](integration-guide.md)
2. Explore example tools in the `examples/` directory
3. Create your first custom tool template
4. Set up monitoring dashboards
5. Configure automated testing pipelines

## Support

- Documentation: `/docs`
- Issue Tracker: GitHub Issues
- Community: MetaClaude Discord
- Email: toolbuilder@metaclaude.ai