# Generated from: e-commerce-checkout.md
# Generated on: 2024-01-15
# Test Case Generator v1.0.0

@checkout @critical
Feature: E-Commerce Checkout Process
  As a customer with items in my cart
  I want to complete the checkout process
  So that I can purchase my selected items

  Background:
    Given I am logged in as "customer@example.com"
    And my cart contains the following items:
      | product        | quantity | price   |
      | Laptop Pro     | 1        | 999.99  |
      | Wireless Mouse | 2        | 29.99   |

  @smoke @happy-path
  Scenario: Successful checkout with credit card
    When I proceed to checkout
    Then I should see my cart summary with total "$1,059.97"
    
    When I enter my shipping address:
      | field        | value               |
      | full_name    | John Doe           |
      | address_1    | 123 Main Street    |
      | city         | New York           |
      | state        | NY                 |
      | postal_code  | 10001              |
      | country      | United States      |
    And I select "Standard Shipping ($5.00)"
    Then the order total should be "$1,064.97"
    
    When I enter my payment information:
      | field        | value               |
      | card_number  | 4111111111111111   |
      | card_name    | John Doe           |
      | expiry_date  | 12/25              |
      | cvv          | 123                |
    And I click "Place Order"
    Then I should see "Order Confirmed!"
    And I should receive an order number
    And I should receive a confirmation email within 2 minutes

  @validation @negative-test
  Scenario: Checkout prevented with out-of-stock item
    Given the "Laptop Pro" becomes out of stock
    When I proceed to checkout
    Then I should see an alert "Some items in your cart are no longer available"
    And the "Laptop Pro" should be marked as "Out of Stock"
    And I should see options to:
      | option                  |
      | Remove item            |
      | Save for later         |
      | Find similar products  |

  @validation @business-rule
  Scenario: Minimum order value enforcement
    Given my cart only contains:
      | product      | quantity | price |
      | USB Cable    | 1        | 8.99  |
    When I proceed to checkout
    Then I should see "Minimum order value is $10.00"
    And the checkout button should be disabled
    And I should see "Add $1.01 more to proceed"

  @edge-case @payment
  Scenario: Payment timeout handling
    Given I am on the payment page
    When I enter valid payment information
    And I click "Place Order"
    And the payment gateway times out after 30 seconds
    Then I should see "Payment processing timed out"
    And I should see "Your payment was not charged"
    And I should have the option to "Try Again"
    And my cart should still contain all items

  @edge-case @concurrency
  Scenario: Concurrent purchase of limited stock
    Given there is only 1 "Limited Edition Keyboard" in stock
    And another user "user2@example.com" has the same item in cart
    When I add "Limited Edition Keyboard" to my cart
    And I quickly proceed to checkout
    And the other user completes purchase first
    Then I should see "Limited Edition Keyboard is no longer available"
    And I should be offered alternative products

  @security @payment
  Scenario: 3D Secure authentication for high-value order
    Given my cart total exceeds $500
    When I enter my payment information
    And I click "Place Order"
    Then I should be redirected to 3D Secure authentication
    When I complete the authentication successfully
    Then the order should be processed
    And I should see "Order Confirmed!"

  @international @edge-case
  Scenario Outline: International shipping with currency conversion
    Given I am shopping from "<country>"
    And my default currency is "<currency>"
    When I proceed to checkout
    Then prices should be displayed in "<currency>"
    And I should see "International shipping rates apply"
    And duties and taxes should be calculated for "<country>"

    Examples:
      | country        | currency |
      | United Kingdom | GBP      |
      | Canada         | CAD      |
      | Australia      | AUD      |
      | Japan          | JPY      |

  @performance @load-test
  Scenario: Checkout performance under load
    Given 1000 users are checking out simultaneously
    When I proceed through the checkout process
    Then each page should load within 2 seconds
    And payment processing should complete within 5 seconds
    And no errors should occur due to system load

  @accessibility
  Scenario: Checkout with screen reader
    Given I am using a screen reader
    When I navigate through the checkout process
    Then all form fields should have proper labels
    And error messages should be announced
    And the order confirmation should be fully accessible
    And focus management should follow WCAG guidelines

  @mobile @responsive
  Scenario: Mobile checkout experience
    Given I am using a mobile device
    When I proceed to checkout
    Then the checkout form should be mobile-optimized
    And I should be able to use autofill for addresses
    And payment fields should trigger appropriate keyboards
    And all buttons should be easily tappable

  @discount @business-rule
  Scenario: Applying discount code with free shipping threshold
    Given my cart subtotal is "$45.00"
    When I apply discount code "SAVE10"
    Then I should see "10% discount applied"
    And my new subtotal should be "$40.50"
    And I should see "Add $9.50 more for free shipping"
    When I add another item worth "$10.00"
    Then I should qualify for free shipping
    And shipping cost should be "$0.00"