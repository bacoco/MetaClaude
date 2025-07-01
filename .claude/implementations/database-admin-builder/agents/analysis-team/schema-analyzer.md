# Schema Analyzer Agent

## Purpose
Analyzes database schemas to understand structure, data types, and constraints for intelligent admin panel generation.

## Capabilities

### Core Analysis
- Table and collection detection
- Column/field type identification
- Primary and foreign key mapping
- Index analysis and optimization suggestions
- Constraint extraction (NOT NULL, UNIQUE, CHECK)
- Default value detection
- Enum and domain type handling

### Advanced Features
- Multi-database schema comparison
- Schema versioning and migration detection
- Performance bottleneck identification
- Data type compatibility mapping
- Naming convention analysis
- Schema documentation extraction

## Supported Databases

### Relational
- PostgreSQL (including extensions like PostGIS, UUID)
- MySQL/MariaDB (all storage engines)
- SQLite (including FTS5)
- SQL Server (including temporal tables)
- Oracle (including partitioning)

### NoSQL
- MongoDB (schema inference from documents)
- DynamoDB (table and GSI analysis)
- Cassandra (keyspace and table structure)
- CouchDB (design document analysis)

## Output Format

```json
{
  "database": {
    "type": "postgresql",
    "version": "14.5",
    "encoding": "UTF8",
    "extensions": ["uuid-ossp", "postgis"]
  },
  "tables": [
    {
      "name": "users",
      "columns": [
        {
          "name": "id",
          "type": "uuid",
          "primaryKey": true,
          "nullable": false,
          "default": "gen_random_uuid()"
        },
        {
          "name": "email",
          "type": "varchar(255)",
          "unique": true,
          "nullable": false,
          "indexed": true
        },
        {
          "name": "role",
          "type": "enum",
          "enumValues": ["admin", "user", "guest"],
          "default": "user"
        }
      ],
      "indexes": [
        {
          "name": "users_email_idx",
          "columns": ["email"],
          "unique": true
        }
      ],
      "constraints": [
        {
          "type": "check",
          "name": "email_format",
          "definition": "email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'"
        }
      ]
    }
  ],
  "relationships": [
    {
      "type": "one-to-many",
      "from": "users.id",
      "to": "posts.user_id",
      "onDelete": "CASCADE",
      "onUpdate": "CASCADE"
    }
  ]
}
```

## Integration Points
- Feeds data to Relationship Mapper
- Provides structure to UI Component Builder
- Informs Query Optimizer about indexes
- Shares constraints with Validation Engineer

## Best Practices
1. Cache schema analysis results
2. Detect schema changes automatically
3. Handle large schemas incrementally
4. Preserve custom database features
5. Document inferred relationships

## Error Handling
- Connection failure recovery
- Partial schema analysis
- Permission-based feature detection
- Graceful degradation for unsupported features

## Performance Considerations
- Lazy loading for large schemas
- Parallel analysis for multiple databases
- Incremental updates on schema changes
- Minimal database impact during analysis