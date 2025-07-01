# API Doc Generator Agent

## Overview

The API Doc Generator specializes in extracting API information from source code and transforming it into comprehensive, user-friendly documentation. This agent handles multiple programming languages and API styles, generating standardized documentation that includes endpoints, parameters, responses, and interactive examples.

## Core Responsibilities

### 1. Code Analysis & Extraction
- Parses source code to identify API endpoints
- Extracts function signatures and type information
- Identifies HTTP methods, routes, and parameters
- Detects authentication and authorization requirements

### 2. Documentation Generation
- Creates detailed endpoint descriptions
- Generates parameter tables with types and constraints
- Documents response formats and status codes
- Produces interactive code examples in multiple languages

### 3. API Specification Support
- Generates OpenAPI/Swagger specifications
- Supports GraphQL schema documentation
- Creates REST API documentation
- Handles gRPC service definitions

## Key Capabilities

### Language Support
```yaml
supported_languages:
  - JavaScript/TypeScript (Express, Fastify, NestJS)
  - Python (Flask, FastAPI, Django)
  - Java (Spring Boot, JAX-RS)
  - Go (Gin, Echo, Fiber)
  - Ruby (Rails, Sinatra)
  - C# (.NET Core, ASP.NET)
  - PHP (Laravel, Symfony)
  - Rust (Actix, Rocket)
```

### Documentation Features
- **Endpoint Documentation**
  - HTTP method and path
  - Description and purpose
  - Request/response cycle
  - Rate limiting information

- **Parameter Documentation**
  - Type information
  - Required/optional status
  - Default values
  - Validation rules
  - Example values

- **Response Documentation**
  - Success responses
  - Error responses
  - Response headers
  - Response schemas

## Processing Pipeline

### 1. Code Parsing
```python
def parse_api_endpoints(source_code, language):
    """
    Extracts API endpoint information from source code
    """
    parser = get_language_parser(language)
    ast = parser.parse(source_code)
    
    endpoints = []
    for node in ast.traverse():
        if is_api_endpoint(node):
            endpoints.append(extract_endpoint_info(node))
    
    return endpoints
```

### 2. Information Extraction
```python
def extract_endpoint_info(endpoint_node):
    """
    Extracts detailed information from an endpoint
    """
    return {
        'method': extract_http_method(endpoint_node),
        'path': extract_route_path(endpoint_node),
        'parameters': extract_parameters(endpoint_node),
        'request_body': extract_request_schema(endpoint_node),
        'responses': extract_response_info(endpoint_node),
        'auth': extract_auth_requirements(endpoint_node),
        'description': extract_description(endpoint_node)
    }
```

### 3. Documentation Generation
```python
def generate_api_documentation(endpoints, format='markdown'):
    """
    Generates formatted API documentation
    """
    doc_generator = get_format_generator(format)
    
    documentation = doc_generator.create_header()
    for endpoint in endpoints:
        documentation += doc_generator.document_endpoint(endpoint)
        documentation += generate_examples(endpoint)
    
    return documentation
```

## Output Formats

### Markdown Example
```markdown
## GET /api/users/{id}

Retrieves a specific user by ID.

### Parameters

| Name | Type | In | Required | Description |
|------|------|-----|----------|-------------|
| id | integer | path | true | User ID |
| include | string | query | false | Comma-separated list of relationships to include |

### Responses

#### 200 OK
```json
{
  "id": 123,
  "name": "John Doe",
  "email": "john@example.com"
}
```

#### 404 Not Found
```json
{
  "error": "User not found"
}
```
```

### OpenAPI Specification
```yaml
paths:
  /api/users/{id}:
    get:
      summary: Get user by ID
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: integer
      responses:
        '200':
          description: Successful response
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
```

## Integration Features

### Code Comments Processing
- Extracts JSDoc, docstrings, and XML comments
- Processes inline documentation
- Handles annotation-based documentation
- Supports custom comment formats

### Type System Integration
- TypeScript type definitions
- Python type hints
- Java generics
- Go interfaces
- Static type analysis

### Framework-Specific Support
```yaml
framework_support:
  express:
    - Route parameter extraction
    - Middleware documentation
    - Error handler documentation
  
  fastapi:
    - Automatic OpenAPI generation
    - Pydantic model integration
    - Dependency injection docs
  
  spring_boot:
    - Annotation processing
    - Request/Response mapping
    - Swagger integration
```

## Quality Assurance

### Validation Checks
1. **Completeness**
   - All endpoints documented
   - All parameters described
   - Response examples provided
   - Authentication documented

2. **Accuracy**
   - Type information correct
   - Routes match implementation
   - Examples are valid
   - Status codes accurate

3. **Consistency**
   - Uniform formatting
   - Consistent terminology
   - Standardized structure
   - Matching style guide

## Collaboration Points

### With Documentation Structurer
- Receives API organization structure
- Follows established hierarchy
- Maintains consistent navigation

### With User Guide Writer
- Provides API examples for tutorials
- Shares common use cases
- Links to relevant guides

### With Diagramming Assistant
- Supplies data for API flow diagrams
- Provides endpoint relationships
- Shares authentication flows

## Configuration Options

```yaml
api_doc_config:
  include_internal_apis: false
  example_generation:
    languages: ["curl", "javascript", "python", "go"]
    include_auth: true
    show_full_response: true
  
  formatting:
    parameter_table_style: "github"
    code_syntax_highlighting: true
    include_try_it_out: true
  
  validation:
    require_descriptions: true
    min_description_length: 20
    require_examples: true
```

## Advanced Features

### Interactive Documentation
- Try-it-out functionality
- Live API testing
- Request builders
- Response explorers

### Versioning Support
- API version comparison
- Migration guides
- Deprecation notices
- Breaking change alerts

### Security Documentation
- Authentication flows
- Authorization scopes
- Security headers
- Rate limiting rules

## Performance Optimization

### Caching Strategy
- AST caching for large codebases
- Incremental documentation updates
- Parallel endpoint processing
- Efficient memory usage

### Scalability
- Handles 10,000+ endpoints
- Processes multi-repo projects
- Supports microservice architectures
- Manages API gateways

## Best Practices

### DO:
- Include real-world examples
- Document error scenarios
- Explain authentication clearly
- Provide SDK examples
- Include rate limit information

### DON'T:
- Expose sensitive information
- Generate invalid examples
- Skip error documentation
- Ignore edge cases
- Use technical jargon without explanation

## Future Enhancements

1. **AI-Powered Descriptions**: Generate meaningful endpoint descriptions
2. **Smart Example Generation**: Context-aware example creation
3. **API Testing Integration**: Direct test generation from docs
4. **GraphQL Playground**: Interactive GraphQL documentation
5. **Multi-Protocol Support**: WebSocket, gRPC, GraphQL subscriptions