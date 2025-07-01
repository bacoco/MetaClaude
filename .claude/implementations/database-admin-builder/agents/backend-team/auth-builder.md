# Auth Builder Agent

## Purpose
Implements comprehensive authentication and authorization systems with enterprise-grade security features for admin panels.

## Capabilities

### Authentication Methods
- JWT (JSON Web Tokens)
- OAuth 2.0 / OpenID Connect
- SAML 2.0
- Session-based auth
- API key authentication
- Multi-factor authentication (2FA/MFA)
- Biometric authentication
- Social login integration

### Authorization Features
- Role-Based Access Control (RBAC)
- Attribute-Based Access Control (ABAC)
- Resource-level permissions
- Dynamic permission evaluation
- Hierarchical roles
- Permission inheritance
- Time-based access
- IP whitelisting

## Authentication Implementation

### JWT Authentication System
```javascript
// JWT configuration and implementation
const authConfig = {
  jwt: {
    secret: process.env.JWT_SECRET,
    accessTokenExpiry: '15m',
    refreshTokenExpiry: '7d',
    issuer: 'admin-panel',
    audience: 'admin-users'
  },
  bcrypt: {
    rounds: 12
  },
  session: {
    maxAge: 3600000, // 1 hour
    secure: true,
    httpOnly: true,
    sameSite: 'strict'
  }
};

// User authentication service
class AuthService {
  async login(email, password, ip, userAgent) {
    const user = await User.query()
      .findOne({ email })
      .withGraphFetched('roles.permissions');
    
    if (!user || !await bcrypt.compare(password, user.passwordHash)) {
      await this.logFailedAttempt(email, ip);
      throw new UnauthorizedError('Invalid credentials');
    }
    
    if (user.lockedUntil > new Date()) {
      throw new ForbiddenError('Account temporarily locked');
    }
    
    // Generate tokens
    const accessToken = this.generateAccessToken(user);
    const refreshToken = await this.generateRefreshToken(user);
    
    // Log successful login
    await AuditLog.create({
      userId: user.id,
      action: 'LOGIN',
      ip,
      userAgent,
      timestamp: new Date()
    });
    
    // Update last login
    await user.$query().patch({
      lastLoginAt: new Date(),
      lastLoginIp: ip
    });
    
    return {
      accessToken,
      refreshToken,
      user: this.sanitizeUser(user)
    };
  }
  
  generateAccessToken(user) {
    const permissions = this.extractPermissions(user.roles);
    
    return jwt.sign(
      {
        sub: user.id,
        email: user.email,
        roles: user.roles.map(r => r.name),
        permissions,
        type: 'access'
      },
      authConfig.jwt.secret,
      {
        expiresIn: authConfig.jwt.accessTokenExpiry,
        issuer: authConfig.jwt.issuer,
        audience: authConfig.jwt.audience
      }
    );
  }
  
  async generateRefreshToken(user) {
    const token = crypto.randomBytes(32).toString('hex');
    const hashedToken = await bcrypt.hash(token, 6);
    
    await RefreshToken.query().insert({
      userId: user.id,
      tokenHash: hashedToken,
      expiresAt: addDays(new Date(), 7),
      family: uuid() // Token family for rotation
    });
    
    return token;
  }
}
```

### Multi-Factor Authentication
```javascript
// 2FA implementation with TOTP
class MFAService {
  async setupMFA(userId) {
    const secret = speakeasy.generateSecret({
      name: `AdminPanel (${user.email})`,
      issuer: 'AdminPanel'
    });
    
    await User.query()
      .findById(userId)
      .patch({
        mfaSecret: this.encrypt(secret.base32),
        mfaEnabled: false
      });
    
    return {
      secret: secret.base32,
      qrCode: await QRCode.toDataURL(secret.otpauth_url),
      backupCodes: await this.generateBackupCodes(userId)
    };
  }
  
  async verifyMFA(userId, token) {
    const user = await User.query().findById(userId);
    const secret = this.decrypt(user.mfaSecret);
    
    const verified = speakeasy.totp.verify({
      secret,
      encoding: 'base32',
      token,
      window: 2 // Allow 2 time steps tolerance
    });
    
    if (!verified) {
      // Check backup codes
      return await this.verifyBackupCode(userId, token);
    }
    
    return verified;
  }
}
```

## Authorization System

### RBAC Implementation
```javascript
// Role and permission structure
const rolePermissionSchema = {
  roles: [
    {
      name: 'super_admin',
      description: 'Full system access',
      permissions: ['*']
    },
    {
      name: 'admin',
      description: 'Administrative access',
      permissions: [
        'users:*',
        'products:*',
        'orders:*',
        'reports:view'
      ]
    },
    {
      name: 'manager',
      description: 'Management access',
      permissions: [
        'products:read',
        'products:update',
        'orders:*',
        'reports:view'
      ]
    },
    {
      name: 'operator',
      description: 'Basic operations',
      permissions: [
        'products:read',
        'orders:read',
        'orders:update'
      ]
    }
  ]
};

// Permission middleware
const authorize = (requiredPermission) => {
  return async (req, res, next) => {
    const user = req.user;
    
    if (!user) {
      return res.status(401).json({ error: 'Unauthorized' });
    }
    
    // Super admin bypass
    if (user.permissions.includes('*')) {
      return next();
    }
    
    // Check specific permission
    const hasPermission = this.checkPermission(
      user.permissions,
      requiredPermission
    );
    
    if (!hasPermission) {
      await AuditLog.create({
        userId: user.id,
        action: 'PERMISSION_DENIED',
        resource: requiredPermission,
        ip: req.ip
      });
      
      return res.status(403).json({ 
        error: 'Insufficient permissions',
        required: requiredPermission
      });
    }
    
    next();
  };
};

// Dynamic permission checking
checkPermission(userPermissions, required) {
  // Direct match
  if (userPermissions.includes(required)) {
    return true;
  }
  
  // Wildcard match (e.g., 'products:*' matches 'products:read')
  const [resource, action] = required.split(':');
  if (userPermissions.includes(`${resource}:*`)) {
    return true;
  }
  
  // Hierarchical match
  const hierarchy = {
    'write': ['read'],
    'delete': ['write', 'read'],
    'admin': ['delete', 'write', 'read']
  };
  
  for (const perm of userPermissions) {
    const [permResource, permAction] = perm.split(':');
    if (permResource === resource && 
        hierarchy[permAction]?.includes(action)) {
      return true;
    }
  }
  
  return false;
}
```

### Resource-Level Security
```javascript
// Row-level security implementation
class ResourceAuthService {
  async canAccessResource(user, resourceType, resourceId, action) {
    // Check basic permission first
    if (!this.hasPermission(user, `${resourceType}:${action}`)) {
      return false;
    }
    
    // Check resource-specific rules
    const rules = await ResourceRule.query()
      .where('resource_type', resourceType)
      .where('resource_id', resourceId);
    
    for (const rule of rules) {
      if (!await this.evaluateRule(rule, user, resourceId)) {
        return false;
      }
    }
    
    // Check ownership
    if (await this.requiresOwnership(resourceType, action)) {
      return await this.isOwner(user, resourceType, resourceId);
    }
    
    return true;
  }
  
  async createResourcePolicy(resource) {
    return {
      type: 'resource_policy',
      resource: {
        type: resource.type,
        id: resource.id
      },
      rules: [
        {
          effect: 'ALLOW',
          principals: ['role:admin'],
          actions: ['*']
        },
        {
          effect: 'ALLOW',
          principals: [`user:${resource.ownerId}`],
          actions: ['read', 'update']
        },
        {
          effect: 'DENY',
          principals: ['*'],
          actions: ['delete'],
          conditions: {
            'resource.status': 'archived'
          }
        }
      ]
    };
  }
}
```

## OAuth 2.0 Integration
```javascript
// OAuth provider configuration
const oauthProviders = {
  google: {
    clientId: process.env.GOOGLE_CLIENT_ID,
    clientSecret: process.env.GOOGLE_CLIENT_SECRET,
    redirectUri: '/auth/google/callback',
    scope: ['profile', 'email'],
    authorizationUrl: 'https://accounts.google.com/o/oauth2/v2/auth',
    tokenUrl: 'https://oauth2.googleapis.com/token',
    userInfoUrl: 'https://www.googleapis.com/oauth2/v1/userinfo'
  },
  github: {
    clientId: process.env.GITHUB_CLIENT_ID,
    clientSecret: process.env.GITHUB_CLIENT_SECRET,
    redirectUri: '/auth/github/callback',
    scope: ['user:email'],
    authorizationUrl: 'https://github.com/login/oauth/authorize',
    tokenUrl: 'https://github.com/login/oauth/access_token',
    userInfoUrl: 'https://api.github.com/user'
  }
};

// OAuth flow implementation
router.get('/auth/:provider', (req, res) => {
  const provider = oauthProviders[req.params.provider];
  const state = generateSecureToken();
  
  req.session.oauthState = state;
  
  const authUrl = new URL(provider.authorizationUrl);
  authUrl.searchParams.append('client_id', provider.clientId);
  authUrl.searchParams.append('redirect_uri', provider.redirectUri);
  authUrl.searchParams.append('scope', provider.scope.join(' '));
  authUrl.searchParams.append('state', state);
  authUrl.searchParams.append('response_type', 'code');
  
  res.redirect(authUrl.toString());
});
```

## Session Management
```javascript
// Secure session configuration
app.use(session({
  store: new RedisStore({ client: redisClient }),
  secret: process.env.SESSION_SECRET,
  resave: false,
  saveUninitialized: false,
  rolling: true,
  cookie: {
    secure: process.env.NODE_ENV === 'production',
    httpOnly: true,
    maxAge: 3600000, // 1 hour
    sameSite: 'strict'
  }
}));

// Session-based auth middleware
const requireSession = async (req, res, next) => {
  if (!req.session.userId) {
    return res.status(401).json({ error: 'Authentication required' });
  }
  
  const user = await User.query()
    .findById(req.session.userId)
    .withGraphFetched('roles.permissions');
  
  if (!user) {
    req.session.destroy();
    return res.status(401).json({ error: 'Session invalid' });
  }
  
  req.user = user;
  next();
};
```

## Integration Points
- Works with API Generator for endpoint security
- Coordinates with Audit Logger for tracking
- Integrates with Access Control Manager
- Connects with Encryption Specialist

## Best Practices
1. Always use HTTPS in production
2. Implement rate limiting for auth endpoints
3. Use secure password policies
4. Log all authentication events
5. Implement account lockout mechanisms
6. Rotate tokens and secrets regularly
7. Use constant-time comparisons