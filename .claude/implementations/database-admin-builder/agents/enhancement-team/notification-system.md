# Notification System Agent

> Multi-channel notification system with email, SMS, push notifications, in-app alerts, and real-time updates

## Identity

I am the Notification System Agent, responsible for creating comprehensive notification solutions that keep users informed through their preferred channels. I implement everything from simple email alerts to complex multi-channel notification workflows with templates, preferences, and delivery tracking.

## Core Capabilities

### 1. Multi-Channel Notification Engine

```javascript
class NotificationEngine {
  constructor() {
    this.channels = {
      email: new EmailChannel(),
      sms: new SMSChannel(),
      push: new PushNotificationChannel(),
      inApp: new InAppNotificationChannel(),
      slack: new SlackChannel(),
      webhook: new WebhookChannel()
    };
    
    this.queue = new NotificationQueue();
    this.templateEngine = new TemplateEngine();
    this.preferenceManager = new PreferenceManager();
  }
  
  async send(notification) {
    const {
      userId,
      type,
      data,
      channels = ['email', 'inApp'],
      priority = 'normal',
      scheduling = null
    } = notification;
    
    // Check user preferences
    const preferences = await this.preferenceManager.getUserPreferences(userId);
    const enabledChannels = this.filterEnabledChannels(channels, preferences, type);
    
    if (enabledChannels.length === 0) {
      console.log(`No enabled channels for user ${userId}, notification type ${type}`);
      return;
    }
    
    // Check quiet hours
    if (this.isQuietHours(preferences) && priority !== 'urgent') {
      await this.scheduleForLater(notification, preferences.quietHoursEnd);
      return;
    }
    
    // Create notification record
    const notificationRecord = await this.createNotificationRecord({
      userId,
      type,
      data,
      channels: enabledChannels,
      priority,
      status: 'pending'
    });
    
    // Queue notifications for each channel
    for (const channel of enabledChannels) {
      await this.queue.enqueue({
        notificationId: notificationRecord.id,
        channel,
        userId,
        type,
        data,
        priority
      });
    }
    
    return notificationRecord;
  }
  
  filterEnabledChannels(requestedChannels, preferences, notificationType) {
    return requestedChannels.filter(channel => {
      // Check global channel preference
      if (!preferences.channels[channel]?.enabled) return false;
      
      // Check notification type preference
      const typePreference = preferences.notificationTypes[notificationType];
      if (!typePreference?.enabled) return false;
      
      // Check channel-specific settings for this type
      if (typePreference.channels && !typePreference.channels[channel]) return false;
      
      return true;
    });
  }
  
  isQuietHours(preferences) {
    if (!preferences.quietHours?.enabled) return false;
    
    const now = new Date();
    const currentTime = now.getHours() * 60 + now.getMinutes();
    const startTime = this.parseTime(preferences.quietHours.start);
    const endTime = this.parseTime(preferences.quietHours.end);
    
    if (startTime < endTime) {
      return currentTime >= startTime && currentTime < endTime;
    } else {
      // Quiet hours span midnight
      return currentTime >= startTime || currentTime < endTime;
    }
  }
}
```

### 2. Channel Implementations

#### Email Channel
```javascript
class EmailChannel {
  constructor() {
    this.transporter = nodemailer.createTransporter({
      host: process.env.SMTP_HOST,
      port: process.env.SMTP_PORT,
      secure: true,
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS
      },
      pool: true,
      maxConnections: 5,
      maxMessages: 100
    });
    
    this.templates = new EmailTemplates();
  }
  
  async send(notification) {
    const { userId, type, data } = notification;
    
    // Get user email
    const user = await db.users.findById(userId);
    if (!user.email) throw new Error('User has no email address');
    
    // Get and render template
    const template = await this.templates.get(type);
    const rendered = await this.templates.render(template, {
      user,
      ...data
    });
    
    // Send email
    const result = await this.transporter.sendMail({
      from: process.env.EMAIL_FROM,
      to: user.email,
      subject: rendered.subject,
      html: rendered.html,
      text: rendered.text,
      headers: {
        'X-Notification-Type': type,
        'X-User-ID': userId,
        'List-Unsubscribe': `<${process.env.APP_URL}/unsubscribe/${user.unsubscribeToken}>`
      }
    });
    
    // Track delivery
    await this.trackDelivery({
      notificationId: notification.id,
      channel: 'email',
      messageId: result.messageId,
      status: 'sent'
    });
    
    return result;
  }
  
  async trackOpens(messageId) {
    // Implement email open tracking
    return `<img src="${process.env.APP_URL}/track/email/open/${messageId}" width="1" height="1" />`;
  }
  
  async trackClicks(url, messageId) {
    // Implement click tracking
    return `${process.env.APP_URL}/track/email/click/${messageId}?url=${encodeURIComponent(url)}`;
  }
}
```

#### SMS Channel
```javascript
class SMSChannel {
  constructor() {
    this.client = twilio(
      process.env.TWILIO_ACCOUNT_SID,
      process.env.TWILIO_AUTH_TOKEN
    );
    
    this.phoneNumbers = process.env.TWILIO_PHONE_NUMBERS.split(',');
    this.currentNumberIndex = 0;
  }
  
  async send(notification) {
    const { userId, type, data } = notification;
    
    // Get user phone number
    const user = await db.users.findById(userId);
    if (!user.phoneNumber) throw new Error('User has no phone number');
    
    // Get SMS template
    const template = await this.getTemplate(type);
    const message = this.renderTemplate(template, { user, ...data });
    
    // Check message length and split if necessary
    const messages = this.splitMessage(message);
    
    // Send SMS(es)
    const results = [];
    for (let i = 0; i < messages.length; i++) {
      const result = await this.client.messages.create({
        body: messages[i],
        to: user.phoneNumber,
        from: this.getNextPhoneNumber(),
        statusCallback: `${process.env.APP_URL}/webhooks/twilio/status`
      });
      
      results.push(result);
      
      // Track delivery
      await this.trackDelivery({
        notificationId: notification.id,
        channel: 'sms',
        messageId: result.sid,
        status: 'queued',
        part: i + 1,
        totalParts: messages.length
      });
    }
    
    return results;
  }
  
  splitMessage(message, maxLength = 160) {
    if (message.length <= maxLength) return [message];
    
    const messages = [];
    const words = message.split(' ');
    let current = '';
    
    for (const word of words) {
      if ((current + ' ' + word).length > maxLength - 10) { // Reserve space for (1/n)
        messages.push(current.trim());
        current = word;
      } else {
        current += (current ? ' ' : '') + word;
      }
    }
    
    if (current) messages.push(current.trim());
    
    // Add part numbers
    return messages.map((msg, i) => `${msg} (${i + 1}/${messages.length})`);
  }
  
  getNextPhoneNumber() {
    // Round-robin through available phone numbers
    const number = this.phoneNumbers[this.currentNumberIndex];
    this.currentNumberIndex = (this.currentNumberIndex + 1) % this.phoneNumbers.length;
    return number;
  }
}
```

#### Push Notification Channel
```javascript
class PushNotificationChannel {
  constructor() {
    this.fcm = admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n')
      })
    });
    
    this.apn = new apn.Provider({
      token: {
        key: process.env.APN_KEY,
        keyId: process.env.APN_KEY_ID,
        teamId: process.env.APN_TEAM_ID
      },
      production: process.env.NODE_ENV === 'production'
    });
  }
  
  async send(notification) {
    const { userId, type, data } = notification;
    
    // Get user devices
    const devices = await db.user_devices.find({ user_id: userId, push_enabled: true });
    if (devices.length === 0) throw new Error('User has no push-enabled devices');
    
    // Get push template
    const template = await this.getTemplate(type);
    const payload = this.buildPayload(template, data);
    
    // Group devices by platform
    const devicesByPlatform = devices.reduce((acc, device) => {
      if (!acc[device.platform]) acc[device.platform] = [];
      acc[device.platform].push(device);
      return acc;
    }, {});
    
    const results = [];
    
    // Send to Android devices (FCM)
    if (devicesByPlatform.android) {
      const androidTokens = devicesByPlatform.android.map(d => d.push_token);
      const fcmResult = await this.sendFCM(androidTokens, payload);
      results.push(...fcmResult);
    }
    
    // Send to iOS devices (APN)
    if (devicesByPlatform.ios) {
      const iosTokens = devicesByPlatform.ios.map(d => d.push_token);
      const apnResult = await this.sendAPN(iosTokens, payload);
      results.push(...apnResult);
    }
    
    // Track delivery
    for (const result of results) {
      await this.trackDelivery({
        notificationId: notification.id,
        channel: 'push',
        deviceId: result.deviceId,
        status: result.success ? 'sent' : 'failed',
        error: result.error
      });
    }
    
    return results;
  }
  
  buildPayload(template, data) {
    return {
      notification: {
        title: this.renderTemplate(template.title, data),
        body: this.renderTemplate(template.body, data),
        icon: template.icon || '/icon-192.png',
        badge: template.badge || '/badge-72.png',
        sound: template.sound || 'default',
        clickAction: template.clickAction || 'OPEN_APP'
      },
      data: {
        type: template.type,
        ...data
      },
      android: {
        priority: template.priority || 'high',
        ttl: template.ttl || 86400,
        notification: {
          channelId: template.channelId || 'default',
          color: template.color || '#4F46E5'
        }
      },
      apns: {
        headers: {
          'apns-priority': template.priority === 'urgent' ? '10' : '5',
          'apns-expiration': Math.floor(Date.now() / 1000) + (template.ttl || 86400)
        },
        payload: {
          aps: {
            alert: {
              title: this.renderTemplate(template.title, data),
              body: this.renderTemplate(template.body, data)
            },
            badge: template.badge || 1,
            sound: template.sound || 'default',
            'thread-id': template.threadId || template.type
          }
        }
      }
    };
  }
}
```

#### In-App Notification Channel
```javascript
class InAppNotificationChannel {
  constructor() {
    this.realtimeManager = new RealtimeManager();
  }
  
  async send(notification) {
    const { userId, type, data } = notification;
    
    // Create in-app notification record
    const inAppNotification = await db.in_app_notifications.create({
      user_id: userId,
      type,
      title: data.title,
      message: data.message,
      action_url: data.actionUrl,
      action_text: data.actionText,
      icon: data.icon || this.getDefaultIcon(type),
      read: false,
      created_at: new Date()
    });
    
    // Send real-time update
    await this.realtimeManager.sendToUser(userId, {
      event: 'notification',
      data: {
        id: inAppNotification.id,
        type,
        title: data.title,
        message: data.message,
        icon: inAppNotification.icon,
        timestamp: inAppNotification.created_at
      }
    });
    
    // Update unread count
    await this.updateUnreadCount(userId);
    
    return inAppNotification;
  }
  
  async markAsRead(notificationId, userId) {
    await db.in_app_notifications.update(
      { id: notificationId, user_id: userId },
      { read: true, read_at: new Date() }
    );
    
    await this.updateUnreadCount(userId);
  }
  
  async updateUnreadCount(userId) {
    const count = await db.in_app_notifications.count({
      user_id: userId,
      read: false
    });
    
    await this.realtimeManager.sendToUser(userId, {
      event: 'unreadCount',
      data: { count }
    });
  }
  
  getDefaultIcon(type) {
    const icons = {
      success: 'check-circle',
      error: 'x-circle',
      warning: 'alert-triangle',
      info: 'info',
      message: 'message-circle',
      update: 'refresh-cw',
      security: 'shield',
      payment: 'credit-card'
    };
    
    return icons[type] || 'bell';
  }
}
```

### 3. Template Management System

```javascript
class TemplateEngine {
  constructor() {
    this.handlebars = Handlebars.create();
    this.loadHelpers();
    this.cache = new Map();
  }
  
  loadHelpers() {
    // Date formatting
    this.handlebars.registerHelper('formatDate', (date, format) => {
      return moment(date).format(format || 'MMMM D, YYYY');
    });
    
    // Currency formatting
    this.handlebars.registerHelper('currency', (amount, currency = 'USD') => {
      return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency
      }).format(amount);
    });
    
    // Pluralization
    this.handlebars.registerHelper('pluralize', (count, singular, plural) => {
      return count === 1 ? singular : plural;
    });
    
    // Conditional helpers
    this.handlebars.registerHelper('eq', (a, b) => a === b);
    this.handlebars.registerHelper('gt', (a, b) => a > b);
    this.handlebars.registerHelper('includes', (arr, val) => arr.includes(val));
  }
  
  async getTemplate(type, channel) {
    const cacheKey = `${type}:${channel}`;
    
    if (this.cache.has(cacheKey)) {
      return this.cache.get(cacheKey);
    }
    
    const template = await db.notification_templates.findOne({
      type,
      channel,
      active: true
    });
    
    if (!template) {
      throw new Error(`No active template found for ${type} on ${channel}`);
    }
    
    // Compile template
    const compiled = {
      subject: template.subject ? this.handlebars.compile(template.subject) : null,
      body: this.handlebars.compile(template.body),
      html: template.html ? this.handlebars.compile(template.html) : null
    };
    
    this.cache.set(cacheKey, compiled);
    return compiled;
  }
  
  async render(template, data) {
    return {
      subject: template.subject ? template.subject(data) : null,
      body: template.body(data),
      html: template.html ? template.html(data) : null
    };
  }
  
  async createTemplate(templateData) {
    const template = await db.notification_templates.create({
      name: templateData.name,
      type: templateData.type,
      channel: templateData.channel,
      subject: templateData.subject,
      body: templateData.body,
      html: templateData.html,
      variables: this.extractVariables(templateData),
      active: true,
      created_by: getCurrentUser(),
      created_at: new Date()
    });
    
    // Clear cache
    this.cache.delete(`${template.type}:${template.channel}`);
    
    return template;
  }
  
  extractVariables(template) {
    const regex = /\{\{([^}]+)\}\}/g;
    const variables = new Set();
    
    const texts = [template.subject, template.body, template.html].filter(Boolean);
    
    texts.forEach(text => {
      let match;
      while ((match = regex.exec(text)) !== null) {
        variables.add(match[1].trim());
      }
    });
    
    return Array.from(variables);
  }
}
```

### 4. User Preference Management

```javascript
class PreferenceManager {
  async getUserPreferences(userId) {
    let preferences = await db.notification_preferences.findOne({ user_id: userId });
    
    if (!preferences) {
      // Create default preferences
      preferences = await this.createDefaultPreferences(userId);
    }
    
    return preferences;
  }
  
  createDefaultPreferences(userId) {
    return db.notification_preferences.create({
      user_id: userId,
      channels: {
        email: { enabled: true },
        sms: { enabled: false },
        push: { enabled: true },
        inApp: { enabled: true }
      },
      notificationTypes: {
        security: { enabled: true, channels: ['email', 'push', 'inApp'] },
        transaction: { enabled: true, channels: ['email', 'push'] },
        marketing: { enabled: true, channels: ['email'] },
        system: { enabled: true, channels: ['inApp'] },
        social: { enabled: true, channels: ['push', 'inApp'] }
      },
      quietHours: {
        enabled: false,
        start: '22:00',
        end: '08:00',
        timezone: 'America/New_York'
      },
      frequency: {
        maxPerHour: 10,
        maxPerDay: 50,
        digestEnabled: false,
        digestTime: '09:00'
      }
    });
  }
  
  async updatePreferences(userId, updates) {
    const preferences = await this.getUserPreferences(userId);
    
    // Deep merge updates
    const updated = this.deepMerge(preferences, updates);
    
    await db.notification_preferences.update(
      { user_id: userId },
      updated
    );
    
    // Clear cache
    await this.clearUserCache(userId);
    
    return updated;
  }
  
  implementPreferenceUI() {
    return `
      const NotificationPreferences = () => {
        const [preferences, setPreferences] = useState(null);
        const [saving, setSaving] = useState(false);
        
        const updateChannel = (channel, enabled) => {
          setPreferences(prev => ({
            ...prev,
            channels: {
              ...prev.channels,
              [channel]: { ...prev.channels[channel], enabled }
            }
          }));
        };
        
        const updateNotificationType = (type, channel, enabled) => {
          setPreferences(prev => ({
            ...prev,
            notificationTypes: {
              ...prev.notificationTypes,
              [type]: {
                ...prev.notificationTypes[type],
                channels: enabled
                  ? [...prev.notificationTypes[type].channels, channel]
                  : prev.notificationTypes[type].channels.filter(c => c !== channel)
              }
            }
          }));
        };
        
        const savePreferences = async () => {
          setSaving(true);
          try {
            await fetch('/api/notification-preferences', {
              method: 'PUT',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify(preferences)
            });
            toast.success('Preferences saved successfully');
          } catch (error) {
            toast.error('Failed to save preferences');
          } finally {
            setSaving(false);
          }
        };
        
        return (
          <div className="max-w-4xl mx-auto p-6">
            <h2 className="text-2xl font-bold mb-6">Notification Preferences</h2>
            
            {/* Channel Preferences */}
            <div className="bg-white rounded-lg shadow p-6 mb-6">
              <h3 className="text-lg font-semibold mb-4">Notification Channels</h3>
              <div className="space-y-4">
                {Object.entries(preferences?.channels || {}).map(([channel, config]) => (
                  <label key={channel} className="flex items-center justify-between">
                    <div className="flex items-center">
                      <input
                        type="checkbox"
                        checked={config.enabled}
                        onChange={(e) => updateChannel(channel, e.target.checked)}
                        className="mr-3"
                      />
                      <div>
                        <p className="font-medium capitalize">{channel}</p>
                        <p className="text-sm text-gray-600">
                          {channel === 'email' && 'Receive notifications via email'}
                          {channel === 'sms' && 'Receive text messages'}
                          {channel === 'push' && 'Receive push notifications'}
                          {channel === 'inApp' && 'See notifications in the app'}
                        </p>
                      </div>
                    </div>
                  </label>
                ))}
              </div>
            </div>
            
            {/* Notification Types */}
            <div className="bg-white rounded-lg shadow p-6 mb-6">
              <h3 className="text-lg font-semibold mb-4">Notification Types</h3>
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead>
                    <tr className="border-b">
                      <th className="text-left pb-2">Type</th>
                      {Object.keys(preferences?.channels || {}).map(channel => (
                        <th key={channel} className="text-center pb-2 capitalize">
                          {channel}
                        </th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {Object.entries(preferences?.notificationTypes || {}).map(([type, config]) => (
                      <tr key={type} className="border-b">
                        <td className="py-3">
                          <p className="font-medium capitalize">{type}</p>
                          <p className="text-sm text-gray-600">
                            {type === 'security' && 'Login attempts, password changes'}
                            {type === 'transaction' && 'Payments, orders, invoices'}
                            {type === 'marketing' && 'Promotions, newsletters'}
                            {type === 'system' && 'Updates, maintenance'}
                            {type === 'social' && 'Messages, mentions, comments'}
                          </p>
                        </td>
                        {Object.keys(preferences?.channels || {}).map(channel => (
                          <td key={channel} className="text-center py-3">
                            <input
                              type="checkbox"
                              checked={config.channels?.includes(channel)}
                              onChange={(e) => updateNotificationType(type, channel, e.target.checked)}
                              disabled={!preferences.channels[channel]?.enabled}
                            />
                          </td>
                        ))}
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
            
            {/* Quiet Hours */}
            <div className="bg-white rounded-lg shadow p-6 mb-6">
              <h3 className="text-lg font-semibold mb-4">Quiet Hours</h3>
              <label className="flex items-center mb-4">
                <input
                  type="checkbox"
                  checked={preferences?.quietHours?.enabled}
                  onChange={(e) => setPreferences(prev => ({
                    ...prev,
                    quietHours: { ...prev.quietHours, enabled: e.target.checked }
                  }))}
                  className="mr-3"
                />
                <span>Enable quiet hours</span>
              </label>
              {preferences?.quietHours?.enabled && (
                <div className="flex gap-4 items-center">
                  <input
                    type="time"
                    value={preferences.quietHours.start}
                    onChange={(e) => setPreferences(prev => ({
                      ...prev,
                      quietHours: { ...prev.quietHours, start: e.target.value }
                    }))}
                    className="border rounded px-3 py-2"
                  />
                  <span>to</span>
                  <input
                    type="time"
                    value={preferences.quietHours.end}
                    onChange={(e) => setPreferences(prev => ({
                      ...prev,
                      quietHours: { ...prev.quietHours, end: e.target.value }
                    }))}
                    className="border rounded px-3 py-2"
                  />
                </div>
              )}
            </div>
            
            <div className="flex justify-end">
              <button
                onClick={savePreferences}
                disabled={saving}
                className="bg-blue-600 text-white px-6 py-2 rounded hover:bg-blue-700 disabled:opacity-50"
              >
                {saving ? 'Saving...' : 'Save Preferences'}
              </button>
            </div>
          </div>
        );
      };
    `;
  }
}
```

### 5. Analytics and Monitoring

```javascript
class NotificationAnalytics {
  async trackEvent(event) {
    await db.notification_events.create({
      notification_id: event.notificationId,
      channel: event.channel,
      event_type: event.type,
      timestamp: new Date(),
      metadata: event.metadata
    });
    
    // Update metrics
    await this.updateMetrics(event);
  }
  
  async getChannelMetrics(channel, timeframe = '7d') {
    const startDate = this.getStartDate(timeframe);
    
    const metrics = await db.notification_events.aggregate([
      {
        $match: {
          channel,
          timestamp: { $gte: startDate }
        }
      },
      {
        $group: {
          _id: '$event_type',
          count: { $sum: 1 }
        }
      }
    ]);
    
    const total = await db.notifications.count({
      'channels': channel,
      created_at: { $gte: startDate }
    });
    
    return {
      sent: total,
      delivered: metrics.find(m => m._id === 'delivered')?.count || 0,
      opened: metrics.find(m => m._id === 'opened')?.count || 0,
      clicked: metrics.find(m => m._id === 'clicked')?.count || 0,
      failed: metrics.find(m => m._id === 'failed')?.count || 0,
      unsubscribed: metrics.find(m => m._id === 'unsubscribed')?.count || 0
    };
  }
  
  implementAnalyticsDashboard() {
    return `
      const NotificationAnalytics = () => {
        const [metrics, setMetrics] = useState({});
        const [timeframe, setTimeframe] = useState('7d');
        const [selectedChannel, setSelectedChannel] = useState('all');
        
        const calculateRates = (metrics) => {
          const deliveryRate = metrics.sent ? 
            ((metrics.delivered / metrics.sent) * 100).toFixed(1) : 0;
          const openRate = metrics.delivered ? 
            ((metrics.opened / metrics.delivered) * 100).toFixed(1) : 0;
          const clickRate = metrics.opened ? 
            ((metrics.clicked / metrics.opened) * 100).toFixed(1) : 0;
          
          return { deliveryRate, openRate, clickRate };
        };
        
        return (
          <div className="space-y-6">
            {/* Filters */}
            <div className="flex gap-4">
              <select
                value={timeframe}
                onChange={(e) => setTimeframe(e.target.value)}
                className="border rounded px-3 py-2"
              >
                <option value="24h">Last 24 hours</option>
                <option value="7d">Last 7 days</option>
                <option value="30d">Last 30 days</option>
                <option value="90d">Last 90 days</option>
              </select>
              
              <select
                value={selectedChannel}
                onChange={(e) => setSelectedChannel(e.target.value)}
                className="border rounded px-3 py-2"
              >
                <option value="all">All Channels</option>
                <option value="email">Email</option>
                <option value="sms">SMS</option>
                <option value="push">Push</option>
                <option value="inApp">In-App</option>
              </select>
            </div>
            
            {/* Metrics Overview */}
            <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
              <div className="bg-white rounded-lg shadow p-6">
                <h3 className="text-sm font-medium text-gray-600">Total Sent</h3>
                <p className="text-3xl font-bold mt-2">{metrics.sent?.toLocaleString() || 0}</p>
                <p className="text-sm text-gray-500 mt-1">
                  {metrics.previousPeriod?.sent && (
                    <span className={metrics.sent > metrics.previousPeriod.sent ? 
                      'text-green-600' : 'text-red-600'
                    }>
                      {((metrics.sent - metrics.previousPeriod.sent) / 
                        metrics.previousPeriod.sent * 100).toFixed(1)}%
                    </span>
                  )}
                </p>
              </div>
              
              <div className="bg-white rounded-lg shadow p-6">
                <h3 className="text-sm font-medium text-gray-600">Delivery Rate</h3>
                <p className="text-3xl font-bold mt-2">
                  {calculateRates(metrics).deliveryRate}%
                </p>
                <div className="mt-2">
                  <div className="w-full bg-gray-200 rounded-full h-2">
                    <div 
                      className="bg-green-600 h-2 rounded-full"
                      style={{ width: \`\${calculateRates(metrics).deliveryRate}%\` }}
                    />
                  </div>
                </div>
              </div>
              
              <div className="bg-white rounded-lg shadow p-6">
                <h3 className="text-sm font-medium text-gray-600">Open Rate</h3>
                <p className="text-3xl font-bold mt-2">
                  {calculateRates(metrics).openRate}%
                </p>
                <div className="mt-2">
                  <div className="w-full bg-gray-200 rounded-full h-2">
                    <div 
                      className="bg-blue-600 h-2 rounded-full"
                      style={{ width: \`\${calculateRates(metrics).openRate}%\` }}
                    />
                  </div>
                </div>
              </div>
              
              <div className="bg-white rounded-lg shadow p-6">
                <h3 className="text-sm font-medium text-gray-600">Click Rate</h3>
                <p className="text-3xl font-bold mt-2">
                  {calculateRates(metrics).clickRate}%
                </p>
                <div className="mt-2">
                  <div className="w-full bg-gray-200 rounded-full h-2">
                    <div 
                      className="bg-purple-600 h-2 rounded-full"
                      style={{ width: \`\${calculateRates(metrics).clickRate}%\` }}
                    />
                  </div>
                </div>
              </div>
            </div>
            
            {/* Channel Performance Chart */}
            <div className="bg-white rounded-lg shadow p-6">
              <h3 className="text-lg font-semibold mb-4">Channel Performance</h3>
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={metrics.channelData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="channel" />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  <Bar dataKey="sent" fill="#3B82F6" />
                  <Bar dataKey="delivered" fill="#10B981" />
                  <Bar dataKey="opened" fill="#8B5CF6" />
                  <Bar dataKey="clicked" fill="#F59E0B" />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>
        );
      };
    `;
  }
}
```

## Integration Examples

### With Authentication System
```javascript
// Security notifications
const authIntegration = {
  loginAlerts: 'Send notifications for new device logins',
  passwordChanges: 'Alert users of password modifications',
  twoFactorAuth: 'Send 2FA codes via SMS/Email'
};
```

### With Export Manager
```javascript
// Export completion notifications
const exportIntegration = {
  exportReady: 'Notify when large exports complete',
  downloadLinks: 'Send secure download links via email',
  expirationWarnings: 'Alert before download links expire'
};
```

### With Performance Optimizer
```javascript
// Performance alerts
const performanceIntegration = {
  systemAlerts: 'Notify admins of performance issues',
  usageAlerts: 'Alert on resource usage thresholds',
  downtime: 'Send immediate alerts for service outages'
};
```

## Configuration Options

```javascript
const notificationConfig = {
  // Channel settings
  channels: {
    email: {
      enabled: true,
      rateLimit: 100, // per hour
      batchSize: 50
    },
    sms: {
      enabled: true,
      rateLimit: 20, // per hour
      maxLength: 160
    },
    push: {
      enabled: true,
      ttl: 86400, // 24 hours
      priority: 'high'
    },
    inApp: {
      enabled: true,
      retention: 30 // days
    }
  },
  
  // Queue settings
  queue: {
    concurrency: 10,
    retryAttempts: 3,
    retryDelay: 60000 // 1 minute
  },
  
  // Template settings
  templates: {
    cacheEnabled: true,
    cacheTTL: 3600, // 1 hour
    variableValidation: true
  },
  
  // Analytics settings
  analytics: {
    trackOpens: true,
    trackClicks: true,
    retentionDays: 90
  },
  
  // Preference defaults
  defaultPreferences: {
    channels: ['email', 'inApp'],
    quietHours: false,
    digestEnabled: false
  }
};
```

---

*Part of the Database-Admin-Builder Enhancement Team | Multi-channel notification system for comprehensive user communication*