# BDD Scenario Template
# Use this template as a starting point for writing Gherkin scenarios

@tag1 @tag2
Feature: [Feature Name]
  As a [type of user]
  I want [some goal]
  So that [some reason]

  # Optional: Background steps that run before each scenario
  Background:
    Given [common precondition]
    And [another common precondition]

  # Basic scenario structure
  @smoke @priority-high
  Scenario: [Scenario description - positive case]
    Given [context or precondition]
    And [additional context]
    When [action or event]
    And [additional action]
    Then [expected outcome]
    And [additional assertion]
    But [exception or exclusion]

  # Scenario with data table
  @data-driven
  Scenario: [Scenario with inline data]
    Given the following users exist:
      | username | email              | role     |
      | john_doe | john@example.com   | admin    |
      | jane_doe | jane@example.com   | user     |
    When I search for "doe"
    Then I should see 2 results

  # Scenario outline for multiple examples
  @edge-cases @validation
  Scenario Outline: [Parameterized scenario description]
    Given I am on the registration page
    When I enter "<username>" as username
    And I enter "<email>" as email
    And I enter "<password>" as password
    And I click register
    Then I should see "<message>"

    Examples:
      | username  | email                | password    | message                        |
      | validuser | valid@example.com    | Pass123!    | Registration successful        |
      | ab        | valid@example.com    | Pass123!    | Username too short             |
      | longuser  | invalid-email        | Pass123!    | Invalid email format           |
      | validuser | valid@example.com    | weak        | Password too weak              |

  # Negative test scenario
  @negative @security
  Scenario: [Security or error scenario]
    Given I am not logged in
    When I try to access "/admin/dashboard"
    Then I should be redirected to "/login"
    And I should see "Authentication required"

  # Performance scenario
  @performance @non-functional
  Scenario: [Performance requirement]
    Given 1000 concurrent users
    When they all perform login
    Then 95% of requests should complete within 2 seconds
    And no requests should fail

  # API testing scenario
  @api @integration
  Scenario: [API endpoint test]
    Given I have a valid API key
    When I send a GET request to "/api/users"
    Then the response status should be 200
    And the response should contain:
      """json
      {
        "users": [
          {
            "id": "string",
            "email": "string"
          }
        ],
        "total": "number"
      }
      """

  # Mobile-specific scenario
  @mobile @responsive
  Scenario: [Mobile user experience]
    Given I am using a mobile device
    And I am in portrait orientation
    When I navigate to the home page
    Then the navigation menu should be collapsed
    When I tap the menu icon
    Then the navigation drawer should slide in from the left

  # Accessibility scenario
  @accessibility @wcag
  Scenario: [Accessibility requirement]
    Given I am using a screen reader
    When I navigate to the form
    Then all form fields should have accessible labels
    And error messages should be announced
    And the tab order should be logical

# Template Usage Notes:
# 1. Replace placeholder text in [brackets] with actual values
# 2. Use meaningful tag names for test organization
# 3. Keep scenarios focused on one behavior
# 4. Use Background for repeated preconditions
# 5. Prefer Scenario Outline for data-driven tests
# 6. Write scenarios in business language, not technical
# 7. Each scenario should be independent
# 8. Use present tense for actions