# OWASP Top 10 Security Checklist

## Overview
This checklist provides a comprehensive guide for identifying and mitigating the OWASP Top 10 security risks in web applications. Each category includes detection methods, prevention strategies, and testing approaches.

## A01:2021 – Broken Access Control

### Detection Checklist
- [ ] **URL Parameter Tampering**: Test if users can modify URL parameters to access unauthorized resources
- [ ] **Horizontal Privilege Escalation**: Verify users cannot access other users' data by changing IDs
- [ ] **Vertical Privilege Escalation**: Ensure regular users cannot access admin functions
- [ ] **Forced Browsing**: Check if authentication is enforced on all sensitive pages
- [ ] **CORS Misconfiguration**: Validate Cross-Origin Resource Sharing policies
- [ ] **JWT Token Vulnerabilities**: Test for weak signatures and token manipulation

### Prevention Measures
- [ ] Implement proper access control checks on every request
- [ ] Use deny by default approach for access control
- [ ] Enforce record ownership validation
- [ ] Disable directory listing and ensure proper file metadata
- [ ] Log access control failures and alert on suspicious patterns
- [ ] Rate limit API and controller access

### Testing Approaches
```yaml
access_control_tests:
  - unauthorized_api_access
  - parameter_manipulation
  - cookie_tampering
  - token_replay_attacks
  - path_traversal_attempts
  - method_override_testing
```

## A02:2021 – Cryptographic Failures

### Detection Checklist
- [ ] **Sensitive Data in Transit**: Verify HTTPS/TLS is used for all data transmission
- [ ] **Weak Encryption Algorithms**: Check for outdated algorithms (MD5, SHA1, DES)
- [ ] **Hard-coded Keys**: Scan for cryptographic keys in source code
- [ ] **Insufficient Key Length**: Ensure appropriate key sizes (RSA 2048+, AES 256)
- [ ] **Missing Encryption**: Identify unencrypted sensitive data at rest
- [ ] **Weak Random Number Generation**: Test randomness quality for tokens/salts

### Prevention Measures
- [ ] Classify data processed, stored, or transmitted
- [ ] Apply strong encryption for data at rest and in transit
- [ ] Use authenticated encryption modes (AES-GCM)
- [ ] Implement proper key management (rotation, storage)
- [ ] Disable caching for sensitive data responses
- [ ] Use secure protocols (TLS 1.2+) with strong ciphers

### Testing Approaches
```yaml
crypto_tests:
  - ssl_tls_configuration
  - certificate_validation
  - encryption_strength
  - key_storage_review
  - random_number_analysis
  - hash_algorithm_review
```

## A03:2021 – Injection

### Detection Checklist
- [ ] **SQL Injection**: Test all data inputs for SQL injection vulnerabilities
- [ ] **NoSQL Injection**: Verify NoSQL queries are properly sanitized
- [ ] **Command Injection**: Check for OS command execution vulnerabilities
- [ ] **LDAP Injection**: Test directory service queries for injection flaws
- [ ] **XPath Injection**: Validate XML query construction
- [ ] **ORM Injection**: Review ORM usage for unsafe practices

### Prevention Measures
- [ ] Use parameterized queries/prepared statements
- [ ] Implement input validation using whitelists
- [ ] Escape special characters for the specific interpreter
- [ ] Use LIMIT and other SQL controls within queries
- [ ] Apply least privilege principle for database accounts
- [ ] Use stored procedures with care (still validate input)

### Testing Approaches
```yaml
injection_tests:
  - sql_injection_fuzzing
  - blind_sql_injection
  - time_based_injection
  - union_based_attacks
  - error_based_exploitation
  - second_order_injection
```

## A04:2021 – Insecure Design

### Detection Checklist
- [ ] **Missing Threat Modeling**: Verify threat modeling was performed
- [ ] **Weak Security Requirements**: Check for defined security requirements
- [ ] **Missing Security Controls**: Identify absent critical security controls
- [ ] **Trust Boundary Violations**: Review data flow across trust boundaries
- [ ] **Business Logic Flaws**: Test for logic bypasses and race conditions
- [ ] **Resource Exhaustion**: Check for DoS vulnerabilities

### Prevention Measures
- [ ] Establish secure development lifecycle
- [ ] Use threat modeling for critical flows
- [ ] Implement secure design patterns
- [ ] Create security user stories
- [ ] Perform design reviews with security experts
- [ ] Use reference architectures

### Testing Approaches
```yaml
design_tests:
  - business_logic_testing
  - race_condition_detection
  - workflow_bypass_attempts
  - resource_limit_testing
  - trust_boundary_analysis
  - component_integration_review
```

## A05:2021 – Security Misconfiguration

### Detection Checklist
- [ ] **Default Credentials**: Test for default usernames and passwords
- [ ] **Unnecessary Features**: Identify enabled unnecessary features/services
- [ ] **Error Handling**: Check for verbose error messages exposing system info
- [ ] **Missing Security Headers**: Verify security headers are properly set
- [ ] **Outdated Software**: Scan for outdated frameworks and libraries
- [ ] **Cloud Misconfiguration**: Review cloud service security settings

### Prevention Measures
- [ ] Implement repeatable hardening process
- [ ] Maintain minimal platform without unnecessary features
- [ ] Review and update configurations regularly
- [ ] Use automated configuration verification
- [ ] Segment application architecture
- [ ] Send security directives to clients (headers)

### Testing Approaches
```yaml
config_tests:
  - default_credential_scanning
  - security_header_analysis
  - service_enumeration
  - version_disclosure_check
  - directory_traversal
  - configuration_file_access
```

## A06:2021 – Vulnerable and Outdated Components

### Detection Checklist
- [ ] **Component Inventory**: Maintain inventory of all components and versions
- [ ] **Vulnerability Scanning**: Regular scanning for known vulnerabilities
- [ ] **Unsupported Versions**: Identify components no longer maintained
- [ ] **Dependency Analysis**: Check transitive dependencies
- [ ] **License Compliance**: Verify component licenses
- [ ] **Configuration Review**: Check component configurations

### Prevention Measures
- [ ] Remove unused dependencies and features
- [ ] Continuously inventory component versions
- [ ] Monitor CVE/NVD for vulnerabilities
- [ ] Subscribe to security alerts for components
- [ ] Obtain components from official sources
- [ ] Prefer signed packages

### Testing Approaches
```yaml
component_tests:
  - dependency_scanning
  - cve_correlation
  - version_identification
  - exploit_availability_check
  - patch_status_verification
  - component_configuration_review
```

## A07:2021 – Identification and Authentication Failures

### Detection Checklist
- [ ] **Weak Passwords**: Test password policy enforcement
- [ ] **Credential Stuffing**: Check for protection against automated attacks
- [ ] **Session Management**: Verify proper session handling
- [ ] **Multi-factor Authentication**: Ensure MFA for sensitive operations
- [ ] **Password Recovery**: Test security of password recovery flows
- [ ] **Session Fixation**: Check for session ID regeneration after login

### Prevention Measures
- [ ] Implement multi-factor authentication
- [ ] Do not ship with default credentials
- [ ] Implement weak password checks
- [ ] Limit failed login attempts
- [ ] Use secure session management
- [ ] Generate new session IDs on authentication

### Testing Approaches
```yaml
auth_tests:
  - brute_force_testing
  - session_hijacking
  - token_prediction
  - password_complexity_check
  - account_enumeration
  - timing_attack_analysis
```

## A08:2021 – Software and Data Integrity Failures

### Detection Checklist
- [ ] **Insecure Deserialization**: Test for unsafe deserialization
- [ ] **CI/CD Pipeline Security**: Review build and deployment security
- [ ] **Unsigned Updates**: Check for unsigned software updates
- [ ] **Dependency Confusion**: Test for dependency substitution attacks
- [ ] **Code Integrity**: Verify code signing and integrity checks
- [ ] **Data Integrity**: Ensure critical data integrity validation

### Prevention Measures
- [ ] Use digital signatures to verify software/data
- [ ] Ensure libraries and dependencies use trusted repos
- [ ] Use software supply chain security tools
- [ ] Review code and configuration changes
- [ ] Ensure CI/CD pipeline has proper segregation
- [ ] Do not send serialized data to untrusted clients

### Testing Approaches
```yaml
integrity_tests:
  - deserialization_testing
  - supply_chain_analysis
  - signature_verification
  - build_process_review
  - update_mechanism_testing
  - data_tampering_detection
```

## A09:2021 – Security Logging and Monitoring Failures

### Detection Checklist
- [ ] **Insufficient Logging**: Verify critical events are logged
- [ ] **Log Injection**: Test for log injection vulnerabilities
- [ ] **Log Storage**: Check secure log storage and retention
- [ ] **Monitoring Coverage**: Ensure adequate monitoring coverage
- [ ] **Alert Configuration**: Verify alerts for suspicious activities
- [ ] **Log Review Process**: Check regular log review procedures

### Prevention Measures
- [ ] Log authentication, access control, and input validation failures
- [ ] Ensure logs are in a consumable format
- [ ] Ensure log integrity and tamper-proofing
- [ ] Establish effective monitoring and alerting
- [ ] Establish incident response and recovery plan
- [ ] Use commercial or open source SIEM solutions

### Testing Approaches
```yaml
logging_tests:
  - log_completeness_review
  - log_injection_testing
  - alert_trigger_validation
  - log_correlation_check
  - retention_policy_verification
  - incident_response_testing
```

## A10:2021 – Server-Side Request Forgery (SSRF)

### Detection Checklist
- [ ] **URL Parameter Testing**: Test all URL input parameters
- [ ] **File Import Features**: Review file import/fetch functionality
- [ ] **Webhook Implementations**: Check webhook URL validation
- [ ] **PDF Generators**: Test PDF generation with external resources
- [ ] **Image Processing**: Review image fetch/processing features
- [ ] **Internal Service Access**: Test for internal network access

### Prevention Measures
- [ ] Segment remote resource access functionality
- [ ] Enforce "deny by default" firewall policies
- [ ] Validate and sanitize all client-supplied input
- [ ] Do not send raw responses to clients
- [ ] Disable HTTP redirections
- [ ] Use allowlists for protocols and domains

### Testing Approaches
```yaml
ssrf_tests:
  - internal_port_scanning
  - cloud_metadata_access
  - internal_service_interaction
  - dns_rebinding_attacks
  - protocol_smuggling
  - redirect_bypass_attempts
```

## Implementation Priority Matrix

```yaml
priority_matrix:
  immediate_high_impact:
    - broken_access_control
    - injection_vulnerabilities
    - authentication_failures
    - cryptographic_failures
  
  short_term_medium_impact:
    - security_misconfiguration
    - vulnerable_components
    - integrity_failures
  
  ongoing_maintenance:
    - insecure_design
    - logging_monitoring
    - ssrf_protection
```

## Validation Checklist

### Pre-Production
- [ ] All OWASP Top 10 categories tested
- [ ] Automated security testing integrated
- [ ] Manual security review completed
- [ ] Threat model updated
- [ ] Security training completed

### Production
- [ ] Continuous monitoring active
- [ ] Incident response plan tested
- [ ] Regular vulnerability scanning
- [ ] Patch management process active
- [ ] Security metrics tracked

## Tools and Resources

```yaml
recommended_tools:
  scanning:
    - owasp_zap
    - burp_suite
    - nikto
    - sqlmap
  
  static_analysis:
    - sonarqube
    - checkmarx
    - fortify
    - semgrep
  
  dependency_checking:
    - owasp_dependency_check
    - snyk
    - npm_audit
    - safety
  
  monitoring:
    - elastic_siem
    - splunk
    - datadog
    - new_relic
```