# Data Profiler Agent

## Purpose
Analyzes actual data patterns, distributions, and quality to inform intelligent UI component selection and validation rules.

## Capabilities

### Statistical Analysis
- Data type distribution
- Null value percentages
- Unique value counts
- Min/max/average for numerics
- String length patterns
- Date range analysis
- Frequency distributions

### Pattern Recognition
- Email format detection
- Phone number patterns
- URL identification
- Geographic data (coordinates, addresses)
- Currency formats
- File paths and names
- JSON/XML content

### Data Quality Metrics
- Completeness scores
- Consistency checking
- Duplicate detection
- Outlier identification
- Data freshness
- Referential integrity

## Profiling Process

```javascript
// Sample profiling for a user table
const profileResults = {
  "users": {
    "row_count": 15420,
    "columns": {
      "email": {
        "data_type": "string",
        "distinct_count": 15420,
        "null_percentage": 0,
        "patterns": [
          {
            "pattern": "^[a-z]+\\.[a-z]+@company\\.com$",
            "percentage": 65,
            "example": "john.doe@company.com"
          },
          {
            "pattern": "^[a-z]+@(gmail|yahoo|outlook)\\.com$",
            "percentage": 35,
            "example": "user@gmail.com"
          }
        ],
        "ui_recommendation": "email_input_with_validation"
      },
      "created_at": {
        "data_type": "timestamp",
        "min": "2020-01-15",
        "max": "2024-01-20",
        "null_percentage": 0,
        "distribution": "steady_growth",
        "ui_recommendation": "date_range_picker"
      },
      "status": {
        "data_type": "string",
        "distinct_values": ["active", "inactive", "pending"],
        "distribution": {
          "active": 78,
          "inactive": 18,
          "pending": 4
        },
        "ui_recommendation": "select_dropdown"
      },
      "revenue": {
        "data_type": "decimal",
        "min": 0,
        "max": 1250000.50,
        "average": 45230.75,
        "percentiles": {
          "25": 12000,
          "50": 35000,
          "75": 65000,
          "95": 125000
        },
        "currency_pattern": "USD",
        "ui_recommendation": "currency_input"
      }
    }
  }
}
```

## UI Component Recommendations

### Based on Data Patterns
```json
{
  "component_mappings": [
    {
      "pattern": "email",
      "component": "EmailInput",
      "validation": "email",
      "features": ["autocomplete", "domain_suggestions"]
    },
    {
      "pattern": "phone",
      "component": "PhoneInput",
      "validation": "international_phone",
      "features": ["country_code_selector", "format_preview"]
    },
    {
      "pattern": "url",
      "component": "URLInput",
      "validation": "valid_url",
      "features": ["protocol_autocomplete", "preview_link"]
    },
    {
      "pattern": "currency",
      "component": "CurrencyInput",
      "validation": "positive_decimal",
      "features": ["currency_symbol", "thousand_separator"]
    },
    {
      "pattern": "percentage",
      "component": "PercentageSlider",
      "validation": "range_0_100",
      "features": ["visual_slider", "precise_input"]
    }
  ]
}
```

## Smart Defaults Detection

```json
{
  "smart_defaults": [
    {
      "column": "status",
      "default_value": "active",
      "confidence": 0.95,
      "reason": "78% of existing records"
    },
    {
      "column": "country",
      "default_value": "US",
      "confidence": 0.82,
      "reason": "Most common value"
    },
    {
      "column": "notification_preferences",
      "default_value": {
        "email": true,
        "sms": false
      },
      "confidence": 0.90,
      "reason": "Typical user preference pattern"
    }
  ]
}
```

## Validation Rules Generation

```javascript
// Auto-generated validation based on data profile
const validationRules = {
  "email": {
    "required": true,
    "type": "email",
    "unique": true,
    "pattern": /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  },
  "age": {
    "type": "integer",
    "min": 18,  // Based on data minimum
    "max": 120, // Based on data maximum + buffer
  },
  "username": {
    "required": true,
    "type": "string",
    "minLength": 3,   // Based on shortest found
    "maxLength": 20,  // Based on longest found
    "pattern": /^[a-zA-Z0-9_]+$/
  }
}
```

## Integration Points
- Receives schema from Schema Analyzer
- Informs Form Generator about input types
- Provides validation rules to Validation Engineer
- Shares insights with Dashboard Designer

## Performance Considerations
- Sample large tables (configurable %)
- Cache profiling results
- Incremental profiling on data changes
- Background profiling for large datasets

## Privacy & Security
- PII detection and masking
- Sensitive data flagging
- Compliance checking (GDPR, HIPAA)
- Audit trail of profiling activities