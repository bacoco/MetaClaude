# Integration Test Template

## Overview
Integration tests verify that different components or services work correctly together. This template provides patterns for testing interactions between modules, external services, databases, and APIs, ensuring the integrated system functions as expected.

## Core Integration Test Structure

### API Integration Tests (Node.js/Express)
```typescript
// api.integration.test.ts
import request from 'supertest';
import { app } from '../src/app';
import { Database } from '../src/database';
import { RedisClient } from '../src/redis';
import { seedTestData, cleanupTestData } from './helpers/test-data';

describe('User API Integration Tests', () => {
    let db: Database;
    let redis: RedisClient;
    
    beforeAll(async () => {
        // Initialize real test database
        db = await Database.connect(process.env.TEST_DATABASE_URL);
        
        // Initialize real Redis instance
        redis = await RedisClient.connect(process.env.TEST_REDIS_URL);
        
        // Run migrations
        await db.migrate();
    });
    
    afterAll(async () => {
        // Clean up connections
        await db.disconnect();
        await redis.disconnect();
    });
    
    beforeEach(async () => {
        // Seed test data
        await seedTestData(db);
        
        // Clear cache
        await redis.flushAll();
    });
    
    afterEach(async () => {
        // Clean up test data
        await cleanupTestData(db);
    });
    
    describe('POST /api/users', () => {
        it('should create user and send welcome email', async () => {
            // Arrange
            const newUser = {
                email: 'newuser@example.com',
                name: 'New User',
                password: 'SecurePass123!'
            };
            
            // Act
            const response = await request(app)
                .post('/api/users')
                .send(newUser)
                .expect('Content-Type', /json/)
                .expect(201);
            
            // Assert API response
            expect(response.body).toMatchObject({
                id: expect.any(String),
                email: newUser.email,
                name: newUser.name
            });
            expect(response.body).not.toHaveProperty('password');
            
            // Verify database state
            const dbUser = await db.users.findByEmail(newUser.email);
            expect(dbUser).toBeTruthy();
            expect(dbUser.password).not.toBe(newUser.password); // Should be hashed
            
            // Verify cache was updated
            const cachedUser = await redis.get(`user:${response.body.id}`);
            expect(JSON.parse(cachedUser)).toMatchObject({
                id: response.body.id,
                email: newUser.email
            });
            
            // Verify email was queued (checking message queue)
            const emailQueue = await getQueueMessages('email-queue');
            expect(emailQueue).toContainEqual(
                expect.objectContaining({
                    type: 'welcome_email',
                    to: newUser.email
                })
            );
        });
        
        it('should handle database errors gracefully', async () => {
            // Simulate database failure
            jest.spyOn(db.users, 'create').mockRejectedValueOnce(
                new Error('Database connection failed')
            );
            
            const response = await request(app)
                .post('/api/users')
                .send({
                    email: 'test@example.com',
                    name: 'Test User',
                    password: 'password'
                })
                .expect(503);
            
            expect(response.body).toEqual({
                error: 'Service temporarily unavailable',
                message: 'Please try again later'
            });
        });
    });
    
    describe('GET /api/users/:id/profile', () => {
        it('should return user profile with aggregated data', async () => {
            // Arrange
            const userId = 'existing-user-id';
            
            // Act
            const response = await request(app)
                .get(`/api/users/${userId}/profile`)
                .set('Authorization', 'Bearer valid-token')
                .expect(200);
            
            // Assert - Verify data from multiple sources
            expect(response.body).toEqual({
                user: expect.objectContaining({
                    id: userId,
                    email: expect.any(String),
                    name: expect.any(String)
                }),
                stats: expect.objectContaining({
                    postsCount: expect.any(Number),
                    followersCount: expect.any(Number),
                    followingCount: expect.any(Number)
                }),
                recentActivity: expect.arrayContaining([
                    expect.objectContaining({
                        type: expect.any(String),
                        timestamp: expect.any(String)
                    })
                ])
            });
        });
    });
});
```

### Database Integration Tests (Python/SQLAlchemy)
```python
# test_database_integration.py
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.models import User, Post, Comment
from app.database import Base
from app.services import UserService, PostService

class TestDatabaseIntegration:
    
    @pytest.fixture(scope='class')
    def db_engine(self):
        """Create test database engine"""
        engine = create_engine('postgresql://test_user:test_pass@localhost/test_db')
        Base.metadata.create_all(bind=engine)
        yield engine
        Base.metadata.drop_all(bind=engine)
    
    @pytest.fixture
    def db_session(self, db_engine):
        """Create a new database session for each test"""
        Session = sessionmaker(bind=db_engine)
        session = Session()
        
        yield session
        
        session.rollback()
        session.close()
    
    def test_user_post_relationship(self, db_session):
        """Test user-post relationship integrity"""
        # Create user
        user = User(
            email='test@example.com',
            name='Test User',
            password_hash='hashed_password'
        )
        db_session.add(user)
        db_session.commit()
        
        # Create posts for user
        post1 = Post(title='First Post', content='Content 1', author_id=user.id)
        post2 = Post(title='Second Post', content='Content 2', author_id=user.id)
        
        db_session.add_all([post1, post2])
        db_session.commit()
        
        # Test relationship navigation
        retrieved_user = db_session.query(User).filter_by(id=user.id).first()
        assert len(retrieved_user.posts) == 2
        assert post1 in retrieved_user.posts
        assert post2 in retrieved_user.posts
        
        # Test cascade delete
        db_session.delete(retrieved_user)
        db_session.commit()
        
        # Verify posts were deleted
        remaining_posts = db_session.query(Post).filter_by(author_id=user.id).all()
        assert len(remaining_posts) == 0
    
    def test_transaction_rollback(self, db_session):
        """Test transaction rollback on error"""
        user_service = UserService(db_session)
        
        initial_count = db_session.query(User).count()
        
        try:
            with db_session.begin():
                # Create user
                user = User(email='test@example.com', name='Test User')
                db_session.add(user)
                
                # Force an error
                raise ValueError("Simulated error")
                
        except ValueError:
            pass
        
        # Verify rollback occurred
        final_count = db_session.query(User).count()
        assert final_count == initial_count
    
    def test_concurrent_access(self, db_engine):
        """Test handling of concurrent database access"""
        Session = sessionmaker(bind=db_engine)
        
        # Create two sessions simulating concurrent access
        session1 = Session()
        session2 = Session()
        
        try:
            # Both sessions read the same user
            user1 = session1.query(User).filter_by(id=1).first()
            user2 = session2.query(User).filter_by(id=1).first()
            
            # Both try to update
            user1.name = 'Updated by Session 1'
            user2.name = 'Updated by Session 2'
            
            # Commit first session
            session1.commit()
            
            # Second session should handle conflict
            with pytest.raises(Exception):  # Optimistic locking exception
                session2.commit()
                
        finally:
            session1.close()
            session2.close()
```

### Microservices Integration Tests (Java/Spring Boot)
```java
// OrderServiceIntegrationTest.java
@SpringBootTest
@AutoConfigureMockMvc
@TestPropertySource(locations = "classpath:application-test.properties")
@DirtiesContext(classMode = ClassMode.AFTER_EACH_TEST_METHOD)
public class OrderServiceIntegrationTest {
    
    @Autowired
    private MockMvc mockMvc;
    
    @Autowired
    private OrderRepository orderRepository;
    
    @MockBean
    private PaymentServiceClient paymentServiceClient;
    
    @MockBean
    private InventoryServiceClient inventoryServiceClient;
    
    @Autowired
    private KafkaTemplate<String, Object> kafkaTemplate;
    
    @Test
    @Transactional
    public void createOrder_Success_AllServicesAvailable() throws Exception {
        // Arrange
        CreateOrderRequest request = CreateOrderRequest.builder()
            .userId("user-123")
            .items(Arrays.asList(
                new OrderItem("product-1", 2, new BigDecimal("29.99")),
                new OrderItem("product-2", 1, new BigDecimal("49.99"))
            ))
            .paymentMethod("CREDIT_CARD")
            .build();
        
        // Mock external service responses
        when(inventoryServiceClient.checkAvailability(anyList()))
            .thenReturn(InventoryResponse.builder()
                .allAvailable(true)
                .items(request.getItems().stream()
                    .map(item -> new InventoryItem(item.getProductId(), true))
                    .collect(Collectors.toList()))
                .build());
        
        when(paymentServiceClient.processPayment(any()))
            .thenReturn(PaymentResponse.builder()
                .transactionId("txn-123")
                .status("APPROVED")
                .build());
        
        // Act
        MvcResult result = mockMvc.perform(post("/api/orders")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.orderId").isNotEmpty())
                .andExpect(jsonPath("$.status").value("CONFIRMED"))
                .andExpect(jsonPath("$.totalAmount").value(109.97))
                .andReturn();
        
        String orderId = JsonPath.read(result.getResponse().getContentAsString(), "$.orderId");
        
        // Assert - Verify database state
        Order savedOrder = orderRepository.findById(orderId).orElseThrow();
        assertEquals(OrderStatus.CONFIRMED, savedOrder.getStatus());
        assertEquals(2, savedOrder.getItems().size());
        assertNotNull(savedOrder.getPaymentTransactionId());
        
        // Verify Kafka events were published
        verify(kafkaTemplate, times(1)).send(
            eq("order-events"),
            argThat(event -> {
                OrderEvent orderEvent = (OrderEvent) event;
                return orderEvent.getEventType() == EventType.ORDER_CREATED
                    && orderEvent.getOrderId().equals(orderId);
            })
        );
    }
    
    @Test
    public void createOrder_InventoryUnavailable_CompensatingTransaction() throws Exception {
        // Arrange
        CreateOrderRequest request = createOrderRequest();
        
        // Mock inventory service to return unavailable
        when(inventoryServiceClient.checkAvailability(anyList()))
            .thenReturn(InventoryResponse.builder()
                .allAvailable(false)
                .build());
        
        // Act & Assert
        mockMvc.perform(post("/api/orders")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error").value("INVENTORY_UNAVAILABLE"));
        
        // Verify no order was saved
        assertEquals(0, orderRepository.count());
        
        // Verify no payment was attempted
        verify(paymentServiceClient, never()).processPayment(any());
    }
}
```

### Message Queue Integration Tests
```python
# test_messaging_integration.py
import pytest
from unittest.mock import patch, MagicMock
import pika
import json
from app.messaging import MessagePublisher, MessageConsumer
from app.handlers import OrderHandler

class TestMessagingIntegration:
    
    @pytest.fixture
    def rabbitmq_connection(self):
        """Create RabbitMQ test connection"""
        connection = pika.BlockingConnection(
            pika.ConnectionParameters('localhost', 5672, 'test_vhost')
        )
        channel = connection.channel()
        
        # Declare test queues
        channel.queue_declare(queue='test_orders', durable=True)
        channel.queue_declare(queue='test_notifications', durable=True)
        
        yield connection
        
        # Cleanup
        channel.queue_delete('test_orders')
        channel.queue_delete('test_notifications')
        connection.close()
    
    def test_order_processing_workflow(self, rabbitmq_connection):
        """Test complete order processing through message queue"""
        channel = rabbitmq_connection.channel()
        
        # Create publisher and consumer
        publisher = MessagePublisher(channel)
        consumer = MessageConsumer(channel)
        handler = OrderHandler()
        
        # Publish order message
        order_message = {
            'order_id': 'order-123',
            'user_id': 'user-456',
            'items': [
                {'product_id': 'prod-1', 'quantity': 2}
            ],
            'total': 59.98
        }
        
        publisher.publish('test_orders', order_message)
        
        # Consume and process message
        processed_messages = []
        
        def callback(ch, method, properties, body):
            message = json.loads(body)
            result = handler.process_order(message)
            processed_messages.append(result)
            ch.basic_ack(delivery_tag=method.delivery_tag)
        
        consumer.consume('test_orders', callback, auto_ack=False)
        
        # Start consuming (would normally run in separate thread)
        connection = consumer.connection
        connection.process_data_events(time_limit=1)
        
        # Verify message was processed
        assert len(processed_messages) == 1
        assert processed_messages[0]['status'] == 'processed'
        assert processed_messages[0]['order_id'] == 'order-123'
        
        # Verify notification was sent
        method, properties, body = channel.basic_get('test_notifications', auto_ack=True)
        assert method is not None
        notification = json.loads(body)
        assert notification['type'] == 'order_confirmation'
        assert notification['order_id'] == 'order-123'
```

### GraphQL Integration Tests
```typescript
// graphql.integration.test.ts
import { ApolloServer } from 'apollo-server-express';
import { createTestClient } from 'apollo-server-testing';
import { gql } from 'apollo-server-express';
import { buildSchema } from '../src/schema';
import { createContext } from '../src/context';
import { seedDatabase, clearDatabase } from './helpers';

describe('GraphQL Integration Tests', () => {
    let server: ApolloServer;
    let query: any;
    let mutate: any;
    
    beforeAll(async () => {
        server = new ApolloServer({
            schema: await buildSchema(),
            context: createContext
        });
        
        const testClient = createTestClient(server);
        query = testClient.query;
        mutate = testClient.mutate;
    });
    
    beforeEach(async () => {
        await seedDatabase();
    });
    
    afterEach(async () => {
        await clearDatabase();
    });
    
    describe('User Queries', () => {
        it('should fetch user with related data', async () => {
            const GET_USER_PROFILE = gql`
                query GetUserProfile($userId: ID!) {
                    user(id: $userId) {
                        id
                        name
                        email
                        posts {
                            id
                            title
                            comments {
                                id
                                content
                                author {
                                    name
                                }
                            }
                        }
                        followers {
                            id
                            name
                        }
                    }
                }
            `;
            
            const { data, errors } = await query({
                query: GET_USER_PROFILE,
                variables: { userId: 'user-1' }
            });
            
            expect(errors).toBeUndefined();
            expect(data.user).toMatchObject({
                id: 'user-1',
                name: expect.any(String),
                posts: expect.arrayContaining([
                    expect.objectContaining({
                        id: expect.any(String),
                        comments: expect.any(Array)
                    })
                ])
            });
        });
    });
    
    describe('Mutations with Side Effects', () => {
        it('should create post and trigger notifications', async () => {
            const CREATE_POST = gql`
                mutation CreatePost($input: CreatePostInput!) {
                    createPost(input: $input) {
                        id
                        title
                        content
                        author {
                            id
                            name
                        }
                        createdAt
                    }
                }
            `;
            
            const { data, errors } = await mutate({
                mutation: CREATE_POST,
                variables: {
                    input: {
                        title: 'New Post',
                        content: 'Post content',
                        authorId: 'user-1',
                        tags: ['test', 'integration']
                    }
                }
            });
            
            expect(errors).toBeUndefined();
            expect(data.createPost).toMatchObject({
                id: expect.any(String),
                title: 'New Post',
                author: {
                    id: 'user-1'
                }
            });
            
            // Verify side effects
            // Check notification service was called
            const notifications = await getNotificationQueue();
            expect(notifications).toContainEqual(
                expect.objectContaining({
                    type: 'new_post',
                    postId: data.createPost.id
                })
            );
            
            // Check search index was updated
            const searchResults = await searchService.search('New Post');
            expect(searchResults).toContainEqual(
                expect.objectContaining({
                    id: data.createPost.id,
                    type: 'post'
                })
            );
        });
    });
});
```

## Testing External Service Integrations

### REST API Client Integration
```python
class TestExternalAPIIntegration:
    
    @pytest.fixture
    def mock_responses(self, requests_mock):
        """Mock external API responses"""
        # Mock successful response
        requests_mock.get(
            'https://api.external.com/users/123',
            json={'id': '123', 'name': 'External User', 'status': 'active'},
            status_code=200
        )
        
        # Mock error response
        requests_mock.get(
            'https://api.external.com/users/404',
            json={'error': 'User not found'},
            status_code=404
        )
        
        # Mock timeout
        requests_mock.get(
            'https://api.external.com/users/timeout',
            exc=requests.exceptions.Timeout
        )
        
        return requests_mock
    
    def test_fetch_external_user_success(self, mock_responses):
        """Test successful external API call"""
        client = ExternalAPIClient()
        
        user = client.get_user('123')
        
        assert user['id'] == '123'
        assert user['name'] == 'External User'
        assert mock_responses.call_count == 1
        
    def test_circuit_breaker_opens_after_failures(self, mock_responses):
        """Test circuit breaker pattern"""
        client = ExternalAPIClient(
            circuit_breaker_threshold=3,
            circuit_breaker_timeout=60
        )
        
        # Cause multiple failures
        for _ in range(3):
            with pytest.raises(requests.exceptions.Timeout):
                client.get_user('timeout')
        
        # Circuit should be open now
        with pytest.raises(CircuitBreakerOpenError):
            client.get_user('123')  # This should fail fast
        
        # Verify no additional external calls were made
        assert mock_responses.call_count == 3
```

### Cloud Service Integration (AWS)
```typescript
// aws-integration.test.ts
import AWS from 'aws-sdk';
import { S3Service } from '../src/services/s3-service';
import { SQSService } from '../src/services/sqs-service';

describe('AWS Services Integration', () => {
    let s3Service: S3Service;
    let sqsService: SQSService;
    
    beforeAll(() => {
        // Use localstack for testing
        AWS.config.update({
            endpoint: 'http://localhost:4566',
            region: 'us-east-1',
            credentials: {
                accessKeyId: 'test',
                secretAccessKey: 'test'
            }
        });
        
        s3Service = new S3Service();
        sqsService = new SQSService();
    });
    
    describe('S3 Integration', () => {
        it('should upload and retrieve files', async () => {
            // Arrange
            const bucketName = 'test-bucket';
            const fileName = 'test-file.txt';
            const fileContent = 'Hello, World!';
            
            // Create bucket
            await s3Service.createBucket(bucketName);
            
            // Act - Upload file
            const uploadResult = await s3Service.uploadFile(
                bucketName,
                fileName,
                Buffer.from(fileContent)
            );
            
            expect(uploadResult.Location).toBeDefined();
            
            // Act - Download file
            const downloadedContent = await s3Service.downloadFile(
                bucketName,
                fileName
            );
            
            // Assert
            expect(downloadedContent.toString()).toBe(fileContent);
            
            // Cleanup
            await s3Service.deleteFile(bucketName, fileName);
            await s3Service.deleteBucket(bucketName);
        });
    });
    
    describe('SQS Integration', () => {
        it('should send and receive messages', async () => {
            // Arrange
            const queueName = 'test-queue';
            const queueUrl = await sqsService.createQueue(queueName);
            
            const testMessage = {
                id: 'msg-123',
                type: 'order',
                data: { orderId: 'order-456' }
            };
            
            // Act - Send message
            await sqsService.sendMessage(queueUrl, testMessage);
            
            // Act - Receive message
            const messages = await sqsService.receiveMessages(queueUrl);
            
            // Assert
            expect(messages).toHaveLength(1);
            const receivedMessage = JSON.parse(messages[0].Body);
            expect(receivedMessage).toEqual(testMessage);
            
            // Cleanup
            await sqsService.deleteMessage(queueUrl, messages[0].ReceiptHandle);
            await sqsService.deleteQueue(queueUrl);
        });
    });
});
```

## Testing Data Consistency

### Multi-Database Consistency
```java
@Test
@Transactional
public void testDataConsistencyAcrossDatabase() {
    // Start distributed transaction
    TransactionStatus status = transactionManager.getTransaction(
        new DefaultTransactionDefinition()
    );
    
    try {
        // Update primary database
        User user = userRepository.save(new User("test@example.com"));
        
        // Update secondary database (analytics)
        analyticsService.trackUserCreation(user.getId());
        
        // Update cache
        cacheService.put("user:" + user.getId(), user);
        
        // Simulate partial failure
        if (shouldSimulateFailure()) {
            throw new RuntimeException("Simulated failure");
        }
        
        transactionManager.commit(status);
        
        // Verify all systems are consistent
        assertUserExistsInAllSystems(user.getId());
        
    } catch (Exception e) {
        transactionManager.rollback(status);
        
        // Verify rollback worked across all systems
        assertUserDoesNotExistInAnySystems(user.getId());
    }
}
```

## Performance Testing in Integration Tests

### Load Testing Integration Points
```python
def test_api_performance_under_load(self):
    """Test API performance with concurrent requests"""
    import concurrent.futures
    import time
    
    def make_request(session, user_id):
        start = time.time()
        response = session.get(f'/api/users/{user_id}/profile')
        duration = time.time() - start
        return {
            'status': response.status_code,
            'duration': duration,
            'user_id': user_id
        }
    
    # Create thread pool
    with concurrent.futures.ThreadPoolExecutor(max_workers=50) as executor:
        # Submit 1000 concurrent requests
        futures = []
        session = requests.Session()
        
        for i in range(1000):
            future = executor.submit(make_request, session, i % 100)
            futures.append(future)
        
        # Collect results
        results = [f.result() for f in concurrent.futures.as_completed(futures)]
    
    # Analyze performance
    successful_requests = [r for r in results if r['status'] == 200]
    durations = [r['duration'] for r in successful_requests]
    
    # Assert performance requirements
    assert len(successful_requests) >= 990  # 99% success rate
    assert sum(durations) / len(durations) < 0.1  # Average < 100ms
    assert max(durations) < 1.0  # No request > 1 second
```

## Best Practices for Integration Tests

### Test Data Management
```typescript
// test-data-manager.ts
export class TestDataManager {
    private createdRecords: Array<{table: string, id: string}> = [];
    
    async createTestUser(overrides?: Partial<User>): Promise<User> {
        const user = await db.users.create({
            email: `test-${Date.now()}@example.com`,
            name: 'Test User',
            ...overrides
        });
        
        this.trackRecord('users', user.id);
        return user;
    }
    
    async cleanup(): Promise<void> {
        // Delete in reverse order to handle foreign keys
        for (const record of this.createdRecords.reverse()) {
            await db[record.table].delete(record.id);
        }
        this.createdRecords = [];
    }
    
    private trackRecord(table: string, id: string): void {
        this.createdRecords.push({ table, id });
    }
}
```

### Integration Test Containers
```python
# Using testcontainers for integration tests
from testcontainers.postgres import PostgresContainer
from testcontainers.redis import RedisContainer
from testcontainers.kafka import KafkaContainer

@pytest.fixture(scope='session')
def postgres_container():
    with PostgresContainer('postgres:13') as postgres:
        yield postgres

@pytest.fixture(scope='session')
def redis_container():
    with RedisContainer('redis:6') as redis:
        yield redis

@pytest.fixture(scope='session')
def kafka_container():
    with KafkaContainer('confluentinc/cp-kafka:latest') as kafka:
        yield kafka

def test_full_integration(postgres_container, redis_container, kafka_container):
    """Test with all dependencies running in containers"""
    # Get connection strings
    postgres_url = postgres_container.get_connection_url()
    redis_url = redis_container.get_connection_url()
    kafka_bootstrap_servers = kafka_container.get_bootstrap_server()
    
    # Initialize application with test containers
    app = create_app({
        'database_url': postgres_url,
        'redis_url': redis_url,
        'kafka_servers': kafka_bootstrap_servers
    })
    
    # Run integration tests
    # ...
```

This integration test template provides comprehensive patterns for testing component interactions, ensuring your integrated system functions correctly as a whole while maintaining isolation and repeatability.