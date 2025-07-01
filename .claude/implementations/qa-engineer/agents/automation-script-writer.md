# Automation Script Writer Agent

## Overview
The Automation Script Writer agent specializes in generating executable test automation scripts across various frameworks and platforms. It transforms test cases into maintainable, efficient automation code that integrates seamlessly with CI/CD pipelines and follows industry best practices.

## Core Responsibilities

### 1. Script Generation
- Convert manual test cases to automated scripts
- Generate code in multiple languages and frameworks
- Create reusable test components and utilities
- Implement cross-browser and cross-platform tests

### 2. Framework Management
- Support multiple automation frameworks
- Implement Page Object Model (POM) patterns
- Create custom test utilities and helpers
- Maintain framework-specific best practices

### 3. Code Quality
- Generate clean, maintainable code
- Implement proper error handling
- Add comprehensive logging and reporting
- Ensure test independence and reliability

## Supported Frameworks

### Web Automation
```python
class SeleniumScriptGenerator:
    def generate_test_script(self, test_case):
        """Generate Selenium WebDriver test script"""
        
        script = f'''
import unittest
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException
import logging

class {self.generate_class_name(test_case['title'])}(unittest.TestCase):
    
    @classmethod
    def setUpClass(cls):
        """Set up test fixtures"""
        cls.driver = webdriver.Chrome()
        cls.driver.maximize_window()
        cls.wait = WebDriverWait(cls.driver, 10)
        cls.logger = logging.getLogger(__name__)
        
    def setUp(self):
        """Set up test method"""
        self.driver.get("{test_case['base_url']}")
        
    def test_{self.generate_method_name(test_case['title'])}(self):
        """
        Test: {test_case['title']}
        Description: {test_case['description']}
        """
        try:
'''
        
        # Generate test steps
        for step in test_case['steps']:
            script += self.generate_step_code(step)
        
        script += '''
        except Exception as e:
            self.logger.error(f"Test failed: {str(e)}")
            self.driver.save_screenshot(f"failure_{self._testMethodName}.png")
            raise
            
    def tearDown(self):
        """Clean up after test method"""
        # Clear cookies and local storage
        self.driver.delete_all_cookies()
        
    @classmethod
    def tearDownClass(cls):
        """Clean up test fixtures"""
        cls.driver.quit()

if __name__ == '__main__':
    unittest.main()
'''
        return script
```

### Modern Framework - Playwright
```typescript
class PlaywrightScriptGenerator {
    generateTestScript(testCase: TestCase): string {
        return `
import { test, expect } from '@playwright/test';
import { Page } from '@playwright/test';

test.describe('${testCase.suite}', () => {
    let page: Page;
    
    test.beforeEach(async ({ browser }) => {
        page = await browser.newPage();
        await page.goto('${testCase.baseUrl}');
    });
    
    test.afterEach(async () => {
        await page.close();
    });
    
    test('${testCase.title}', async () => {
        // Test: ${testCase.description}
        ${this.generatePlaywrightSteps(testCase.steps)}
    });
});

${this.generateHelperFunctions(testCase)}
`;
    }
    
    private generatePlaywrightSteps(steps: TestStep[]): string {
        return steps.map(step => {
            switch (step.action) {
                case 'click':
                    return `await page.click('${step.selector}');`;
                case 'fill':
                    return `await page.fill('${step.selector}', '${step.value}');`;
                case 'verify':
                    return `await expect(page.locator('${step.selector}')).${step.assertion}('${step.expected}');`;
                default:
                    return `// Custom action: ${step.action}`;
            }
        }).join('\n        ');
    }
}
```

### API Testing - RestAssured/Pytest
```python
class APITestGenerator:
    def generate_api_test(self, test_case):
        """Generate API test script using pytest and requests"""
        
        return f'''
import pytest
import requests
import json
from datetime import datetime
import allure

class Test{self.generate_class_name(test_case['api_name'])}:
    
    @pytest.fixture(scope="class")
    def base_url(self):
        """Base URL for API endpoints"""
        return "{test_case['base_url']}"
    
    @pytest.fixture(scope="class")
    def headers(self):
        """Common headers for API requests"""
        return {{
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": "Bearer {{token}}"
        }}
    
    @allure.story("{test_case['feature']}")
    @allure.title("{test_case['title']}")
    def test_{self.generate_method_name(test_case['title'])}(self, base_url, headers):
        """
        Test: {test_case['description']}
        Expected: {test_case['expected_result']}
        """
        
        # Prepare test data
        {self.generate_test_data_setup(test_case['test_data'])}
        
        # Make API request
        response = requests.{test_case['method'].lower()}(
            f"{{base_url}}{test_case['endpoint']}",
            headers=headers,
            {self.generate_request_params(test_case)}
        )
        
        # Log request and response
        allure.attach(json.dumps(request_data, indent=2), "Request Body", allure.attachment_type.JSON)
        allure.attach(response.text, "Response Body", allure.attachment_type.JSON)
        
        # Assertions
        assert response.status_code == {test_case['expected_status']}, f"Expected status {{test_case['expected_status']}}, got {{response.status_code}}"
        
        {self.generate_response_assertions(test_case['assertions'])}
'''
```

## Page Object Model Implementation

### Base Page Object
```python
class PageObjectGenerator:
    def generate_page_object(self, page_spec):
        """Generate Page Object Model class"""
        
        return f'''
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.action_chains import ActionChains
import logging

class {page_spec['name']}Page:
    """Page Object for {page_spec['name']} page"""
    
    def __init__(self, driver):
        self.driver = driver
        self.wait = WebDriverWait(driver, 10)
        self.logger = logging.getLogger(__name__)
        
    # Locators
    {self.generate_locators(page_spec['elements'])}
    
    # Page Methods
    {self.generate_page_methods(page_spec['actions'])}
    
    # Verification Methods
    {self.generate_verification_methods(page_spec['verifications'])}
    
    # Helper Methods
    def wait_for_page_load(self):
        """Wait for page to be fully loaded"""
        self.wait.until(
            EC.presence_of_element_located((By.TAG_NAME, "body"))
        )
        
    def is_element_present(self, locator):
        """Check if element is present on page"""
        try:
            self.driver.find_element(*locator)
            return True
        except:
            return False
'''
```

### Component-Based Architecture
```typescript
class ComponentGenerator {
    generateReusableComponent(component: ComponentSpec): string {
        return `
export class ${component.name}Component {
    constructor(private page: Page) {}
    
    // Selectors
    private selectors = {
        ${Object.entries(component.selectors)
            .map(([key, value]) => `${key}: '${value}'`)
            .join(',\n        ')}
    };
    
    // Actions
    ${this.generateComponentActions(component.actions)}
    
    // Getters
    ${this.generateComponentGetters(component.properties)}
    
    // Validations
    async validate(): Promise<boolean> {
        ${this.generateValidationLogic(component.validations)}
    }
}
`;
    }
}
```

## Test Data Management

### Data-Driven Testing
```python
def generate_data_driven_test(self, test_spec):
    """Generate data-driven test with multiple data sets"""
    
    return f'''
import pytest
import csv
import json
from parameterized import parameterized

class TestDataDriven:
    
    @staticmethod
    def load_test_data():
        """Load test data from external source"""
        test_data = []
        
        # Load from CSV
        with open('test_data/{test_spec["data_file"]}', 'r') as file:
            reader = csv.DictReader(file)
            for row in reader:
                test_data.append(row)
        
        return test_data
    
    @parameterized.expand(load_test_data())
    def test_{test_spec["name"]}_with_multiple_data(self, **test_data):
        """
        Data-driven test for {test_spec["description"]}
        """
        # Initialize page objects
        login_page = LoginPage(self.driver)
        dashboard_page = DashboardPage(self.driver)
        
        # Execute test with current data set
        login_page.login(test_data['username'], test_data['password'])
        
        # Verify expected outcome based on data
        if test_data['expected_result'] == 'success':
            assert dashboard_page.is_displayed(), "Dashboard should be displayed after successful login"
        else:
            assert login_page.get_error_message() == test_data['expected_error'], \
                f"Expected error: {{test_data['expected_error']}}"
'''
```

## Cross-Platform Testing

### Mobile Automation
```java
public class AppiumTestGenerator {
    
    public String generateMobileTest(TestCase testCase) {
        return String.format("""
import io.appium.java_client.AppiumDriver;
import io.appium.java_client.MobileElement;
import io.appium.java_client.android.AndroidDriver;
import io.appium.java_client.ios.IOSDriver;
import org.testng.annotations.*;
import org.testng.Assert;

public class %s {
    
    private AppiumDriver<MobileElement> driver;
    private String platform = System.getProperty("platform", "android");
    
    @BeforeClass
    public void setUp() throws Exception {
        if (platform.equalsIgnoreCase("android")) {
            driver = new AndroidDriver<>(getAndroidCapabilities());
        } else {
            driver = new IOSDriver<>(getIOSCapabilities());
        }
    }
    
    @Test
    public void test%s() {
        // Test: %s
        %s
    }
    
    @AfterClass
    public void tearDown() {
        if (driver != null) {
            driver.quit();
        }
    }
}
""", 
            generateClassName(testCase.getTitle()),
            generateMethodName(testCase.getTitle()),
            testCase.getDescription(),
            generateMobileSteps(testCase.getSteps())
        );
    }
}
```

## CI/CD Integration

### Jenkins Pipeline Integration
```groovy
def generateJenkinsfile(testSuite) {
    return """
pipeline {
    agent any
    
    environment {
        TEST_ENV = '${testSuite.environment}'
        BROWSER = '${testSuite.browser}'
        PARALLEL_THREADS = '${testSuite.parallelThreads}'
    }
    
    stages {
        stage('Setup') {
            steps {
                sh 'pip install -r requirements.txt'
                sh 'npm install'
            }
        }
        
        stage('Run Tests') {
            parallel {
                ${generateParallelStages(testSuite.testGroups)}
            }
        }
        
        stage('Generate Reports') {
            steps {
                allure([
                    includeProperties: false,
                    jdk: '',
                    properties: [],
                    reportBuildPolicy: 'ALWAYS',
                    results: [[path: 'allure-results']]
                ])
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        failure {
            emailext (
                subject: "Test Failure: \${env.JOB_NAME} - \${env.BUILD_NUMBER}",
                body: "Test execution failed. Check: \${env.BUILD_URL}",
                to: "${testSuite.notificationEmail}"
            )
        }
    }
}
"""
}
```

## Best Practices Implementation

### Error Handling and Recovery
```python
def generate_robust_test_with_recovery(self, test_case):
    """Generate test with comprehensive error handling"""
    
    return f'''
class RobustTest(BaseTest):
    
    @retry(stop_max_attempt_number=3, wait_fixed=2000)
    def test_with_retry_{test_case["name"]}(self):
        """Test with automatic retry on failure"""
        
        try:
            # Test implementation
            {self.generate_test_steps(test_case)}
            
        except StaleElementReferenceException:
            self.logger.warning("Stale element detected, refreshing page")
            self.driver.refresh()
            self.wait_for_page_load()
            
            # Retry the failed step
            {self.generate_recovery_logic(test_case)}
            
        except TimeoutException as e:
            # Capture diagnostic information
            self.capture_diagnostics()
            raise AssertionError(f"Test timed out: {{str(e)}}")
            
    def capture_diagnostics(self):
        """Capture diagnostic information on failure"""
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # Screenshot
        self.driver.save_screenshot(f"diagnostics/screenshot_{{timestamp}}.png")
        
        # Page source
        with open(f"diagnostics/page_source_{{timestamp}}.html", "w") as f:
            f.write(self.driver.page_source)
            
        # Browser logs
        logs = self.driver.get_log('browser')
        with open(f"diagnostics/console_logs_{{timestamp}}.json", "w") as f:
            json.dump(logs, f, indent=2)
'''
```

### Performance Optimization
```python
def generate_optimized_test_suite(self, test_suite):
    """Generate optimized test suite with parallel execution"""
    
    return f'''
import pytest
from pytest_xdist import plugin

class OptimizedTestSuite:
    
    @pytest.fixture(scope="session")
    def shared_driver(self):
        """Share driver instance across tests for performance"""
        driver = self.create_driver()
        yield driver
        driver.quit()
    
    @pytest.mark.parametrize("test_data", load_test_data(), ids=generate_test_ids)
    def test_parallel_execution(self, shared_driver, test_data):
        """Execute tests in parallel with shared resources"""
        
        # Use thread-safe page objects
        page = ThreadSafePageObject(shared_driver, test_data['page_id'])
        
        # Execute test
        result = page.execute_test_scenario(test_data)
        
        # Assert results
        assert result.success, f"Test failed: {{result.error_message}}"
    
    @pytest.fixture(autouse=True)
    def reset_state(self, shared_driver):
        """Reset application state between tests"""
        yield
        # Clean up after each test
        self.cleanup_test_data(shared_driver)
'''
```

## Maintenance Features

### Self-Healing Locators
```python
class SelfHealingLocatorGenerator:
    def generate_smart_locator(self, element):
        """Generate self-healing locator strategy"""
        
        return f'''
class SmartLocator:
    def __init__(self, primary_locator, fallback_locators):
        self.primary = primary_locator
        self.fallbacks = fallback_locators
        self.success_history = {{}}
        
    def find_element(self, driver):
        """Find element with self-healing capability"""
        
        # Try primary locator
        try:
            element = driver.find_element(*self.primary)
            self.success_history[self.primary] = self.success_history.get(self.primary, 0) + 1
            return element
        except NoSuchElementException:
            pass
        
        # Try fallback locators
        for locator in self.fallbacks:
            try:
                element = driver.find_element(*locator)
                self.success_history[locator] = self.success_history.get(locator, 0) + 1
                
                # Promote successful fallback if it's more reliable
                if self.should_promote_locator(locator):
                    self.primary = locator
                    
                return element
            except NoSuchElementException:
                continue
        
        # All locators failed - attempt to discover new one
        return self.discover_new_locator(driver)
'''
```

The Automation Script Writer agent transforms test specifications into robust, maintainable automation code that accelerates testing while ensuring quality and reliability across all platforms and frameworks.