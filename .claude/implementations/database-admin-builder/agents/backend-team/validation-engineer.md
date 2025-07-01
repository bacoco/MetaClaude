# Validation Engineer Agent

## Purpose
Implements comprehensive input validation, data sanitization, and business rule validation to ensure data integrity and security.

## Capabilities

### Validation Types
- Schema validation
- Type validation
- Format validation
- Business rule validation
- Cross-field validation
- Async validation
- Conditional validation
- Custom validators

### Sanitization Features
- HTML/XSS prevention
- SQL injection prevention
- Input normalization
- Data type coercion
- Whitelist filtering
- Character encoding
- File upload validation

## Validation Schema Generation

### Automatic Schema Creation
```javascript
class ValidationSchemaGenerator {
  generateFromModel(model, metadata) {
    const schema = {
      type: 'object',
      properties: {},
      required: [],
      additionalProperties: false
    };
    
    // Analyze model columns
    Object.entries(model.jsonSchema.properties).forEach(([field, config]) => {
      const validation = this.generateFieldValidation(field, config, metadata);
      schema.properties[field] = validation;
      
      if (config.required || metadata[field]?.required) {
        schema.required.push(field);
      }
    });
    
    // Add cross-field validations
    if (metadata.crossFieldValidations) {
      schema.allOf = metadata.crossFieldValidations.map(rule => 
        this.generateCrossFieldValidation(rule)
      );
    }
    
    return schema;
  }
  
  generateFieldValidation(field, config, metadata) {
    const validation = {
      type: this.mapSQLTypeToJSON(config.type)
    };
    
    // String validations
    if (validation.type === 'string') {
      if (config.maxLength) {
        validation.maxLength = config.maxLength;
      }
      if (config.minLength || metadata[field]?.minLength) {
        validation.minLength = config.minLength || metadata[field].minLength;
      }
      if (config.pattern || metadata[field]?.pattern) {
        validation.pattern = config.pattern || metadata[field].pattern;
      }
      if (config.enum) {
        validation.enum = config.enum;
      }
      
      // Format validations
      if (metadata[field]?.format) {
        validation.format = metadata[field].format; // email, uri, date, etc.
      }
    }
    
    // Number validations
    if (validation.type === 'number' || validation.type === 'integer') {
      if (config.minimum !== undefined) {
        validation.minimum = config.minimum;
      }
      if (config.maximum !== undefined) {
        validation.maximum = config.maximum;
      }
      if (metadata[field]?.multipleOf) {
        validation.multipleOf = metadata[field].multipleOf;
      }
    }
    
    // Custom validators
    if (metadata[field]?.custom) {
      validation['x-custom-validator'] = metadata[field].custom;
    }
    
    return validation;
  }
}
```

### Validation Implementation
```javascript
class Validator {
  constructor() {
    this.ajv = new Ajv({ 
      allErrors: true,
      coerceTypes: true,
      useDefaults: true,
      removeAdditional: true
    });
    
    // Add custom formats
    this.addCustomFormats();
    
    // Add custom keywords
    this.addCustomKeywords();
  }
  
  addCustomFormats() {
    // Email validation
    this.ajv.addFormat('email', {
      type: 'string',
      validate: (email) => {
        const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return re.test(email);
      }
    });
    
    // Phone validation
    this.ajv.addFormat('phone', {
      type: 'string',
      validate: (phone) => {
        const re = /^[\+]?[(]?[0-9]{3}[)]?[-\s\.]?[(]?[0-9]{3}[)]?[-\s\.]?[0-9]{4,6}$/;
        return re.test(phone);
      }
    });
    
    // URL validation
    this.ajv.addFormat('url', {
      type: 'string',
      validate: (url) => {
        try {
          new URL(url);
          return true;
        } catch {
          return false;
        }
      }
    });
    
    // Credit card validation
    this.ajv.addFormat('credit-card', {
      type: 'string',
      validate: (cc) => {
        // Luhn algorithm
        const digits = cc.replace(/\D/g, '');
        let sum = 0;
        let isEven = false;
        
        for (let i = digits.length - 1; i >= 0; i--) {
          let digit = parseInt(digits[i]);
          
          if (isEven) {
            digit *= 2;
            if (digit > 9) {
              digit -= 9;
            }
          }
          
          sum += digit;
          isEven = !isEven;
        }
        
        return sum % 10 === 0;
      }
    });
  }
  
  addCustomKeywords() {
    // Unique validation (async)
    this.ajv.addKeyword({
      keyword: 'unique',
      async: true,
      schema: true,
      compile: function(schema, parentSchema) {
        return async function validate(data) {
          if (!schema) return true;
          
          const { model, field, ignoreId } = schema;
          const query = model.query().where(field, data);
          
          if (ignoreId) {
            query.whereNot('id', ignoreId);
          }
          
          const exists = await query.first();
          
          if (exists) {
            validate.errors = [{
              keyword: 'unique',
              message: `This ${field} is already taken`
            }];
            return false;
          }
          
          return true;
        };
      }
    });
    
    // Conditional validation
    this.ajv.addKeyword({
      keyword: 'conditionalRequired',
      schema: true,
      compile: function(schema) {
        return function validate(data, dataPath, parentData) {
          const { field, condition } = schema;
          
          if (condition(parentData) && !data) {
            validate.errors = [{
              keyword: 'conditionalRequired',
              message: `${field} is required when ${condition.description}`
            }];
            return false;
          }
          
          return true;
        };
      }
    });
  }
  
  async validate(data, schema, options = {}) {
    const { 
      partial = false,
      context = {},
      sanitize = true 
    } = options;
    
    // Sanitize input first
    if (sanitize) {
      data = this.sanitize(data, schema);
    }
    
    // Handle partial validation for updates
    if (partial) {
      schema = this.makeSchemaPartial(schema);
    }
    
    // Compile and validate
    const validate = this.ajv.compile(schema);
    const valid = await validate(data);
    
    if (!valid) {
      const errors = this.formatErrors(validate.errors);
      throw new ValidationError(errors);
    }
    
    // Apply custom validators
    if (schema.customValidators) {
      await this.runCustomValidators(data, schema.customValidators, context);
    }
    
    return data;
  }
  
  formatErrors(ajvErrors) {
    const errors = {};
    
    ajvErrors.forEach(error => {
      const field = error.instancePath.slice(1) || error.params.missingProperty;
      const message = this.getErrorMessage(error);
      
      if (errors[field]) {
        errors[field].push(message);
      } else {
        errors[field] = [message];
      }
    });
    
    return errors;
  }
  
  getErrorMessage(error) {
    const messages = {
      required: 'This field is required',
      type: `Must be a ${error.params.type}`,
      minLength: `Must be at least ${error.params.limit} characters`,
      maxLength: `Must not exceed ${error.params.limit} characters`,
      minimum: `Must be at least ${error.params.limit}`,
      maximum: `Must not exceed ${error.params.limit}`,
      pattern: 'Invalid format',
      enum: `Must be one of: ${error.params.allowedValues.join(', ')}`,
      format: `Invalid ${error.params.format}`,
      unique: error.message || 'This value already exists'
    };
    
    return messages[error.keyword] || error.message || 'Invalid value';
  }
}
```

### Sanitization Implementation
```javascript
class Sanitizer {
  sanitize(data, schema) {
    const sanitized = {};
    
    Object.entries(data).forEach(([key, value]) => {
      if (schema.properties[key]) {
        sanitized[key] = this.sanitizeField(
          value, 
          schema.properties[key],
          key
        );
      }
    });
    
    return sanitized;
  }
  
  sanitizeField(value, fieldSchema, fieldName) {
    if (value === null || value === undefined) {
      return value;
    }
    
    const type = fieldSchema.type;
    
    switch (type) {
      case 'string':
        return this.sanitizeString(value, fieldSchema);
      
      case 'number':
      case 'integer':
        return this.sanitizeNumber(value, fieldSchema);
      
      case 'boolean':
        return this.sanitizeBoolean(value);
      
      case 'array':
        return this.sanitizeArray(value, fieldSchema);
      
      case 'object':
        return this.sanitizeObject(value, fieldSchema);
      
      default:
        return value;
    }
  }
  
  sanitizeString(value, schema) {
    let sanitized = String(value);
    
    // Trim whitespace
    sanitized = sanitized.trim();
    
    // XSS prevention
    if (!schema.allowHtml) {
      sanitized = this.escapeHtml(sanitized);
    }
    
    // SQL injection prevention
    if (schema.escapeSql) {
      sanitized = this.escapeSql(sanitized);
    }
    
    // Normalize unicode
    sanitized = sanitized.normalize('NFC');
    
    // Apply whitelist if specified
    if (schema.whitelist) {
      sanitized = sanitized.replace(
        new RegExp(`[^${schema.whitelist}]`, 'g'), 
        ''
      );
    }
    
    // Convert case if specified
    if (schema.lowercase) {
      sanitized = sanitized.toLowerCase();
    } else if (schema.uppercase) {
      sanitized = sanitized.toUpperCase();
    }
    
    return sanitized;
  }
  
  escapeHtml(str) {
    const map = {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#39;',
      '/': '&#x2F;'
    };
    
    return str.replace(/[&<>"'\/]/g, char => map[char]);
  }
  
  escapeSql(str) {
    // Basic SQL escape - in practice, use parameterized queries
    return str.replace(/['"\\]/g, char => '\\' + char);
  }
}
```

### Business Rule Validation
```javascript
class BusinessRuleValidator {
  constructor() {
    this.rules = new Map();
  }
  
  // Product validation rules
  addProductRules() {
    this.addRule('product.price_margin', {
      description: 'Price must be at least 20% above cost',
      validate: (product) => {
        if (product.price && product.cost) {
          return product.price >= product.cost * 1.2;
        }
        return true;
      },
      message: 'Price must provide at least 20% profit margin'
    });
    
    this.addRule('product.stock_level', {
      description: 'Stock cannot be negative',
      validate: (product) => {
        return product.stock_quantity >= 0;
      },
      message: 'Stock quantity cannot be negative'
    });
    
    this.addRule('product.sku_format', {
      description: 'SKU must follow company format',
      validate: (product) => {
        const skuPattern = /^[A-Z]{3}-\d{4}-[A-Z0-9]{2}$/;
        return skuPattern.test(product.sku);
      },
      message: 'SKU must follow format: XXX-0000-XX'
    });
  }
  
  // Order validation rules
  addOrderRules() {
    this.addRule('order.minimum_amount', {
      description: 'Order must meet minimum amount',
      validate: async (order, context) => {
        const minAmount = await context.getMinimumOrderAmount();
        return order.total >= minAmount;
      },
      message: 'Order does not meet minimum amount requirement'
    });
    
    this.addRule('order.delivery_date', {
      description: 'Delivery date must be realistic',
      validate: (order) => {
        if (order.delivery_date) {
          const minDate = new Date();
          minDate.setDate(minDate.getDate() + 2); // 2 days minimum
          return new Date(order.delivery_date) >= minDate;
        }
        return true;
      },
      message: 'Delivery date must be at least 2 days from now'
    });
  }
  
  async validateEntity(entity, entityType, context = {}) {
    const errors = [];
    const rulesPrefix = `${entityType}.`;
    
    for (const [ruleName, rule] of this.rules) {
      if (ruleName.startsWith(rulesPrefix)) {
        try {
          const isValid = await rule.validate(entity, context);
          
          if (!isValid) {
            errors.push({
              rule: ruleName,
              message: rule.message,
              field: ruleName.split('.')[1]
            });
          }
        } catch (error) {
          errors.push({
            rule: ruleName,
            message: `Validation error: ${error.message}`,
            field: ruleName.split('.')[1]
          });
        }
      }
    }
    
    if (errors.length > 0) {
      throw new BusinessRuleValidationError(errors);
    }
    
    return true;
  }
}
```

### File Upload Validation
```javascript
class FileValidator {
  constructor() {
    this.config = {
      maxSize: 10 * 1024 * 1024, // 10MB
      allowedTypes: [
        'image/jpeg',
        'image/png',
        'image/gif',
        'application/pdf',
        'application/vnd.ms-excel',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      ],
      allowedExtensions: [
        '.jpg', '.jpeg', '.png', '.gif', '.pdf', '.xls', '.xlsx'
      ]
    };
  }
  
  async validateFile(file, options = {}) {
    const config = { ...this.config, ...options };
    const errors = [];
    
    // Check file size
    if (file.size > config.maxSize) {
      errors.push({
        field: 'file',
        message: `File size exceeds maximum allowed size of ${config.maxSize / 1024 / 1024}MB`
      });
    }
    
    // Check MIME type
    if (!config.allowedTypes.includes(file.mimetype)) {
      errors.push({
        field: 'file',
        message: `File type ${file.mimetype} is not allowed`
      });
    }
    
    // Check extension
    const ext = path.extname(file.originalname).toLowerCase();
    if (!config.allowedExtensions.includes(ext)) {
      errors.push({
        field: 'file',
        message: `File extension ${ext} is not allowed`
      });
    }
    
    // Verify file content matches MIME type
    const fileType = await FileType.fromBuffer(file.buffer);
    if (fileType && fileType.mime !== file.mimetype) {
      errors.push({
        field: 'file',
        message: 'File content does not match declared type'
      });
    }
    
    // Scan for malware if configured
    if (config.scanForMalware) {
      const isSafe = await this.scanFile(file);
      if (!isSafe) {
        errors.push({
          field: 'file',
          message: 'File failed security scan'
        });
      }
    }
    
    if (errors.length > 0) {
      throw new ValidationError(errors);
    }
    
    return true;
  }
}
```

## Integration Points
- Receives constraints from Constraint Validator
- Works with API Generator for request validation
- Coordinates with Business Logic Creator
- Integrates with Form Generator for client-side validation

## Best Practices
1. Validate on both client and server
2. Never trust client-side validation alone
3. Sanitize all user input
4. Use parameterized queries for SQL
5. Implement rate limiting
6. Log validation failures
7. Provide clear error messages