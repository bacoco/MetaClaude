# Audit Logger Agent

## Purpose
Implements comprehensive audit logging and compliance tracking for admin panels by capturing all system activities, user actions, and data changes while ensuring regulatory compliance and providing forensic capabilities for security analysis.

## Capabilities

### Activity Tracking Types
- User authentication events (login, logout, failed attempts)
- Authorization changes (role assignments, permission grants)
- Data CRUD operations with before/after values
- Configuration modifications
- API endpoint access patterns
- File uploads and downloads
- System administrative actions
- Database schema changes
- Security incidents and violations
- Performance anomalies
- Integration events
- Scheduled job executions

### Compliance Features
- GDPR compliance (right to be forgotten, data portability)
- HIPAA audit controls (access logs, data integrity)
- SOX compliance (financial controls, change management)
- PCI-DSS requirements (cardholder data access)
- ISO 27001 standards
- CCPA privacy requirements
- Custom regulatory frameworks
- Automated compliance reporting
- Retention policy enforcement
- Data anonymization
- Audit trail integrity
- Evidence chain of custody

### Storage Mechanisms
- Relational databases (PostgreSQL, MySQL, SQL Server)
- NoSQL stores (MongoDB, Elasticsearch)
- Time-series databases (InfluxDB, TimescaleDB)
- Cloud storage (S3, Azure Blob, GCS)
- File-based logging (JSON, CSV)
- Message queues (Kafka, RabbitMQ)
- SIEM integration (Splunk, ELK)
- Blockchain for immutability
- Hybrid storage strategies
- Compressed archives
- Encrypted vaults
- Distributed storage

### Real-time Monitoring
- Live activity dashboards
- Anomaly detection alerts
- Threshold-based notifications
- Pattern recognition
- User behavior analytics
- Security threat detection
- Performance monitoring
- Compliance violations
- System health checks
- Resource usage tracking
- Integration status
- Custom alert rules

## Audit Logging Strategy

### Schema-Based Audit Configuration
```typescript
interface AuditConfigurationGenerator {
  generateAuditConfig(schema: DatabaseSchema): AuditConfiguration {
    const config: AuditConfiguration = {
      entities: {},
      globalSettings: this.getGlobalSettings(),
      retentionPolicies: this.generateRetentionPolicies(schema),
      complianceRules: this.detectComplianceRequirements(schema)
    };
    
    // Configure audit for each entity
    schema.entities.forEach(entity => {
      config.entities[entity.name] = {
        auditLevel: this.determineAuditLevel(entity),
        sensitiveFields: this.identifySensitiveFields(entity),
        triggers: this.generateAuditTriggers(entity),
        retentionPeriod: this.getRetentionPeriod(entity),
        maskingRules: this.generateMaskingRules(entity),
        includeRelations: this.shouldAuditRelations(entity)
      };
    });
    
    return config;
  }
  
  identifySensitiveFields(entity: Entity): SensitiveFieldConfig[] {
    const sensitiveFields: SensitiveFieldConfig[] = [];
    
    entity.fields.forEach(field => {
      // Check for PII patterns
      const piiPatterns = {
        ssn: /ssn|social.*security/i,
        creditCard: /card.*number|credit.*card/i,
        email: /email|e-mail/i,
        phone: /phone|mobile|tel/i,
        address: /address|street|city|zip/i,
        dob: /birth|dob|birthday/i,
        financial: /account.*number|routing|salary/i,
        health: /diagnosis|medical|health/i,
        password: /password|pwd|secret/i
      };
      
      for (const [type, pattern] of Object.entries(piiPatterns)) {
        if (pattern.test(field.name) || pattern.test(field.description || '')) {
          sensitiveFields.push({
            field: field.name,
            type: type as PIIType,
            maskingStrategy: this.getMaskingStrategy(type, field),
            auditLevel: 'detailed',
            requiresEncryption: true
          });
          break;
        }
      }
    });
    
    return sensitiveFields;
  }
  
  generateAuditTriggers(entity: Entity): DatabaseTrigger[] {
    const triggers: DatabaseTrigger[] = [];
    
    // Insert trigger
    triggers.push({
      name: `audit_${entity.name}_insert`,
      event: 'INSERT',
      timing: 'AFTER',
      body: this.generateInsertTriggerBody(entity)
    });
    
    // Update trigger
    triggers.push({
      name: `audit_${entity.name}_update`,
      event: 'UPDATE',
      timing: 'AFTER',
      body: this.generateUpdateTriggerBody(entity)
    });
    
    // Delete trigger
    triggers.push({
      name: `audit_${entity.name}_delete`,
      event: 'DELETE',
      timing: 'BEFORE',
      body: this.generateDeleteTriggerBody(entity)
    });
    
    return triggers;
  }
  
  private getMaskingStrategy(type: string, field: Field): MaskingStrategy {
    switch (type) {
      case 'ssn':
        return { type: 'partial', showLast: 4, replaceWith: '*' };
      case 'creditCard':
        return { type: 'partial', showFirst: 6, showLast: 4, replaceWith: '*' };
      case 'email':
        return { type: 'partial', showDomain: true, replaceWith: '***' };
      case 'password':
        return { type: 'hash', algorithm: 'sha256' };
      case 'financial':
        return { type: 'encrypt', algorithm: 'aes-256-gcm' };
      default:
        return { type: 'redact' };
    }
  }
}
```

### Express.js Audit Middleware
```typescript
import { Request, Response, NextFunction } from 'express';
import { AsyncLocalStorage } from 'async_hooks';

export class AuditMiddleware {
  private asyncLocalStorage = new AsyncLocalStorage<AuditContext>();
  
  constructor(
    private auditService: AuditService,
    private config: AuditConfig
  ) {}
  
  // Main audit middleware
  middleware() {
    return async (req: Request, res: Response, next: NextFunction) => {
      const auditContext: AuditContext = {
        requestId: generateRequestId(),
        userId: req.user?.id,
        sessionId: req.session?.id,
        ipAddress: this.getClientIp(req),
        userAgent: req.headers['user-agent'],
        timestamp: new Date(),
        method: req.method,
        path: req.path,
        query: this.sanitizeData(req.query),
        body: this.sanitizeData(req.body)
      };
      
      // Store context for nested operations
      this.asyncLocalStorage.run(auditContext, async () => {
        // Log request
        await this.auditService.logEvent({
          type: 'api_request',
          category: 'api',
          severity: 'info',
          ...auditContext
        });
        
        // Capture response
        const originalSend = res.send;
        res.send = function(data: any) {
          res.locals.responseBody = data;
          return originalSend.call(this, data);
        };
        
        // Continue processing
        next();
      });
    };
  }
  
  // Database query interceptor
  databaseInterceptor() {
    return {
      beforeCreate: async (instance: any, options: any) => {
        const context = this.asyncLocalStorage.getStore();
        await this.auditService.logEvent({
          type: 'data_create',
          category: 'database',
          severity: 'info',
          entity: instance.constructor.name,
          data: this.sanitizeData(instance.toJSON()),
          ...context
        });
      },
      
      beforeUpdate: async (instance: any, options: any) => {
        const context = this.asyncLocalStorage.getStore();
        const changes = instance.changed();
        const previousValues: any = {};
        const currentValues: any = {};
        
        changes.forEach((field: string) => {
          previousValues[field] = instance._previousDataValues[field];
          currentValues[field] = instance[field];
        });
        
        await this.auditService.logEvent({
          type: 'data_update',
          category: 'database',
          severity: 'info',
          entity: instance.constructor.name,
          entityId: instance.id,
          changes: {
            before: this.sanitizeData(previousValues),
            after: this.sanitizeData(currentValues)
          },
          ...context
        });
      },
      
      beforeDestroy: async (instance: any, options: any) => {
        const context = this.asyncLocalStorage.getStore();
        await this.auditService.logEvent({
          type: 'data_delete',
          category: 'database',
          severity: 'warning',
          entity: instance.constructor.name,
          entityId: instance.id,
          data: this.sanitizeData(instance.toJSON()),
          ...context
        });
      }
    };
  }
  
  // Error logging middleware
  errorLogger() {
    return async (err: Error, req: Request, res: Response, next: NextFunction) => {
      const context = this.asyncLocalStorage.getStore();
      
      await this.auditService.logEvent({
        type: 'error',
        category: 'system',
        severity: 'error',
        error: {
          message: err.message,
          stack: err.stack,
          name: err.name
        },
        ...context
      });
      
      next(err);
    };
  }
  
  // Performance tracking
  performanceTracker() {
    return async (req: Request, res: Response, next: NextFunction) => {
      const startTime = process.hrtime.bigint();
      
      res.on('finish', async () => {
        const endTime = process.hrtime.bigint();
        const duration = Number(endTime - startTime) / 1_000_000; // Convert to ms
        
        if (duration > this.config.performanceThreshold) {
          const context = this.asyncLocalStorage.getStore();
          await this.auditService.logEvent({
            type: 'performance',
            category: 'monitoring',
            severity: 'warning',
            duration,
            threshold: this.config.performanceThreshold,
            ...context
          });
        }
      });
      
      next();
    };
  }
  
  private sanitizeData(data: any): any {
    if (!data) return data;
    
    const sanitized = JSON.parse(JSON.stringify(data));
    const sensitiveFields = this.config.sensitiveFields;
    
    const sanitizeObject = (obj: any) => {
      for (const key in obj) {
        if (sensitiveFields.some(field => key.toLowerCase().includes(field))) {
          obj[key] = '[REDACTED]';
        } else if (typeof obj[key] === 'object' && obj[key] !== null) {
          sanitizeObject(obj[key]);
        }
      }
    };
    
    sanitizeObject(sanitized);
    return sanitized;
  }
  
  private getClientIp(req: Request): string {
    return req.headers['x-forwarded-for'] as string ||
           req.headers['x-real-ip'] as string ||
           req.connection.remoteAddress ||
           '';
  }
}
```

### Database Audit Triggers
```sql
-- PostgreSQL audit trigger implementation
CREATE TABLE IF NOT EXISTS audit_log (
  id BIGSERIAL PRIMARY KEY,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  user_id VARCHAR(255),
  session_id VARCHAR(255),
  ip_address INET,
  action VARCHAR(50) NOT NULL,
  table_name VARCHAR(255) NOT NULL,
  record_id VARCHAR(255),
  old_values JSONB,
  new_values JSONB,
  changed_fields TEXT[],
  metadata JSONB,
  INDEX idx_audit_timestamp (timestamp),
  INDEX idx_audit_user (user_id),
  INDEX idx_audit_table_record (table_name, record_id)
) PARTITION BY RANGE (timestamp);

-- Create monthly partitions
CREATE TABLE audit_log_2024_01 PARTITION OF audit_log
  FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

-- Audit trigger function
CREATE OR REPLACE FUNCTION audit_trigger_function()
RETURNS TRIGGER AS $$
DECLARE
  audit_data JSONB;
  changed_fields TEXT[];
  old_data JSONB;
  new_data JSONB;
BEGIN
  -- Get session variables
  audit_data = jsonb_build_object(
    'user_id', current_setting('app.current_user_id', true),
    'session_id', current_setting('app.session_id', true),
    'ip_address', current_setting('app.client_ip', true)::INET
  );
  
  -- Determine action and capture data
  IF TG_OP = 'INSERT' THEN
    new_data = to_jsonb(NEW);
    changed_fields = array(SELECT jsonb_object_keys(new_data));
  ELSIF TG_OP = 'UPDATE' THEN
    old_data = to_jsonb(OLD);
    new_data = to_jsonb(NEW);
    
    -- Find changed fields
    SELECT array_agg(key) INTO changed_fields
    FROM jsonb_each(old_data) o
    FULL OUTER JOIN jsonb_each(new_data) n USING (key)
    WHERE o.value IS DISTINCT FROM n.value;
  ELSIF TG_OP = 'DELETE' THEN
    old_data = to_jsonb(OLD);
    changed_fields = array(SELECT jsonb_object_keys(old_data));
  END IF;
  
  -- Insert audit record
  INSERT INTO audit_log (
    user_id,
    session_id,
    ip_address,
    action,
    table_name,
    record_id,
    old_values,
    new_values,
    changed_fields,
    metadata
  ) VALUES (
    audit_data->>'user_id',
    audit_data->>'session_id',
    (audit_data->>'ip_address')::INET,
    TG_OP,
    TG_TABLE_NAME,
    COALESCE(NEW.id::TEXT, OLD.id::TEXT),
    old_data,
    new_data,
    changed_fields,
    audit_data
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to tables
CREATE TRIGGER audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON users
FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();
```

### React Audit Implementation
```tsx
import React, { createContext, useContext, useEffect, useRef } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';

interface AuditContextValue {
  logEvent: (event: AuditEvent) => void;
  logAction: (action: string, data?: any) => void;
  logError: (error: Error, context?: any) => void;
  startTimer: (label: string) => () => void;
}

const AuditContext = createContext<AuditContextValue | undefined>(undefined);

// Audit provider component
export const AuditProvider: React.FC<{ children: React.ReactNode }> = ({ 
  children 
}) => {
  const location = useLocation();
  const auditQueue = useRef<AuditEvent[]>([]);
  const timers = useRef<Map<string, number>>(new Map());
  
  // Track page views
  useEffect(() => {
    logEvent({
      type: 'page_view',
      category: 'navigation',
      path: location.pathname,
      search: location.search
    });
  }, [location]);
  
  // Track session duration
  useEffect(() => {
    const sessionStart = Date.now();
    
    return () => {
      logEvent({
        type: 'session_end',
        category: 'session',
        duration: Date.now() - sessionStart
      });
      
      // Flush remaining events
      flushAuditQueue();
    };
  }, []);
  
  const logEvent = (event: AuditEvent) => {
    const enrichedEvent: AuditEvent = {
      ...event,
      timestamp: new Date().toISOString(),
      sessionId: getSessionId(),
      userId: getCurrentUserId(),
      browser: getBrowserInfo(),
      viewport: getViewportInfo()
    };
    
    auditQueue.current.push(enrichedEvent);
    
    if (auditQueue.current.length >= 10) {
      flushAuditQueue();
    }
  };
  
  const logAction = (action: string, data?: any) => {
    logEvent({
      type: 'user_action',
      category: 'interaction',
      action,
      data: sanitizeData(data)
    });
  };
  
  const logError = (error: Error, context?: any) => {
    logEvent({
      type: 'error',
      category: 'error',
      severity: 'error',
      error: {
        message: error.message,
        stack: error.stack,
        name: error.name
      },
      context: sanitizeData(context)
    });
  };
  
  const startTimer = (label: string): (() => void) => {
    const startTime = performance.now();
    timers.current.set(label, startTime);
    
    return () => {
      const endTime = performance.now();
      const duration = endTime - (timers.current.get(label) || startTime);
      timers.current.delete(label);
      
      logEvent({
        type: 'performance',
        category: 'timing',
        label,
        duration
      });
    };
  };
  
  const flushAuditQueue = async () => {
    if (auditQueue.current.length === 0) return;
    
    const events = [...auditQueue.current];
    auditQueue.current = [];
    
    try {
      await fetch('/api/audit/batch', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ events })
      });
    } catch (error) {
      console.error('Failed to send audit events:', error);
      // Store in localStorage for retry
      const stored = localStorage.getItem('pending_audit_events');
      const pending = stored ? JSON.parse(stored) : [];
      pending.push(...events);
      localStorage.setItem('pending_audit_events', JSON.stringify(pending));
    }
  };
  
  // Flush events periodically
  useEffect(() => {
    const interval = setInterval(flushAuditQueue, 30000); // 30 seconds
    return () => clearInterval(interval);
  }, []);
  
  return (
    <AuditContext.Provider value={{ logEvent, logAction, logError, startTimer }}>
      {children}
    </AuditContext.Provider>
  );
};

// Audit hook
export const useAudit = () => {
  const context = useContext(AuditContext);
  if (!context) {
    throw new Error('useAudit must be used within AuditProvider');
  }
  return context;
};

// HOC for component auditing
export function withAudit<P extends object>(
  Component: React.ComponentType<P>,
  componentName: string
) {
  return React.forwardRef<any, P>((props, ref) => {
    const { logAction, startTimer } = useAudit();
    const mountTimer = useRef<(() => void) | null>(null);
    
    useEffect(() => {
      // Track component mount
      logAction('component_mount', { component: componentName });
      mountTimer.current = startTimer(`${componentName}_render`);
      
      return () => {
        // Track component unmount
        logAction('component_unmount', { component: componentName });
        if (mountTimer.current) {
          mountTimer.current();
        }
      };
    }, []);
    
    // Track prop changes
    useEffect(() => {
      logAction('props_change', { 
        component: componentName,
        props: sanitizeData(props)
      });
    }, [props]);
    
    return <Component {...props} ref={ref} />;
  });
}

// Error boundary with audit logging
export class AuditErrorBoundary extends React.Component<
  { children: React.ReactNode },
  { hasError: boolean }
> {
  constructor(props: { children: React.ReactNode }) {
    super(props);
    this.state = { hasError: false };
  }
  
  static getDerivedStateFromError(error: Error) {
    return { hasError: true };
  }
  
  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    // Log to audit system
    fetch('/api/audit/error', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        type: 'react_error',
        error: {
          message: error.message,
          stack: error.stack,
          componentStack: errorInfo.componentStack
        },
        timestamp: new Date().toISOString()
      })
    }).catch(console.error);
  }
  
  render() {
    if (this.state.hasError) {
      return (
        <div className="error-boundary">
          <h2>Something went wrong</h2>
          <p>The error has been logged for investigation.</p>
        </div>
      );
    }
    
    return this.props.children;
  }
}

// Performance monitoring hook
export const usePerformanceAudit = (componentName: string) => {
  const { logEvent } = useAudit();
  const renderCount = useRef(0);
  const renderTimer = useRef<number>();
  
  useEffect(() => {
    renderTimer.current = performance.now();
    
    return () => {
      const renderTime = performance.now() - (renderTimer.current || 0);
      renderCount.current++;
      
      if (renderTime > 16.67) { // Over 60fps threshold
        logEvent({
          type: 'performance_warning',
          category: 'performance',
          component: componentName,
          renderTime,
          renderCount: renderCount.current
        });
      }
    };
  });
};

// Utility functions
function sanitizeData(data: any): any {
  if (!data) return data;
  
  const sensitivePatterns = [
    /password/i,
    /secret/i,
    /token/i,
    /key/i,
    /ssn/i,
    /creditcard/i
  ];
  
  const sanitize = (obj: any): any => {
    if (typeof obj !== 'object' || obj === null) return obj;
    
    const sanitized: any = Array.isArray(obj) ? [] : {};
    
    for (const key in obj) {
      if (sensitivePatterns.some(pattern => pattern.test(key))) {
        sanitized[key] = '[REDACTED]';
      } else if (typeof obj[key] === 'object') {
        sanitized[key] = sanitize(obj[key]);
      } else {
        sanitized[key] = obj[key];
      }
    }
    
    return sanitized;
  };
  
  return sanitize(data);
}
```

### Vue.js Audit Implementation
```vue
<template>
  <div>
    <slot />
  </div>
</template>

<script setup lang="ts">
import { provide, onMounted, onUnmounted, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import type { AuditEvent } from '@/types/audit';

// Audit queue for batching
const auditQueue = ref<AuditEvent[]>([]);
const timers = new Map<string, number>();

// Log event function
function logEvent(event: Partial<AuditEvent>) {
  const enrichedEvent: AuditEvent = {
    ...event,
    timestamp: new Date().toISOString(),
    sessionId: getSessionId(),
    userId: getCurrentUserId(),
    browser: getBrowserInfo(),
    viewport: getViewportInfo()
  } as AuditEvent;
  
  auditQueue.value.push(enrichedEvent);
  
  if (auditQueue.value.length >= 10) {
    flushAuditQueue();
  }
}

// Log user action
function logAction(action: string, data?: any) {
  logEvent({
    type: 'user_action',
    category: 'interaction',
    action,
    data: sanitizeData(data)
  });
}

// Log error
function logError(error: Error, context?: any) {
  logEvent({
    type: 'error',
    category: 'error',
    severity: 'error',
    error: {
      message: error.message,
      stack: error.stack,
      name: error.name
    },
    context: sanitizeData(context)
  });
}

// Performance timer
function startTimer(label: string): () => void {
  const startTime = performance.now();
  timers.set(label, startTime);
  
  return () => {
    const endTime = performance.now();
    const duration = endTime - (timers.get(label) || startTime);
    timers.delete(label);
    
    logEvent({
      type: 'performance',
      category: 'timing',
      label,
      duration
    });
  };
}

// Flush audit queue
async function flushAuditQueue() {
  if (auditQueue.value.length === 0) return;
  
  const events = [...auditQueue.value];
  auditQueue.value = [];
  
  try {
    await fetch('/api/audit/batch', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ events })
    });
  } catch (error) {
    console.error('Failed to send audit events:', error);
    // Store in localStorage for retry
    const stored = localStorage.getItem('pending_audit_events');
    const pending = stored ? JSON.parse(stored) : [];
    pending.push(...events);
    localStorage.setItem('pending_audit_events', JSON.stringify(pending));
  }
}

// Provide audit functions
provide('audit', {
  logEvent,
  logAction,
  logError,
  startTimer
});

// Track route changes
const route = useRoute();
const router = useRouter();

router.afterEach((to, from) => {
  logEvent({
    type: 'navigation',
    category: 'router',
    from: from.fullPath,
    to: to.fullPath,
    params: to.params,
    query: to.query
  });
});

// Session tracking
const sessionStart = Date.now();

onMounted(() => {
  // Retry pending events
  const pending = localStorage.getItem('pending_audit_events');
  if (pending) {
    try {
      const events = JSON.parse(pending);
      auditQueue.value.push(...events);
      localStorage.removeItem('pending_audit_events');
      flushAuditQueue();
    } catch (error) {
      console.error('Failed to parse pending events:', error);
    }
  }
  
  // Periodic flush
  const interval = setInterval(flushAuditQueue, 30000);
  
  onUnmounted(() => {
    clearInterval(interval);
    
    // Log session end
    logEvent({
      type: 'session_end',
      category: 'session',
      duration: Date.now() - sessionStart
    });
    
    // Final flush
    flushAuditQueue();
  });
});

// Error handler
const errorHandler = (event: ErrorEvent) => {
  logError(new Error(event.message), {
    filename: event.filename,
    lineno: event.lineno,
    colno: event.colno
  });
};

window.addEventListener('error', errorHandler);
onUnmounted(() => {
  window.removeEventListener('error', errorHandler);
});
</script>

<!-- Audit directive -->
<script lang="ts">
import { Directive } from 'vue';

export const vAudit: Directive = {
  mounted(el, binding) {
    const { logAction } = useAudit();
    const { event = 'click', action, data } = binding.value;
    
    const handler = () => {
      logAction(action, typeof data === 'function' ? data() : data);
    };
    
    el.addEventListener(event, handler);
    el._auditHandler = handler;
    el._auditEvent = event;
  },
  
  unmounted(el) {
    if (el._auditHandler && el._auditEvent) {
      el.removeEventListener(el._auditEvent, el._auditHandler);
    }
  }
};
</script>

<!-- Composable -->
<script lang="ts">
import { inject } from 'vue';

export function useAudit() {
  const audit = inject('audit');
  if (!audit) {
    throw new Error('useAudit must be used within AuditProvider');
  }
  return audit;
}
</script>

<!-- Vuex plugin -->
<script lang="ts">
import type { Store } from 'vuex';

export function createAuditPlugin() {
  return (store: Store<any>) => {
    // Log all mutations
    store.subscribe((mutation, state) => {
      logEvent({
        type: 'state_change',
        category: 'vuex',
        mutation: mutation.type,
        payload: sanitizeData(mutation.payload)
      });
    });
    
    // Log all actions
    store.subscribeAction({
      before: (action, state) => {
        logEvent({
          type: 'action_dispatch',
          category: 'vuex',
          action: action.type,
          payload: sanitizeData(action.payload)
        });
      },
      error: (action, state, error) => {
        logError(error, {
          action: action.type,
          payload: action.payload
        });
      }
    });
  };
}
</script>
```

### Audit Analysis & Reporting
```typescript
// Anomaly detection engine
export class AnomalyDetectionEngine {
  private algorithms: AnomalyAlgorithm[] = [
    new StatisticalAnomalyDetector(),
    new MachineLearningDetector(),
    new RuleBasedDetector()
  ];
  
  async detectAnomalies(logs: AuditLog[]): Promise<Anomaly[]> {
    const anomalies: Anomaly[] = [];
    
    // Run each algorithm
    for (const algorithm of this.algorithms) {
      const detected = await algorithm.detect(logs);
      anomalies.push(...detected);
    }
    
    // Deduplicate and score
    return this.consolidateAnomalies(anomalies);
  }
  
  private consolidateAnomalies(anomalies: Anomaly[]): Anomaly[] {
    const grouped = new Map<string, Anomaly[]>();
    
    // Group by event
    anomalies.forEach(anomaly => {
      const key = `${anomaly.eventId}-${anomaly.type}`;
      if (!grouped.has(key)) {
        grouped.set(key, []);
      }
      grouped.get(key)!.push(anomaly);
    });
    
    // Consolidate scores
    const consolidated: Anomaly[] = [];
    grouped.forEach(group => {
      const scores = group.map(a => a.score);
      const avgScore = scores.reduce((a, b) => a + b) / scores.length;
      
      consolidated.push({
        ...group[0],
        score: avgScore,
        detectedBy: group.map(a => a.algorithm)
      });
    });
    
    return consolidated.sort((a, b) => b.score - a.score);
  }
}

// Compliance report generator
export class ComplianceReportGenerator {
  async generateReport(
    type: ComplianceFramework,
    startDate: Date,
    endDate: Date
  ): Promise<ComplianceReport> {
    const framework = this.getFramework(type);
    const logs = await this.auditService.getLogsInRange(startDate, endDate);
    
    const report: ComplianceReport = {
      framework: type,
      period: { start: startDate, end: endDate },
      generatedAt: new Date(),
      requirements: [],
      summary: {
        totalRequirements: 0,
        compliantRequirements: 0,
        violations: 0,
        warnings: 0
      }
    };
    
    // Check each requirement
    for (const requirement of framework.requirements) {
      const result = await this.checkRequirement(requirement, logs);
      report.requirements.push(result);
      
      // Update summary
      report.summary.totalRequirements++;
      if (result.status === 'compliant') {
        report.summary.compliantRequirements++;
      } else if (result.status === 'violation') {
        report.summary.violations++;
      } else if (result.status === 'warning') {
        report.summary.warnings++;
      }
    }
    
    report.summary.complianceScore = 
      (report.summary.compliantRequirements / report.summary.totalRequirements) * 100;
    
    return report;
  }
  
  private async checkRequirement(
    requirement: ComplianceRequirement,
    logs: AuditLog[]
  ): Promise<RequirementResult> {
    const relevantLogs = logs.filter(log => 
      requirement.eventTypes.includes(log.type)
    );
    
    const violations: Violation[] = [];
    
    // Check specific rules
    for (const rule of requirement.rules) {
      const ruleViolations = await this.checkRule(rule, relevantLogs);
      violations.push(...ruleViolations);
    }
    
    return {
      requirement: requirement.id,
      name: requirement.name,
      status: violations.length === 0 ? 'compliant' : 'violation',
      violations,
      evidence: relevantLogs.slice(0, 10) // Sample evidence
    };
  }
}

// React Compliance Dashboard
export const ComplianceDashboard: React.FC = () => {
  const [framework, setFramework] = useState<ComplianceFramework>('GDPR');
  const [dateRange, setDateRange] = useState<[Date, Date]>([
    startOfMonth(new Date()),
    endOfMonth(new Date())
  ]);
  const [report, setReport] = useState<ComplianceReport | null>(null);
  const [loading, setLoading] = useState(false);
  
  const generateReport = async () => {
    setLoading(true);
    try {
      const result = await api.post('/api/audit/compliance-report', {
        framework,
        startDate: dateRange[0],
        endDate: dateRange[1]
      });
      setReport(result.data);
    } catch (error) {
      console.error('Failed to generate report:', error);
    } finally {
      setLoading(false);
    }
  };
  
  return (
    <div className="compliance-dashboard">
      <Card>
        <CardHeader>
          <CardTitle>Compliance Report Generator</CardTitle>
        </CardHeader>
        <CardBody>
          <div className="flex gap-4 mb-4">
            <Select
              value={framework}
              onChange={(e) => setFramework(e.target.value as ComplianceFramework)}
            >
              <option value="GDPR">GDPR</option>
              <option value="HIPAA">HIPAA</option>
              <option value="SOX">SOX</option>
              <option value="PCI-DSS">PCI-DSS</option>
            </Select>
            
            <DateRangePicker
              value={dateRange}
              onChange={setDateRange}
            />
            
            <Button onClick={generateReport} loading={loading}>
              Generate Report
            </Button>
          </div>
          
          {report && (
            <>
              <div className="grid grid-cols-4 gap-4 mb-6">
                <MetricCard
                  title="Compliance Score"
                  value={`${report.summary.complianceScore.toFixed(1)}%`}
                  trend={report.summary.complianceScore >= 95 ? 'up' : 'down'}
                />
                <MetricCard
                  title="Requirements"
                  value={report.summary.totalRequirements}
                  subtitle={`${report.summary.compliantRequirements} compliant`}
                />
                <MetricCard
                  title="Violations"
                  value={report.summary.violations}
                  variant={report.summary.violations > 0 ? 'danger' : 'success'}
                />
                <MetricCard
                  title="Warnings"
                  value={report.summary.warnings}
                  variant={report.summary.warnings > 0 ? 'warning' : 'success'}
                />
              </div>
              
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Requirement</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Violations</TableHead>
                    <TableHead>Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {report.requirements.map(req => (
                    <TableRow key={req.requirement}>
                      <TableCell>{req.name}</TableCell>
                      <TableCell>
                        <Badge variant={
                          req.status === 'compliant' ? 'success' :
                          req.status === 'warning' ? 'warning' : 'danger'
                        }>
                          {req.status}
                        </Badge>
                      </TableCell>
                      <TableCell>{req.violations.length}</TableCell>
                      <TableCell>
                        <Button size="sm" variant="ghost">
                          View Details
                        </Button>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </>
          )}
        </CardBody>
      </Card>
    </div>
  );
};
```

### Compliance & Security Configuration
```typescript
// Complete audit configuration
export const auditConfig: AuditConfiguration = {
  // Core settings
  core: {
    enabled: true,
    mode: 'async',
    bufferSize: 10000,
    flushInterval: 30000,
    compressionEnabled: true,
    encryptionEnabled: true
  },
  
  // Compliance frameworks
  compliance: {
    gdpr: {
      enabled: true,
      dataRetention: 90, // days
      rightToErasure: true,
      dataPortability: true,
      consentTracking: true,
      anonymizationDelay: 30 // days
    },
    
    hipaa: {
      enabled: true,
      minimumPasswordLength: 12,
      sessionTimeout: 900000, // 15 minutes
      encryptionRequired: true,
      auditRetention: 2190, // 6 years
      accessReportFrequency: 'monthly'
    },
    
    sox: {
      enabled: true,
      changeApprovalRequired: true,
      segregationOfDuties: true,
      financialDataRetention: 2555, // 7 years
      quarterlyReview: true
    },
    
    pciDss: {
      enabled: true,
      cardDataMasking: true,
      networkSegmentation: true,
      vulnerabilityScanning: 'quarterly',
      penetrationTesting: 'annual',
      logRetention: 365 // 1 year minimum
    }
  },
  
  // Security settings
  security: {
    encryption: {
      algorithm: 'aes-256-gcm',
      keyRotation: 90, // days
      transitEncryption: true,
      atRestEncryption: true
    },
    
    integrity: {
      hashChaining: true,
      digitalSignatures: true,
      timestamping: true,
      tamperDetection: true
    },
    
    accessControl: {
      requireAuthentication: true,
      requireMFA: true,
      ipWhitelist: [],
      sessionRecording: true
    }
  },
  
  // Performance optimization
  performance: {
    asyncProcessing: true,
    batchSize: 1000,
    parallelWorkers: 4,
    compressionLevel: 6,
    
    indexes: [
      { fields: ['timestamp'], type: 'btree' },
      { fields: ['userId'], type: 'hash' },
      { fields: ['entityType', 'entityId'], type: 'compound' },
      { fields: ['severity'], type: 'btree', condition: "severity != 'info'" }
    ],
    
    partitioning: {
      strategy: 'time-based',
      interval: 'monthly',
      retention: {
        hot: 30, // days
        warm: 90,
        cold: 365,
        archive: 2555 // 7 years
      }
    }
  },
  
  // Storage configuration
  storage: {
    primary: {
      type: 'postgresql',
      connection: process.env.AUDIT_DB_URL,
      pool: { min: 2, max: 10 },
      ssl: true
    },
    
    archive: {
      type: 's3',
      bucket: process.env.AUDIT_ARCHIVE_BUCKET,
      region: process.env.AWS_REGION,
      encryption: 'AES256',
      lifecycle: {
        transitionToIA: 90,
        transitionToGlacier: 365
      }
    },
    
    cache: {
      type: 'redis',
      connection: process.env.REDIS_URL,
      ttl: 3600
    }
  },
  
  // Integration settings
  integrations: {
    siem: {
      type: 'splunk',
      endpoint: process.env.SPLUNK_HEC_URL,
      token: process.env.SPLUNK_HEC_TOKEN,
      sourcetype: 'admin_audit_log'
    },
    
    monitoring: {
      type: 'datadog',
      apiKey: process.env.DATADOG_API_KEY,
      tags: ['env:production', 'service:admin-panel']
    },
    
    alerting: {
      channels: [
        {
          type: 'email',
          recipients: ['security@company.com'],
          severities: ['critical', 'high']
        },
        {
          type: 'slack',
          webhook: process.env.SLACK_WEBHOOK,
          channel: '#security-alerts',
          severities: ['critical', 'high', 'medium']
        },
        {
          type: 'pagerduty',
          serviceKey: process.env.PAGERDUTY_KEY,
          severities: ['critical']
        }
      ]
    }
  }
};
```

## Integration Points
- Receives schema information from Schema Analyzer
- Coordinates with Access Control Manager for permissions
- Works with Encryption Specialist for data protection
- Integrates with Vulnerability Scanner for security monitoring
- Provides data to Compliance Checker for reports

## Best Practices
1. Log all security-relevant events without exception
2. Use structured logging for easy parsing
3. Implement log rotation and archival strategies
4. Encrypt sensitive data in logs
5. Monitor log integrity continuously
6. Set up real-time alerting for critical events
7. Regular compliance report generation
8. Implement proper log retention policies
9. Use correlation IDs for request tracing
10. Test audit trail completeness regularly