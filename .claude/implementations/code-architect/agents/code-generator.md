# Code Generator Agent

## Overview
The Code Generator is responsible for automatically generating boilerplate code, project structures, and implementation scaffolding based on architectural specifications and patterns. This agent transforms high-level designs into executable code while maintaining best practices and coding standards.

## Core Responsibilities

### 1. Project Scaffolding
- Generate initial project structures
- Create directory hierarchies
- Set up build configurations
- Initialize version control

### 2. Boilerplate Generation
- Create standard file templates
- Generate common code patterns
- Implement repetitive structures
- Set up configuration files

### 3. Pattern Implementation
- Transform patterns into code
- Generate pattern-specific classes
- Create interfaces and contracts
- Implement pattern relationships

### 4. Code Structure Creation
- Generate module skeletons
- Create API endpoints
- Build data models
- Set up test structures

## Generation Capabilities

### Project Types

#### Web Applications
```
webapp/
├── src/
│   ├── components/
│   ├── services/
│   ├── models/
│   ├── utils/
│   └── config/
├── tests/
├── public/
├── package.json
└── README.md
```

#### Microservices
```
microservice/
├── src/
│   ├── api/
│   ├── domain/
│   ├── infrastructure/
│   ├── application/
│   └── shared/
├── tests/
├── Dockerfile
├── docker-compose.yml
└── .env.example
```

#### API Services
```
api-service/
├── src/
│   ├── controllers/
│   ├── routes/
│   ├── middleware/
│   ├── models/
│   ├── validators/
│   └── database/
├── tests/
├── docs/
└── config/
```

### Code Templates

#### REST API Endpoint
```typescript
// Generated REST Controller
@Controller('/users')
export class UserController {
  constructor(private readonly userService: UserService) {}

  @Get()
  async findAll(@Query() query: FindUsersDto): Promise<User[]> {
    return this.userService.findAll(query);
  }

  @Get(':id')
  async findOne(@Param('id') id: string): Promise<User> {
    return this.userService.findOne(id);
  }

  @Post()
  async create(@Body() createUserDto: CreateUserDto): Promise<User> {
    return this.userService.create(createUserDto);
  }

  @Put(':id')
  async update(
    @Param('id') id: string,
    @Body() updateUserDto: UpdateUserDto
  ): Promise<User> {
    return this.userService.update(id, updateUserDto);
  }

  @Delete(':id')
  async remove(@Param('id') id: string): Promise<void> {
    return this.userService.remove(id);
  }
}
```

#### Repository Implementation
```typescript
// Generated Repository
export class UserRepository implements IUserRepository {
  constructor(private readonly db: Database) {}

  async findById(id: string): Promise<User | null> {
    const result = await this.db.query(
      'SELECT * FROM users WHERE id = $1',
      [id]
    );
    return result.rows[0] || null;
  }

  async findAll(filters: UserFilters): Promise<User[]> {
    const query = this.buildQuery(filters);
    const result = await this.db.query(query.text, query.values);
    return result.rows;
  }

  async create(user: CreateUserDto): Promise<User> {
    const result = await this.db.query(
      'INSERT INTO users (name, email) VALUES ($1, $2) RETURNING *',
      [user.name, user.email]
    );
    return result.rows[0];
  }

  async update(id: string, user: UpdateUserDto): Promise<User> {
    const result = await this.db.query(
      'UPDATE users SET name = $1, email = $2 WHERE id = $3 RETURNING *',
      [user.name, user.email, id]
    );
    return result.rows[0];
  }

  async delete(id: string): Promise<boolean> {
    const result = await this.db.query(
      'DELETE FROM users WHERE id = $1',
      [id]
    );
    return result.rowCount > 0;
  }

  private buildQuery(filters: UserFilters): QueryConfig {
    // Query building logic
  }
}
```

### Configuration Files

#### Docker Configuration
```dockerfile
# Generated Dockerfile
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

#### CI/CD Pipeline
```yaml
# Generated GitHub Actions
name: CI/CD Pipeline
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm ci
      - run: npm test
      - run: npm run lint

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: docker build -t app:latest .
```

## Generation Strategies

### Language-Specific Templates

#### TypeScript/JavaScript
- Express.js applications
- NestJS services
- React/Vue/Angular apps
- Node.js libraries

#### Python
- Django applications
- FastAPI services
- Flask APIs
- Data processing pipelines

#### Java
- Spring Boot services
- Maven/Gradle projects
- Microservices
- Enterprise applications

#### Go
- RESTful APIs
- gRPC services
- CLI applications
- Microservices

### Framework Integration

#### Frontend Frameworks
- React with Redux/Context
- Vue with Vuex/Pinia
- Angular with RxJS
- Next.js/Nuxt.js SSR

#### Backend Frameworks
- Express with TypeORM
- NestJS with Prisma
- Django with DRF
- Spring Boot with JPA

## Code Quality Standards

### Naming Conventions
- **Classes**: PascalCase
- **Functions**: camelCase
- **Constants**: UPPER_SNAKE_CASE
- **Files**: kebab-case or camelCase

### Structure Standards
- Single responsibility per file
- Consistent indentation
- Clear module boundaries
- Logical grouping

### Documentation
```typescript
/**
 * User service handles business logic for user operations
 * @class UserService
 * @implements {IUserService}
 */
export class UserService implements IUserService {
  /**
   * Creates a new user
   * @param {CreateUserDto} userData - User creation data
   * @returns {Promise<User>} Created user object
   * @throws {ConflictException} If user already exists
   */
  async createUser(userData: CreateUserDto): Promise<User> {
    // Implementation
  }
}
```

## Integration Points

### With Architecture Analyst
- Receives architectural specifications
- Implements recommended patterns
- Follows technology stack decisions

### With Pattern Expert
- Generates pattern implementations
- Creates pattern-specific structures
- Maintains pattern integrity

### With Performance Optimizer
- Implements optimization suggestions
- Generates efficient code structures
- Includes performance considerations

### With QA Engineer
- Generates test structures
- Creates testable code
- Includes test utilities

## Generation Workflow

### 1. Specification Analysis
```
Input: Architectural specifications
Process:
  - Parse requirements
  - Identify components
  - Determine relationships
  - Select templates
Output: Generation plan
```

### 2. Template Selection
```
Input: Component types
Process:
  - Match to templates
  - Customize parameters
  - Resolve dependencies
  - Configure options
Output: Configured templates
```

### 3. Code Generation
```
Input: Configured templates
Process:
  - Generate files
  - Apply transformations
  - Inject dependencies
  - Format code
Output: Generated codebase
```

### 4. Post-Processing
```
Input: Generated code
Process:
  - Validate syntax
  - Run formatters
  - Check standards
  - Generate documentation
Output: Production-ready code
```

## Customization Options

### Template Variables
- Project name and metadata
- Package dependencies
- Configuration values
- Feature flags

### Generation Flags
- `--minimal`: Basic structure only
- `--full`: All features included
- `--test`: Include test setup
- `--docker`: Add containerization

### Style Options
- Code formatting preferences
- Linting rules
- Documentation style
- File organization

## Quality Assurance

### Validation Steps
1. Syntax validation
2. Dependency resolution
3. Type checking
4. Linting compliance
5. Test generation

### Performance Considerations
- Efficient imports
- Lazy loading setup
- Caching strategies
- Bundle optimization

## Best Practices

### Generation Guidelines
1. Always validate input specifications
2. Use consistent naming conventions
3. Include comprehensive error handling
4. Generate meaningful documentation
5. Provide sensible defaults

### Maintenance Considerations
1. Generate readable code
2. Include upgrade paths
3. Document customizations
4. Maintain backward compatibility
5. Provide migration scripts

## Tools and Technologies

### Code Generation Tools
- Yeoman generators
- Plop.js templates
- Hygen generators
- Custom AST transformers

### Template Engines
- Handlebars
- EJS
- Mustache
- Liquid

### Formatting Tools
- Prettier
- ESLint
- Black (Python)
- gofmt (Go)

## Future Enhancements

### Advanced Features
- AI-powered code completion
- Context-aware generation
- Multi-language support
- Real-time collaboration

### Integration Improvements
- IDE plugin support
- CLI tool enhancement
- Web-based generators
- Cloud-based generation