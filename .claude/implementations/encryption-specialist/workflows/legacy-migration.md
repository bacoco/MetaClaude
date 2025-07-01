# Legacy System Encryption Migration Workflow

## Overview
This workflow guides the migration of an existing unencrypted system to a fully encrypted architecture with zero downtime and data integrity preservation.

## Prerequisites
- Full database backup completed
- Encryption keys provisioned in KMS/HSM
- Test environment available
- Rollback procedures documented

## Workflow Steps

### Phase 1: Assessment and Planning

#### 1.1 Data Discovery
```javascript
async function discoverSensitiveData(database) {
  const scanner = new DataScanner({
    patterns: {
      ssn: /^\d{3}-\d{2}-\d{4}$/,
      creditCard: /^\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}$/,
      email: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
      phone: /^\+?\d{10,15}$/
    }
  });
  
  const results = await scanner.scan(database);
  
  return {
    tables: results.tables,
    columns: results.sensitiveColumns,
    dataVolume: results.totalRows,
    classification: results.dataTypes
  };
}
```

#### 1.2 Performance Baseline
```javascript
async function establishBaseline(database) {
  const metrics = {
    queryPerformance: await measureQueryLatency(database),
    throughput: await measureThroughput(database),
    cpuUsage: await measureCPUUsage(database),
    ioOperations: await measureIOPS(database)
  };
  
  return {
    baseline: metrics,
    thresholds: {
      maxLatencyIncrease: '10%',
      minThroughput: metrics.throughput * 0.9,
      maxCPUIncrease: '15%'
    }
  };
}
```

### Phase 2: Shadow Table Implementation

#### 2.1 Create Shadow Tables
```sql
-- For each table with sensitive data
CREATE TABLE users_encrypted LIKE users;

-- Add encryption metadata columns
ALTER TABLE users_encrypted ADD COLUMN 
  encryption_key_id VARCHAR(255),
  encryption_algorithm VARCHAR(50),
  encrypted_at TIMESTAMP,
  migration_status ENUM('pending', 'migrated', 'verified');

-- Add indexes for performance
CREATE INDEX idx_migration_status ON users_encrypted(migration_status);
```

#### 2.2 Set Up Triggers
```javascript
async function setupDualWriteTriggers(table) {
  const encryptionService = new EncryptionService();
  
  // Create trigger function
  await db.query(`
    CREATE OR REPLACE FUNCTION sync_to_encrypted_${table}()
    RETURNS TRIGGER AS $$
    BEGIN
      -- Encrypt sensitive columns
      NEW.ssn_encrypted = encrypt_column(NEW.ssn);
      NEW.email_encrypted = encrypt_column(NEW.email);
      
      -- Insert into shadow table
      INSERT INTO ${table}_encrypted 
      SELECT NEW.*, current_timestamp, 'migrated'
      ON CONFLICT (id) DO UPDATE SET
        ssn_encrypted = EXCLUDED.ssn_encrypted,
        email_encrypted = EXCLUDED.email_encrypted,
        updated_at = current_timestamp;
        
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
  `);
  
  // Create triggers
  await db.query(`
    CREATE TRIGGER ${table}_encrypt_sync
    AFTER INSERT OR UPDATE ON ${table}
    FOR EACH ROW
    EXECUTE FUNCTION sync_to_encrypted_${table}();
  `);
}
```

### Phase 3: Historical Data Migration

#### 3.1 Batch Migration Process
```javascript
class BatchMigration {
  constructor(config) {
    this.batchSize = config.batchSize || 1000;
    this.parallelWorkers = config.workers || 4;
    this.encryptionService = new EncryptionService(config.kms);
  }
  
  async migrate(table, columns) {
    const totalRows = await this.getRowCount(table);
    const batches = Math.ceil(totalRows / this.batchSize);
    
    console.log(`Starting migration of ${totalRows} rows in ${batches} batches`);
    
    // Create worker pool
    const workers = [];
    for (let i = 0; i < this.parallelWorkers; i++) {
      workers.push(this.createWorker(i));
    }
    
    // Distribute batches to workers
    const queue = new BatchQueue(batches);
    await Promise.all(workers.map(worker => 
      this.processBatches(worker, queue, table, columns)
    ));
  }
  
  async processBatch(table, columns, offset) {
    // Fetch batch
    const rows = await db.query(`
      SELECT * FROM ${table}
      WHERE migration_status IS NULL
      ORDER BY id
      LIMIT ? OFFSET ?
    `, [this.batchSize, offset]);
    
    // Encrypt in parallel
    const encrypted = await Promise.all(
      rows.map(row => this.encryptRow(row, columns))
    );
    
    // Bulk insert
    await this.bulkInsertEncrypted(table, encrypted);
    
    // Update progress
    await this.updateProgress(table, rows.length);
  }
  
  async encryptRow(row, columns) {
    const encrypted = { ...row };
    
    for (const column of columns) {
      if (row[column]) {
        encrypted[`${column}_encrypted`] = await this.encryptionService.encrypt(
          row[column],
          { 
            keyId: this.config.keyId,
            context: { 
              table: table,
              column: column,
              rowId: row.id 
            }
          }
        );
      }
    }
    
    encrypted.encryption_key_id = this.config.keyId;
    encrypted.encryption_algorithm = 'AES-256-GCM';
    encrypted.encrypted_at = new Date();
    encrypted.migration_status = 'migrated';
    
    return encrypted;
  }
}
```

#### 3.2 Progress Monitoring
```javascript
class MigrationMonitor {
  constructor(tables) {
    this.tables = tables;
    this.startTime = Date.now();
  }
  
  async getProgress() {
    const progress = await Promise.all(
      this.tables.map(async table => {
        const total = await db.query(
          `SELECT COUNT(*) as total FROM ${table}`
        );
        const migrated = await db.query(
          `SELECT COUNT(*) as migrated FROM ${table}_encrypted 
           WHERE migration_status = 'migrated'`
        );
        
        return {
          table,
          total: total[0].total,
          migrated: migrated[0].migrated,
          percentage: (migrated[0].migrated / total[0].total) * 100,
          estimatedCompletion: this.estimateCompletion(
            migrated[0].migrated,
            total[0].total
          )
        };
      })
    );
    
    return {
      overall: this.calculateOverallProgress(progress),
      tables: progress,
      elapsed: Date.now() - this.startTime,
      performance: await this.getPerformanceMetrics()
    };
  }
  
  async displayProgress() {
    const progress = await this.getProgress();
    
    console.clear();
    console.log('=== Migration Progress ===\n');
    
    progress.tables.forEach(table => {
      const bar = this.createProgressBar(table.percentage);
      console.log(`${table.table}: ${bar} ${table.percentage.toFixed(1)}%`);
      console.log(`  Migrated: ${table.migrated.toLocaleString()} / ${table.total.toLocaleString()}`);
      console.log(`  ETA: ${table.estimatedCompletion}\n`);
    });
    
    console.log(`Overall: ${progress.overall.toFixed(1)}%`);
    console.log(`Elapsed: ${this.formatDuration(progress.elapsed)}`);
  }
}
```

### Phase 4: Data Validation

#### 4.1 Integrity Verification
```javascript
async function validateMigration(table, columns) {
  const validator = new MigrationValidator();
  
  // Sample-based validation
  const sampleSize = Math.min(10000, await getRowCount(table));
  const samples = await db.query(`
    SELECT * FROM ${table} 
    ORDER BY RANDOM() 
    LIMIT ?
  `, [sampleSize]);
  
  const validationResults = await Promise.all(
    samples.map(async original => {
      const encrypted = await db.query(`
        SELECT * FROM ${table}_encrypted 
        WHERE id = ?
      `, [original.id]);
      
      if (!encrypted[0]) {
        return { id: original.id, status: 'missing' };
      }
      
      // Verify each encrypted column
      const columnResults = await Promise.all(
        columns.map(async column => {
          const decrypted = await encryptionService.decrypt(
            encrypted[0][`${column}_encrypted`]
          );
          
          return {
            column,
            matches: decrypted === original[column],
            original: original[column],
            decrypted
          };
        })
      );
      
      return {
        id: original.id,
        status: columnResults.every(r => r.matches) ? 'valid' : 'mismatch',
        details: columnResults
      };
    })
  );
  
  const summary = {
    total: validationResults.length,
    valid: validationResults.filter(r => r.status === 'valid').length,
    mismatches: validationResults.filter(r => r.status === 'mismatch').length,
    missing: validationResults.filter(r => r.status === 'missing').length
  };
  
  console.log(`Validation Results for ${table}:`);
  console.log(`  Valid: ${summary.valid} (${(summary.valid/summary.total*100).toFixed(2)}%)`);
  console.log(`  Mismatches: ${summary.mismatches}`);
  console.log(`  Missing: ${summary.missing}`);
  
  return summary;
}
```

#### 4.2 Performance Validation
```javascript
async function validatePerformance(baseline) {
  const current = await measurePerformanceMetrics();
  
  const comparison = {
    queryLatency: {
      baseline: baseline.queryPerformance,
      current: current.queryPerformance,
      increase: ((current.queryPerformance - baseline.queryPerformance) / baseline.queryPerformance) * 100
    },
    throughput: {
      baseline: baseline.throughput,
      current: current.throughput,
      decrease: ((baseline.throughput - current.throughput) / baseline.throughput) * 100
    },
    cpu: {
      baseline: baseline.cpuUsage,
      current: current.cpuUsage,
      increase: ((current.cpuUsage - baseline.cpuUsage) / baseline.cpuUsage) * 100
    }
  };
  
  const acceptable = 
    comparison.queryLatency.increase < 10 &&
    comparison.throughput.decrease < 10 &&
    comparison.cpu.increase < 15;
    
  return {
    comparison,
    acceptable,
    recommendations: generateOptimizationRecommendations(comparison)
  };
}
```

### Phase 5: Cutover

#### 5.1 Application Update
```javascript
class ApplicationCutover {
  constructor(config) {
    this.tables = config.tables;
    this.rollbackEnabled = true;
  }
  
  async executeСutover() {
    try {
      // Phase 1: Update read operations
      await this.updateReadOperations();
      
      // Monitor for 5 minutes
      await this.monitor(5 * 60 * 1000);
      
      // Phase 2: Update write operations
      await this.updateWriteOperations();
      
      // Monitor for 15 minutes
      await this.monitor(15 * 60 * 1000);
      
      // Phase 3: Disable dual writes
      await this.disableDualWrites();
      
      // Final validation
      await this.finalValidation();
      
      console.log('Cutover completed successfully');
      
    } catch (error) {
      console.error('Cutover failed:', error);
      if (this.rollbackEnabled) {
        await this.rollback();
      }
      throw error;
    }
  }
  
  async updateReadOperations() {
    // Update ORM/query builders to use encrypted tables
    for (const table of this.tables) {
      await db.query(`
        CREATE OR REPLACE VIEW ${table}_view AS
        SELECT 
          id,
          decrypt_column(ssn_encrypted) as ssn,
          decrypt_column(email_encrypted) as email,
          -- other columns
        FROM ${table}_encrypted;
      `);
      
      // Update application to use views
      await this.updateApplicationConfig({
        [`${table}.source`]: `${table}_view`
      });
    }
  }
  
  async rollback() {
    console.log('Initiating rollback...');
    
    // Revert views to original tables
    for (const table of this.tables) {
      await db.query(`
        CREATE OR REPLACE VIEW ${table}_view AS
        SELECT * FROM ${table};
      `);
    }
    
    // Re-enable original configuration
    await this.updateApplicationConfig({
      useEncryption: false
    });
    
    console.log('Rollback completed');
  }
}
```

#### 5.2 Cleanup
```javascript
async function cleanup(tables) {
  // After successful validation period (e.g., 30 days)
  
  for (const table of tables) {
    // Archive original unencrypted data
    await db.query(`
      CREATE TABLE ${table}_archive AS 
      SELECT * FROM ${table};
    `);
    
    // Drop triggers
    await db.query(`
      DROP TRIGGER IF EXISTS ${table}_encrypt_sync;
      DROP FUNCTION IF EXISTS sync_to_encrypted_${table}();
    `);
    
    // Rename encrypted table to original name
    await db.query(`
      ALTER TABLE ${table} RENAME TO ${table}_old;
      ALTER TABLE ${table}_encrypted RENAME TO ${table};
    `);
    
    // Update indexes and constraints
    await updateIndexesAndConstraints(table);
    
    // Schedule deletion of unencrypted data
    await scheduleSecureDeletion(`${table}_old`, 90); // 90 days
  }
}
```

## Monitoring Dashboard

```javascript
class MigrationDashboard {
  async render() {
    const status = await this.getOverallStatus();
    
    console.log(`
╔════════════════════════════════════════════════════════════╗
║                 ENCRYPTION MIGRATION DASHBOARD              ║
╠════════════════════════════════════════════════════════════╣
║ Status: ${status.phase.padEnd(20)} │ Health: ${status.health}        ║
╠════════════════════════════════════════════════════════════╣
║                        PROGRESS                             ║
╠═══════════════════════════════════════════════════════════ ╣
${this.renderProgress(status.progress)}
╠════════════════════════════════════════════════════════════╣
║                      PERFORMANCE                            ║
╠═══════════════════════════════════════════════════════════ ╣
║ Query Latency: ${status.performance.latency}ms (${status.performance.latencyChange})        ║
║ Throughput:    ${status.performance.throughput} ops/s (${status.performance.throughputChange})  ║
║ CPU Usage:     ${status.performance.cpu}% (${status.performance.cpuChange})             ║
╠════════════════════════════════════════════════════════════╣
║                        ALERTS                               ║
╠═══════════════════════════════════════════════════════════ ╣
${this.renderAlerts(status.alerts)}
╚════════════════════════════════════════════════════════════╝
    `);
  }
}
```

## Rollback Procedures

### Immediate Rollback
```javascript
async function immediateRollback() {
  // Stop all migration processes
  await stopMigrationWorkers();
  
  // Disable triggers
  await disableAllTriggers();
  
  // Revert application configuration
  await revertApplicationConfig();
  
  // Clear shadow tables
  await truncateShadowTables();
  
  // Restore from backup if needed
  if (dataCorruption) {
    await restoreFromBackup();
  }
}
```

### Gradual Rollback
```javascript
async function gradualRollback() {
  // Switch back to unencrypted tables gradually
  const tables = await getTablesInMigration();
  
  for (const table of tables) {
    // Revert one table at a time
    await revertTable(table);
    
    // Monitor for stability
    await monitorStability(30 * 60 * 1000); // 30 minutes
    
    // Continue if stable
    if (await isSystemStable()) {
      continue;
    } else {
      await pauseRollback();
      await alertOperations();
    }
  }
}
```

## Success Criteria

1. **Data Integrity**: 100% of data successfully encrypted and validated
2. **Performance**: Less than 10% increase in query latency
3. **Availability**: Zero downtime during migration
4. **Compliance**: All regulatory requirements met
5. **Rollback**: Successful rollback test completed

## Post-Migration Tasks

1. Update documentation
2. Train operations team
3. Update monitoring alerts
4. Schedule key rotation
5. Conduct security audit
6. Performance optimization
7. Disaster recovery test