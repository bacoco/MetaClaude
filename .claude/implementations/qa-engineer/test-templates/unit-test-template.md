# Unit Test Template

## Overview
This template provides standardized patterns and best practices for creating comprehensive unit tests. Unit tests verify individual components or functions in isolation, ensuring each piece of code works correctly before integration.

## Basic Unit Test Structure

### JavaScript/TypeScript (Jest)
```typescript
// user.service.test.ts
import { UserService } from './user.service';
import { UserRepository } from './user.repository';
import { User } from './user.model';

// Mock dependencies
jest.mock('./user.repository');

describe('UserService', () => {
    let userService: UserService;
    let mockUserRepository: jest.Mocked<UserRepository>;
    
    beforeEach(() => {
        // Reset mocks before each test
        jest.clearAllMocks();
        
        // Create mock instance
        mockUserRepository = new UserRepository() as jest.Mocked<UserRepository>;
        
        // Initialize service with mocked dependency
        userService = new UserService(mockUserRepository);
    });
    
    describe('createUser', () => {
        it('should create a user successfully with valid data', async () => {
            // Arrange
            const userData = {
                email: 'test@example.com',
                name: 'Test User',
                age: 25
            };
            
            const expectedUser = new User({
                id: 'user-123',
                ...userData,
                createdAt: new Date()
            });
            
            mockUserRepository.save.mockResolvedValue(expectedUser);
            
            // Act
            const result = await userService.createUser(userData);
            
            // Assert
            expect(result).toEqual(expectedUser);
            expect(mockUserRepository.save).toHaveBeenCalledWith(
                expect.objectContaining(userData)
            );
            expect(mockUserRepository.save).toHaveBeenCalledTimes(1);
        });
        
        it('should throw error when email is invalid', async () => {
            // Arrange
            const invalidUserData = {
                email: 'invalid-email',
                name: 'Test User',
                age: 25
            };
            
            // Act & Assert
            await expect(userService.createUser(invalidUserData))
                .rejects
                .toThrow('Invalid email format');
                
            expect(mockUserRepository.save).not.toHaveBeenCalled();
        });
        
        it('should handle repository errors gracefully', async () => {
            // Arrange
            const userData = {
                email: 'test@example.com',
                name: 'Test User',
                age: 25
            };
            
            const dbError = new Error('Database connection failed');
            mockUserRepository.save.mockRejectedValue(dbError);
            
            // Act & Assert
            await expect(userService.createUser(userData))
                .rejects
                .toThrow('Failed to create user');
        });
    });
    
    describe('getUserById', () => {
        it('should return user when found', async () => {
            // Arrange
            const userId = 'user-123';
            const expectedUser = new User({
                id: userId,
                email: 'test@example.com',
                name: 'Test User',
                age: 25
            });
            
            mockUserRepository.findById.mockResolvedValue(expectedUser);
            
            // Act
            const result = await userService.getUserById(userId);
            
            // Assert
            expect(result).toEqual(expectedUser);
            expect(mockUserRepository.findById).toHaveBeenCalledWith(userId);
        });
        
        it('should return null when user not found', async () => {
            // Arrange
            mockUserRepository.findById.mockResolvedValue(null);
            
            // Act
            const result = await userService.getUserById('non-existent');
            
            // Assert
            expect(result).toBeNull();
        });
    });
});
```

### Python (pytest)
```python
# test_user_service.py
import pytest
from unittest.mock import Mock, patch
from datetime import datetime
from user_service import UserService
from user_repository import UserRepository
from models import User
from exceptions import ValidationError, DatabaseError

class TestUserService:
    
    @pytest.fixture
    def mock_repository(self):
        """Create a mock repository for testing"""
        return Mock(spec=UserRepository)
    
    @pytest.fixture
    def user_service(self, mock_repository):
        """Create UserService instance with mocked dependencies"""
        return UserService(repository=mock_repository)
    
    class TestCreateUser:
        
        def test_create_user_success(self, user_service, mock_repository):
            # Arrange
            user_data = {
                'email': 'test@example.com',
                'name': 'Test User',
                'age': 25
            }
            
            expected_user = User(
                id='user-123',
                email=user_data['email'],
                name=user_data['name'],
                age=user_data['age'],
                created_at=datetime.now()
            )
            
            mock_repository.save.return_value = expected_user
            
            # Act
            result = user_service.create_user(**user_data)
            
            # Assert
            assert result == expected_user
            mock_repository.save.assert_called_once()
            saved_user = mock_repository.save.call_args[0][0]
            assert saved_user.email == user_data['email']
            assert saved_user.name == user_data['name']
            
        def test_create_user_invalid_email(self, user_service, mock_repository):
            # Arrange
            invalid_data = {
                'email': 'invalid-email',
                'name': 'Test User',
                'age': 25
            }
            
            # Act & Assert
            with pytest.raises(ValidationError) as exc_info:
                user_service.create_user(**invalid_data)
            
            assert 'Invalid email format' in str(exc_info.value)
            mock_repository.save.assert_not_called()
            
        def test_create_user_database_error(self, user_service, mock_repository):
            # Arrange
            user_data = {
                'email': 'test@example.com',
                'name': 'Test User',
                'age': 25
            }
            
            mock_repository.save.side_effect = DatabaseError('Connection failed')
            
            # Act & Assert
            with pytest.raises(DatabaseError) as exc_info:
                user_service.create_user(**user_data)
            
            assert 'Failed to create user' in str(exc_info.value)
            
        @pytest.mark.parametrize('age,expected_error', [
            (-1, 'Age must be positive'),
            (0, 'Age must be positive'),
            (150, 'Age must be less than 150'),
            (None, 'Age is required')
        ])
        def test_create_user_invalid_age(self, user_service, age, expected_error):
            # Arrange
            user_data = {
                'email': 'test@example.com',
                'name': 'Test User',
                'age': age
            }
            
            # Act & Assert
            with pytest.raises(ValidationError) as exc_info:
                user_service.create_user(**user_data)
            
            assert expected_error in str(exc_info.value)
```

### Java (JUnit 5)
```java
// UserServiceTest.java
import org.junit.jupiter.api.*;
import org.mockito.*;
import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;

class UserServiceTest {
    
    @Mock
    private UserRepository userRepository;
    
    @InjectMocks
    private UserService userService;
    
    private AutoCloseable closeable;
    
    @BeforeEach
    void setUp() {
        closeable = MockitoAnnotations.openMocks(this);
    }
    
    @AfterEach
    void tearDown() throws Exception {
        closeable.close();
    }
    
    @Nested
    @DisplayName("Create User")
    class CreateUserTests {
        
        @Test
        @DisplayName("Should create user successfully with valid data")
        void createUser_ValidData_Success() {
            // Arrange
            UserDto userDto = UserDto.builder()
                .email("test@example.com")
                .name("Test User")
                .age(25)
                .build();
                
            User expectedUser = User.builder()
                .id("user-123")
                .email(userDto.getEmail())
                .name(userDto.getName())
                .age(userDto.getAge())
                .createdAt(LocalDateTime.now())
                .build();
                
            when(userRepository.save(any(User.class))).thenReturn(expectedUser);
            
            // Act
            User result = userService.createUser(userDto);
            
            // Assert
            assertNotNull(result);
            assertEquals(expectedUser.getId(), result.getId());
            assertEquals(expectedUser.getEmail(), result.getEmail());
            
            verify(userRepository, times(1)).save(argThat(user -> 
                user.getEmail().equals(userDto.getEmail()) &&
                user.getName().equals(userDto.getName())
            ));
        }
        
        @Test
        @DisplayName("Should throw exception for invalid email")
        void createUser_InvalidEmail_ThrowsException() {
            // Arrange
            UserDto invalidUser = UserDto.builder()
                .email("invalid-email")
                .name("Test User")
                .age(25)
                .build();
            
            // Act & Assert
            ValidationException exception = assertThrows(
                ValidationException.class,
                () -> userService.createUser(invalidUser)
            );
            
            assertEquals("Invalid email format", exception.getMessage());
            verifyNoInteractions(userRepository);
        }
        
        @ParameterizedTest
        @ValueSource(ints = {-1, 0, 150, 200})
        @DisplayName("Should throw exception for invalid age")
        void createUser_InvalidAge_ThrowsException(int invalidAge) {
            // Arrange
            UserDto userDto = UserDto.builder()
                .email("test@example.com")
                .name("Test User")
                .age(invalidAge)
                .build();
            
            // Act & Assert
            ValidationException exception = assertThrows(
                ValidationException.class,
                () -> userService.createUser(userDto)
            );
            
            assertTrue(exception.getMessage().contains("Invalid age"));
        }
    }
}
```

## Advanced Testing Patterns

### Testing Async Operations
```typescript
describe('Async Operations', () => {
    it('should handle async operations correctly', async () => {
        // Using async/await
        const result = await asyncFunction();
        expect(result).toBe('expected');
        
        // Using promises
        return asyncFunction().then(result => {
            expect(result).toBe('expected');
        });
        
        // Testing rejected promises
        await expect(failingAsyncFunction()).rejects.toThrow('Error message');
    });
    
    it('should handle timeouts properly', async () => {
        jest.useFakeTimers();
        
        const promise = delayedFunction(5000);
        
        // Fast-forward time
        jest.advanceTimersByTime(5000);
        
        const result = await promise;
        expect(result).toBe('completed');
        
        jest.useRealTimers();
    });
});
```

### Testing with Spies and Stubs
```python
def test_complex_interaction(self, mocker):
    # Create a spy to track calls while preserving behavior
    spy = mocker.spy(module, 'function_to_spy')
    
    # Create a stub with specific behavior
    stub = mocker.stub(name='custom_stub')
    stub.return_value = 'stubbed_value'
    
    # Patch a method
    mocker.patch.object(
        SomeClass,
        'method_name',
        return_value='mocked_value'
    )
    
    # Execute code that uses these
    result = function_under_test()
    
    # Verify spy was called
    assert spy.call_count == 2
    assert spy.call_args_list[0] == mocker.call('arg1', 'arg2')
```

## Testing Edge Cases

### Boundary Value Testing
```typescript
describe('Boundary Value Tests', () => {
    const testCases = [
        { input: -1, expected: 'error', description: 'below minimum' },
        { input: 0, expected: 0, description: 'minimum boundary' },
        { input: 50, expected: 50, description: 'middle value' },
        { input: 100, expected: 100, description: 'maximum boundary' },
        { input: 101, expected: 'error', description: 'above maximum' }
    ];
    
    testCases.forEach(({ input, expected, description }) => {
        it(`should handle ${description}`, () => {
            const result = boundaryFunction(input);
            expect(result).toBe(expected);
        });
    });
});
```

### Error Handling Tests
```python
class TestErrorHandling:
    
    def test_graceful_degradation(self, service):
        """Test that service degrades gracefully on partial failure"""
        # Simulate partial system failure
        with patch.object(service, 'external_api') as mock_api:
            mock_api.side_effect = ConnectionError("API unavailable")
            
            # Should return cached/default data instead of failing
            result = service.get_data_with_fallback()
            
            assert result['status'] == 'degraded'
            assert result['data'] == service.get_cached_data()
            assert result['warning'] == 'Using cached data'
    
    def test_circuit_breaker(self, service):
        """Test circuit breaker pattern implementation"""
        # Simulate multiple failures
        for _ in range(5):
            with pytest.raises(ServiceUnavailableError):
                service.call_flaky_service()
        
        # Circuit should be open now
        assert service.circuit_breaker.is_open
        
        # Calls should fail fast without hitting the service
        with pytest.raises(CircuitOpenError):
            service.call_flaky_service()
```

## Test Data Builders

### Builder Pattern for Test Data
```typescript
class UserTestDataBuilder {
    private user: Partial<User> = {
        id: 'default-id',
        email: 'default@example.com',
        name: 'Default User',
        age: 25,
        roles: ['user'],
        createdAt: new Date()
    };
    
    withId(id: string): this {
        this.user.id = id;
        return this;
    }
    
    withEmail(email: string): this {
        this.user.email = email;
        return this;
    }
    
    withAge(age: number): this {
        this.user.age = age;
        return this;
    }
    
    withRoles(roles: string[]): this {
        this.user.roles = roles;
        return this;
    }
    
    asAdmin(): this {
        this.user.roles = ['admin'];
        return this;
    }
    
    build(): User {
        return new User(this.user as User);
    }
}

// Usage in tests
const adminUser = new UserTestDataBuilder()
    .withEmail('admin@example.com')
    .asAdmin()
    .build();
```

## Performance Testing in Unit Tests

### Measuring Execution Time
```python
import time
import pytest

def test_performance_requirement(self):
    """Ensure function completes within performance SLA"""
    start_time = time.perf_counter()
    
    # Execute function
    result = expensive_function(large_dataset)
    
    end_time = time.perf_counter()
    execution_time = end_time - start_time
    
    # Assert both correctness and performance
    assert result == expected_result
    assert execution_time < 0.1, f"Function took {execution_time}s, expected < 0.1s"

@pytest.mark.benchmark
def test_algorithm_performance(benchmark):
    """Benchmark algorithm performance"""
    result = benchmark(algorithm_function, test_data)
    
    # Benchmark automatically measures:
    # - Min, max, mean execution time
    # - Standard deviation
    # - Number of rounds
    assert result == expected_output
```

## Test Organization Best Practices

### AAA Pattern (Arrange, Act, Assert)
```typescript
it('should follow AAA pattern', () => {
    // Arrange - Set up test data and mocks
    const testData = createTestData();
    const mockService = createMockService();
    
    // Act - Execute the function under test
    const result = functionUnderTest(testData, mockService);
    
    // Assert - Verify the results
    expect(result).toEqual(expectedResult);
    expect(mockService.method).toHaveBeenCalledWith(expectedArgs);
});
```

### Test Naming Conventions
```java
@Test
@DisplayName("Given valid user data, when createUser is called, then user should be created successfully")
void createUser_ValidData_CreatesUserSuccessfully() {
    // Test implementation
}

// Alternative naming patterns:
// methodName_stateUnderTest_expectedBehavior
// should_expectedBehavior_when_stateUnderTest
// test_methodName_scenario_expectedOutcome
```

## Continuous Testing Integration

### Pre-commit Hook Configuration
```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: unit-tests
        name: Run unit tests
        entry: npm test -- --coverage --passWithNoTests
        language: system
        pass_filenames: false
        stages: [commit]
```

### CI/CD Pipeline Integration
```yaml
# .github/workflows/unit-tests.yml
name: Unit Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup Node.js
        uses: actions/setup-node@v2
        with:
          node-version: '16'
          
      - name: Install dependencies
        run: npm ci
        
      - name: Run unit tests
        run: npm test -- --coverage --ci
        
      - name: Upload coverage
        uses: codecov/codecov-action@v2
        with:
          file: ./coverage/lcov.info
          fail_ci_if_error: true
```

This unit test template provides comprehensive patterns for creating maintainable, effective unit tests that ensure code quality and reliability at the component level.