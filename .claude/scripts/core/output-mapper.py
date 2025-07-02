#!/usr/bin/env python3
"""
Advanced Output Mapper for TES Orchestration
Maps complex tool outputs to workflow variables with transformation support
"""

import json
import re
from typing import Any, Dict, List, Union, Optional, Callable
from dataclasses import dataclass
from jsonpath_ng import parse
from functools import reduce
import operator


@dataclass
class MappingRule:
    """Defines a mapping rule for output transformation"""
    source: str  # JSONPath expression
    target: str  # Target variable name
    transform: Optional[str] = None  # Transformation type
    default: Any = None  # Default value if source not found
    required: bool = False  # Whether this mapping is required
    
    
class OutputTransformer:
    """Handles output transformations"""
    
    @staticmethod
    def to_string(value: Any) -> str:
        """Convert any value to string"""
        if isinstance(value, (dict, list)):
            return json.dumps(value)
        return str(value)
    
    @staticmethod
    def to_number(value: Any) -> Union[int, float]:
        """Convert value to number"""
        if isinstance(value, str):
            # Try to parse as float first, then int
            try:
                if '.' in value:
                    return float(value)
                return int(value)
            except ValueError:
                raise ValueError(f"Cannot convert '{value}' to number")
        return float(value)
    
    @staticmethod
    def to_boolean(value: Any) -> bool:
        """Convert value to boolean"""
        if isinstance(value, str):
            return value.lower() in ('true', 'yes', '1', 'on')
        return bool(value)
    
    @staticmethod
    def to_array(value: Any) -> List[Any]:
        """Convert value to array"""
        if isinstance(value, list):
            return value
        elif isinstance(value, dict):
            return list(value.values())
        elif isinstance(value, str):
            # Try to parse as JSON array
            try:
                parsed = json.loads(value)
                if isinstance(parsed, list):
                    return parsed
            except json.JSONDecodeError:
                pass
            # Split by comma if not JSON
            return [item.strip() for item in value.split(',')]
        return [value]
    
    @staticmethod
    def to_object(value: Any) -> Dict[str, Any]:
        """Convert value to object/dict"""
        if isinstance(value, dict):
            return value
        elif isinstance(value, str):
            try:
                parsed = json.loads(value)
                if isinstance(parsed, dict):
                    return parsed
            except json.JSONDecodeError:
                pass
        elif isinstance(value, list):
            # Convert list to dict with index keys
            return {str(i): v for i, v in enumerate(value)}
        return {"value": value}
    
    @staticmethod
    def filter_array(value: List[Any], condition: str) -> List[Any]:
        """Filter array based on condition"""
        if not isinstance(value, list):
            raise ValueError("Filter requires array input")
        
        # Parse condition (e.g., "item > 5", "item.status == 'active'")
        # Simple implementation - can be extended
        filtered = []
        for item in value:
            try:
                # Create local scope for evaluation
                local_vars = {"item": item}
                if eval(condition, {"__builtins__": {}}, local_vars):
                    filtered.append(item)
            except Exception:
                continue
        return filtered
    
    @staticmethod
    def map_array(value: List[Any], expression: str) -> List[Any]:
        """Map array elements using expression"""
        if not isinstance(value, list):
            raise ValueError("Map requires array input")
        
        mapped = []
        for item in value:
            try:
                local_vars = {"item": item}
                result = eval(expression, {"__builtins__": {}}, local_vars)
                mapped.append(result)
            except Exception as e:
                mapped.append(None)
        return mapped
    
    @staticmethod
    def reduce_array(value: List[Any], operation: str, initial: Any = None) -> Any:
        """Reduce array to single value"""
        if not isinstance(value, list):
            raise ValueError("Reduce requires array input")
        
        operations = {
            'sum': lambda x, y: x + y,
            'product': lambda x, y: x * y,
            'min': min,
            'max': max,
            'count': lambda x, _: x + 1,
            'concat': lambda x, y: str(x) + str(y)
        }
        
        if operation in operations:
            if operation in ('min', 'max'):
                return operations[operation](value)
            elif operation == 'count':
                return len(value)
            else:
                return reduce(operations[operation], value, initial or 0)
        else:
            # Custom reduce expression
            return reduce(lambda x, y: eval(operation, {"__builtins__": {}, "acc": x, "item": y}), value, initial)


class OutputMapper:
    """Maps complex TES outputs to workflow variables"""
    
    def __init__(self):
        self.transformer = OutputTransformer()
        self.transformers = {
            'string': self.transformer.to_string,
            'number': self.transformer.to_number,
            'boolean': self.transformer.to_boolean,
            'array': self.transformer.to_array,
            'object': self.transformer.to_object,
        }
    
    def map_output(self, output: Dict[str, Any], mappings: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Map tool output to workflow variables based on mapping rules
        
        Args:
            output: Raw tool output
            mappings: List of mapping rules
            
        Returns:
            Mapped variables dictionary
        """
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
                    value = self._apply_transform(value, rule.transform)
                
                result[rule.target] = value
                
            except Exception as e:
                errors.append(f"Error mapping '{mapping_config.get('source', 'unknown')}': {str(e)}")
        
        if errors:
            result['_mapping_errors'] = errors
            
        return result
    
    def _extract_value(self, data: Dict[str, Any], path: str) -> Any:
        """Extract value using JSONPath expression"""
        if path.startswith('$'):
            # JSONPath expression
            jsonpath_expr = parse(path)
            matches = jsonpath_expr.find(data)
            if matches:
                # Return first match for single value, array for multiple
                if len(matches) == 1:
                    return matches[0].value
                else:
                    return [match.value for match in matches]
        else:
            # Simple dot notation
            parts = path.split('.')
            current = data
            for part in parts:
                if isinstance(current, dict) and part in current:
                    current = current[part]
                elif isinstance(current, list) and part.isdigit():
                    index = int(part)
                    if 0 <= index < len(current):
                        current = current[index]
                    else:
                        return None
                else:
                    return None
            return current
        return None
    
    def _apply_transform(self, value: Any, transform: str) -> Any:
        """Apply transformation to value"""
        # Basic type transformations
        if transform in self.transformers:
            return self.transformers[transform](value)
        
        # Pipeline transformations (e.g., "filter:item > 5|map:item * 2|reduce:sum")
        if '|' in transform:
            transforms = transform.split('|')
            result = value
            for t in transforms:
                result = self._apply_single_transform(result, t.strip())
            return result
        
        # Single complex transformation
        return self._apply_single_transform(value, transform)
    
    def _apply_single_transform(self, value: Any, transform: str) -> Any:
        """Apply a single transformation"""
        if ':' in transform:
            operation, param = transform.split(':', 1)
            
            if operation == 'filter':
                return self.transformer.filter_array(value, param)
            elif operation == 'map':
                return self.transformer.map_array(value, param)
            elif operation == 'reduce':
                # Parse reduce parameters
                parts = param.split(',')
                op = parts[0]
                initial = eval(parts[1]) if len(parts) > 1 else None
                return self.transformer.reduce_array(value, op, initial)
            elif operation == 'regex':
                # Extract using regex
                if isinstance(value, str):
                    match = re.search(param, value)
                    return match.group(1) if match and match.groups() else match.group(0) if match else None
            elif operation == 'split':
                # Split string
                if isinstance(value, str):
                    return value.split(param)
            elif operation == 'join':
                # Join array
                if isinstance(value, list):
                    return param.join(str(item) for item in value)
            elif operation == 'keys':
                # Get object keys
                if isinstance(value, dict):
                    return list(value.keys())
            elif operation == 'values':
                # Get object values
                if isinstance(value, dict):
                    return list(value.values())
            
        # Custom transformation expression
        try:
            return eval(transform, {"__builtins__": {}, "value": value, "json": json})
        except Exception:
            return value
    
    def create_mapping_pipeline(self, mappings: List[Dict[str, Any]]) -> Callable:
        """Create a reusable mapping pipeline"""
        def pipeline(output: Dict[str, Any]) -> Dict[str, Any]:
            return self.map_output(output, mappings)
        return pipeline
    
    def validate_mapping(self, mapping: Dict[str, Any], sample_output: Dict[str, Any]) -> Dict[str, Any]:
        """Validate a mapping against sample output"""
        try:
            rule = MappingRule(**mapping)
            value = self._extract_value(sample_output, rule.source)
            
            validation = {
                'valid': True,
                'source': rule.source,
                'target': rule.target,
                'found': value is not None,
                'value': value,
                'transform': rule.transform
            }
            
            if value is not None and rule.transform:
                try:
                    transformed = self._apply_transform(value, rule.transform)
                    validation['transformed_value'] = transformed
                except Exception as e:
                    validation['valid'] = False
                    validation['error'] = str(e)
            
            return validation
            
        except Exception as e:
            return {
                'valid': False,
                'error': str(e),
                'mapping': mapping
            }


# Example usage and testing
if __name__ == '__main__':
    # Sample complex output
    sample_output = {
        "status": "success",
        "data": {
            "users": [
                {"id": 1, "name": "Alice", "score": 95, "active": True},
                {"id": 2, "name": "Bob", "score": 87, "active": False},
                {"id": 3, "name": "Charlie", "score": 92, "active": True}
            ],
            "metadata": {
                "total": 3,
                "timestamp": "2024-01-15T10:30:00Z"
            }
        },
        "logs": ["Started processing", "Completed successfully"]
    }
    
    # Define mappings
    mappings = [
        {
            "source": "$.data.users[*].score",
            "target": "all_scores",
            "transform": "array"
        },
        {
            "source": "$.data.users[?(@.active)].name",
            "target": "active_users",
            "transform": "array"
        },
        {
            "source": "$.data.users",
            "target": "high_scorers",
            "transform": "filter:item['score'] > 90|map:item['name']"
        },
        {
            "source": "$.data.users[*].score",
            "target": "average_score",
            "transform": "reduce:sum|number",
            "default": 0
        },
        {
            "source": "$.data.metadata.timestamp",
            "target": "processed_at",
            "transform": "regex:(\\d{4}-\\d{2}-\\d{2})"
        }
    ]
    
    # Test mapping
    mapper = OutputMapper()
    result = mapper.map_output(sample_output, mappings)
    
    print("Mapped Output:")
    print(json.dumps(result, indent=2))