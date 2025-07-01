# Test Case Generator Integration Guide

## Overview
This guide provides comprehensive instructions for integrating the Test Case Generator with various development tools, CI/CD pipelines, test management systems, and automation frameworks.

## Table of Contents
1. [CI/CD Integration](#cicd-integration)
2. [Test Framework Integration](#test-framework-integration)
3. [Test Management Systems](#test-management-systems)
4. [API Integration](#api-integration)
5. [IDE Integration](#ide-integration)
6. [Version Control Integration](#version-control-integration)
7. [Monitoring and Reporting](#monitoring-and-reporting)

## CI/CD Integration

### GitHub Actions
```yaml
name: Automated Test Generation
on:
  pull_request:
    types: [opened, synchronize]
  push:
    branches: [main, develop]

jobs:
  generate-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Claude Flow
        run: |
          curl -fsSL https://claude.ai/install.sh | sh
          ./claude-flow auth --token ${{ secrets.CLAUDE_API_TOKEN }}
      
      - name: Detect Changed Requirements
        id: changes
        run: |
          echo "requirements=$(git diff --name-only ${{ github.event.before }} ${{ github.sha }} | grep -E '(requirements|stories)' | tr '\n' ' ')" >> $GITHUB_OUTPUT
      
      - name: Generate Test Cases
        if: steps.changes.outputs.requirements != ''
        run: |
          ./claude-flow workflow prd-to-test-plan.md \
            --input "${{ steps.changes.outputs.requirements }}" \
            --output test-artifacts/
      
      - name: Generate BDD Scenarios
        run: |
          ./claude-flow workflow bdd-scenario-generation.md \
            --input requirements/ \
            --output features/
      
      - name: Discover Edge Cases
        run: |
          ./claude-flow workflow edge-case-discovery.md \
            --feature "new-features" \
            --output test-artifacts/edge-cases.json
      
      - name: Upload Test Artifacts
        uses: actions/upload-artifact@v3
        with:
          name: generated-tests
          path: test-artifacts/
      
      - name: Comment PR with Test Summary
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v6
        with:
          script: |
            const fs = require('fs');
            const testPlan = JSON.parse(fs.readFileSync('test-artifacts/test-plan.json'));
            const comment = `## 🧪 Test Generation Summary
            
            - **Total Test Cases Generated**: ${testPlan.total_cases}
            - **Coverage**: ${testPlan.coverage}%
            - **Edge Cases Found**: ${testPlan.edge_cases}
            - **Execution Time Estimate**: ${testPlan.estimated_duration}
            
            [View Full Test Plan](https://github.com/${{ github.repository }}/actions/runs/${{ github.run_id }})`;
            
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: comment
            });
```

### Jenkins Pipeline
```groovy
pipeline {
    agent any
    
    parameters {
        choice(name: 'TEST_DEPTH', choices: ['quick', 'standard', 'comprehensive'], description: 'Test generation depth')
        booleanParam(name: 'INCLUDE_EDGE_CASES', defaultValue: true, description: 'Include edge case discovery')
        string(name: 'REQUIREMENTS_PATH', defaultValue: 'requirements/', description: 'Path to requirements')
    }
    
    stages {
        stage('Setup') {
            steps {
                sh '''
                    # Install Claude Flow if not present
                    if [ ! -f "./claude-flow" ]; then
                        curl -fsSL https://claude.ai/install.sh | sh
                    fi
                    ./claude-flow auth --token ${CLAUDE_API_TOKEN}
                '''
            }
        }
        
        stage('Analyze Requirements') {
            steps {
                script {
                    sh """
                        ./claude-flow agent spawn requirements-interpreter \
                            --input ${params.REQUIREMENTS_PATH} \
                            --depth ${params.TEST_DEPTH} \
                            --output requirements-analysis.json
                    """
                }
            }
        }
        
        stage('Generate Test Cases') {
            parallel {
                stage('Functional Tests') {
                    steps {
                        sh '''
                            ./claude-flow agent spawn scenario-builder \
                                --requirements requirements-analysis.json \
                                --type functional \
                                --output functional-tests.json
                        '''
                    }
                }
                
                stage('Integration Tests') {
                    steps {
                        sh '''
                            ./claude-flow agent spawn scenario-builder \
                                --requirements requirements-analysis.json \
                                --type integration \
                                --output integration-tests.json
                        '''
                    }
                }
                
                stage('Edge Cases') {
                    when {
                        expression { params.INCLUDE_EDGE_CASES }
                    }
                    steps {
                        sh '''
                            ./claude-flow workflow edge-case-discovery.md \
                                --requirements requirements-analysis.json \
                                --output edge-cases.json
                        '''
                    }
                }
            }
        }
        
        stage('Create Test Plan') {
            steps {
                sh '''
                    ./claude-flow agent spawn test-plan-architect \
                        --functional functional-tests.json \
                        --integration integration-tests.json \
                        --edge-cases edge-cases.json \
                        --output master-test-plan.json
                '''
            }
        }
        
        stage('Export to Test Management') {
            steps {
                sh '''
                    # Export to TestRail
                    ./claude-flow sparc "Export master-test-plan.json to TestRail format"
                    
                    # Upload to TestRail
                    python scripts/upload_to_testrail.py \
                        --plan master-test-plan.json \
                        --project ${TESTRAIL_PROJECT_ID}
                '''
            }
        }
    }
    
    post {
        always {
            archiveArtifacts artifacts: '*.json,features/**/*.feature', fingerprint: true
            
            publishHTML([
                allowMissing: false,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: 'test-reports',
                reportFiles: 'test-plan-summary.html',
                reportName: 'Test Plan Report'
            ])
        }
        
        success {
            emailext (
                subject: "Test Generation Complete: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                body: '''Test cases have been successfully generated.
                
                View the test plan: ${BUILD_URL}Test_20Plan_20Report/
                Total test cases: ${TEST_CASE_COUNT}
                Coverage: ${TEST_COVERAGE}%
                ''',
                to: "${env.TEAM_EMAIL}"
            )
        }
    }
}
```

### GitLab CI
```yaml
stages:
  - analyze
  - generate
  - integrate
  - report

variables:
  CLAUDE_FLOW_VERSION: "latest"
  TEST_OUTPUT_DIR: "generated-tests"

before_script:
  - |
    if [ ! -f "./claude-flow" ]; then
      curl -fsSL https://claude.ai/install.sh | sh
    fi
  - ./claude-flow auth --token $CLAUDE_API_TOKEN

analyze:requirements:
  stage: analyze
  script:
    - |
      ./claude-flow agent spawn requirements-interpreter \
        --input requirements/ \
        --output $TEST_OUTPUT_DIR/requirements.json
  artifacts:
    paths:
      - $TEST_OUTPUT_DIR/requirements.json
    expire_in: 1 week

generate:test-cases:
  stage: generate
  needs: ["analyze:requirements"]
  parallel:
    matrix:
      - TYPE: [functional, integration, edge-cases]
  script:
    - |
      case $TYPE in
        functional)
          ./claude-flow agent spawn scenario-builder \
            --requirements $TEST_OUTPUT_DIR/requirements.json \
            --type functional
          ;;
        integration)
          ./claude-flow agent spawn scenario-builder \
            --requirements $TEST_OUTPUT_DIR/requirements.json \
            --type integration
          ;;
        edge-cases)
          ./claude-flow workflow edge-case-discovery.md \
            --requirements $TEST_OUTPUT_DIR/requirements.json
          ;;
      esac
  artifacts:
    paths:
      - $TEST_OUTPUT_DIR/
    expire_in: 1 week

create:test-plan:
  stage: integrate
  needs: ["generate:test-cases"]
  script:
    - |
      ./claude-flow agent spawn test-plan-architect \
        --input $TEST_OUTPUT_DIR/ \
        --output $TEST_OUTPUT_DIR/master-test-plan.json
    - |
      # Convert to various formats
      ./claude-flow sparc "Convert test plan to Gherkin format"
      ./claude-flow sparc "Convert test plan to JUnit XML format"
  artifacts:
    paths:
      - $TEST_OUTPUT_DIR/
    reports:
      junit: $TEST_OUTPUT_DIR/junit-report.xml
    expire_in: 1 month

upload:to-test-management:
  stage: integrate
  needs: ["create:test-plan"]
  script:
    - |
      # Upload to Jira/Xray
      curl -X POST https://jira.company.com/rest/api/2/issue \
        -H "Authorization: Bearer $JIRA_TOKEN" \
        -H "Content-Type: application/json" \
        -d @$TEST_OUTPUT_DIR/jira-test-cases.json
  only:
    - main
    - develop
```

## Test Framework Integration

### Cypress Integration
```javascript
// cypress/plugins/claude-test-generator.js
const { exec } = require('child_process');
const fs = require('fs').promises;
const path = require('path');

module.exports = {
  async generateTestsFromRequirements(requirementsPath) {
    return new Promise((resolve, reject) => {
      exec(
        `./claude-flow sparc "Generate Cypress tests from ${requirementsPath}"`,
        async (error, stdout, stderr) => {
          if (error) {
            reject(error);
            return;
          }
          
          // Parse generated tests
          const generatedTests = JSON.parse(
            await fs.readFile('generated-cypress-tests.json', 'utf8')
          );
          
          // Create Cypress spec files
          for (const test of generatedTests.tests) {
            const specPath = path.join(
              'cypress/e2e/generated',
              `${test.feature}.cy.js`
            );
            
            const specContent = `
// Auto-generated by Claude Test Generator
describe('${test.feature}', () => {
  ${test.scenarios.map(scenario => `
  it('${scenario.name}', () => {
    ${scenario.steps.map(step => `
    // ${step.description}
    ${step.code}`).join('\n')}
  });
  `).join('\n')}
});
            `;
            
            await fs.writeFile(specPath, specContent);
          }
          
          resolve(generatedTests);
        }
      );
    });
  }
};

// cypress.config.js
const { defineConfig } = require('cypress');
const claudePlugin = require('./cypress/plugins/claude-test-generator');

module.exports = defineConfig({
  e2e: {
    setupNodeEvents(on, config) {
      on('task', {
        generateTests: claudePlugin.generateTestsFromRequirements
      });
    },
  },
});

// Usage in tests
describe('Dynamic Test Generation', () => {
  before(() => {
    cy.task('generateTests', 'requirements/new-feature.md');
  });
  
  it('should have generated tests available', () => {
    cy.readFile('cypress/e2e/generated/new-feature.cy.js').should('exist');
  });
});
```

### Jest Integration
```javascript
// jest-claude-generator.js
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

class JestTestGenerator {
  constructor(options = {}) {
    this.outputDir = options.outputDir || '__tests__/generated';
    this.templatePath = options.templatePath || 'templates/jest-test.js';
  }
  
  async generateUnitTests(componentPath) {
    const result = execSync(
      `./claude-flow sparc "Generate Jest unit tests for ${componentPath}"`,
      { encoding: 'utf8' }
    );
    
    const tests = JSON.parse(result);
    
    // Create test files
    tests.forEach(test => {
      const testPath = path.join(
        this.outputDir,
        `${test.component}.test.js`
      );
      
      const testContent = `
// Auto-generated test for ${test.component}
import { ${test.imports.join(', ')} } from '${test.importPath}';

describe('${test.component}', () => {
  ${test.testCases.map(tc => `
  test('${tc.description}', () => {
    ${tc.arrange}
    ${tc.act}
    ${tc.assert}
  });
  `).join('\n')}
});
      `;
      
      fs.writeFileSync(testPath, testContent);
    });
    
    return tests;
  }
  
  async generateIntegrationTests(apiSpec) {
    const result = execSync(
      `./claude-flow sparc "Generate Jest integration tests from ${apiSpec}"`,
      { encoding: 'utf8' }
    );
    
    return JSON.parse(result);
  }
}

// jest.setup.js
global.testGenerator = new JestTestGenerator({
  outputDir: '__tests__/generated',
  templatePath: 'templates/jest-test.js'
});

// Example usage in package.json scripts
{
  "scripts": {
    "test:generate": "node -e \"require('./jest-claude-generator').generateUnitTests('src/components')\"",
    "test:generate:api": "node -e \"require('./jest-claude-generator').generateIntegrationTests('api/swagger.yaml')\"",
    "test": "npm run test:generate && jest"
  }
}
```

### Playwright Integration
```typescript
// playwright-test-generator.ts
import { exec } from 'child_process';
import { promisify } from 'util';
import * as fs from 'fs/promises';
import * as path from 'path';

const execAsync = promisify(exec);

interface GeneratedTest {
  name: string;
  feature: string;
  scenarios: Array<{
    name: string;
    steps: Array<{
      action: string;
      selector?: string;
      value?: string;
      assertion?: string;
    }>;
  }>;
}

export class PlaywrightTestGenerator {
  private outputDir: string;
  
  constructor(outputDir = 'tests/e2e/generated') {
    this.outputDir = outputDir;
  }
  
  async generateE2ETests(userStoryPath: string): Promise<GeneratedTest[]> {
    const { stdout } = await execAsync(
      `./claude-flow sparc "Generate Playwright E2E tests from ${userStoryPath}"`
    );
    
    const tests: GeneratedTest[] = JSON.parse(stdout);
    
    for (const test of tests) {
      const testPath = path.join(
        this.outputDir,
        `${test.feature}.spec.ts`
      );
      
      const testContent = this.generatePlaywrightTest(test);
      await fs.writeFile(testPath, testContent);
    }
    
    return tests;
  }
  
  private generatePlaywrightTest(test: GeneratedTest): string {
    return `
// Auto-generated Playwright test for ${test.feature}
import { test, expect } from '@playwright/test';

test.describe('${test.feature}', () => {
  ${test.scenarios.map(scenario => `
  test('${scenario.name}', async ({ page }) => {
    ${scenario.steps.map(step => this.generateStep(step)).join('\n    ')}
  });
  `).join('\n')}
});
    `.trim();
  }
  
  private generateStep(step: any): string {
    switch (step.action) {
      case 'navigate':
        return `await page.goto('${step.value}');`;
      case 'click':
        return `await page.click('${step.selector}');`;
      case 'fill':
        return `await page.fill('${step.selector}', '${step.value}');`;
      case 'assert':
        return `await expect(page.locator('${step.selector}')).${step.assertion};`;
      default:
        return `// TODO: ${step.action}`;
    }
  }
}

// playwright.config.ts
import { defineConfig } from '@playwright/test';
import { PlaywrightTestGenerator } from './playwright-test-generator';

// Generate tests before running
const generator = new PlaywrightTestGenerator();
generator.generateE2ETests('requirements/user-stories.md');

export default defineConfig({
  testDir: './tests',
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
});
```

## Test Management Systems

### Jira/Xray Integration
```python
# jira_xray_integration.py
import json
import requests
from typing import List, Dict
import subprocess

class JiraXrayIntegration:
    def __init__(self, jira_url: str, auth_token: str):
        self.jira_url = jira_url
        self.headers = {
            'Authorization': f'Bearer {auth_token}',
            'Content-Type': 'application/json'
        }
    
    def generate_and_upload_tests(self, requirements_path: str, project_key: str):
        # Generate test cases using Claude Flow
        result = subprocess.run(
            ['./claude-flow', 'workflow', 'prd-to-test-plan.md',
             '--input', requirements_path,
             '--output', 'test-cases.json'],
            capture_output=True,
            text=True
        )
        
        with open('test-cases.json', 'r') as f:
            test_cases = json.load(f)
        
        # Convert to Xray format and upload
        for test in test_cases['test_cases']:
            xray_test = self.convert_to_xray_format(test, project_key)
            self.create_xray_test(xray_test)
    
    def convert_to_xray_format(self, test_case: Dict, project_key: str) -> Dict:
        return {
            "fields": {
                "project": {"key": project_key},
                "summary": test_case['title'],
                "description": test_case['description'],
                "issuetype": {"name": "Test"},
                "customfield_10100": {  # Test Type
                    "value": test_case['type']
                },
                "customfield_10101": test_case['steps']  # Test Steps
            }
        }
    
    def create_xray_test(self, xray_test: Dict) -> str:
        response = requests.post(
            f"{self.jira_url}/rest/api/2/issue",
            headers=self.headers,
            json=xray_test
        )
        response.raise_for_status()
        return response.json()['key']
    
    def create_test_execution(self, test_keys: List[str], version: str):
        execution = {
            "fields": {
                "project": {"key": "PROJ"},
                "summary": f"Test Execution for {version}",
                "issuetype": {"name": "Test Execution"},
                "fixVersions": [{"name": version}]
            }
        }
        
        response = requests.post(
            f"{self.jira_url}/rest/api/2/issue",
            headers=self.headers,
            json=execution
        )
        
        execution_key = response.json()['key']
        
        # Add tests to execution
        for test_key in test_keys:
            self.add_test_to_execution(execution_key, test_key)
        
        return execution_key

# Usage
if __name__ == "__main__":
    integration = JiraXrayIntegration(
        jira_url="https://company.atlassian.net",
        auth_token="your-token"
    )
    
    integration.generate_and_upload_tests(
        requirements_path="requirements/",
        project_key="PROJ"
    )
```

### TestRail Integration
```ruby
# testrail_integration.rb
require 'json'
require 'net/http'

class TestRailIntegration
  def initialize(base_url, username, api_key)
    @base_url = base_url
    @auth = "Basic #{Base64.encode64("#{username}:#{api_key}")}"
  end
  
  def generate_and_sync_tests(requirements_path, project_id, suite_id)
    # Generate test cases
    test_cases = generate_test_cases(requirements_path)
    
    # Create test cases in TestRail
    test_cases.each do |test|
      create_test_case(project_id, suite_id, test)
    end
    
    # Create test plan
    create_test_plan(project_id, test_cases)
  end
  
  private
  
  def generate_test_cases(requirements_path)
    result = `./claude-flow workflow prd-to-test-plan.md --input #{requirements_path} --output -`
    JSON.parse(result)['test_cases']
  end
  
  def create_test_case(project_id, suite_id, test)
    uri = URI("#{@base_url}/index.php?/api/v2/add_case/#{suite_id}")
    
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = @auth
    request['Content-Type'] = 'application/json'
    
    request.body = {
      title: test['title'],
      type_id: map_test_type(test['type']),
      priority_id: map_priority(test['priority']),
      estimate: test['estimated_duration'],
      refs: test['requirement_id'],
      custom_steps: test['steps'].map do |step|
        {
          content: step['action'],
          expected: step['expected']
        }
      end
    }.to_json
    
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
    
    JSON.parse(response.body)
  end
  
  def map_test_type(type)
    {
      'functional' => 1,
      'integration' => 2,
      'performance' => 3,
      'security' => 4
    }[type.downcase] || 1
  end
  
  def map_priority(priority)
    {
      'critical' => 5,
      'high' => 4,
      'medium' => 3,
      'low' => 2
    }[priority.downcase] || 3
  end
end
```

## API Integration

### REST API Wrapper
```python
# claude_test_api.py
from flask import Flask, request, jsonify
import subprocess
import json
import os

app = Flask(__name__)

@app.route('/api/generate/test-cases', methods=['POST'])
def generate_test_cases():
    """
    Generate test cases from requirements
    
    POST /api/generate/test-cases
    {
        "requirements": "path/to/requirements.md",
        "type": "functional|integration|all",
        "include_edge_cases": true,
        "output_format": "json|gherkin|markdown"
    }
    """
    data = request.json
    
    command = [
        './claude-flow', 'workflow', 'prd-to-test-plan.md',
        '--input', data['requirements'],
        '--type', data.get('type', 'all'),
        '--format', data.get('output_format', 'json')
    ]
    
    if data.get('include_edge_cases'):
        command.append('--edge-cases')
    
    try:
        result = subprocess.run(command, capture_output=True, text=True, check=True)
        output = json.loads(result.stdout)
        
        return jsonify({
            'success': True,
            'test_cases': output['test_cases'],
            'total_count': len(output['test_cases']),
            'coverage': output.get('coverage', 'N/A')
        })
    except subprocess.CalledProcessError as e:
        return jsonify({
            'success': False,
            'error': str(e),
            'stderr': e.stderr
        }), 500

@app.route('/api/generate/bdd-scenarios', methods=['POST'])
def generate_bdd_scenarios():
    """
    Generate BDD scenarios from user stories
    
    POST /api/generate/bdd-scenarios
    {
        "user_stories": "path/to/stories.md",
        "tags": ["@smoke", "@regression"],
        "examples": true
    }
    """
    data = request.json
    
    command = [
        './claude-flow', 'workflow', 'bdd-scenario-generation.md',
        '--input', data['user_stories']
    ]
    
    if data.get('tags'):
        command.extend(['--tags', ','.join(data['tags'])])
    
    if data.get('examples'):
        command.append('--with-examples')
    
    result = subprocess.run(command, capture_output=True, text=True)
    
    return jsonify({
        'success': result.returncode == 0,
        'scenarios': result.stdout,
        'error': result.stderr if result.returncode != 0 else None
    })

@app.route('/api/discover/edge-cases', methods=['POST'])
def discover_edge_cases():
    """
    Discover edge cases for a feature
    
    POST /api/discover/edge-cases
    {
        "feature": "login-form",
        "depth": "shallow|standard|deep",
        "categories": ["security", "performance", "boundary"]
    }
    """
    data = request.json
    
    command = [
        './claude-flow', 'workflow', 'edge-case-discovery.md',
        '--feature', data['feature'],
        '--depth', data.get('depth', 'standard')
    ]
    
    if data.get('categories'):
        command.extend(['--categories', ','.join(data['categories'])])
    
    result = subprocess.run(command, capture_output=True, text=True)
    edge_cases = json.loads(result.stdout)
    
    return jsonify({
        'success': True,
        'edge_cases': edge_cases,
        'critical_count': len([e for e in edge_cases if e['severity'] == 'critical']),
        'total_count': len(edge_cases)
    })

if __name__ == '__main__':
    app.run(debug=True, port=5000)
```

### GraphQL API
```javascript
// graphql-schema.js
const { GraphQLSchema, GraphQLObjectType, GraphQLString, GraphQLList, GraphQLBoolean, GraphQLInt } = require('graphql');
const { exec } = require('child_process');
const { promisify } = require('util');

const execAsync = promisify(exec);

const TestCaseType = new GraphQLObjectType({
  name: 'TestCase',
  fields: {
    id: { type: GraphQLString },
    title: { type: GraphQLString },
    description: { type: GraphQLString },
    priority: { type: GraphQLString },
    type: { type: GraphQLString },
    steps: { type: new GraphQLList(GraphQLString) }
  }
});

const EdgeCaseType = new GraphQLObjectType({
  name: 'EdgeCase',
  fields: {
    id: { type: GraphQLString },
    category: { type: GraphQLString },
    description: { type: GraphQLString },
    severity: { type: GraphQLString },
    testData: { type: GraphQLString }
  }
});

const RootQuery = new GraphQLObjectType({
  name: 'RootQueryType',
  fields: {
    generateTestCases: {
      type: new GraphQLList(TestCaseType),
      args: {
        requirements: { type: GraphQLString },
        includeEdgeCases: { type: GraphQLBoolean }
      },
      async resolve(parent, args) {
        const command = `./claude-flow sparc "Generate test cases from ${args.requirements}"`;
        const { stdout } = await execAsync(command);
        return JSON.parse(stdout).test_cases;
      }
    },
    
    discoverEdgeCases: {
      type: new GraphQLList(EdgeCaseType),
      args: {
        feature: { type: GraphQLString },
        depth: { type: GraphQLString }
      },
      async resolve(parent, args) {
        const command = `./claude-flow workflow edge-case-discovery.md --feature ${args.feature} --depth ${args.depth || 'standard'}`;
        const { stdout } = await execAsync(command);
        return JSON.parse(stdout).edge_cases;
      }
    }
  }
});

module.exports = new GraphQLSchema({
  query: RootQuery
});
```

## IDE Integration

### VS Code Extension
```typescript
// vscode-extension/src/extension.ts
import * as vscode from 'vscode';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

export function activate(context: vscode.ExtensionContext) {
  // Command: Generate test cases from current file
  let generateTests = vscode.commands.registerCommand(
    'claude-test-generator.generateTests',
    async () => {
      const editor = vscode.window.activeTextEditor;
      if (!editor) {
        vscode.window.showErrorMessage('No active file');
        return;
      }
      
      const filePath = editor.document.fileName;
      
      try {
        const { stdout } = await execAsync(
          `./claude-flow sparc "Generate test cases from ${filePath}"`
        );
        
        const tests = JSON.parse(stdout);
        
        // Create new file with generated tests
        const testContent = formatTestCases(tests);
        const testDoc = await vscode.workspace.openTextDocument({
          content: testContent,
          language: 'javascript'
        });
        
        await vscode.window.showTextDocument(testDoc);
        
        vscode.window.showInformationMessage(
          `Generated ${tests.test_cases.length} test cases`
        );
      } catch (error) {
        vscode.window.showErrorMessage(`Error: ${error.message}`);
      }
    }
  );
  
  // Command: Discover edge cases for selected code
  let discoverEdgeCases = vscode.commands.registerCommand(
    'claude-test-generator.discoverEdgeCases',
    async () => {
      const editor = vscode.window.activeTextEditor;
      const selection = editor.selection;
      const selectedText = editor.document.getText(selection);
      
      if (!selectedText) {
        vscode.window.showErrorMessage('No code selected');
        return;
      }
      
      const { stdout } = await execAsync(
        `./claude-flow sparc "Find edge cases for: ${selectedText}"`
      );
      
      const edgeCases = JSON.parse(stdout);
      
      // Show edge cases in panel
      const panel = vscode.window.createWebviewPanel(
        'edgeCases',
        'Edge Cases',
        vscode.ViewColumn.Two,
        {}
      );
      
      panel.webview.html = getEdgeCaseHTML(edgeCases);
    }
  );
  
  context.subscriptions.push(generateTests, discoverEdgeCases);
}

function formatTestCases(tests: any): string {
  return tests.test_cases.map(test => `
describe('${test.title}', () => {
  test('${test.description}', () => {
    ${test.steps.map(step => `
    // ${step.action}
    // Expected: ${step.expected}`).join('\n')}
  });
});
  `).join('\n\n');
}

function getEdgeCaseHTML(edgeCases: any): string {
  return `
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; padding: 20px; }
    .edge-case { margin: 20px 0; padding: 15px; border: 1px solid #ddd; }
    .critical { border-color: #f00; background: #fee; }
    .high { border-color: #fa0; background: #ffe; }
  </style>
</head>
<body>
  <h1>Edge Cases Discovered</h1>
  ${edgeCases.map(edge => `
    <div class="edge-case ${edge.severity}">
      <h3>${edge.description}</h3>
      <p><strong>Category:</strong> ${edge.category}</p>
      <p><strong>Severity:</strong> ${edge.severity}</p>
      <p><strong>Test Data:</strong> <code>${edge.testData}</code></p>
    </div>
  `).join('')}
</body>
</html>
  `;
}
```

### IntelliJ IDEA Plugin
```java
// TestGeneratorAction.java
package com.claude.testgenerator;

import com.intellij.openapi.actionSystem.AnAction;
import com.intellij.openapi.actionSystem.AnActionEvent;
import com.intellij.openapi.actionSystem.CommonDataKeys;
import com.intellij.openapi.project.Project;
import com.intellij.openapi.vfs.VirtualFile;
import com.intellij.openapi.command.WriteCommandAction;
import com.intellij.openapi.fileEditor.FileEditorManager;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.stream.Collectors;

public class TestGeneratorAction extends AnAction {
    
    @Override
    public void actionPerformed(AnActionEvent e) {
        Project project = e.getProject();
        VirtualFile file = e.getData(CommonDataKeys.VIRTUAL_FILE);
        
        if (project == null || file == null) {
            return;
        }
        
        try {
            // Generate tests using Claude Flow
            Process process = new ProcessBuilder(
                "./claude-flow", "sparc", 
                "Generate JUnit tests from " + file.getPath()
            ).start();
            
            String output = new BufferedReader(
                new InputStreamReader(process.getInputStream())
            ).lines().collect(Collectors.joining("\n"));
            
            // Parse and create test file
            String testContent = parseTestContent(output);
            String testFileName = file.getNameWithoutExtension() + "Test.java";
            
            WriteCommandAction.runWriteCommandAction(project, () -> {
                try {
                    VirtualFile testDir = project.getBaseDir()
                        .findChild("src")
                        .findChild("test")
                        .findChild("java");
                    
                    VirtualFile testFile = testDir.createChildData(this, testFileName);
                    testFile.setBinaryContent(testContent.getBytes());
                    
                    FileEditorManager.getInstance(project).openFile(testFile, true);
                } catch (Exception ex) {
                    ex.printStackTrace();
                }
            });
            
        } catch (Exception ex) {
            ex.printStackTrace();
        }
    }
    
    private String parseTestContent(String claudeOutput) {
        // Parse Claude output and format as Java test
        return """
            import org.junit.jupiter.api.Test;
            import static org.junit.jupiter.api.Assertions.*;
            
            public class GeneratedTest {
                @Test
                void testGenerated() {
                    // Generated test content
                }
            }
            """;
    }
}
```

## Version Control Integration

### Git Hooks
```bash
#!/bin/bash
# .git/hooks/pre-commit
# Generate tests for changed files

echo "Generating tests for changed files..."

# Get list of changed requirement files
CHANGED_REQS=$(git diff --cached --name-only | grep -E "(requirements|stories|specs)")

if [ -n "$CHANGED_REQS" ]; then
    echo "Found changed requirements: $CHANGED_REQS"
    
    # Generate test cases
    ./claude-flow workflow prd-to-test-plan.md \
        --input "$CHANGED_REQS" \
        --output generated-tests/
    
    # Add generated tests to commit
    git add generated-tests/
    
    echo "Test cases generated and added to commit"
fi

# Run test validation
./claude-flow sparc "Validate test coverage for changed requirements"

exit 0
```

### GitHub App
```javascript
// github-app.js
const { App } = require('@octokit/app');
const { exec } = require('child_process');
const { promisify } = require('util');

const execAsync = promisify(exec);

const app = new App({
  appId: process.env.GITHUB_APP_ID,
  privateKey: process.env.GITHUB_PRIVATE_KEY,
});

module.exports = async (req, res) => {
  const { action, pull_request } = req.body;
  
  if (action !== 'opened' && action !== 'synchronize') {
    return res.status(200).send('OK');
  }
  
  const installationAccessToken = await app.getInstallationAccessToken({
    installationId: req.body.installation.id,
  });
  
  // Get changed files
  const changedFiles = await getChangedFiles(
    pull_request.base.repo.full_name,
    pull_request.number,
    installationAccessToken
  );
  
  // Filter for requirement files
  const requirementFiles = changedFiles.filter(f => 
    f.match(/\.(md|txt|yaml)$/) && f.includes('requirements')
  );
  
  if (requirementFiles.length > 0) {
    // Generate test cases
    const testCases = await generateTestCases(requirementFiles);
    
    // Comment on PR
    await commentOnPR(
      pull_request.base.repo.full_name,
      pull_request.number,
      formatTestSummary(testCases),
      installationAccessToken
    );
  }
  
  res.status(200).send('OK');
};

async function generateTestCases(files) {
  const { stdout } = await execAsync(
    `./claude-flow workflow prd-to-test-plan.md --input "${files.join(' ')}"`
  );
  return JSON.parse(stdout);
}

function formatTestSummary(testCases) {
  return `## 🧪 Test Case Generation Summary

Based on the requirement changes in this PR, I've generated the following test cases:

- **Total Test Cases**: ${testCases.total_cases}
- **Functional Tests**: ${testCases.functional_count}
- **Integration Tests**: ${testCases.integration_count}
- **Edge Cases**: ${testCases.edge_case_count}

### Coverage Analysis
- **Requirement Coverage**: ${testCases.coverage}%
- **Risk Coverage**: ${testCases.risk_coverage}%

### Execution Estimate
- **Manual Testing**: ${testCases.manual_duration}
- **Automated Testing**: ${testCases.automated_duration}

<details>
<summary>View Generated Test Cases</summary>

\`\`\`json
${JSON.stringify(testCases.test_cases, null, 2)}
\`\`\`

</details>

### Next Steps
1. Review the generated test cases
2. Run \`npm run test:generated\` to execute automated tests
3. Update test cases if requirements change
`;
}
```

## Monitoring and Reporting

### Metrics Dashboard
```python
# metrics_dashboard.py
from flask import Flask, render_template
import json
from datetime import datetime, timedelta
import sqlite3

app = Flask(__name__)

@app.route('/dashboard')
def dashboard():
    # Get test generation metrics
    metrics = get_test_generation_metrics()
    
    return render_template('dashboard.html', metrics=metrics)

def get_test_generation_metrics():
    conn = sqlite3.connect('test_metrics.db')
    cursor = conn.cursor()
    
    # Get metrics for last 30 days
    thirty_days_ago = (datetime.now() - timedelta(days=30)).isoformat()
    
    cursor.execute("""
        SELECT 
            COUNT(*) as total_generations,
            SUM(test_case_count) as total_test_cases,
            AVG(coverage_percentage) as avg_coverage,
            SUM(edge_case_count) as total_edge_cases,
            AVG(generation_time) as avg_generation_time
        FROM test_generations
        WHERE created_at > ?
    """, (thirty_days_ago,))
    
    metrics = cursor.fetchone()
    
    # Get breakdown by type
    cursor.execute("""
        SELECT test_type, COUNT(*) as count
        FROM test_cases
        WHERE created_at > ?
        GROUP BY test_type
    """, (thirty_days_ago,))
    
    type_breakdown = cursor.fetchall()
    
    conn.close()
    
    return {
        'total_generations': metrics[0],
        'total_test_cases': metrics[1],
        'avg_coverage': metrics[2],
        'total_edge_cases': metrics[3],
        'avg_generation_time': metrics[4],
        'type_breakdown': dict(type_breakdown)
    }

# Log test generation events
def log_generation_event(event_data):
    conn = sqlite3.connect('test_metrics.db')
    cursor = conn.cursor()
    
    cursor.execute("""
        INSERT INTO test_generations 
        (created_at, test_case_count, coverage_percentage, edge_case_count, generation_time)
        VALUES (?, ?, ?, ?, ?)
    """, (
        datetime.now().isoformat(),
        event_data['test_case_count'],
        event_data['coverage_percentage'],
        event_data['edge_case_count'],
        event_data['generation_time']
    ))
    
    conn.commit()
    conn.close()
```

### Slack Integration
```javascript
// slack-integration.js
const { WebClient } = require('@slack/web-api');
const { exec } = require('child_process');
const { promisify } = require('util');

const execAsync = promisify(exec);
const slack = new WebClient(process.env.SLACK_TOKEN);

async function notifyTestGeneration(channelId, requirementsPath) {
  // Generate tests
  const startTime = Date.now();
  const { stdout } = await execAsync(
    `./claude-flow workflow prd-to-test-plan.md --input ${requirementsPath}`
  );
  const duration = (Date.now() - startTime) / 1000;
  
  const results = JSON.parse(stdout);
  
  // Send Slack notification
  await slack.chat.postMessage({
    channel: channelId,
    blocks: [
      {
        type: 'header',
        text: {
          type: 'plain_text',
          text: '🧪 Test Cases Generated'
        }
      },
      {
        type: 'section',
        fields: [
          {
            type: 'mrkdwn',
            text: `*Total Tests:*\n${results.total_cases}`
          },
          {
            type: 'mrkdwn',
            text: `*Coverage:*\n${results.coverage}%`
          },
          {
            type: 'mrkdwn',
            text: `*Edge Cases:*\n${results.edge_cases}`
          },
          {
            type: 'mrkdwn',
            text: `*Duration:*\n${duration}s`
          }
        ]
      },
      {
        type: 'actions',
        elements: [
          {
            type: 'button',
            text: {
              type: 'plain_text',
              text: 'View Test Plan'
            },
            url: `${process.env.BASE_URL}/test-plans/${results.plan_id}`
          },
          {
            type: 'button',
            text: {
              type: 'plain_text',
              text: 'Download Tests'
            },
            url: `${process.env.BASE_URL}/api/download/${results.plan_id}`
          }
        ]
      }
    ]
  });
}

// Slash command handler
async function handleSlashCommand(req, res) {
  const { text, channel_id } = req.body;
  
  // Acknowledge command
  res.status(200).send('Generating test cases...');
  
  // Process in background
  try {
    await notifyTestGeneration(channel_id, text);
  } catch (error) {
    await slack.chat.postMessage({
      channel: channel_id,
      text: `❌ Error generating tests: ${error.message}`
    });
  }
}

module.exports = { handleSlashCommand, notifyTestGeneration };
```

## Best Practices

1. **Automate Test Generation**: Integrate into CI/CD for automatic test updates
2. **Version Control Tests**: Store generated tests alongside code
3. **Monitor Coverage**: Track test coverage trends over time
4. **Regular Reviews**: Periodically review and update generated tests
5. **Custom Templates**: Create project-specific test templates
6. **Incremental Generation**: Only regenerate tests for changed requirements
7. **Quality Gates**: Set minimum coverage thresholds
8. **Documentation**: Keep integration documentation up-to-date