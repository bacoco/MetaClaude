#!/usr/bin/env python3
"""
Minimal Output Mapper - Works without external dependencies
Falls back to basic functionality when jsonpath_ng is not available
"""

import json
import re
from typing import Any, Dict, List, Union, Optional
from dataclasses import dataclass

# Try to import jsonpath_ng, but don't fail if not available
try:
    from jsonpath_ng import parse
    JSONPATH_AVAILABLE = True
except ImportError:
    JSONPATH_AVAILABLE = False


@dataclass
class MappingRule:
    """Defines a mapping rule for output transformation"""
    source: str
    target: str
    transform: Optional[str] = None
    default: Any = None
    required: bool = False


class OutputMapper:
    """Minimal output mapper with fallback for missing dependencies"""
    
    def __init__(self):
        self.jsonpath_available = JSONPATH_AVAILABLE
        if not self.jsonpath_available:
            print("Note: jsonpath_ng not available. Using basic path extraction.")
    
    def map_output(self, output: Dict[str, Any], mappings: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Map tool output to workflow variables"""
        # Handle backward compatibility - convert dict to list
        if isinstance(mappings, dict):
            mappings = [
                {"source": f"$.{k}", "target": v}
                for k, v in mappings.items()
            ]
        
        result = {}
        errors = []
        
        for mapping_config in mappings:
            try:
                rule = MappingRule(**mapping_config)
                value = self._extract_value(output, rule.source)
                
                if value is None:
                    if rule.required:
                        errors.append(f"Required field '{rule.source}' not found")
                        continue
                    elif rule.default is not None:
                        value = rule.default
                    else:
                        continue
                
                # Apply transformation
                if rule.transform:
                    value = self._apply_basic_transform(value, rule.transform)
                
                result[rule.target] = value
                
            except Exception as e:
                errors.append(f"Error mapping '{mapping_config.get('source', 'unknown')}': {str(e)}")
        
        if errors:
            result['_mapping_errors'] = errors
            
        return result
    
    def _extract_value(self, data: Dict[str, Any], path: str) -> Any:
        """Extract value using path expression"""
        if self.jsonpath_available and path.startswith('$'):
            # Use jsonpath_ng if available
            try:
                jsonpath_expr = parse(path)
                matches = jsonpath_expr.find(data)
                if matches:
                    if len(matches) == 1:
                        return matches[0].value
                    else:
                        return [match.value for match in matches]
            except:
                # Fall back to basic extraction
                pass
        
        # Basic extraction (always available)
        return self._basic_extract(data, path)
    
    def _basic_extract(self, data: Dict[str, Any], path: str) -> Any:
        """Basic path extraction without jsonpath_ng"""
        # Remove $ prefix if present
        if path.startswith('$'):
            path = path[1:]
        if path.startswith('.'):
            path = path[1:]
        
        # Handle simple paths
        if not path:
            return data
        
        # Split by dots, handling array indices
        parts = []
        current = ''
        in_brackets = False
        
        for char in path:
            if char == '[':
                if current:
                    parts.append(current)
                    current = ''
                in_brackets = True
            elif char == ']':
                if current:
                    parts.append(f"[{current}]")
                    current = ''
                in_brackets = False
            elif char == '.' and not in_brackets:
                if current:
                    parts.append(current)
                    current = ''
            else:
                current += char
        
        if current:
            parts.append(current)
        
        # Navigate through the data
        current_data = data
        for part in parts:
            if part.startswith('[') and part.endswith(']'):
                # Array index
                index = part[1:-1]
                if index == '*':
                    # Return all items
                    if isinstance(current_data, list):
                        return current_data
                    else:
                        return None
                elif index.isdigit():
                    index = int(index)
                    if isinstance(current_data, list) and 0 <= index < len(current_data):
                        current_data = current_data[index]
                    else:
                        return None
                else:
                    return None
            else:
                # Dictionary key
                if isinstance(current_data, dict) and part in current_data:
                    current_data = current_data[part]
                else:
                    return None
        
        return current_data
    
    def _apply_basic_transform(self, value: Any, transform: str) -> Any:
        """Apply basic transformations"""
        # Type conversions
        if transform == 'string':
            return str(value) if value is not None else ''
        elif transform == 'number':
            try:
                if isinstance(value, str):
                    return float(value) if '.' in value else int(value)
                return float(value)
            except:
                return 0
        elif transform == 'boolean':
            if isinstance(value, str):
                return value.lower() in ('true', 'yes', '1', 'on')
            return bool(value)
        elif transform == 'array':
            if isinstance(value, list):
                return value
            elif value is None:
                return []
            else:
                return [value]
        elif transform == 'object':
            if isinstance(value, dict):
                return value
            else:
                return {"value": value}
        
        # No transformation
        return value


# Test the minimal mapper
if __name__ == '__main__':
    mapper = OutputMapper()
    
    # Test data
    test_data = {
        "status": "success",
        "data": {
            "users": [
                {"name": "Alice", "active": True},
                {"name": "Bob", "active": False}
            ],
            "count": 2
        }
    }
    
    # Test mappings
    mappings = [
        {"source": "$.status", "target": "status"},
        {"source": "$.data.count", "target": "user_count", "transform": "number"},
        {"source": "$.data.users[0].name", "target": "first_user"},
        {"source": "$.missing", "target": "missing_field", "default": "not found"}
    ]
    
    result = mapper.map_output(test_data, mappings)
    print("Mapped output:")
    print(json.dumps(result, indent=2))