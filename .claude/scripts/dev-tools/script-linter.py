#!/usr/bin/env python3

"""
Script Linter - Security and best practices linter for TES scripts
This tool performs security checks and validates scripts against best practices.
"""

import ast
import re
import subprocess
import sys
import os
import json
import argparse
from pathlib import Path
from typing import List, Dict, Any, Tuple, Optional
import tempfile
import shutil

# ANSI color codes
class Colors:
    GREEN = '\033[0;32m'
    BLUE = '\033[0;34m'
    YELLOW = '\033[1;33m'
    RED = '\033[0;31m'
    CYAN = '\033[0;36m'
    MAGENTA = '\033[0;35m'
    NC = '\033[0m'


class SecurityIssue:
    """Represents a security issue found in the script"""
    def __init__(self, severity: str, category: str, message: str, 
                 line: Optional[int] = None, code: Optional[str] = None):
        self.severity = severity
        self.category = category
        self.message = message
        self.line = line
        self.code = code


class BestPracticeIssue:
    """Represents a best practice violation"""
    def __init__(self, category: str, message: str, 
                 line: Optional[int] = None, suggestion: Optional[str] = None):
        self.category = category
        self.message = message
        self.line = line
        self.suggestion = suggestion


class ScriptLinter:
    """Main linter class for analyzing scripts"""
    
    # Security patterns to check
    SECURITY_PATTERNS = {
        # Secrets and credentials
        "hardcoded_secrets": [
            (r'(password|passwd|pwd)\s*=\s*["\'][^"\']+["\']', "Hardcoded password detected"),
            (r'(api[_-]?key|apikey)\s*=\s*["\'][^"\']+["\']', "Hardcoded API key detected"),
            (r'(secret|token)\s*=\s*["\'][^"\']+["\']', "Hardcoded secret/token detected"),
            (r'AWS[_-]?SECRET[_-]?ACCESS[_-]?KEY\s*=', "AWS secret key detected"),
            (r'PRIVATE[_-]?KEY\s*=\s*["\'][^"\']+["\']', "Private key detected"),
        ],
        
        # Command injection
        "command_injection": [
            (r'eval\s*\(', "Use of eval() is dangerous"),
            (r'exec\s*\(', "Use of exec() is dangerous"),
            (r'\$\(.*\$[{(]?\w+[)}]?.*\)', "Potential command injection via variable substitution"),
            (r'`.*\$[{(]?\w+[)}]?.*`', "Potential command injection in backticks"),
        ],
        
        # Path traversal
        "path_traversal": [
            (r'\.\./', "Path traversal detected"),
            (r'open\s*\([^,)]*\$', "Unvalidated file path in open()"),
            (r'cat\s+[^|]*\$', "Unvalidated file path in cat command"),
        ],
        
        # Network access
        "network_access": [
            (r'(curl|wget|nc|netcat)\s+', "Network tool usage detected"),
            (r'(http|https|ftp)://', "External URL detected"),
            (r'socket\s*\(', "Socket usage detected"),
            (r'requests\.(get|post|put|delete)', "HTTP request detected"),
        ],
        
        # System access
        "system_access": [
            (r'sudo\s+', "Sudo usage detected"),
            (r'chmod\s+777', "Dangerous permission change"),
            (r'rm\s+-rf\s+/', "Dangerous recursive delete"),
            (r'/etc/(passwd|shadow|sudoers)', "Access to sensitive system files"),
        ]
    }
    
    # Best practices patterns
    BEST_PRACTICES = {
        "error_handling": [
            (r'set\s+-e', "Good: Using set -e for error handling", True),
            (r'set\s+-u', "Good: Using set -u for undefined variables", True),
            (r'trap\s+', "Good: Using trap for cleanup", True),
        ],
        
        "shell_practices": [
            (r'\[\[.*\]\]', "Good: Using [[ ]] for conditionals", True),
            (r'"\$\{[^}]+\}"', "Good: Quoted variable expansion", True),
            (r'\$\(.*\)', "Good: Using $() instead of backticks", True),
        ],
        
        "python_practices": [
            (r'if\s+__name__\s*==\s*["\']__main__["\']', "Good: Main guard present", True),
            (r'with\s+open\s*\(', "Good: Using context manager for files", True),
            (r'logging\.', "Good: Using logging module", True),
        ],
        
        "node_practices": [
            (r'use\s+strict', "Good: Strict mode enabled", True),
            (r'const\s+\w+\s*=', "Good: Using const", True),
            (r'async\s+function|await\s+', "Good: Using async/await", True),
        ]
    }
    
    def __init__(self, verbose: bool = False):
        self.verbose = verbose
        self.security_issues: List[SecurityIssue] = []
        self.best_practice_issues: List[BestPracticeIssue] = []
        self.good_practices: List[str] = []
        
    def print_header(self):
        """Print tool header"""
        print(f"{Colors.MAGENTA}╔══════════════════════════════════════════════════════════╗{Colors.NC}")
        print(f"{Colors.MAGENTA}║          TES Script Linter - Version 1.0.0               ║{Colors.NC}")
        print(f"{Colors.MAGENTA}╚══════════════════════════════════════════════════════════╝{Colors.NC}")
        print()
    
    def lint_file(self, file_path: str) -> Tuple[int, int]:
        """Lint a single file"""
        self.security_issues = []
        self.best_practice_issues = []
        self.good_practices = []
        
        # Detect file type
        file_ext = Path(file_path).suffix
        
        if file_ext in ['.sh', '.bash']:
            self._lint_shell_script(file_path)
        elif file_ext == '.py':
            self._lint_python_script(file_path)
        elif file_ext == '.js':
            self._lint_javascript_script(file_path)
        else:
            # Try to detect from shebang
            with open(file_path, 'r') as f:
                first_line = f.readline().strip()
                if 'bash' in first_line or 'sh' in first_line:
                    self._lint_shell_script(file_path)
                elif 'python' in first_line:
                    self._lint_python_script(file_path)
                elif 'node' in first_line:
                    self._lint_javascript_script(file_path)
                else:
                    print(f"{Colors.YELLOW}Warning: Unknown file type, performing generic checks{Colors.NC}")
                    self._lint_generic(file_path)
        
        return len(self.security_issues), len(self.best_practice_issues)
    
    def _lint_shell_script(self, file_path: str):
        """Lint a shell script"""
        with open(file_path, 'r') as f:
            content = f.read()
            lines = content.splitlines()
        
        # Check for shellcheck if available
        if shutil.which('shellcheck'):
            self._run_shellcheck(file_path)
        
        # Security checks
        self._check_security_patterns(content, lines, 'shell')
        
        # Shell-specific checks
        self._check_shell_best_practices(content, lines)
        
        # Check for unsafe variable usage
        self._check_unsafe_variables(content, lines)
        
        # Check for proper quoting
        self._check_quoting_issues(content, lines)
    
    def _lint_python_script(self, file_path: str):
        """Lint a Python script"""
        with open(file_path, 'r') as f:
            content = f.read()
            lines = content.splitlines()
        
        # Security checks
        self._check_security_patterns(content, lines, 'python')
        
        # Python-specific checks
        self._check_python_best_practices(content, lines)
        
        # AST-based analysis
        try:
            tree = ast.parse(content)
            self._analyze_python_ast(tree, lines)
        except SyntaxError as e:
            self.best_practice_issues.append(
                BestPracticeIssue(
                    "syntax",
                    f"Python syntax error: {e}",
                    e.lineno
                )
            )
        
        # Check for security tools usage
        if shutil.which('bandit'):
            self._run_bandit(file_path)
    
    def _lint_javascript_script(self, file_path: str):
        """Lint a JavaScript/Node.js script"""
        with open(file_path, 'r') as f:
            content = f.read()
            lines = content.splitlines()
        
        # Security checks
        self._check_security_patterns(content, lines, 'javascript')
        
        # JavaScript-specific checks
        self._check_javascript_best_practices(content, lines)
        
        # Check for common vulnerabilities
        self._check_javascript_vulnerabilities(content, lines)
    
    def _lint_generic(self, file_path: str):
        """Generic linting for unknown file types"""
        with open(file_path, 'r') as f:
            content = f.read()
            lines = content.splitlines()
        
        # Basic security checks
        self._check_security_patterns(content, lines, 'generic')
    
    def _check_security_patterns(self, content: str, lines: List[str], script_type: str):
        """Check for security issues using regex patterns"""
        for category, patterns in self.SECURITY_PATTERNS.items():
            for pattern, message in patterns:
                # Skip network checks for scripts that declare network permission
                if category == "network_access" and self._has_network_permission(content):
                    continue
                
                for i, line in enumerate(lines):
                    if re.search(pattern, line, re.IGNORECASE):
                        # Determine severity
                        severity = self._get_severity(category)
                        
                        self.security_issues.append(
                            SecurityIssue(
                                severity=severity,
                                category=category,
                                message=message,
                                line=i + 1,
                                code=line.strip()
                            )
                        )
    
    def _check_shell_best_practices(self, content: str, lines: List[str]):
        """Check shell script best practices"""
        # Check for error handling
        if 'set -e' not in content:
            self.best_practice_issues.append(
                BestPracticeIssue(
                    "error_handling",
                    "Missing 'set -e' for error handling",
                    suggestion="Add 'set -e' at the beginning of the script"
                )
            )
        else:
            self.good_practices.append("Using 'set -e' for error handling")
        
        if 'set -u' not in content:
            self.best_practice_issues.append(
                BestPracticeIssue(
                    "error_handling",
                    "Missing 'set -u' for undefined variable checking",
                    suggestion="Add 'set -u' at the beginning of the script"
                )
            )
        else:
            self.good_practices.append("Using 'set -u' for undefined variables")
        
        # Check for trap usage
        if 'trap' not in content:
            self.best_practice_issues.append(
                BestPracticeIssue(
                    "cleanup",
                    "No trap for cleanup on exit",
                    suggestion="Add trap for cleanup, e.g., trap 'cleanup' EXIT"
                )
            )
        
        # Check for function definitions
        if not re.search(r'(function\s+\w+|^\w+\s*\(\))', content, re.MULTILINE):
            self.best_practice_issues.append(
                BestPracticeIssue(
                    "structure",
                    "No functions defined - consider modularizing code",
                    suggestion="Break code into functions for better organization"
                )
            )
    
    def _check_python_best_practices(self, content: str, lines: List[str]):
        """Check Python script best practices"""
        # Check for main guard
        if '__name__' not in content:
            self.best_practice_issues.append(
                BestPracticeIssue(
                    "structure",
                    "Missing if __name__ == '__main__' guard",
                    suggestion="Add main guard to allow script to be imported"
                )
            )
        else:
            self.good_practices.append("Has proper main guard")
        
        # Check for exception handling
        if 'try:' not in content:
            self.best_practice_issues.append(
                BestPracticeIssue(
                    "error_handling",
                    "No exception handling found",
                    suggestion="Add try/except blocks for error handling"
                )
            )
        
        # Check for logging
        if 'logging' not in content and 'print(' in content:
            self.best_practice_issues.append(
                BestPracticeIssue(
                    "logging",
                    "Using print() instead of logging",
                    suggestion="Use logging module instead of print() for better control"
                )
            )
    
    def _check_javascript_best_practices(self, content: str, lines: List[str]):
        """Check JavaScript best practices"""
        # Check for strict mode
        if "'use strict'" not in content and '"use strict"' not in content:
            self.best_practice_issues.append(
                BestPracticeIssue(
                    "strict_mode",
                    "Missing 'use strict' directive",
                    line=1,
                    suggestion="Add 'use strict' at the beginning"
                )
            )
        else:
            self.good_practices.append("Using strict mode")
        
        # Check for var usage
        if re.search(r'\bvar\s+', content):
            self.best_practice_issues.append(
                BestPracticeIssue(
                    "variables",
                    "Using 'var' instead of 'let' or 'const'",
                    suggestion="Replace 'var' with 'let' or 'const'"
                )
            )
        
        # Check for error handling
        if 'catch' not in content:
            self.best_practice_issues.append(
                BestPracticeIssue(
                    "error_handling",
                    "No error handling found",
                    suggestion="Add try/catch blocks for error handling"
                )
            )
    
    def _check_unsafe_variables(self, content: str, lines: List[str]):
        """Check for unsafe variable usage in shell scripts"""
        # Unquoted variables
        unquoted_pattern = r'\$\w+(?!["\'])'
        for i, line in enumerate(lines):
            # Skip comments
            if line.strip().startswith('#'):
                continue
            
            matches = re.findall(unquoted_pattern, line)
            if matches:
                self.best_practice_issues.append(
                    BestPracticeIssue(
                        "quoting",
                        f"Unquoted variable usage: {matches[0]}",
                        line=i + 1,
                        suggestion="Always quote variables: \"$VAR\""
                    )
                )
    
    def _check_quoting_issues(self, content: str, lines: List[str]):
        """Check for quoting issues in shell scripts"""
        # Check for word splitting issues
        problematic_patterns = [
            (r'for\s+\w+\s+in\s+\$', "Unquoted variable in for loop"),
            (r'if\s+\[\s+\$', "Unquoted variable in test condition"),
        ]
        
        for pattern, message in problematic_patterns:
            for i, line in enumerate(lines):
                if re.search(pattern, line):
                    self.best_practice_issues.append(
                        BestPracticeIssue(
                            "quoting",
                            message,
                            line=i + 1,
                            suggestion="Use proper quoting to prevent word splitting"
                        )
                    )
    
    def _analyze_python_ast(self, tree: ast.AST, lines: List[str]):
        """Analyze Python AST for security issues"""
        class SecurityVisitor(ast.NodeVisitor):
            def __init__(self, linter):
                self.linter = linter
                
            def visit_Call(self, node):
                # Check for dangerous functions
                if isinstance(node.func, ast.Name):
                    if node.func.id in ['eval', 'exec', 'compile']:
                        self.linter.security_issues.append(
                            SecurityIssue(
                                severity="high",
                                category="code_execution",
                                message=f"Dangerous function: {node.func.id}()",
                                line=node.lineno
                            )
                        )
                    elif node.func.id == 'open':
                        # Check if file path is validated
                        if node.args and isinstance(node.args[0], ast.Name):
                            self.linter.security_issues.append(
                                SecurityIssue(
                                    severity="medium",
                                    category="file_access",
                                    message="Unvalidated file path in open()",
                                    line=node.lineno
                                )
                            )
                
                self.generic_visit(node)
            
            def visit_Import(self, node):
                # Check for dangerous imports
                dangerous_modules = ['pickle', 'marshal', 'subprocess']
                for alias in node.names:
                    if alias.name in dangerous_modules:
                        self.linter.best_practice_issues.append(
                            BestPracticeIssue(
                                "imports",
                                f"Potentially dangerous module: {alias.name}",
                                line=node.lineno,
                                suggestion="Ensure proper input validation when using this module"
                            )
                        )
                
                self.generic_visit(node)
        
        visitor = SecurityVisitor(self)
        visitor.visit(tree)
    
    def _check_javascript_vulnerabilities(self, content: str, lines: List[str]):
        """Check for JavaScript-specific vulnerabilities"""
        # Check for eval usage
        eval_pattern = r'eval\s*\('
        for i, line in enumerate(lines):
            if re.search(eval_pattern, line):
                self.security_issues.append(
                    SecurityIssue(
                        severity="high",
                        category="code_execution",
                        message="Use of eval() is dangerous",
                        line=i + 1,
                        code=line.strip()
                    )
                )
        
        # Check for innerHTML usage
        inner_html_pattern = r'\.innerHTML\s*='
        for i, line in enumerate(lines):
            if re.search(inner_html_pattern, line):
                self.security_issues.append(
                    SecurityIssue(
                        severity="medium",
                        category="xss",
                        message="Direct innerHTML assignment can lead to XSS",
                        line=i + 1,
                        code=line.strip()
                    )
                )
    
    def _run_shellcheck(self, file_path: str):
        """Run shellcheck if available"""
        try:
            result = subprocess.run(
                ['shellcheck', '-f', 'json', file_path],
                capture_output=True,
                text=True
            )
            
            if result.stdout:
                issues = json.loads(result.stdout)
                for issue in issues:
                    severity = "high" if issue['level'] == "error" else "medium"
                    self.security_issues.append(
                        SecurityIssue(
                            severity=severity,
                            category="shellcheck",
                            message=f"SC{issue['code']}: {issue['message']}",
                            line=issue['line'],
                            code=issue.get('code', '')
                        )
                    )
        except Exception:
            pass  # Shellcheck not available or failed
    
    def _run_bandit(self, file_path: str):
        """Run bandit security scanner if available"""
        try:
            result = subprocess.run(
                ['bandit', '-f', 'json', file_path],
                capture_output=True,
                text=True
            )
            
            if result.stdout:
                report = json.loads(result.stdout)
                for issue in report.get('results', []):
                    self.security_issues.append(
                        SecurityIssue(
                            severity=issue['issue_severity'].lower(),
                            category="bandit",
                            message=f"{issue['test_name']}: {issue['issue_text']}",
                            line=issue['line_number']
                        )
                    )
        except Exception:
            pass  # Bandit not available or failed
    
    def _has_network_permission(self, content: str) -> bool:
        """Check if script declares network permission"""
        # Look for TES metadata or comments indicating network permission
        return re.search(r'(permissions.*network|network_access.*true)', content, re.IGNORECASE) is not None
    
    def _get_severity(self, category: str) -> str:
        """Determine severity based on category"""
        high_severity = ["hardcoded_secrets", "command_injection", "system_access"]
        medium_severity = ["path_traversal", "network_access"]
        
        if category in high_severity:
            return "high"
        elif category in medium_severity:
            return "medium"
        else:
            return "low"
    
    def generate_report(self, file_path: str) -> Dict[str, Any]:
        """Generate a comprehensive report"""
        report = {
            "file": file_path,
            "summary": {
                "security_issues": len(self.security_issues),
                "best_practice_issues": len(self.best_practice_issues),
                "good_practices": len(self.good_practices)
            },
            "security": {
                "high": len([i for i in self.security_issues if i.severity == "high"]),
                "medium": len([i for i in self.security_issues if i.severity == "medium"]),
                "low": len([i for i in self.security_issues if i.severity == "low"]),
                "issues": [
                    {
                        "severity": issue.severity,
                        "category": issue.category,
                        "message": issue.message,
                        "line": issue.line,
                        "code": issue.code
                    }
                    for issue in self.security_issues
                ]
            },
            "best_practices": {
                "issues": [
                    {
                        "category": issue.category,
                        "message": issue.message,
                        "line": issue.line,
                        "suggestion": issue.suggestion
                    }
                    for issue in self.best_practice_issues
                ],
                "good": self.good_practices
            }
        }
        
        return report
    
    def print_report(self, file_path: str):
        """Print a formatted report"""
        print(f"\n{Colors.BLUE}═══════════════ Linting Report ═══════════════{Colors.NC}")
        print(f"File: {file_path}")
        
        # Security issues
        if self.security_issues:
            print(f"\n{Colors.RED}Security Issues ({len(self.security_issues)}):{Colors.NC}")
            
            # Group by severity
            for severity in ["high", "medium", "low"]:
                issues = [i for i in self.security_issues if i.severity == severity]
                if issues:
                    color = Colors.RED if severity == "high" else Colors.YELLOW if severity == "medium" else Colors.BLUE
                    print(f"\n  {color}{severity.upper()} severity:{Colors.NC}")
                    for issue in issues:
                        print(f"    Line {issue.line}: {issue.message}")
                        if issue.code and self.verbose:
                            print(f"      Code: {issue.code}")
        else:
            print(f"\n{Colors.GREEN}✓ No security issues found{Colors.NC}")
        
        # Best practice issues
        if self.best_practice_issues:
            print(f"\n{Colors.YELLOW}Best Practice Issues ({len(self.best_practice_issues)}):{Colors.NC}")
            for issue in self.best_practice_issues:
                line_info = f"Line {issue.line}: " if issue.line else ""
                print(f"  {line_info}{issue.message}")
                if issue.suggestion:
                    print(f"    → {issue.suggestion}")
        
        # Good practices
        if self.good_practices:
            print(f"\n{Colors.GREEN}Good Practices Found ({len(self.good_practices)}):{Colors.NC}")
            for practice in self.good_practices:
                print(f"  ✓ {practice}")
        
        # Summary
        print(f"\n{Colors.BLUE}Summary:{Colors.NC}")
        total_issues = len(self.security_issues) + len(self.best_practice_issues)
        if total_issues == 0:
            print(f"  {Colors.GREEN}✓ Script passed all checks!{Colors.NC}")
        else:
            high_count = len([i for i in self.security_issues if i.severity == "high"])
            if high_count > 0:
                print(f"  {Colors.RED}✗ Found {high_count} high severity issues{Colors.NC}")
            print(f"  Total issues: {total_issues}")
            print(f"  Security: {len(self.security_issues)}")
            print(f"  Best practices: {len(self.best_practice_issues)}")


def setup_pre_commit_hook():
    """Setup pre-commit hook for automatic linting"""
    hook_content = """#!/bin/bash
# TES Script Linter Pre-commit Hook

# Find all modified scripts
scripts=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\\.(sh|py|js)$')

if [ -z "$scripts" ]; then
    exit 0
fi

echo "Running TES Script Linter on modified scripts..."

failed=0
for script in $scripts; do
    if [ -f "$script" ]; then
        python3 "$(dirname "$0")/../../.claude/scripts/dev-tools/script-linter.py" "$script"
        if [ $? -ne 0 ]; then
            failed=1
        fi
    fi
done

if [ $failed -eq 1 ]; then
    echo ""
    echo "Linting failed! Fix issues before committing."
    echo "To bypass: git commit --no-verify"
    exit 1
fi

exit 0
"""
    
    git_dir = subprocess.run(['git', 'rev-parse', '--git-dir'], 
                           capture_output=True, text=True).stdout.strip()
    
    if git_dir:
        hook_path = Path(git_dir) / 'hooks' / 'pre-commit'
        
        # Backup existing hook
        if hook_path.exists():
            backup_path = hook_path.with_suffix('.backup')
            shutil.copy2(hook_path, backup_path)
            print(f"Backed up existing hook to {backup_path}")
        
        # Write new hook
        hook_path.write_text(hook_content)
        hook_path.chmod(0o755)
        print(f"{Colors.GREEN}✓ Pre-commit hook installed at {hook_path}{Colors.NC}")
        print("The linter will now run automatically before each commit.")
    else:
        print(f"{Colors.RED}Error: Not in a git repository{Colors.NC}")


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description='Security and best practices linter for TES scripts',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument(
        'files',
        nargs='*',
        help='Script files to lint'
    )
    
    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='Show detailed output'
    )
    
    parser.add_argument(
        '-j', '--json',
        action='store_true',
        help='Output results as JSON'
    )
    
    parser.add_argument(
        '-o', '--output',
        help='Write report to file'
    )
    
    parser.add_argument(
        '--install-hook',
        action='store_true',
        help='Install as git pre-commit hook'
    )
    
    parser.add_argument(
        '--severity',
        choices=['low', 'medium', 'high'],
        default='low',
        help='Minimum severity to report (default: low)'
    )
    
    parser.add_argument(
        '--no-external',
        action='store_true',
        help='Disable external tools (shellcheck, bandit)'
    )
    
    args = parser.parse_args()
    
    linter = ScriptLinter(verbose=args.verbose)
    
    # Install pre-commit hook if requested
    if args.install_hook:
        linter.print_header()
        setup_pre_commit_hook()
        return 0
    
    # Show help if no files provided
    if not args.files:
        parser.print_help()
        return 0
    
    linter.print_header()
    
    total_security = 0
    total_practices = 0
    all_reports = []
    
    # Lint each file
    for file_path in args.files:
        if not os.path.exists(file_path):
            print(f"{Colors.RED}Error: File not found: {file_path}{Colors.NC}")
            continue
        
        print(f"\n{Colors.BLUE}Linting: {file_path}{Colors.NC}")
        
        security_count, practice_count = linter.lint_file(file_path)
        total_security += security_count
        total_practices += practice_count
        
        # Filter by severity
        if args.severity != 'low':
            linter.security_issues = [
                i for i in linter.security_issues
                if i.severity in (['high', 'medium'] if args.severity == 'medium' else ['high'])
            ]
        
        # Generate report
        report = linter.generate_report(file_path)
        all_reports.append(report)
        
        # Print or save report
        if args.json:
            if args.output:
                with open(args.output, 'w') as f:
                    json.dump(all_reports, f, indent=2)
            else:
                print(json.dumps(report, indent=2))
        else:
            linter.print_report(file_path)
    
    # Overall summary for multiple files
    if len(args.files) > 1 and not args.json:
        print(f"\n{Colors.BLUE}═══════════════ Overall Summary ═══════════════{Colors.NC}")
        print(f"Files analyzed: {len(args.files)}")
        print(f"Total security issues: {total_security}")
        print(f"Total best practice issues: {total_practices}")
        
        if total_security == 0 and total_practices == 0:
            print(f"\n{Colors.GREEN}✓ All scripts passed linting!{Colors.NC}")
        
    # Exit with error if high severity issues found
    high_severity_count = sum(
        len([i for i in report['security']['issues'] if i['severity'] == 'high'])
        for report in all_reports
    )
    
    return 1 if high_severity_count > 0 else 0


if __name__ == "__main__":
    sys.exit(main())