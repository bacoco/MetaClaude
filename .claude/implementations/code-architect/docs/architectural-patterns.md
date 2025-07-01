# Architectural Patterns Guide

## Overview
This guide provides comprehensive documentation of architectural patterns supported by the Code Architect specialist. Each pattern includes implementation details, use cases, benefits, and trade-offs to help teams make informed architectural decisions.

## Pattern Categories

### 1. Application Architecture Patterns

#### Monolithic Architecture
**Description**: A single deployable unit containing all application functionality.

**Structure**:
```
monolithic-app/
├── src/
│   ├── controllers/      # Request handling
│   ├── services/        # Business logic
│   ├── repositories/    # Data access
│   ├── models/          # Domain models
│   └── utils/           # Shared utilities
├── database/            # Database scripts
├── tests/              # All tests
└── config/             # Configuration
```

**When to Use**:
- Small to medium applications
- Single development team
- Rapid prototyping
- Limited scalability requirements

**Benefits**:
- Simple development and deployment
- Easy debugging and testing
- Single codebase to maintain
- No network latency between components

**Trade-offs**:
- Difficult to scale specific components
- Technology lock-in
- Large codebase can become complex
- Single point of failure

**Implementation Example**:
```typescript
// Monolithic application structure
class Application {
  private userService: UserService;
  private orderService: OrderService;
  private productService: ProductService;
  
  constructor() {
    const database = new Database(config.database);
    
    // All services in single process
    this.userService = new UserService(database);
    this.orderService = new OrderService(database);
    this.productService = new ProductService(database);
  }
  
  start(): void {
    const app = express();
    
    // All routes in single application
    app.use('/users', userRoutes(this.userService));
    app.use('/orders', orderRoutes(this.orderService));
    app.use('/products', productRoutes(this.productService));
    
    app.listen(config.port);
  }
}
```

#### Microservices Architecture
**Description**: Application composed of small, independent services that communicate over network protocols.

**Structure**:
```
microservices/
├── services/
│   ├── user-service/
│   │   ├── src/
│   │   ├── tests/
│   │   └── Dockerfile
│   ├── order-service/
│   │   ├── src/
│   │   ├── tests/
│   │   └── Dockerfile
│   └── product-service/
│       ├── src/
│       ├── tests/
│       └── Dockerfile
├── api-gateway/
├── docker-compose.yml
└── kubernetes/
```

**When to Use**:
- Large, complex applications
- Multiple development teams
- Different scaling requirements per component
- Need for technology diversity

**Benefits**:
- Independent scaling
- Technology flexibility
- Fault isolation
- Parallel development

**Trade-offs**:
- Increased complexity
- Network latency
- Data consistency challenges
- Operational overhead

**Implementation Example**:
```typescript
// User Service
@Controller()
export class UserService {
  constructor(
    private readonly database: UserDatabase,
    private readonly messageQueue: MessageQueue
  ) {}
  
  @Post('/users')
  async createUser(data: CreateUserDto): Promise<User> {
    const user = await this.database.create(data);
    
    // Async communication with other services
    await this.messageQueue.publish('user.created', {
      userId: user.id,
      email: user.email
    });
    
    return user;
  }
}

// Order Service (separate deployment)
@Controller()
export class OrderService {
  constructor(
    private readonly database: OrderDatabase,
    private readonly userClient: UserServiceClient
  ) {}
  
  @Post('/orders')
  async createOrder(data: CreateOrderDto): Promise<Order> {
    // Sync communication with user service
    const user = await this.userClient.getUser(data.userId);
    
    if (!user) {
      throw new NotFoundException('User not found');
    }
    
    return this.database.create({
      ...data,
      userEmail: user.email
    });
  }
}
```

#### Event-Driven Architecture
**Description**: Architecture pattern where components communicate through events rather than direct calls.

**Structure**:
```
event-driven/
├── services/
│   ├── event-producer/
│   ├── event-consumer/
│   └── event-processor/
├── event-bus/
│   ├── kafka/
│   └── schema-registry/
├── event-store/
└── monitoring/
```

**When to Use**:
- Highly decoupled systems
- Real-time data processing
- Complex event flows
- Audit trail requirements

**Benefits**:
- Loose coupling
- High scalability
- Real-time processing
- Event sourcing capability

**Trade-offs**:
- Eventual consistency
- Complex debugging
- Event ordering challenges
- Infrastructure complexity

**Implementation Example**:
```typescript
// Event definitions
interface OrderEvent {
  eventId: string;
  timestamp: Date;
  aggregateId: string;
  eventType: string;
  payload: any;
}

// Event Producer
class OrderService {
  constructor(private eventBus: EventBus) {}
  
  async createOrder(data: CreateOrderDto): Promise<void> {
    const order = await this.processOrder(data);
    
    // Publish event
    await this.eventBus.publish({
      eventType: 'OrderCreated',
      aggregateId: order.id,
      payload: {
        orderId: order.id,
        customerId: order.customerId,
        total: order.total,
        items: order.items
      }
    });
  }
}

// Event Consumer
class InventoryService {
  constructor(private eventBus: EventBus) {
    this.eventBus.subscribe('OrderCreated', this.handleOrderCreated.bind(this));
  }
  
  async handleOrderCreated(event: OrderEvent): Promise<void> {
    const { items } = event.payload;
    
    // Update inventory based on order
    for (const item of items) {
      await this.updateStock(item.productId, -item.quantity);
    }
    
    // Publish inventory updated event
    await this.eventBus.publish({
      eventType: 'InventoryUpdated',
      aggregateId: event.aggregateId,
      payload: { orderId: event.aggregateId, items }
    });
  }
}
```

### 2. Design Principles

#### SOLID Principles

**Single Responsibility Principle (SRP)**
```typescript
// Bad: Multiple responsibilities
class User {
  constructor(public email: string) {}
  
  save(): void {
    // Database logic
  }
  
  sendEmail(): void {
    // Email logic
  }
  
  validateEmail(): boolean {
    // Validation logic
  }
}

// Good: Single responsibility
class User {
  constructor(public email: string) {}
}

class UserRepository {
  save(user: User): void {
    // Database logic only
  }
}

class EmailService {
  send(to: string, subject: string, body: string): void {
    // Email logic only
  }
}

class EmailValidator {
  validate(email: string): boolean {
    // Validation logic only
  }
}
```

**Open/Closed Principle (OCP)**
```typescript
// Bad: Modification required for new types
class DiscountCalculator {
  calculate(customerType: string, amount: number): number {
    if (customerType === 'regular') {
      return amount * 0.9;
    } else if (customerType === 'vip') {
      return amount * 0.8;
    }
    return amount;
  }
}

// Good: Open for extension, closed for modification
interface DiscountStrategy {
  calculate(amount: number): number;
}

class RegularDiscount implements DiscountStrategy {
  calculate(amount: number): number {
    return amount * 0.9;
  }
}

class VIPDiscount implements DiscountStrategy {
  calculate(amount: number): number {
    return amount * 0.8;
  }
}

class DiscountCalculator {
  constructor(private strategy: DiscountStrategy) {}
  
  calculate(amount: number): number {
    return this.strategy.calculate(amount);
  }
}
```

**Liskov Substitution Principle (LSP)**
```typescript
// Bad: Subclass changes behavior
class Rectangle {
  constructor(protected width: number, protected height: number) {}
  
  setWidth(width: number): void {
    this.width = width;
  }
  
  setHeight(height: number): void {
    this.height = height;
  }
  
  getArea(): number {
    return this.width * this.height;
  }
}

class Square extends Rectangle {
  setWidth(width: number): void {
    this.width = width;
    this.height = width; // Breaks LSP
  }
  
  setHeight(height: number): void {
    this.width = height;
    this.height = height; // Breaks LSP
  }
}

// Good: Proper abstraction
interface Shape {
  getArea(): number;
}

class Rectangle implements Shape {
  constructor(private width: number, private height: number) {}
  
  getArea(): number {
    return this.width * this.height;
  }
}

class Square implements Shape {
  constructor(private side: number) {}
  
  getArea(): number {
    return this.side * this.side;
  }
}
```

**Interface Segregation Principle (ISP)**
```typescript
// Bad: Fat interface
interface Worker {
  work(): void;
  eat(): void;
  sleep(): void;
}

class Human implements Worker {
  work(): void { /* ... */ }
  eat(): void { /* ... */ }
  sleep(): void { /* ... */ }
}

class Robot implements Worker {
  work(): void { /* ... */ }
  eat(): void { throw new Error('Robots don\'t eat'); }
  sleep(): void { throw new Error('Robots don\'t sleep'); }
}

// Good: Segregated interfaces
interface Workable {
  work(): void;
}

interface Eatable {
  eat(): void;
}

interface Sleepable {
  sleep(): void;
}

class Human implements Workable, Eatable, Sleepable {
  work(): void { /* ... */ }
  eat(): void { /* ... */ }
  sleep(): void { /* ... */ }
}

class Robot implements Workable {
  work(): void { /* ... */ }
}
```

**Dependency Inversion Principle (DIP)**
```typescript
// Bad: High-level depends on low-level
class EmailService {
  send(message: string): void {
    const smtp = new SMTPClient(); // Direct dependency
    smtp.sendEmail(message);
  }
}

// Good: Depend on abstractions
interface EmailClient {
  send(message: string): void;
}

class SMTPClient implements EmailClient {
  send(message: string): void {
    // SMTP implementation
  }
}

class SendGridClient implements EmailClient {
  send(message: string): void {
    // SendGrid implementation
  }
}

class EmailService {
  constructor(private client: EmailClient) {} // Dependency injection
  
  send(message: string): void {
    this.client.send(message);
  }
}
```

### 3. Data Management Patterns

#### Repository Pattern
**Description**: Encapsulates data access logic and provides a more object-oriented view of the persistence layer.

```typescript
// Repository interface
interface UserRepository {
  findById(id: string): Promise<User | null>;
  findByEmail(email: string): Promise<User | null>;
  save(user: User): Promise<User>;
  delete(id: string): Promise<void>;
}

// Implementation
class PostgresUserRepository implements UserRepository {
  constructor(private db: Database) {}
  
  async findById(id: string): Promise<User | null> {
    const result = await this.db.query(
      'SELECT * FROM users WHERE id = $1',
      [id]
    );
    return result.rows[0] ? this.mapToUser(result.rows[0]) : null;
  }
  
  async save(user: User): Promise<User> {
    if (user.id) {
      return this.update(user);
    }
    return this.create(user);
  }
  
  private mapToUser(row: any): User {
    return new User(row.id, row.email, row.name);
  }
}
```

#### Unit of Work Pattern
**Description**: Maintains a list of objects affected by a business transaction and coordinates writing out changes.

```typescript
interface UnitOfWork {
  registerNew(entity: Entity): void;
  registerDirty(entity: Entity): void;
  registerDeleted(entity: Entity): void;
  commit(): Promise<void>;
  rollback(): Promise<void>;
}

class DatabaseUnitOfWork implements UnitOfWork {
  private newEntities: Entity[] = [];
  private dirtyEntities: Entity[] = [];
  private deletedEntities: Entity[] = [];
  
  registerNew(entity: Entity): void {
    this.newEntities.push(entity);
  }
  
  registerDirty(entity: Entity): void {
    if (!this.dirtyEntities.includes(entity)) {
      this.dirtyEntities.push(entity);
    }
  }
  
  registerDeleted(entity: Entity): void {
    this.deletedEntities.push(entity);
  }
  
  async commit(): Promise<void> {
    const transaction = await this.db.beginTransaction();
    
    try {
      // Insert new entities
      for (const entity of this.newEntities) {
        await this.insert(entity, transaction);
      }
      
      // Update dirty entities
      for (const entity of this.dirtyEntities) {
        await this.update(entity, transaction);
      }
      
      // Delete removed entities
      for (const entity of this.deletedEntities) {
        await this.delete(entity, transaction);
      }
      
      await transaction.commit();
      this.clear();
    } catch (error) {
      await transaction.rollback();
      throw error;
    }
  }
  
  private clear(): void {
    this.newEntities = [];
    this.dirtyEntities = [];
    this.deletedEntities = [];
  }
}
```

### 4. Integration Patterns

#### API Gateway Pattern
**Description**: Single entry point for all client requests, handling routing, composition, and protocol translation.

```typescript
class APIGateway {
  constructor(
    private userService: ServiceClient,
    private orderService: ServiceClient,
    private productService: ServiceClient
  ) {}
  
  // Aggregation
  async getUserDashboard(userId: string): Promise<Dashboard> {
    const [user, orders, recommendations] = await Promise.all([
      this.userService.get(`/users/${userId}`),
      this.orderService.get(`/users/${userId}/orders`),
      this.productService.get(`/users/${userId}/recommendations`)
    ]);
    
    return {
      user,
      recentOrders: orders.slice(0, 5),
      recommendations
    };
  }
  
  // Protocol translation
  async handleWebSocketMessage(message: WSMessage): Promise<void> {
    const httpRequest = this.translateToHTTP(message);
    const response = await this.routeRequest(httpRequest);
    await this.sendWebSocketResponse(message.clientId, response);
  }
  
  // Rate limiting
  async handleRequest(request: Request): Promise<Response> {
    const rateLimitOk = await this.rateLimiter.check(request.userId);
    if (!rateLimitOk) {
      return new Response(429, 'Too Many Requests');
    }
    
    return this.routeRequest(request);
  }
}
```

#### Circuit Breaker Pattern
**Description**: Prevents cascading failures by monitoring for failures and temporarily blocking requests to failing services.

```typescript
class CircuitBreaker {
  private failures = 0;
  private lastFailureTime: Date | null = null;
  private state: 'CLOSED' | 'OPEN' | 'HALF_OPEN' = 'CLOSED';
  
  constructor(
    private threshold = 5,
    private timeout = 60000, // 1 minute
    private resetTimeout = 120000 // 2 minutes
  ) {}
  
  async call<T>(fn: () => Promise<T>): Promise<T> {
    if (this.state === 'OPEN') {
      if (Date.now() - this.lastFailureTime!.getTime() > this.resetTimeout) {
        this.state = 'HALF_OPEN';
      } else {
        throw new Error('Circuit breaker is OPEN');
      }
    }
    
    try {
      const result = await fn();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }
  
  private onSuccess(): void {
    this.failures = 0;
    this.state = 'CLOSED';
  }
  
  private onFailure(): void {
    this.failures++;
    this.lastFailureTime = new Date();
    
    if (this.failures >= this.threshold) {
      this.state = 'OPEN';
    }
  }
}

// Usage
const circuitBreaker = new CircuitBreaker();
const userService = {
  getUser: async (id: string) => {
    return circuitBreaker.call(() => 
      fetch(`https://api.example.com/users/${id}`)
    );
  }
};
```

## Pattern Selection Guide

### Decision Matrix
```
┌─────────────────────┬────────────┬───────────────┬──────────────┐
│ Requirement         │ Monolithic │ Microservices │ Event-Driven │
├─────────────────────┼────────────┼───────────────┼──────────────┤
│ Simple deployment   │ ✓✓✓        │ ✗             │ ✗            │
│ Independent scaling │ ✗          │ ✓✓✓           │ ✓✓           │
│ Technology diversity│ ✗          │ ✓✓✓           │ ✓✓           │
│ Real-time processing│ ✓          │ ✓✓            │ ✓✓✓          │
│ Team autonomy       │ ✗          │ ✓✓✓           │ ✓✓           │
│ Data consistency    │ ✓✓✓        │ ✓             │ ✗            │
│ Operational simple  │ ✓✓✓        │ ✗             │ ✗            │
└─────────────────────┴────────────┴───────────────┴──────────────┘
```

### Pattern Combinations
1. **Microservices + Event-Driven**: Maximum decoupling and scalability
2. **Monolithic + CQRS**: Read/write optimization in single deployment
3. **API Gateway + Circuit Breaker**: Resilient service communication
4. **Repository + Unit of Work**: Clean data access layer

## Implementation Checklist

### Before Implementation
- [ ] Requirements clearly defined
- [ ] Team skills assessment completed
- [ ] Infrastructure requirements evaluated
- [ ] Cost-benefit analysis performed

### During Implementation
- [ ] Follow pattern guidelines strictly
- [ ] Document deviations and reasons
- [ ] Implement monitoring from start
- [ ] Regular architecture reviews

### After Implementation
- [ ] Performance benchmarks met
- [ ] Scalability tested
- [ ] Documentation complete
- [ ] Team trained on pattern