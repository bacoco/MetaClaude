# Component Mapping Rules

Comprehensive guide for mapping API schemas to UI components with detailed rules and conventions.

## Table of Contents
- [Data Type Mappings](#data-type-mappings)
- [Field Name Conventions](#field-name-conventions)
- [Validation to UI Constraints](#validation-to-ui-constraints)
- [Relationship Mappings](#relationship-mappings)
- [Complex Type Handling](#complex-type-handling)
- [State Management Rules](#state-management-rules)
- [Accessibility Mappings](#accessibility-mappings)

## Data Type Mappings

### Primitive Types

| API Type | UI Component | Options | Example |
|----------|--------------|---------|---------|
| `string` | `TextInput` | maxLength, pattern | `<TextInput name="username" />` |
| `string` (email) | `EmailInput` | validation | `<EmailInput name="email" required />` |
| `string` (url) | `UrlInput` | validation | `<UrlInput name="website" />` |
| `string` (tel) | `PhoneInput` | format, country | `<PhoneInput name="phone" format="international" />` |
| `string` (long) | `TextArea` | rows, maxLength | `<TextArea name="description" rows={4} />` |
| `string` (enum) | `Select` | options | `<Select name="status" options={['active', 'inactive']} />` |
| `number` | `NumberInput` | min, max, step | `<NumberInput name="age" min={0} max={150} />` |
| `integer` | `IntegerInput` | min, max | `<IntegerInput name="quantity" min={1} />` |
| `boolean` | `Checkbox` / `Switch` | label | `<Switch name="isActive" label="Active" />` |
| `date` | `DatePicker` | format, min, max | `<DatePicker name="birthDate" max={today} />` |
| `datetime` | `DateTimePicker` | format, timezone | `<DateTimePicker name="appointment" />` |
| `time` | `TimePicker` | format, step | `<TimePicker name="startTime" step={15} />` |
| `file` | `FileInput` | accept, maxSize | `<FileInput name="avatar" accept="image/*" />` |

### Advanced String Patterns

```typescript
interface StringPatternMapping {
  pattern: RegExp;
  component: string;
  props: Record<string, any>;
}

const stringPatternMappings: StringPatternMapping[] = [
  {
    pattern: /^#[0-9A-F]{6}$/i,
    component: 'ColorPicker',
    props: { format: 'hex' }
  },
  {
    pattern: /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/,
    component: 'IPAddressInput',
    props: { version: 4 }
  },
  {
    pattern: /^[A-Z]{2}\d{2}\s?[A-Z]{3}$/,
    component: 'LicensePlateInput',
    props: { country: 'UK' }
  },
  {
    pattern: /password|secret/i,
    component: 'PasswordInput',
    props: { showToggle: true, strengthMeter: true }
  },
  {
    pattern: /^data:image\//,
    component: 'ImagePreview',
    props: { editable: true }
  }
];
```

### Numeric Patterns

```typescript
interface NumericMapping {
  conditions: {
    min?: number;
    max?: number;
    step?: number;
    suffix?: string;
  };
  component: string;
  props: Record<string, any>;
}

const numericMappings: NumericMapping[] = [
  {
    conditions: { min: 0, max: 100, suffix: '%' },
    component: 'PercentageInput',
    props: { showSlider: true }
  },
  {
    conditions: { min: 0, max: 5, step: 0.5 },
    component: 'RatingInput',
    props: { allowHalf: true }
  },
  {
    conditions: { suffix: '$' },
    component: 'CurrencyInput',
    props: { currency: 'USD', locale: 'en-US' }
  },
  {
    conditions: { min: -90, max: 90 },
    component: 'LatitudeInput',
    props: { showMap: true }
  }
];
```

## Field Name Conventions

### Automatic Component Selection by Field Name

```typescript
const fieldNameMappings: Record<string, ComponentConfig> = {
  // User fields
  'username': { component: 'TextInput', props: { icon: 'user', autocomplete: 'username' } },
  'email': { component: 'EmailInput', props: { icon: 'mail', autocomplete: 'email' } },
  'password': { component: 'PasswordInput', props: { icon: 'lock', strengthMeter: true } },
  'confirmPassword': { component: 'PasswordInput', props: { icon: 'lock', match: 'password' } },
  'firstName': { component: 'TextInput', props: { autocomplete: 'given-name' } },
  'lastName': { component: 'TextInput', props: { autocomplete: 'family-name' } },
  'fullName': { component: 'TextInput', props: { autocomplete: 'name' } },
  'avatar': { component: 'AvatarUpload', props: { shape: 'circle', maxSize: '5MB' } },
  
  // Contact fields
  'phone': { component: 'PhoneInput', props: { autocomplete: 'tel' } },
  'mobile': { component: 'PhoneInput', props: { autocomplete: 'tel', type: 'mobile' } },
  'fax': { component: 'PhoneInput', props: { autocomplete: 'tel', type: 'fax' } },
  'website': { component: 'UrlInput', props: { autocomplete: 'url' } },
  'address': { component: 'AddressInput', props: { autocomplete: 'street-address' } },
  'city': { component: 'TextInput', props: { autocomplete: 'address-level2' } },
  'state': { component: 'StateSelect', props: { autocomplete: 'address-level1' } },
  'country': { component: 'CountrySelect', props: { autocomplete: 'country' } },
  'zipCode': { component: 'ZipCodeInput', props: { autocomplete: 'postal-code' } },
  
  // Date/Time fields
  'birthDate': { component: 'DatePicker', props: { max: 'today', yearsBack: 100 } },
  'startDate': { component: 'DatePicker', props: { min: 'today' } },
  'endDate': { component: 'DatePicker', props: { min: 'startDate' } },
  'createdAt': { component: 'DateTimeDisplay', props: { format: 'relative' } },
  'updatedAt': { component: 'DateTimeDisplay', props: { format: 'relative' } },
  'scheduledAt': { component: 'DateTimePicker', props: { min: 'now', step: 15 } },
  
  // Status/State fields
  'status': { component: 'StatusSelect', props: { showIcon: true } },
  'isActive': { component: 'Switch', props: { label: 'Active' } },
  'isEnabled': { component: 'Switch', props: { label: 'Enabled' } },
  'isPublished': { component: 'Switch', props: { label: 'Published' } },
  'isDeleted': { component: 'Switch', props: { label: 'Deleted', color: 'danger' } },
  
  // Content fields
  'title': { component: 'TextInput', props: { size: 'large', maxLength: 100 } },
  'description': { component: 'TextArea', props: { rows: 3, maxLength: 500 } },
  'content': { component: 'RichTextEditor', props: { toolbar: 'full' } },
  'markdown': { component: 'MarkdownEditor', props: { preview: true } },
  'code': { component: 'CodeEditor', props: { language: 'auto' } },
  'json': { component: 'JsonEditor', props: { validate: true } },
  
  // Numeric fields
  'price': { component: 'CurrencyInput', props: { currency: 'USD' } },
  'amount': { component: 'NumberInput', props: { min: 0, step: 0.01 } },
  'quantity': { component: 'IntegerInput', props: { min: 0 } },
  'rating': { component: 'RatingInput', props: { max: 5 } },
  'score': { component: 'NumberInput', props: { min: 0, max: 100 } },
  'percentage': { component: 'PercentageInput', props: { min: 0, max: 100 } },
  
  // File fields
  'image': { component: 'ImageUpload', props: { accept: 'image/*', preview: true } },
  'logo': { component: 'ImageUpload', props: { accept: 'image/*', aspectRatio: '1:1' } },
  'document': { component: 'FileUpload', props: { accept: '.pdf,.doc,.docx' } },
  'video': { component: 'VideoUpload', props: { accept: 'video/*', maxSize: '100MB' } },
  
  // Special fields
  'color': { component: 'ColorPicker', props: { format: 'hex' } },
  'icon': { component: 'IconPicker', props: { set: 'material' } },
  'tags': { component: 'TagInput', props: { allowCreate: true } },
  'categories': { component: 'MultiSelect', props: { searchable: true } },
  'permissions': { component: 'PermissionMatrix', props: { grouped: true } }
};
```

### Field Grouping Rules

```typescript
interface FieldGroup {
  pattern: RegExp | string[];
  group: string;
  layout: 'horizontal' | 'vertical' | 'grid';
}

const fieldGroupingRules: FieldGroup[] = [
  {
    pattern: ['firstName', 'lastName'],
    group: 'Name',
    layout: 'horizontal'
  },
  {
    pattern: ['address', 'city', 'state', 'zipCode', 'country'],
    group: 'Address',
    layout: 'vertical'
  },
  {
    pattern: /^price|cost|amount|total/i,
    group: 'Pricing',
    layout: 'grid'
  },
  {
    pattern: /^is[A-Z]/,
    group: 'Settings',
    layout: 'vertical'
  }
];
```

## Validation to UI Constraints

### Validation Rule Mappings

```typescript
interface ValidationMapping {
  apiValidation: string;
  uiConstraint: string;
  componentProp: Record<string, any>;
}

const validationMappings: ValidationMapping[] = [
  // Required fields
  {
    apiValidation: 'required',
    uiConstraint: 'required',
    componentProp: { required: true, showAsterisk: true }
  },
  
  // String validations
  {
    apiValidation: 'minLength',
    uiConstraint: 'minLength',
    componentProp: { minLength: '{value}', showCounter: true }
  },
  {
    apiValidation: 'maxLength',
    uiConstraint: 'maxLength',
    componentProp: { maxLength: '{value}', showCounter: true }
  },
  {
    apiValidation: 'pattern',
    uiConstraint: 'pattern',
    componentProp: { pattern: '{value}', showValidation: true }
  },
  
  // Numeric validations
  {
    apiValidation: 'minimum',
    uiConstraint: 'min',
    componentProp: { min: '{value}', showLimits: true }
  },
  {
    apiValidation: 'maximum',
    uiConstraint: 'max',
    componentProp: { max: '{value}', showLimits: true }
  },
  {
    apiValidation: 'multipleOf',
    uiConstraint: 'step',
    componentProp: { step: '{value}' }
  },
  
  // Array validations
  {
    apiValidation: 'minItems',
    uiConstraint: 'minItems',
    componentProp: { minItems: '{value}', showCount: true }
  },
  {
    apiValidation: 'maxItems',
    uiConstraint: 'maxItems',
    componentProp: { maxItems: '{value}', showCount: true }
  },
  {
    apiValidation: 'uniqueItems',
    uiConstraint: 'unique',
    componentProp: { allowDuplicates: false }
  }
];
```

### Custom Validation UI Feedback

```typescript
interface ValidationFeedback {
  rule: string;
  severity: 'error' | 'warning' | 'info';
  message: string;
  display: 'inline' | 'tooltip' | 'summary';
}

const validationFeedbackRules: Record<string, ValidationFeedback> = {
  'email': {
    rule: 'email',
    severity: 'error',
    message: 'Please enter a valid email address',
    display: 'inline'
  },
  'strongPassword': {
    rule: 'pattern',
    severity: 'warning',
    message: 'Password should contain uppercase, lowercase, number, and special character',
    display: 'tooltip'
  },
  'futureDate': {
    rule: 'min',
    severity: 'error',
    message: 'Date must be in the future',
    display: 'inline'
  },
  'uniqueUsername': {
    rule: 'remote',
    severity: 'error',
    message: 'Username is already taken',
    display: 'inline'
  }
};
```

## Relationship Mappings

### One-to-Many Relationships

```typescript
interface OneToManyMapping {
  parentEntity: string;
  childEntity: string;
  displayComponent: string;
  features: string[];
}

const oneToManyMappings: OneToManyMapping[] = [
  {
    parentEntity: 'User',
    childEntity: 'Posts',
    displayComponent: 'NestedDataTable',
    features: ['inline-create', 'inline-edit', 'bulk-delete']
  },
  {
    parentEntity: 'Order',
    childEntity: 'OrderItems',
    displayComponent: 'EditableTable',
    features: ['add-row', 'remove-row', 'calculate-total']
  },
  {
    parentEntity: 'Category',
    childEntity: 'Products',
    displayComponent: 'CardGrid',
    features: ['filter', 'sort', 'infinite-scroll']
  }
];
```

### Many-to-Many Relationships

```typescript
interface ManyToManyMapping {
  entities: [string, string];
  displayComponent: string;
  selectionMode: 'checkbox' | 'transfer' | 'tags';
}

const manyToManyMappings: ManyToManyMapping[] = [
  {
    entities: ['User', 'Role'],
    displayComponent: 'TransferList',
    selectionMode: 'transfer'
  },
  {
    entities: ['Post', 'Tag'],
    displayComponent: 'TagSelector',
    selectionMode: 'tags'
  },
  {
    entities: ['Product', 'Category'],
    displayComponent: 'TreeSelect',
    selectionMode: 'checkbox'
  }
];
```

## Complex Type Handling

### Nested Object Mapping

```typescript
interface NestedObjectRule {
  depth: number;
  component: string;
  layout: string;
}

const nestedObjectRules: NestedObjectRule[] = [
  {
    depth: 1,
    component: 'FieldGroup',
    layout: 'card'
  },
  {
    depth: 2,
    component: 'CollapsibleSection',
    layout: 'accordion'
  },
  {
    depth: 3,
    component: 'TabbedForm',
    layout: 'tabs'
  }
];

// Example implementation
function mapNestedObject(schema: ObjectSchema, depth: number = 0): UIComponent {
  const rule = nestedObjectRules.find(r => r.depth === depth) || nestedObjectRules[0];
  
  return {
    component: rule.component,
    layout: rule.layout,
    fields: Object.entries(schema.properties).map(([key, value]) => {
      if (value.type === 'object') {
        return mapNestedObject(value, depth + 1);
      }
      return mapField(key, value);
    })
  };
}
```

### Array of Objects

```typescript
interface ArrayMapping {
  itemType: string;
  minItems?: number;
  maxItems?: number;
  component: string;
  features: string[];
}

const arrayMappings: ArrayMapping[] = [
  {
    itemType: 'string',
    component: 'TagInput',
    features: ['autocomplete', 'create-new']
  },
  {
    itemType: 'object',
    maxItems: 5,
    component: 'RepeatableFields',
    features: ['add', 'remove', 'reorder']
  },
  {
    itemType: 'object',
    minItems: 10,
    component: 'VirtualizedList',
    features: ['search', 'filter', 'bulk-actions']
  }
];
```

## State Management Rules

### Form State Mapping

```typescript
interface FormStateRule {
  apiState: string;
  uiState: string;
  behavior: Record<string, any>;
}

const formStateRules: FormStateRule[] = [
  {
    apiState: 'loading',
    uiState: 'disabled',
    behavior: { showSpinner: true, disableSubmit: true }
  },
  {
    apiState: 'error',
    uiState: 'error',
    behavior: { showError: true, scrollToError: true }
  },
  {
    apiState: 'success',
    uiState: 'success',
    behavior: { showSuccess: true, resetForm: true }
  },
  {
    apiState: 'validating',
    uiState: 'validating',
    behavior: { showValidatingIndicator: true }
  }
];
```

### Conditional Field Display

```typescript
interface ConditionalRule {
  condition: {
    field: string;
    operator: 'equals' | 'notEquals' | 'contains' | 'greaterThan';
    value: any;
  };
  action: 'show' | 'hide' | 'enable' | 'disable' | 'require';
  target: string | string[];
}

const conditionalRules: ConditionalRule[] = [
  {
    condition: { field: 'accountType', operator: 'equals', value: 'business' },
    action: 'show',
    target: ['companyName', 'taxId']
  },
  {
    condition: { field: 'hasShipping', operator: 'equals', value: true },
    action: 'require',
    target: ['shippingAddress']
  },
  {
    condition: { field: 'age', operator: 'greaterThan', value: 18 },
    action: 'enable',
    target: ['termsAcceptance']
  }
];
```

## Accessibility Mappings

### ARIA Attribute Mapping

```typescript
interface AccessibilityMapping {
  component: string;
  ariaAttributes: Record<string, string>;
  keyboardSupport: string[];
}

const accessibilityMappings: AccessibilityMapping[] = [
  {
    component: 'Select',
    ariaAttributes: {
      'role': 'combobox',
      'aria-expanded': '{isOpen}',
      'aria-haspopup': 'listbox',
      'aria-controls': '{listId}'
    },
    keyboardSupport: ['ArrowDown', 'ArrowUp', 'Enter', 'Escape']
  },
  {
    component: 'DatePicker',
    ariaAttributes: {
      'role': 'application',
      'aria-label': 'Date picker',
      'aria-describedby': '{helpTextId}'
    },
    keyboardSupport: ['ArrowKeys', 'PageUp', 'PageDown', 'Home', 'End']
  },
  {
    component: 'Slider',
    ariaAttributes: {
      'role': 'slider',
      'aria-valuemin': '{min}',
      'aria-valuemax': '{max}',
      'aria-valuenow': '{value}',
      'aria-orientation': 'horizontal'
    },
    keyboardSupport: ['ArrowLeft', 'ArrowRight', 'Home', 'End']
  }
];
```

### Label and Help Text Generation

```typescript
interface LabelMapping {
  fieldName: string;
  label: string;
  helpText?: string;
  placeholder?: string;
}

function generateLabels(fieldName: string): LabelMapping {
  // Convert camelCase to Title Case
  const label = fieldName
    .replace(/([A-Z])/g, ' $1')
    .replace(/^./, str => str.toUpperCase())
    .trim();
  
  // Generate contextual help text
  const helpTextMap: Record<string, string> = {
    email: 'We\'ll never share your email with anyone else',
    password: 'Must be at least 8 characters long',
    phone: 'Include country code for international numbers',
    birthDate: 'Must be 18 years or older',
    website: 'Include https:// or http://',
    taxId: 'Required for business accounts'
  };
  
  return {
    fieldName,
    label,
    helpText: helpTextMap[fieldName],
    placeholder: `Enter ${label.toLowerCase()}`
  };
}
```

## Advanced Mapping Examples

### Complete Field Mapping Function

```typescript
function mapApiFieldToUIComponent(
  fieldName: string,
  fieldSchema: FieldSchema,
  context: MappingContext
): UIComponentConfig {
  // 1. Check field name conventions
  if (fieldNameMappings[fieldName]) {
    return fieldNameMappings[fieldName];
  }
  
  // 2. Check data type
  const baseComponent = getComponentByType(fieldSchema.type);
  
  // 3. Apply validation constraints
  const constraints = mapValidationToConstraints(fieldSchema.validation);
  
  // 4. Check for patterns
  const pattern = detectPattern(fieldName, fieldSchema);
  if (pattern) {
    return applyPattern(pattern, baseComponent);
  }
  
  // 5. Apply relationship mappings
  if (fieldSchema.relationship) {
    return mapRelationship(fieldSchema.relationship);
  }
  
  // 6. Generate accessibility attributes
  const accessibility = generateAccessibility(fieldName, baseComponent);
  
  // 7. Apply conditional rules
  const conditionals = findConditionalRules(fieldName, context);
  
  return {
    component: baseComponent.component,
    props: {
      ...baseComponent.props,
      ...constraints,
      ...accessibility,
      name: fieldName,
      label: generateLabels(fieldName).label,
      conditionals
    }
  };
}
```

### Schema-Driven Form Generation

```typescript
function generateFormFromAPISchema(
  apiSchema: APISchema,
  options: FormGenerationOptions = {}
): FormConfig {
  const sections: FormSection[] = [];
  
  // Group fields by category
  const fieldGroups = groupFields(apiSchema.properties);
  
  // Generate sections
  for (const [groupName, fields] of Object.entries(fieldGroups)) {
    const section: FormSection = {
      title: groupName,
      fields: fields.map(field => 
        mapApiFieldToUIComponent(field.name, field.schema, { apiSchema })
      ),
      layout: determineLayout(fields),
      collapsible: options.collapsibleSections
    };
    
    sections.push(section);
  }
  
  return {
    sections,
    validation: mapAPIValidationToFormValidation(apiSchema.validation),
    submission: {
      endpoint: apiSchema.endpoint,
      method: apiSchema.method,
      headers: apiSchema.headers
    },
    layout: options.layout || 'vertical',
    features: {
      autoSave: options.autoSave,
      confirmExit: options.confirmExit,
      progressIndicator: sections.length > 3
    }
  };
}
```

This comprehensive mapping system ensures consistent and predictable UI generation from API schemas while maintaining flexibility for customization and edge cases.