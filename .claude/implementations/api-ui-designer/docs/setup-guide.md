# API-to-UI Designer Setup Guide

Complete guide to get started with automatic UI generation from API specifications.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [First API-to-UI Generation](#first-api-to-ui-generation)
- [Advanced Setup](#advanced-setup)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Software
- Node.js 18.0 or higher
- npm 9.0 or higher
- Git

### Optional but Recommended
- Docker (for running local API mocks)
- Visual Studio Code with extensions:
  - OpenAPI (Swagger) Editor
  - REST Client
  - GraphQL

### Knowledge Requirements
- Basic understanding of REST APIs or GraphQL
- Familiarity with OpenAPI/Swagger specifications
- Basic React/Vue/Angular knowledge (depending on your target framework)

## Installation

### 1. Install via npm

```bash
npm install @ui-designer/api-to-ui --save-dev
```

### 2. Install via Claude-Flow

```bash
# Initialize Claude-Flow project with API-to-UI support
./claude-flow init --with-api-ui

# Or add to existing project
./claude-flow add api-ui-designer
```

### 3. Manual Installation

```bash
# Clone the repository
git clone https://github.com/your-org/api-ui-designer.git
cd api-ui-designer

# Install dependencies
npm install

# Build the project
npm run build

# Link globally
npm link
```

## Configuration

### 1. Create Configuration File

Create `api-ui.config.js` in your project root:

```javascript
module.exports = {
  // Input configuration
  input: {
    // API specification source
    source: {
      type: 'openapi', // 'openapi' | 'graphql' | 'json-schema'
      path: './api/openapi.yaml', // Path to your API spec
      url: 'https://api.example.com/swagger.json', // Or URL
      watch: true // Auto-regenerate on changes
    },
    
    // Authentication for fetching specs
    auth: {
      type: 'bearer', // 'bearer' | 'basic' | 'apikey'
      token: process.env.API_TOKEN
    }
  },
  
  // Output configuration
  output: {
    // Target framework
    framework: 'react', // 'react' | 'vue' | 'angular' | 'web-components'
    
    // Output directory
    directory: './src/generated/components',
    
    // File naming convention
    fileNaming: 'kebab-case', // 'kebab-case' | 'camelCase' | 'PascalCase'
    
    // Component naming
    componentNaming: 'PascalCase',
    
    // TypeScript support
    typescript: true,
    
    // Generate tests
    generateTests: true,
    testFramework: 'jest' // 'jest' | 'vitest' | 'cypress'
  },
  
  // UI configuration
  ui: {
    // Component library
    componentLibrary: 'mui', // 'mui' | 'antd' | 'chakra' | 'custom'
    
    // Theme configuration
    theme: {
      primaryColor: '#1976d2',
      mode: 'light', // 'light' | 'dark' | 'auto'
      customTheme: './src/theme.js'
    },
    
    // Default component mappings override
    componentMappings: {
      'string': 'CustomTextInput',
      'number': 'CustomNumberInput'
    },
    
    // Layout preferences
    layout: {
      formLayout: 'vertical', // 'vertical' | 'horizontal' | 'inline'
      maxColumns: 2,
      spacing: 'normal' // 'compact' | 'normal' | 'comfortable'
    }
  },
  
  // Generation rules
  rules: {
    // Include/exclude endpoints
    include: ['/api/v1/**'],
    exclude: ['/api/v1/internal/**'],
    
    // Custom field mappings
    fieldMappings: {
      'user_name': { component: 'UsernameInput', required: true },
      'phone_number': { component: 'PhoneInput', format: 'international' }
    },
    
    // Validation rules
    validation: {
      emailDomains: ['company.com'], // Restrict email domains
      passwordStrength: 'strong', // 'weak' | 'medium' | 'strong'
      requiredByDefault: false
    }
  },
  
  // API client configuration
  api: {
    // Base URL for API calls
    baseURL: process.env.REACT_APP_API_URL || 'http://localhost:3000',
    
    // Request interceptors
    interceptors: './src/api/interceptors.js',
    
    // Error handling
    errorHandling: 'toast', // 'toast' | 'modal' | 'inline' | 'custom'
    
    // Retry configuration
    retry: {
      times: 3,
      delay: 1000,
      backoff: 'exponential'
    }
  },
  
  // Plugin system
  plugins: [
    '@ui-designer/plugin-auth', // Authentication plugin
    '@ui-designer/plugin-i18n', // Internationalization
    '@ui-designer/plugin-analytics', // Analytics integration
    './plugins/custom-plugin.js' // Custom plugin
  ]
};
```

### 2. Environment Variables

Create `.env` file:

```env
# API Configuration
API_TOKEN=your-api-token
API_BASE_URL=https://api.example.com

# UI Designer Configuration
UI_DESIGNER_MODE=development
UI_DESIGNER_LOG_LEVEL=debug

# Component Library License Keys (if required)
MUI_LICENSE_KEY=your-license-key
```

### 3. TypeScript Configuration

If using TypeScript, update `tsconfig.json`:

```json
{
  "compilerOptions": {
    "paths": {
      "@generated/*": ["./src/generated/*"],
      "@ui-components/*": ["./src/components/*"]
    }
  },
  "include": [
    "src/**/*",
    "src/generated/**/*"
  ]
}
```

## First API-to-UI Generation

### Step 1: Prepare Your API Specification

Create `api/openapi.yaml`:

```yaml
openapi: 3.0.0
info:
  title: User Management API
  version: 1.0.0

paths:
  /users:
    get:
      summary: List users
      responses:
        '200':
          description: User list
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/User'
    
    post:
      summary: Create user
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/UserInput'
      responses:
        '201':
          description: User created

components:
  schemas:
    User:
      type: object
      properties:
        id:
          type: string
          format: uuid
        name:
          type: string
          minLength: 2
          maxLength: 100
        email:
          type: string
          format: email
        role:
          type: string
          enum: [admin, user, guest]
        createdAt:
          type: string
          format: date-time
    
    UserInput:
      type: object
      required: [name, email]
      properties:
        name:
          type: string
          minLength: 2
          maxLength: 100
        email:
          type: string
          format: email
        role:
          type: string
          enum: [admin, user, guest]
          default: user
```

### Step 2: Generate UI Components

Run the generation command:

```bash
# Using npm script
npm run generate-ui

# Using CLI directly
api-ui generate

# Using Claude-Flow
./claude-flow api-ui generate --watch
```

### Step 3: Review Generated Components

The generator creates the following structure:

```
src/generated/
├── components/
│   ├── UserList/
│   │   ├── UserList.tsx
│   │   ├── UserList.test.tsx
│   │   ├── UserList.styles.ts
│   │   └── index.ts
│   ├── UserForm/
│   │   ├── UserForm.tsx
│   │   ├── UserForm.test.tsx
│   │   ├── UserForm.validation.ts
│   │   └── index.ts
│   └── index.ts
├── api/
│   ├── userApi.ts
│   ├── types.ts
│   └── hooks.ts
└── index.ts
```

### Step 4: Use Generated Components

```tsx
import React from 'react';
import { UserList, UserForm } from '@generated/components';
import { useCreateUser } from '@generated/api/hooks';

function UserManagement() {
  const createUser = useCreateUser();
  
  return (
    <div>
      <h1>User Management</h1>
      
      {/* Generated form with automatic validation */}
      <UserForm
        onSubmit={async (data) => {
          await createUser(data);
        }}
        onSuccess={() => {
          console.log('User created!');
        }}
      />
      
      {/* Generated list with sorting, filtering, and pagination */}
      <UserList
        onEdit={(user) => console.log('Edit', user)}
        onDelete={(user) => console.log('Delete', user)}
      />
    </div>
  );
}
```

## Advanced Setup

### Custom Component Templates

Create custom templates in `templates/components/`:

```typescript
// templates/components/TextInput.template.tsx
export const TextInputTemplate = `
import React from 'react';
import { TextField } from '@mui/material';
import { {{componentName}}Props } from './types';

export const {{componentName}}: React.FC<{{componentName}}Props> = ({
  name,
  label,
  value,
  onChange,
  error,
  helperText,
  ...props
}) => {
  return (
    <TextField
      name={name}
      label={label}
      value={value}
      onChange={onChange}
      error={error}
      helperText={helperText}
      fullWidth
      margin="normal"
      {...props}
    />
  );
};
`;
```

### Custom Mapping Rules

Create `mappings/custom-rules.js`:

```javascript
module.exports = {
  // Custom type mappings
  typeMappings: {
    'string:phone': {
      component: 'PhoneInput',
      imports: ["import PhoneInput from 'react-phone-input-2'"],
      props: {
        country: 'us',
        inputProps: {
          required: true
        }
      }
    }
  },
  
  // Custom validation messages
  validationMessages: {
    required: (field) => `${field.label} is required`,
    email: 'Please enter a valid email address',
    minLength: (field, value) => `${field.label} must be at least ${value} characters`
  },
  
  // Custom transformers
  transformers: {
    // Transform field names
    fieldName: (name) => {
      return name.replace(/_/g, '');
    },
    
    // Transform labels
    label: (fieldName) => {
      return fieldName
        .replace(/([A-Z])/g, ' $1')
        .replace(/^./, str => str.toUpperCase())
        .trim();
    }
  }
};
```

### Plugin Development

Create custom plugins:

```javascript
// plugins/auth-plugin.js
module.exports = {
  name: 'auth-plugin',
  
  // Hook into the generation process
  hooks: {
    // Before generation
    beforeGenerate: async (config, api) => {
      console.log('Checking authentication endpoints...');
    },
    
    // Modify component generation
    modifyComponent: (component, fieldSchema) => {
      if (fieldSchema.name === 'password') {
        component.props.type = 'password';
        component.props.autoComplete = 'current-password';
      }
      return component;
    },
    
    // After generation
    afterGenerate: async (results) => {
      console.log(`Generated ${results.components.length} components`);
    }
  },
  
  // Add custom commands
  commands: {
    'generate-auth': {
      description: 'Generate authentication components',
      action: async (options) => {
        // Custom generation logic
      }
    }
  }
};
```

### CI/CD Integration

#### GitHub Actions

```yaml
# .github/workflows/generate-ui.yml
name: Generate UI Components

on:
  push:
    paths:
      - 'api/openapi.yaml'
      - 'api-ui.config.js'

jobs:
  generate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Generate UI components
        run: npm run generate-ui
      
      - name: Run tests
        run: npm test -- --testPathPattern=generated
      
      - name: Commit changes
        uses: EndBug/add-and-commit@v9
        with:
          message: 'chore: regenerate UI components from API spec'
          add: 'src/generated'
```

#### Pre-commit Hook

```bash
# .husky/pre-commit
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

# Check if API spec has changed
if git diff --cached --name-only | grep -q "openapi.yaml"; then
  echo "API specification changed, regenerating UI components..."
  npm run generate-ui
  git add src/generated
fi
```

## Troubleshooting

### Common Issues

#### 1. Generation Fails with Schema Errors

**Problem**: Invalid OpenAPI specification
```bash
Error: Schema validation failed: paths./users.get.responses.200.content.application/json.schema.$ref
```

**Solution**: Validate your OpenAPI spec
```bash
# Install validator
npm install -g @apidevtools/swagger-cli

# Validate
swagger-cli validate api/openapi.yaml
```

#### 2. TypeScript Compilation Errors

**Problem**: Generated types conflict
```bash
TS2304: Cannot find name 'UserInput'
```

**Solution**: Check type generation settings
```javascript
// api-ui.config.js
module.exports = {
  output: {
    typescript: true,
    typesPath: './src/types/generated.ts', // Separate types file
    skipTypeCheck: false // Enable to debug
  }
};
```

#### 3. Component Library Conflicts

**Problem**: Styled components conflict
```bash
Error: Multiple versions of styled-components detected
```

**Solution**: Use resolution in package.json
```json
{
  "resolutions": {
    "styled-components": "^5.3.0"
  }
}
```

#### 4. API Connection Issues

**Problem**: Cannot fetch remote specification
```bash
Error: Failed to fetch API specification: ECONNREFUSED
```

**Solution**: Configure proxy or use local file
```javascript
// api-ui.config.js
module.exports = {
  input: {
    source: {
      type: 'openapi',
      path: './api/openapi-local.yaml', // Use local copy
      // Or configure proxy
      proxy: {
        host: 'proxy.company.com',
        port: 8080
      }
    }
  }
};
```

### Debug Mode

Enable verbose logging:

```bash
# Set environment variable
export UI_DESIGNER_LOG_LEVEL=debug

# Or use CLI flag
api-ui generate --debug

# View generation plan without executing
api-ui generate --dry-run
```

### Performance Optimization

For large API specifications:

```javascript
// api-ui.config.js
module.exports = {
  performance: {
    // Process endpoints in parallel
    parallel: true,
    maxWorkers: 4,
    
    // Cache parsed schemas
    cache: {
      enabled: true,
      ttl: 3600 // 1 hour
    },
    
    // Incremental generation
    incremental: true,
    
    // Skip unchanged endpoints
    skipUnchanged: true
  }
};
```

## Next Steps

1. **Explore Advanced Features**
   - Custom component templates
   - Plugin development
   - Theme customization

2. **Integrate with Your Workflow**
   - Set up CI/CD pipeline
   - Configure pre-commit hooks
   - Add to build process

3. **Customize for Your Needs**
   - Create custom mapping rules
   - Develop organization-specific plugins
   - Build component library adapters

4. **Join the Community**
   - Report issues on GitHub
   - Share custom plugins
   - Contribute to documentation

For more examples and advanced usage, check out the [examples repository](https://github.com/your-org/api-ui-designer-examples).