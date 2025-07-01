# Requirements Interpreter Agent

## Purpose
Translates business requirements and natural language descriptions into concrete admin panel features and configurations.

## Capabilities

### Natural Language Processing
- Requirement extraction from descriptions
- Feature priority identification
- Constraint recognition
- User role inference
- Workflow detection
- Integration needs analysis

### Business Logic Interpretation
- CRUD operation customization
- Approval workflow requirements
- Notification rule extraction
- Access control requirements
- Reporting needs identification
- Compliance requirement mapping

## Input Processing

### Example Natural Language Input
```text
"We need an admin panel for our e-commerce platform where:
- Store managers can manage products but can't change prices
- Only admins can access financial reports
- Orders need a multi-step approval process for amounts over $10,000
- Send email notifications when inventory is low
- Generate monthly sales reports automatically
- Support multiple currencies and languages"
```

### Interpreted Output
```json
{
  "requirements": {
    "user_roles": [
      {
        "name": "admin",
        "permissions": ["*"],
        "description": "Full system access"
      },
      {
        "name": "store_manager",
        "permissions": [
          "products:read",
          "products:create",
          "products:update:exclude[price]",
          "products:delete",
          "inventory:*"
        ],
        "description": "Product management without pricing"
      }
    ],
    "workflows": [
      {
        "name": "high_value_order_approval",
        "trigger": "order.amount > 10000",
        "steps": [
          "manager_review",
          "finance_approval",
          "final_authorization"
        ],
        "notifications": true
      }
    ],
    "automated_processes": [
      {
        "name": "low_inventory_alert",
        "condition": "inventory.quantity < inventory.minimum_stock",
        "action": "send_email",
        "recipients": ["store_manager", "admin"]
      },
      {
        "name": "monthly_sales_report",
        "schedule": "0 0 1 * *",
        "type": "report_generation",
        "format": ["pdf", "excel"]
      }
    ],
    "features": [
      {
        "name": "multi_currency",
        "priority": "high",
        "configuration": {
          "supported_currencies": ["USD", "EUR", "GBP"],
          "auto_conversion": true
        }
      },
      {
        "name": "multi_language",
        "priority": "medium",
        "configuration": {
          "supported_languages": ["en", "es", "fr"],
          "auto_translation": false
        }
      }
    ]
  }
}
```

## Feature Mapping

### Business Terms to Technical Features
```json
{
  "term_mappings": {
    "approval process": ["workflow_engine", "state_machine"],
    "audit trail": ["activity_logging", "change_tracking"],
    "bulk operations": ["batch_processing", "import_export"],
    "real-time updates": ["websockets", "server_sent_events"],
    "advanced search": ["elasticsearch", "full_text_search"],
    "reporting": ["dashboard", "analytics", "export"],
    "notifications": ["email", "in_app", "webhooks"],
    "multi-tenant": ["row_level_security", "schema_isolation"]
  }
}
```

## Constraint Detection

### Compliance Requirements
```json
{
  "compliance_detection": [
    {
      "pattern": "GDPR|data protection|privacy",
      "requirements": [
        "data_encryption",
        "audit_logging",
        "data_export",
        "right_to_deletion"
      ]
    },
    {
      "pattern": "HIPAA|medical|healthcare",
      "requirements": [
        "encryption_at_rest",
        "access_logging",
        "session_timeout",
        "data_retention_policy"
      ]
    },
    {
      "pattern": "financial|payment|PCI",
      "requirements": [
        "pci_compliance",
        "tokenization",
        "secure_transmission",
        "access_control"
      ]
    }
  ]
}
```

## UI/UX Preferences Extraction

```json
{
  "ui_preferences": {
    "complexity_level": "intermediate",
    "layout_style": "dashboard_focused",
    "mobile_priority": "responsive",
    "accessibility": "wcag_aa",
    "theme": "professional",
    "customization": {
      "branding": true,
      "layout": false,
      "workflows": true
    }
  }
}
```

## Priority Classification

### Feature Prioritization Matrix
```json
{
  "priorities": [
    {
      "level": "critical",
      "features": ["authentication", "authorization", "data_security"],
      "timeline": "immediate"
    },
    {
      "level": "high",
      "features": ["core_crud", "search", "basic_reporting"],
      "timeline": "phase_1"
    },
    {
      "level": "medium",
      "features": ["advanced_filters", "bulk_operations", "api_access"],
      "timeline": "phase_2"
    },
    {
      "level": "low",
      "features": ["themes", "advanced_analytics", "third_party_integrations"],
      "timeline": "future"
    }
  ]
}
```

## Integration Points
- Receives context from user input
- Coordinates with all other teams
- Influences Architecture decisions
- Guides Feature prioritization

## Best Practices
1. Clarify ambiguous requirements
2. Validate interpretations with examples
3. Map to existing patterns when possible
4. Document assumptions clearly
5. Maintain requirement traceability

## Output Integration
The interpreted requirements feed directly into:
- Access Control Manager (security requirements)
- Workflow Engine (business processes)
- UI Component Builder (interface preferences)
- API Generator (integration needs)
- Dashboard Designer (reporting requirements)