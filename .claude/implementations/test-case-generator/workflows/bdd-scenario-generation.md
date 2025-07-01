# BDD Scenario Generation Workflow

## Overview
This workflow specializes in generating Behavior-Driven Development (BDD) scenarios from user stories, requirements, or existing test cases. It produces Gherkin-formatted feature files ready for automation frameworks like Cucumber, SpecFlow, or Behave.

## Workflow Purpose

### Key Benefits
- **Business-Readable Tests**: Scenarios written in plain English that stakeholders can understand
- **Living Documentation**: Tests serve as always-current system documentation
- **Collaboration Bridge**: Shared understanding between business, development, and QA teams
- **Automation-Ready**: Direct integration with BDD frameworks for immediate test execution
- **Requirement Traceability**: Clear mapping from requirements to executable scenarios

## Agent Coordination Architecture

### Multi-Agent BDD Generation System
```yaml
orchestrator:
  name: "BDD Orchestrator"
  role: "Coordinate scenario generation across multiple agents"
  responsibilities:
    - Analyze input requirements
    - Distribute work to specialized agents
    - Ensure consistency across generated scenarios
    - Manage feature file organization

specialized_agents:
  requirement_analyzer:
    role: "Extract testable behaviors from requirements"
    outputs:
      - Behavioral specifications
      - Acceptance criteria mapping
      - Test boundaries and constraints
  
  scenario_writer:
    role: "Convert behaviors into Gherkin scenarios"
    outputs:
      - Feature files with scenarios
      - Background contexts
      - Scenario outlines
  
  data_generator:
    role: "Create test data and examples"
    outputs:
      - Examples tables
      - Test data fixtures
      - Edge case datasets
  
  step_architect:
    role: "Design reusable step definitions"
    outputs:
      - Step definition templates
      - Page object patterns
      - Helper utilities
```

## Workflow Stages

### Stage 1: Requirement Analysis & Behavior Extraction
**Duration**: 10-15 minutes
**Agents**: Requirement Analyzer, Domain Expert
**Process**: Deep analysis of requirements to extract testable behaviors

```bash
# Analyze requirements with domain context
./claude-flow swarm "Analyze requirements for BDD scenarios" \
  --strategy analysis \
  --mode hierarchical \
  --agents "requirement_analyzer,domain_expert" \
  --memory-key "bdd_requirements"
```

### Stage 2: Feature Mapping & Organization
**Duration**: 10-15 minutes
**Agents**: BDD Orchestrator, Scenario Writer
**Process**: Organize scenarios into logical feature files with proper structure

```bash
# Create feature file structure
./claude-flow sparc run architect \
  "Design feature file organization from behavioral requirements"

# Generate feature mapping
./claude-flow memory store "feature_structure" \
  "$(cat feature-organization.json)"
```

### Stage 3: Scenario Generation & Detailing
**Duration**: 20-30 minutes
**Agents**: Scenario Writer, Test Designer
**Process**: Generate comprehensive Given-When-Then scenarios

```bash
# Generate detailed scenarios with parallel processing
./claude-flow swarm "Generate BDD scenarios for all features" \
  --strategy development \
  --mode distributed \
  --parallel \
  --agents "scenario_writer,test_designer,edge_case_finder" \
  --output "features/"
```

### Stage 4: Data Generation & Examples
**Duration**: 15-20 minutes
**Agents**: Data Generator, Test Data Specialist
**Process**: Create comprehensive test data and example tables

```bash
# Generate test data and examples
./claude-flow task create data-generation \
  "Create example tables and test datasets for all scenario outlines"

# Validate data coverage
./claude-flow sparc "Validate test data covers all edge cases and boundaries"
```

### Stage 5: Step Definition Generation
**Duration**: 15-20 minutes
**Agents**: Step Architect, Framework Specialist
**Process**: Generate framework-specific step definition stubs

```bash
# Generate step definitions for chosen framework
./claude-flow agent spawn step-generator \
  --framework "cucumber-js" \
  --pattern "page-object" \
  --output "step-definitions/"
```

## Input Formats

### User Story Format
```markdown
## User Story: Shopping Cart Management

**As a** registered customer
**I want to** manage items in my shopping cart
**So that** I can purchase multiple products in one transaction

### Acceptance Criteria
- I can add items to my cart from product pages
- I can update item quantities (1-99 per item)
- I can remove items from my cart
- Cart persists between sessions for logged-in users
- Cart shows real-time total price including tax
- Cart validates stock availability before checkout

### Business Rules
- Maximum cart value: $10,000
- Cart expires after 30 days of inactivity
- Promotional items limited to 1 per customer
- Free shipping on orders over $50
```

### Structured Requirements Format
```yaml
feature: Shopping Cart Management
epic: E-Commerce Platform
priority: high

requirements:
  - id: CART-001
    title: "Add items to cart"
    description: "Users can add products to shopping cart"
    acceptance_criteria:
      - "Item must be in stock"
      - "Maximum 99 items per product"
      - "Cart updates immediately"
      - "Show success confirmation"
    business_rules:
      - rule: "Stock validation"
        condition: "quantity <= available_stock"
        error: "Insufficient stock available"
      - rule: "Quantity limit"
        condition: "quantity <= 99"
        error: "Maximum 99 items allowed"
    test_data:
      valid:
        - product_id: "LAPTOP-001"
          quantity: 1
          expected: "success"
        - product_id: "MOUSE-002"
          quantity: 5
          expected: "success"
      invalid:
        - product_id: "LAPTOP-001"
          quantity: 100
          expected: "error: quantity_limit"
        - product_id: "OUT-OF-STOCK"
          quantity: 1
          expected: "error: no_stock"
```

### Domain Model Format
```json
{
  "domain": "e-commerce",
  "entities": {
    "Cart": {
      "attributes": ["id", "user_id", "items", "total", "created_at", "updated_at"],
      "operations": ["add_item", "remove_item", "update_quantity", "clear", "calculate_total"],
      "states": ["active", "abandoned", "converted"]
    },
    "CartItem": {
      "attributes": ["product_id", "quantity", "price", "subtotal"],
      "validations": ["quantity_range", "price_positive", "product_exists"]
    }
  },
  "workflows": {
    "checkout": ["validate_cart", "check_stock", "calculate_shipping", "process_payment", "create_order"]
  }
}
```

## Output Examples

### 1. Comprehensive Feature File (shopping-cart.feature)
```gherkin
@cart @e-commerce
Feature: Shopping Cart Management
  As a registered customer
  I want to manage items in my shopping cart
  So that I can purchase multiple products in one transaction

  Background:
    Given I am logged in as "customer@example.com"
    And the following products exist in the catalog:
      | id   | name           | price  | stock | category    | promotional |
      | L001 | Gaming Laptop  | 999.99 | 10    | Electronics | false       |
      | M002 | Wireless Mouse | 29.99  | 50    | Accessories | false       |
      | K003 | RGB Keyboard   | 79.99  | 25    | Accessories | false       |
      | P004 | Promo Headset  | 49.99  | 5     | Accessories | true        |
    And tax rate is "8%" for "Electronics"
    And tax rate is "6%" for "Accessories"
    And free shipping threshold is "$50.00"

  # Happy Path Scenarios
  @smoke @happy-path
  Scenario: Add single item to empty cart
    Given my shopping cart is empty
    When I add 1 "Gaming Laptop" to my cart
    Then my cart should contain 1 item
    And the cart should show:
      | Product       | Quantity | Unit Price | Subtotal   |
      | Gaming Laptop | 1        | $999.99    | $999.99    |
    And the cart summary should show:
      | Subtotal | $999.99 |
      | Tax      | $80.00  |
      | Shipping | $0.00   |
      | Total    | $1,079.99 |
    And I should see "Gaming Laptop added to cart" notification

  @cart @validation @edge-case
  Scenario: Add item exceeding stock
    Given my shopping cart is empty
    And "Gaming Laptop" has 2 items in stock
    When I try to add 3 "Gaming Laptop" to my cart
    Then I should see error "Only 2 items available in stock"
    And my cart should remain empty
    And the add to cart button should show "Limited Stock"

  @cart @business-rule
  Scenario: Promotional item quantity limit
    Given my shopping cart is empty
    And "Promo Headset" is a promotional item limited to 1 per customer
    When I add 1 "Promo Headset" to my cart
    And I try to add 1 more "Promo Headset" to my cart
    Then I should see error "Promotional items limited to 1 per customer"
    And my cart should contain only 1 "Promo Headset"

  @cart @calculation
  Scenario Outline: Add multiple items with tax calculation
    Given my shopping cart is empty
    When I add <quantity> "<product>" to my cart
    Then my cart should contain <quantity> items
    And the subtotal should be "<subtotal>"
    And the tax should be "<tax>"
    And the total should be "<total>"

    Examples: Electronics with 8% tax
      | product       | quantity | subtotal   | tax     | total      |
      | Gaming Laptop | 1        | $999.99    | $80.00  | $1,079.99  |
      | Gaming Laptop | 2        | $1,999.98  | $160.00 | $2,159.98  |

    Examples: Accessories with 6% tax
      | product        | quantity | subtotal | tax    | total   |
      | Wireless Mouse | 1        | $29.99   | $1.80  | $31.79  |
      | Wireless Mouse | 5        | $149.95  | $9.00  | $158.95 |
      | RGB Keyboard   | 2        | $159.98  | $9.60  | $169.58 |

  @cart @persistence @integration
  Scenario: Cart persists across sessions
    Given my cart contains:
      | product        | quantity |
      | Gaming Laptop  | 1        |
      | Wireless Mouse | 2        |
    When I log out
    And I wait 5 seconds
    And I log back in as "customer@example.com"
    Then my cart should still contain:
      | product        | quantity |
      | Gaming Laptop  | 1        |
      | Wireless Mouse | 2        |
    And the cart total should be "$1,143.77"

  @cart @update
  Scenario: Update item quantity in cart
    Given my cart contains:
      | product        | quantity |
      | Wireless Mouse | 2        |
    When I update "Wireless Mouse" quantity to 5
    Then my cart should show:
      | product        | quantity |
      | Wireless Mouse | 5        |
    And the cart total should be "$158.95"
    And I should see "Cart updated" notification

  @cart @removal
  Scenario: Remove item from cart
    Given my cart contains:
      | product        | quantity |
      | Gaming Laptop  | 1        |
      | Wireless Mouse | 2        |
    When I remove "Wireless Mouse" from my cart
    Then my cart should only contain:
      | product       | quantity |
      | Gaming Laptop | 1        |
    And I should see "Wireless Mouse removed from cart" notification

  @cart @shipping
  Scenario: Free shipping threshold
    Given my cart is empty
    And free shipping applies to orders over "$50.00"
    When I add 1 "Wireless Mouse" to my cart
    Then the shipping cost should be "$5.99"
    When I add 1 "RGB Keyboard" to my cart
    Then the shipping cost should be "$0.00"
    And I should see "Free shipping applied!" message

  @cart @expiry @scheduled
  Scenario: Cart expiration after inactivity
    Given my cart contains items added 29 days ago
    When I view my cart
    Then I should see "Your cart will expire in 1 day" warning
    When I wait 2 days without activity
    And I view my cart
    Then my cart should be empty
    And I should see "Your cart has expired due to inactivity" message
```

### 2. Framework-Specific Step Definitions

#### Cucumber.js Step Definitions
```javascript
// step-definitions/shopping-cart.steps.js
const { Given, When, Then, Before, After } = require('@cucumber/cucumber');
const { expect } = require('chai');
const { CartPage } = require('../pages/cart.page');
const { ProductPage } = require('../pages/product.page');
const { LoginPage } = require('../pages/login.page');

// Hook for setup
Before(async function() {
  this.cart = new CartPage(this.driver);
  this.product = new ProductPage(this.driver);
  this.login = new LoginPage(this.driver);
});

// Background steps
Given('I am logged in as {string}', async function(email) {
  await this.login.navigateToLogin();
  await this.login.login(email, process.env.TEST_PASSWORD);
  await this.login.verifyLoggedIn(email);
});

Given('the following products exist in the catalog:', async function(dataTable) {
  // Convert data table to array of products
  const products = dataTable.hashes();
  
  // Store in test context for later use
  this.testData.products = products;
  
  // Verify products in database or mock as needed
  for (const product of products) {
    await this.product.verifyProductExists(product);
  }
});

Given('tax rate is {string} for {string}', async function(rate, category) {
  this.testData.taxRates = this.testData.taxRates || {};
  this.testData.taxRates[category] = parseFloat(rate.replace('%', '')) / 100;
});

// Cart state steps
Given('my shopping cart is empty', async function() {
  await this.cart.navigateToCart();
  await this.cart.clearCart();
  const itemCount = await this.cart.getItemCount();
  expect(itemCount).to.equal(0);
});

Given('my cart contains:', async function(dataTable) {
  await this.cart.clearCart();
  const items = dataTable.hashes();
  
  for (const item of items) {
    await this.product.searchProduct(item.product);
    await this.product.addToCart(item.product, parseInt(item.quantity));
  }
});

// Action steps
When('I add {int} {string} to my cart', async function(quantity, productName) {
  await this.product.searchProduct(productName);
  await this.product.addToCart(productName, quantity);
  this.lastAction = { type: 'add', product: productName, quantity };
});

When('I try to add {int} {string} to my cart', async function(quantity, productName) {
  try {
    await this.product.searchProduct(productName);
    await this.product.addToCart(productName, quantity);
    this.lastActionFailed = false;
  } catch (error) {
    this.lastError = error.message;
    this.lastActionFailed = true;
  }
});

When('I update {string} quantity to {int}', async function(productName, newQuantity) {
  await this.cart.navigateToCart();
  await this.cart.updateQuantity(productName, newQuantity);
});

When('I remove {string} from my cart', async function(productName) {
  await this.cart.navigateToCart();
  await this.cart.removeItem(productName);
});

// Assertion steps
Then('my cart should contain {int} item(s)', async function(expectedCount) {
  const actualCount = await this.cart.getItemCount();
  expect(actualCount).to.equal(expectedCount);
});

Then('my cart should show:', async function(dataTable) {
  const expectedItems = dataTable.hashes();
  const actualItems = await this.cart.getCartItems();
  
  expect(actualItems).to.have.lengthOf(expectedItems.length);
  
  for (let i = 0; i < expectedItems.length; i++) {
    expect(actualItems[i]).to.deep.include(expectedItems[i]);
  }
});

Then('the cart summary should show:', async function(dataTable) {
  const expectedSummary = dataTable.rowsHash();
  const actualSummary = await this.cart.getCartSummary();
  
  for (const [field, expectedValue] of Object.entries(expectedSummary)) {
    expect(actualSummary[field]).to.equal(expectedValue);
  }
});

Then('I should see {string} notification', async function(message) {
  const notification = await this.cart.getNotification();
  expect(notification).to.equal(message);
});

Then('I should see error {string}', async function(errorMessage) {
  const error = await this.cart.getErrorMessage();
  expect(error).to.equal(errorMessage);
});
```

#### SpecFlow (C#) Step Definitions
```csharp
// StepDefinitions/ShoppingCartSteps.cs
using System;
using System.Collections.Generic;
using System.Linq;
using TechTalk.SpecFlow;
using TechTalk.SpecFlow.Assist;
using NUnit.Framework;
using ShoppingCart.Pages;
using ShoppingCart.Models;

namespace ShoppingCart.StepDefinitions
{
    [Binding]
    public class ShoppingCartSteps
    {
        private readonly ScenarioContext _scenarioContext;
        private readonly CartPage _cartPage;
        private readonly ProductPage _productPage;
        private readonly LoginPage _loginPage;
        private Dictionary<string, decimal> _taxRates;

        public ShoppingCartSteps(ScenarioContext scenarioContext)
        {
            _scenarioContext = scenarioContext;
            _cartPage = new CartPage();
            _productPage = new ProductPage();
            _loginPage = new LoginPage();
            _taxRates = new Dictionary<string, decimal>();
        }

        [Given(@"I am logged in as ""(.*)""")]
        public async Task GivenIAmLoggedInAs(string email)
        {
            await _loginPage.NavigateToLogin();
            await _loginPage.Login(email, Environment.GetEnvironmentVariable("TEST_PASSWORD"));
            await _loginPage.VerifyLoggedIn(email);
        }

        [Given(@"the following products exist in the catalog:")]
        public async Task GivenTheFollowingProductsExist(Table table)
        {
            var products = table.CreateSet<Product>().ToList();
            _scenarioContext["products"] = products;
            
            foreach (var product in products)
            {
                await _productPage.VerifyProductExists(product);
            }
        }

        [Given(@"tax rate is ""(.*)"" for ""(.*)""")]
        public void GivenTaxRateIsFor(string rate, string category)
        {
            var rateValue = decimal.Parse(rate.Replace("%", "")) / 100;
            _taxRates[category] = rateValue;
            _scenarioContext["taxRates"] = _taxRates;
        }

        [Given(@"my shopping cart is empty")]
        public async Task GivenMyShoppingCartIsEmpty()
        {
            await _cartPage.NavigateToCart();
            await _cartPage.ClearCart();
            var itemCount = await _cartPage.GetItemCount();
            Assert.AreEqual(0, itemCount);
        }

        [Given(@"my cart contains:")]
        public async Task GivenMyCartContains(Table table)
        {
            await _cartPage.ClearCart();
            var items = table.CreateSet<CartItem>().ToList();
            
            foreach (var item in items)
            {
                await _productPage.SearchProduct(item.Product);
                await _productPage.AddToCart(item.Product, item.Quantity);
            }
        }

        [When(@"I add (.*) ""(.*)"" to my cart")]
        public async Task WhenIAddToMyCart(int quantity, string productName)
        {
            await _productPage.SearchProduct(productName);
            await _productPage.AddToCart(productName, quantity);
            _scenarioContext["lastAction"] = new { Type = "add", Product = productName, Quantity = quantity };
        }

        [When(@"I try to add (.*) ""(.*)"" to my cart")]
        public async Task WhenITryToAddToMyCart(int quantity, string productName)
        {
            try
            {
                await _productPage.SearchProduct(productName);
                await _productPage.AddToCart(productName, quantity);
                _scenarioContext["lastActionFailed"] = false;
            }
            catch (Exception ex)
            {
                _scenarioContext["lastError"] = ex.Message;
                _scenarioContext["lastActionFailed"] = true;
            }
        }

        [Then(@"my cart should contain (.*) items?")]
        public async Task ThenMyCartShouldContainItems(int expectedCount)
        {
            var actualCount = await _cartPage.GetItemCount();
            Assert.AreEqual(expectedCount, actualCount);
        }

        [Then(@"the cart should show:")]
        public async Task ThenTheCartShouldShow(Table table)
        {
            var expectedItems = table.CreateSet<CartItemDisplay>().ToList();
            var actualItems = await _cartPage.GetCartItems();
            
            Assert.AreEqual(expectedItems.Count, actualItems.Count);
            
            for (int i = 0; i < expectedItems.Count; i++)
            {
                Assert.AreEqual(expectedItems[i].Product, actualItems[i].Product);
                Assert.AreEqual(expectedItems[i].Quantity, actualItems[i].Quantity);
                Assert.AreEqual(expectedItems[i].UnitPrice, actualItems[i].UnitPrice);
                Assert.AreEqual(expectedItems[i].Subtotal, actualItems[i].Subtotal);
            }
        }

        [Then(@"I should see ""(.*)"" notification")]
        public async Task ThenIShouldSeeNotification(string message)
        {
            var notification = await _cartPage.GetNotification();
            Assert.AreEqual(message, notification);
        }

        [Then(@"I should see error ""(.*)""")]
        public async Task ThenIShouldSeeError(string errorMessage)
        {
            var error = await _cartPage.GetErrorMessage();
            Assert.AreEqual(errorMessage, error);
        }
    }
}
```

#### Behave (Python) Step Definitions
```python
# features/steps/shopping_cart.py
from behave import given, when, then
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from decimal import Decimal
import os

# Page objects
from pages.cart_page import CartPage
from pages.product_page import ProductPage
from pages.login_page import LoginPage

@given('I am logged in as "{email}"')
def step_login(context, email):
    context.login_page = LoginPage(context.driver)
    context.login_page.navigate_to_login()
    context.login_page.login(email, os.getenv('TEST_PASSWORD'))
    context.login_page.verify_logged_in(email)

@given('the following products exist in the catalog')
def step_products_exist(context):
    context.products = []
    for row in context.table:
        product = {
            'id': row['id'],
            'name': row['name'],
            'price': Decimal(row['price']),
            'stock': int(row['stock']),
            'category': row['category'],
            'promotional': row['promotional'] == 'true'
        }
        context.products.append(product)
        
        # Verify product exists (could be API call or DB check)
        context.product_page = ProductPage(context.driver)
        context.product_page.verify_product_exists(product)

@given('tax rate is "{rate}" for "{category}"')
def step_set_tax_rate(context, rate, category):
    if not hasattr(context, 'tax_rates'):
        context.tax_rates = {}
    
    rate_value = Decimal(rate.strip('%')) / 100
    context.tax_rates[category] = rate_value

@given('my shopping cart is empty')
def step_empty_cart(context):
    context.cart_page = CartPage(context.driver)
    context.cart_page.navigate_to_cart()
    context.cart_page.clear_cart()
    
    item_count = context.cart_page.get_item_count()
    assert item_count == 0, f"Expected empty cart but found {item_count} items"

@given('my cart contains')
def step_cart_contains(context):
    context.cart_page = CartPage(context.driver)
    context.cart_page.clear_cart()
    
    for row in context.table:
        product_name = row['product']
        quantity = int(row['quantity'])
        
        context.product_page.search_product(product_name)
        context.product_page.add_to_cart(product_name, quantity)

@when('I add {quantity:d} "{product_name}" to my cart')
def step_add_to_cart(context, quantity, product_name):
    context.product_page = ProductPage(context.driver)
    context.product_page.search_product(product_name)
    context.product_page.add_to_cart(product_name, quantity)
    
    context.last_action = {
        'type': 'add',
        'product': product_name,
        'quantity': quantity
    }

@when('I try to add {quantity:d} "{product_name}" to my cart')
def step_try_add_to_cart(context, quantity, product_name):
    context.product_page = ProductPage(context.driver)
    
    try:
        context.product_page.search_product(product_name)
        context.product_page.add_to_cart(product_name, quantity)
        context.last_action_failed = False
    except Exception as e:
        context.last_error = str(e)
        context.last_action_failed = True

@when('I update "{product_name}" quantity to {new_quantity:d}')
def step_update_quantity(context, product_name, new_quantity):
    context.cart_page.navigate_to_cart()
    context.cart_page.update_quantity(product_name, new_quantity)

@when('I remove "{product_name}" from my cart')
def step_remove_from_cart(context, product_name):
    context.cart_page.navigate_to_cart()
    context.cart_page.remove_item(product_name)

@then('my cart should contain {expected_count:d} item(s)')
def step_verify_item_count(context, expected_count):
    actual_count = context.cart_page.get_item_count()
    assert actual_count == expected_count, \
        f"Expected {expected_count} items but found {actual_count}"

@then('the cart should show')
def step_verify_cart_contents(context):
    actual_items = context.cart_page.get_cart_items()
    
    assert len(actual_items) == len(context.table.rows), \
        f"Expected {len(context.table.rows)} items but found {len(actual_items)}"
    
    for i, row in enumerate(context.table):
        expected = {
            'product': row['Product'],
            'quantity': int(row['Quantity']),
            'unit_price': row['Unit Price'],
            'subtotal': row['Subtotal']
        }
        
        actual = actual_items[i]
        for key, expected_value in expected.items():
            assert actual[key] == expected_value, \
                f"Mismatch in {key}: expected {expected_value}, got {actual[key]}"

@then('the cart summary should show')
def step_verify_cart_summary(context):
    actual_summary = context.cart_page.get_cart_summary()
    
    for row in context.table:
        field = row[0]
        expected_value = row[1]
        
        assert field in actual_summary, f"Summary field '{field}' not found"
        assert actual_summary[field] == expected_value, \
            f"Expected {field} to be {expected_value}, but got {actual_summary[field]}"

@then('I should see "{message}" notification')
def step_verify_notification(context, message):
    notification = context.cart_page.get_notification()
    assert notification == message, \
        f"Expected notification '{message}' but got '{notification}'"

@then('I should see error "{error_message}"')
def step_verify_error(context, error_message):
    error = context.cart_page.get_error_message()
    assert error == error_message, \
        f"Expected error '{error_message}' but got '{error}'"
```

### 3. Test Data Configuration

#### YAML Configuration
```yaml
# config/test-data.yaml
test_environment:
  base_url: "${BASE_URL:http://localhost:3000}"
  api_url: "${API_URL:http://localhost:3001/api}"
  timeout: 30

test_users:
  standard:
    email: "customer@example.com"
    password: "TestPass123!"
    type: "registered"
  
  premium:
    email: "premium@example.com"
    password: "PremiumPass456!"
    type: "premium"
    benefits:
      - "free_shipping"
      - "priority_support"
      - "exclusive_deals"
  
  guest:
    email: "guest@example.com"
    type: "guest"

test_products:
  electronics:
    - id: "L001"
      name: "Gaming Laptop"
      price: 999.99
      tax_category: "electronics"
      weight: 5.5
      dimensions: "15x10x1"
    
    - id: "T002"
      name: "4K Monitor"
      price: 499.99
      tax_category: "electronics"
      weight: 8.0
      dimensions: "24x16x3"
  
  accessories:
    - id: "M001"
      name: "Wireless Mouse"
      price: 29.99
      tax_category: "accessories"
      weight: 0.2
      dimensions: "4x2x1"
    
    - id: "K001"
      name: "RGB Keyboard"
      price: 79.99
      tax_category: "accessories"
      weight: 1.0
      dimensions: "18x6x1"

tax_configuration:
  rates:
    electronics: 0.08
    accessories: 0.06
    books: 0
    general: 0.07
  
  exemptions:
    - "educational_materials"
    - "medical_supplies"

shipping_rules:
  free_shipping_threshold: 50.00
  
  standard_shipping:
    base_rate: 5.99
    per_pound: 0.50
    estimated_days: 5-7
  
  express_shipping:
    base_rate: 14.99
    per_pound: 1.00
    estimated_days: 2-3
  
  overnight_shipping:
    base_rate: 29.99
    per_pound: 2.00
    estimated_days: 1

business_rules:
  cart:
    max_value: 10000.00
    max_items_per_product: 99
    expiry_days: 30
    
  promotions:
    max_promotional_items: 1
    coupon_stack_limit: 2
    
  inventory:
    low_stock_threshold: 5
    out_of_stock_behavior: "disable_add_to_cart"
```

#### JSON Test Data
```json
{
  "edge_cases": {
    "boundary_values": {
      "quantity": {
        "min": 0,
        "max": 99,
        "over_max": 100,
        "negative": -1
      },
      "price": {
        "min": 0.01,
        "max": 9999.99,
        "over_max": 10000.00,
        "zero": 0.00
      }
    },
    
    "special_characters": {
      "product_names": [
        "Product with 'quotes'",
        "Product with \"double quotes\"",
        "Product & Special Chars",
        "Café Français",
        "🎮 Gaming Console"
      ]
    },
    
    "concurrent_scenarios": {
      "stock_depletion": {
        "description": "Multiple users buying last item",
        "setup": "Set product stock to 1",
        "users": 2,
        "expected": "First user succeeds, second gets error"
      }
    }
  },
  
  "performance_thresholds": {
    "page_load": 2000,
    "api_response": 500,
    "cart_update": 1000
  }
}
```

## Execution Commands

### Basic BDD Generation
```bash
# Generate from user stories
./claude-flow workflow bdd-scenario-generation.md \
  --input "user-stories/" \
  --output "features/" \
  --framework "cucumber"

# Generate from requirements
./claude-flow sparc "Generate BDD scenarios from requirements.yaml"
```

### Advanced Generation Options
```bash
# Full BDD suite generation with all options
./claude-flow swarm "Generate comprehensive BDD test suite" \
  --strategy development \
  --mode hierarchical \
  --config bdd-config.yaml \
  --tags "@smoke,@regression,@edge-case" \
  --examples "comprehensive" \
  --frameworks "cucumber,specflow,behave" \
  --step-pattern "page-object" \
  --data-strategy "boundary,equivalence,decision-table" \
  --output-format "feature,xlsx,json" \
  --parallel --monitor
```

### Framework-Specific Commands

#### Cucumber (JavaScript/TypeScript)
```bash
# Generate Cucumber.js compatible features
./claude-flow sparc run scenario-writer \
  "Generate Cucumber-JS features with TypeScript step definitions" \
  --config cucumber.config.js \
  --step-style async-await \
  --page-objects true

# Execute generated tests
npm run test:cucumber -- --tags "@smoke"
```

#### SpecFlow (.NET)
```bash
# Generate SpecFlow features
./claude-flow sparc run scenario-writer \
  "Create SpecFlow features with C# bindings" \
  --framework specflow \
  --project-type nunit \
  --namespace "ShoppingCart.Tests"

# Execute in Visual Studio or CLI
dotnet test --filter "Category=smoke"
```

#### Behave (Python)
```bash
# Generate Behave features
./claude-flow sparc run scenario-writer \
  "Generate Behave features with Python step implementations" \
  --framework behave \
  --step-style context-based \
  --fixtures pytest

# Execute tests
behave --tags=@smoke --format=json -o reports/behave.json
```

## BDD Patterns Library

### 1. CRUD Operations Pattern
```gherkin
@crud
Feature: [Entity] Management

  Background:
    Given I am authenticated as "[role]"
    And I have permission to manage [entities]

  # CREATE
  Scenario: Create new [entity]
    When I create a [entity] with valid data
    Then the [entity] should be created successfully
    And I should see it in the [entity] list

  # READ
  Scenario: View [entity] details
    Given a [entity] "[name]" exists
    When I view the [entity] details
    Then I should see all [entity] information

  # UPDATE
  Scenario: Update [entity]
    Given a [entity] "[name]" exists
    When I update the [entity]'s [field] to "[value]"
    Then the [entity]'s [field] should be "[value]"

  # DELETE
  Scenario: Delete [entity]
    Given a [entity] "[name]" exists
    When I delete the [entity]
    Then the [entity] should no longer exist
```

### 2. State Machine Pattern
```gherkin
@state-machine
Feature: [Entity] State Transitions

  Scenario Outline: Valid state transitions
    Given a [entity] in "<from_state>" state
    When I perform "<action>"
    Then the [entity] should transition to "<to_state>"
    And the transition should be logged

    Examples:
      | from_state | action    | to_state   |
      | draft      | submit    | pending    |
      | pending    | approve   | approved   |
      | pending    | reject    | rejected   |
      | approved   | publish   | published  |

  Scenario: Invalid state transition
    Given a [entity] in "published" state
    When I try to perform "reject"
    Then I should see error "Invalid state transition"
    And the [entity] should remain in "published" state
```

### 3. Business Rules Pattern
```gherkin
@business-rules
Feature: [Domain] Business Rules

  Background:
    Given the following business rules are configured:
      | rule                | condition           | action           |
      | minimum_order_value | total < 10          | block_checkout   |
      | bulk_discount      | quantity >= 10      | apply_10_percent |
      | vip_customer       | customer_type = vip | free_shipping    |

  Scenario Outline: Apply business rules
    Given I am a "<customer_type>" customer
    And my cart total is $<total>
    And I have <quantity> items
    When I proceed to checkout
    Then "<rule>" should be applied
    And the result should be "<result>"

    Examples:
      | customer_type | total | quantity | rule              | result         |
      | standard      | 5.00  | 1        | minimum_order_value | checkout_blocked |
      | standard      | 100.00| 10       | bulk_discount     | 10% discount    |
      | vip           | 25.00 | 1        | vip_customer      | free shipping   |
```

### 4. Error Handling Pattern
```gherkin
@error-handling
Feature: Error Handling and Recovery

  Scenario Outline: Handle system errors gracefully
    Given the system is in normal state
    When "<error_condition>" occurs
    Then I should see user-friendly message "<message>"
    And the error should be logged with severity "<severity>"
    And the system should "<recovery_action>"

    Examples:
      | error_condition        | message                          | severity | recovery_action    |
      | database_timeout      | "System is busy, please retry"   | high     | retry_3_times     |
      | payment_gateway_down  | "Payment unavailable"            | critical | show_alternatives |
      | invalid_api_response  | "Something went wrong"           | medium   | use_cached_data   |
```

### 5. Performance Testing Pattern
```gherkin
@performance
Feature: Performance Requirements

  Scenario: Page load performance
    When I navigate to the "[page]" page
    Then the page should load within [time] seconds
    And all images should be loaded within [time] seconds
    And the page should be interactive within [time] seconds

  Scenario: Concurrent user handling
    Given [number] users are using the system
    When they all perform "[action]" simultaneously
    Then all requests should complete within [time] seconds
    And the success rate should be at least [percentage]%
    And no data corruption should occur

  Scenario: API response time
    When I make a "[method]" request to "[endpoint]"
    Then the response time should be less than [time]ms
    And the response should include proper caching headers
```

## Tag Organization Strategy

### Hierarchical Tag Structure
```gherkin
# Test Level Tags
@unit           # Unit-level BDD scenarios
@integration    # Integration scenarios
@e2e            # End-to-end scenarios
@api            # API-level scenarios
@ui             # UI-level scenarios

# Execution Tags
@smoke          # Quick smoke tests
@regression     # Full regression suite
@nightly        # Nightly build tests
@weekly         # Weekly full suite
@release        # Release validation

# Priority Tags
@critical       # Business critical
@high           # High priority
@medium         # Medium priority
@low            # Low priority

# Feature Tags
@authentication # Auth features
@cart           # Shopping cart
@checkout       # Checkout process
@payment        # Payment processing

# Special Tags
@wip            # Work in progress
@skip           # Skip execution
@manual         # Manual testing required
@flaky          # Known flaky test
@data-driven    # Uses external data
```

### Tag Usage Examples
```gherkin
@smoke @critical @authentication @ui
Scenario: User login with valid credentials

@regression @medium @cart @api
Scenario: Add item to cart via API

@nightly @integration @payment @data-driven
Scenario Outline: Process payment with multiple methods
```

## CI/CD Integration

### GitHub Actions Workflow
```yaml
# .github/workflows/bdd-tests.yml
name: BDD Test Suite

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 2 * * *'  # Nightly at 2 AM

jobs:
  generate-scenarios:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Claude Flow
        run: |
          npm install -g @anthropic/claude-flow
          ./claude-flow init
      
      - name: Generate BDD Scenarios
        run: |
          ./claude-flow workflow bdd-scenario-generation.md \
            --input requirements/ \
            --output features/ \
            --tags "@smoke,@critical"
      
      - name: Upload Features
        uses: actions/upload-artifact@v3
        with:
          name: generated-features
          path: features/

  run-cucumber-tests:
    needs: generate-scenarios
    runs-on: ubuntu-latest
    strategy:
      matrix:
        browser: [chrome, firefox, edge]
        
    steps:
      - uses: actions/checkout@v3
      
      - name: Download Features
        uses: actions/download-artifact@v3
        with:
          name: generated-features
          path: features/
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          
      - name: Install Dependencies
        run: npm ci
        
      - name: Run Cucumber Tests
        env:
          BROWSER: ${{ matrix.browser }}
        run: |
          npm run test:cucumber -- \
            --tags "@smoke and not @skip" \
            --format json:reports/cucumber-${{ matrix.browser }}.json
      
      - name: Generate Report
        if: always()
        run: |
          npm run report:cucumber
          
      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-results-${{ matrix.browser }}
          path: reports/

  run-specflow-tests:
    needs: generate-scenarios
    runs-on: windows-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup .NET
        uses: actions/setup-dotnet@v3
        with:
          dotnet-version: '7.0.x'
          
      - name: Download Features
        uses: actions/download-artifact@v3
        with:
          name: generated-features
          path: Features/
          
      - name: Build Solution
        run: dotnet build
        
      - name: Run SpecFlow Tests
        run: |
          dotnet test \
            --filter "Category=smoke" \
            --logger "trx;LogFileName=specflow-results.trx"
            
      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: specflow-results
          path: TestResults/

  run-behave-tests:
    needs: generate-scenarios
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
          
      - name: Download Features
        uses: actions/download-artifact@v3
        with:
          name: generated-features
          path: features/
          
      - name: Install Dependencies
        run: |
          pip install -r requirements.txt
          
      - name: Run Behave Tests
        run: |
          behave \
            --tags=@smoke \
            --format=json \
            --outfile=reports/behave-results.json
            
      - name: Generate Allure Report
        if: always()
        run: |
          behave -f allure_behave.formatter:AllureFormatter \
            -o allure-results
          allure generate allure-results -o allure-report
          
      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: behave-results
          path: |
            reports/
            allure-report/
```

### Jenkins Pipeline
```groovy
// Jenkinsfile
pipeline {
    agent any
    
    parameters {
        choice(
            name: 'FRAMEWORK',
            choices: ['cucumber', 'specflow', 'behave', 'all'],
            description: 'BDD Framework to use'
        )
        string(
            name: 'TAGS',
            defaultValue: '@smoke',
            description: 'Tags to run'
        )
    }
    
    stages {
        stage('Generate BDD Scenarios') {
            steps {
                sh '''
                    ./claude-flow workflow bdd-scenario-generation.md \
                        --input requirements/ \
                        --output features/ \
                        --framework ${FRAMEWORK} \
                        --tags "${TAGS}"
                '''
            }
        }
        
        stage('Run Tests') {
            parallel {
                stage('Cucumber Tests') {
                    when {
                        expression { params.FRAMEWORK in ['cucumber', 'all'] }
                    }
                    steps {
                        sh 'npm run test:cucumber -- --tags "${TAGS}"'
                    }
                }
                
                stage('SpecFlow Tests') {
                    when {
                        expression { params.FRAMEWORK in ['specflow', 'all'] }
                    }
                    steps {
                        sh 'dotnet test --filter "Category=${TAGS}"'
                    }
                }
                
                stage('Behave Tests') {
                    when {
                        expression { params.FRAMEWORK in ['behave', 'all'] }
                    }
                    steps {
                        sh 'behave --tags=${TAGS}'
                    }
                }
            }
        }
        
        stage('Publish Reports') {
            steps {
                cucumber reports: 'reports/**/*.json'
                publishHTML([
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: 'reports/html',
                    reportFiles: 'index.html',
                    reportName: 'BDD Test Report'
                ])
            }
        }
    }
    
    post {
        always {
            archiveArtifacts artifacts: 'features/**/*.feature', fingerprint: true
            archiveArtifacts artifacts: 'reports/**/*', fingerprint: true
        }
    }
}
```

## Advanced Integration Patterns

### 1. Multi-Framework Orchestration
```bash
# Generate scenarios for all frameworks simultaneously
./claude-flow swarm "Generate BDD scenarios for all frameworks" \
  --agents "cucumber_specialist,specflow_specialist,behave_specialist" \
  --parallel \
  --output-format "multi-framework"

# Validate cross-framework compatibility
./claude-flow sparc "Validate BDD scenarios work across Cucumber, SpecFlow, and Behave"
```

### 2. Living Documentation Generation
```bash
# Generate living documentation from features
./claude-flow sparc run documenter \
  "Create living documentation from BDD features" \
  --format "html,pdf,confluence" \
  --include-examples \
  --include-step-definitions
```

### 3. Test Data Generation Pipeline
```bash
# Generate comprehensive test data
./claude-flow task create test-data-pipeline \
  "Generate test data for all BDD scenarios"

# Store in memory for reuse
./claude-flow memory store "bdd_test_data" \
  "$(cat generated-test-data.json)"
```

### 4. Continuous Scenario Refinement
```bash
# Analyze test execution results
./claude-flow sparc run analyzer \
  "Analyze BDD test failures and suggest improvements"

# Refine scenarios based on analysis
./claude-flow sparc "Refine BDD scenarios based on failure analysis"
```

## Best Practices & Guidelines

### 1. Scenario Writing Best Practices
- **Independent & Isolated**: Each scenario should run independently without relying on other scenarios
- **Single Purpose**: One scenario should test one behavior or business rule
- **Declarative Style**: Focus on what, not how (business language over technical details)
- **Concrete Examples**: Use specific, realistic data rather than abstract placeholders
- **Consistent Voice**: Maintain consistent grammar and tense throughout scenarios

### 2. Feature Organization
- **Domain-Driven Structure**: Organize features by business domain
- **Logical Grouping**: Group related scenarios within features
- **Clear Naming**: Use descriptive feature and scenario names
- **Proper Tagging**: Apply meaningful tags for test organization
- **Version Control**: Track feature files in source control

### 3. Step Definition Guidelines
- **Reusability**: Design steps to be reusable across scenarios
- **Parameterization**: Use parameters for flexibility
- **Clear Intent**: Step names should clearly express intent
- **Avoid UI Details**: Keep UI specifics in page objects
- **Error Handling**: Include proper error handling and logging

### 4. Data Management
- **Test Data Isolation**: Each test should manage its own data
- **Cleanup Strategy**: Implement proper teardown procedures
- **Configuration-Driven**: Use configuration files for test data
- **Environment Flexibility**: Support multiple test environments
- **Data Privacy**: Avoid using production data

### 5. Performance Optimization
- **Parallel Execution**: Design for parallel test execution
- **Smart Waits**: Use explicit waits over implicit waits
- **Resource Management**: Properly manage browser/API connections
- **Selective Execution**: Use tags for targeted test runs
- **Result Caching**: Cache reusable test data and configurations

## Troubleshooting Guide

### Common Issues and Solutions

#### 1. Ambiguous Step Definitions
**Problem**: Multiple step definitions match the same step
**Solution**:
- Make regex patterns more specific
- Use unique parameter types
- Reorganize step definitions by domain

#### 2. Flaky Scenarios
**Problem**: Tests pass/fail inconsistently
**Solution**:
- Add proper synchronization
- Isolate test data
- Mock external dependencies
- Implement retry mechanisms

#### 3. Slow Test Execution
**Problem**: Test suite takes too long to run
**Solution**:
- Enable parallel execution
- Optimize database operations
- Use API calls for setup/teardown
- Implement smart test selection

#### 4. Step Definition Maintenance
**Problem**: Step definitions become hard to maintain
**Solution**:
- Follow page object pattern
- Create helper utilities
- Use composition over inheritance
- Regular refactoring

#### 5. Cross-Browser Issues
**Problem**: Tests fail on specific browsers
**Solution**:
- Use standardized selectors
- Implement browser-specific handling
- Regular cross-browser testing
- Update driver versions

## Metrics and Reporting

### Key Metrics to Track
```yaml
coverage_metrics:
  requirement_coverage: "% of requirements with BDD scenarios"
  scenario_coverage: "% of user stories covered"
  step_reusability: "Average reuse of step definitions"
  
execution_metrics:
  pass_rate: "% of scenarios passing"
  execution_time: "Average scenario execution time"
  flakiness_rate: "% of flaky scenarios"
  
quality_metrics:
  scenario_clarity: "Readability score (1-10)"
  maintenance_effort: "Hours spent on maintenance"
  defect_detection: "Defects found by BDD tests"
```

### Reporting Templates
```javascript
// Custom report generation
const generateBDDReport = {
  summary: {
    total_features: 25,
    total_scenarios: 150,
    passed: 145,
    failed: 3,
    skipped: 2,
    pass_rate: "96.7%",
    execution_time: "15m 32s"
  },
  
  coverage: {
    requirements_covered: "89%",
    business_rules_tested: "94%",
    edge_cases_included: "78%"
  },
  
  trends: {
    pass_rate_trend: "improving",
    execution_time_trend: "stable",
    new_scenarios_added: 12
  }
};
```

## Success Criteria

### Workflow Success Metrics
- **Scenario Generation Speed**: < 2 minutes per feature file
- **Step Reusability**: > 70% step definition reuse
- **Framework Compatibility**: 100% cross-framework support
- **Automation Readiness**: 95% of scenarios immediately executable
- **Business Readability**: 90% stakeholder comprehension rate

---

*BDD Scenario Generation Workflow v2.0 | Living Documentation | Multi-Framework Support*