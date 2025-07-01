# Audit Logger - Implementation Strategy

## 1. Schema-Based Audit Configuration Generator

### Overview
The schema-based audit configuration generator automatically analyzes database schemas and entity definitions to create comprehensive audit logging infrastructure.

### Core Interfaces

```typescript
// Audit configuration types
interface AuditFieldConfig {
  fieldName: string;
  isSensitive: boolean;
  encryptionRequired: boolean;
  piiType?: 'email' | 'ssn' | 'creditCard' | 'phone' | 'address' | 'name';
  maskingStrategy?: 'full' | 'partial' | 'hash' | 'encrypt';
  retentionPeriod?: number; // in days
}

interface AuditEntityConfig {
  entityName: string;
  tableName: string;
  auditLevel: 'none' | 'basic' | 'detailed' | 'full';
  fields: AuditFieldConfig[];
  triggers: AuditTrigger[];
  customRules?: AuditRule[];
}

interface AuditTrigger {
  operation: 'INSERT' | 'UPDATE' | 'DELETE' | 'SELECT';
  condition?: string;
  captureFields: string[];
  captureOldValues: boolean;
  captureNewValues: boolean;
}

interface AuditRule {
  name: string;
  condition: string;
  action: 'log' | 'alert' | 'block';
  severity: 'low' | 'medium' | 'high' | 'critical';
}
```

### Implementation

```typescript
import { DataTypes, Model, Sequelize } from 'sequelize';
import * as crypto from 'crypto';

export class AuditConfigurationGenerator {
  private sensitiveFieldPatterns = [
    { pattern: /password|secret|key/i, type: 'credential' },
    { pattern: /email/i, type: 'email' },
    { pattern: /ssn|social.*security/i, type: 'ssn' },
    { pattern: /credit.*card|card.*number/i, type: 'creditCard' },
    { pattern: /phone|mobile|cell/i, type: 'phone' },
    { pattern: /address|street|city|zip/i, type: 'address' },
    { pattern: /first.*name|last.*name|full.*name/i, type: 'name' }
  ];

  async generateAuditConfig(model: typeof Model): Promise<AuditEntityConfig> {
    const attributes = model.rawAttributes;
    const tableName = model.tableName;
    
    const fields: AuditFieldConfig[] = Object.entries(attributes).map(([fieldName, attr]) => {
      const sensitiveInfo = this.detectSensitiveField(fieldName, attr);
      
      return {
        fieldName,
        isSensitive: sensitiveInfo.isSensitive,
        encryptionRequired: sensitiveInfo.requiresEncryption,
        piiType: sensitiveInfo.piiType as any,
        maskingStrategy: this.determineMaskingStrategy(sensitiveInfo),
        retentionPeriod: this.determineRetentionPeriod(sensitiveInfo)
      };
    });

    const auditLevel = this.determineAuditLevel(fields);
    const triggers = this.generateAuditTriggers(tableName, fields, auditLevel);

    return {
      entityName: model.name,
      tableName,
      auditLevel,
      fields,
      triggers,
      customRules: this.generateCustomRules(model.name, fields)
    };
  }

  private detectSensitiveField(fieldName: string, attribute: any) {
    for (const { pattern, type } of this.sensitiveFieldPatterns) {
      if (pattern.test(fieldName)) {
        return {
          isSensitive: true,
          requiresEncryption: ['credential', 'ssn', 'creditCard'].includes(type),
          piiType: type
        };
      }
    }

    // Check for custom validators or comments
    if (attribute.comment && attribute.comment.includes('@sensitive')) {
      return { isSensitive: true, requiresEncryption: true, piiType: null };
    }

    return { isSensitive: false, requiresEncryption: false, piiType: null };
  }

  private determineMaskingStrategy(sensitiveInfo: any): AuditFieldConfig['maskingStrategy'] {
    if (!sensitiveInfo.isSensitive) return undefined;
    
    switch (sensitiveInfo.piiType) {
      case 'credential':
        return 'hash';
      case 'ssn':
      case 'creditCard':
        return 'encrypt';
      case 'email':
        return 'partial';
      default:
        return 'full';
    }
  }

  private determineRetentionPeriod(sensitiveInfo: any): number {
    // GDPR compliance: different retention periods for different data types
    if (!sensitiveInfo.isSensitive) return 2555; // 7 years default
    
    switch (sensitiveInfo.piiType) {
      case 'credential':
        return 90; // 3 months for security credentials
      case 'ssn':
      case 'creditCard':
        return 365; // 1 year for financial data
      default:
        return 1095; // 3 years for general PII
    }
  }

  private generateAuditTriggers(
    tableName: string,
    fields: AuditFieldConfig[],
    auditLevel: string
  ): AuditTrigger[] {
    const triggers: AuditTrigger[] = [];
    const sensitiveFields = fields.filter(f => f.isSensitive).map(f => f.fieldName);
    const nonSensitiveFields = fields.filter(f => !f.isSensitive).map(f => f.fieldName);

    // Always audit sensitive field changes
    if (sensitiveFields.length > 0) {
      triggers.push({
        operation: 'UPDATE',
        captureFields: sensitiveFields,
        captureOldValues: true,
        captureNewValues: false, // Don't log new sensitive values
        condition: sensitiveFields.map(f => `OLD.${f} != NEW.${f}`).join(' OR ')
      });
    }

    // Audit based on level
    switch (auditLevel) {
      case 'full':
        triggers.push(
          {
            operation: 'INSERT',
            captureFields: nonSensitiveFields,
            captureOldValues: false,
            captureNewValues: true
          },
          {
            operation: 'UPDATE',
            captureFields: nonSensitiveFields,
            captureOldValues: true,
            captureNewValues: true
          },
          {
            operation: 'DELETE',
            captureFields: [...nonSensitiveFields, ...sensitiveFields.map(f => `${f}_hash`)],
            captureOldValues: true,
            captureNewValues: false
          }
        );
        break;
      case 'detailed':
        triggers.push(
          {
            operation: 'UPDATE',
            captureFields: nonSensitiveFields,
            captureOldValues: true,
            captureNewValues: true
          },
          {
            operation: 'DELETE',
            captureFields: ['id', 'updated_at'],
            captureOldValues: true,
            captureNewValues: false
          }
        );
        break;
      case 'basic':
        triggers.push({
          operation: 'DELETE',
          captureFields: ['id'],
          captureOldValues: true,
          captureNewValues: false
        });
        break;
    }

    return triggers;
  }

  async createAuditTable(entityConfig: AuditEntityConfig, sequelize: Sequelize): Promise<void> {
    const auditTableName = `${entityConfig.tableName}_audit`;
    
    await sequelize.query(`
      CREATE TABLE IF NOT EXISTS ${auditTableName} (
        audit_id BIGSERIAL PRIMARY KEY,
        entity_id VARCHAR(255) NOT NULL,
        operation VARCHAR(20) NOT NULL,
        operated_by VARCHAR(255),
        operated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        ip_address INET,
        session_id VARCHAR(255),
        correlation_id UUID,
        old_values JSONB,
        new_values JSONB,
        change_set JSONB,
        metadata JSONB,
        INDEX idx_entity_id (entity_id),
        INDEX idx_operated_at (operated_at),
        INDEX idx_operated_by (operated_by),
        INDEX idx_correlation_id (correlation_id)
      );
    `);

    // Create triggers for each operation
    for (const trigger of entityConfig.triggers) {
      await this.createDatabaseTrigger(entityConfig.tableName, auditTableName, trigger, sequelize);
    }
  }

  private async createDatabaseTrigger(
    tableName: string,
    auditTableName: string,
    trigger: AuditTrigger,
    sequelize: Sequelize
  ): Promise<void> {
    const triggerName = `audit_${tableName}_${trigger.operation.toLowerCase()}`;
    const functionName = `${triggerName}_func`;

    // Create trigger function
    await sequelize.query(`
      CREATE OR REPLACE FUNCTION ${functionName}()
      RETURNS TRIGGER AS $$
      DECLARE
        old_data JSONB;
        new_data JSONB;
        change_data JSONB;
      BEGIN
        -- Capture old values
        ${trigger.captureOldValues ? `
          old_data := to_jsonb(OLD);
          -- Remove sensitive fields from old_data
          ${trigger.captureFields.map(field => 
            `old_data := old_data - '${field}';`
          ).join('\n')}
        ` : 'old_data := NULL;'}
        
        -- Capture new values
        ${trigger.captureNewValues ? `
          new_data := to_jsonb(NEW);
          -- Remove sensitive fields from new_data
          ${trigger.captureFields.filter(field => 
            !entityConfig.fields.find(f => f.fieldName === field)?.isSensitive
          ).map(field => 
            `new_data := new_data - '${field}';`
          ).join('\n')}
        ` : 'new_data := NULL;'}
        
        -- Calculate change set
        IF old_data IS NOT NULL AND new_data IS NOT NULL THEN
          SELECT jsonb_object_agg(key, value) INTO change_data
          FROM (
            SELECT key, new_data->key as value
            FROM jsonb_object_keys(new_data) AS key
            WHERE old_data->key IS DISTINCT FROM new_data->key
          ) changes;
        END IF;
        
        -- Insert audit record
        INSERT INTO ${auditTableName} (
          entity_id,
          operation,
          operated_by,
          ip_address,
          session_id,
          correlation_id,
          old_values,
          new_values,
          change_set,
          metadata
        ) VALUES (
          COALESCE(NEW.id::TEXT, OLD.id::TEXT),
          '${trigger.operation}',
          current_setting('app.current_user', true),
          inet(current_setting('app.current_ip', true)),
          current_setting('app.session_id', true),
          current_setting('app.correlation_id', true)::UUID,
          old_data,
          new_data,
          change_data,
          jsonb_build_object(
            'schema_version', '1.0',
            'trigger_condition', '${trigger.condition || 'none'}'
          )
        );
        
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    `);

    // Create trigger
    await sequelize.query(`
      DROP TRIGGER IF EXISTS ${triggerName} ON ${tableName};
      CREATE TRIGGER ${triggerName}
      ${trigger.operation === 'DELETE' ? 'BEFORE' : 'AFTER'} ${trigger.operation}
      ON ${tableName}
      FOR EACH ROW
      ${trigger.condition ? `WHEN (${trigger.condition})` : ''}
      EXECUTE FUNCTION ${functionName}();
    `);
  }
}
```

## 2. Event Capture Strategy

### Database Operation Interception

```typescript
import { Model, ModelStatic, Options } from 'sequelize';
import { v4 as uuidv4 } from 'uuid';

export interface AuditContext {
  userId: string;
  sessionId: string;
  ipAddress: string;
  correlationId: string;
  userAgent?: string;
  requestId?: string;
}

export class DatabaseAuditInterceptor {
  private static context: AsyncLocalStorage<AuditContext> = new AsyncLocalStorage();

  static initialize(sequelize: any) {
    // Hook into Sequelize lifecycle events
    sequelize.addHook('beforeCreate', this.auditCreate.bind(this));
    sequelize.addHook('beforeUpdate', this.auditUpdate.bind(this));
    sequelize.addHook('beforeDestroy', this.auditDelete.bind(this));
    sequelize.addHook('afterFind', this.auditSelect.bind(this));
  }

  static runWithContext<T>(context: AuditContext, fn: () => T): T {
    return this.context.run(context, fn);
  }

  private static async auditCreate(instance: Model, options: Options) {
    const context = this.context.getStore();
    if (!context) return;

    const auditLog: AuditLog = {
      id: uuidv4(),
      timestamp: new Date(),
      entityType: instance.constructor.name,
      entityId: instance.get('id') as string,
      operation: 'CREATE',
      userId: context.userId,
      sessionId: context.sessionId,
      ipAddress: context.ipAddress,
      correlationId: context.correlationId,
      newValues: this.sanitizeValues(instance.toJSON()),
      metadata: {
        modelName: instance.constructor.name,
        tableName: (instance.constructor as any).tableName
      }
    };

    await this.persistAuditLog(auditLog);
  }

  private static async auditUpdate(instance: Model, options: Options) {
    const context = this.context.getStore();
    if (!context) return;

    const changedFields = instance.changed() || [];
    const previousValues = instance._previousDataValues;
    const currentValues = instance.dataValues;

    const changes: Record<string, { old: any; new: any }> = {};
    changedFields.forEach(field => {
      changes[field] = {
        old: this.sanitizeValue(field, previousValues[field]),
        new: this.sanitizeValue(field, currentValues[field])
      };
    });

    const auditLog: AuditLog = {
      id: uuidv4(),
      timestamp: new Date(),
      entityType: instance.constructor.name,
      entityId: instance.get('id') as string,
      operation: 'UPDATE',
      userId: context.userId,
      sessionId: context.sessionId,
      ipAddress: context.ipAddress,
      correlationId: context.correlationId,
      changes,
      metadata: {
        changedFields,
        modelName: instance.constructor.name,
        tableName: (instance.constructor as any).tableName
      }
    };

    await this.persistAuditLog(auditLog);
  }

  private static sanitizeValue(fieldName: string, value: any): any {
    const sensitivePatterns = /password|secret|token|key|ssn|credit/i;
    
    if (sensitivePatterns.test(fieldName)) {
      return value ? '[REDACTED]' : null;
    }
    
    return value;
  }

  private static sanitizeValues(values: Record<string, any>): Record<string, any> {
    const sanitized: Record<string, any> = {};
    
    Object.entries(values).forEach(([key, value]) => {
      sanitized[key] = this.sanitizeValue(key, value);
    });
    
    return sanitized;
  }
}
```

### API Middleware for Request/Response Auditing

```typescript
import { Request, Response, NextFunction } from 'express';
import { v4 as uuidv4 } from 'uuid';

export interface ApiAuditLog {
  id: string;
  timestamp: Date;
  method: string;
  path: string;
  statusCode: number;
  userId?: string;
  sessionId: string;
  ipAddress: string;
  correlationId: string;
  requestHeaders: Record<string, string>;
  requestBody?: any;
  responseBody?: any;
  responseTime: number;
  error?: any;
}

export class ApiAuditMiddleware {
  private static sensitiveHeaders = ['authorization', 'cookie', 'x-api-key'];
  private static sensitiveBodyPaths = ['password', 'creditCard', 'ssn'];

  static middleware(options: { 
    skipPaths?: string[]; 
    captureBody?: boolean;
    captureResponse?: boolean;
  } = {}) {
    return async (req: Request, res: Response, next: NextFunction) => {
      // Skip audit for specified paths
      if (options.skipPaths?.some(path => req.path.startsWith(path))) {
        return next();
      }

      const startTime = Date.now();
      const correlationId = req.headers['x-correlation-id'] as string || uuidv4();
      const sessionId = req.session?.id || req.headers['x-session-id'] as string || uuidv4();

      // Inject audit context
      (req as any).auditContext = {
        correlationId,
        sessionId,
        userId: (req as any).user?.id,
        ipAddress: this.getClientIp(req)
      };

      // Capture request data
      const auditLog: Partial<ApiAuditLog> = {
        id: uuidv4(),
        timestamp: new Date(),
        method: req.method,
        path: req.path,
        userId: (req as any).user?.id,
        sessionId,
        ipAddress: this.getClientIp(req),
        correlationId,
        requestHeaders: this.sanitizeHeaders(req.headers)
      };

      if (options.captureBody && req.body) {
        auditLog.requestBody = this.sanitizeBody(req.body);
      }

      // Capture response
      if (options.captureResponse) {
        const originalSend = res.send;
        res.send = function(data: any) {
          auditLog.responseBody = ApiAuditMiddleware.sanitizeBody(
            typeof data === 'string' ? JSON.parse(data) : data
          );
          return originalSend.call(this, data);
        };
      }

      // Log on response finish
      res.on('finish', async () => {
        auditLog.statusCode = res.statusCode;
        auditLog.responseTime = Date.now() - startTime;

        // Run audit logging in background
        setImmediate(() => {
          ApiAuditLogger.log(auditLog as ApiAuditLog);
        });
      });

      // Handle errors
      res.on('error', (error) => {
        auditLog.error = {
          message: error.message,
          stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
        };
      });

      next();
    };
  }

  private static getClientIp(req: Request): string {
    return (req.headers['x-forwarded-for'] as string)?.split(',')[0] || 
           req.socket.remoteAddress || 
           'unknown';
  }

  private static sanitizeHeaders(headers: any): Record<string, string> {
    const sanitized: Record<string, string> = {};
    
    Object.entries(headers).forEach(([key, value]) => {
      if (this.sensitiveHeaders.includes(key.toLowerCase())) {
        sanitized[key] = '[REDACTED]';
      } else {
        sanitized[key] = value as string;
      }
    });
    
    return sanitized;
  }

  private static sanitizeBody(body: any, path: string = ''): any {
    if (!body || typeof body !== 'object') return body;
    
    if (Array.isArray(body)) {
      return body.map((item, index) => this.sanitizeBody(item, `${path}[${index}]`));
    }
    
    const sanitized: any = {};
    
    Object.entries(body).forEach(([key, value]) => {
      const currentPath = path ? `${path}.${key}` : key;
      
      if (this.sensitiveBodyPaths.some(sensitive => currentPath.includes(sensitive))) {
        sanitized[key] = '[REDACTED]';
      } else if (typeof value === 'object') {
        sanitized[key] = this.sanitizeBody(value, currentPath);
      } else {
        sanitized[key] = value;
      }
    });
    
    return sanitized;
  }
}
```

### Frontend Action Tracking

```typescript
export interface FrontendAuditEvent {
  id: string;
  timestamp: Date;
  eventType: 'click' | 'input' | 'navigation' | 'error' | 'custom';
  eventName: string;
  userId?: string;
  sessionId: string;
  page: string;
  component?: string;
  elementId?: string;
  elementType?: string;
  value?: any;
  metadata?: Record<string, any>;
  userAgent: string;
  screenResolution: string;
  correlationId: string;
}

export class FrontendAuditTracker {
  private static instance: FrontendAuditTracker;
  private eventQueue: FrontendAuditEvent[] = [];
  private sessionId: string;
  private userId?: string;
  private batchTimer?: NodeJS.Timeout;
  private readonly batchSize = 50;
  private readonly batchInterval = 5000; // 5 seconds

  private constructor() {
    this.sessionId = this.generateSessionId();
    this.initializeEventListeners();
    this.startBatchTimer();
  }

  static getInstance(): FrontendAuditTracker {
    if (!this.instance) {
      this.instance = new FrontendAuditTracker();
    }
    return this.instance;
  }

  setUserId(userId: string) {
    this.userId = userId;
  }

  trackEvent(event: Partial<FrontendAuditEvent>) {
    const auditEvent: FrontendAuditEvent = {
      id: this.generateId(),
      timestamp: new Date(),
      sessionId: this.sessionId,
      userId: this.userId,
      page: window.location.pathname,
      userAgent: navigator.userAgent,
      screenResolution: `${window.screen.width}x${window.screen.height}`,
      correlationId: this.getCurrentCorrelationId(),
      ...event
    } as FrontendAuditEvent;

    this.eventQueue.push(auditEvent);

    // Send immediately if queue is full
    if (this.eventQueue.length >= this.batchSize) {
      this.flushEvents();
    }
  }

  private initializeEventListeners() {
    // Track clicks on sensitive elements
    document.addEventListener('click', (e) => {
      const target = e.target as HTMLElement;
      const auditableElements = ['button', 'a', '[data-audit]'];
      
      if (auditableElements.some(selector => target.matches(selector))) {
        this.trackEvent({
          eventType: 'click',
          eventName: 'element_click',
          elementId: target.id,
          elementType: target.tagName.toLowerCase(),
          component: target.getAttribute('data-component') || undefined,
          metadata: {
            text: target.textContent?.substring(0, 50),
            href: (target as HTMLAnchorElement).href || undefined,
            dataAttributes: this.getDataAttributes(target)
          }
        });
      }
    });

    // Track form submissions
    document.addEventListener('submit', (e) => {
      const form = e.target as HTMLFormElement;
      
      this.trackEvent({
        eventType: 'custom',
        eventName: 'form_submit',
        elementId: form.id,
        component: form.getAttribute('data-component') || undefined,
        metadata: {
          formName: form.name,
          action: form.action,
          method: form.method,
          fields: Array.from(form.elements)
            .filter(el => (el as HTMLInputElement).name)
            .map(el => ({
              name: (el as HTMLInputElement).name,
              type: (el as HTMLInputElement).type
            }))
        }
      });
    });

    // Track navigation
    const originalPushState = history.pushState;
    history.pushState = function(...args) {
      FrontendAuditTracker.getInstance().trackEvent({
        eventType: 'navigation',
        eventName: 'route_change',
        metadata: {
          from: window.location.pathname,
          to: args[2]
        }
      });
      return originalPushState.apply(history, args);
    };

    // Track errors
    window.addEventListener('error', (e) => {
      this.trackEvent({
        eventType: 'error',
        eventName: 'javascript_error',
        metadata: {
          message: e.message,
          filename: e.filename,
          lineno: e.lineno,
          colno: e.colno,
          stack: e.error?.stack
        }
      });
    });

    // Track sensitive input changes (with debouncing)
    let inputTimeout: NodeJS.Timeout;
    document.addEventListener('input', (e) => {
      const target = e.target as HTMLInputElement;
      
      if (target.matches('[data-audit-input]')) {
        clearTimeout(inputTimeout);
        inputTimeout = setTimeout(() => {
          this.trackEvent({
            eventType: 'input',
            eventName: 'sensitive_input_change',
            elementId: target.id,
            elementType: target.type,
            component: target.getAttribute('data-component') || undefined,
            value: target.type === 'password' ? '[REDACTED]' : target.value.substring(0, 50),
            metadata: {
              fieldName: target.name,
              hasValue: !!target.value
            }
          });
        }, 1000);
      }
    });
  }

  private getDataAttributes(element: HTMLElement): Record<string, string> {
    const dataAttrs: Record<string, string> = {};
    
    Array.from(element.attributes)
      .filter(attr => attr.name.startsWith('data-'))
      .forEach(attr => {
        dataAttrs[attr.name] = attr.value;
      });
    
    return dataAttrs;
  }

  private async flushEvents() {
    if (this.eventQueue.length === 0) return;

    const events = [...this.eventQueue];
    this.eventQueue = [];

    try {
      await fetch('/api/audit/frontend-events', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Correlation-Id': this.getCurrentCorrelationId()
        },
        body: JSON.stringify({ events })
      });
    } catch (error) {
      console.error('Failed to send audit events:', error);
      // Re-queue events on failure
      this.eventQueue.unshift(...events);
    }
  }

  private startBatchTimer() {
    this.batchTimer = setInterval(() => {
      this.flushEvents();
    }, this.batchInterval);
  }

  private generateSessionId(): string {
    return `session_${Date.now()}_${Math.random().toString(36).substring(2, 15)}`;
  }

  private generateId(): string {
    return `evt_${Date.now()}_${Math.random().toString(36).substring(2, 15)}`;
  }

  private getCurrentCorrelationId(): string {
    return (window as any).__CORRELATION_ID__ || this.generateId();
  }
}

// Initialize on page load
if (typeof window !== 'undefined') {
  const tracker = FrontendAuditTracker.getInstance();
  (window as any).__AUDIT_TRACKER__ = tracker;
}
```

### System Event Monitoring

```typescript
import { EventEmitter } from 'events';
import * as os from 'os';
import * as process from 'process';

export interface SystemAuditEvent {
  id: string;
  timestamp: Date;
  eventType: 'startup' | 'shutdown' | 'config_change' | 'security_event' | 'performance' | 'error';
  eventName: string;
  severity: 'info' | 'warning' | 'error' | 'critical';
  source: string;
  hostname: string;
  pid: number;
  metadata: Record<string, any>;
  correlationId?: string;
}

export class SystemEventMonitor extends EventEmitter {
  private static instance: SystemEventMonitor;
  private startTime: Date;
  private configSnapshot: Record<string, any> = {};

  private constructor() {
    super();
    this.startTime = new Date();
    this.initializeMonitoring();
  }

  static getInstance(): SystemEventMonitor {
    if (!this.instance) {
      this.instance = new SystemEventMonitor();
    }
    return this.instance;
  }

  private initializeMonitoring() {
    // Monitor process events
    process.on('exit', (code) => {
      this.logSystemEvent({
        eventType: 'shutdown',
        eventName: 'process_exit',
        severity: code === 0 ? 'info' : 'error',
        source: 'process',
        metadata: {
          exitCode: code,
          uptime: process.uptime(),
          memoryUsage: process.memoryUsage()
        }
      });
    });

    process.on('uncaughtException', (error) => {
      this.logSystemEvent({
        eventType: 'error',
        eventName: 'uncaught_exception',
        severity: 'critical',
        source: 'process',
        metadata: {
          error: {
            message: error.message,
            stack: error.stack,
            name: error.name
          }
        }
      });
    });

    process.on('unhandledRejection', (reason, promise) => {
      this.logSystemEvent({
        eventType: 'error',
        eventName: 'unhandled_rejection',
        severity: 'error',
        source: 'process',
        metadata: {
          reason: reason instanceof Error ? {
            message: reason.message,
            stack: reason.stack
          } : reason,
          promise: promise.toString()
        }
      });
    });

    // Monitor configuration changes
    this.monitorConfigChanges();

    // Monitor system resources
    this.monitorSystemResources();

    // Log startup
    this.logSystemEvent({
      eventType: 'startup',
      eventName: 'application_start',
      severity: 'info',
      source: 'system',
      metadata: {
        nodeVersion: process.version,
        platform: os.platform(),
        arch: os.arch(),
        hostname: os.hostname(),
        environment: process.env.NODE_ENV,
        cpus: os.cpus().length,
        totalMemory: os.totalmem(),
        startupConfig: this.getStartupConfig()
      }
    });
  }

  private monitorConfigChanges() {
    // Watch for environment variable changes
    const originalEnv = { ...process.env };
    
    setInterval(() => {
      const currentEnv = { ...process.env };
      const changes: Record<string, { old: any; new: any }> = {};
      
      // Check for changes
      Object.keys({ ...originalEnv, ...currentEnv }).forEach(key => {
        if (originalEnv[key] !== currentEnv[key]) {
          // Skip sensitive values
          const isSensitive = /password|secret|key|token/i.test(key);
          changes[key] = {
            old: isSensitive ? '[REDACTED]' : originalEnv[key],
            new: isSensitive ? '[REDACTED]' : currentEnv[key]
          };
        }
      });
      
      if (Object.keys(changes).length > 0) {
        this.logSystemEvent({
          eventType: 'config_change',
          eventName: 'environment_variables_changed',
          severity: 'warning',
          source: 'config',
          metadata: { changes }
        });
        Object.assign(originalEnv, currentEnv);
      }
    }, 30000); // Check every 30 seconds
  }

  private monitorSystemResources() {
    setInterval(() => {
      const memoryUsage = process.memoryUsage();
      const cpuUsage = process.cpuUsage();
      
      // Check for high memory usage
      const memoryThreshold = 0.85; // 85% of heap
      const heapUsedRatio = memoryUsage.heapUsed / memoryUsage.heapTotal;
      
      if (heapUsedRatio > memoryThreshold) {
        this.logSystemEvent({
          eventType: 'performance',
          eventName: 'high_memory_usage',
          severity: 'warning',
          source: 'system',
          metadata: {
            heapUsed: memoryUsage.heapUsed,
            heapTotal: memoryUsage.heapTotal,
            rss: memoryUsage.rss,
            external: memoryUsage.external,
            heapUsedRatio
          }
        });
      }
      
      // Log periodic metrics
      this.emit('metrics', {
        timestamp: new Date(),
        memory: memoryUsage,
        cpu: cpuUsage,
        uptime: process.uptime(),
        loadAverage: os.loadavg()
      });
    }, 60000); // Check every minute
  }

  logSecurityEvent(event: {
    eventName: string;
    severity: 'warning' | 'error' | 'critical';
    userId?: string;
    ipAddress?: string;
    details: any;
  }) {
    this.logSystemEvent({
      eventType: 'security_event',
      eventName: event.eventName,
      severity: event.severity,
      source: 'security',
      metadata: {
        userId: event.userId,
        ipAddress: event.ipAddress,
        details: event.details,
        timestamp: new Date()
      }
    });
  }

  private logSystemEvent(event: Omit<SystemAuditEvent, 'id' | 'timestamp' | 'hostname' | 'pid'>) {
    const auditEvent: SystemAuditEvent = {
      id: this.generateId(),
      timestamp: new Date(),
      hostname: os.hostname(),
      pid: process.pid,
      ...event
    };

    // Emit event for listeners
    this.emit('audit', auditEvent);

    // Persist to audit log
    this.persistSystemAudit(auditEvent);
  }

  private async persistSystemAudit(event: SystemAuditEvent) {
    try {
      // Implementation would depend on your storage backend
      await AuditStorage.getInstance().storeSystemEvent(event);
    } catch (error) {
      console.error('Failed to persist system audit event:', error);
    }
  }

  private getStartupConfig(): Record<string, any> {
    return {
      nodeEnv: process.env.NODE_ENV,
      port: process.env.PORT,
      databaseUrl: process.env.DATABASE_URL ? '[CONFIGURED]' : '[NOT_CONFIGURED]',
      logLevel: process.env.LOG_LEVEL,
      features: {
        apiAudit: process.env.ENABLE_API_AUDIT === 'true',
        dbAudit: process.env.ENABLE_DB_AUDIT === 'true',
        frontendTracking: process.env.ENABLE_FRONTEND_TRACKING === 'true'
      }
    };
  }

  private generateId(): string {
    return `sys_${Date.now()}_${Math.random().toString(36).substring(2, 15)}`;
  }
}
```

## 3. Data Structure for Audit Logs

### Core Audit Log Interfaces

```typescript
// Base audit log structure
export interface AuditLog {
  id: string;
  timestamp: Date;
  entityType: string;
  entityId: string;
  operation: 'CREATE' | 'READ' | 'UPDATE' | 'DELETE' | 'EXECUTE';
  userId?: string;
  sessionId: string;
  ipAddress: string;
  correlationId: string;
  oldValues?: Record<string, any>;
  newValues?: Record<string, any>;
  changes?: Record<string, { old: any; new: any }>;
  metadata?: AuditMetadata;
  tags?: string[];
  riskScore?: number;
}

// Extended metadata for rich context
export interface AuditMetadata {
  userAgent?: string;
  requestId?: string;
  apiEndpoint?: string;
  httpMethod?: string;
  responseCode?: number;
  executionTime?: number;
  queryParameters?: Record<string, any>;
  headers?: Record<string, string>;
  geoLocation?: GeoLocation;
  deviceInfo?: DeviceInfo;
  applicationContext?: ApplicationContext;
}

export interface GeoLocation {
  country?: string;
  region?: string;
  city?: string;
  latitude?: number;
  longitude?: number;
  timezone?: string;
}

export interface DeviceInfo {
  type: 'desktop' | 'mobile' | 'tablet' | 'unknown';
  os?: string;
  browser?: string;
  browserVersion?: string;
}

export interface ApplicationContext {
  version: string;
  environment: string;
  feature?: string;
  module?: string;
  tenant?: string;
}

// Specialized audit log types
export interface SecurityAuditLog extends AuditLog {
  securityEvent: {
    type: 'authentication' | 'authorization' | 'access_denied' | 'suspicious_activity';
    severity: 'low' | 'medium' | 'high' | 'critical';
    threatIndicators?: string[];
    remediationAction?: string;
  };
}

export interface ComplianceAuditLog extends AuditLog {
  compliance: {
    regulation: 'GDPR' | 'HIPAA' | 'SOC2' | 'PCI-DSS';
    requirement: string;
    status: 'compliant' | 'non_compliant' | 'exception';
    evidence?: string;
  };
}

export interface PerformanceAuditLog extends AuditLog {
  performance: {
    duration: number;
    cpuUsage?: number;
    memoryUsage?: number;
    databaseQueries?: number;
    cacheHits?: number;
    cacheMisses?: number;
  };
}
```

### Audit Log Storage Implementation

```typescript
import { Pool } from 'pg';
import { createHash } from 'crypto';
import { compress, decompress } from 'zlib';
import { promisify } from 'util';

const gzipAsync = promisify(compress);
const gunzipAsync = promisify(decompress);

export class AuditLogStorage {
  private pool: Pool;
  private encryptionKey: Buffer;

  constructor(pool: Pool, encryptionKey: string) {
    this.pool = pool;
    this.encryptionKey = Buffer.from(encryptionKey, 'hex');
  }

  async store(auditLog: AuditLog): Promise<void> {
    const client = await this.pool.connect();
    
    try {
      await client.query('BEGIN');

      // Generate search tokens
      const searchTokens = this.generateSearchTokens(auditLog);
      
      // Compress and potentially encrypt sensitive data
      const processedLog = await this.processAuditLog(auditLog);
      
      // Store main audit record
      const { rows } = await client.query(`
        INSERT INTO audit_logs (
          id, timestamp, entity_type, entity_id, operation,
          user_id, session_id, ip_address, correlation_id,
          data, search_tokens, risk_score, ttl
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
        RETURNING id
      `, [
        auditLog.id,
        auditLog.timestamp,
        auditLog.entityType,
        auditLog.entityId,
        auditLog.operation,
        auditLog.userId,
        auditLog.sessionId,
        auditLog.ipAddress,
        auditLog.correlationId,
        processedLog,
        searchTokens,
        auditLog.riskScore || 0,
        this.calculateTTL(auditLog)
      ]);

      // Store in time-series partition for efficient querying
      await this.storeInTimeSeries(client, auditLog);
      
      // Update aggregate statistics
      await this.updateAggregates(client, auditLog);
      
      await client.query('COMMIT');
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async query(criteria: AuditQueryCriteria): Promise<AuditLog[]> {
    const { text, values } = this.buildQuery(criteria);
    const { rows } = await this.pool.query(text, values);
    
    // Decompress and decrypt results
    const results = await Promise.all(
      rows.map(row => this.unprocessAuditLog(row))
    );
    
    return results;
  }

  private async processAuditLog(auditLog: AuditLog): Promise<Buffer> {
    // Remove sensitive fields and prepare for storage
    const processedData = {
      ...auditLog,
      oldValues: this.maskSensitiveData(auditLog.oldValues),
      newValues: this.maskSensitiveData(auditLog.newValues),
      changes: this.maskChanges(auditLog.changes)
    };
    
    // Convert to JSON and compress
    const jsonData = JSON.stringify(processedData);
    const compressed = await gzipAsync(Buffer.from(jsonData));
    
    // Encrypt if contains sensitive data
    if (this.containsSensitiveData(auditLog)) {
      return this.encrypt(compressed);
    }
    
    return compressed;
  }

  private maskSensitiveData(data?: Record<string, any>): Record<string, any> | undefined {
    if (!data) return undefined;
    
    const masked: Record<string, any> = {};
    const sensitiveFields = /password|secret|token|ssn|creditCard/i;
    
    Object.entries(data).forEach(([key, value]) => {
      if (sensitiveFields.test(key)) {
        masked[key] = this.hashValue(value);
      } else if (typeof value === 'object' && value !== null) {
        masked[key] = this.maskSensitiveData(value);
      } else {
        masked[key] = value;
      }
    });
    
    return masked;
  }

  private hashValue(value: any): string {
    if (!value) return '[NULL]';
    const hash = createHash('sha256');
    hash.update(String(value));
    return `[HASH:${hash.digest('hex').substring(0, 8)}]`;
  }

  private generateSearchTokens(auditLog: AuditLog): string[] {
    const tokens = new Set<string>();
    
    // Add standard tokens
    tokens.add(auditLog.entityType.toLowerCase());
    tokens.add(auditLog.operation.toLowerCase());
    if (auditLog.userId) tokens.add(`user:${auditLog.userId}`);
    if (auditLog.ipAddress) tokens.add(`ip:${auditLog.ipAddress}`);
    
    // Add metadata tokens
    if (auditLog.metadata?.apiEndpoint) {
      tokens.add(`api:${auditLog.metadata.apiEndpoint}`);
    }
    
    // Add custom tags
    auditLog.tags?.forEach(tag => tokens.add(tag.toLowerCase()));
    
    return Array.from(tokens);
  }

  private calculateTTL(auditLog: AuditLog): Date {
    // Different retention policies based on type and compliance requirements
    const retentionDays = {
      'security': 2555, // 7 years for security events
      'compliance': 2555, // 7 years for compliance
      'performance': 90, // 3 months for performance metrics
      'default': 365 // 1 year default
    };
    
    const type = auditLog.tags?.find(tag => Object.keys(retentionDays).includes(tag)) || 'default';
    const days = retentionDays[type as keyof typeof retentionDays];
    
    const ttl = new Date(auditLog.timestamp);
    ttl.setDate(ttl.getDate() + days);
    
    return ttl;
  }
}

// Query interface for retrieving audit logs
export interface AuditQueryCriteria {
  startDate?: Date;
  endDate?: Date;
  entityType?: string;
  entityId?: string;
  userId?: string;
  operation?: string[];
  ipAddress?: string;
  correlationId?: string;
  tags?: string[];
  searchText?: string;
  limit?: number;
  offset?: number;
  orderBy?: 'timestamp' | 'risk_score';
  orderDirection?: 'ASC' | 'DESC';
}

// Aggregation interfaces for analytics
export interface AuditAggregation {
  period: 'hour' | 'day' | 'week' | 'month';
  entityType?: string;
  operation?: string;
  metrics: {
    count: number;
    uniqueUsers: number;
    averageResponseTime?: number;
    errorRate?: number;
    riskScore?: number;
  };
}
```

This comprehensive audit logging implementation strategy provides:

1. **Schema-based Configuration**: Automatically identifies sensitive fields and generates appropriate audit configurations
2. **Multi-layer Event Capture**: Intercepts events at database, API, frontend, and system levels
3. **Rich Data Structures**: Captures comprehensive context while protecting sensitive information
4. **Security Features**: Encryption, masking, and hashing of sensitive data
5. **Performance Optimization**: Compression, partitioning, and efficient querying
6. **Compliance Support**: Configurable retention policies and regulation-specific logging
7. **Real-time Monitoring**: System event tracking and performance metrics

The implementation ensures complete audit trail coverage while maintaining security and performance standards.