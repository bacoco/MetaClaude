# End-to-End (E2E) Test Template

## Overview
End-to-end tests validate complete user workflows through the entire application stack, from the user interface through all services to the database. This template provides patterns for creating maintainable, reliable E2E tests that simulate real user scenarios.

## Core E2E Test Structure

### Web Application E2E Tests (Playwright)
```typescript
// e-commerce-checkout.e2e.test.ts
import { test, expect, Page } from '@playwright/test';
import { TestDataFactory } from './helpers/test-data-factory';
import { PaymentMockServer } from './helpers/payment-mock-server';

test.describe('E-Commerce Checkout Flow', () => {
    let page: Page;
    let testData: TestDataFactory;
    let paymentMock: PaymentMockServer;
    
    test.beforeAll(async () => {
        // Start mock servers
        paymentMock = new PaymentMockServer();
        await paymentMock.start();
        
        // Initialize test data
        testData = new TestDataFactory();
    });
    
    test.afterAll(async () => {
        await paymentMock.stop();
    });
    
    test.beforeEach(async ({ browser }) => {
        // Create new page with viewport
        const context = await browser.newContext({
            viewport: { width: 1280, height: 720 },
            locale: 'en-US',
            timezoneId: 'America/New_York'
        });
        
        page = await context.newPage();
        
        // Set up request interception
        await page.route('**/api/payment/**', route => {
            return paymentMock.handleRequest(route);
        });
        
        // Navigate to application
        await page.goto(process.env.E2E_BASE_URL || 'http://localhost:3000');
    });
    
    test.afterEach(async () => {
        // Capture screenshot on failure
        const testInfo = test.info();
        if (testInfo.status !== 'passed') {
            await page.screenshot({
                path: `screenshots/${testInfo.title}-failure.png`,
                fullPage: true
            });
        }
        
        await page.close();
    });
    
    test('should complete full checkout process', async () => {
        // Arrange
        const user = await testData.createUser();
        const products = await testData.createProducts(3);
        
        // Step 1: Login
        await test.step('User logs in', async () => {
            await page.click('[data-testid="login-button"]');
            await page.fill('[data-testid="email-input"]', user.email);
            await page.fill('[data-testid="password-input"]', user.password);
            await page.click('[data-testid="submit-login"]');
            
            // Wait for redirect
            await page.waitForURL('**/dashboard');
            await expect(page.locator('[data-testid="user-menu"]')).toContainText(user.name);
        });
        
        // Step 2: Browse and add products to cart
        await test.step('Add products to cart', async () => {
            await page.click('[data-testid="shop-nav"]');
            
            for (const product of products) {
                // Search for product
                await page.fill('[data-testid="search-input"]', product.name);
                await page.press('[data-testid="search-input"]', 'Enter');
                
                // Wait for search results
                await page.waitForSelector(`[data-testid="product-${product.id}"]`);
                
                // Add to cart
                await page.click(`[data-testid="add-to-cart-${product.id}"]`);
                
                // Verify cart updated
                await expect(page.locator('[data-testid="cart-count"]')).toHaveText(
                    String(products.indexOf(product) + 1)
                );
            }
        });
        
        // Step 3: Review cart
        await test.step('Review cart contents', async () => {
            await page.click('[data-testid="cart-icon"]');
            
            // Verify all products in cart
            for (const product of products) {
                await expect(page.locator(`[data-testid="cart-item-${product.id}"]`)).toBeVisible();
            }
            
            // Verify total price
            const expectedTotal = products.reduce((sum, p) => sum + p.price, 0);
            await expect(page.locator('[data-testid="cart-total"]')).toHaveText(
                `$${expectedTotal.toFixed(2)}`
            );
            
            await page.click('[data-testid="checkout-button"]');
        });
        
        // Step 4: Enter shipping information
        await test.step('Fill shipping information', async () => {
            const shippingInfo = testData.generateShippingInfo();
            
            await page.fill('[data-testid="shipping-name"]', shippingInfo.name);
            await page.fill('[data-testid="shipping-address"]', shippingInfo.address);
            await page.fill('[data-testid="shipping-city"]', shippingInfo.city);
            await page.selectOption('[data-testid="shipping-state"]', shippingInfo.state);
            await page.fill('[data-testid="shipping-zip"]', shippingInfo.zip);
            
            // Select shipping method
            await page.click('[data-testid="shipping-standard"]');
            
            await page.click('[data-testid="continue-to-payment"]');
        });
        
        // Step 5: Enter payment information
        await test.step('Process payment', async () => {
            // Fill payment form (iframe handling)
            const paymentFrame = page.frameLocator('[data-testid="payment-iframe"]');
            
            await paymentFrame.locator('#card-number').fill('4242 4242 4242 4242');
            await paymentFrame.locator('#expiry').fill('12/25');
            await paymentFrame.locator('#cvc').fill('123');
            
            // Submit order
            await page.click('[data-testid="place-order"]');
            
            // Wait for processing
            await expect(page.locator('[data-testid="processing-spinner"]')).toBeVisible();
            await expect(page.locator('[data-testid="processing-spinner"]')).toBeHidden({
                timeout: 10000
            });
        });
        
        // Step 6: Verify order confirmation
        await test.step('Verify order confirmation', async () => {
            // Should redirect to confirmation page
            await page.waitForURL('**/order-confirmation/**');
            
            // Verify order details
            await expect(page.locator('[data-testid="order-number"]')).toBeVisible();
            const orderNumber = await page.locator('[data-testid="order-number"]').textContent();
            expect(orderNumber).toMatch(/^ORD-\d{10}$/);
            
            // Verify email sent
            await expect(page.locator('[data-testid="email-confirmation"]')).toContainText(
                `Confirmation email sent to ${user.email}`
            );
            
            // Verify order in database
            const order = await testData.getOrder(orderNumber);
            expect(order.status).toBe('CONFIRMED');
            expect(order.items).toHaveLength(products.length);
        });
    });
    
    test('should handle payment failure gracefully', async () => {
        // Configure payment mock to fail
        paymentMock.setResponse('decline');
        
        // ... perform checkout steps until payment ...
        
        await test.step('Handle payment failure', async () => {
            await page.click('[data-testid="place-order"]');
            
            // Should show error message
            await expect(page.locator('[data-testid="payment-error"]')).toContainText(
                'Payment declined. Please try a different payment method.'
            );
            
            // Should remain on payment page
            expect(page.url()).toContain('/checkout/payment');
            
            // Cart should still contain items
            const cartCount = await page.locator('[data-testid="cart-count"]').textContent();
            expect(parseInt(cartCount)).toBeGreaterThan(0);
        });
    });
});
```

### Mobile Application E2E Tests (Appium + WebdriverIO)
```typescript
// mobile-app-onboarding.e2e.test.ts
import { remote } from 'webdriverio';
import { expect } from 'chai';

describe('Mobile App Onboarding Flow', () => {
    let driver: WebdriverIO.Browser;
    
    before(async () => {
        driver = await remote({
            port: 4723,
            path: '/wd/hub',
            capabilities: {
                platformName: 'iOS',
                platformVersion: '15.0',
                deviceName: 'iPhone 13',
                app: process.env.IOS_APP_PATH,
                automationName: 'XCUITest',
                noReset: false
            }
        });
        
        // Wait for app to load
        await driver.pause(3000);
    });
    
    after(async () => {
        await driver.deleteSession();
    });
    
    it('should complete onboarding flow', async () => {
        // Step 1: Welcome screen
        const welcomeTitle = await driver.$('~welcome-title');
        await expect(await welcomeTitle.getText()).to.equal('Welcome to MyApp');
        
        const getStartedButton = await driver.$('~get-started-button');
        await getStartedButton.click();
        
        // Step 2: Permissions
        await driver.pause(1000);
        
        // Handle notification permission
        const allowNotifications = await driver.$('~Allow');
        if (await allowNotifications.isExisting()) {
            await allowNotifications.click();
        }
        
        // Handle location permission
        const allowLocation = await driver.$('~Allow While Using App');
        if (await allowLocation.isExisting()) {
            await allowLocation.click();
        }
        
        // Step 3: Create account
        const emailField = await driver.$('~email-input');
        await emailField.setValue('test@example.com');
        
        const passwordField = await driver.$('~password-input');
        await passwordField.setValue('SecurePass123!');
        
        const createAccountButton = await driver.$('~create-account-button');
        await createAccountButton.click();
        
        // Wait for account creation
        await driver.waitUntil(
            async () => {
                const homeScreen = await driver.$('~home-screen');
                return await homeScreen.isDisplayed();
            },
            {
                timeout: 10000,
                timeoutMsg: 'Home screen did not appear after account creation'
            }
        );
        
        // Verify user is logged in
        const profileButton = await driver.$('~profile-button');
        await profileButton.click();
        
        const userEmail = await driver.$('~user-email');
        await expect(await userEmail.getText()).to.equal('test@example.com');
    });
    
    it('should handle offline mode during onboarding', async () => {
        // Enable airplane mode
        await driver.toggleAirplaneMode();
        
        try {
            // Attempt to create account
            const createAccountButton = await driver.$('~create-account-button');
            await createAccountButton.click();
            
            // Should show offline message
            const offlineMessage = await driver.$('~offline-message');
            await expect(await offlineMessage.getText()).to.contain('No internet connection');
            
            // Should allow offline mode
            const continueOfflineButton = await driver.$('~continue-offline-button');
            await continueOfflineButton.click();
            
            // Should reach limited home screen
            const homeScreen = await driver.$('~home-screen');
            await expect(await homeScreen.isDisplayed()).to.be.true;
            
            const syncBanner = await driver.$('~sync-pending-banner');
            await expect(await syncBanner.isDisplayed()).to.be.true;
            
        } finally {
            // Disable airplane mode
            await driver.toggleAirplaneMode();
        }
    });
});
```

### API-Driven E2E Tests (Cypress)
```javascript
// api-workflow.e2e.cy.js
describe('API Workflow E2E Tests', () => {
    let authToken;
    let userId;
    
    before(() => {
        // Clean up test data
        cy.task('db:seed');
    });
    
    after(() => {
        cy.task('db:cleanup');
    });
    
    it('should complete user journey from registration to first purchase', () => {
        // Step 1: User Registration
        cy.request('POST', '/api/auth/register', {
            email: 'newuser@example.com',
            password: 'SecurePass123!',
            name: 'New User'
        }).then((response) => {
            expect(response.status).to.eq(201);
            expect(response.body).to.have.property('user');
            expect(response.body).to.have.property('token');
            
            authToken = response.body.token;
            userId = response.body.user.id;
            
            // Verify email verification sent
            cy.task('email:check', 'newuser@example.com').then((emails) => {
                expect(emails).to.have.length(1);
                expect(emails[0].subject).to.contain('Verify your email');
            });
        });
        
        // Step 2: Email Verification
        cy.task('email:getVerificationLink', 'newuser@example.com').then((link) => {
            cy.request('GET', link).then((response) => {
                expect(response.status).to.eq(200);
                expect(response.body.message).to.eq('Email verified successfully');
            });
        });
        
        // Step 3: Update Profile
        cy.request({
            method: 'PUT',
            url: `/api/users/${userId}/profile`,
            headers: {
                Authorization: `Bearer ${authToken}`
            },
            body: {
                phoneNumber: '+1234567890',
                address: {
                    street: '123 Main St',
                    city: 'New York',
                    state: 'NY',
                    zip: '10001'
                }
            }
        }).then((response) => {
            expect(response.status).to.eq(200);
            expect(response.body.phoneNumber).to.eq('+1234567890');
        });
        
        // Step 4: Browse Products
        cy.request('GET', '/api/products?category=electronics').then((response) => {
            expect(response.status).to.eq(200);
            expect(response.body.products).to.have.length.greaterThan(0);
            
            const product = response.body.products[0];
            
            // Step 5: Add to Cart
            cy.request({
                method: 'POST',
                url: '/api/cart/items',
                headers: {
                    Authorization: `Bearer ${authToken}`
                },
                body: {
                    productId: product.id,
                    quantity: 2
                }
            }).then((response) => {
                expect(response.status).to.eq(201);
                expect(response.body.items).to.have.length(1);
                expect(response.body.total).to.eq(product.price * 2);
            });
        });
        
        // Step 6: Checkout
        cy.request({
            method: 'POST',
            url: '/api/orders',
            headers: {
                Authorization: `Bearer ${authToken}`
            },
            body: {
                paymentMethod: 'credit_card',
                paymentDetails: {
                    cardNumber: '4242424242424242',
                    expiryMonth: '12',
                    expiryYear: '2025',
                    cvv: '123'
                }
            }
        }).then((response) => {
            expect(response.status).to.eq(201);
            expect(response.body.status).to.eq('confirmed');
            expect(response.body.orderId).to.match(/^ORD-/);
            
            const orderId = response.body.orderId;
            
            // Step 7: Verify Order Status
            cy.request({
                method: 'GET',
                url: `/api/orders/${orderId}`,
                headers: {
                    Authorization: `Bearer ${authToken}`
                }
            }).then((response) => {
                expect(response.status).to.eq(200);
                expect(response.body.status).to.eq('processing');
                expect(response.body.tracking).to.have.property('number');
            });
            
            // Verify order confirmation email
            cy.task('email:check', 'newuser@example.com').then((emails) => {
                const orderEmail = emails.find(e => e.subject.includes('Order Confirmation'));
                expect(orderEmail).to.exist;
                expect(orderEmail.body).to.contain(orderId);
            });
        });
    });
});
```

### Cross-Browser E2E Tests
```typescript
// cross-browser.e2e.test.ts
import { test, expect, devices } from '@playwright/test';

// Define browsers and devices to test
const browsers = ['chromium', 'firefox', 'webkit'];
const testDevices = [
    { name: 'Desktop Chrome', device: null },
    { name: 'iPhone 12', device: devices['iPhone 12'] },
    { name: 'Pixel 5', device: devices['Pixel 5'] },
    { name: 'iPad Pro', device: devices['iPad Pro'] }
];

testDevices.forEach(({ name, device }) => {
    test.describe(`Critical User Flows - ${name}`, () => {
        test.use(device || {});
        
        test('should work across all browsers and devices', async ({ page, browserName }) => {
            await page.goto('/');
            
            // Visual regression test
            await expect(page).toHaveScreenshot(`homepage-${name}-${browserName}.png`, {
                fullPage: true,
                animations: 'disabled'
            });
            
            // Test responsive navigation
            if (device?.isMobile) {
                // Mobile navigation
                await page.click('[data-testid="mobile-menu-toggle"]');
                await expect(page.locator('[data-testid="mobile-menu"]')).toBeVisible();
            } else {
                // Desktop navigation
                await expect(page.locator('[data-testid="desktop-nav"]')).toBeVisible();
            }
            
            // Test critical functionality
            await page.click('[data-testid="search-trigger"]');
            await page.fill('[data-testid="search-input"]', 'test product');
            await page.press('[data-testid="search-input"]', 'Enter');
            
            // Verify search results
            await expect(page.locator('[data-testid="search-results"]')).toBeVisible();
            await expect(page.locator('[data-testid="result-item"]')).toHaveCount(10);
        });
    });
});
```

## Advanced E2E Testing Patterns

### Data-Driven E2E Tests
```typescript
// data-driven-e2e.test.ts
interface TestScenario {
    name: string;
    userData: UserData;
    products: ProductData[];
    expectedOutcome: string;
    paymentMethod: PaymentMethod;
}

const testScenarios: TestScenario[] = [
    {
        name: 'Standard user with credit card',
        userData: { type: 'standard', location: 'US' },
        products: [{ category: 'electronics', priceRange: 'medium' }],
        expectedOutcome: 'success',
        paymentMethod: 'credit_card'
    },
    {
        name: 'Premium user with PayPal',
        userData: { type: 'premium', location: 'EU' },
        products: [{ category: 'luxury', priceRange: 'high' }],
        expectedOutcome: 'success',
        paymentMethod: 'paypal'
    },
    {
        name: 'Restricted user attempt',
        userData: { type: 'restricted', location: 'US' },
        products: [{ category: 'restricted', priceRange: 'any' }],
        expectedOutcome: 'blocked',
        paymentMethod: 'credit_card'
    }
];

testScenarios.forEach((scenario) => {
    test(`E2E: ${scenario.name}`, async ({ page }) => {
        // Create test data based on scenario
        const user = await TestDataFactory.createUser(scenario.userData);
        const products = await TestDataFactory.createProducts(scenario.products);
        
        // Login
        await loginAs(page, user);
        
        // Execute purchase flow
        for (const product of products) {
            await addToCart(page, product);
        }
        
        // Checkout with specified payment method
        await checkout(page, scenario.paymentMethod);
        
        // Verify expected outcome
        if (scenario.expectedOutcome === 'success') {
            await expect(page).toHaveURL(/order-confirmation/);
        } else if (scenario.expectedOutcome === 'blocked') {
            await expect(page.locator('[data-testid="error-message"]'))
                .toContainText('Purchase not allowed');
        }
    });
});
```

### Performance Monitoring in E2E Tests
```javascript
// performance-e2e.cy.js
describe('E2E Performance Tests', () => {
    it('should meet performance budgets throughout user journey', () => {
        // Start performance recording
        cy.startPerformanceRecording();
        
        // Homepage load
        cy.visit('/');
        cy.checkPerformanceMetrics({
            'first-contentful-paint': 1500,
            'largest-contentful-paint': 2500,
            'time-to-interactive': 3500,
            'cumulative-layout-shift': 0.1
        });
        
        // Search interaction
        cy.get('[data-testid="search-input"]').type('laptop');
        cy.get('[data-testid="search-submit"]').click();
        
        // Measure search response time
        cy.checkApiResponseTime('/api/search', 500);
        
        // Product page
        cy.get('[data-testid="product-link"]').first().click();
        cy.checkPerformanceMetrics({
            'time-to-interactive': 2000
        });
        
        // Add to cart interaction
        cy.intercept('POST', '/api/cart/items').as('addToCart');
        cy.get('[data-testid="add-to-cart"]').click();
        cy.wait('@addToCart').then((interception) => {
            expect(interception.response.duration).to.be.lessThan(300);
        });
        
        // Generate performance report
        cy.generatePerformanceReport();
    });
});
```

### Security Testing in E2E
```python
# security-e2e.test.py
import pytest
from selenium import webdriver
from selenium.webdriver.common.by import By
import time

class TestSecurityE2E:
    
    def test_authentication_security_flow(self, driver):
        """Test security aspects of authentication flow"""
        driver.get(f"{BASE_URL}/login")
        
        # Test 1: Password field should mask input
        password_field = driver.find_element(By.ID, "password")
        assert password_field.get_attribute("type") == "password"
        
        # Test 2: Brute force protection
        for attempt in range(5):
            driver.find_element(By.ID, "email").send_keys("test@example.com")
            driver.find_element(By.ID, "password").send_keys("wrong_password")
            driver.find_element(By.ID, "login-submit").click()
            time.sleep(1)
        
        # Should show account locked message
        error_message = driver.find_element(By.CLASS_NAME, "error-message")
        assert "account has been temporarily locked" in error_message.text.lower()
        
        # Test 3: Session management
        # Login with valid credentials
        driver.delete_all_cookies()
        driver.get(f"{BASE_URL}/login")
        self.login_valid_user(driver)
        
        # Save session cookie
        session_cookie = driver.get_cookie("session_id")
        assert session_cookie is not None
        assert session_cookie.get("httpOnly") is True
        assert session_cookie.get("secure") is True
        
        # Test 4: CSRF protection
        driver.get(f"{BASE_URL}/profile")
        csrf_token = driver.find_element(By.NAME, "csrf_token").get_attribute("value")
        assert len(csrf_token) > 20
        
        # Test 5: XSS prevention
        driver.get(f"{BASE_URL}/search?q=<script>alert('xss')</script>")
        # Verify script is not executed
        assert not self.is_alert_present(driver)
        # Verify input is escaped in display
        search_display = driver.find_element(By.ID, "search-query-display")
        assert "&lt;script&gt;" in search_display.get_attribute("innerHTML")
```

### Multi-System E2E Tests
```typescript
// multi-system-e2e.test.ts
test.describe('Multi-System Integration E2E', () => {
    let mainApp: Page;
    let adminPortal: Page;
    let mobileApp: WebdriverIO.Browser;
    let emailService: EmailService;
    let smsService: SMSService;
    
    test('should sync data across all systems', async ({ browser }) => {
        // Initialize all systems
        mainApp = await browser.newPage();
        adminPortal = await browser.newPage();
        mobileApp = await initializeMobileApp();
        emailService = new EmailService();
        smsService = new SMSService();
        
        // Step 1: Create order in main app
        await mainApp.goto(MAIN_APP_URL);
        const orderData = await createOrder(mainApp);
        
        // Step 2: Verify order appears in admin portal
        await adminPortal.goto(ADMIN_PORTAL_URL);
        await adminLogin(adminPortal);
        await adminPortal.goto(`${ADMIN_PORTAL_URL}/orders`);
        
        await expect(adminPortal.locator(`[data-order-id="${orderData.id}"]`))
            .toBeVisible({ timeout: 10000 });
        
        // Step 3: Update order status in admin
        await adminPortal.click(`[data-order-id="${orderData.id}"] [data-action="ship"]`);
        await adminPortal.fill('[data-testid="tracking-number"]', 'TRACK123456');
        await adminPortal.click('[data-testid="confirm-shipment"]');
        
        // Step 4: Verify customer receives notifications
        // Check email
        const emails = await emailService.getEmails(orderData.customerEmail);
        const shipmentEmail = emails.find(e => e.subject.includes('shipped'));
        expect(shipmentEmail).toBeDefined();
        expect(shipmentEmail.body).toContain('TRACK123456');
        
        // Check SMS
        const smsMessages = await smsService.getMessages(orderData.customerPhone);
        expect(smsMessages).toContainEqual(
            expect.objectContaining({
                body: expect.stringContaining('Your order has been shipped')
            })
        );
        
        // Step 5: Verify update in mobile app
        await mobileApp.execute('mobile: launchApp');
        await mobileApp.$('~orders-tab').click();
        
        const orderElement = await mobileApp.$(`~order-${orderData.id}`);
        await expect(await orderElement.$('~order-status').getText()).toBe('Shipped');
        await expect(await orderElement.$('~tracking-number').getText()).toBe('TRACK123456');
        
        // Step 6: Verify real-time sync
        await mainApp.reload();
        await mainApp.goto(`${MAIN_APP_URL}/orders/${orderData.id}`);
        await expect(mainApp.locator('[data-testid="order-status"]')).toHaveText('Shipped');
        
        // Step 7: Test webhook delivery
        const webhookLogs = await getWebhookLogs(orderData.id);
        expect(webhookLogs).toContainEqual(
            expect.objectContaining({
                event: 'order.shipped',
                status: 'delivered',
                attempts: 1
            })
        );
    });
});
```

## E2E Test Environment Management

### Test Environment Configuration
```typescript
// environments.config.ts
export const environments = {
    local: {
        baseUrl: 'http://localhost:3000',
        apiUrl: 'http://localhost:3001/api',
        database: 'postgresql://localhost/test_db',
        redis: 'redis://localhost:6379',
        features: {
            payments: true,
            notifications: true,
            analytics: false
        }
    },
    staging: {
        baseUrl: 'https://staging.example.com',
        apiUrl: 'https://api-staging.example.com',
        database: process.env.STAGING_DB_URL,
        redis: process.env.STAGING_REDIS_URL,
        features: {
            payments: true,
            notifications: true,
            analytics: true
        }
    },
    production: {
        baseUrl: 'https://www.example.com',
        apiUrl: 'https://api.example.com',
        database: process.env.PROD_DB_URL,
        redis: process.env.PROD_REDIS_URL,
        features: {
            payments: true,
            notifications: true,
            analytics: true
        }
    }
};

// Helper to get current environment
export function getEnvironment(): Environment {
    const env = process.env.E2E_ENV || 'local';
    return environments[env];
}
```

### Parallel Execution Strategy
```yaml
# .circleci/config.yml
version: 2.1

jobs:
  e2e-tests:
    parallelism: 4
    docker:
      - image: mcr.microsoft.com/playwright:v1.25.0-focal
    steps:
      - checkout
      - run:
          name: Install dependencies
          command: npm ci
      
      - run:
          name: Split tests
          command: |
            TESTFILES=$(circleci tests glob "e2e/**/*.test.ts" | circleci tests split --split-by=timings)
            echo $TESTFILES > /tmp/tests-to-run.txt
      
      - run:
          name: Run E2E tests
          command: |
            TESTFILES=$(cat /tmp/tests-to-run.txt)
            npm run test:e2e -- $TESTFILES
      
      - store_test_results:
          path: test-results
      
      - store_artifacts:
          path: screenshots
          destination: screenshots

workflows:
  test:
    jobs:
      - e2e-tests:
          matrix:
            parameters:
              browser: ["chromium", "firefox", "webkit"]
```

## Best Practices for E2E Tests

### Test Isolation
```typescript
// test-isolation.ts
export class TestIsolation {
    static async createIsolatedEnvironment(): Promise<TestEnvironment> {
        // Create unique namespace for this test run
        const testId = `test_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        
        // Create isolated database schema
        const dbSchema = await createTestSchema(testId);
        
        // Create isolated message queues
        const queues = await createTestQueues(testId);
        
        // Create isolated storage buckets
        const storage = await createTestStorage(testId);
        
        // Create test users with unique emails
        const users = await createTestUsers(testId);
        
        return {
            testId,
            dbSchema,
            queues,
            storage,
            users,
            cleanup: async () => {
                await dropTestSchema(testId);
                await deleteTestQueues(testId);
                await deleteTestStorage(testId);
                await deleteTestUsers(testId);
            }
        };
    }
}

// Usage in tests
test.beforeEach(async () => {
    testEnv = await TestIsolation.createIsolatedEnvironment();
});

test.afterEach(async () => {
    await testEnv.cleanup();
});
```

### Retry and Recovery Strategies
```typescript
// retry-strategies.ts
export async function withRetry<T>(
    fn: () => Promise<T>,
    options: {
        maxAttempts?: number;
        delay?: number;
        backoff?: boolean;
        onRetry?: (attempt: number, error: Error) => void;
    } = {}
): Promise<T> {
    const { 
        maxAttempts = 3, 
        delay = 1000, 
        backoff = true,
        onRetry 
    } = options;
    
    let lastError: Error;
    
    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
            return await fn();
        } catch (error) {
            lastError = error;
            
            if (attempt < maxAttempts) {
                const waitTime = backoff ? delay * Math.pow(2, attempt - 1) : delay;
                
                if (onRetry) {
                    onRetry(attempt, error);
                }
                
                await new Promise(resolve => setTimeout(resolve, waitTime));
            }
        }
    }
    
    throw lastError;
}

// Usage in E2E tests
await withRetry(
    async () => {
        await page.click('[data-testid="flaky-button"]');
        await expect(page.locator('[data-testid="success-message"]')).toBeVisible();
    },
    {
        maxAttempts: 3,
        delay: 2000,
        onRetry: (attempt, error) => {
            console.log(`Retry attempt ${attempt} due to: ${error.message}`);
        }
    }
);
```

This E2E test template provides comprehensive patterns for testing complete user workflows, ensuring your application works correctly from the user's perspective across all integrated systems and platforms.