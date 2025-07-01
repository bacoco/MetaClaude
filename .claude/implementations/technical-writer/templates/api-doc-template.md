# API Documentation Template

This template provides a comprehensive structure for documenting REST APIs, GraphQL endpoints, or other web services. Customize sections based on your specific API requirements.

---

# [API Name] API Documentation

**Version:** [X.X.X]  
**Base URL:** `https://api.example.com/v1`  
**Last Updated:** [Date]

## Overview

[Brief description of the API, its purpose, and main features. Include what problems it solves and who should use it.]

### Key Features
- [Feature 1]
- [Feature 2]
- [Feature 3]

### API Status
- **Production:** `https://api.example.com`
- **Staging:** `https://staging-api.example.com`
- **Development:** `https://dev-api.example.com`

---

## Getting Started

### Prerequisites
- [Requirement 1 (e.g., API key, account)]
- [Requirement 2 (e.g., specific software version)]
- [Requirement 3]

### Quick Start

1. **Get your API credentials**
   ```bash
   # Sign up at https://example.com/developers
   # Navigate to API Keys section
   ```

2. **Make your first request**
   ```bash
   curl -X GET https://api.example.com/v1/status \
     -H "Authorization: Bearer YOUR_API_KEY"
   ```

3. **Handle the response**
   ```json
   {
     "status": "operational",
     "version": "1.0.0",
     "timestamp": "2024-01-15T10:30:00Z"
   }
   ```

---

## Authentication

### API Key Authentication

All API requests require authentication using an API key.

**Header Format:**
```
Authorization: Bearer YOUR_API_KEY
```

**Example Request:**
```bash
curl -X GET https://api.example.com/v1/users \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json"
```

### OAuth 2.0 (if applicable)

[Describe OAuth flow, scopes, and token management]

---

## Base URL & Versioning

### Base URL Structure
```
https://api.example.com/{version}/{endpoint}
```

### API Versions
| Version | Status | End of Life |
|---------|--------|-------------|
| v1 | Current | N/A |
| v0 | Deprecated | 2024-12-31 |

### Version Header (Optional)
```
API-Version: 1.0
```

---

## Common Headers

### Request Headers
| Header | Required | Description |
|--------|----------|-------------|
| `Authorization` | Yes | Bearer token for authentication |
| `Content-Type` | Yes* | Media type of the request body (*for POST/PUT) |
| `Accept` | No | Preferred response format (default: `application/json`) |
| `X-Request-ID` | No | Unique request identifier for tracking |

### Response Headers
| Header | Description |
|--------|-------------|
| `X-Request-ID` | Echoed from request or generated |
| `X-Rate-Limit-Limit` | Request limit per hour |
| `X-Rate-Limit-Remaining` | Remaining requests |
| `X-Rate-Limit-Reset` | Unix timestamp when limit resets |

---

## Endpoints

### [Resource Name] (e.g., Users)

#### List [Resources]
```
GET /[resources]
```

Retrieves a paginated list of [resources].

**Query Parameters:**
| Parameter | Type | Required | Description | Default |
|-----------|------|----------|-------------|---------|
| `page` | integer | No | Page number | 1 |
| `limit` | integer | No | Items per page (max: 100) | 20 |
| `sort` | string | No | Sort field | `created_at` |
| `order` | string | No | Sort order (`asc`, `desc`) | `desc` |
| `filter` | string | No | Filter criteria | - |

**Example Request:**
```bash
curl -X GET "https://api.example.com/v1/users?page=1&limit=10" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

**Example Response:**
```json
{
  "data": [
    {
      "id": "usr_123456",
      "name": "John Doe",
      "email": "john@example.com",
      "created_at": "2024-01-15T10:30:00Z",
      "updated_at": "2024-01-15T10:30:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 150,
    "pages": 15
  }
}
```

#### Get [Resource]
```
GET /[resources]/{id}
```

Retrieves a specific [resource] by ID.

**Path Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | string | Yes | [Resource] identifier |

**Example Request:**
```bash
curl -X GET "https://api.example.com/v1/users/usr_123456" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

**Example Response:**
```json
{
  "id": "usr_123456",
  "name": "John Doe",
  "email": "john@example.com",
  "profile": {
    "bio": "Software developer",
    "avatar_url": "https://example.com/avatars/john.jpg"
  },
  "settings": {
    "notifications": true,
    "timezone": "America/New_York"
  },
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:30:00Z"
}
```

#### Create [Resource]
```
POST /[resources]
```

Creates a new [resource].

**Request Body:**
```json
{
  "name": "string (required)",
  "email": "string (required)",
  "profile": {
    "bio": "string (optional)",
    "avatar_url": "string (optional)"
  }
}
```

**Field Validation:**
| Field | Type | Required | Validation Rules |
|-------|------|----------|------------------|
| `name` | string | Yes | Min: 2, Max: 100 characters |
| `email` | string | Yes | Valid email format |
| `profile.bio` | string | No | Max: 500 characters |

**Example Request:**
```bash
curl -X POST "https://api.example.com/v1/users" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Jane Smith",
    "email": "jane@example.com",
    "profile": {
      "bio": "Product manager"
    }
  }'
```

**Example Response:**
```json
{
  "id": "usr_789012",
  "name": "Jane Smith",
  "email": "jane@example.com",
  "profile": {
    "bio": "Product manager",
    "avatar_url": null
  },
  "created_at": "2024-01-15T11:00:00Z",
  "updated_at": "2024-01-15T11:00:00Z"
}
```

#### Update [Resource]
```
PUT /[resources]/{id}
```

Updates an existing [resource]. All fields are optional.

**Path Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | string | Yes | [Resource] identifier |

**Request Body:**
```json
{
  "name": "string (optional)",
  "email": "string (optional)",
  "profile": {
    "bio": "string (optional)",
    "avatar_url": "string (optional)"
  }
}
```

**Example Request:**
```bash
curl -X PUT "https://api.example.com/v1/users/usr_123456" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "profile": {
      "bio": "Senior software developer"
    }
  }'
```

#### Delete [Resource]
```
DELETE /[resources]/{id}
```

Deletes a [resource].

**Path Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | string | Yes | [Resource] identifier |

**Example Request:**
```bash
curl -X DELETE "https://api.example.com/v1/users/usr_123456" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

**Example Response:**
```json
{
  "message": "User successfully deleted",
  "id": "usr_123456"
}
```

---

## Error Handling

### Error Response Format
```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": {
      "field": "Additional error context"
    },
    "request_id": "req_abc123"
  }
}
```

### Common Error Codes

| HTTP Status | Error Code | Description |
|-------------|------------|-------------|
| 400 | `BAD_REQUEST` | Invalid request format or parameters |
| 401 | `UNAUTHORIZED` | Missing or invalid authentication |
| 403 | `FORBIDDEN` | Insufficient permissions |
| 404 | `NOT_FOUND` | Resource not found |
| 409 | `CONFLICT` | Resource conflict (e.g., duplicate) |
| 422 | `VALIDATION_ERROR` | Request validation failed |
| 429 | `RATE_LIMIT_EXCEEDED` | Too many requests |
| 500 | `INTERNAL_ERROR` | Server error |
| 503 | `SERVICE_UNAVAILABLE` | Service temporarily unavailable |

### Error Examples

**Validation Error (422):**
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Request validation failed",
    "details": {
      "email": "Invalid email format",
      "name": "Name is required"
    },
    "request_id": "req_xyz789"
  }
}
```

**Rate Limit Error (429):**
```json
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "API rate limit exceeded",
    "details": {
      "limit": 100,
      "remaining": 0,
      "reset_at": "2024-01-15T12:00:00Z"
    },
    "request_id": "req_def456"
  }
}
```

---

## Rate Limiting

### Limits
- **Default:** 100 requests per hour
- **Authenticated:** 1,000 requests per hour
- **Enterprise:** Custom limits

### Rate Limit Headers
```
X-Rate-Limit-Limit: 1000
X-Rate-Limit-Remaining: 999
X-Rate-Limit-Reset: 1705320000
```

### Handling Rate Limits
```python
import time
import requests

def make_api_request(url, headers):
    response = requests.get(url, headers=headers)
    
    if response.status_code == 429:
        reset_time = int(response.headers.get('X-Rate-Limit-Reset', 0))
        sleep_time = max(reset_time - time.time(), 0)
        time.sleep(sleep_time)
        return make_api_request(url, headers)  # Retry
    
    return response
```

---

## Pagination

### Pagination Parameters
- `page`: Current page number (default: 1)
- `limit`: Items per page (default: 20, max: 100)

### Pagination Response
```json
{
  "data": [...],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 150,
    "pages": 8,
    "has_next": true,
    "has_prev": false
  },
  "links": {
    "first": "https://api.example.com/v1/users?page=1&limit=20",
    "last": "https://api.example.com/v1/users?page=8&limit=20",
    "next": "https://api.example.com/v1/users?page=2&limit=20",
    "prev": null
  }
}
```

---

## Webhooks (if applicable)

### Webhook Events
| Event | Description | Payload |
|-------|-------------|---------|
| `user.created` | New user registration | User object |
| `user.updated` | User profile updated | User object with changes |
| `user.deleted` | User account deleted | User ID |

### Webhook Payload Format
```json
{
  "id": "evt_123456",
  "type": "user.created",
  "created_at": "2024-01-15T10:30:00Z",
  "data": {
    // Event-specific data
  }
}
```

### Webhook Security
```python
import hmac
import hashlib

def verify_webhook(payload, signature, secret):
    expected = hmac.new(
        secret.encode(),
        payload.encode(),
        hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(expected, signature)
```

---

## Code Examples

### JavaScript/Node.js
```javascript
const axios = require('axios');

const api = axios.create({
  baseURL: 'https://api.example.com/v1',
  headers: {
    'Authorization': 'Bearer YOUR_API_KEY',
    'Content-Type': 'application/json'
  }
});

// GET request
async function getUsers() {
  try {
    const response = await api.get('/users');
    return response.data;
  } catch (error) {
    console.error('Error:', error.response.data);
  }
}

// POST request
async function createUser(userData) {
  try {
    const response = await api.post('/users', userData);
    return response.data;
  } catch (error) {
    console.error('Error:', error.response.data);
  }
}
```

### Python
```python
import requests

class APIClient:
    def __init__(self, api_key):
        self.base_url = 'https://api.example.com/v1'
        self.headers = {
            'Authorization': f'Bearer {api_key}',
            'Content-Type': 'application/json'
        }
    
    def get_users(self, page=1, limit=20):
        response = requests.get(
            f'{self.base_url}/users',
            headers=self.headers,
            params={'page': page, 'limit': limit}
        )
        response.raise_for_status()
        return response.json()
    
    def create_user(self, user_data):
        response = requests.post(
            f'{self.base_url}/users',
            headers=self.headers,
            json=user_data
        )
        response.raise_for_status()
        return response.json()

# Usage
client = APIClient('YOUR_API_KEY')
users = client.get_users()
```

### cURL
```bash
# GET request with query parameters
curl -X GET "https://api.example.com/v1/users?page=1&limit=10" \
  -H "Authorization: Bearer YOUR_API_KEY"

# POST request with JSON body
curl -X POST "https://api.example.com/v1/users" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com"
  }'

# PUT request
curl -X PUT "https://api.example.com/v1/users/usr_123456" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Updated"
  }'

# DELETE request
curl -X DELETE "https://api.example.com/v1/users/usr_123456" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

## SDKs & Libraries

### Official SDKs
- **JavaScript/TypeScript:** `npm install @example/api-sdk`
- **Python:** `pip install example-api`
- **Ruby:** `gem install example-api`
- **Go:** `go get github.com/example/api-sdk-go`

### Community Libraries
- [PHP SDK](https://github.com/community/example-php)
- [Java SDK](https://github.com/community/example-java)
- [.NET SDK](https://github.com/community/example-dotnet)

---

## Changelog

### Version 1.0.0 (2024-01-15)
- Initial API release
- User management endpoints
- Authentication system
- Rate limiting

### Version 0.9.0 (2023-12-01)
- Beta release
- Core functionality
- Limited access

---

## Support

### Resources
- **Documentation:** https://docs.example.com
- **API Status:** https://status.example.com
- **Support Portal:** https://support.example.com

### Contact
- **Email:** api-support@example.com
- **Developer Forum:** https://forum.example.com
- **GitHub Issues:** https://github.com/example/api/issues

### FAQ

**Q: How do I get an API key?**  
A: Sign up at https://example.com/developers and navigate to the API Keys section.

**Q: What are the rate limits?**  
A: Default limit is 100 requests per hour. Authenticated users get 1,000 requests per hour.

**Q: Is there a sandbox environment?**  
A: Yes, use https://sandbox-api.example.com for testing.

---

## Appendix

### Status Codes Summary
| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created |
| 204 | No Content |
| 400 | Bad Request |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not Found |
| 429 | Too Many Requests |
| 500 | Internal Server Error |

### Glossary
- **API Key:** Unique identifier for authentication
- **Endpoint:** Specific URL for API functionality
- **Payload:** Data sent in request body
- **Rate Limit:** Maximum requests allowed per time period
- **Webhook:** HTTP callback for events