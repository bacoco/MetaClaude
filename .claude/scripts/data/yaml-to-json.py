#!/usr/bin/env python3
"""
YAML to JSON Converter
Convert YAML files to JSON format with validation
"""

import sys
import json
import yaml
import argparse
from pathlib import Path


def convert_yaml_to_json(input_file, output_file=None, pretty=True):
    """Convert YAML file to JSON format"""
    try:
        # Read YAML file
        with open(input_file, 'r') as f:
            yaml_data = yaml.safe_load(f)
        
        # Convert to JSON
        if pretty:
            json_str = json.dumps(yaml_data, indent=2, sort_keys=False)
        else:
            json_str = json.dumps(yaml_data, separators=(',', ':'))
        
        # Output
        if output_file:
            with open(output_file, 'w') as f:
                f.write(json_str)
                f.write('\n')
            
            # Return metadata
            return {
                'success': True,
                'input_file': str(input_file),
                'output_file': str(output_file),
                'data_type': type(yaml_data).__name__,
                'size': len(json_str)
            }
        else:
            # Output to stdout
            print(json_str)
            return {
                'success': True,
                'data_type': type(yaml_data).__name__,
                'size': len(json_str)
            }
            
    except yaml.YAMLError as e:
        return {
            'success': False,
            'error': f'YAML parsing error: {str(e)}'
        }
    except Exception as e:
        return {
            'success': False,
            'error': f'Conversion error: {str(e)}'
        }


def main():
    parser = argparse.ArgumentParser(description='Convert YAML to JSON')
    parser.add_argument('input_file', help='Input YAML file')
    parser.add_argument('output_file', nargs='?', help='Output JSON file (stdout if not specified)')
    parser.add_argument('--compact', action='store_true', help='Output compact JSON')
    
    args = parser.parse_args()
    
    # Check if input file exists
    input_path = Path(args.input_file)
    if not input_path.exists():
        print(f"Error: Input file not found: {args.input_file}", file=sys.stderr)
        sys.exit(1)
    
    # Convert
    result = convert_yaml_to_json(
        input_path,
        args.output_file,
        pretty=not args.compact
    )
    
    # Handle result
    if result['success']:
        if args.output_file:
            # Output metadata for TES parsing
            print(f"json_data={json.dumps({'file': args.output_file})}")
            print(f"data_type={result['data_type']}")
            print(f"size={result['size']}")
    else:
        print(result['error'], file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()