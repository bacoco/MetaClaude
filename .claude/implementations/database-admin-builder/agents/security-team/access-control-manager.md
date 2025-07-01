# Access Control Manager Agent

## Purpose
Implements comprehensive role-based access control (RBAC) and permission systems for admin panels by analyzing database schemas, defining security policies, and generating authorization middleware to ensure data protection and compliance.

## Capabilities

### Access Control Models
- Role-Based Access Control (RBAC)
- Attribute-Based Access Control (ABAC)
- Permission-Based Access Control
- Hierarchical roles
- Dynamic permissions
- Resource-level security
- Field-level security
- Row-level security (RLS)
- Multi-tenant isolation
- Time-based access

### Security Features
- OAuth2/OIDC integration
- SAML support
- Multi-factor authentication
- Session management
- API key management
- JWT token handling
- Permission inheritance
- Delegation support
- Audit trail integration
- Zero-trust architecture

### Policy Management
- Policy definition language
- Rule engine integration
- Conditional access
- Context-aware permissions
- Geographic restrictions
- Device trust levels
- Risk-based access
- Emergency access
- Break-glass procedures

## Access Control Strategy

### Schema-Based Security Model
```typescript
interface AccessControlGenerator {
  generateSecurityModel(schema: DatabaseSchema): SecurityModel {
    const model: SecurityModel = {
      resources: this.identifyResources(schema),
      roles: this.generateDefaultRoles(schema),
      permissions: this.generatePermissions(schema),
      policies: this.generatePolicies(schema),
      middleware: this.generateMiddleware(schema),
      validators: this.generateValidators(schema)
    };
    
    // Add field-level security
    this.addFieldLevelSecurity(model, schema);
    
    // Add row-level security
    this.addRowLevelSecurity(model, schema);
    
    // Add multi-tenant support
    if (this.isMultiTenant(schema)) {
      this.addMultiTenantSecurity(model, schema);
    }
    
    return model;
  }
  
  generatePermissions(schema: DatabaseSchema): Permission[] {
    const permissions: Permission[] = [];
    
    // Generate CRUD permissions for each entity
    schema.entities.forEach(entity => {
      const basePermissions = [
        {
          id: `${entity.name}:create`,
          name: `Create ${this.humanize(entity.name)}`,
          resource: entity.name,
          action: 'create',
          description: `Create new ${entity.name} records`
        },
        {
          id: `${entity.name}:read`,
          name: `View ${this.humanize(entity.name)}`,
          resource: entity.name,
          action: 'read',
          description: `View ${entity.name} records`
        },
        {
          id: `${entity.name}:update`,
          name: `Update ${this.humanize(entity.name)}`,
          resource: entity.name,
          action: 'update',
          description: `Update existing ${entity.name} records`
        },
        {
          id: `${entity.name}:delete`,
          name: `Delete ${this.humanize(entity.name)}`,
          resource: entity.name,
          action: 'delete',
          description: `Delete ${entity.name} records`
        }
      ];
      
      permissions.push(...basePermissions);
      
      // Add special permissions
      if (this.hasStatusField(entity)) {
        permissions.push({
          id: `${entity.name}:approve`,
          name: `Approve ${this.humanize(entity.name)}`,
          resource: entity.name,
          action: 'approve',
          description: `Approve ${entity.name} status changes`
        });
      }
      
      if (this.hasSensitiveData(entity)) {
        permissions.push({
          id: `${entity.name}:export`,
          name: `Export ${this.humanize(entity.name)}`,
          resource: entity.name,
          action: 'export',
          description: `Export ${entity.name} data`
        });
      }
      
      // Add field-specific permissions
      entity.fields.forEach(field => {
        if (field.sensitive || field.pii) {
          permissions.push({
            id: `${entity.name}:${field.name}:read`,
            name: `View ${this.humanize(field.name)} field`,
            resource: entity.name,
            action: 'read',
            field: field.name,
            description: `View sensitive ${field.name} data`
          });
        }
      });
    });
    
    // Add system permissions
    permissions.push(
      {
        id: 'system:manage_users',
        name: 'Manage Users',
        resource: 'system',
        action: 'manage_users',
        description: 'Create, update, and delete user accounts'
      },
      {
        id: 'system:manage_roles',
        name: 'Manage Roles',
        resource: 'system',
        action: 'manage_roles',
        description: 'Create and modify role definitions'
      },
      {
        id: 'system:view_audit_logs',
        name: 'View Audit Logs',
        resource: 'system',
        action: 'view_audit_logs',
        description: 'Access system audit trail'
      },
      {
        id: 'system:manage_settings',
        name: 'Manage Settings',
        resource: 'system',
        action: 'manage_settings',
        description: 'Modify system configuration'
      }
    );
    
    return permissions;
  }
  
  generateDefaultRoles(schema: DatabaseSchema): Role[] {
    return [
      {
        id: 'super_admin',
        name: 'Super Administrator',
        description: 'Full system access',
        permissions: ['*'], // All permissions
        priority: 100,
        system: true
      },
      {
        id: 'admin',
        name: 'Administrator',
        description: 'Administrative access',
        permissions: this.generateAdminPermissions(schema),
        priority: 90,
        system: true
      },
      {
        id: 'manager',
        name: 'Manager',
        description: 'Management access',
        permissions: this.generateManagerPermissions(schema),
        priority: 70,
        system: true
      },
      {
        id: 'editor',
        name: 'Editor',
        description: 'Content editing access',
        permissions: this.generateEditorPermissions(schema),
        priority: 50,
        system: true
      },
      {
        id: 'viewer',
        name: 'Viewer',
        description: 'Read-only access',
        permissions: this.generateViewerPermissions(schema),
        priority: 30,
        system: true
      },
      {
        id: 'guest',
        name: 'Guest',
        description: 'Limited guest access',
        permissions: this.generateGuestPermissions(schema),
        priority: 10,
        system: true
      }
    ];
  }
  
  generatePolicies(schema: DatabaseSchema): Policy[] {
    const policies: Policy[] = [];
    
    // Resource-based policies
    schema.entities.forEach(entity => {
      // Owner policy
      if (this.hasOwnerField(entity)) {
        policies.push({
          id: `${entity.name}_owner_policy`,
          name: `${entity.name} Owner Policy`,
          effect: 'allow',
          resources: [entity.name],
          actions: ['read', 'update', 'delete'],
          conditions: [
            {
              type: 'resource_owner',
              field: this.getOwnerField(entity),
              operator: 'equals',
              value: '${user.id}'
            }
          ]
        });
      }
      
      // Department isolation
      if (this.hasDepartmentField(entity)) {
        policies.push({
          id: `${entity.name}_department_policy`,
          name: `${entity.name} Department Policy`,
          effect: 'allow',
          resources: [entity.name],
          actions: ['*'],
          conditions: [
            {
              type: 'attribute_match',
              resourceField: 'department_id',
              userAttribute: 'department_id',
              operator: 'equals'
            }
          ]
        });
      }
      
      // Time-based access
      if (this.hasTimeSensitiveData(entity)) {
        policies.push({
          id: `${entity.name}_business_hours_policy`,
          name: `${entity.name} Business Hours Policy`,
          effect: 'deny',
          resources: [entity.name],
          actions: ['update', 'delete'],
          conditions: [
            {
              type: 'time_range',
              start: '18:00',
              end: '08:00',
              timezone: 'user'
            }
          ],
          priority: 10
        });
      }
    });
    
    // Global policies
    policies.push(
      {
        id: 'ip_whitelist_policy',
        name: 'IP Whitelist Policy',
        effect: 'deny',
        resources: ['*'],
        actions: ['*'],
        conditions: [
          {
            type: 'ip_address',
            operator: 'not_in',
            value: '${config.allowed_ips}'
          }
        ],
        priority: 100
      },
      {
        id: 'mfa_required_policy',
        name: 'MFA Required Policy',
        effect: 'deny',
        resources: ['*'],
        actions: ['create', 'update', 'delete'],
        conditions: [
          {
            type: 'user_attribute',
            attribute: 'mfa_enabled',
            operator: 'equals',
            value: false
          }
        ],
        priority: 90
      }
    );
    
    return policies;
  }
}
```

### Express.js Middleware Implementation
```typescript
import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { Redis } from 'ioredis';

// Permission checking middleware
export class PermissionMiddleware {
  constructor(
    private redis: Redis,
    private config: SecurityConfig
  ) {}
  
  // Check single permission
  requirePermission(permission: string) {
    return async (req: Request, res: Response, next: NextFunction) => {
      try {
        const user = req.user;
        if (!user) {
          return res.status(401).json({ error: 'Authentication required' });
        }
        
        // Check permission cache
        const cacheKey = `permissions:${user.id}`;
        let userPermissions = await this.redis.get(cacheKey);
        
        if (!userPermissions) {
          userPermissions = await this.loadUserPermissions(user.id);
          await this.redis.setex(cacheKey, 300, JSON.stringify(userPermissions));
        } else {
          userPermissions = JSON.parse(userPermissions);
        }
        
        if (this.hasPermission(userPermissions, permission)) {
          next();
        } else {
          res.status(403).json({ 
            error: 'Insufficient permissions',
            required: permission 
          });
        }
      } catch (error) {
        console.error('Permission check error:', error);
        res.status(500).json({ error: 'Internal server error' });
      }
    };
  }
  
  // Check multiple permissions (AND)
  requireAllPermissions(...permissions: string[]) {
    return async (req: Request, res: Response, next: NextFunction) => {
      try {
        const user = req.user;
        if (!user) {
          return res.status(401).json({ error: 'Authentication required' });
        }
        
        const userPermissions = await this.getUserPermissions(user.id);
        const hasAll = permissions.every(p => 
          this.hasPermission(userPermissions, p)
        );
        
        if (hasAll) {
          next();
        } else {
          res.status(403).json({ 
            error: 'Insufficient permissions',
            required: permissions 
          });
        }
      } catch (error) {
        console.error('Permission check error:', error);
        res.status(500).json({ error: 'Internal server error' });
      }
    };
  }
  
  // Check multiple permissions (OR)
  requireAnyPermission(...permissions: string[]) {
    return async (req: Request, res: Response, next: NextFunction) => {
      try {
        const user = req.user;
        if (!user) {
          return res.status(401).json({ error: 'Authentication required' });
        }
        
        const userPermissions = await this.getUserPermissions(user.id);
        const hasAny = permissions.some(p => 
          this.hasPermission(userPermissions, p)
        );
        
        if (hasAny) {
          next();
        } else {
          res.status(403).json({ 
            error: 'Insufficient permissions',
            required: permissions,
            requiresAny: true
          });
        }
      } catch (error) {
        console.error('Permission check error:', error);
        res.status(500).json({ error: 'Internal server error' });
      }
    };
  }
  
  // Resource-based permission check
  requireResourcePermission(
    resourceType: string,
    action: string,
    getResourceId?: (req: Request) => string
  ) {
    return async (req: Request, res: Response, next: NextFunction) => {
      try {
        const user = req.user;
        if (!user) {
          return res.status(401).json({ error: 'Authentication required' });
        }
        
        const resourceId = getResourceId ? getResourceId(req) : req.params.id;
        const permission = `${resourceType}:${action}`;
        
        // Check basic permission
        const hasBasicPermission = await this.checkPermission(user.id, permission);
        if (!hasBasicPermission) {
          return res.status(403).json({ 
            error: 'Insufficient permissions',
            required: permission 
          });
        }
        
        // Check resource-specific policies
        const resource = await this.loadResource(resourceType, resourceId);
        if (!resource) {
          return res.status(404).json({ error: 'Resource not found' });
        }
        
        const canAccess = await this.evaluatePolicies(
          user,
          resource,
          action
        );
        
        if (canAccess) {
          req.resource = resource;
          next();
        } else {
          res.status(403).json({ 
            error: 'Access denied by policy',
            resource: resourceType,
            action 
          });
        }
      } catch (error) {
        console.error('Resource permission check error:', error);
        res.status(500).json({ error: 'Internal server error' });
      }
    };
  }
  
  // Field-level security
  filterFields(fields: string[]) {
    return async (req: Request, res: Response, next: NextFunction) => {
      const user = req.user;
      if (!user) {
        return next();
      }
      
      // Store original send function
      const originalSend = res.send;
      
      // Override send function
      res.send = function(data: any) {
        if (typeof data === 'object' && data !== null) {
          const filtered = filterObjectFields(
            data,
            fields,
            user.permissions
          );
          return originalSend.call(this, filtered);
        }
        return originalSend.call(this, data);
      };
      
      next();
    };
  }
  
  private hasPermission(userPermissions: string[], required: string): boolean {
    // Check for wildcard permission
    if (userPermissions.includes('*')) return true;
    
    // Check exact match
    if (userPermissions.includes(required)) return true;
    
    // Check wildcard patterns
    const parts = required.split(':');
    for (let i = parts.length - 1; i > 0; i--) {
      const pattern = parts.slice(0, i).join(':') + ':*';
      if (userPermissions.includes(pattern)) return true;
    }
    
    return false;
  }
  
  private async evaluatePolicies(
    user: User,
    resource: any,
    action: string
  ): Promise<boolean> {
    const policies = await this.loadPolicies(resource._type, action);
    
    // Sort by priority
    policies.sort((a, b) => (b.priority || 0) - (a.priority || 0));
    
    for (const policy of policies) {
      const result = await this.evaluatePolicy(policy, user, resource, action);
      
      if (result === 'deny') return false;
      if (result === 'allow') return true;
    }
    
    // Default deny
    return false;
  }
  
  private async evaluatePolicy(
    policy: Policy,
    user: User,
    resource: any,
    action: string
  ): Promise<'allow' | 'deny' | 'skip'> {
    // Check if policy applies
    if (!this.policyApplies(policy, resource._type, action)) {
      return 'skip';
    }
    
    // Evaluate conditions
    const conditionsMet = await this.evaluateConditions(
      policy.conditions,
      user,
      resource
    );
    
    if (conditionsMet) {
      return policy.effect;
    }
    
    return 'skip';
  }
}

// Role-based access control
export class RBACService {
  constructor(
    private db: Database,
    private cache: Cache
  ) {}
  
  async createRole(role: RoleCreateDto): Promise<Role> {
    // Validate permissions exist
    const validPermissions = await this.validatePermissions(role.permissions);
    
    const newRole = await this.db.roles.create({
      ...role,
      permissions: validPermissions,
      createdAt: new Date(),
      updatedAt: new Date()
    });
    
    // Clear cache
    await this.cache.del('roles:*');
    
    return newRole;
  }
  
  async assignRole(userId: string, roleId: string): Promise<void> {
    // Check if role exists
    const role = await this.getRole(roleId);
    if (!role) {
      throw new Error('Role not found');
    }
    
    // Assign role
    await this.db.userRoles.create({
      userId,
      roleId,
      assignedAt: new Date()
    });
    
    // Clear user permission cache
    await this.cache.del(`permissions:${userId}`);
  }
  
  async getUserPermissions(userId: string): Promise<string[]> {
    // Check cache
    const cached = await this.cache.get(`permissions:${userId}`);
    if (cached) {
      return JSON.parse(cached);
    }
    
    // Load user roles
    const userRoles = await this.db.userRoles.findAll({
      where: { userId },
      include: [{
        model: this.db.roles,
        include: [this.db.permissions]
      }]
    });
    
    // Aggregate permissions
    const permissions = new Set<string>();
    
    for (const userRole of userRoles) {
      const role = userRole.role;
      
      // Add role permissions
      for (const permission of role.permissions) {
        permissions.add(permission);
      }
      
      // Handle permission inheritance
      if (role.inherits) {
        const inheritedPermissions = await this.getRolePermissions(role.inherits);
        inheritedPermissions.forEach(p => permissions.add(p));
      }
    }
    
    // Add user-specific permissions
    const userPermissions = await this.db.userPermissions.findAll({
      where: { userId }
    });
    
    userPermissions.forEach(up => permissions.add(up.permission));
    
    const permissionArray = Array.from(permissions);
    
    // Cache for 5 minutes
    await this.cache.setex(
      `permissions:${userId}`,
      300,
      JSON.stringify(permissionArray)
    );
    
    return permissionArray;
  }
  
  async checkPermission(
    userId: string,
    permission: string,
    context?: any
  ): Promise<boolean> {
    const userPermissions = await this.getUserPermissions(userId);
    
    // Check direct permission
    if (this.hasPermission(userPermissions, permission)) {
      return true;
    }
    
    // Check dynamic permissions
    if (context) {
      return this.checkDynamicPermission(userId, permission, context);
    }
    
    return false;
  }
  
  private async checkDynamicPermission(
    userId: string,
    permission: string,
    context: any
  ): Promise<boolean> {
    // Example: Check if user owns the resource
    if (context.ownerId === userId) {
      const ownerPermissions = ['read', 'update', 'delete'];
      const requestedAction = permission.split(':')[1];
      if (ownerPermissions.includes(requestedAction)) {
        return true;
      }
    }
    
    // Example: Check department-based access
    if (context.departmentId) {
      const user = await this.db.users.findByPk(userId);
      if (user.departmentId === context.departmentId) {
        return true;
      }
    }
    
    return false;
  }
}
```

### React Permission Components
```tsx
import React, { createContext, useContext, useState, useEffect } from 'react';
import { User, Permission, Role } from '@/types/auth';

interface AuthContextValue {
  user: User | null;
  permissions: string[];
  roles: Role[];
  hasPermission: (permission: string) => boolean;
  hasAnyPermission: (...permissions: string[]) => boolean;
  hasAllPermissions: (...permissions: string[]) => boolean;
  hasRole: (role: string) => boolean;
  can: (action: string, resource: string, context?: any) => boolean;
  loading: boolean;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ 
  children 
}) => {
  const [user, setUser] = useState<User | null>(null);
  const [permissions, setPermissions] = useState<string[]>([]);
  const [roles, setRoles] = useState<Role[]>([]);
  const [loading, setLoading] = useState(true);
  
  useEffect(() => {
    loadUserData();
  }, []);
  
  const loadUserData = async () => {
    try {
      const response = await api.get('/auth/me');
      const userData = response.data;
      
      setUser(userData.user);
      setPermissions(userData.permissions);
      setRoles(userData.roles);
    } catch (error) {
      console.error('Failed to load user data:', error);
    } finally {
      setLoading(false);
    }
  };
  
  const hasPermission = (permission: string): boolean => {
    // Super admin has all permissions
    if (permissions.includes('*')) return true;
    
    // Check exact match
    if (permissions.includes(permission)) return true;
    
    // Check wildcard patterns
    const parts = permission.split(':');
    for (let i = parts.length - 1; i > 0; i--) {
      const pattern = parts.slice(0, i).join(':') + ':*';
      if (permissions.includes(pattern)) return true;
    }
    
    return false;
  };
  
  const hasAnyPermission = (...perms: string[]): boolean => {
    return perms.some(p => hasPermission(p));
  };
  
  const hasAllPermissions = (...perms: string[]): boolean => {
    return perms.every(p => hasPermission(p));
  };
  
  const hasRole = (role: string): boolean => {
    return roles.some(r => r.id === role || r.name === role);
  };
  
  const can = (action: string, resource: string, context?: any): boolean => {
    // Check basic permission
    const permission = `${resource}:${action}`;
    if (!hasPermission(permission)) return false;
    
    // Check context-based permissions
    if (context) {
      // Owner check
      if (context.ownerId && user?.id === context.ownerId) {
        return ['read', 'update', 'delete'].includes(action);
      }
      
      // Department check
      if (context.departmentId && user?.departmentId === context.departmentId) {
        return true;
      }
    }
    
    return true;
  };
  
  return (
    <AuthContext.Provider
      value={{
        user,
        permissions,
        roles,
        hasPermission,
        hasAnyPermission,
        hasAllPermissions,
        hasRole,
        can,
        loading
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
};

// Permission guard component
export const PermissionGuard: React.FC<{
  permission?: string;
  permissions?: string[];
  requireAll?: boolean;
  fallback?: React.ReactNode;
  children: React.ReactNode;
}> = ({ 
  permission, 
  permissions, 
  requireAll = false, 
  fallback = null, 
  children 
}) => {
  const { hasPermission, hasAnyPermission, hasAllPermissions } = useAuth();
  
  let hasAccess = false;
  
  if (permission) {
    hasAccess = hasPermission(permission);
  } else if (permissions) {
    hasAccess = requireAll 
      ? hasAllPermissions(...permissions)
      : hasAnyPermission(...permissions);
  }
  
  return hasAccess ? <>{children}</> : <>{fallback}</>;
};

// Can component for inline permission checks
export const Can: React.FC<{
  do: string;
  on: string;
  context?: any;
  fallback?: React.ReactNode;
  children: React.ReactNode;
}> = ({ do: action, on: resource, context, fallback = null, children }) => {
  const { can } = useAuth();
  
  return can(action, resource, context) ? <>{children}</> : <>{fallback}</>;
};

// Role guard component
export const RoleGuard: React.FC<{
  role?: string;
  roles?: string[];
  requireAll?: boolean;
  fallback?: React.ReactNode;
  children: React.ReactNode;
}> = ({ role, roles, requireAll = false, fallback = null, children }) => {
  const { hasRole } = useAuth();
  
  let hasAccess = false;
  
  if (role) {
    hasAccess = hasRole(role);
  } else if (roles) {
    hasAccess = requireAll
      ? roles.every(r => hasRole(r))
      : roles.some(r => hasRole(r));
  }
  
  return hasAccess ? <>{children}</> : <>{fallback}</>;
};

// Hook for permission-based rendering
export const usePermissions = () => {
  const auth = useAuth();
  
  return {
    can: auth.can,
    cannot: (action: string, resource: string, context?: any) => 
      !auth.can(action, resource, context),
    hasPermission: auth.hasPermission,
    hasRole: auth.hasRole,
    isAuthenticated: !!auth.user,
    isSuperAdmin: auth.hasPermission('*'),
    filterByPermission: <T extends { permission?: string }>(
      items: T[]
    ): T[] => {
      return items.filter(item => 
        !item.permission || auth.hasPermission(item.permission)
      );
    }
  };
};

// Field-level security component
export const SecureField: React.FC<{
  permission: string;
  fallback?: React.ReactNode;
  mask?: boolean;
  children: React.ReactNode;
}> = ({ permission, fallback = '***', mask = false, children }) => {
  const { hasPermission } = useAuth();
  
  if (!hasPermission(permission)) {
    return <>{fallback}</>;
  }
  
  if (mask) {
    return <span className="secure-field masked">{children}</span>;
  }
  
  return <>{children}</>;
};

// Usage examples
export const ExampleUsage: React.FC = () => {
  const { can } = usePermissions();
  
  return (
    <div>
      {/* Permission-based rendering */}
      <PermissionGuard permission="users:create">
        <Button>Create User</Button>
      </PermissionGuard>
      
      {/* Multiple permissions (OR) */}
      <PermissionGuard permissions={['users:update', 'users:manage']}>
        <Button>Edit User</Button>
      </PermissionGuard>
      
      {/* Multiple permissions (AND) */}
      <PermissionGuard 
        permissions={['users:read', 'users:export']} 
        requireAll
      >
        <Button>Export Users</Button>
      </PermissionGuard>
      
      {/* Resource-based permissions */}
      <Can do="update" on="user" context={{ ownerId: user.id }}>
        <Button>Edit Profile</Button>
      </Can>
      
      {/* Role-based rendering */}
      <RoleGuard role="admin">
        <AdminPanel />
      </RoleGuard>
      
      {/* Field-level security */}
      <div>
        Email: <SecureField permission="users:email:read">
          {user.email}
        </SecureField>
      </div>
      
      {/* Programmatic check */}
      {can('delete', 'user', { id: userId }) && (
        <Button onClick={handleDelete}>Delete</Button>
      )}
    </div>
  );
};
```

### Vue.js Permission System
```vue
<template>
  <div>
    <slot />
  </div>
</template>

<script setup lang="ts">
import { provide, reactive, computed } from 'vue';
import type { User, Permission, Role } from '@/types/auth';

// Permission state
const state = reactive({
  user: null as User | null,
  permissions: [] as string[],
  roles: [] as Role[],
  loading: true
});

// Load user data
async function loadUserData() {
  try {
    const { data } = await api.get('/auth/me');
    state.user = data.user;
    state.permissions = data.permissions;
    state.roles = data.roles;
  } catch (error) {
    console.error('Failed to load user data:', error);
  } finally {
    state.loading = false;
  }
}

// Permission checking functions
function hasPermission(permission: string): boolean {
  // Super admin has all permissions
  if (state.permissions.includes('*')) return true;
  
  // Check exact match
  if (state.permissions.includes(permission)) return true;
  
  // Check wildcard patterns
  const parts = permission.split(':');
  for (let i = parts.length - 1; i > 0; i--) {
    const pattern = parts.slice(0, i).join(':') + ':*';
    if (state.permissions.includes(pattern)) return true;
  }
  
  return false;
}

function hasAnyPermission(...permissions: string[]): boolean {
  return permissions.some(p => hasPermission(p));
}

function hasAllPermissions(...permissions: string[]): boolean {
  return permissions.every(p => hasPermission(p));
}

function hasRole(role: string): boolean {
  return state.roles.some(r => r.id === role || r.name === role);
}

function can(action: string, resource: string, context?: any): boolean {
  // Check basic permission
  const permission = `${resource}:${action}`;
  if (!hasPermission(permission)) return false;
  
  // Check context-based permissions
  if (context && state.user) {
    // Owner check
    if (context.ownerId && state.user.id === context.ownerId) {
      return ['read', 'update', 'delete'].includes(action);
    }
    
    // Department check
    if (context.departmentId && state.user.departmentId === context.departmentId) {
      return true;
    }
  }
  
  return true;
}

// Provide auth functions
provide('auth', {
  user: computed(() => state.user),
  permissions: computed(() => state.permissions),
  roles: computed(() => state.roles),
  loading: computed(() => state.loading),
  hasPermission,
  hasAnyPermission,
  hasAllPermissions,
  hasRole,
  can
});

// Load on mount
loadUserData();
</script>

<!-- Permission directive -->
<script lang="ts">
import { Directive } from 'vue';

export const vPermission: Directive = {
  mounted(el, binding) {
    const { hasPermission } = useAuth();
    const permission = binding.value;
    
    if (!hasPermission(permission)) {
      el.style.display = 'none';
    }
  },
  updated(el, binding) {
    const { hasPermission } = useAuth();
    const permission = binding.value;
    
    if (!hasPermission(permission)) {
      el.style.display = 'none';
    } else {
      el.style.display = '';
    }
  }
};

export const vRole: Directive = {
  mounted(el, binding) {
    const { hasRole } = useAuth();
    const role = binding.value;
    
    if (!hasRole(role)) {
      el.style.display = 'none';
    }
  },
  updated(el, binding) {
    const { hasRole } = useAuth();
    const role = binding.value;
    
    if (!hasRole(role)) {
      el.style.display = 'none';
    } else {
      el.style.display = '';
    }
  }
};
</script>

<!-- Permission components -->
<template>
  <div v-if="hasAccess">
    <slot />
  </div>
  <div v-else-if="$slots.fallback">
    <slot name="fallback" />
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { useAuth } from '@/composables/useAuth';

interface Props {
  permission?: string;
  permissions?: string[];
  requireAll?: boolean;
  role?: string;
  roles?: string[];
}

const props = withDefaults(defineProps<Props>(), {
  requireAll: false
});

const { hasPermission, hasAnyPermission, hasAllPermissions, hasRole } = useAuth();

const hasAccess = computed(() => {
  if (props.permission) {
    return hasPermission(props.permission);
  }
  
  if (props.permissions) {
    return props.requireAll
      ? hasAllPermissions(...props.permissions)
      : hasAnyPermission(...props.permissions);
  }
  
  if (props.role) {
    return hasRole(props.role);
  }
  
  if (props.roles) {
    return props.requireAll
      ? props.roles.every(r => hasRole(r))
      : props.roles.some(r => hasRole(r));
  }
  
  return true;
});
</script>

<!-- Can component -->
<template>
  <div v-if="canPerform">
    <slot />
  </div>
  <div v-else-if="$slots.fallback">
    <slot name="fallback" />
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { useAuth } from '@/composables/useAuth';

interface Props {
  do: string;
  on: string;
  context?: any;
}

const props = defineProps<Props>();
const { can } = useAuth();

const canPerform = computed(() => 
  can(props.do, props.on, props.context)
);
</script>

<!-- Usage examples -->
<template>
  <div>
    <!-- Permission-based rendering -->
    <PermissionGuard permission="users:create">
      <button>Create User</button>
    </PermissionGuard>
    
    <!-- Multiple permissions -->
    <PermissionGuard 
      :permissions="['users:update', 'users:manage']"
      :require-all="false"
    >
      <button>Edit User</button>
    </PermissionGuard>
    
    <!-- Resource-based permissions -->
    <Can do="update" on="user" :context="{ ownerId: user.id }">
      <button>Edit Profile</button>
    </Can>
    
    <!-- Role-based rendering -->
    <PermissionGuard role="admin">
      <AdminPanel />
    </PermissionGuard>
    
    <!-- Using directives -->
    <button v-permission="'users:delete'">Delete User</button>
    <div v-role="'admin'">Admin Section</div>
    
    <!-- Field-level security -->
    <SecureField permission="users:email:read" mask>
      {{ user.email }}
    </SecureField>
  </div>
</template>
```

### Access Control Configuration
```typescript
// Access control configuration schema
export interface AccessControlConfig {
  // Authentication settings
  authentication: {
    providers: AuthProvider[];
    sessionTimeout: number;
    requireMFA: boolean;
    passwordPolicy: PasswordPolicy;
  };
  
  // Authorization settings
  authorization: {
    model: 'RBAC' | 'ABAC' | 'HYBRID';
    defaultRole: string;
    guestPermissions: string[];
    cacheTimeout: number;
  };
  
  // Security policies
  policies: {
    ipWhitelist?: string[];
    ipBlacklist?: string[];
    rateLimit: RateLimitConfig;
    corsOrigins: string[];
    trustedProxies: string[];
  };
  
  // Audit settings
  audit: {
    enabled: boolean;
    events: AuditEvent[];
    retention: number;
    storage: 'database' | 'file' | 's3';
  };
}

// Default secure configuration
export const defaultAccessControlConfig: AccessControlConfig = {
  authentication: {
    providers: ['local', 'oauth2'],
    sessionTimeout: 3600, // 1 hour
    requireMFA: false,
    passwordPolicy: {
      minLength: 8,
      requireUppercase: true,
      requireLowercase: true,
      requireNumbers: true,
      requireSpecialChars: true,
      preventReuse: 5,
      maxAge: 90 // days
    }
  },
  
  authorization: {
    model: 'RBAC',
    defaultRole: 'viewer',
    guestPermissions: ['public:read'],
    cacheTimeout: 300 // 5 minutes
  },
  
  policies: {
    rateLimit: {
      windowMs: 15 * 60 * 1000, // 15 minutes
      max: 100,
      message: 'Too many requests from this IP'
    },
    corsOrigins: ['http://localhost:3000'],
    trustedProxies: ['127.0.0.1']
  },
  
  audit: {
    enabled: true,
    events: [
      'auth.login',
      'auth.logout',
      'auth.failed',
      'permission.granted',
      'permission.denied',
      'data.create',
      'data.update',
      'data.delete',
      'admin.action'
    ],
    retention: 90, // days
    storage: 'database'
  }
};
```

## Integration Points
- Receives user/role schemas from Schema Analyzer
- Provides middleware to API Generator
- Coordinates with Audit Logger for tracking
- Integrates with Auth Builder for authentication
- Works with Vulnerability Scanner for security

## Best Practices
1. Implement principle of least privilege
2. Use role inheritance to reduce complexity
3. Cache permissions for performance
4. Audit all permission changes
5. Implement break-glass procedures
6. Regular permission reviews
7. Separate authentication from authorization
8. Use secure session management
9. Implement proper CORS policies
10. Monitor for privilege escalation attempts