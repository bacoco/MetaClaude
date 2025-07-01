# Constraint Validator Agent

## Purpose
Ensures data integrity by identifying, validating, and implementing database constraints in the admin panel's forms and operations.

## Capabilities

### Constraint Types
- Primary Key constraints
- Foreign Key relationships
- Unique constraints
- Check constraints
- Not Null requirements
- Default values
- Domain constraints
- Trigger-based rules

### Advanced Validation
- Cross-table validation
- Computed field constraints
- Temporal constraints
- Business rule validation
- Conditional constraints
- Regular expression patterns
- Custom validation functions

## Constraint Analysis

### Database-Level Constraints
```sql
-- Example constraints from database
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sku VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    price DECIMAL(10,2) CHECK (price > 0),
    cost DECIMAL(10,2) CHECK (cost >= 0),
    stock_quantity INTEGER DEFAULT 0 CHECK (stock_quantity >= 0),
    category_id INTEGER REFERENCES categories(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Business constraint
    CONSTRAINT profitable CHECK (price > cost * 1.2)
);

-- Trigger-based constraint
CREATE TRIGGER prevent_negative_stock
BEFORE UPDATE ON products
FOR EACH ROW
WHEN (NEW.stock_quantity < 0)
BEGIN
    SIGNAL SQLSTATE '45000' 
    SET MESSAGE_TEXT = 'Stock cannot be negative';
END;
```

### Translated Validation Rules
```json
{
  "products": {
    "fields": {
      "sku": {
        "constraints": [
          {
            "type": "required",
            "message": "SKU is required"
          },
          {
            "type": "unique",
            "message": "SKU must be unique",
            "async": true
          },
          {
            "type": "maxLength",
            "value": 50,
            "message": "SKU cannot exceed 50 characters"
          }
        ]
      },
      "price": {
        "constraints": [
          {
            "type": "required",
            "message": "Price is required"
          },
          {
            "type": "min",
            "value": 0.01,
            "message": "Price must be greater than 0"
          },
          {
            "type": "precision",
            "integer": 8,
            "decimal": 2,
            "message": "Price format: up to 8 digits with 2 decimal places"
          }
        ]
      },
      "cost": {
        "constraints": [
          {
            "type": "min",
            "value": 0,
            "message": "Cost cannot be negative"
          },
          {
            "type": "custom",
            "validator": "profitabilityCheck",
            "message": "Price must be at least 20% higher than cost",
            "dependencies": ["price"]
          }
        ]
      },
      "category_id": {
        "constraints": [
          {
            "type": "foreignKey",
            "reference": "categories.id",
            "message": "Invalid category",
            "async": true
          }
        ]
      }
    },
    "form_constraints": [
      {
        "type": "cross_field",
        "fields": ["price", "cost"],
        "validator": "price > cost * 1.2",
        "message": "Price must provide at least 20% profit margin"
      }
    ]
  }
}
```

## Validation Implementation

### Client-Side Validation
```javascript
// Generated validation schema
const productValidationSchema = {
  sku: [
    { rule: 'required', message: 'SKU is required' },
    { rule: 'maxLength:50', message: 'SKU cannot exceed 50 characters' },
    { rule: 'unique', async: true, endpoint: '/api/validate/sku' }
  ],
  price: [
    { rule: 'required', message: 'Price is required' },
    { rule: 'min:0.01', message: 'Price must be greater than 0' },
    { rule: 'decimal:8,2', message: 'Invalid price format' }
  ],
  cost: [
    { rule: 'min:0', message: 'Cost cannot be negative' },
    {
      rule: 'custom',
      validator: (value, formData) => {
        return formData.price > value * 1.2;
      },
      message: 'Price must be at least 20% higher than cost',
      dependencies: ['price']
    }
  ]
};
```

### Server-Side Validation
```python
# Generated validation class
class ProductValidator:
    def validate_sku(self, value, existing_id=None):
        if not value:
            raise ValidationError("SKU is required")
        if len(value) > 50:
            raise ValidationError("SKU cannot exceed 50 characters")
        if Product.objects.filter(sku=value).exclude(id=existing_id).exists():
            raise ValidationError("SKU must be unique")
        return value
    
    def validate_price_cost_relationship(self, data):
        if 'price' in data and 'cost' in data:
            if data['price'] <= data['cost'] * 1.2:
                raise ValidationError(
                    "Price must be at least 20% higher than cost"
                )
```

## Complex Constraint Patterns

### Temporal Constraints
```json
{
  "temporal_constraints": [
    {
      "field": "end_date",
      "constraint": "must_be_after",
      "reference": "start_date",
      "message": "End date must be after start date"
    },
    {
      "field": "birth_date",
      "constraint": "age_range",
      "min_age": 18,
      "max_age": 120,
      "message": "Must be between 18 and 120 years old"
    }
  ]
}
```

### Conditional Constraints
```json
{
  "conditional_constraints": [
    {
      "condition": "payment_method === 'credit_card'",
      "apply_constraints": {
        "card_number": ["required", "credit_card"],
        "cvv": ["required", "digits:3,4"],
        "expiry_date": ["required", "future_date"]
      }
    },
    {
      "condition": "shipping_method === 'express'",
      "apply_constraints": {
        "delivery_date": ["required", "within_days:3"]
      }
    }
  ]
}
```

## Error Handling

### User-Friendly Messages
```json
{
  "error_messages": {
    "foreign_key_violation": {
      "default": "Related record not found",
      "specific": {
        "category_id": "Please select a valid category",
        "user_id": "User account no longer exists"
      }
    },
    "unique_violation": {
      "default": "This value already exists",
      "specific": {
        "email": "This email is already registered",
        "sku": "A product with this SKU already exists"
      }
    },
    "check_constraint": {
      "default": "Value does not meet requirements",
      "specific": {
        "age_check": "Must be 18 years or older",
        "price_check": "Price must be positive"
      }
    }
  }
}
```

## Integration Points
- Receives schema from Schema Analyzer
- Works with Form Generator for UI validation
- Coordinates with Validation Engineer
- Informs Error State Designer

## Best Practices
1. Validate on both client and server
2. Provide clear, actionable error messages
3. Show validation errors in context
4. Handle async validation gracefully
5. Cache validation results when appropriate
6. Group related validation errors
7. Implement progressive validation