# Automation Frameworks

## Overview
This document provides comprehensive guidance on test automation frameworks, their architecture, implementation patterns, and best practices. It covers various automation tools, frameworks, and strategies for building maintainable and scalable test automation solutions.

## Framework Architecture

### Core Components
```
┌─────────────────────────────────────────────────────────┐
│                  Test Automation Framework               │
├─────────────────────────────────────────────────────────┤
│  Test Layer                                             │
│  ├── Test Cases                                        │
│  ├── Test Suites                                       │
│  └── Test Data                                         │
├─────────────────────────────────────────────────────────┤
│  Business Layer                                         │
│  ├── Page Objects / API Objects                        │
│  ├── Business Workflows                                │
│  └── Domain Models                                     │
├─────────────────────────────────────────────────────────┤
│  Technical Layer                                        │
│  ├── Driver Management                                  │
│  ├── Utilities & Helpers                               │
│  ├── Reporting & Logging                               │
│  └── Configuration Management                          │
├─────────────────────────────────────────────────────────┤
│  Infrastructure Layer                                   │
│  ├── CI/CD Integration                                 │
│  ├── Test Environments                                 │
│  └── External Services                                 │
└─────────────────────────────────────────────────────────┘
```

## Web Automation Frameworks

### 1. Selenium WebDriver Framework

#### Architecture
```python
# framework/core/driver_factory.py
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
import os

class DriverFactory:
    
    @staticmethod
    def create_driver(browser="chrome", headless=False):
        """Create and configure WebDriver instance"""
        
        if browser.lower() == "chrome":
            return DriverFactory._create_chrome_driver(headless)
        elif browser.lower() == "firefox":
            return DriverFactory._create_firefox_driver(headless)
        elif browser.lower() == "safari":
            return DriverFactory._create_safari_driver()
        else:
            raise ValueError(f"Unsupported browser: {browser}")
    
    @staticmethod
    def _create_chrome_driver(headless):
        options = Options()
        
        # Standard options
        options.add_argument("--disable-blink-features=AutomationControlled")
        options.add_experimental_option("excludeSwitches", ["enable-automation"])
        options.add_experimental_option('useAutomationExtension', False)
        
        if headless:
            options.add_argument("--headless")
            options.add_argument("--no-sandbox")
            options.add_argument("--disable-dev-shm-usage")
        
        # Performance options
        prefs = {
            "profile.default_content_setting_values": {
                "images": 2,  # Block images for faster loading
                "plugins": 2,
                "popups": 2,
                "geolocation": 2,
                "notifications": 2
            }
        }
        options.add_experimental_option("prefs", prefs)
        
        service = Service(executable_path=os.getenv("CHROME_DRIVER_PATH"))
        
        driver = webdriver.Chrome(service=service, options=options)
        driver.maximize_window()
        
        return driver
```

#### Page Object Model (POM)
```python
# framework/pages/base_page.py
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException
import logging

class BasePage:
    
    def __init__(self, driver, timeout=10):
        self.driver = driver
        self.wait = WebDriverWait(driver, timeout)
        self.logger = logging.getLogger(self.__class__.__name__)
        
    def wait_for_element(self, locator, condition=EC.presence_of_element_located):
        """Wait for element with retry logic"""
        try:
            element = self.wait.until(condition(locator))
            self.logger.debug(f"Element found: {locator}")
            return element
        except TimeoutException:
            self.logger.error(f"Element not found: {locator}")
            self.capture_screenshot()
            raise
    
    def click(self, locator):
        """Click element with JavaScript fallback"""
        try:
            element = self.wait_for_element(locator, EC.element_to_be_clickable)
            element.click()
        except Exception as e:
            self.logger.warning(f"Regular click failed: {e}. Trying JavaScript click.")
            element = self.wait_for_element(locator)
            self.driver.execute_script("arguments[0].click();", element)
    
    def capture_screenshot(self):
        """Capture screenshot on failure"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"screenshots/{self.__class__.__name__}_{timestamp}.png"
        self.driver.save_screenshot(filename)
        self.logger.info(f"Screenshot saved: {filename}")
```

### 2. Playwright Framework

#### Modern Architecture
```typescript
// framework/core/browser-manager.ts
import { chromium, firefox, webkit, Browser, BrowserContext, Page } from '@playwright/test';

export class BrowserManager {
    private browser: Browser | null = null;
    private context: BrowserContext | null = null;
    
    async initialize(options: BrowserOptions): Promise<void> {
        const { browserName, headless, viewport, recordVideo } = options;
        
        // Launch browser
        switch (browserName) {
            case 'chromium':
                this.browser = await chromium.launch({ headless });
                break;
            case 'firefox':
                this.browser = await firefox.launch({ headless });
                break;
            case 'webkit':
                this.browser = await webkit.launch({ headless });
                break;
        }
        
        // Create context with options
        this.context = await this.browser.newContext({
            viewport,
            recordVideo: recordVideo ? { dir: 'videos' } : undefined,
            ignoreHTTPSErrors: true,
            locale: 'en-US',
            timezoneId: 'America/New_York',
            permissions: ['geolocation', 'notifications']
        });
        
        // Set up request interception
        await this.setupRequestInterception();
    }
    
    private async setupRequestInterception(): Promise<void> {
        if (!this.context) return;
        
        // Block unnecessary resources
        await this.context.route('**/*.{png,jpg,jpeg,gif,svg}', route => route.abort());
        
        // Mock API responses
        await this.context.route('**/api/config', route => {
            route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify({ feature_flags: { new_ui: true } })
            });
        });
        
        // Log all API calls
        this.context.on('request', request => {
            if (request.url().includes('/api/')) {
                console.log(`API Call: ${request.method()} ${request.url()}`);
            }
        });
    }
    
    async createPage(): Promise<Page> {
        if (!this.context) throw new Error('Browser not initialized');
        
        const page = await this.context.newPage();
        
        // Add custom methods to page
        await page.addInitScript(() => {
            // Override date to ensure consistent tests
            Date.now = () => new Date('2024-01-01').getTime();
            
            // Add test helpers to window
            (window as any).__testHelpers = {
                getReduxState: () => (window as any).__REDUX_STORE__?.getState(),
                triggerEvent: (selector: string, event: string) => {
                    document.querySelector(selector)?.dispatchEvent(new Event(event));
                }
            };
        });
        
        return page;
    }
}
```

#### Component Testing
```typescript
// framework/components/component-test-base.ts
import { Page, Locator } from '@playwright/test';

export abstract class ComponentBase {
    constructor(protected page: Page, protected rootSelector: string) {}
    
    protected get root(): Locator {
        return this.page.locator(this.rootSelector);
    }
    
    async waitForLoad(): Promise<void> {
        await this.root.waitFor({ state: 'visible' });
    }
    
    async isDisplayed(): Promise<boolean> {
        return await this.root.isVisible();
    }
    
    async takeSnapshot(name: string): Promise<void> {
        await this.root.screenshot({ path: `snapshots/${name}.png` });
    }
}

// Example component
export class SearchComponent extends ComponentBase {
    private get searchInput(): Locator {
        return this.root.locator('[data-testid="search-input"]');
    }
    
    private get searchButton(): Locator {
        return this.root.locator('[data-testid="search-button"]');
    }
    
    private get results(): Locator {
        return this.root.locator('[data-testid="search-results"] [data-testid="result-item"]');
    }
    
    async search(query: string): Promise<void> {
        await this.searchInput.fill(query);
        await this.searchButton.click();
    }
    
    async getResultCount(): Promise<number> {
        await this.results.first().waitFor();
        return await this.results.count();
    }
    
    async getResultTitles(): Promise<string[]> {
        return await this.results.locator('.title').allTextContents();
    }
}
```

### 3. Cypress Framework

#### Advanced Configuration
```javascript
// cypress.config.js
const { defineConfig } = require('cypress');

module.exports = defineConfig({
    e2e: {
        baseUrl: 'http://localhost:3000',
        viewportWidth: 1280,
        viewportHeight: 720,
        video: true,
        screenshotOnRunFailure: true,
        
        // Retry configuration
        retries: {
            runMode: 2,
            openMode: 0
        },
        
        // Custom timeouts
        defaultCommandTimeout: 10000,
        pageLoadTimeout: 30000,
        requestTimeout: 10000,
        
        // Setup Node events
        setupNodeEvents(on, config) {
            // Custom tasks
            on('task', {
                // Database operations
                'db:seed': require('./cypress/tasks/database').seed,
                'db:cleanup': require('./cypress/tasks/database').cleanup,
                
                // Email operations
                'email:check': require('./cypress/tasks/email').checkInbox,
                
                // Performance metrics
                'perf:analyze': require('./cypress/tasks/performance').analyze
            });
            
            // Code coverage
            require('@cypress/code-coverage/task')(on, config);
            
            // Visual regression
            on('after:screenshot', (details) => {
                require('./cypress/tasks/visual-regression').compare(details);
            });
            
            return config;
        }
    }
});
```

#### Custom Commands
```javascript
// cypress/support/commands.js

// API Testing Commands
Cypress.Commands.add('apiRequest', (method, url, options = {}) => {
    const { body, headers = {}, failOnStatusCode = true } = options;
    
    return cy.request({
        method,
        url: `${Cypress.env('API_URL')}${url}`,
        body,
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${window.localStorage.getItem('authToken')}`,
            ...headers
        },
        failOnStatusCode
    });
});

// Data Attribute Selectors
Cypress.Commands.add('getByTestId', (testId) => {
    return cy.get(`[data-testid="${testId}"]`);
});

// Wait for API
Cypress.Commands.add('waitForApi', (alias, timeout = 10000) => {
    return cy.intercept('GET', '**/api/**').as(alias)
        .wait(`@${alias}`, { timeout });
});

// Visual Testing
Cypress.Commands.add('matchImageSnapshot', (name, options = {}) => {
    cy.screenshot(name, {
        capture: 'viewport',
        overwrite: true,
        ...options
    });
    
    cy.task('visual:compare', { name, ...options });
});
```

## API Automation Frameworks

### 1. REST API Testing Framework

#### Architecture
```python
# framework/api/base_client.py
import requests
from urllib.parse import urljoin
import json
import time
from typing import Dict, Any, Optional

class APIClient:
    
    def __init__(self, base_url: str, headers: Optional[Dict] = None):
        self.base_url = base_url
        self.session = requests.Session()
        self.session.headers.update(headers or {})
        self.session.headers.update({'Content-Type': 'application/json'})
        
    def request(
        self,
        method: str,
        endpoint: str,
        data: Optional[Dict] = None,
        params: Optional[Dict] = None,
        **kwargs
    ) -> requests.Response:
        """Make HTTP request with retry logic"""
        
        url = urljoin(self.base_url, endpoint)
        
        # Retry configuration
        max_retries = 3
        backoff_factor = 0.3
        retry_statuses = [502, 503, 504]
        
        for attempt in range(max_retries):
            try:
                response = self.session.request(
                    method=method,
                    url=url,
                    json=data,
                    params=params,
                    **kwargs
                )
                
                # Log request/response
                self._log_request(method, url, data, response)
                
                # Retry on specific status codes
                if response.status_code in retry_statuses and attempt < max_retries - 1:
                    time.sleep(backoff_factor * (2 ** attempt))
                    continue
                    
                return response
                
            except requests.exceptions.RequestException as e:
                if attempt < max_retries - 1:
                    time.sleep(backoff_factor * (2 ** attempt))
                    continue
                raise
                
    def _log_request(self, method: str, url: str, data: Any, response: requests.Response):
        """Log API request and response"""
        log_entry = {
            'timestamp': time.time(),
            'request': {
                'method': method,
                'url': url,
                'data': data
            },
            'response': {
                'status_code': response.status_code,
                'headers': dict(response.headers),
                'body': response.text[:1000]  # Truncate large responses
            },
            'duration': response.elapsed.total_seconds()
        }
        
        # Write to log file or send to logging service
        self._write_log(log_entry)
```

#### Schema Validation
```python
# framework/api/schema_validator.py
from jsonschema import validate, ValidationError
import yaml

class SchemaValidator:
    
    def __init__(self, schema_dir: str):
        self.schema_dir = schema_dir
        self.schemas = {}
        
    def load_schema(self, schema_name: str) -> Dict:
        """Load schema from file"""
        if schema_name not in self.schemas:
            with open(f"{self.schema_dir}/{schema_name}.yaml", 'r') as f:
                self.schemas[schema_name] = yaml.safe_load(f)
        return self.schemas[schema_name]
    
    def validate_response(self, response_data: Dict, schema_name: str):
        """Validate response against schema"""
        schema = self.load_schema(schema_name)
        
        try:
            validate(instance=response_data, schema=schema)
            return True, None
        except ValidationError as e:
            return False, str(e)

# Example schema (user_schema.yaml)
"""
type: object
required:
  - id
  - email
  - name
properties:
  id:
    type: string
    pattern: "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"
  email:
    type: string
    format: email
  name:
    type: string
    minLength: 1
    maxLength: 100
  age:
    type: integer
    minimum: 0
    maximum: 150
  roles:
    type: array
    items:
      type: string
      enum: ["user", "admin", "moderator"]
additionalProperties: false
"""
```

### 2. GraphQL Testing Framework

#### GraphQL Client
```typescript
// framework/graphql/graphql-client.ts
import { GraphQLClient } from 'graphql-request';
import { DocumentNode } from 'graphql';

export class GraphQLTestClient {
    private client: GraphQLClient;
    
    constructor(endpoint: string, options?: RequestInit) {
        this.client = new GraphQLClient(endpoint, {
            ...options,
            headers: {
                'Content-Type': 'application/json',
                ...options?.headers
            }
        });
    }
    
    async query<T = any>(
        document: DocumentNode | string,
        variables?: any,
        requestHeaders?: HeadersInit
    ): Promise<T> {
        try {
            const response = await this.client.request<T>(
                document,
                variables,
                requestHeaders
            );
            
            // Log for debugging
            this.logQuery(document, variables, response);
            
            return response;
        } catch (error) {
            this.logError(document, variables, error);
            throw error;
        }
    }
    
    async batchQueries<T = any>(
        queries: Array<{
            document: DocumentNode | string;
            variables?: any;
        }>
    ): Promise<T[]> {
        return Promise.all(
            queries.map(q => this.query(q.document, q.variables))
        );
    }
    
    setAuthToken(token: string): void {
        this.client.setHeader('Authorization', `Bearer ${token}`);
    }
}

// Test utilities
export class GraphQLTestUtils {
    static createMockSchema() {
        return `
            type Query {
                user(id: ID!): User
                users(filter: UserFilter): [User!]!
            }
            
            type Mutation {
                createUser(input: CreateUserInput!): User!
                updateUser(id: ID!, input: UpdateUserInput!): User!
            }
            
            type User {
                id: ID!
                email: String!
                name: String!
                posts: [Post!]!
            }
        `;
    }
    
    static generateVariables(overrides = {}) {
        return {
            id: 'test-id',
            email: 'test@example.com',
            name: 'Test User',
            ...overrides
        };
    }
}
```

## Mobile Automation Frameworks

### Appium Framework Architecture
```java
// framework/mobile/MobileDriverManager.java
import io.appium.java_client.AppiumDriver;
import io.appium.java_client.android.AndroidDriver;
import io.appium.java_client.ios.IOSDriver;
import org.openqa.selenium.remote.DesiredCapabilities;

public class MobileDriverManager {
    
    private static ThreadLocal<AppiumDriver> driverThreadLocal = new ThreadLocal<>();
    
    public static AppiumDriver getDriver() {
        return driverThreadLocal.get();
    }
    
    public static void setDriver(Platform platform, DeviceConfig config) {
        AppiumDriver driver;
        
        switch (platform) {
            case ANDROID:
                driver = createAndroidDriver(config);
                break;
            case IOS:
                driver = createIOSDriver(config);
                break;
            default:
                throw new IllegalArgumentException("Unsupported platform: " + platform);
        }
        
        driverThreadLocal.set(driver);
    }
    
    private static AndroidDriver createAndroidDriver(DeviceConfig config) {
        DesiredCapabilities capabilities = new DesiredCapabilities();
        
        // Basic capabilities
        capabilities.setCapability("platformName", "Android");
        capabilities.setCapability("deviceName", config.getDeviceName());
        capabilities.setCapability("platformVersion", config.getPlatformVersion());
        capabilities.setCapability("app", config.getAppPath());
        
        // Advanced capabilities
        capabilities.setCapability("automationName", "UiAutomator2");
        capabilities.setCapability("noReset", config.isNoReset());
        capabilities.setCapability("fullReset", config.isFullReset());
        capabilities.setCapability("autoGrantPermissions", true);
        capabilities.setCapability("unicodeKeyboard", true);
        capabilities.setCapability("resetKeyboard", true);
        
        // Performance capabilities
        capabilities.setCapability("waitForIdleTimeout", 0);
        capabilities.setCapability("waitForSelectorTimeout", 0);
        
        return new AndroidDriver(config.getAppiumServerUrl(), capabilities);
    }
    
    private static IOSDriver createIOSDriver(DeviceConfig config) {
        DesiredCapabilities capabilities = new DesiredCapabilities();
        
        // Basic capabilities
        capabilities.setCapability("platformName", "iOS");
        capabilities.setCapability("deviceName", config.getDeviceName());
        capabilities.setCapability("platformVersion", config.getPlatformVersion());
        capabilities.setCapability("app", config.getAppPath());
        
        // iOS specific
        capabilities.setCapability("automationName", "XCUITest");
        capabilities.setCapability("useNewWDA", true);
        capabilities.setCapability("wdaLaunchTimeout", 120000);
        capabilities.setCapability("wdaConnectionTimeout", 120000);
        
        return new IOSDriver(config.getAppiumServerUrl(), capabilities);
    }
}

// Mobile Page Object
public abstract class MobileBasePage {
    
    protected AppiumDriver driver;
    protected WebDriverWait wait;
    
    public MobileBasePage() {
        this.driver = MobileDriverManager.getDriver();
        this.wait = new WebDriverWait(driver, Duration.ofSeconds(10));
    }
    
    protected MobileElement findElement(By locator) {
        return (MobileElement) wait.until(
            ExpectedConditions.presenceOfElementLocated(locator)
        );
    }
    
    protected void swipeUp() {
        Dimension size = driver.manage().window().getSize();
        int startX = size.width / 2;
        int startY = (int) (size.height * 0.8);
        int endY = (int) (size.height * 0.2);
        
        new TouchAction(driver)
            .press(PointOption.point(startX, startY))
            .waitAction(WaitOptions.waitOptions(Duration.ofMillis(500)))
            .moveTo(PointOption.point(startX, endY))
            .release()
            .perform();
    }
}
```

## Performance Testing Frameworks

### JMeter DSL Framework
```kotlin
// framework/performance/JMeterDSL.kt
import org.apache.jmeter.config.Arguments
import org.apache.jmeter.protocol.http.sampler.HTTPSamplerProxy
import org.apache.jmeter.testelement.TestPlan
import org.apache.jmeter.threads.ThreadGroup

class PerformanceTestBuilder {
    
    private val testPlan = TestPlan("Performance Test Plan")
    private val threadGroups = mutableListOf<ThreadGroup>()
    
    fun scenario(name: String, users: Int, rampUp: Int, duration: Int): ScenarioBuilder {
        val threadGroup = ThreadGroup().apply {
            this.name = name
            this.numThreads = users
            this.rampUp = rampUp
            this.duration = duration
            this.scheduler = true
        }
        
        threadGroups.add(threadGroup)
        return ScenarioBuilder(threadGroup)
    }
    
    inner class ScenarioBuilder(private val threadGroup: ThreadGroup) {
        
        fun request(name: String, url: String): RequestBuilder {
            return RequestBuilder(name, url, threadGroup)
        }
        
        fun think(seconds: Int): ScenarioBuilder {
            // Add think time
            val timer = ConstantTimer()
            timer.delay = (seconds * 1000).toString()
            threadGroup.addTestElement(timer)
            return this
        }
    }
    
    inner class RequestBuilder(
        name: String, 
        url: String, 
        private val threadGroup: ThreadGroup
    ) {
        private val sampler = HTTPSamplerProxy().apply {
            this.name = name
            this.path = url
            this.method = "GET"
        }
        
        fun method(method: String): RequestBuilder {
            sampler.method = method
            return this
        }
        
        fun body(body: String): RequestBuilder {
            sampler.postBodyRaw = true
            sampler.arguments = Arguments().apply {
                addArgument("", body)
            }
            return this
        }
        
        fun header(name: String, value: String): RequestBuilder {
            sampler.headerManager.add(Header(name, value))
            return this
        }
        
        fun assertion(assertionBuilder: AssertionBuilder.() -> Unit): RequestBuilder {
            val assertion = ResponseAssertion()
            AssertionBuilder(assertion).assertionBuilder()
            sampler.addTestElement(assertion)
            return this
        }
        
        fun extract(variable: String, regex: String): RequestBuilder {
            val extractor = RegexExtractor().apply {
                this.referenceName = variable
                this.regex = regex
                this.template = "$1$"
            }
            sampler.addTestElement(extractor)
            return this
        }
        
        fun build() {
            threadGroup.addTestElement(sampler)
        }
    }
}

// Usage
val perfTest = PerformanceTestBuilder()
    .scenario("Login Flow", users = 100, rampUp = 60, duration = 300)
        .request("Login Page", "/login")
            .assertion {
                responseCode(200)
                responseTime(lessThan = 1000)
            }
            .build()
        .think(2)
        .request("Submit Login", "/api/auth/login")
            .method("POST")
            .body("""{"email": "test@example.com", "password": "password"}""")
            .header("Content-Type", "application/json")
            .assertion {
                responseCode(200)
                responseContains("token")
            }
            .extract("authToken", "\"token\":\"([^\"]+)\"")
            .build()
    .build()
```

## Framework Best Practices

### 1. Configuration Management
```yaml
# config/test-config.yaml
environments:
  local:
    base_url: http://localhost:3000
    api_url: http://localhost:3001/api
    database:
      host: localhost
      port: 5432
      name: test_db
    
  staging:
    base_url: https://staging.example.com
    api_url: https://api-staging.example.com
    database:
      host: staging-db.example.com
      port: 5432
      name: staging_db

test_data:
  users:
    admin:
      email: admin@example.com
      password: ${ADMIN_PASSWORD}
    standard:
      email: user@example.com
      password: ${USER_PASSWORD}

timeouts:
  implicit_wait: 0
  explicit_wait: 10
  page_load: 30
  script: 30

parallel_execution:
  enabled: true
  max_instances: 4
  strategy: distributed
```

### 2. Reporting Framework
```python
# framework/reporting/html_reporter.py
from datetime import datetime
import json
from pathlib import Path
from jinja2 import Template

class HTMLReporter:
    
    def __init__(self, report_dir: str):
        self.report_dir = Path(report_dir)
        self.report_dir.mkdir(exist_ok=True)
        
    def generate_report(self, test_results: Dict):
        """Generate HTML test report"""
        
        report_data = {
            'title': 'Test Automation Report',
            'generated_at': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
            'summary': self._calculate_summary(test_results),
            'test_results': test_results,
            'charts': self._generate_charts_data(test_results)
        }
        
        # Load template
        template = Template(self._load_template())
        
        # Generate HTML
        html_content = template.render(**report_data)
        
        # Write report
        report_path = self.report_dir / f"report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.html"
        report_path.write_text(html_content)
        
        # Copy assets
        self._copy_assets()
        
        return str(report_path)
    
    def _calculate_summary(self, test_results: Dict) -> Dict:
        total = len(test_results)
        passed = sum(1 for r in test_results if r['status'] == 'PASSED')
        failed = sum(1 for r in test_results if r['status'] == 'FAILED')
        skipped = sum(1 for r in test_results if r['status'] == 'SKIPPED')
        
        return {
            'total': total,
            'passed': passed,
            'failed': failed,
            'skipped': skipped,
            'pass_rate': (passed / total * 100) if total > 0 else 0,
            'execution_time': sum(r.get('duration', 0) for r in test_results)
        }
```

### 3. Parallel Execution Framework
```javascript
// framework/parallel/test-distributor.js
const { Worker } = require('worker_threads');
const os = require('os');

class TestDistributor {
    constructor(options = {}) {
        this.maxWorkers = options.maxWorkers || os.cpus().length;
        this.workers = [];
        this.testQueue = [];
        this.results = [];
    }
    
    async distributeTests(testFiles) {
        // Split tests into chunks
        const chunks = this.chunkTests(testFiles, this.maxWorkers);
        
        // Create workers
        const workerPromises = chunks.map((chunk, index) => {
            return this.createWorker(chunk, index);
        });
        
        // Wait for all workers to complete
        const results = await Promise.all(workerPromises);
        
        // Merge results
        return this.mergeResults(results);
    }
    
    createWorker(testChunk, workerId) {
        return new Promise((resolve, reject) => {
            const worker = new Worker('./framework/parallel/test-runner-worker.js', {
                workerData: {
                    testFiles: testChunk,
                    workerId: workerId,
                    config: this.getWorkerConfig()
                }
            });
            
            worker.on('message', (message) => {
                if (message.type === 'test-complete') {
                    this.handleTestComplete(message.data);
                }
            });
            
            worker.on('error', reject);
            
            worker.on('exit', (code) => {
                if (code !== 0) {
                    reject(new Error(`Worker ${workerId} stopped with exit code ${code}`));
                } else {
                    resolve(this.results.filter(r => r.workerId === workerId));
                }
            });
            
            this.workers.push(worker);
        });
    }
    
    chunkTests(tests, chunkSize) {
        const chunks = [];
        
        // Sort tests by estimated duration
        const sortedTests = tests.sort((a, b) => {
            return this.getEstimatedDuration(b) - this.getEstimatedDuration(a);
        });
        
        // Distribute tests evenly
        for (let i = 0; i < chunkSize; i++) {
            chunks[i] = [];
        }
        
        sortedTests.forEach((test, index) => {
            chunks[index % chunkSize].push(test);
        });
        
        return chunks;
    }
}
```

### 4. Self-Healing Framework
```python
# framework/self_healing/locator_healer.py
from selenium.webdriver.common.by import By
import difflib

class LocatorHealer:
    
    def __init__(self, driver):
        self.driver = driver
        self.locator_history = {}
        
    def find_element_with_healing(self, locator_strategy):
        """Find element with self-healing capability"""
        
        primary_locator = locator_strategy.primary
        
        try:
            # Try primary locator
            element = self.driver.find_element(*primary_locator)
            self.record_success(locator_strategy.id, primary_locator)
            return element
            
        except NoSuchElementException:
            # Try fallback locators
            for fallback in locator_strategy.fallbacks:
                try:
                    element = self.driver.find_element(*fallback)
                    self.record_success(locator_strategy.id, fallback)
                    
                    # Update primary if fallback is more reliable
                    if self.should_update_primary(locator_strategy.id, fallback):
                        locator_strategy.primary = fallback
                        
                    return element
                except NoSuchElementException:
                    continue
            
            # All locators failed - try to heal
            healed_locator = self.heal_locator(locator_strategy)
            if healed_locator:
                element = self.driver.find_element(*healed_locator)
                locator_strategy.add_fallback(healed_locator)
                return element
                
            raise NoSuchElementException(f"Could not find element with any locator strategy")
    
    def heal_locator(self, locator_strategy):
        """Attempt to heal broken locator"""
        
        # Get page source
        page_source = self.driver.page_source
        
        # Try different healing strategies
        healers = [
            self.heal_by_text_similarity,
            self.heal_by_structure_similarity,
            self.heal_by_visual_similarity
        ]
        
        for healer in healers:
            healed = healer(locator_strategy, page_source)
            if healed:
                return healed
                
        return None
```

This comprehensive automation frameworks guide provides the foundation for building robust, scalable, and maintainable test automation solutions across different platforms and technologies.