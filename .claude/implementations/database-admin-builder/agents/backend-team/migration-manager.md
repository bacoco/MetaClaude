# Migration Manager Agent

## Purpose
Manages database schema versioning, migrations, and safe schema updates with zero-downtime deployment strategies.

## Capabilities

### Migration Features
- Schema version control
- Forward and rollback migrations
- Data migrations
- Zero-downtime deployments
- Multi-database support
- Migration testing
- Automatic backup creation
- Schema drift detection

### Advanced Capabilities
- Blue-green deployments
- Gradual column migrations
- Index optimization
- Data transformation pipelines
- Cross-database migrations
- Schema synchronization
- Migration scheduling
- Conflict resolution

## Migration Generation

### Schema Change Detection
```javascript
class MigrationGenerator {
  async detectSchemaChanges(currentSchema, targetSchema) {
    const changes = {
      tables: {
        added: [],
        removed: [],
        modified: []
      },
      columns: {
        added: [],
        removed: [],
        modified: []
      },
      indexes: {
        added: [],
        removed: [],
        modified: []
      },
      constraints: {
        added: [],
        removed: [],
        modified: []
      }
    };
    
    // Compare tables
    const currentTables = new Set(Object.keys(currentSchema.tables));
    const targetTables = new Set(Object.keys(targetSchema.tables));
    
    // New tables
    for (const table of targetTables) {
      if (!currentTables.has(table)) {
        changes.tables.added.push(targetSchema.tables[table]);
      }
    }
    
    // Removed tables
    for (const table of currentTables) {
      if (!targetTables.has(table)) {
        changes.tables.removed.push(currentSchema.tables[table]);
      }
    }
    
    // Modified tables
    for (const table of currentTables) {
      if (targetTables.has(table)) {
        const tableChanges = this.compareTableSchemas(
          currentSchema.tables[table],
          targetSchema.tables[table]
        );
        
        if (tableChanges.hasChanges) {
          changes.tables.modified.push({
            table,
            changes: tableChanges
          });
        }
      }
    }
    
    return changes;
  }
  
  generateMigration(changes, options = {}) {
    const timestamp = new Date().toISOString().replace(/[^0-9]/g, '').slice(0, 14);
    const name = options.name || 'schema_update';
    const filename = `${timestamp}_${name}.js`;
    
    const migration = {
      filename,
      up: this.generateUpMigration(changes),
      down: this.generateDownMigration(changes),
      metadata: {
        generated: new Date(),
        changes: this.summarizeChanges(changes),
        breaking: this.detectBreakingChanges(changes)
      }
    };
    
    return migration;
  }
  
  generateUpMigration(changes) {
    const statements = [];
    
    // Create new tables
    changes.tables.added.forEach(table => {
      statements.push(this.generateCreateTable(table));
    });
    
    // Modify existing tables
    changes.tables.modified.forEach(({ table, changes }) => {
      // Add columns
      changes.columns.added.forEach(column => {
        statements.push(
          `ALTER TABLE ${table} ADD COLUMN ${this.generateColumnDefinition(column)}`
        );
      });
      
      // Modify columns (safe operations only)
      changes.columns.modified.forEach(({ column, from, to }) => {
        if (this.isSafeColumnModification(from, to)) {
          statements.push(
            `ALTER TABLE ${table} ALTER COLUMN ${column} ${this.generateColumnModification(from, to)}`
          );
        } else {
          // Generate gradual migration
          statements.push(...this.generateGradualColumnMigration(table, column, from, to));
        }
      });
      
      // Add indexes
      changes.indexes.added.forEach(index => {
        statements.push(this.generateCreateIndex(table, index));
      });
    });
    
    // Remove tables (with safety check)
    changes.tables.removed.forEach(table => {
      statements.push(`-- WARNING: Table removal requires manual confirmation`);
      statements.push(`-- DROP TABLE ${table.name};`);
    });
    
    return statements;
  }
}
```

### Zero-Downtime Migration Strategies
```javascript
class ZeroDowntimeMigrator {
  async performGradualMigration(migration) {
    const steps = [];
    
    // Phase 1: Add new columns/tables without removing old ones
    steps.push({
      name: 'add_new_schema',
      forward: async (db) => {
        for (const statement of migration.additive) {
          await db.raw(statement);
        }
      },
      rollback: async (db) => {
        for (const statement of migration.additiveRollback) {
          await db.raw(statement);
        }
      },
      validation: async (db) => {
        // Verify new schema exists
        return this.validateSchemaAdditions(db, migration.expectedAdditions);
      }
    });
    
    // Phase 2: Dual-write to both old and new schema
    steps.push({
      name: 'enable_dual_write',
      forward: async (db) => {
        // Create triggers for dual-write
        for (const trigger of migration.dualWriteTriggers) {
          await db.raw(trigger);
        }
      },
      rollback: async (db) => {
        for (const trigger of migration.dualWriteTriggers) {
          await db.raw(`DROP TRIGGER IF EXISTS ${trigger.name}`);
        }
      },
      validation: async (db) => {
        // Test dual-write is working
        return this.validateDualWrite(db, migration.testCases);
      }
    });
    
    // Phase 3: Backfill data
    steps.push({
      name: 'backfill_data',
      forward: async (db) => {
        await this.performBatchedBackfill(db, migration.backfillQueries);
      },
      rollback: async (db) => {
        // Usually no rollback for backfill
      },
      validation: async (db) => {
        return this.validateDataConsistency(db, migration.consistencyChecks);
      }
    });
    
    // Phase 4: Switch reads to new schema
    steps.push({
      name: 'switch_reads',
      forward: async (db) => {
        // Update application configuration
        await this.updateReadConfiguration(migration.readConfig);
      },
      rollback: async (db) => {
        await this.updateReadConfiguration(migration.oldReadConfig);
      },
      validation: async (db) => {
        return this.validateReadPerformance(db, migration.performanceThresholds);
      }
    });
    
    // Phase 5: Remove old schema
    steps.push({
      name: 'cleanup_old_schema',
      forward: async (db) => {
        // Wait for safety period
        await this.waitForSafetyPeriod(migration.safetyPeriod || 24 * 60 * 60 * 1000);
        
        // Remove old columns/tables
        for (const statement of migration.cleanup) {
          await db.raw(statement);
        }
      },
      rollback: async (db) => {
        // Restore old schema
        for (const statement of migration.restore) {
          await db.raw(statement);
        }
      },
      validation: async (db) => {
        return this.validateCleanup(db, migration.cleanupValidation);
      }
    });
    
    return steps;
  }
  
  async performBatchedBackfill(db, queries) {
    for (const query of queries) {
      const { sql, batchSize = 1000 } = query;
      let offset = 0;
      let hasMore = true;
      
      while (hasMore) {
        const result = await db.raw(`
          ${sql}
          LIMIT ${batchSize}
          OFFSET ${offset}
        `);
        
        hasMore = result.rows.length === batchSize;
        offset += batchSize;
        
        // Add delay to prevent overload
        await new Promise(resolve => setTimeout(resolve, 100));
      }
    }
  }
}
```

### Migration Execution Engine
```javascript
class MigrationRunner {
  constructor(config) {
    this.config = config;
    this.history = new MigrationHistory(config.database);
  }
  
  async runMigrations(options = {}) {
    const { 
      target = 'latest',
      dry = false,
      backup = true 
    } = options;
    
    try {
      // Create backup if requested
      if (backup && !dry) {
        await this.createBackup();
      }
      
      // Get pending migrations
      const pending = await this.getPendingMigrations(target);
      
      if (pending.length === 0) {
        console.log('Database is up to date');
        return;
      }
      
      console.log(`Found ${pending.length} pending migrations`);
      
      // Execute migrations
      for (const migration of pending) {
        await this.executeMigration(migration, { dry });
      }
      
      console.log('All migrations completed successfully');
      
    } catch (error) {
      console.error('Migration failed:', error.message);
      
      if (!dry) {
        console.log('Rolling back...');
        await this.rollbackToLastStable();
      }
      
      throw error;
    }
  }
  
  async executeMigration(migration, options = {}) {
    const { dry = false } = options;
    
    console.log(`\nExecuting migration: ${migration.name}`);
    
    if (dry) {
      console.log('DRY RUN - SQL to be executed:');
      console.log(migration.up.join(';\n'));
      return;
    }
    
    const startTime = Date.now();
    
    try {
      // Begin transaction
      await this.db.transaction(async (trx) => {
        // Execute up migration
        for (const statement of migration.up) {
          await trx.raw(statement);
        }
        
        // Record migration
        await this.history.recordMigration({
          name: migration.name,
          batch: await this.history.getNextBatch(),
          executedAt: new Date()
        });
      });
      
      const duration = Date.now() - startTime;
      console.log(`✓ Migration completed in ${duration}ms`);
      
      // Run post-migration validations
      if (migration.validations) {
        await this.runValidations(migration.validations);
      }
      
    } catch (error) {
      console.error(`✗ Migration failed: ${error.message}`);
      throw error;
    }
  }
  
  async rollback(steps = 1) {
    const executed = await this.history.getExecutedMigrations();
    const toRollback = executed.slice(0, steps);
    
    for (const migration of toRollback) {
      console.log(`Rolling back: ${migration.name}`);
      
      try {
        await this.db.transaction(async (trx) => {
          // Execute down migration
          for (const statement of migration.down) {
            await trx.raw(statement);
          }
          
          // Remove from history
          await this.history.removeMigration(migration.name);
        });
        
        console.log(`✓ Rolled back successfully`);
        
      } catch (error) {
        console.error(`✗ Rollback failed: ${error.message}`);
        throw error;
      }
    }
  }
}
```

### Schema Version Control
```javascript
class SchemaVersionControl {
  constructor(db) {
    this.db = db;
    this.initializeVersionTable();
  }
  
  async initializeVersionTable() {
    await this.db.raw(`
      CREATE TABLE IF NOT EXISTS schema_versions (
        id SERIAL PRIMARY KEY,
        version VARCHAR(255) NOT NULL UNIQUE,
        name VARCHAR(255) NOT NULL,
        executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        execution_time INTEGER,
        checksum VARCHAR(64),
        status VARCHAR(50) DEFAULT 'completed',
        metadata JSONB
      )
    `);
    
    await this.db.raw(`
      CREATE INDEX IF NOT EXISTS idx_schema_versions_version 
      ON schema_versions(version);
    `);
  }
  
  async getCurrentVersion() {
    const result = await this.db('schema_versions')
      .orderBy('executed_at', 'desc')
      .first();
    
    return result ? result.version : '0';
  }
  
  async recordVersion(migration) {
    const checksum = this.calculateChecksum(migration);
    
    await this.db('schema_versions').insert({
      version: migration.version,
      name: migration.name,
      execution_time: migration.executionTime,
      checksum,
      metadata: {
        author: migration.author,
        description: migration.description,
        breaking_changes: migration.breakingChanges || []
      }
    });
  }
  
  calculateChecksum(migration) {
    const content = migration.up.join('\n');
    return crypto.createHash('sha256')
      .update(content)
      .digest('hex');
  }
  
  async validateMigrationIntegrity(migration) {
    const recorded = await this.db('schema_versions')
      .where('version', migration.version)
      .first();
    
    if (recorded) {
      const currentChecksum = this.calculateChecksum(migration);
      
      if (recorded.checksum !== currentChecksum) {
        throw new Error(
          `Migration ${migration.version} has been modified after execution`
        );
      }
    }
    
    return true;
  }
}
```

### Data Migration Patterns
```javascript
class DataMigrator {
  // Transform data during migration
  async transformColumn(table, oldColumn, newColumn, transformer) {
    // Add new column
    await this.db.schema.table(table, (t) => {
      t.string(newColumn);
    });
    
    // Batch transform data
    const batchSize = 1000;
    let offset = 0;
    let hasMore = true;
    
    while (hasMore) {
      const rows = await this.db(table)
        .select('id', oldColumn)
        .whereNotNull(oldColumn)
        .limit(batchSize)
        .offset(offset);
      
      hasMore = rows.length === batchSize;
      
      if (rows.length > 0) {
        const updates = rows.map(row => ({
          id: row.id,
          [newColumn]: transformer(row[oldColumn])
        }));
        
        // Batch update
        await this.db.transaction(async (trx) => {
          for (const update of updates) {
            await trx(table)
              .where('id', update.id)
              .update({ [newColumn]: update[newColumn] });
          }
        });
      }
      
      offset += batchSize;
      
      // Progress reporting
      console.log(`Processed ${offset} rows...`);
    }
    
    // Drop old column after verification
    await this.db.schema.table(table, (t) => {
      t.dropColumn(oldColumn);
    });
  }
  
  // Split table migration
  async splitTable(sourceTable, mappings) {
    /*
    mappings = [
      {
        targetTable: 'users',
        columns: ['id', 'email', 'name'],
        keyColumn: 'id'
      },
      {
        targetTable: 'user_profiles',
        columns: ['bio', 'avatar', 'website'],
        foreignKey: { column: 'user_id', references: 'users.id' }
      }
    ]
    */
    
    for (const mapping of mappings) {
      // Create target table
      await this.createTableFromMapping(mapping);
      
      // Migrate data
      const columns = mapping.columns.join(', ');
      const insertColumns = mapping.foreignKey 
        ? [...mapping.columns, mapping.foreignKey.column].join(', ')
        : columns;
      
      await this.db.raw(`
        INSERT INTO ${mapping.targetTable} (${insertColumns})
        SELECT ${columns}${mapping.foreignKey ? ', id' : ''}
        FROM ${sourceTable}
      `);
    }
  }
}
```

### Migration Testing
```javascript
class MigrationTester {
  async testMigration(migration) {
    const tests = [];
    
    // Test forward migration
    tests.push({
      name: 'Forward migration',
      test: async () => {
        const testDb = await this.createTestDatabase();
        
        try {
          await this.applyMigration(testDb, migration.up);
          await this.validateSchema(testDb, migration.expectedSchema);
        } finally {
          await this.dropTestDatabase(testDb);
        }
      }
    });
    
    // Test rollback
    tests.push({
      name: 'Rollback migration',
      test: async () => {
        const testDb = await this.createTestDatabase();
        
        try {
          await this.applyMigration(testDb, migration.up);
          await this.applyMigration(testDb, migration.down);
          await this.validateSchema(testDb, migration.originalSchema);
        } finally {
          await this.dropTestDatabase(testDb);
        }
      }
    });
    
    // Test idempotency
    tests.push({
      name: 'Idempotency',
      test: async () => {
        const testDb = await this.createTestDatabase();
        
        try {
          await this.applyMigration(testDb, migration.up);
          // Apply again - should not fail
          await this.applyMigration(testDb, migration.up);
        } finally {
          await this.dropTestDatabase(testDb);
        }
      }
    });
    
    // Run all tests
    const results = [];
    for (const test of tests) {
      try {
        await test.test();
        results.push({ name: test.name, passed: true });
      } catch (error) {
        results.push({ 
          name: test.name, 
          passed: false, 
          error: error.message 
        });
      }
    }
    
    return results;
  }
}
```

## Integration Points
- Receives schema from Schema Analyzer
- Coordinates with Query Optimizer for index creation
- Works with Business Logic Creator for data migrations
- Integrates with backup systems

## Best Practices
1. Always test migrations on staging first
2. Create backups before major migrations
3. Use transactions when possible
4. Implement gradual migrations for large tables
5. Monitor migration performance
6. Document breaking changes clearly
7. Version control all migrations