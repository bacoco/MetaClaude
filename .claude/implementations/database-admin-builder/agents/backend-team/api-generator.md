# API Generator Agent

## Purpose
Automatically generates RESTful and GraphQL APIs from database schemas with built-in best practices, security, and performance optimizations.

## Capabilities

### API Styles
- RESTful APIs (OpenAPI 3.0 compliant)
- GraphQL APIs with resolvers
- JSON-RPC endpoints
- gRPC services
- WebSocket real-time APIs
- Hybrid REST/GraphQL

### Advanced Features
- Automatic pagination
- Filtering and sorting
- Field selection/projection
- Nested resource expansion
- Batch operations
- Rate limiting
- API versioning
- HATEOAS links

## RESTful API Generation

### Endpoint Structure
```yaml
# Generated OpenAPI specification
openapi: 3.0.0
info:
  title: Admin Panel API
  version: 1.0.0
  
paths:
  /api/v1/products:
    get:
      summary: List products
      parameters:
        - name: page
          in: query
          schema:
            type: integer
            default: 1
        - name: limit
          in: query
          schema:
            type: integer
            default: 20
            maximum: 100
        - name: sort
          in: query
          schema:
            type: string
            enum: [name, price, created_at, -name, -price, -created_at]
        - name: filter
          in: query
          schema:
            type: object
            properties:
              category_id:
                type: integer
              price_min:
                type: number
              price_max:
                type: number
              in_stock:
                type: boolean
      responses:
        200:
          description: Product list
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    type: array
                    items:
                      $ref: '#/components/schemas/Product'
                  meta:
                    type: object
                    properties:
                      total:
                        type: integer
                      page:
                        type: integer
                      pages:
                        type: integer
                      limit:
                        type: integer
    
    post:
      summary: Create product
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/ProductInput'
      responses:
        201:
          description: Created product
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Product'
```

### Implementation Example (Node.js/Express)
```javascript
// Auto-generated Express routes
const router = express.Router();

// List products with pagination, filtering, and sorting
router.get('/api/v1/products', async (req, res) => {
  const {
    page = 1,
    limit = 20,
    sort = '-created_at',
    filter = {}
  } = req.query;
  
  const query = Product.query();
  
  // Apply filters
  if (filter.category_id) {
    query.where('category_id', filter.category_id);
  }
  if (filter.price_min) {
    query.where('price', '>=', filter.price_min);
  }
  if (filter.price_max) {
    query.where('price', '<=', filter.price_max);
  }
  
  // Apply sorting
  const sortField = sort.startsWith('-') ? sort.slice(1) : sort;
  const sortOrder = sort.startsWith('-') ? 'desc' : 'asc';
  query.orderBy(sortField, sortOrder);
  
  // Pagination
  const offset = (page - 1) * limit;
  const [{ count }] = await query.clone().count();
  const data = await query.limit(limit).offset(offset);
  
  res.json({
    data,
    meta: {
      total: count,
      page,
      pages: Math.ceil(count / limit),
      limit
    }
  });
});

// Batch operations
router.post('/api/v1/products/batch', async (req, res) => {
  const { operations } = req.body;
  const results = [];
  
  await db.transaction(async (trx) => {
    for (const op of operations) {
      switch (op.action) {
        case 'create':
          results.push(await Product.query(trx).insert(op.data));
          break;
        case 'update':
          results.push(await Product.query(trx)
            .patch(op.data)
            .where('id', op.id));
          break;
        case 'delete':
          results.push(await Product.query(trx)
            .delete()
            .where('id', op.id));
          break;
      }
    }
  });
  
  res.json({ results });
});
```

## GraphQL API Generation

### Schema Definition
```graphql
# Auto-generated GraphQL schema
type Product {
  id: ID!
  sku: String!
  name: String!
  description: String
  price: Float!
  cost: Float
  stockQuantity: Int!
  category: Category!
  createdAt: DateTime!
  updatedAt: DateTime!
  
  # Computed fields
  profitMargin: Float!
  inStock: Boolean!
  
  # Related data
  reviews(first: Int, after: String): ReviewConnection!
  orderItems(first: Int, after: String): OrderItemConnection!
}

type Query {
  products(
    first: Int
    after: String
    filter: ProductFilter
    orderBy: ProductOrderBy
  ): ProductConnection!
  
  product(id: ID!): Product
  
  productSearch(
    query: String!
    first: Int
    after: String
  ): ProductConnection!
}

type Mutation {
  createProduct(input: CreateProductInput!): Product!
  updateProduct(id: ID!, input: UpdateProductInput!): Product!
  deleteProduct(id: ID!): Boolean!
  
  # Batch operations
  batchCreateProducts(input: [CreateProductInput!]!): [Product!]!
  batchUpdateProducts(input: [BatchUpdateProductInput!]!): [Product!]!
  batchDeleteProducts(ids: [ID!]!): Int!
}

type Subscription {
  productCreated: Product!
  productUpdated(id: ID): Product!
  productDeleted: ID!
  inventoryChanged(productId: ID): InventoryUpdate!
}
```

### Resolver Implementation
```javascript
// Auto-generated GraphQL resolvers
const resolvers = {
  Query: {
    products: async (_, { first = 20, after, filter, orderBy }) => {
      const query = Product.query();
      
      // Apply filters
      if (filter) {
        Object.entries(filter).forEach(([key, value]) => {
          if (value !== undefined) {
            query.where(snakeCase(key), value);
          }
        });
      }
      
      // Apply ordering
      if (orderBy) {
        const { field, direction } = orderBy;
        query.orderBy(snakeCase(field), direction.toLowerCase());
      }
      
      // Cursor-based pagination
      if (after) {
        const cursor = decodeCursor(after);
        query.where('id', '>', cursor.id);
      }
      
      const items = await query.limit(first + 1);
      const hasNextPage = items.length > first;
      const edges = items.slice(0, first).map(item => ({
        node: item,
        cursor: encodeCursor({ id: item.id })
      }));
      
      return {
        edges,
        pageInfo: {
          hasNextPage,
          endCursor: edges[edges.length - 1]?.cursor
        }
      };
    }
  },
  
  Product: {
    profitMargin: (product) => {
      return ((product.price - product.cost) / product.price) * 100;
    },
    
    category: (product) => {
      return Category.query().findById(product.categoryId);
    },
    
    reviews: async (product, { first, after }) => {
      // Implement pagination for related data
      return getConnection(Review, { productId: product.id }, { first, after });
    }
  },
  
  Mutation: {
    createProduct: async (_, { input }, { user }) => {
      await authorize(user, 'products:create');
      
      const product = await Product.query().insert({
        ...input,
        createdBy: user.id
      });
      
      pubsub.publish('PRODUCT_CREATED', { productCreated: product });
      
      return product;
    }
  },
  
  Subscription: {
    productCreated: {
      subscribe: () => pubsub.asyncIterator(['PRODUCT_CREATED'])
    },
    
    inventoryChanged: {
      subscribe: withFilter(
        () => pubsub.asyncIterator(['INVENTORY_CHANGED']),
        (payload, variables) => {
          return !variables.productId || 
                 payload.inventoryChanged.productId === variables.productId;
        }
      )
    }
  }
};
```

## Advanced Features

### Field Selection
```javascript
// REST API with field selection
router.get('/api/v1/products/:id', async (req, res) => {
  const { fields } = req.query;
  const query = Product.query().findById(req.params.id);
  
  if (fields) {
    query.select(fields.split(','));
  }
  
  const product = await query;
  res.json(product);
});
```

### Nested Resource Expansion
```javascript
// Support ?expand=category,reviews
router.get('/api/v1/products/:id', async (req, res) => {
  const { expand } = req.query;
  const query = Product.query().findById(req.params.id);
  
  if (expand) {
    expand.split(',').forEach(relation => {
      query.withGraphFetched(relation);
    });
  }
  
  const product = await query;
  res.json(product);
});
```

## Integration Points
- Receives schema from Schema Analyzer
- Coordinates with Auth Builder for security
- Works with Query Optimizer for performance
- Integrates with Validation Engineer

## Best Practices
1. Version APIs from the start
2. Use consistent naming conventions
3. Implement proper error handling
4. Add comprehensive documentation
5. Include request/response examples
6. Support bulk operations
7. Implement idempotency for mutations