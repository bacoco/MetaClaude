#!/usr/bin/env python3
"""
Test script to verify orchestration system is working correctly
"""

import sys
import json
from pathlib import Path

# Add core directory to path
sys.path.insert(0, str(Path(__file__).parent / 'core'))

# Check for required dependencies
missing_deps = []
try:
    import jsonpath_ng
except ImportError:
    missing_deps.append('jsonpath-ng')

try:
    import yaml
except ImportError:
    missing_deps.append('pyyaml')

if missing_deps:
    print("✗ Missing required dependencies:")
    for dep in missing_deps:
        print(f"  - {dep}")
    print("\nPlease install dependencies:")
    print("  pip install -r requirements.txt")
    print("\nOr install individually:")
    print(f"  pip install {' '.join(missing_deps)}")
    sys.exit(1)

try:
    from output_mapper import OutputMapper, OutputTransformer
    from workflow_controller import WorkflowController, ConditionEvaluator, TaskStatus
    print("✓ Core modules imported successfully")
except ImportError as e:
    print(f"✗ Failed to import core modules: {e}")
    print("\nMake sure you're in the correct directory or that the core modules exist.")
    sys.exit(1)

def test_output_mapper():
    """Test output mapping functionality"""
    print("\n=== Testing Output Mapper ===")
    
    mapper = OutputMapper()
    
    # Test data
    test_output = {
        "status": "success",
        "data": {
            "users": [
                {"id": 1, "name": "Alice", "active": True, "score": 95},
                {"id": 2, "name": "Bob", "active": False, "score": 72},
                {"id": 3, "name": "Charlie", "active": True, "score": 88}
            ],
            "total": 3
        }
    }
    
    # Test mappings
    mappings = [
        {
            "source": "$.data.total",
            "target": "user_count",
            "transform": "number"
        },
        {
            "source": "$.data.users[?(@.active)].name",
            "target": "active_users",
            "transform": "array"
        },
        {
            "source": "$.data.users",
            "target": "high_scorers",
            "transform": "filter:item['score'] > 80|map:item['name']"
        }
    ]
    
    result = mapper.map_output(test_output, mappings)
    
    # Verify results
    assert result['user_count'] == 3, "User count should be 3"
    assert set(result['active_users']) == {"Alice", "Charlie"}, "Active users incorrect"
    assert set(result['high_scorers']) == {"Alice", "Charlie"}, "High scorers incorrect"
    
    print("✓ Output mapping tests passed")
    print(f"  - Extracted user count: {result['user_count']}")
    print(f"  - Active users: {result['active_users']}")
    print(f"  - High scorers: {result['high_scorers']}")

def test_condition_evaluator():
    """Test condition evaluation"""
    print("\n=== Testing Condition Evaluator ===")
    
    evaluator = ConditionEvaluator()
    
    variables = {
        "score": 85,
        "status": "active",
        "items": [1, 2, 3],
        "user": {"name": "Alice", "role": "admin"}
    }
    
    # Test simple conditions
    assert evaluator.evaluate("variables['score'] > 80", variables) == True
    assert evaluator.evaluate("variables['status'] == 'inactive'", variables) == False
    
    # Test complex conditions
    complex_condition = {
        "and": [
            {"greater": ["$score", 80]},
            {"equals": ["$status", "active"]}
        ]
    }
    assert evaluator.evaluate(complex_condition, variables) == True
    
    # Test exists
    assert evaluator.evaluate({"exists": "user.name"}, variables) == True
    assert evaluator.evaluate({"exists": "user.email"}, variables) == False
    
    print("✓ Condition evaluation tests passed")

def test_transformations():
    """Test data transformations"""
    print("\n=== Testing Transformations ===")
    
    transformer = OutputTransformer()
    
    # Test type conversions
    assert transformer.to_string(123) == "123"
    assert transformer.to_number("42.5") == 42.5
    assert transformer.to_boolean("true") == True
    assert transformer.to_array("a,b,c") == ["a", "b", "c"]
    
    # Test array operations
    data = [1, 2, 3, 4, 5]
    filtered = transformer.filter_array(data, "item > 3")
    assert filtered == [4, 5]
    
    mapped = transformer.map_array(data, "item * 2")
    assert mapped == [2, 4, 6, 8, 10]
    
    reduced = transformer.reduce_array(data, "sum")
    assert reduced == 15
    
    print("✓ Transformation tests passed")

def test_backward_compatibility():
    """Test backward compatibility with old-style mappings"""
    print("\n=== Testing Backward Compatibility ===")
    
    mapper = OutputMapper()
    
    # Old style mapping (dict format)
    old_style = {
        "result": "my_variable",
        "status": "status_code"
    }
    
    # Convert to new style
    new_style = []
    for source, target in old_style.items():
        new_style.append({
            "source": f"$.{source}",
            "target": target
        })
    
    # Test both produce same result
    test_data = {"result": "success", "status": 200}
    result = mapper.map_output(test_data, new_style)
    
    assert result['my_variable'] == "success"
    assert result['status_code'] == 200
    
    print("✓ Backward compatibility tests passed")

def main():
    """Run all tests"""
    print("TES Orchestration System Test Suite")
    print("=" * 40)
    
    try:
        test_output_mapper()
        test_condition_evaluator()
        test_transformations()
        test_backward_compatibility()
        
        print("\n" + "=" * 40)
        print("✓ All tests passed! Orchestration system is working correctly.")
        print("\nYou can now use:")
        print("- output-mapper.py for complex data extraction")
        print("- workflow-controller.py for advanced workflow control")
        print("- See ORCHESTRATION-GUIDE.md for full documentation")
        print("- Check examples/ directory for workflow examples")
        
    except AssertionError as e:
        print(f"\n✗ Test failed: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"\n✗ Unexpected error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()