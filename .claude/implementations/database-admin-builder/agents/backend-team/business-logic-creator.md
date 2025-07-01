# Business Logic Creator Agent

## Purpose
Generates comprehensive business logic layers including CRUD operations, workflows, state machines, and complex business rule implementations.

## Capabilities

### Core Features
- CRUD operation generation
- Business rule engine
- Workflow orchestration
- State machine implementation
- Event-driven architecture
- Transaction management
- Domain-driven design patterns
- Service layer generation

### Advanced Capabilities
- Saga pattern implementation
- CQRS (Command Query Responsibility Segregation)
- Event sourcing
- Business process automation
- Rule-based decision making
- Approval workflows
- Notification triggers
- Audit trail generation

## Service Layer Architecture

### Base Service Class
```javascript
// Generated base service with common patterns
class BaseService {
  constructor(model, dependencies = {}) {
    this.model = model;
    this.validator = dependencies.validator;
    this.eventBus = dependencies.eventBus;
    this.auditLogger = dependencies.auditLogger;
    this.cache = dependencies.cache;
  }
  
  async findById(id, options = {}) {
    const { 
      includes = [], 
      fields = null,
      checkPermissions = true,
      user = null 
    } = options;
    
    if (checkPermissions && user) {
      await this.checkPermission(user, 'read', id);
    }
    
    let query = this.model.query().findById(id);
    
    if (includes.length > 0) {
      query = query.withGraphFetched(this.buildIncludeGraph(includes));
    }
    
    if (fields) {
      query = query.select(fields);
    }
    
    const result = await query;
    
    if (!result) {
      throw new NotFoundError(`${this.model.name} not found`);
    }
    
    await this.afterFind(result, options);
    
    return result;
  }
  
  async create(data, options = {}) {
    const { user, skipValidation = false } = options;
    
    // Start transaction
    const trx = await this.model.startTransaction();
    
    try {
      // Validate
      if (!skipValidation) {
        await this.validate(data, 'create');
      }
      
      // Check permissions
      if (user) {
        await this.checkPermission(user, 'create');
      }
      
      // Apply business rules
      data = await this.beforeCreate(data, options);
      
      // Create record
      const created = await this.model
        .query(trx)
        .insert(data)
        .returning('*');
      
      // Handle related data
      if (data._relations) {
        await this.createRelations(created, data._relations, trx);
      }
      
      // Trigger events
      await this.eventBus.emit(`${this.model.tableName}.created`, {
        record: created,
        user,
        timestamp: new Date()
      });
      
      // Audit log
      await this.auditLogger.log({
        action: 'CREATE',
        model: this.model.name,
        recordId: created.id,
        data: created,
        user: user?.id
      });
      
      await trx.commit();
      
      // After create hooks
      await this.afterCreate(created, options);
      
      // Clear relevant caches
      await this.invalidateCache();
      
      return created;
    } catch (error) {
      await trx.rollback();
      throw error;
    }
  }
  
  async update(id, data, options = {}) {
    const { 
      user, 
      skipValidation = false,
      returnOld = false 
    } = options;
    
    const trx = await this.model.startTransaction();
    
    try {
      // Get existing record
      const existing = await this.model
        .query(trx)
        .findById(id)
        .forUpdate(); // Lock row
      
      if (!existing) {
        throw new NotFoundError(`${this.model.name} not found`);
      }
      
      // Check permissions
      if (user) {
        await this.checkPermission(user, 'update', existing);
      }
      
      // Validate
      if (!skipValidation) {
        await this.validate(data, 'update', existing);
      }
      
      // Apply business rules
      data = await this.beforeUpdate(data, existing, options);
      
      // Update record
      const updated = await this.model
        .query(trx)
        .patchAndFetchById(id, data);
      
      // Create change log
      await this.createChangeLog(existing, updated, user, trx);
      
      // Trigger events
      await this.eventBus.emit(`${this.model.tableName}.updated`, {
        old: existing,
        new: updated,
        changes: this.getChanges(existing, updated),
        user,
        timestamp: new Date()
      });
      
      await trx.commit();
      
      // After update hooks
      await this.afterUpdate(updated, existing, options);
      
      // Clear caches
      await this.invalidateCache(id);
      
      return returnOld ? { old: existing, new: updated } : updated;
    } catch (error) {
      await trx.rollback();
      throw error;
    }
  }
  
  async delete(id, options = {}) {
    const { user, soft = true, force = false } = options;
    
    const trx = await this.model.startTransaction();
    
    try {
      const existing = await this.model
        .query(trx)
        .findById(id)
        .forUpdate();
      
      if (!existing) {
        throw new NotFoundError(`${this.model.name} not found`);
      }
      
      // Check permissions
      if (user) {
        await this.checkPermission(user, 'delete', existing);
      }
      
      // Check if deletion is allowed
      await this.canDelete(existing, options);
      
      // Soft delete by default
      if (soft && !force) {
        await this.model
          .query(trx)
          .findById(id)
          .patch({
            deleted_at: new Date(),
            deleted_by: user?.id
          });
      } else {
        // Hard delete
        await this.model
          .query(trx)
          .deleteById(id);
      }
      
      // Handle cascading deletes
      await this.handleCascadingDeletes(existing, trx, { soft });
      
      // Trigger events
      await this.eventBus.emit(`${this.model.tableName}.deleted`, {
        record: existing,
        soft,
        user,
        timestamp: new Date()
      });
      
      await trx.commit();
      
      // After delete hooks
      await this.afterDelete(existing, options);
      
      // Clear caches
      await this.invalidateCache(id);
      
      return { success: true, deleted: existing };
    } catch (error) {
      await trx.rollback();
      throw error;
    }
  }
}
```

### Business Rule Engine
```javascript
class BusinessRuleEngine {
  constructor() {
    this.rules = new Map();
  }
  
  // Define business rules
  defineRule(name, rule) {
    this.rules.set(name, {
      name,
      condition: rule.when,
      action: rule.then,
      priority: rule.priority || 0,
      enabled: rule.enabled !== false
    });
  }
  
  // Order processing rules example
  initializeOrderRules() {
    // Automatic discount rule
    this.defineRule('bulk_discount', {
      when: (order) => order.items.length > 10,
      then: (order) => {
        order.discount = Math.min(order.subtotal * 0.1, 100);
        order.discountReason = 'Bulk order discount (10%)';
      },
      priority: 1
    });
    
    // VIP customer rule
    this.defineRule('vip_discount', {
      when: async (order, context) => {
        const customer = await context.getCustomer(order.customerId);
        return customer.tier === 'VIP' && order.subtotal > 500;
      },
      then: (order) => {
        order.discount = (order.discount || 0) + order.subtotal * 0.15;
        order.discountReason = (order.discountReason || '') + ' VIP discount (15%)';
      },
      priority: 2
    });
    
    // Inventory check rule
    this.defineRule('inventory_check', {
      when: async (order, context) => {
        for (const item of order.items) {
          const stock = await context.checkStock(item.productId);
          if (stock < item.quantity) {
            return true;
          }
        }
        return false;
      },
      then: (order) => {
        order.status = 'pending_inventory';
        order.holdReason = 'Insufficient inventory';
        throw new BusinessRuleError('Order requires inventory check');
      },
      priority: 0
    });
    
    // Fraud detection rule
    this.defineRule('fraud_check', {
      when: async (order, context) => {
        const riskScore = await context.calculateRiskScore(order);
        return riskScore > 0.8;
      },
      then: async (order, context) => {
        order.status = 'pending_review';
        order.requiresReview = true;
        await context.notifyFraudTeam(order);
      },
      priority: -1
    });
  }
  
  async applyRules(entity, context, ruleSet = null) {
    const applicableRules = ruleSet 
      ? this.getRuleSet(ruleSet)
      : Array.from(this.rules.values());
    
    // Sort by priority
    const sortedRules = applicableRules
      .filter(rule => rule.enabled)
      .sort((a, b) => a.priority - b.priority);
    
    const results = [];
    
    for (const rule of sortedRules) {
      try {
        const conditionMet = await rule.condition(entity, context);
        
        if (conditionMet) {
          await rule.action(entity, context);
          results.push({
            rule: rule.name,
            applied: true,
            timestamp: new Date()
          });
        }
      } catch (error) {
        if (error instanceof BusinessRuleError) {
          throw error;
        }
        
        results.push({
          rule: rule.name,
          applied: false,
          error: error.message
        });
      }
    }
    
    return results;
  }
}
```

### Workflow Engine
```javascript
class WorkflowEngine {
  constructor() {
    this.workflows = new Map();
    this.stateMachines = new Map();
  }
  
  // Define approval workflow
  defineApprovalWorkflow() {
    const workflow = {
      name: 'purchase_order_approval',
      triggers: ['purchase_order.created'],
      
      steps: [
        {
          id: 'manager_approval',
          type: 'approval',
          assignTo: 'direct_manager',
          condition: (po) => po.amount < 10000,
          timeout: '24h',
          actions: {
            approve: 'auto_approve_if_under_5000',
            reject: 'notify_requester'
          }
        },
        {
          id: 'finance_approval',
          type: 'approval',
          assignTo: 'finance_team',
          condition: (po) => po.amount >= 10000 && po.amount < 50000,
          timeout: '48h',
          escalateTo: 'cfo'
        },
        {
          id: 'executive_approval',
          type: 'approval',
          assignTo: 'cfo',
          condition: (po) => po.amount >= 50000,
          timeout: '72h',
          requiresComment: true
        },
        {
          id: 'process_order',
          type: 'system',
          action: async (po, context) => {
            await context.createPurchaseOrder(po);
            await context.notifyVendor(po);
            await context.updateBudget(po);
          }
        }
      ],
      
      onComplete: async (po, context) => {
        await context.notifyRequester(po, 'approved');
        await context.logApproval(po);
      },
      
      onReject: async (po, context, reason) => {
        await context.notifyRequester(po, 'rejected', reason);
        po.status = 'rejected';
        po.rejectionReason = reason;
      },
      
      onTimeout: async (po, context, step) => {
        await context.escalate(po, step);
      }
    };
    
    this.workflows.set(workflow.name, workflow);
  }
  
  async executeWorkflow(workflowName, entity, context) {
    const workflow = this.workflows.get(workflowName);
    if (!workflow) {
      throw new Error(`Workflow ${workflowName} not found`);
    }
    
    const execution = {
      id: uuid(),
      workflowName,
      entityId: entity.id,
      status: 'running',
      currentStep: 0,
      history: [],
      startedAt: new Date()
    };
    
    try {
      for (const step of workflow.steps) {
        if (step.condition && !await step.condition(entity, context)) {
          execution.history.push({
            step: step.id,
            action: 'skipped',
            timestamp: new Date()
          });
          continue;
        }
        
        const result = await this.executeStep(step, entity, context);
        
        execution.history.push({
          step: step.id,
          action: result.action,
          actor: result.actor,
          timestamp: new Date(),
          data: result.data
        });
        
        if (result.action === 'reject') {
          execution.status = 'rejected';
          await workflow.onReject(entity, context, result.reason);
          break;
        }
        
        execution.currentStep++;
      }
      
      if (execution.status !== 'rejected') {
        execution.status = 'completed';
        await workflow.onComplete(entity, context);
      }
      
    } catch (error) {
      execution.status = 'failed';
      execution.error = error.message;
      throw error;
    } finally {
      execution.completedAt = new Date();
      await this.saveExecution(execution);
    }
    
    return execution;
  }
}
```

### State Machine Implementation
```javascript
class StateMachine {
  constructor(config) {
    this.states = config.states;
    this.transitions = config.transitions;
    this.initialState = config.initialState;
    this.beforeTransition = config.beforeTransition || (() => {});
    this.afterTransition = config.afterTransition || (() => {});
  }
  
  // Order state machine example
  static createOrderStateMachine() {
    return new StateMachine({
      initialState: 'pending',
      
      states: {
        pending: {
          onEnter: async (order) => {
            await this.validateOrder(order);
          }
        },
        confirmed: {
          onEnter: async (order) => {
            await this.reserveInventory(order);
            await this.sendConfirmationEmail(order);
          }
        },
        processing: {
          onEnter: async (order) => {
            await this.chargePayment(order);
            await this.createShipment(order);
          }
        },
        shipped: {
          onEnter: async (order) => {
            await this.sendTrackingInfo(order);
          }
        },
        delivered: {
          onEnter: async (order) => {
            await this.requestFeedback(order);
          }
        },
        cancelled: {
          onEnter: async (order) => {
            await this.releaseInventory(order);
            await this.processRefund(order);
          }
        }
      },
      
      transitions: [
        { from: 'pending', to: 'confirmed', event: 'confirm' },
        { from: 'confirmed', to: 'processing', event: 'process' },
        { from: 'processing', to: 'shipped', event: 'ship' },
        { from: 'shipped', to: 'delivered', event: 'deliver' },
        { from: ['pending', 'confirmed'], to: 'cancelled', event: 'cancel' },
        { from: 'processing', to: 'cancelled', event: 'cancel', 
          guard: (order) => !order.paymentCaptured }
      ],
      
      beforeTransition: async (from, to, order) => {
        // Audit state change
        await AuditLog.create({
          entity: 'order',
          entityId: order.id,
          action: 'state_change',
          from,
          to,
          timestamp: new Date()
        });
      },
      
      afterTransition: async (from, to, order) => {
        // Send notifications
        await NotificationService.notify({
          type: 'order_status_changed',
          orderId: order.id,
          oldStatus: from,
          newStatus: to
        });
      }
    });
  }
  
  canTransition(currentState, event) {
    return this.transitions.some(t => 
      (t.from === currentState || 
       (Array.isArray(t.from) && t.from.includes(currentState))) &&
      t.event === event
    );
  }
  
  async transition(entity, event, context = {}) {
    const currentState = entity.state || this.initialState;
    
    const transition = this.transitions.find(t =>
      (t.from === currentState || 
       (Array.isArray(t.from) && t.from.includes(currentState))) &&
      t.event === event
    );
    
    if (!transition) {
      throw new Error(
        `Invalid transition: ${event} from ${currentState}`
      );
    }
    
    // Check guard condition
    if (transition.guard && !await transition.guard(entity, context)) {
      throw new Error(
        `Transition guard failed: ${event} from ${currentState}`
      );
    }
    
    // Before transition hook
    await this.beforeTransition(currentState, transition.to, entity);
    
    // Exit current state
    if (this.states[currentState]?.onExit) {
      await this.states[currentState].onExit(entity, context);
    }
    
    // Update state
    entity.state = transition.to;
    entity.stateChangedAt = new Date();
    
    // Enter new state
    if (this.states[transition.to]?.onEnter) {
      await this.states[transition.to].onEnter(entity, context);
    }
    
    // After transition hook
    await this.afterTransition(currentState, transition.to, entity);
    
    return entity;
  }
}
```

## Integration Points
- Works with API Generator for endpoint logic
- Coordinates with Validation Engineer
- Integrates with Audit Logger
- Connects with Notification System

## Best Practices
1. Use transactions for data consistency
2. Implement idempotent operations
3. Add comprehensive error handling
4. Log all business-critical operations
5. Make workflows configurable
6. Test edge cases thoroughly
7. Document business rules clearly