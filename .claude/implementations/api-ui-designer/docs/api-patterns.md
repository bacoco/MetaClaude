# API Patterns and UI Mappings

This guide outlines common API patterns and their corresponding UI component mappings for automatic interface generation.

## Table of Contents
- [RESTful CRUD Operations](#restful-crud-operations)
- [GraphQL Queries and Mutations](#graphql-queries-and-mutations)
- [WebSocket Real-time Patterns](#websocket-real-time-patterns)
- [Pagination Patterns](#pagination-patterns)
- [Search and Filter Patterns](#search-and-filter-patterns)
- [Authentication Patterns](#authentication-patterns)
- [File Upload Patterns](#file-upload-patterns)

## RESTful CRUD Operations

### List/Collection Pattern
**API Pattern:**
```http
GET /api/users
Response: Array of objects
```

**UI Mapping:**
```typescript
// Component: DataTable or DataGrid
interface ListUIPattern {
  component: 'DataTable' | 'CardGrid' | 'ListView';
  features: {
    sorting: boolean;
    filtering: boolean;
    selection: 'single' | 'multiple' | 'none';
    actions: ['view', 'edit', 'delete'];
  };
}
```

**Example Implementation:**
```jsx
<DataTable
  endpoint="/api/users"
  columns={[
    { field: 'name', header: 'Name', sortable: true },
    { field: 'email', header: 'Email', sortable: true },
    { field: 'status', header: 'Status', badge: true }
  ]}
  actions={[
    { icon: 'eye', label: 'View', onClick: (row) => navigate(`/users/${row.id}`) },
    { icon: 'edit', label: 'Edit', onClick: (row) => openEditModal(row) },
    { icon: 'trash', label: 'Delete', onClick: (row) => confirmDelete(row) }
  ]}
/>
```

### Create Pattern
**API Pattern:**
```http
POST /api/users
Body: { name, email, role }
```

**UI Mapping:**
```typescript
// Component: Form with Modal or Page
interface CreateUIPattern {
  component: 'Modal' | 'Page' | 'Drawer';
  form: {
    layout: 'vertical' | 'horizontal' | 'grid';
    validation: 'onSubmit' | 'onChange' | 'onBlur';
    submitButton: { text: string; position: 'bottom' | 'top' };
  };
}
```

**Example Implementation:**
```jsx
<CreateModal
  title="Create New User"
  endpoint="/api/users"
  fields={[
    { name: 'name', type: 'text', required: true, label: 'Full Name' },
    { name: 'email', type: 'email', required: true, label: 'Email Address' },
    { name: 'role', type: 'select', options: roles, label: 'User Role' }
  ]}
  onSuccess={(data) => {
    showToast('User created successfully');
    refreshList();
  }}
/>
```

### Read/Detail Pattern
**API Pattern:**
```http
GET /api/users/:id
Response: Single object with nested data
```

**UI Mapping:**
```typescript
// Component: Detail View or Card
interface DetailUIPattern {
  component: 'DetailPage' | 'DetailCard' | 'Tabs';
  layout: {
    sections: Array<{
      title: string;
      fields: Array<{ label: string; value: string }>;
    }>;
    actions: Array<'edit' | 'delete' | 'duplicate'>;
  };
}
```

### Update Pattern
**API Pattern:**
```http
PUT /api/users/:id
PATCH /api/users/:id
Body: { partial or full object }
```

**UI Mapping:**
```typescript
// Component: Edit Form
interface UpdateUIPattern {
  component: 'EditForm' | 'InlineEdit' | 'QuickEdit';
  mode: 'full' | 'partial' | 'inline';
  confirmation: boolean;
}
```

### Delete Pattern
**API Pattern:**
```http
DELETE /api/users/:id
```

**UI Mapping:**
```typescript
// Component: Confirmation Dialog
interface DeleteUIPattern {
  component: 'ConfirmDialog' | 'ActionButton';
  confirmation: {
    title: string;
    message: string;
    type: 'danger' | 'warning';
  };
}
```

## GraphQL Queries and Mutations

### Complex Query Pattern
**API Pattern:**
```graphql
query GetUserWithPosts($userId: ID!) {
  user(id: $userId) {
    id
    name
    posts {
      id
      title
      comments {
        id
        content
      }
    }
  }
}
```

**UI Mapping:**
```typescript
// Component: Master-Detail Layout
interface GraphQLQueryUIPattern {
  component: 'MasterDetail' | 'NestedAccordion' | 'TabsWithSections';
  dataStructure: {
    master: { entity: string; fields: string[] };
    details: Array<{
      entity: string;
      relationship: 'oneToMany' | 'oneToOne';
      display: 'table' | 'cards' | 'list';
    }>;
  };
}
```

**Example Implementation:**
```jsx
<MasterDetailLayout
  query={GET_USER_WITH_POSTS}
  variables={{ userId }}
  master={{
    component: UserProfile,
    fields: ['name', 'email', 'avatar']
  }}
  details={[
    {
      title: 'Posts',
      component: PostsList,
      emptyMessage: 'No posts yet'
    },
    {
      title: 'Activity',
      component: ActivityTimeline
    }
  ]}
/>
```

### Mutation with Optimistic Updates
**API Pattern:**
```graphql
mutation UpdateUserStatus($id: ID!, $status: Status!) {
  updateUserStatus(id: $id, status: $status) {
    id
    status
    updatedAt
  }
}
```

**UI Mapping:**
```jsx
<StatusToggle
  mutation={UPDATE_USER_STATUS}
  optimisticResponse={(current, newStatus) => ({
    ...current,
    status: newStatus,
    updatedAt: new Date()
  })}
  options={['active', 'inactive', 'pending']}
/>
```

## WebSocket Real-time Patterns

### Live Updates Pattern
**API Pattern:**
```javascript
ws.on('user:updated', (data) => { /* handle update */ })
ws.on('user:deleted', (id) => { /* handle deletion */ })
```

**UI Mapping:**
```typescript
// Component: Real-time List or Dashboard
interface WebSocketUIPattern {
  component: 'LiveList' | 'Dashboard' | 'NotificationFeed';
  indicators: {
    connectionStatus: boolean;
    lastUpdate: boolean;
    animation: 'pulse' | 'fade' | 'slide';
  };
}
```

**Example Implementation:**
```jsx
<LiveDataTable
  initialData={users}
  wsEndpoint="wss://api.example.com/users"
  events={{
    'user:created': (user) => addRow(user),
    'user:updated': (user) => updateRow(user),
    'user:deleted': (id) => removeRow(id)
  }}
  showLiveIndicator
  animateChanges
/>
```

### Chat/Messaging Pattern
**API Pattern:**
```javascript
ws.emit('message:send', { text, channelId })
ws.on('message:received', (message) => { /* display message */ })
```

**UI Mapping:**
```jsx
<ChatInterface
  channel={channelId}
  onSend={(text) => ws.emit('message:send', { text, channelId })}
  onTyping={() => ws.emit('user:typing', { channelId })}
  features={{
    typing: true,
    reactions: true,
    threads: true,
    fileUpload: true
  }}
/>
```

## Pagination Patterns

### Offset-based Pagination
**API Pattern:**
```http
GET /api/users?page=1&limit=20
Response: { data: [], total: 100, page: 1, totalPages: 5 }
```

**UI Mapping:**
```jsx
<PaginatedTable
  endpoint="/api/users"
  pageSize={20}
  pagination={{
    type: 'offset',
    showPageSize: true,
    pageSizeOptions: [10, 20, 50, 100],
    showJumpToPage: true
  }}
/>
```

### Cursor-based Pagination
**API Pattern:**
```http
GET /api/feed?cursor=xyz123&limit=20
Response: { data: [], nextCursor: 'abc456', hasMore: true }
```

**UI Mapping:**
```jsx
<InfiniteScrollList
  endpoint="/api/feed"
  loadMore={(cursor) => fetch(`/api/feed?cursor=${cursor}&limit=20`)}
  renderItem={(item) => <FeedCard {...item} />}
  loader={<SkeletonCard />}
/>
```

## Search and Filter Patterns

### Full-text Search
**API Pattern:**
```http
GET /api/search?q=user+query&type=all
```

**UI Mapping:**
```jsx
<SearchInterface
  endpoint="/api/search"
  features={{
    autocomplete: true,
    suggestions: true,
    history: true,
    filters: ['type', 'date', 'status']
  }}
  resultsComponent={SearchResults}
/>
```

### Advanced Filtering
**API Pattern:**
```http
GET /api/products?category=electronics&price[min]=100&price[max]=500&brand[]=apple&brand[]=samsung
```

**UI Mapping:**
```jsx
<FilterPanel
  filters={[
    {
      type: 'multiselect',
      field: 'category',
      label: 'Categories',
      endpoint: '/api/categories'
    },
    {
      type: 'range',
      field: 'price',
      label: 'Price Range',
      min: 0,
      max: 10000,
      step: 100
    },
    {
      type: 'checkbox',
      field: 'brand',
      label: 'Brands',
      options: brands
    }
  ]}
  onFilter={(filters) => updateResults(filters)}
/>
```

## Authentication Patterns

### Login/Session Pattern
**API Pattern:**
```http
POST /api/auth/login
Body: { username, password }
Response: { token, user, expiresIn }
```

**UI Mapping:**
```jsx
<LoginForm
  endpoint="/api/auth/login"
  fields={[
    { name: 'username', type: 'text', icon: 'user' },
    { name: 'password', type: 'password', icon: 'lock' }
  ]}
  features={{
    rememberMe: true,
    forgotPassword: '/auth/forgot',
    socialLogin: ['google', 'github'],
    twoFactor: true
  }}
  onSuccess={(response) => {
    setAuth(response.token);
    navigate('/dashboard');
  }}
/>
```

## File Upload Patterns

### Single File Upload
**API Pattern:**
```http
POST /api/upload
Content-Type: multipart/form-data
Body: FormData with file
```

**UI Mapping:**
```jsx
<FileUpload
  endpoint="/api/upload"
  accept="image/*,application/pdf"
  maxSize={5 * 1024 * 1024} // 5MB
  preview={true}
  onUpload={(file) => {
    const formData = new FormData();
    formData.append('file', file);
    return fetch('/api/upload', { method: 'POST', body: formData });
  }}
/>
```

### Multi-file with Progress
**API Pattern:**
```http
POST /api/batch-upload
Body: Multiple files with metadata
```

**UI Mapping:**
```jsx
<BatchFileUploader
  endpoint="/api/batch-upload"
  multiple={true}
  maxFiles={10}
  features={{
    dragDrop: true,
    preview: true,
    progress: true,
    retry: true,
    chunks: true
  }}
  onProgress={(file, progress) => updateProgress(file.id, progress)}
  onComplete={(results) => showUploadSummary(results)}
/>
```

## Best Practices

1. **Consistency**: Use the same UI pattern for similar API patterns across your application
2. **Progressive Enhancement**: Start with basic patterns and add features based on API capabilities
3. **Error Handling**: Always map API error responses to appropriate UI feedback
4. **Loading States**: Implement skeleton screens or loading indicators for all async operations
5. **Optimistic Updates**: Use optimistic UI updates for better perceived performance
6. **Caching**: Implement appropriate caching strategies based on data volatility

## Pattern Detection Algorithm

```typescript
function detectUIPattern(endpoint: APIEndpoint): UIPattern {
  // Analyze method
  const method = endpoint.method.toUpperCase();
  
  // Analyze response type
  const responseType = endpoint.response?.type;
  const isArray = responseType === 'array';
  const isPaginated = endpoint.response?.properties?.includes('page');
  
  // Analyze request body
  const hasBody = endpoint.requestBody !== undefined;
  const bodyFields = endpoint.requestBody?.properties || [];
  
  // Pattern matching
  if (method === 'GET' && isArray) {
    if (isPaginated) return 'PaginatedList';
    return 'SimpleList';
  }
  
  if (method === 'GET' && !isArray) {
    return 'DetailView';
  }
  
  if (method === 'POST' && hasBody) {
    if (bodyFields.includes('file')) return 'FileUpload';
    return 'CreateForm';
  }
  
  if (method === 'PUT' || method === 'PATCH') {
    return 'EditForm';
  }
  
  if (method === 'DELETE') {
    return 'DeleteConfirmation';
  }
  
  return 'Custom';
}
```

This pattern detection can be extended to analyze more complex scenarios and automatically suggest the most appropriate UI components for any given API endpoint.