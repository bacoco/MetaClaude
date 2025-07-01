# Monolithic Architecture Example

## Overview
This example demonstrates a well-structured monolithic architecture implementation for a content management system (CMS) using the Code Architect patterns and best practices. While monolithic, the application follows clean architecture principles with clear separation of concerns.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      Presentation Layer                      │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │  Web Views  │  │  API Routes  │  │  Admin Interface │  │
│  └─────────────┘  └──────────────┘  └──────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                      Application Layer                       │
│  ┌──────────────┐  ┌───────────────┐  ┌───────────────┐   │
│  │   Services   │  │   Use Cases   │  │   DTOs        │   │
│  └──────────────┘  └───────────────┘  └───────────────┘   │
├─────────────────────────────────────────────────────────────┤
│                       Domain Layer                           │
│  ┌──────────────┐  ┌───────────────┐  ┌───────────────┐   │
│  │   Entities   │  │ Value Objects │  │ Domain Events │   │
│  └──────────────┘  └───────────────┘  └───────────────┘   │
├─────────────────────────────────────────────────────────────┤
│                   Infrastructure Layer                       │
│  ┌──────────────┐  ┌───────────────┐  ┌───────────────┐   │
│  │ Repositories │  │   Database    │  │ External APIs │   │
│  └──────────────┘  └───────────────┘  └───────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Project Structure

```
cms-monolith/
├── src/
│   ├── presentation/
│   │   ├── controllers/
│   │   ├── middleware/
│   │   ├── validators/
│   │   └── views/
│   ├── application/
│   │   ├── services/
│   │   ├── use-cases/
│   │   └── dtos/
│   ├── domain/
│   │   ├── entities/
│   │   ├── value-objects/
│   │   ├── events/
│   │   └── repositories/
│   └── infrastructure/
│       ├── database/
│       ├── repositories/
│       ├── external/
│       └── config/
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── database/
│   ├── migrations/
│   └── seeds/
├── public/
├── docs/
└── config/
```

## Clean Architecture Implementation

### Domain Layer (Core Business Logic)

```typescript
// domain/entities/Article.ts
export class Article {
  private constructor(
    private readonly id: ArticleId,
    private title: Title,
    private content: Content,
    private author: Author,
    private status: ArticleStatus,
    private readonly createdAt: Date,
    private updatedAt: Date
  ) {}

  static create(props: CreateArticleProps): Article {
    const articleId = ArticleId.generate();
    const title = new Title(props.title);
    const content = new Content(props.content);
    const author = new Author(props.authorId);
    
    return new Article(
      articleId,
      title,
      content,
      author,
      ArticleStatus.DRAFT,
      new Date(),
      new Date()
    );
  }

  publish(): void {
    if (this.status !== ArticleStatus.DRAFT) {
      throw new DomainError('Only draft articles can be published');
    }
    
    this.status = ArticleStatus.PUBLISHED;
    this.updatedAt = new Date();
    
    // Raise domain event
    this.addDomainEvent(new ArticlePublishedEvent(this.id, this.author));
  }

  updateContent(title: string, content: string): void {
    this.title = new Title(title);
    this.content = new Content(content);
    this.updatedAt = new Date();
    
    this.addDomainEvent(new ArticleUpdatedEvent(this.id));
  }
}

// domain/value-objects/Title.ts
export class Title {
  private readonly value: string;

  constructor(value: string) {
    if (!value || value.trim().length === 0) {
      throw new DomainError('Title cannot be empty');
    }
    
    if (value.length > 200) {
      throw new DomainError('Title cannot exceed 200 characters');
    }
    
    this.value = value.trim();
  }

  toString(): string {
    return this.value;
  }
}
```

### Application Layer (Use Cases)

```typescript
// application/use-cases/PublishArticle.ts
export class PublishArticleUseCase {
  constructor(
    private articleRepository: ArticleRepository,
    private eventBus: EventBus,
    private notificationService: NotificationService
  ) {}

  async execute(command: PublishArticleCommand): Promise<void> {
    const article = await this.articleRepository.findById(command.articleId);
    
    if (!article) {
      throw new NotFoundError('Article not found');
    }
    
    // Business logic in domain
    article.publish();
    
    // Persist changes
    await this.articleRepository.save(article);
    
    // Publish domain events
    for (const event of article.getUncommittedEvents()) {
      await this.eventBus.publish(event);
    }
    
    // Side effects
    await this.notificationService.notifySubscribers(article);
  }
}

// application/services/ArticleService.ts
export class ArticleService {
  constructor(
    private createArticle: CreateArticleUseCase,
    private publishArticle: PublishArticleUseCase,
    private searchArticles: SearchArticlesUseCase
  ) {}

  async create(dto: CreateArticleDto): Promise<ArticleDto> {
    const result = await this.createArticle.execute({
      title: dto.title,
      content: dto.content,
      authorId: dto.authorId
    });
    
    return this.mapToDto(result);
  }

  async publish(articleId: string): Promise<void> {
    await this.publishArticle.execute({ articleId });
  }

  async search(criteria: SearchCriteria): Promise<ArticleListDto> {
    const results = await this.searchArticles.execute(criteria);
    return {
      items: results.items.map(this.mapToDto),
      total: results.total,
      page: results.page,
      pageSize: results.pageSize
    };
  }

  private mapToDto(article: Article): ArticleDto {
    return {
      id: article.id.toString(),
      title: article.title.toString(),
      content: article.content.toString(),
      author: article.author.name,
      status: article.status,
      createdAt: article.createdAt,
      updatedAt: article.updatedAt
    };
  }
}
```

### Infrastructure Layer (External Concerns)

```typescript
// infrastructure/repositories/PostgresArticleRepository.ts
export class PostgresArticleRepository implements ArticleRepository {
  constructor(private db: Database) {}

  async findById(id: ArticleId): Promise<Article | null> {
    const result = await this.db.query(
      'SELECT * FROM articles WHERE id = $1',
      [id.toString()]
    );
    
    if (!result.rows[0]) {
      return null;
    }
    
    return this.mapToDomain(result.rows[0]);
  }

  async save(article: Article): Promise<void> {
    const data = this.mapToDatabase(article);
    
    await this.db.query(
      `INSERT INTO articles (id, title, content, author_id, status, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       ON CONFLICT (id) DO UPDATE
       SET title = EXCLUDED.title,
           content = EXCLUDED.content,
           status = EXCLUDED.status,
           updated_at = EXCLUDED.updated_at`,
      [data.id, data.title, data.content, data.author_id, data.status, data.created_at, data.updated_at]
    );
  }

  async search(criteria: SearchCriteria): Promise<SearchResult<Article>> {
    let query = 'SELECT * FROM articles WHERE 1=1';
    const params: any[] = [];
    
    if (criteria.title) {
      params.push(`%${criteria.title}%`);
      query += ` AND title ILIKE $${params.length}`;
    }
    
    if (criteria.status) {
      params.push(criteria.status);
      query += ` AND status = $${params.length}`;
    }
    
    // Add pagination
    const countResult = await this.db.query(
      query.replace('SELECT *', 'SELECT COUNT(*)'),
      params
    );
    
    params.push(criteria.pageSize, (criteria.page - 1) * criteria.pageSize);
    query += ` ORDER BY created_at DESC LIMIT $${params.length - 1} OFFSET $${params.length}`;
    
    const result = await this.db.query(query, params);
    
    return {
      items: result.rows.map(this.mapToDomain),
      total: parseInt(countResult.rows[0].count),
      page: criteria.page,
      pageSize: criteria.pageSize
    };
  }

  private mapToDomain(row: any): Article {
    // Map database row to domain entity
    return Article.reconstitute({
      id: new ArticleId(row.id),
      title: new Title(row.title),
      content: new Content(row.content),
      author: new Author(row.author_id),
      status: row.status as ArticleStatus,
      createdAt: row.created_at,
      updatedAt: row.updated_at
    });
  }

  private mapToDatabase(article: Article): any {
    // Map domain entity to database row
    return {
      id: article.id.toString(),
      title: article.title.toString(),
      content: article.content.toString(),
      author_id: article.author.id,
      status: article.status,
      created_at: article.createdAt,
      updated_at: article.updatedAt
    };
  }
}
```

### Presentation Layer (HTTP/API)

```typescript
// presentation/controllers/ArticleController.ts
@Controller('/articles')
export class ArticleController {
  constructor(private articleService: ArticleService) {}

  @Post('/')
  @UseGuards(AuthGuard)
  @UseValidation(CreateArticleValidator)
  async createArticle(
    @Body() dto: CreateArticleDto,
    @CurrentUser() user: User
  ): Promise<ApiResponse<ArticleDto>> {
    const article = await this.articleService.create({
      ...dto,
      authorId: user.id
    });
    
    return {
      success: true,
      data: article
    };
  }

  @Put('/:id/publish')
  @UseGuards(AuthGuard, PermissionGuard('publish_article'))
  async publishArticle(
    @Param('id') id: string
  ): Promise<ApiResponse<void>> {
    await this.articleService.publish(id);
    
    return {
      success: true,
      message: 'Article published successfully'
    };
  }

  @Get('/')
  @UseCache(300) // 5 minutes
  async searchArticles(
    @Query() query: SearchArticlesQuery
  ): Promise<ApiResponse<ArticleListDto>> {
    const results = await this.articleService.search({
      title: query.title,
      status: query.status,
      page: query.page || 1,
      pageSize: query.pageSize || 20
    });
    
    return {
      success: true,
      data: results
    };
  }

  @Get('/:id')
  @UseCache(600) // 10 minutes
  async getArticle(
    @Param('id') id: string
  ): Promise<ApiResponse<ArticleDto>> {
    const article = await this.articleService.findById(id);
    
    if (!article) {
      throw new NotFoundException('Article not found');
    }
    
    return {
      success: true,
      data: article
    };
  }
}
```

## Module Organization

### Dependency Injection Container

```typescript
// infrastructure/container/Container.ts
export class Container {
  private services = new Map<string, any>();
  
  register<T>(token: string, factory: () => T): void {
    this.services.set(token, factory);
  }
  
  resolve<T>(token: string): T {
    const factory = this.services.get(token);
    if (!factory) {
      throw new Error(`Service ${token} not registered`);
    }
    return factory();
  }
}

// infrastructure/container/setup.ts
export function setupContainer(): Container {
  const container = new Container();
  
  // Infrastructure
  container.register('Database', () => new PostgresDatabase(config.database));
  container.register('EventBus', () => new InMemoryEventBus());
  container.register('Cache', () => new RedisCache(config.redis));
  
  // Repositories
  container.register('ArticleRepository', () => 
    new PostgresArticleRepository(container.resolve('Database'))
  );
  
  // Use Cases
  container.register('CreateArticleUseCase', () =>
    new CreateArticleUseCase(
      container.resolve('ArticleRepository'),
      container.resolve('EventBus')
    )
  );
  
  // Services
  container.register('ArticleService', () =>
    new ArticleService(
      container.resolve('CreateArticleUseCase'),
      container.resolve('PublishArticleUseCase'),
      container.resolve('SearchArticlesUseCase')
    )
  );
  
  // Controllers
  container.register('ArticleController', () =>
    new ArticleController(container.resolve('ArticleService'))
  );
  
  return container;
}
```

## Configuration Management

### Environment Configuration

```typescript
// config/index.ts
export const config = {
  app: {
    name: process.env.APP_NAME || 'CMS Monolith',
    env: process.env.NODE_ENV || 'development',
    port: parseInt(process.env.PORT || '3000'),
    baseUrl: process.env.BASE_URL || 'http://localhost:3000'
  },
  database: {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432'),
    user: process.env.DB_USER || 'cms_user',
    password: process.env.DB_PASSWORD || 'password',
    database: process.env.DB_NAME || 'cms_db',
    pool: {
      min: 5,
      max: 20,
      idleTimeoutMillis: 30000
    }
  },
  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT || '6379'),
    password: process.env.REDIS_PASSWORD,
    db: parseInt(process.env.REDIS_DB || '0')
  },
  auth: {
    jwtSecret: process.env.JWT_SECRET || 'development-secret',
    jwtExpiry: process.env.JWT_EXPIRY || '24h',
    bcryptRounds: parseInt(process.env.BCRYPT_ROUNDS || '10')
  },
  email: {
    provider: process.env.EMAIL_PROVIDER || 'smtp',
    smtp: {
      host: process.env.SMTP_HOST,
      port: parseInt(process.env.SMTP_PORT || '587'),
      secure: process.env.SMTP_SECURE === 'true',
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS
      }
    }
  }
};
```

## Database Design

### Schema Definition

```sql
-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'user',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Articles table
CREATE TABLE articles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    author_id UUID NOT NULL REFERENCES users(id),
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    published_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Categories table
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) UNIQUE NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Article categories (many-to-many)
CREATE TABLE article_categories (
    article_id UUID NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    PRIMARY KEY (article_id, category_id)
);

-- Comments table
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    article_id UUID NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id),
    content TEXT NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_articles_author_id ON articles(author_id);
CREATE INDEX idx_articles_status ON articles(status);
CREATE INDEX idx_articles_created_at ON articles(created_at DESC);
CREATE INDEX idx_comments_article_id ON comments(article_id);
CREATE INDEX idx_comments_user_id ON comments(user_id);
```

## Testing Strategy

### Unit Tests

```typescript
// tests/unit/domain/entities/Article.test.ts
describe('Article Entity', () => {
  describe('create', () => {
    it('should create a new article with draft status', () => {
      const article = Article.create({
        title: 'Test Article',
        content: 'Test content',
        authorId: 'author-123'
      });
      
      expect(article.status).toBe(ArticleStatus.DRAFT);
      expect(article.title.toString()).toBe('Test Article');
      expect(article.getUncommittedEvents()).toHaveLength(1);
    });
    
    it('should throw error for invalid title', () => {
      expect(() => {
        Article.create({
          title: '',
          content: 'Test content',
          authorId: 'author-123'
        });
      }).toThrow(DomainError);
    });
  });
  
  describe('publish', () => {
    it('should publish a draft article', () => {
      const article = Article.create({
        title: 'Test Article',
        content: 'Test content',
        authorId: 'author-123'
      });
      
      article.publish();
      
      expect(article.status).toBe(ArticleStatus.PUBLISHED);
      expect(article.getUncommittedEvents()).toHaveLength(2);
    });
    
    it('should throw error when publishing non-draft article', () => {
      const article = createPublishedArticle();
      
      expect(() => article.publish()).toThrow(DomainError);
    });
  });
});
```

### Integration Tests

```typescript
// tests/integration/ArticleService.test.ts
describe('ArticleService Integration', () => {
  let service: ArticleService;
  let database: Database;
  
  beforeAll(async () => {
    database = await setupTestDatabase();
    const container = setupTestContainer(database);
    service = container.resolve('ArticleService');
  });
  
  afterAll(async () => {
    await database.close();
  });
  
  describe('create and publish article flow', () => {
    it('should create and publish an article', async () => {
      // Create article
      const createDto = {
        title: 'Integration Test Article',
        content: 'Test content',
        authorId: 'test-author'
      };
      
      const created = await service.create(createDto);
      expect(created.id).toBeDefined();
      expect(created.status).toBe('draft');
      
      // Publish article
      await service.publish(created.id);
      
      // Verify published
      const published = await service.findById(created.id);
      expect(published.status).toBe('published');
    });
  });
});
```

## Performance Optimization

### Caching Strategy

```typescript
// infrastructure/cache/CacheDecorator.ts
export function Cacheable(ttl: number = 300) {
  return function (target: any, propertyName: string, descriptor: PropertyDescriptor) {
    const originalMethod = descriptor.value;
    
    descriptor.value = async function (...args: any[]) {
      const cache = this.cache || Container.resolve('Cache');
      const key = `${target.constructor.name}:${propertyName}:${JSON.stringify(args)}`;
      
      // Check cache
      const cached = await cache.get(key);
      if (cached) {
        return cached;
      }
      
      // Execute method
      const result = await originalMethod.apply(this, args);
      
      // Cache result
      await cache.set(key, result, ttl);
      
      return result;
    };
    
    return descriptor;
  };
}

// Usage
class ArticleService {
  @Cacheable(600) // 10 minutes
  async findById(id: string): Promise<ArticleDto> {
    // Method implementation
  }
  
  @Cacheable(300) // 5 minutes
  async search(criteria: SearchCriteria): Promise<ArticleListDto> {
    // Method implementation
  }
}
```

### Database Query Optimization

```typescript
// infrastructure/database/QueryBuilder.ts
export class QueryBuilder {
  private query: string = '';
  private params: any[] = [];
  
  select(fields: string[]): this {
    this.query = `SELECT ${fields.join(', ')}`;
    return this;
  }
  
  from(table: string): this {
    this.query += ` FROM ${table}`;
    return this;
  }
  
  where(conditions: Record<string, any>): this {
    const whereClauses = Object.entries(conditions)
      .map(([key, value]) => {
        this.params.push(value);
        return `${key} = $${this.params.length}`;
      })
      .join(' AND ');
    
    this.query += ` WHERE ${whereClauses}`;
    return this;
  }
  
  orderBy(field: string, direction: 'ASC' | 'DESC' = 'ASC'): this {
    this.query += ` ORDER BY ${field} ${direction}`;
    return this;
  }
  
  limit(count: number): this {
    this.params.push(count);
    this.query += ` LIMIT $${this.params.length}`;
    return this;
  }
  
  offset(count: number): this {
    this.params.push(count);
    this.query += ` OFFSET $${this.params.length}`;
    return this;
  }
  
  build(): { query: string; params: any[] } {
    return { query: this.query, params: this.params };
  }
}
```

## Deployment

### Docker Configuration

```dockerfile
# Dockerfile
FROM node:18-alpine AS builder

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy source
COPY . .

# Build application
RUN npm run build

# Production image
FROM node:18-alpine

WORKDIR /app

# Copy built application
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001
USER nodejs

EXPOSE 3000

CMD ["node", "dist/index.js"]
```

### Production Configuration

```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://user:pass@db:5432/cms
      - REDIS_URL=redis://cache:6379
    depends_on:
      - db
      - cache
    restart: unless-stopped

  db:
    image: postgres:15
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=cms
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
    restart: unless-stopped

  cache:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - app
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:
```

## Monitoring and Observability

### Application Metrics

```typescript
// infrastructure/monitoring/Metrics.ts
import { Counter, Histogram, register } from 'prom-client';

export class Metrics {
  private static httpRequestDuration = new Histogram({
    name: 'http_request_duration_seconds',
    help: 'Duration of HTTP requests in seconds',
    labelNames: ['method', 'route', 'status'],
    buckets: [0.1, 0.5, 1, 2, 5]
  });

  private static httpRequestTotal = new Counter({
    name: 'http_request_total',
    help: 'Total number of HTTP requests',
    labelNames: ['method', 'route', 'status']
  });

  private static businessMetrics = new Counter({
    name: 'business_operations_total',
    help: 'Total number of business operations',
    labelNames: ['operation', 'status']
  });

  static recordHttpRequest(method: string, route: string, status: number, duration: number): void {
    this.httpRequestDuration.observe({ method, route, status }, duration);
    this.httpRequestTotal.inc({ method, route, status });
  }

  static recordBusinessOperation(operation: string, status: 'success' | 'failure'): void {
    this.businessMetrics.inc({ operation, status });
  }

  static getMetrics(): string {
    return register.metrics();
  }
}
```

## Benefits of Well-Structured Monolith

### Advantages Realized
1. **Simplicity**: Single deployment unit, easier to understand
2. **Performance**: No network latency between components
3. **Data Consistency**: ACID transactions across all operations
4. **Development Speed**: Faster initial development
5. **Debugging**: Easier to trace issues

### Clean Architecture Benefits
1. **Testability**: Each layer can be tested independently
2. **Flexibility**: Easy to swap implementations
3. **Maintainability**: Clear separation of concerns
4. **Evolvability**: Can be split into microservices later

### When to Use
- Small to medium-sized applications
- Single development team
- Limited scaling requirements
- Rapid prototyping needed
- Strong consistency requirements

### Migration Path
The clean architecture makes it easier to migrate to microservices later:
1. Each bounded context can become a service
2. Use cases can be exposed as APIs
3. Domain events can become integration events
4. Repositories can be adapted for remote calls