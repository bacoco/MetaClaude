# Edge Case Discovery Workflow

## Overview
This workflow systematically discovers edge cases across all domains using AI-driven analysis, multiple discovery techniques, and coordinated agent swarms. It identifies boundary conditions, security vulnerabilities, performance limits, and exceptional scenarios that might compromise system reliability.

## Workflow Purpose

### Core Objectives
- **Systematic Domain Coverage**: Comprehensive edge case discovery across all system domains
- **Multi-Technique Analysis**: Employ boundary analysis, fault injection, and combinatorial testing
- **Security Focus**: Identify attack vectors and vulnerability edge cases
- **Performance Limits**: Discover concurrency and performance breaking points
- **Risk-Based Prioritization**: Create prioritized test suites with risk assessments
- **Mitigation Strategies**: Provide actionable remediation for discovered edge cases

## Workflow Architecture

### Agent Coordination Model
```yaml
orchestration:
  mode: hierarchical
  coordinator: edge-case-orchestrator
  
agents:
  domain_analyzers:
    - input_boundary_analyzer
    - state_space_explorer
    - integration_edge_finder
    - security_vulnerability_scanner
    - performance_limit_tester
    - concurrency_edge_detector
    
  technique_specialists:
    - boundary_value_analyst
    - fault_injection_expert
    - combinatorial_tester
    - mutation_specialist
    - fuzzing_agent
    
  assessment_team:
    - risk_assessor
    - prioritization_engine
    - mitigation_strategist
    - test_suite_generator
```

## Discovery Techniques

### 1. Boundary Value Analysis (BVA)
```python
class BoundaryAnalyzer:
    """Systematic boundary value discovery"""
    
    def analyze_numeric_boundaries(self, field, constraints):
        boundaries = {
            'exact_boundaries': [
                constraints['min'],
                constraints['max']
            ],
            'near_boundaries': [
                constraints['min'] - 1,
                constraints['min'] + 1,
                constraints['max'] - 1,
                constraints['max'] + 1
            ],
            'type_boundaries': [
                sys.maxsize,
                -sys.maxsize - 1,
                sys.float_info.max,
                sys.float_info.min,
                sys.float_info.epsilon
            ],
            'special_values': [
                0, -0, 0.0,
                float('inf'), float('-inf'), float('nan'),
                None, '', []
            ]
        }
        
        # Domain-specific boundaries
        if field.type == 'currency':
            boundaries['precision_edges'] = [
                0.001, 0.01, 0.1,  # Sub-cent values
                999999.99,  # Near million
                -0.01  # Negative currency
            ]
        
        return boundaries
```

### 2. Fault Injection Testing
```javascript
class FaultInjector {
  constructor() {
    this.faultTypes = {
      network: ['timeout', 'partial_response', 'connection_reset', 'dns_failure'],
      resource: ['memory_exhaustion', 'disk_full', 'cpu_spike', 'thread_pool_exhaustion'],
      dependency: ['service_down', 'slow_response', 'invalid_response', 'version_mismatch'],
      data: ['corruption', 'encoding_error', 'truncation', 'duplication'],
      timing: ['race_condition', 'deadlock', 'clock_skew', 'timeout_cascade']
    };
  }
  
  generateFaultScenarios(system) {
    const scenarios = [];
    
    // Single fault injection
    for (const [category, faults] of Object.entries(this.faultTypes)) {
      for (const fault of faults) {
        scenarios.push({
          type: 'single_fault',
          category,
          fault,
          injection_point: this.identifyInjectionPoint(system, fault),
          expected_behavior: this.defineExpectedBehavior(fault),
          recovery_strategy: this.determineRecovery(fault)
        });
      }
    }
    
    // Cascading fault scenarios
    scenarios.push(...this.generateCascadingFaults(system));
    
    // Byzantine fault scenarios
    scenarios.push(...this.generateByzantineFaults(system));
    
    return scenarios;
  }
}
```

### 3. Combinatorial Testing
```python
class CombinatorialTester:
    """Generate n-wise parameter combinations for edge discovery"""
    
    def generate_pairwise_combinations(self, parameters):
        """Generate all 2-way parameter combinations"""
        from itertools import combinations, product
        
        # Define parameter domains with edge values
        param_domains = {
            'user_type': ['guest', 'free', 'premium', 'admin', 'suspended'],
            'data_size': ['empty', '1_byte', '1KB', '1MB', '1GB', 'max_allowed'],
            'connection': ['fast', 'slow', 'intermittent', 'offline', 'proxy'],
            'locale': ['en-US', 'ar-SA', 'zh-CN', 'he-IL', 'emoji_only'],
            'device': ['desktop', 'mobile', 'tablet', 'iot', 'legacy_browser'],
            'concurrent_users': [1, 10, 100, 1000, 10000, 'max_capacity']
        }
        
        # Generate pairwise combinations
        test_cases = []
        param_names = list(param_domains.keys())
        
        for pair in combinations(param_names, 2):
            param1, param2 = pair
            for val1, val2 in product(param_domains[param1], param_domains[param2]):
                # Check if this is an edge combination
                if self.is_edge_combination(param1, val1, param2, val2):
                    test_cases.append({
                        'combination': {param1: val1, param2: val2},
                        'risk_score': self.calculate_risk(param1, val1, param2, val2),
                        'category': self.categorize_edge(param1, val1, param2, val2)
                    })
        
        return sorted(test_cases, key=lambda x: x['risk_score'], reverse=True)
```

### 4. Security Edge Case Discovery
```yaml
security_edge_discovery:
  attack_vectors:
    injection:
      sql_injection:
        basic:
          - "' OR '1'='1"
          - "1'; DROP TABLE users; --"
          - "admin'--"
        advanced:
          - "1' UNION SELECT NULL, username, password FROM users--"
          - "' AND (SELECT * FROM (SELECT(SLEEP(5)))a)--"
          - "1' AND extractvalue(1,concat(0x7e,(SELECT database()),0x7e))--"
        blind:
          - "1' AND IF(1=1, SLEEP(5), 0)--"
          - "1' AND (SELECT CASE WHEN (1=1) THEN pg_sleep(5) ELSE pg_sleep(0) END)--"
          
      command_injection:
        - "; ls -la"
        - "| whoami"
        - "$(cat /etc/passwd)"
        - "`rm -rf /`"
        - "&& net user hacker password /add"
        
      ldap_injection:
        - "*)(uid=*))(|(uid=*"
        - "admin)(&(password=*))"
        - "*)(mail=*))(|(mail=*"
        
      xpath_injection:
        - "' or '1'='1"
        - "'] | //user[password='password"
        - "' and count(/*)=1 and '1'='1"
        
    authentication_bypass:
      jwt_attacks:
        - algorithm_none: "alg: none"
        - key_confusion: "RS256 to HS256"
        - expired_token: "exp: past_timestamp"
        - kid_injection: "kid: ../../../../../../dev/null"
        
      session_attacks:
        - session_fixation
        - session_hijacking
        - concurrent_session_limit_bypass
        - session_timeout_bypass
        
    authorization_flaws:
      - horizontal_privilege_escalation
      - vertical_privilege_escalation
      - insecure_direct_object_reference
      - missing_function_level_access_control
      
    business_logic:
      - negative_quantity_purchase
      - price_manipulation
      - race_condition_double_spending
      - workflow_bypass
      - state_manipulation
```

### 5. Performance and Concurrency Edge Cases
```javascript
class PerformanceEdgeDiscovery {
  constructor() {
    this.patterns = {
      concurrency: {
        race_conditions: [
          'read-modify-write',
          'check-then-act',
          'compound_operations',
          'lazy_initialization'
        ],
        
        deadlocks: [
          'circular_wait',
          'nested_locks',
          'lock_ordering',
          'resource_starvation'
        ],
        
        resource_contention: [
          'connection_pool_exhaustion',
          'thread_pool_saturation',
          'cache_stampede',
          'database_lock_contention'
        ]
      },
      
      performance_boundaries: {
        memory: [
          'heap_exhaustion',
          'stack_overflow',
          'memory_leak_accumulation',
          'gc_pressure'
        ],
        
        cpu: [
          'algorithmic_complexity',
          'infinite_loops',
          'regex_catastrophic_backtracking',
          'fork_bomb'
        ],
        
        io: [
          'disk_full',
          'network_saturation',
          'file_descriptor_exhaustion',
          'bandwidth_limits'
        ]
      },
      
      scalability_edges: {
        data_volume: [
          'large_result_sets',
          'unbounded_queries',
          'cartesian_products',
          'exponential_growth'
        ],
        
        concurrent_load: [
          'thundering_herd',
          'cascade_failure',
          'retry_storm',
          'feedback_loop'
        ]
      }
    };
  }
  
  generateConcurrencyTests(system) {
    return {
      scenarios: [
        {
          name: 'Distributed Lock Race',
          setup: 'Multiple nodes acquiring same distributed lock',
          edge: 'Network partition during lock acquisition',
          test: 'Verify split-brain prevention'
        },
        {
          name: 'Database Transaction Isolation',
          setup: 'Concurrent transactions on same data',
          edge: 'Phantom reads, lost updates',
          test: 'Verify isolation level handling'
        },
        {
          name: 'Event Ordering',
          setup: 'Distributed event processing',
          edge: 'Out-of-order event delivery',
          test: 'Verify eventual consistency'
        }
      ]
    };
  }
}
```

## Categorization System

### Risk-Based Categories
```yaml
categorization:
  dimensions:
    severity:
      critical: "System crash, data loss, security breach"
      high: "Service degradation, data corruption risk"
      medium: "Feature malfunction, poor user experience"
      low: "Minor inconvenience, cosmetic issues"
      
    likelihood:
      very_high: "Will occur in normal usage"
      high: "Likely under specific conditions"
      medium: "Possible with edge inputs"
      low: "Requires deliberate exploitation"
      very_low: "Theoretical or requires multiple failures"
      
    impact_area:
      security: "Authentication, authorization, data protection"
      data_integrity: "Data consistency, accuracy, completeness"
      availability: "Service uptime, performance, scalability"
      compliance: "Regulatory requirements, standards"
      user_experience: "Usability, accessibility, satisfaction"
      
  risk_matrix:
    critical_high: "Immediate fix required"
    critical_medium: "Fix in current sprint"
    high_high: "Fix in next release"
    high_medium: "Schedule for remediation"
    medium_any: "Add to backlog"
    low_any: "Document and monitor"
```

### Domain-Specific Categories
```json
{
  "domain_categories": {
    "financial": {
      "edge_types": [
        "precision_rounding",
        "currency_conversion",
        "negative_balance",
        "transaction_timing",
        "regulatory_limits"
      ],
      "specific_cases": [
        {
          "name": "Fractional Cent Handling",
          "scenario": "0.001 USD transaction",
          "risk": "Accumulation of rounding errors"
        },
        {
          "name": "Cross-Border Transaction",
          "scenario": "Currency conversion at midnight UTC",
          "risk": "Rate change during processing"
        }
      ]
    },
    
    "healthcare": {
      "edge_types": [
        "patient_safety",
        "data_privacy",
        "drug_interactions",
        "dosage_calculations",
        "emergency_protocols"
      ],
      "specific_cases": [
        {
          "name": "Allergy Cascade",
          "scenario": "Multiple conflicting allergies",
          "risk": "Medication recommendation conflict"
        },
        {
          "name": "Time Zone Medication",
          "scenario": "Dosage schedule across time zones",
          "risk": "Missed or duplicate doses"
        }
      ]
    },
    
    "iot": {
      "edge_types": [
        "connectivity_loss",
        "sensor_malfunction",
        "firmware_corruption",
        "power_failures",
        "environmental_extremes"
      ],
      "specific_cases": [
        {
          "name": "Sensor Drift",
          "scenario": "Gradual sensor calibration loss",
          "risk": "Incorrect critical measurements"
        },
        {
          "name": "Network Partition",
          "scenario": "Device cluster split",
          "risk": "Conflicting device states"
        }
      ]
    }
  }
}
```

## Prioritized Test Suite Generation

### Priority Algorithm
```python
class TestSuitePrioritizer:
    def __init__(self):
        self.weights = {
            'severity': 0.4,
            'likelihood': 0.3,
            'coverage_gap': 0.2,
            'business_impact': 0.1
        }
    
    def prioritize_edge_cases(self, edge_cases):
        """Generate prioritized test suites based on risk and coverage"""
        
        # Calculate priority scores
        for edge_case in edge_cases:
            edge_case['priority_score'] = self.calculate_priority(edge_case)
            edge_case['test_effort'] = self.estimate_effort(edge_case)
            edge_case['roi'] = edge_case['priority_score'] / edge_case['test_effort']
        
        # Sort by ROI (Return on Investment)
        prioritized = sorted(edge_cases, key=lambda x: x['roi'], reverse=True)
        
        # Generate test suites
        test_suites = {
            'smoke_suite': self.select_critical_edges(prioritized),
            'regression_suite': self.select_high_coverage_edges(prioritized),
            'comprehensive_suite': self.select_all_valuable_edges(prioritized),
            'security_suite': self.select_security_edges(prioritized),
            'performance_suite': self.select_performance_edges(prioritized)
        }
        
        return test_suites
    
    def generate_test_plan(self, test_suites):
        """Create executable test plan with dependencies"""
        return {
            'execution_order': [
                {
                    'phase': 'Critical Path',
                    'suites': ['smoke_suite'],
                    'duration': '30 minutes',
                    'parallel': False
                },
                {
                    'phase': 'Security Validation',
                    'suites': ['security_suite'],
                    'duration': '2 hours',
                    'parallel': True
                },
                {
                    'phase': 'Performance Baseline',
                    'suites': ['performance_suite'],
                    'duration': '4 hours',
                    'parallel': True
                },
                {
                    'phase': 'Full Regression',
                    'suites': ['regression_suite', 'comprehensive_suite'],
                    'duration': '8 hours',
                    'parallel': True
                }
            ]
        }
```

## Risk Assessment and Mitigation

### Risk Assessment Framework
```yaml
risk_assessment:
  methodology:
    identification:
      - automated_discovery
      - expert_review
      - historical_analysis
      - threat_modeling
      
    analysis:
      quantitative:
        - probability_calculation
        - impact_estimation
        - cost_of_failure
        - mitigation_cost
        
      qualitative:
        - expert_judgment
        - scenario_analysis
        - precedent_review
        - stakeholder_input
        
  risk_scoring:
    formula: "(severity * likelihood * exposure) / mitigation_effectiveness"
    
    factors:
      severity:
        data_loss: 10
        security_breach: 9
        service_outage: 8
        compliance_violation: 7
        performance_degradation: 5
        user_inconvenience: 3
        
      likelihood:
        certain: 1.0
        very_likely: 0.8
        likely: 0.6
        possible: 0.4
        unlikely: 0.2
        rare: 0.1
        
      exposure:
        all_users: 1.0
        majority_users: 0.7
        significant_subset: 0.5
        small_group: 0.3
        edge_users: 0.1
```

### Mitigation Strategies
```javascript
class MitigationStrategist {
  generateMitigations(edge_case) {
    const strategies = {
      preventive: this.getPreventiveStrategies(edge_case),
      detective: this.getDetectiveStrategies(edge_case),
      corrective: this.getCorrectiveStrategies(edge_case),
      compensating: this.getCompensatingControls(edge_case)
    };
    
    return {
      edge_case: edge_case.id,
      primary_mitigation: this.selectPrimaryStrategy(strategies, edge_case),
      fallback_strategies: this.selectFallbacks(strategies, edge_case),
      implementation_plan: this.createImplementationPlan(strategies, edge_case),
      validation_tests: this.generateValidationTests(strategies, edge_case),
      monitoring_requirements: this.defineMonitoring(edge_case)
    };
  }
  
  getPreventiveStrategies(edge_case) {
    const strategies = [];
    
    switch(edge_case.category) {
      case 'input_validation':
        strategies.push({
          type: 'input_sanitization',
          implementation: 'Add validation layer with strict type checking',
          effectiveness: 0.9
        });
        strategies.push({
          type: 'whitelist_validation',
          implementation: 'Allow only known-good patterns',
          effectiveness: 0.95
        });
        break;
        
      case 'concurrency':
        strategies.push({
          type: 'locking_mechanism',
          implementation: 'Implement distributed locks with timeout',
          effectiveness: 0.85
        });
        strategies.push({
          type: 'optimistic_concurrency',
          implementation: 'Use version control for conflict detection',
          effectiveness: 0.8
        });
        break;
        
      case 'security':
        strategies.push({
          type: 'defense_in_depth',
          implementation: 'Multiple security layers',
          effectiveness: 0.95
        });
        strategies.push({
          type: 'least_privilege',
          implementation: 'Minimal access rights',
          effectiveness: 0.9
        });
        break;
    }
    
    return strategies;
  }
}
```

## Workflow Execution

### Stage 1: Domain Analysis and Planning
```bash
# Initialize edge case discovery with domain analysis
./claude-flow swarm "Analyze system domains for edge case discovery" \
  --strategy analysis \
  --mode hierarchical \
  --max-agents 8 \
  --parallel \
  --output edge-domains.json

# Store domain analysis in memory
./claude-flow memory store "edge_case_domains" "$(cat edge-domains.json)"
```

### Stage 2: Multi-Technique Discovery
```bash
# Launch specialized discovery agents
./claude-flow sparc "Perform boundary value analysis on all identified domains"
./claude-flow sparc "Execute fault injection scenarios for system resilience"
./claude-flow sparc "Generate combinatorial test cases for feature interactions"
./claude-flow sparc "Identify security edge cases and attack vectors"
./claude-flow sparc "Discover performance and concurrency edge cases"
```

### Stage 3: Risk Assessment and Prioritization
```bash
# Assess discovered edge cases
./claude-flow swarm "Assess risk levels for all discovered edge cases" \
  --strategy analysis \
  --mode mesh \
  --max-agents 5 \
  --monitor

# Generate prioritized test suites
./claude-flow sparc "Create prioritized edge case test suites based on risk assessment"
```

### Stage 4: Mitigation Strategy Development
```bash
# Develop mitigation strategies
./claude-flow sparc "Generate mitigation strategies for high-risk edge cases"

# Create implementation plan
./claude-flow task create implementation \
  "Implement edge case mitigations" \
  --priority high
```

### Stage 5: Test Suite Generation
```bash
# Generate executable test cases
./claude-flow workflow test-case-generator.md \
  --input edge-cases-prioritized.json \
  --output edge-case-tests/

# Integrate with CI/CD
./claude-flow sparc "Create CI/CD pipeline for edge case testing"
```

## Practical Examples

### Example 1: E-Commerce Platform Edge Cases
```yaml
discovered_edge_cases:
  payment_processing:
    - case: "Concurrent discount application"
      scenario: "Multiple discount codes applied simultaneously"
      risk: "Negative total price"
      test: |
        1. Add item worth $100 to cart
        2. Apply 60% discount code in tab 1
        3. Apply 50% discount code in tab 2 simultaneously
        4. Verify total never goes below $0
      mitigation: "Implement atomic discount calculation with mutex"
      
    - case: "Currency precision overflow"
      scenario: "Converting between currencies with different decimal places"
      risk: "Financial calculation errors"
      test: |
        1. Create order in JPY (0 decimal places)
        2. Add item costing 1 USD (2 decimal places)
        3. Convert to BHD (3 decimal places)
        4. Verify no precision loss
      mitigation: "Use decimal arithmetic library with configurable precision"
      
  inventory_management:
    - case: "Distributed inventory race condition"
      scenario: "Multiple warehouses updating same SKU"
      risk: "Overselling or phantom inventory"
      test: |
        1. Set distributed inventory to 10 units across 3 warehouses
        2. Simulate 15 concurrent purchase requests
        3. Verify exactly 10 succeed, 5 fail gracefully
      mitigation: "Implement distributed consensus for inventory updates"
```

### Example 2: Healthcare System Edge Cases
```json
{
  "edge_cases": {
    "medication_dosing": [
      {
        "case": "Pediatric weight boundary",
        "scenario": "Child weight exactly at dosage tier boundary",
        "risk": "Incorrect medication dosage",
        "test": {
          "weight": "20.0 kg",
          "medication": "Amoxicillin",
          "boundary": "20kg tier change",
          "verify": "Correct tier selection"
        },
        "mitigation": "Implement overlapping ranges with clinical review"
      },
      {
        "case": "Drug interaction cascade",
        "scenario": "Adding medication triggers multiple interaction warnings",
        "risk": "Alert fatigue or missed critical interaction",
        "test": {
          "current_meds": ["Warfarin", "Aspirin", "Ibuprofen"],
          "new_med": "Clopidogrel",
          "expected": "Aggregated bleeding risk alert"
        },
        "mitigation": "Intelligent alert aggregation with severity ranking"
      }
    ],
    "patient_data": [
      {
        "case": "Timezone admission",
        "scenario": "Patient admitted during DST transition",
        "risk": "Medication timing errors",
        "test": {
          "admission_time": "2024-03-10 02:30:00",
          "timezone": "America/New_York",
          "medication_schedule": "Every 6 hours",
          "verify": "Correct scheduling across DST"
        },
        "mitigation": "Store all times in UTC with timezone metadata"
      }
    ]
  }
}
```

### Example 3: IoT Platform Edge Cases
```python
# Edge case discovery for IoT platform
edge_cases = {
    'connectivity': [
        {
            'case': 'Intermittent connectivity with queued commands',
            'scenario': 'Device reconnects with 1000+ queued commands',
            'risk': 'Command flood causing device crash',
            'test': '''
                1. Queue 1000 commands while device offline
                2. Simulate device reconnection
                3. Monitor command delivery rate
                4. Verify device stability
            ''',
            'mitigation': 'Implement command throttling and prioritization'
        },
        {
            'case': 'Clock drift compensation',
            'scenario': 'Device clock drifts 1 hour during offline period',
            'risk': 'Incorrect event timestamps and sequencing',
            'test': '''
                1. Set device time to T
                2. Disconnect for 24 hours
                3. Drift clock by +1 hour
                4. Reconnect and verify time sync
            ''',
            'mitigation': 'NTP sync with drift detection and correction'
        }
    ],
    'security': [
        {
            'case': 'Firmware rollback attack',
            'scenario': 'Attempt to install older vulnerable firmware',
            'risk': 'Security regression',
            'test': '''
                1. Update device to latest firmware
                2. Attempt to install older version
                3. Verify rollback prevention
            ''',
            'mitigation': 'Cryptographic version enforcement'
        }
    ]
}
```

## Integration Patterns

### CI/CD Pipeline Integration
```yaml
# .github/workflows/edge-case-discovery.yml
name: Edge Case Discovery Pipeline

on:
  pull_request:
    branches: [main, develop]
  schedule:
    - cron: '0 2 * * 1'  # Weekly on Monday

jobs:
  discover-edge-cases:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Claude Flow
        run: |
          npm install -g @anthropic/claude-flow
          claude-flow init --ci
      
      - name: Discover Edge Cases
        run: |
          claude-flow workflow edge-case-discovery.md \
            --mode comprehensive \
            --domains "$(cat domains.json)" \
            --techniques all \
            --output edge-cases/
      
      - name: Assess Risk Levels
        run: |
          claude-flow sparc "Assess risk levels for discovered edge cases" \
            --input edge-cases/ \
            --output risk-assessment.json
      
      - name: Generate Test Suites
        run: |
          claude-flow sparc "Generate prioritized test suites from edge cases" \
            --risk-assessment risk-assessment.json \
            --output test-suites/
      
      - name: Create Mitigation Plan
        if: contains(github.event.pull_request.labels.*.name, 'needs-mitigation')
        run: |
          claude-flow sparc "Create mitigation plan for critical edge cases" \
            --threshold critical \
            --output mitigation-plan.md
      
      - name: Update Test Coverage
        run: |
          claude-flow sparc "Update test coverage metrics with edge cases" \
            --existing coverage.json \
            --new-cases edge-cases/ \
            --output coverage-updated.json
      
      - name: Comment PR
        uses: actions/github-script@v6
        with:
          script: |
            const fs = require('fs');
            const summary = JSON.parse(fs.readFileSync('risk-assessment.json'));
            
            const comment = `## 🔍 Edge Case Discovery Report
            
            **Discovered**: ${summary.total_cases} edge cases
            **Critical**: ${summary.critical} | **High**: ${summary.high} | **Medium**: ${summary.medium}
            
            ### Top Risk Areas:
            ${summary.top_risks.map(r => `- **${r.area}**: ${r.count} cases`).join('\n')}
            
            ### Recommended Actions:
            ${summary.recommendations.map(r => `- ${r}`).join('\n')}
            
            [View Full Report](./edge-cases/report.html)`;
            
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: comment
            });
```

### Monitoring and Alerting
```javascript
// Edge case monitoring configuration
const monitoringConfig = {
  realtime: {
    edge_case_triggers: [
      {
        name: 'Boundary Value Hit',
        condition: 'input == system.limits.max',
        alert: 'slack',
        severity: 'warning'
      },
      {
        name: 'Concurrent Limit Reached',
        condition: 'active_users >= 0.95 * max_users',
        alert: 'pagerduty',
        severity: 'critical'
      },
      {
        name: 'Security Pattern Detected',
        condition: 'matches_attack_pattern(input)',
        alert: 'security_team',
        severity: 'critical'
      }
    ]
  },
  
  batch_analysis: {
    schedule: 'daily',
    checks: [
      'edge_case_frequency',
      'new_pattern_detection',
      'mitigation_effectiveness'
    ]
  }
};
```

## Best Practices

### 1. Comprehensive Discovery
- **Multi-Technique Approach**: Always use multiple discovery techniques
- **Domain Expert Integration**: Involve domain experts in edge case validation
- **Historical Analysis**: Learn from past incidents and production issues
- **Continuous Discovery**: Regularly update edge case catalog

### 2. Smart Prioritization
- **Risk-Based Focus**: Prioritize by potential impact and likelihood
- **Resource Optimization**: Balance test coverage with available resources
- **Business Alignment**: Align edge case testing with business priorities
- **Regulatory Compliance**: Ensure coverage of compliance-related edges

### 3. Effective Mitigation
- **Defense in Depth**: Layer multiple mitigation strategies
- **Fail-Safe Design**: Design systems to fail gracefully
- **Monitoring Integration**: Monitor for edge case occurrences
- **Continuous Improvement**: Refine mitigations based on effectiveness

### 4. Team Collaboration
- **Shared Knowledge**: Document and share edge case discoveries
- **Cross-Team Review**: Have multiple teams review critical edge cases
- **Training Integration**: Use edge cases for team training
- **Incident Learning**: Update edge cases based on incidents

## Troubleshooting

### Common Issues and Solutions

1. **Edge Case Explosion**
   ```bash
   # Problem: Too many edge cases to test
   # Solution: Use risk-based filtering
   ./claude-flow sparc "Filter edge cases by risk score > 7.0"
   ```

2. **False Positive Edge Cases**
   ```bash
   # Problem: Unrealistic edge cases identified
   # Solution: Validate with domain constraints
   ./claude-flow sparc "Validate edge cases against business rules"
   ```

3. **Missing Domain Coverage**
   ```bash
   # Problem: Some domains not analyzed
   # Solution: Run comprehensive domain discovery
   ./claude-flow swarm "Discover all system domains for edge case analysis" \
     --mode distributed \
     --max-agents 10
   ```

4. **Ineffective Mitigations**
   ```bash
   # Problem: Mitigations not preventing edge cases
   # Solution: Analyze and improve strategies
   ./claude-flow sparc "Analyze mitigation effectiveness and suggest improvements"
   ```

## Advanced Topics

### Machine Learning for Edge Discovery
```python
class MLEdgeDiscovery:
    """Use ML to discover non-obvious edge cases"""
    
    def train_edge_detector(self, historical_data):
        # Train model on past edge cases and incidents
        features = self.extract_features(historical_data)
        model = self.train_anomaly_detector(features)
        return model
    
    def predict_edge_cases(self, system_model, ml_model):
        # Generate potential edge cases using ML
        predictions = []
        
        # Analyze system behavior patterns
        behavior_vectors = self.vectorize_system_behavior(system_model)
        
        # Identify anomalous patterns
        anomalies = ml_model.predict(behavior_vectors)
        
        # Convert to edge case specifications
        for anomaly in anomalies:
            edge_case = self.anomaly_to_edge_case(anomaly)
            predictions.append(edge_case)
        
        return predictions
```

### Chaos Engineering Integration
```yaml
chaos_engineering:
  edge_case_experiments:
    - name: "Cascading Service Failure"
      hypothesis: "System degrades gracefully when 30% of services fail"
      method:
        - inject: "random_service_failures"
        - rate: "30%"
        - duration: "5 minutes"
      validation:
        - "response_time < 2x normal"
        - "error_rate < 5%"
        - "no data loss"
      
    - name: "Clock Skew Chaos"
      hypothesis: "System handles 5-minute clock skew between nodes"
      method:
        - inject: "clock_skew"
        - magnitude: "+/- 5 minutes"
        - targets: "random 50% of nodes"
      validation:
        - "eventual consistency achieved"
        - "no transaction failures"
        - "audit logs remain accurate"
```

## Conclusion

This edge case discovery workflow provides a comprehensive approach to identifying, prioritizing, and mitigating edge cases across all system domains. By combining multiple discovery techniques, risk-based prioritization, and systematic mitigation strategies, teams can build more robust and reliable systems.

The workflow is designed to be:
- **Systematic**: Covers all domains and edge case categories
- **Scalable**: Works for small features or entire systems
- **Actionable**: Provides clear mitigation strategies
- **Integrated**: Fits into existing development workflows
- **Continuous**: Supports ongoing edge case discovery and refinement

Regular execution of this workflow ensures that edge cases are not just discovered but effectively managed throughout the software development lifecycle.