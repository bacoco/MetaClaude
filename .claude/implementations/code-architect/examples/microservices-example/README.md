# Microservices Architecture Example

## Overview
This example demonstrates a microservices architecture implementation for an e-commerce platform using the Code Architect patterns and best practices.

## Architecture Overview

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   API Gateway   │     │  Load Balancer  │     │   Web Client    │
└────────┬────────┘     └────────┬────────┘     └────────┬────────┘
         │                       │                         │
         └───────────────────────┴─────────────────────────┘
                                 │
         ┌───────────────────────┴─────────────────────────┐
         │                                                 │
    ┌────▼─────┐  ┌──────▼──────┐  ┌──────▼──────┐  ┌────▼─────┐
    │   User   │  │   Product   │  │    Order    │  │ Payment  │
    │ Service  │  │   Service   │  │   Service   │  │ Service  │
    └────┬─────┘  └──────┬──────┘  └──────┬──────┘  └────┬─────┘
         │               │                 │               │
    ┌────▼─────┐  ┌──────▼──────┐  ┌──────▼──────┐  ┌────▼─────┐
    │PostgreSQL│  │  MongoDB    │  │ PostgreSQL  │  │  Redis   │
    └──────────┘  └─────────────┘  └─────────────┘  └──────────┘
```

## Services

### 1. User Service
- **Responsibility**: User authentication, profile management
- **Technology**: Node.js + Express + PostgreSQL
- **Port**: 3001
- **Endpoints**:
  - POST /auth/register
  - POST /auth/login
  - GET /users/:id
  - PUT /users/:id

### 2. Product Service
- **Responsibility**: Product catalog, inventory management
- **Technology**: Node.js + Express + MongoDB
- **Port**: 3002
- **Endpoints**:
  - GET /products
  - GET /products/:id
  - POST /products (admin)
  - PUT /products/:id/inventory

### 3. Order Service
- **Responsibility**: Order processing, order history
- **Technology**: Node.js + Express + PostgreSQL
- **Port**: 3003
- **Endpoints**:
  - POST /orders
  - GET /orders/:id
  - GET /users/:userId/orders
  - PUT /orders/:id/status

### 4. Payment Service
- **Responsibility**: Payment processing, transaction history
- **Technology**: Node.js + Express + Redis
- **Port**: 3004
- **Endpoints**:
  - POST /payments
  - GET /payments/:id
  - POST /payments/refund

## Communication Patterns

### Synchronous Communication (REST)
```typescript
// Order Service calling User Service
class OrderService {
  async createOrder(orderData: CreateOrderDto): Promise<Order> {
    // Validate user exists
    const user = await this.httpClient.get(
      `http://user-service:3001/users/${orderData.userId}`
    );
    
    if (!user) {
      throw new NotFoundException('User not found');
    }
    
    // Create order
    return this.orderRepository.create(orderData);
  }
}
```

### Asynchronous Communication (Events)
```typescript
// Order Service publishing event
class OrderService {
  async createOrder(orderData: CreateOrderDto): Promise<Order> {
    const order = await this.orderRepository.create(orderData);
    
    // Publish event for other services
    await this.eventBus.publish('order.created', {
      orderId: order.id,
      userId: order.userId,
      items: order.items,
      total: order.total
    });
    
    return order;
  }
}

// Inventory Service consuming event
class InventoryService {
  constructor() {
    this.eventBus.subscribe('order.created', this.handleOrderCreated);
  }
  
  async handleOrderCreated(event: OrderCreatedEvent): Promise<void> {
    // Update inventory levels
    for (const item of event.items) {
      await this.updateInventory(item.productId, -item.quantity);
    }
  }
}
```

## Deployment Configuration

### Docker Compose
```yaml
version: '3.8'

services:
  api-gateway:
    build: ./api-gateway
    ports:
      - "3000:3000"
    environment:
      - SERVICE_URLS={"user":"http://user-service:3001","product":"http://product-service:3002"}
    depends_on:
      - user-service
      - product-service
      - order-service
      - payment-service

  user-service:
    build: ./services/user-service
    environment:
      - DATABASE_URL=postgresql://user:pass@user-db:5432/users
      - JWT_SECRET=${JWT_SECRET}
    depends_on:
      - user-db
      - rabbitmq

  product-service:
    build: ./services/product-service
    environment:
      - MONGODB_URL=mongodb://product-db:27017/products
    depends_on:
      - product-db
      - rabbitmq

  order-service:
    build: ./services/order-service
    environment:
      - DATABASE_URL=postgresql://user:pass@order-db:5432/orders
    depends_on:
      - order-db
      - rabbitmq

  payment-service:
    build: ./services/payment-service
    environment:
      - REDIS_URL=redis://payment-cache:6379
      - STRIPE_KEY=${STRIPE_KEY}
    depends_on:
      - payment-cache
      - rabbitmq

  # Databases
  user-db:
    image: postgres:15
    environment:
      - POSTGRES_DB=users
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass

  product-db:
    image: mongo:6
    environment:
      - MONGO_INITDB_DATABASE=products

  order-db:
    image: postgres:15
    environment:
      - POSTGRES_DB=orders
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass

  payment-cache:
    image: redis:7

  # Message Queue
  rabbitmq:
    image: rabbitmq:3-management
    ports:
      - "5672:5672"
      - "15672:15672"
```

### Kubernetes Configuration
```yaml
# user-service-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
spec:
  replicas: 3
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
    spec:
      containers:
      - name: user-service
        image: myregistry/user-service:latest
        ports:
        - containerPort: 3001
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: user-db-secret
              key: url
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: user-service
spec:
  selector:
    app: user-service
  ports:
  - port: 3001
    targetPort: 3001
```

## Patterns Implemented

### 1. API Gateway Pattern
- Single entry point for clients
- Request routing and aggregation
- Authentication and rate limiting

### 2. Database per Service
- Each service owns its data
- No direct database access between services
- Data consistency through events

### 3. Event Sourcing
- Order service stores events
- Enables audit trail
- Supports event replay

### 4. Circuit Breaker
- Prevents cascading failures
- Implements fallback mechanisms
- Monitors service health

### 5. Service Discovery
- Dynamic service registration
- Health checking
- Load balancing

## Security Implementation

### JWT Authentication
```typescript
// Middleware in API Gateway
export async function authenticate(req: Request, res: Response, next: NextFunction) {
  const token = req.headers.authorization?.split(' ')[1];
  
  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }
  
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid token' });
  }
}
```

### Service-to-Service Authentication
```typescript
// Internal service communication
class ServiceClient {
  constructor(private serviceName: string) {}
  
  async request(path: string, options: RequestOptions = {}): Promise<any> {
    const internalToken = this.generateInternalToken();
    
    return fetch(`http://${this.serviceName}${path}`, {
      ...options,
      headers: {
        ...options.headers,
        'X-Internal-Token': internalToken
      }
    });
  }
  
  private generateInternalToken(): string {
    return jwt.sign(
      { service: process.env.SERVICE_NAME },
      process.env.INTERNAL_SECRET,
      { expiresIn: '1m' }
    );
  }
}
```

## Monitoring and Observability

### Distributed Tracing
```typescript
// Trace context propagation
import { trace, context } from '@opentelemetry/api';

export function traceMiddleware(req: Request, res: Response, next: NextFunction) {
  const tracer = trace.getTracer('microservices-example');
  const span = tracer.startSpan(`${req.method} ${req.path}`);
  
  // Add trace context to request
  req.traceId = span.spanContext().traceId;
  
  // Propagate to downstream services
  req.headers['x-trace-id'] = req.traceId;
  
  res.on('finish', () => {
    span.setStatus({ code: res.statusCode < 400 ? 0 : 1 });
    span.end();
  });
  
  next();
}
```

### Metrics Collection
```typescript
import { Counter, Histogram } from 'prom-client';

const httpRequestDuration = new Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status']
});

const httpRequestTotal = new Counter({
  name: 'http_request_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status']
});

export function metricsMiddleware(req: Request, res: Response, next: NextFunction) {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    const labels = {
      method: req.method,
      route: req.route?.path || 'unknown',
      status: res.statusCode
    };
    
    httpRequestDuration.observe(labels, duration);
    httpRequestTotal.inc(labels);
  });
  
  next();
}
```

## Testing Strategy

### Unit Tests
```typescript
// user.service.test.ts
describe('UserService', () => {
  let userService: UserService;
  let mockRepository: jest.Mocked<UserRepository>;
  
  beforeEach(() => {
    mockRepository = createMockRepository();
    userService = new UserService(mockRepository);
  });
  
  describe('createUser', () => {
    it('should create a new user', async () => {
      const userData = { email: 'test@example.com', password: 'password' };
      const hashedPassword = 'hashed_password';
      
      mockRepository.create.mockResolvedValue({
        id: '123',
        ...userData,
        password: hashedPassword
      });
      
      const result = await userService.createUser(userData);
      
      expect(result.id).toBe('123');
      expect(result.email).toBe(userData.email);
      expect(result.password).toBeUndefined(); // Password should not be returned
    });
  });
});
```

### Integration Tests
```typescript
// order-flow.integration.test.ts
describe('Order Flow Integration', () => {
  it('should complete order flow from creation to payment', async () => {
    // Create user
    const user = await createTestUser();
    
    // Create order
    const order = await api.post('/orders', {
      userId: user.id,
      items: [{ productId: 'prod-1', quantity: 2 }]
    });
    
    expect(order.status).toBe(201);
    expect(order.body.status).toBe('pending');
    
    // Process payment
    const payment = await api.post('/payments', {
      orderId: order.body.id,
      amount: order.body.total,
      method: 'card'
    });
    
    expect(payment.status).toBe(200);
    
    // Verify order status updated
    const updatedOrder = await api.get(`/orders/${order.body.id}`);
    expect(updatedOrder.body.status).toBe('paid');
  });
});
```

## Performance Optimization

### Caching Strategy
```typescript
// Redis caching layer
class CacheService {
  constructor(private redis: Redis) {}
  
  async get<T>(key: string): Promise<T | null> {
    const cached = await this.redis.get(key);
    return cached ? JSON.parse(cached) : null;
  }
  
  async set<T>(key: string, value: T, ttl: number = 300): Promise<void> {
    await this.redis.setex(key, ttl, JSON.stringify(value));
  }
  
  async invalidate(pattern: string): Promise<void> {
    const keys = await this.redis.keys(pattern);
    if (keys.length > 0) {
      await this.redis.del(...keys);
    }
  }
}

// Usage in service
class ProductService {
  async getProduct(id: string): Promise<Product> {
    const cacheKey = `product:${id}`;
    
    // Check cache
    const cached = await this.cache.get<Product>(cacheKey);
    if (cached) return cached;
    
    // Fetch from database
    const product = await this.repository.findById(id);
    
    // Cache result
    await this.cache.set(cacheKey, product, 600); // 10 minutes
    
    return product;
  }
}
```

## Running the Example

### Prerequisites
- Docker and Docker Compose
- Node.js 18+
- PostgreSQL client
- MongoDB client
- Redis client

### Setup Instructions
1. Clone the repository
2. Install dependencies: `npm install`
3. Set environment variables: `cp .env.example .env`
4. Start services: `docker-compose up`
5. Run migrations: `npm run migrate`
6. Seed data: `npm run seed`

### Testing the Services
```bash
# Health check
curl http://localhost:3000/health

# Create user
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password"}'

# Login
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password"}'

# Create order (with auth token)
curl -X POST http://localhost:3000/orders \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"items":[{"productId":"prod-1","quantity":2}]}'
```

## Lessons Learned

### Benefits Realized
- Independent deployment and scaling
- Technology diversity (different databases per service)
- Fault isolation
- Team autonomy

### Challenges Faced
- Distributed transaction management
- Data consistency across services
- Increased operational complexity
- Network latency between services

### Best Practices Applied
- API versioning for backward compatibility
- Comprehensive logging and monitoring
- Circuit breakers for resilience
- Event-driven communication for loose coupling
- Automated testing at all levels