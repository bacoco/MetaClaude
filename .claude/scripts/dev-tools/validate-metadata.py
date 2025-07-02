#!/usr/bin/env python3

"""
Validate Script Metadata - Validate and fix script metadata against registry schema
This tool helps ensure scripts have properly formatted metadata for TES registration.
"""

import json
import sys
import os
import argparse
from pathlib import Path
from typing import Dict, List, Any, Optional, Tuple
from datetime import datetime
import re

# ANSI color codes
class Colors:
    GREEN = '\033[0;32m'
    BLUE = '\033[0;34m'
    YELLOW = '\033[1;33m'
    RED = '\033[0;31m'
    CYAN = '\033[0;36m'
    NC = '\033[0m'

# Registry schema definition
REGISTRY_SCHEMA = {
    "required_fields": [
        "id", "name", "category", "path", "description", 
        "execution", "version"
    ],
    "optional_fields": [
        "outputs", "specialists", "dependencies", "security",
        "examples", "tags", "author", "last_updated"
    ],
    "field_types": {
        "id": str,
        "name": str,
        "category": str,
        "path": str,
        "description": str,
        "version": str,
        "execution": dict,
        "outputs": list,
        "specialists": list,
        "dependencies": list,
        "security": dict,
        "examples": list,
        "tags": list,
        "author": str,
        "last_updated": str
    },
    "execution_schema": {
        "required": ["type", "interpreter", "args"],
        "optional": ["timeout", "permissions", "environment"],
        "arg_schema": {
            "required": ["name", "type", "description"],
            "optional": ["required", "default", "choices", "pattern"]
        }
    },
    "output_schema": {
        "required": ["name", "type", "description"],
        "optional": ["format", "example"]
    },
    "security_schema": {
        "required": ["sandbox"],
        "optional": ["max_memory", "network_access", "file_access", "max_cpu"]
    },
    "valid_categories": [
        "analysis", "data", "validation", "generation", 
        "integration", "monitoring", "core", "utility"
    ],
    "valid_arg_types": [
        "string", "number", "boolean", "array", "object", "file"
    ],
    "valid_permissions": [
        "read_file", "write_file", "network", "execute", "system"
    ],
    "valid_sandboxes": [
        "none", "minimal", "standard", "strict"
    ]
}


class MetadataValidator:
    """Validator for script metadata"""
    
    def __init__(self, verbose: bool = False):
        self.verbose = verbose
        self.errors: List[str] = []
        self.warnings: List[str] = []
        self.suggestions: List[str] = []
        
    def print_header(self):
        """Print tool header"""
        print(f"{Colors.CYAN}╔══════════════════════════════════════════════════════════╗{Colors.NC}")
        print(f"{Colors.CYAN}║        TES Metadata Validator - Version 1.0.0            ║{Colors.NC}")
        print(f"{Colors.CYAN}╚══════════════════════════════════════════════════════════╝{Colors.NC}")
        print()
    
    def validate_metadata(self, metadata: Dict[str, Any], file_path: Optional[str] = None) -> bool:
        """Validate metadata against schema"""
        self.errors = []
        self.warnings = []
        self.suggestions = []
        
        # Check required fields
        for field in REGISTRY_SCHEMA["required_fields"]:
            if field not in metadata:
                self.errors.append(f"Missing required field: '{field}'")
            elif not metadata[field]:
                self.errors.append(f"Required field '{field}' is empty")
        
        # Check field types
        for field, expected_type in REGISTRY_SCHEMA["field_types"].items():
            if field in metadata and not isinstance(metadata.get(field), expected_type):
                self.errors.append(
                    f"Field '{field}' has wrong type. Expected {expected_type.__name__}, "
                    f"got {type(metadata[field]).__name__}"
                )
        
        # Validate specific fields
        if "id" in metadata:
            self._validate_id(metadata["id"])
        
        if "category" in metadata:
            self._validate_category(metadata["category"])
        
        if "path" in metadata:
            self._validate_path(metadata["path"], file_path)
        
        if "version" in metadata:
            self._validate_version(metadata["version"])
        
        if "execution" in metadata:
            self._validate_execution(metadata["execution"])
        
        if "outputs" in metadata:
            self._validate_outputs(metadata["outputs"])
        
        if "security" in metadata:
            self._validate_security(metadata["security"])
        
        if "dependencies" in metadata:
            self._validate_dependencies(metadata["dependencies"])
        
        # Check for unused fields
        known_fields = set(REGISTRY_SCHEMA["required_fields"] + REGISTRY_SCHEMA["optional_fields"])
        unknown_fields = set(metadata.keys()) - known_fields
        for field in unknown_fields:
            self.warnings.append(f"Unknown field: '{field}'")
        
        # Generate suggestions
        self._generate_suggestions(metadata)
        
        return len(self.errors) == 0
    
    def _validate_id(self, script_id: str):
        """Validate script ID format"""
        if not re.match(r'^[a-z0-9-]+/[a-z0-9-]+$', script_id):
            self.errors.append(
                f"Invalid ID format: '{script_id}'. "
                "Expected format: 'category/script-name'"
            )
    
    def _validate_category(self, category: str):
        """Validate category"""
        if category not in REGISTRY_SCHEMA["valid_categories"]:
            self.errors.append(
                f"Invalid category: '{category}'. "
                f"Valid categories: {', '.join(REGISTRY_SCHEMA['valid_categories'])}"
            )
    
    def _validate_path(self, path: str, metadata_file: Optional[str]):
        """Validate script path"""
        if not path.startswith("scripts/"):
            self.warnings.append(
                f"Path should start with 'scripts/': '{path}'"
            )
        
        # Check if file exists (relative to registry)
        if metadata_file:
            base_dir = Path(metadata_file).parent.parent
            script_path = base_dir / path
            if not script_path.exists():
                self.errors.append(f"Script file not found: {script_path}")
    
    def _validate_version(self, version: str):
        """Validate version format"""
        if not re.match(r'^\d+\.\d+\.\d+$', version):
            self.errors.append(
                f"Invalid version format: '{version}'. "
                "Expected semantic versioning (e.g., 1.0.0)"
            )
    
    def _validate_execution(self, execution: Dict[str, Any]):
        """Validate execution configuration"""
        # Check required fields
        for field in REGISTRY_SCHEMA["execution_schema"]["required"]:
            if field not in execution:
                self.errors.append(f"Missing execution field: '{field}'")
        
        # Validate args
        if "args" in execution and isinstance(execution["args"], list):
            for i, arg in enumerate(execution["args"]):
                self._validate_arg(arg, i)
        
        # Validate timeout
        if "timeout" in execution:
            if not isinstance(execution["timeout"], (int, float)) or execution["timeout"] <= 0:
                self.errors.append("Timeout must be a positive number")
        
        # Validate permissions
        if "permissions" in execution:
            for perm in execution["permissions"]:
                if perm not in REGISTRY_SCHEMA["valid_permissions"]:
                    self.warnings.append(
                        f"Unknown permission: '{perm}'. "
                        f"Valid permissions: {', '.join(REGISTRY_SCHEMA['valid_permissions'])}"
                    )
    
    def _validate_arg(self, arg: Dict[str, Any], index: int):
        """Validate argument definition"""
        # Check required fields
        for field in REGISTRY_SCHEMA["execution_schema"]["arg_schema"]["required"]:
            if field not in arg:
                self.errors.append(f"Argument {index}: Missing required field '{field}'")
        
        # Validate type
        if "type" in arg and arg["type"] not in REGISTRY_SCHEMA["valid_arg_types"]:
            self.errors.append(
                f"Argument {index}: Invalid type '{arg['type']}'. "
                f"Valid types: {', '.join(REGISTRY_SCHEMA['valid_arg_types'])}"
            )
        
        # Validate name format
        if "name" in arg and not re.match(r'^[a-z_][a-z0-9_]*$', arg["name"]):
            self.warnings.append(
                f"Argument {index}: Name '{arg['name']}' should follow snake_case convention"
            )
    
    def _validate_outputs(self, outputs: List[Dict[str, Any]]):
        """Validate output definitions"""
        for i, output in enumerate(outputs):
            for field in REGISTRY_SCHEMA["output_schema"]["required"]:
                if field not in output:
                    self.errors.append(f"Output {i}: Missing required field '{field}'")
            
            if "type" in output and output["type"] not in REGISTRY_SCHEMA["valid_arg_types"]:
                self.warnings.append(f"Output {i}: Unknown type '{output['type']}'")
    
    def _validate_security(self, security: Dict[str, Any]):
        """Validate security configuration"""
        # Check sandbox
        if "sandbox" in security:
            if security["sandbox"] not in REGISTRY_SCHEMA["valid_sandboxes"]:
                self.errors.append(
                    f"Invalid sandbox type: '{security['sandbox']}'. "
                    f"Valid types: {', '.join(REGISTRY_SCHEMA['valid_sandboxes'])}"
                )
        else:
            self.warnings.append("Security configuration missing 'sandbox' field")
        
        # Validate memory limit format
        if "max_memory" in security:
            if not re.match(r'^\d+[MG]B$', security["max_memory"]):
                self.errors.append(
                    "Invalid memory limit format. Expected format: '512MB' or '1GB'"
                )
    
    def _validate_dependencies(self, dependencies: List[str]):
        """Validate dependencies"""
        for dep in dependencies:
            if not isinstance(dep, str) or not dep:
                self.errors.append(f"Invalid dependency: {dep}")
    
    def _generate_suggestions(self, metadata: Dict[str, Any]):
        """Generate improvement suggestions"""
        # Check description length
        if "description" in metadata:
            desc_len = len(metadata["description"])
            if desc_len < 10:
                self.suggestions.append("Description is very short. Consider adding more detail.")
            elif desc_len > 200:
                self.suggestions.append("Description is quite long. Consider making it more concise.")
        
        # Check for missing optional fields that are recommended
        recommended_fields = ["outputs", "security", "tags"]
        for field in recommended_fields:
            if field not in metadata:
                self.suggestions.append(f"Consider adding '{field}' field for better documentation")
        
        # Check for examples
        if "examples" not in metadata or not metadata.get("examples"):
            self.suggestions.append("Consider adding usage examples")
        
        # Check timeout
        if "execution" in metadata and "timeout" not in metadata["execution"]:
            self.suggestions.append("Consider specifying an execution timeout")
        
        # Check tags
        if "tags" in metadata and len(metadata["tags"]) < 2:
            self.suggestions.append("Consider adding more tags for better discoverability")
    
    def auto_fix(self, metadata: Dict[str, Any]) -> Dict[str, Any]:
        """Attempt to auto-fix common issues"""
        fixed = metadata.copy()
        fixes_applied = []
        
        # Fix ID format
        if "id" in fixed and "/" not in fixed["id"]:
            if "category" in fixed and "name" in fixed:
                fixed["id"] = f"{fixed['category']}/{fixed['name']}"
                fixes_applied.append("Generated ID from category and name")
        
        # Fix path format
        if "path" in fixed and not fixed["path"].startswith("scripts/"):
            fixed["path"] = f"scripts/{fixed['path']}"
            fixes_applied.append("Added 'scripts/' prefix to path")
        
        # Add default version if missing
        if "version" not in fixed:
            fixed["version"] = "1.0.0"
            fixes_applied.append("Added default version 1.0.0")
        
        # Add default security if missing
        if "security" not in fixed:
            fixed["security"] = {
                "sandbox": "minimal",
                "max_memory": "512MB",
                "network_access": False
            }
            fixes_applied.append("Added default security configuration")
        
        # Fix timeout type
        if "execution" in fixed and "timeout" in fixed["execution"]:
            timeout = fixed["execution"]["timeout"]
            if isinstance(timeout, str) and timeout.isdigit():
                fixed["execution"]["timeout"] = int(timeout)
                fixes_applied.append("Converted timeout to integer")
        
        # Add empty outputs if missing
        if "outputs" not in fixed:
            fixed["outputs"] = []
            fixes_applied.append("Added empty outputs array")
        
        # Report fixes
        if fixes_applied:
            print(f"\n{Colors.BLUE}Auto-fixes applied:{Colors.NC}")
            for fix in fixes_applied:
                print(f"  • {fix}")
        
        return fixed
    
    def print_report(self):
        """Print validation report"""
        print(f"\n{Colors.BLUE}═══════════════ Validation Report ═══════════════{Colors.NC}")
        
        # Errors
        if self.errors:
            print(f"\n{Colors.RED}Errors ({len(self.errors)}):{Colors.NC}")
            for error in self.errors:
                print(f"  ✗ {error}")
        else:
            print(f"\n{Colors.GREEN}✓ No errors found{Colors.NC}")
        
        # Warnings
        if self.warnings:
            print(f"\n{Colors.YELLOW}Warnings ({len(self.warnings)}):{Colors.NC}")
            for warning in self.warnings:
                print(f"  ⚠ {warning}")
        
        # Suggestions
        if self.suggestions:
            print(f"\n{Colors.CYAN}Suggestions ({len(self.suggestions)}):{Colors.NC}")
            for suggestion in self.suggestions:
                print(f"  → {suggestion}")
        
        # Summary
        print(f"\n{Colors.BLUE}Summary:{Colors.NC}")
        status = "PASSED" if not self.errors else "FAILED"
        color = Colors.GREEN if not self.errors else Colors.RED
        print(f"  Status: {color}{status}{Colors.NC}")
        print(f"  Errors: {len(self.errors)}")
        print(f"  Warnings: {len(self.warnings)}")
        print(f"  Suggestions: {len(self.suggestions)}")


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description='Validate and fix script metadata for TES registry',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument(
        'file',
        nargs='?',
        help='Metadata file to validate (JSON format)'
    )
    
    parser.add_argument(
        '-r', '--registry',
        default='/Users/loic/develop/DesignerClaude/UIDesignerClaude/.claude/scripts/registry.json',
        help='Path to registry file (default: scripts/registry.json)'
    )
    
    parser.add_argument(
        '-f', '--fix',
        action='store_true',
        help='Automatically fix common issues'
    )
    
    parser.add_argument(
        '-o', '--output',
        help='Output fixed metadata to file'
    )
    
    parser.add_argument(
        '-a', '--all',
        action='store_true',
        help='Validate all scripts in registry'
    )
    
    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='Show detailed output'
    )
    
    parser.add_argument(
        '--schema',
        action='store_true',
        help='Show registry schema'
    )
    
    args = parser.parse_args()
    
    validator = MetadataValidator(verbose=args.verbose)
    validator.print_header()
    
    # Show schema if requested
    if args.schema:
        print(f"{Colors.BLUE}Registry Schema:{Colors.NC}")
        print(json.dumps(REGISTRY_SCHEMA, indent=2))
        return 0
    
    # Validate all scripts in registry
    if args.all:
        if not os.path.exists(args.registry):
            print(f"{Colors.RED}Error: Registry file not found: {args.registry}{Colors.NC}")
            return 1
        
        with open(args.registry, 'r') as f:
            registry = json.load(f)
        
        print(f"Validating {len(registry.get('scripts', []))} scripts...\n")
        
        total_errors = 0
        for script in registry.get('scripts', []):
            print(f"{Colors.BLUE}Validating: {script.get('id', 'unknown')}{Colors.NC}")
            
            if validator.validate_metadata(script, args.registry):
                print(f"{Colors.GREEN}  ✓ Valid{Colors.NC}")
            else:
                print(f"{Colors.RED}  ✗ Invalid ({len(validator.errors)} errors){Colors.NC}")
                total_errors += len(validator.errors)
        
        print(f"\n{Colors.BLUE}Total errors: {total_errors}{Colors.NC}")
        return 0 if total_errors == 0 else 1
    
    # Validate single file
    if not args.file:
        parser.print_help()
        return 0
    
    if not os.path.exists(args.file):
        print(f"{Colors.RED}Error: File not found: {args.file}{Colors.NC}")
        return 1
    
    try:
        with open(args.file, 'r') as f:
            metadata = json.load(f)
    except json.JSONDecodeError as e:
        print(f"{Colors.RED}Error: Invalid JSON in {args.file}: {e}{Colors.NC}")
        return 1
    
    # Validate metadata
    is_valid = validator.validate_metadata(metadata, args.file)
    
    # Apply fixes if requested
    if args.fix:
        metadata = validator.auto_fix(metadata)
        
        # Re-validate after fixes
        print(f"\n{Colors.BLUE}Re-validating after fixes...{Colors.NC}")
        is_valid = validator.validate_metadata(metadata, args.file)
    
    # Print report
    validator.print_report()
    
    # Save fixed metadata if requested
    if args.fix and args.output:
        with open(args.output, 'w') as f:
            json.dump(metadata, f, indent=2)
        print(f"\n{Colors.GREEN}Fixed metadata saved to: {args.output}{Colors.NC}")
    elif args.fix and not args.output:
        print(f"\n{Colors.YELLOW}Fixed metadata (use -o to save):{Colors.NC}")
        print(json.dumps(metadata, indent=2))
    
    return 0 if is_valid else 1


if __name__ == "__main__":
    sys.exit(main())