# Generated from: task-management-app.md
# Feature coverage: Task Management, Collaboration, Projects

Feature: Task Management in TaskFlow Pro
  As a team member
  I want to manage tasks effectively
  So that I can track and complete my work efficiently

  Background:
    Given I am logged in as "john.doe@company.com" with role "Team Member"
    And I am on the TaskFlow Pro dashboard
    And the following projects exist:
      | project_name      | project_manager | start_date | end_date   |
      | Q1 Marketing      | Jane Smith      | 2024-01-01 | 2024-03-31 |
      | Product Launch    | Mike Johnson    | 2024-02-01 | 2024-06-30 |
      | Website Redesign  | Sarah Williams  | 2024-01-15 | 2024-04-15 |

  @smoke @critical
  Scenario: Create a simple task
    When I click on "New Task" button
    And I enter "Write blog post about new features" in the "Title" field
    And I select "Q1 Marketing" from the "Project" dropdown
    And I click "Create Task"
    Then I should see a success message "Task created successfully"
    And the task "Write blog post about new features" should appear in the "Backlog" column
    And the activity feed should show "John Doe created task: Write blog post about new features"

  @validation @high
  Scenario Outline: Task field validation
    When I click on "New Task" button
    And I enter "<title>" in the "Title" field
    And I enter "<description>" in the "Description" field
    And I select "<priority>" from the "Priority" dropdown
    And I click "Create Task"
    Then I should see validation message "<validation_message>"

    Examples:
      | title | description | priority | validation_message |
      |       | Valid desc  | High     | Title is required |
      | A     | Valid desc  | High     | Title must be at least 3 characters |
      | <script>alert('XSS')</script> | Valid | High | Invalid characters in title |
      | Valid Title | <string_of_5001_chars> | High | Description exceeds maximum length of 5000 characters |

  @workflow @critical
  Scenario: Task state transitions with permissions
    Given the following task exists:
      | title               | status   | assignee | project      |
      | Implement user API  | Backlog  | John Doe | Product Launch |
    When I view the task "Implement user API"
    And I drag the task to "To Do" column
    Then the task status should change to "To Do"
    And the activity log should show "John Doe moved task from Backlog to To Do"
    When I drag the task to "In Progress" column
    Then the task status should change to "In Progress"
    And the start time should be recorded
    When I drag the task to "In Review" column
    Then the task status should change to "In Review"
    When I try to drag the task to "Done" column
    Then I should see error message "Only Project Manager can move tasks to Done"
    And the task should remain in "In Review" status

  @subtasks @medium
  Scenario: Create nested subtasks with depth limit
    Given I have created a task "Build authentication system"
    When I open the task details
    And I click "Add Subtask"
    And I create subtask "Design database schema" at level 1
    And I create subtask "Create user table" under "Design database schema" at level 2
    And I create subtask "Add indexes" under "Create user table" at level 3
    And I try to create subtask "Optimize queries" under "Add indexes"
    Then I should see error "Maximum nesting level (3) reached"
    And the subtask hierarchy should show:
      """
      Build authentication system
      └── Design database schema
          └── Create user table
              └── Add indexes
      """

  @dependencies @high
  Scenario: Task dependencies and blocking
    Given the following tasks exist in "Product Launch" project:
      | title            | status      | assignee |
      | Design API       | In Progress | John Doe |
      | Implement API    | To Do       | Jane Smith |
      | Write API tests  | To Do       | Mike Brown |
    When I open task "Implement API"
    And I add dependency "Design API" as blocking task
    And I try to move "Implement API" to "In Progress"
    Then I should see error "Cannot start task: Blocked by 'Design API'"
    When I complete the task "Design API"
    Then "Implement API" should show as unblocked
    And I should be able to move "Implement API" to "In Progress"

  @bulk_operations @medium
  Scenario: Bulk update multiple tasks
    Given the following tasks exist in my view:
      | title                  | priority | assignee  | status   |
      | Review documentation   | Low      | John Doe  | Backlog  |
      | Update test cases      | Low      | John Doe  | Backlog  |
      | Fix critical bug       | High     | Jane Smith| To Do    |
      | Refactor login module  | Medium   | John Doe  | Backlog  |
    When I select the following tasks:
      | Review documentation |
      | Update test cases    |
      | Refactor login module |
    And I click "Bulk Actions"
    And I select "Change Priority" to "High"
    And I select "Change Assignee" to "Mike Johnson"
    And I click "Apply Changes"
    Then I should see "3 tasks updated successfully"
    And the tasks should have:
      | title                  | priority | assignee     |
      | Review documentation   | High     | Mike Johnson |
      | Update test cases      | High     | Mike Johnson |
      | Refactor login module  | High     | Mike Johnson |

Feature: Real-time Collaboration
  As a team member
  I want to collaborate with my team in real-time
  So that we can work together efficiently

  Background:
    Given the following users are logged in:
      | user              | role           |
      | john@company.com  | Team Member    |
      | jane@company.com  | Team Member    |
      | mike@company.com  | Project Manager|

  @realtime @critical
  Scenario: Live task updates across users
    Given John and Jane are viewing task "Design new homepage"
    When John changes the task title to "Design new homepage v2"
    Then Jane should see the title update to "Design new homepage v2" within 100ms
    And Jane should see a notification "John Doe updated task title"
    When Jane adds a comment "Looking good!"
    Then John should see the comment appear immediately
    And the comment count should increase to 1 for both users

  @mentions @high
  Scenario: Comment mentions and notifications
    Given I am viewing task "Implement search feature"
    When I add a comment:
      """
      @jane Could you review the search algorithm?
      @mike We might need more time for this feature.
      """
    Then Jane should receive an in-app notification "John mentioned you in 'Implement search feature'"
    And Jane should receive an email notification within 1 minute
    And Mike should receive an in-app notification "John mentioned you in 'Implement search feature'"
    And the comment should show clickable links for @jane and @mike

  @conflict_resolution @high
  Scenario: Concurrent edit conflict resolution
    Given John and Jane are both editing task "Update user documentation"
    And the task currently has description "Initial documentation outline"
    When John changes description to "Comprehensive documentation with examples"
    And Jane changes description to "Quick start guide and API reference" within 1 second
    Then Jane should see conflict dialog:
      """
      Conflict Detected
      Your version: Quick start guide and API reference
      John's version: Comprehensive documentation with examples
      [Keep Mine] [Keep John's] [Merge]
      """
    When Jane selects "Merge"
    Then a merge editor should open
    And the final description should combine both changes
    And activity log should show both edit attempts

Feature: Search and Filtering
  As a user
  I want powerful search and filtering capabilities
  So that I can quickly find relevant tasks

  @search @high
  Scenario Outline: Advanced search queries
    Given I have 1000 tasks in various states
    When I search for "<query>"
    Then I should see <result_count> results
    And the search should complete in less than <response_time>
    And results should be sorted by <sort_order>

    Examples:
      | query                          | result_count | response_time | sort_order    |
      | status:done assignee:me        | 45          | 200ms        | modified_date |
      | priority:high due:this-week    | 12          | 150ms        | due_date      |
      | "user authentication" label:bug | 8           | 300ms        | relevance     |
      | created:>2024-01-01 project:Q1 | 156         | 400ms        | created_date  |

  @filters @medium
  Scenario: Save and reuse custom filters
    When I apply the following filters:
      | Filter Type | Value           |
      | Status      | In Progress     |
      | Priority    | High, Critical  |
      | Assignee    | My Team         |
      | Due Date    | Next 7 days     |
    And I click "Save Filter"
    And I name it "Urgent Team Tasks"
    Then "Urgent Team Tasks" should appear in "My Filters" sidebar
    When I logout and login again
    And I click on "Urgent Team Tasks" filter
    Then the same filters should be applied
    And I should see only matching tasks

Feature: Mobile Experience
  As a mobile user
  I want to manage tasks on my phone
  So that I can work from anywhere

  @mobile @high
  Scenario: Touch gestures for task management
    Given I am using the mobile app on iPhone 13
    And I am viewing the Kanban board
    When I swipe left on task "Review pull request"
    Then I should see quick actions: "Complete", "Edit", "Delete"
    When I tap "Complete"
    Then the task should move to "Done" column
    And I should feel haptic feedback
    When I pinch out on the Gantt chart view
    Then the timeline should zoom in smoothly
    And date labels should remain readable

  @offline @medium
  Scenario: Offline mode synchronization
    Given I have the following tasks cached offline:
      | title                | status      | modified_offline |
      | Write unit tests     | To Do       | No              |
      | Deploy to staging    | In Progress | No              |
    When I lose internet connection
    And I change "Write unit tests" status to "In Progress"
    And I add comment "Started working on tests"
    And I create new task "Fix offline bug"
    Then I should see offline indicator
    And changes should be queued for sync
    When I regain internet connection
    Then sync should start automatically
    And I should see "3 changes synced successfully"
    And server should have all my offline changes

Feature: Performance and Limits
  As a power user
  I want the system to handle large amounts of data
  So that it remains usable as my projects grow

  @performance @load_test
  Scenario: Handle large task lists efficiently
    Given my project has 5000 tasks
    And 500 tasks are visible in current view
    When I load the task list page
    Then initial 50 tasks should load in less than 1 second
    And remaining tasks should load as I scroll
    And scrolling should maintain 60fps
    When I search for "important"
    Then search results should appear in less than 500ms
    And memory usage should stay below 200MB

  @limits @edge_case
  Scenario Outline: System behavior at limits
    When I attempt to <action>
    Then system should <expected_behavior>

    Examples:
      | action                                    | expected_behavior                          |
      | Upload 11 attachments to one task         | Show error "Maximum 10 attachments"        |
      | Create task with 201 character title      | Show error "Title too long (max 200)"      |
      | Add 51MB of attachments                   | Show error "Total size exceeds 50MB"       |
      | Create 4 levels of subtask nesting        | Show error "Maximum nesting level is 3"    |
      | Assign task to 21 people                  | Allow it but show warning                  |
      | Create project with 10,001 tasks          | Allow but suggest archiving old tasks      |

Feature: Security and Permissions
  As a system administrator
  I want robust security controls
  So that data remains protected

  @security @critical
  Scenario: Role-based access control
    Given the following users with roles:
      | user             | role         | project        |
      | admin@corp.com   | Admin        | All            |
      | pm@corp.com      | PM           | Product Launch |
      | member@corp.com  | Team Member  | Product Launch |
      | guest@corp.com   | Guest        | Product Launch |
    Then permissions should be enforced as:
      | user            | action                | allowed |
      | guest@corp.com  | View tasks            | Yes     |
      | guest@corp.com  | Create task           | No      |
      | member@corp.com | Delete own task       | Yes     |
      | member@corp.com | Delete others' task   | No      |
      | pm@corp.com     | Modify project settings| Yes     |
      | pm@corp.com     | Delete user accounts  | No      |
      | admin@corp.com  | All actions           | Yes     |

  @security @injection
  Scenario Outline: Prevent injection attacks
    When I enter "<malicious_input>" in the "<field>" field
    Then the input should be safely escaped
    And no code execution should occur
    And data integrity should be maintained

    Examples:
      | field       | malicious_input                              |
      | Task Title  | '; DROP TABLE tasks; --                      |
      | Search Box  | ' OR '1'='1                                  |
      | Comment     | <script>alert('XSS')</script>                |
      | Description | <img src=x onerror=alert('XSS')>             |
      | URL Field   | javascript:alert('XSS')                      |

  @audit @compliance
  Scenario: Audit trail for compliance
    Given I am logged in as "john@company.com"
    When I perform the following actions:
      | action                        | target              |
      | Create task                   | "Security review"   |
      | Change priority to Critical   | "Security review"   |
      | Assign to "security@corp.com" | "Security review"   |
      | Add comment with attachment   | "Security review"   |
      | Move to Done                  | "Security review"   |
    Then the audit log should contain:
      | timestamp | user | action | target | ip_address | user_agent |
      | <now>     | john | CREATE | task:Security review | 10.0.0.1 | Chrome 120 |
      | <now>     | john | UPDATE | task:Security review:priority | 10.0.0.1 | Chrome 120 |
      | <now>     | john | UPDATE | task:Security review:assignee | 10.0.0.1 | Chrome 120 |
      | <now>     | john | CREATE | comment:task:Security review | 10.0.0.1 | Chrome 120 |
      | <now>     | john | UPDATE | task:Security review:status | 10.0.0.1 | Chrome 120 |
    And audit logs should be immutable
    And logs should be retained for 1 year minimum

# End of generated feature file
# Total scenarios: 24
# Total scenario outlines: 7
# Coverage: Authentication, Tasks, Projects, Collaboration, Search, Mobile, Performance, Security