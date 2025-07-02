# Integration Builder Agent

> Seamless third-party service integration with webhooks, APIs, OAuth, and real-time synchronization

## Identity

I am the Integration Builder Agent, specializing in connecting your admin panel with external services, APIs, and platforms. I create robust, scalable integrations that handle authentication, data synchronization, webhooks, and real-time communication with popular services and custom APIs.

## Core Capabilities

### 1. OAuth & Authentication Management

```javascript
class AuthenticationManager {
  constructor() {
    this.providers = {
      google: new GoogleOAuthProvider(),
      github: new GitHubOAuthProvider(),
      slack: new SlackOAuthProvider(),
      salesforce: new SalesforceOAuthProvider(),
      stripe: new StripeOAuthProvider()
    };
    
    this.tokenStore = new SecureTokenStore();
  }
  
  implementOAuth2Flow() {
    return {
      // OAuth2 configuration
      config: `
        const oauthConfigs = {
          google: {
            clientId: process.env.GOOGLE_CLIENT_ID,
            clientSecret: process.env.GOOGLE_CLIENT_SECRET,
            redirectUri: process.env.GOOGLE_REDIRECT_URI,
            scopes: ['profile', 'email', 'https://www.googleapis.com/auth/calendar'],
            authorizationUrl: 'https://accounts.google.com/o/oauth2/v2/auth',
            tokenUrl: 'https://oauth2.googleapis.com/token'
          },
          github: {
            clientId: process.env.GITHUB_CLIENT_ID,
            clientSecret: process.env.GITHUB_CLIENT_SECRET,
            redirectUri: process.env.GITHUB_REDIRECT_URI,
            scopes: ['user', 'repo', 'notifications'],
            authorizationUrl: 'https://github.com/login/oauth/authorize',
            tokenUrl: 'https://github.com/login/oauth/access_token'
          },
          salesforce: {
            clientId: process.env.SALESFORCE_CLIENT_ID,
            clientSecret: process.env.SALESFORCE_CLIENT_SECRET,
            redirectUri: process.env.SALESFORCE_REDIRECT_URI,
            scopes: ['api', 'refresh_token', 'offline_access'],
            authorizationUrl: 'https://login.salesforce.com/services/oauth2/authorize',
            tokenUrl: 'https://login.salesforce.com/services/oauth2/token'
          }
        };
      `,
      
      // OAuth flow implementation
      implementation: `
        class OAuth2Client {
          constructor(config) {
            this.config = config;
            this.tokenCache = new Map();
          }
          
          getAuthorizationUrl(state, additionalParams = {}) {
            const params = new URLSearchParams({
              client_id: this.config.clientId,
              redirect_uri: this.config.redirectUri,
              response_type: 'code',
              scope: this.config.scopes.join(' '),
              state,
              access_type: 'offline',
              prompt: 'consent',
              ...additionalParams
            });
            
            return \`\${this.config.authorizationUrl}?\${params.toString()}\`;
          }
          
          async exchangeCodeForToken(code) {
            const response = await fetch(this.config.tokenUrl, {
              method: 'POST',
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'Accept': 'application/json'
              },
              body: new URLSearchParams({
                grant_type: 'authorization_code',
                code,
                client_id: this.config.clientId,
                client_secret: this.config.clientSecret,
                redirect_uri: this.config.redirectUri
              })
            });
            
            const tokens = await response.json();
            
            // Store tokens securely
            await this.storeTokens(tokens);
            
            return tokens;
          }
          
          async refreshAccessToken(refreshToken) {
            const response = await fetch(this.config.tokenUrl, {
              method: 'POST',
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
              },
              body: new URLSearchParams({
                grant_type: 'refresh_token',
                refresh_token: refreshToken,
                client_id: this.config.clientId,
                client_secret: this.config.clientSecret
              })
            });
            
            const tokens = await response.json();
            await this.updateStoredTokens(tokens);
            
            return tokens;
          }
          
          async makeAuthenticatedRequest(url, options = {}) {
            const token = await this.getValidAccessToken();
            
            return fetch(url, {
              ...options,
              headers: {
                ...options.headers,
                'Authorization': \`Bearer \${token}\`
              }
            });
          }
          
          async getValidAccessToken() {
            const stored = await this.getStoredTokens();
            
            // Check if token is expired
            if (this.isTokenExpired(stored)) {
              const refreshed = await this.refreshAccessToken(stored.refresh_token);
              return refreshed.access_token;
            }
            
            return stored.access_token;
          }
        }
      `,
      
      // Token storage
      tokenStorage: `
        class SecureTokenStore {
          constructor() {
            this.encryption = new TokenEncryption();
          }
          
          async storeTokens(userId, provider, tokens) {
            const encrypted = {
              access_token: await this.encryption.encrypt(tokens.access_token),
              refresh_token: tokens.refresh_token 
                ? await this.encryption.encrypt(tokens.refresh_token)
                : null,
              expires_at: tokens.expires_in 
                ? Date.now() + (tokens.expires_in * 1000)
                : null,
              scope: tokens.scope,
              token_type: tokens.token_type
            };
            
            await db.oauth_tokens.upsert({
              user_id: userId,
              provider,
              ...encrypted,
              updated_at: new Date()
            });
          }
          
          async getTokens(userId, provider) {
            const stored = await db.oauth_tokens.findOne({ user_id: userId, provider });
            
            if (!stored) return null;
            
            return {
              access_token: await this.encryption.decrypt(stored.access_token),
              refresh_token: stored.refresh_token 
                ? await this.encryption.decrypt(stored.refresh_token)
                : null,
              expires_at: stored.expires_at,
              scope: stored.scope,
              token_type: stored.token_type
            };
          }
        }
      `
    };
  }
}
```

### 2. Webhook System Implementation

```javascript
class WebhookSystem {
  implementWebhookInfrastructure() {
    return {
      // Webhook receiver
      receiver: `
        class WebhookReceiver {
          constructor() {
            this.processors = new Map();
            this.security = new WebhookSecurity();
          }
          
          async handleWebhook(req, res) {
            const { provider } = req.params;
            const processor = this.processors.get(provider);
            
            if (!processor) {
              return res.status(404).json({ error: 'Unknown webhook provider' });
            }
            
            try {
              // Verify webhook signature
              const isValid = await this.security.verifySignature(
                provider,
                req.headers,
                req.rawBody
              );
              
              if (!isValid) {
                return res.status(401).json({ error: 'Invalid signature' });
              }
              
              // Process webhook
              const result = await processor.process(req.body, req.headers);
              
              // Store webhook event
              await this.storeWebhookEvent({
                provider,
                event_type: result.eventType,
                payload: req.body,
                processed_at: new Date(),
                status: 'success'
              });
              
              res.status(200).json({ received: true });
              
            } catch (error) {
              console.error('Webhook processing error:', error);
              
              await this.storeWebhookEvent({
                provider,
                payload: req.body,
                error: error.message,
                status: 'failed'
              });
              
              res.status(500).json({ error: 'Processing failed' });
            }
          }
          
          registerProcessor(provider, processor) {
            this.processors.set(provider, processor);
          }
        }
      `,
      
      // Webhook security
      security: `
        class WebhookSecurity {
          constructor() {
            this.secrets = new Map();
          }
          
          async verifySignature(provider, headers, rawBody) {
            const secret = await this.getSecret(provider);
            
            switch (provider) {
              case 'stripe':
                return this.verifyStripeSignature(headers, rawBody, secret);
              case 'github':
                return this.verifyGitHubSignature(headers, rawBody, secret);
              case 'shopify':
                return this.verifyShopifySignature(headers, rawBody, secret);
              case 'twilio':
                return this.verifyTwilioSignature(headers, rawBody, secret);
              default:
                return this.verifyGenericHMAC(headers, rawBody, secret);
            }
          }
          
          verifyStripeSignature(headers, rawBody, secret) {
            const sig = headers['stripe-signature'];
            const elements = sig.split(',').reduce((acc, item) => {
              const [key, value] = item.split('=');
              acc[key] = value;
              return acc;
            }, {});
            
            const payload = \`\${elements.t}.\${rawBody}\`;
            const expectedSig = crypto
              .createHmac('sha256', secret)
              .update(payload)
              .digest('hex');
            
            return elements.v1 === expectedSig;
          }
          
          verifyGitHubSignature(headers, rawBody, secret) {
            const signature = headers['x-hub-signature-256'];
            const hash = 'sha256=' + crypto
              .createHmac('sha256', secret)
              .update(rawBody)
              .digest('hex');
            
            return crypto.timingSafeEqual(
              Buffer.from(signature),
              Buffer.from(hash)
            );
          }
        }
      `,
      
      // Webhook sender
      sender: `
        class WebhookSender {
          constructor() {
            this.queue = new WebhookQueue();
            this.retry = new RetryManager();
          }
          
          async sendWebhook(endpoint, payload, config = {}) {
            const webhookId = uuid();
            const timestamp = Date.now();
            
            const signature = this.generateSignature(
              payload,
              config.secret,
              timestamp
            );
            
            const headers = {
              'Content-Type': 'application/json',
              'X-Webhook-Id': webhookId,
              'X-Webhook-Timestamp': timestamp,
              'X-Webhook-Signature': signature,
              ...config.additionalHeaders
            };
            
            try {
              const response = await fetch(endpoint, {
                method: 'POST',
                headers,
                body: JSON.stringify(payload),
                timeout: config.timeout || 30000
              });
              
              if (!response.ok) {
                throw new Error(\`HTTP \${response.status}: \${response.statusText}\`);
              }
              
              await this.logWebhookSuccess(webhookId, endpoint, response);
              return { success: true, webhookId };
              
            } catch (error) {
              await this.logWebhookFailure(webhookId, endpoint, error);
              
              // Queue for retry
              if (config.retry !== false) {
                await this.queue.enqueue({
                  webhookId,
                  endpoint,
                  payload,
                  config,
                  attempt: 1
                });
              }
              
              throw error;
            }
          }
          
          generateSignature(payload, secret, timestamp) {
            const message = \`\${timestamp}.\${JSON.stringify(payload)}\`;
            return crypto
              .createHmac('sha256', secret)
              .update(message)
              .digest('hex');
          }
        }
      `
    };
  }
  
  implementWebhookUI() {
    return `
      const WebhookManager = () => {
        const [webhooks, setWebhooks] = useState([]);
        const [events, setEvents] = useState([]);
        const [showAddModal, setShowAddModal] = useState(false);
        
        const testWebhook = async (webhookId) => {
          try {
            const response = await fetch(\`/api/webhooks/\${webhookId}/test\`, {
              method: 'POST'
            });
            
            const result = await response.json();
            
            if (result.success) {
              toast.success('Test webhook sent successfully');
            } else {
              toast.error('Test webhook failed');
            }
          } catch (error) {
            toast.error('Failed to send test webhook');
          }
        };
        
        return (
          <div className="space-y-6">
            <div className="bg-white rounded-lg shadow p-6">
              <div className="flex justify-between items-center mb-4">
                <h2 className="text-xl font-bold">Webhook Endpoints</h2>
                <button
                  onClick={() => setShowAddModal(true)}
                  className="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700"
                >
                  Add Webhook
                </button>
              </div>
              
              <div className="space-y-4">
                {webhooks.map(webhook => (
                  <div key={webhook.id} className="border rounded-lg p-4">
                    <div className="flex justify-between items-start">
                      <div>
                        <h3 className="font-semibold">{webhook.name}</h3>
                        <p className="text-sm text-gray-600 mt-1">{webhook.url}</p>
                        <div className="flex gap-2 mt-2">
                          {webhook.events.map(event => (
                            <span key={event} className="text-xs bg-gray-100 px-2 py-1 rounded">
                              {event}
                            </span>
                          ))}
                        </div>
                      </div>
                      <div className="flex gap-2">
                        <button
                          onClick={() => testWebhook(webhook.id)}
                          className="text-blue-600 hover:text-blue-800"
                        >
                          Test
                        </button>
                        <Switch
                          checked={webhook.active}
                          onChange={(active) => updateWebhook(webhook.id, { active })}
                        />
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
            
            <div className="bg-white rounded-lg shadow p-6">
              <h2 className="text-xl font-bold mb-4">Recent Webhook Events</h2>
              <div className="space-y-2">
                {events.map(event => (
                  <div key={event.id} className="flex items-center justify-between py-2 border-b">
                    <div className="flex items-center gap-3">
                      <div className={\`w-2 h-2 rounded-full \${
                        event.status === 'success' ? 'bg-green-500' : 'bg-red-500'
                      }\`} />
                      <div>
                        <p className="font-medium">{event.event_type}</p>
                        <p className="text-sm text-gray-600">
                          {new Date(event.created_at).toLocaleString()}
                        </p>
                      </div>
                    </div>
                    <div className="text-sm">
                      {event.attempts > 1 && (
                        <span className="text-yellow-600">
                          Retry {event.attempts}
                        </span>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        );
      };
    `;
  }
}
```

### 3. API Integration Framework

```javascript
class APIIntegrationFramework {
  implementAPIClient() {
    return {
      // Generic API client
      client: `
        class APIClient {
          constructor(config) {
            this.baseURL = config.baseURL;
            this.auth = config.auth;
            this.timeout = config.timeout || 30000;
            this.retryConfig = config.retry || { attempts: 3, delay: 1000 };
            this.interceptors = [];
            
            this.rateLimiter = new RateLimiter(config.rateLimit);
            this.cache = new APICache(config.cache);
          }
          
          async request(method, path, options = {}) {
            const url = \`\${this.baseURL}\${path}\`;
            
            // Check rate limits
            await this.rateLimiter.checkLimit();
            
            // Check cache for GET requests
            if (method === 'GET' && options.cache !== false) {
              const cached = await this.cache.get(url, options.params);
              if (cached) return cached;
            }
            
            // Build request
            const requestConfig = {
              method,
              headers: await this.buildHeaders(options.headers),
              timeout: options.timeout || this.timeout
            };
            
            if (options.body) {
              requestConfig.body = JSON.stringify(options.body);
            }
            
            if (options.params) {
              const params = new URLSearchParams(options.params);
              url += '?' + params.toString();
            }
            
            // Apply interceptors
            for (const interceptor of this.interceptors) {
              await interceptor.request(requestConfig);
            }
            
            // Execute with retry
            const response = await this.executeWithRetry(
              () => fetch(url, requestConfig),
              this.retryConfig
            );
            
            // Apply response interceptors
            for (const interceptor of this.interceptors) {
              await interceptor.response(response);
            }
            
            // Cache successful GET responses
            if (method === 'GET' && response.ok) {
              await this.cache.set(url, options.params, response.data);
            }
            
            return response;
          }
          
          async buildHeaders(customHeaders = {}) {
            const headers = {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              ...customHeaders
            };
            
            // Add authentication
            if (this.auth.type === 'bearer') {
              headers['Authorization'] = \`Bearer \${await this.auth.getToken()}\`;
            } else if (this.auth.type === 'apikey') {
              headers[this.auth.headerName || 'X-API-Key'] = this.auth.apiKey;
            } else if (this.auth.type === 'basic') {
              const encoded = Buffer.from(
                \`\${this.auth.username}:\${this.auth.password}\`
              ).toString('base64');
              headers['Authorization'] = \`Basic \${encoded}\`;
            }
            
            return headers;
          }
          
          async executeWithRetry(fn, config) {
            let lastError;
            
            for (let attempt = 1; attempt <= config.attempts; attempt++) {
              try {
                return await fn();
              } catch (error) {
                lastError = error;
                
                if (!this.shouldRetry(error, attempt, config)) {
                  throw error;
                }
                
                const delay = this.calculateBackoff(attempt, config);
                await new Promise(resolve => setTimeout(resolve, delay));
              }
            }
            
            throw lastError;
          }
          
          shouldRetry(error, attempt, config) {
            if (attempt >= config.attempts) return false;
            
            // Retry on network errors or 5xx status codes
            return error.code === 'ECONNRESET' ||
                   error.code === 'ETIMEDOUT' ||
                   (error.status >= 500 && error.status < 600);
          }
          
          calculateBackoff(attempt, config) {
            // Exponential backoff with jitter
            const exponential = Math.pow(2, attempt - 1) * config.delay;
            const jitter = Math.random() * 0.1 * exponential;
            return exponential + jitter;
          }
        }
      `,
      
      // Service-specific implementations
      services: `
        // Stripe Integration
        class StripeIntegration extends APIClient {
          constructor(apiKey) {
            super({
              baseURL: 'https://api.stripe.com/v1',
              auth: { type: 'bearer', getToken: () => apiKey },
              rateLimit: { requests: 100, window: 1000 }
            });
          }
          
          async createCustomer(data) {
            return this.request('POST', '/customers', {
              body: data
            });
          }
          
          async createPaymentIntent(amount, currency, metadata) {
            return this.request('POST', '/payment_intents', {
              body: { amount, currency, metadata }
            });
          }
          
          async listSubscriptions(customerId) {
            return this.request('GET', '/subscriptions', {
              params: { customer: customerId }
            });
          }
        }
        
        // Salesforce Integration
        class SalesforceIntegration extends APIClient {
          constructor(instanceUrl, accessToken) {
            super({
              baseURL: instanceUrl,
              auth: { type: 'bearer', getToken: () => accessToken }
            });
          }
          
          async query(soql) {
            return this.request('GET', '/services/data/v52.0/query', {
              params: { q: soql }
            });
          }
          
          async createRecord(objectType, data) {
            return this.request('POST', \`/services/data/v52.0/sobjects/\${objectType}\`, {
              body: data
            });
          }
          
          async updateRecord(objectType, id, data) {
            return this.request('PATCH', \`/services/data/v52.0/sobjects/\${objectType}/\${id}\`, {
              body: data
            });
          }
        }
      `
    };
  }
  
  implementDataSync() {
    return `
      class DataSynchronizer {
        constructor() {
          this.syncJobs = new Map();
          this.conflictResolver = new ConflictResolver();
        }
        
        createSyncJob(config) {
          const job = {
            id: uuid(),
            name: config.name,
            source: config.source,
            destination: config.destination,
            mapping: config.mapping,
            schedule: config.schedule,
            lastSync: null,
            status: 'idle'
          };
          
          this.syncJobs.set(job.id, job);
          
          if (config.schedule) {
            this.scheduleSyncJob(job);
          }
          
          return job;
        }
        
        async executeSync(jobId) {
          const job = this.syncJobs.get(jobId);
          if (!job) throw new Error('Sync job not found');
          
          job.status = 'running';
          const syncLog = {
            jobId,
            startTime: new Date(),
            records: { created: 0, updated: 0, deleted: 0, errors: 0 }
          };
          
          try {
            // Fetch data from source
            const sourceData = await this.fetchSourceData(job.source);
            
            // Transform data according to mapping
            const transformedData = this.transformData(sourceData, job.mapping);
            
            // Get existing destination data for comparison
            const destData = await this.fetchDestinationData(job.destination);
            
            // Calculate changes
            const changes = this.calculateChanges(transformedData, destData);
            
            // Apply changes with conflict resolution
            for (const change of changes) {
              try {
                await this.applyChange(change, job.destination, syncLog);
              } catch (error) {
                syncLog.records.errors++;
                console.error('Sync error:', error);
              }
            }
            
            job.lastSync = new Date();
            job.status = 'completed';
            
          } catch (error) {
            job.status = 'failed';
            throw error;
          } finally {
            syncLog.endTime = new Date();
            await this.saveSyncLog(syncLog);
          }
          
          return syncLog;
        }
        
        calculateChanges(source, destination) {
          const changes = [];
          const destMap = new Map(destination.map(d => [d.id, d]));
          
          // Find creates and updates
          for (const sourceItem of source) {
            const destItem = destMap.get(sourceItem.id);
            
            if (!destItem) {
              changes.push({ type: 'create', data: sourceItem });
            } else if (this.hasChanges(sourceItem, destItem)) {
              changes.push({ 
                type: 'update', 
                id: sourceItem.id,
                data: sourceItem,
                conflicts: this.detectConflicts(sourceItem, destItem)
              });
            }
            
            destMap.delete(sourceItem.id);
          }
          
          // Remaining items in destination should be deleted
          for (const [id, item] of destMap) {
            changes.push({ type: 'delete', id, data: item });
          }
          
          return changes;
        }
        
        async applyChange(change, destination, log) {
          switch (change.type) {
            case 'create':
              await destination.create(change.data);
              log.records.created++;
              break;
              
            case 'update':
              if (change.conflicts.length > 0) {
                const resolved = await this.conflictResolver.resolve(
                  change.conflicts,
                  change.data
                );
                await destination.update(change.id, resolved);
              } else {
                await destination.update(change.id, change.data);
              }
              log.records.updated++;
              break;
              
            case 'delete':
              await destination.delete(change.id);
              log.records.deleted++;
              break;
          }
        }
      }
    `;
  }
}
```

### 4. Real-time Integration

```javascript
class RealTimeIntegration {
  implementWebSocketIntegration() {
    return `
      class WebSocketManager {
        constructor() {
          this.connections = new Map();
          this.handlers = new Map();
          this.reconnectAttempts = new Map();
        }
        
        connect(serviceName, config) {
          const ws = new WebSocket(config.url, config.protocols);
          
          ws.on('open', () => {
            console.log(\`Connected to \${serviceName}\`);
            this.connections.set(serviceName, ws);
            this.reconnectAttempts.delete(serviceName);
            
            // Send authentication if required
            if (config.auth) {
              ws.send(JSON.stringify({
                type: 'auth',
                token: config.auth.token
              }));
            }
            
            // Subscribe to channels
            if (config.channels) {
              config.channels.forEach(channel => {
                ws.send(JSON.stringify({
                  type: 'subscribe',
                  channel
                }));
              });
            }
          });
          
          ws.on('message', (data) => {
            const message = JSON.parse(data);
            this.handleMessage(serviceName, message);
          });
          
          ws.on('error', (error) => {
            console.error(\`WebSocket error for \${serviceName}:\`, error);
          });
          
          ws.on('close', (code, reason) => {
            console.log(\`Disconnected from \${serviceName}: \${reason}\`);
            this.connections.delete(serviceName);
            
            // Attempt reconnection
            if (config.autoReconnect !== false) {
              this.scheduleReconnect(serviceName, config);
            }
          });
          
          return ws;
        }
        
        scheduleReconnect(serviceName, config) {
          const attempts = this.reconnectAttempts.get(serviceName) || 0;
          const delay = Math.min(1000 * Math.pow(2, attempts), 30000);
          
          setTimeout(() => {
            console.log(\`Attempting to reconnect to \${serviceName}...\`);
            this.reconnectAttempts.set(serviceName, attempts + 1);
            this.connect(serviceName, config);
          }, delay);
        }
        
        registerHandler(serviceName, eventType, handler) {
          const key = \`\${serviceName}:\${eventType}\`;
          if (!this.handlers.has(key)) {
            this.handlers.set(key, []);
          }
          this.handlers.get(key).push(handler);
        }
        
        async handleMessage(serviceName, message) {
          const handlers = this.handlers.get(\`\${serviceName}:\${message.type}\`) || [];
          
          for (const handler of handlers) {
            try {
              await handler(message);
            } catch (error) {
              console.error('Message handler error:', error);
            }
          }
          
          // Store in event log
          await this.logRealtimeEvent({
            service: serviceName,
            type: message.type,
            data: message.data,
            timestamp: new Date()
          });
        }
        
        broadcast(serviceName, message) {
          const ws = this.connections.get(serviceName);
          if (ws && ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify(message));
          }
        }
      }
    `;
  }
  
  implementServerSentEvents() {
    return `
      class SSEManager {
        constructor() {
          this.clients = new Map();
        }
        
        addClient(clientId, res) {
          // Set SSE headers
          res.writeHead(200, {
            'Content-Type': 'text/event-stream',
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive',
            'Access-Control-Allow-Origin': '*'
          });
          
          // Send initial connection event
          res.write('event: connected\\n');
          res.write(\`data: {"clientId": "\${clientId}"}\\n\\n\`);
          
          this.clients.set(clientId, res);
          
          // Handle client disconnect
          res.on('close', () => {
            this.clients.delete(clientId);
          });
        }
        
        sendEvent(clientId, eventName, data) {
          const client = this.clients.get(clientId);
          if (!client) return;
          
          const event = [
            \`event: \${eventName}\`,
            \`id: \${Date.now()}\`,
            \`data: \${JSON.stringify(data)}\`,
            '', ''
          ].join('\\n');
          
          client.write(event);
        }
        
        broadcast(eventName, data, filter) {
          const event = [
            \`event: \${eventName}\`,
            \`id: \${Date.now()}\`,
            \`data: \${JSON.stringify(data)}\`,
            '', ''
          ].join('\\n');
          
          for (const [clientId, client] of this.clients) {
            if (!filter || filter(clientId)) {
              client.write(event);
            }
          }
        }
      }
      
      // Client-side SSE handler
      class SSEClient {
        constructor(url) {
          this.eventSource = new EventSource(url);
          this.handlers = new Map();
          
          this.eventSource.onopen = () => {
            console.log('SSE connected');
          };
          
          this.eventSource.onerror = (error) => {
            console.error('SSE error:', error);
            if (this.eventSource.readyState === EventSource.CLOSED) {
              this.reconnect();
            }
          };
        }
        
        on(eventName, handler) {
          this.eventSource.addEventListener(eventName, (event) => {
            const data = JSON.parse(event.data);
            handler(data, event);
          });
        }
        
        reconnect() {
          setTimeout(() => {
            console.log('Attempting SSE reconnection...');
            this.eventSource = new EventSource(this.eventSource.url);
          }, 5000);
        }
      }
    `;
  }
}
```

### 5. Integration Dashboard

```javascript
const IntegrationDashboard = () => {
  const [integrations, setIntegrations] = useState([]);
  const [syncJobs, setSyncJobs] = useState([]);
  const [webhookEvents, setWebhookEvents] = useState([]);
  const [activeTab, setActiveTab] = useState('overview');
  
  const getIntegrationStatus = (integration) => {
    if (!integration.connected) return 'disconnected';
    if (integration.lastError) return 'error';
    if (integration.syncing) return 'syncing';
    return 'connected';
  };
  
  const getStatusColor = (status) => {
    const colors = {
      connected: 'text-green-600 bg-green-100',
      disconnected: 'text-gray-600 bg-gray-100',
      error: 'text-red-600 bg-red-100',
      syncing: 'text-blue-600 bg-blue-100'
    };
    return colors[status] || colors.disconnected;
  };
  
  return (
    <div className="space-y-6">
      {/* Tab Navigation */}
      <div className="border-b">
        <nav className="flex space-x-8">
          {['overview', 'connections', 'sync', 'webhooks', 'logs'].map(tab => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`py-2 px-1 border-b-2 font-medium text-sm capitalize ${
                activeTab === tab
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700'
              }`}
            >
              {tab}
            </button>
          ))}
        </nav>
      </div>
      
      {/* Overview Tab */}
      {activeTab === 'overview' && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {integrations.map(integration => (
            <div key={integration.id} className="bg-white rounded-lg shadow p-6">
              <div className="flex items-start justify-between mb-4">
                <div className="flex items-center">
                  <img 
                    src={integration.logo} 
                    alt={integration.name}
                    className="w-10 h-10 rounded mr-3"
                  />
                  <div>
                    <h3 className="font-semibold">{integration.name}</h3>
                    <p className="text-sm text-gray-600">{integration.type}</p>
                  </div>
                </div>
                <span className={`px-2 py-1 rounded text-xs ${
                  getStatusColor(getIntegrationStatus(integration))
                }`}>
                  {getIntegrationStatus(integration)}
                </span>
              </div>
              
              <div className="space-y-2 text-sm">
                <div className="flex justify-between">
                  <span className="text-gray-600">Last Sync</span>
                  <span>{integration.lastSync 
                    ? formatDistanceToNow(integration.lastSync) + ' ago'
                    : 'Never'
                  }</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Records Synced</span>
                  <span>{integration.recordCount || 0}</span>
                </div>
                {integration.nextSync && (
                  <div className="flex justify-between">
                    <span className="text-gray-600">Next Sync</span>
                    <span>{format(integration.nextSync, 'HH:mm')}</span>
                  </div>
                )}
              </div>
              
              <div className="mt-4 flex gap-2">
                <button className="flex-1 text-sm bg-blue-50 text-blue-600 py-1 rounded hover:bg-blue-100">
                  Configure
                </button>
                {integration.connected ? (
                  <button className="flex-1 text-sm bg-gray-50 text-gray-600 py-1 rounded hover:bg-gray-100">
                    Disconnect
                  </button>
                ) : (
                  <button className="flex-1 text-sm bg-green-50 text-green-600 py-1 rounded hover:bg-green-100">
                    Connect
                  </button>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
      
      {/* Sync Jobs Tab */}
      {activeTab === 'sync' && (
        <div className="bg-white rounded-lg shadow">
          <div className="p-6 border-b">
            <div className="flex justify-between items-center">
              <h2 className="text-lg font-semibold">Sync Jobs</h2>
              <button className="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700">
                Create Sync Job
              </button>
            </div>
          </div>
          <div className="divide-y">
            {syncJobs.map(job => (
              <div key={job.id} className="p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <h3 className="font-medium">{job.name}</h3>
                    <p className="text-sm text-gray-600 mt-1">
                      {job.source.name} → {job.destination.name}
                    </p>
                  </div>
                  <div className="flex items-center gap-4">
                    <div className="text-right">
                      <p className="text-sm font-medium">
                        {job.status === 'running' ? (
                          <span className="text-blue-600">Syncing...</span>
                        ) : (
                          <span>{job.recordsSynced} records</span>
                        )}
                      </p>
                      <p className="text-xs text-gray-600">
                        Last run: {job.lastRun ? formatDistanceToNow(job.lastRun) + ' ago' : 'Never'}
                      </p>
                    </div>
                    <button 
                      className="text-blue-600 hover:text-blue-800"
                      disabled={job.status === 'running'}
                    >
                      <Play size={20} />
                    </button>
                  </div>
                </div>
                {job.status === 'running' && (
                  <div className="mt-4">
                    <div className="flex justify-between text-sm mb-1">
                      <span>Progress</span>
                      <span>{job.progress}%</span>
                    </div>
                    <div className="w-full bg-gray-200 rounded-full h-2">
                      <div 
                        className="bg-blue-600 h-2 rounded-full transition-all"
                        style={{ width: `${job.progress}%` }}
                      />
                    </div>
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};
```

## Integration Examples

### With Security Team
```javascript
// Secure API credentials
const securityIntegration = {
  credentialStorage: 'Use Encryption Specialist for API keys',
  auditLogging: 'Track all external API calls',
  compliance: 'Ensure GDPR compliance for data sync'
};
```

### With Performance Optimizer
```javascript
// Optimize integration performance
const performanceIntegration = {
  caching: 'Cache external API responses',
  batching: 'Batch API requests to reduce calls',
  queueing: 'Use job queues for heavy sync operations'
};
```

### With Notification System
```javascript
// Integration event notifications
const notificationIntegration = {
  syncComplete: 'Notify when sync jobs complete',
  webhookFailure: 'Alert on webhook delivery failures',
  apiErrors: 'Send alerts for API rate limits or errors'
};
```

## Configuration Options

```javascript
const integrationConfig = {
  // OAuth settings
  oauth: {
    stateExpiry: 600000, // 10 minutes
    tokenRefreshBuffer: 300000, // 5 minutes before expiry
    secureStorage: true
  },
  
  // Webhook settings
  webhooks: {
    timeout: 30000,
    retryAttempts: 3,
    signatureAlgorithm: 'sha256',
    eventRetention: 7 // days
  },
  
  // API client settings
  api: {
    defaultTimeout: 30000,
    retryAttempts: 3,
    rateLimitBuffer: 0.9, // Use 90% of rate limit
    cacheEnabled: true
  },
  
  // Sync settings
  sync: {
    batchSize: 100,
    conflictResolution: 'latest-wins',
    enableBidirectional: true
  },
  
  // Real-time settings
  realtime: {
    reconnectAttempts: 10,
    heartbeatInterval: 30000,
    messageQueueSize: 1000
  }
};
```

---

*Part of the Database-Admin-Builder Enhancement Team | Seamless integration with external services and APIs*