#!/usr/bin/env python3
"""
Orchestration Demo - Shows how to use the advanced orchestration system
Includes examples of backward compatibility and various features
"""

import asyncio
import json
import yaml
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent / 'core'))

from workflow_controller import WorkflowController, TaskStatus
from output_mapper import OutputMapper


class OrchestrationDemo:
    """Demonstrates orchestration system usage"""
    
    def __init__(self):
        self.controller = WorkflowController(max_parallel_tasks=5)
        self.mapper = OutputMapper()
        self._register_demo_tools()
    
    def _register_demo_tools(self):
        """Register demo tool implementations"""
        
        # HTTP GET tool
        async def http_get(url: str, headers: dict = None):
            # Simulate API call
            await asyncio.sleep(0.5)
            return {
                "status": 200,
                "response": {
                    "data": {
                        "records": [
                            {"id": 1, "name": "Item 1", "score": 95, "priority": "high"},
                            {"id": 2, "name": "Item 2", "score": 78, "priority": "normal"},
                            {"id": 3, "name": "Item 3", "score": 88, "priority": "high"},
                        ],
                        "total_count": 3
                    },
                    "metadata": {
                        "timestamp": "2024-01-15T10:30:00Z"
                    }
                }
            }
        
        # Data processor tool
        def data_processor(records: list, filter: str = None):
            if filter:
                priority = filter.split(':')[1] if ':' in filter else 'normal'
                filtered = [r for r in records if r.get('priority') == priority]
            else:
                filtered = records
            
            return {
                "processed": filtered,
                "count": len(filtered)
            }
        
        # Simple processor for backward compatibility
        def simple_processor(input: any):
            return {"result": f"Processed: {input}"}
        
        # Statistics calculator
        def statistics_calculator(data: list):
            scores = [item.get('score', 0) for item in data]
            return {
                "stats": {
                    "average": sum(scores) / len(scores) if scores else 0,
                    "min": min(scores) if scores else 0,
                    "max": max(scores) if scores else 0,
                    "distribution": {
                        "high": len([s for s in scores if s >= 90]),
                        "medium": len([s for s in scores if 70 <= s < 90]),
                        "low": len([s for s in scores if s < 70])
                    }
                }
            }
        
        # Register all tools
        self.controller.register_tool('http_get', http_get)
        self.controller.register_tool('data_processor', data_processor)
        self.controller.register_tool('simple_processor', simple_processor)
        self.controller.register_tool('statistics_calculator', statistics_calculator)
        self.controller.register_tool('http_request', http_get)  # Alias
    
    async def demo_simple_workflow(self):
        """Demonstrate simple workflow with backward compatibility"""
        print("\n=== Simple Workflow Demo (Backward Compatible) ===")
        
        workflow = {
            'id': 'simple_demo',
            'name': 'Simple Sequential Demo',
            'steps': [
                {
                    'type': 'task',
                    'id': 'fetch',
                    'tool': 'http_get',
                    'parameters': {
                        'url': 'https://api.example.com/data'
                    },
                    # Old style output mapping
                    'output_mapping': {
                        'response': 'api_response'
                    }
                },
                {
                    'type': 'task',
                    'id': 'process',
                    'tool': 'simple_processor',
                    'parameters': {
                        'input': '$api_response'
                    }
                }
            ]
        }
        
        # Convert old-style mappings automatically
        self._convert_legacy_mappings(workflow)
        
        state = await self.controller.execute_workflow(workflow)
        print(f"Status: {state.status}")
        print(f"Variables: {json.dumps(state.variables, indent=2)}")
    
    async def demo_advanced_features(self):
        """Demonstrate advanced orchestration features"""
        print("\n=== Advanced Features Demo ===")
        
        workflow = {
            'id': 'advanced_demo',
            'name': 'Advanced Orchestration Demo',
            'variables': {
                'threshold': 85
            },
            'steps': [
                # Fetch data with complex output mapping
                {
                    'type': 'task',
                    'id': 'fetch_data',
                    'tool': 'http_request',
                    'parameters': {
                        'url': 'https://api.example.com/data'
                    },
                    'output_mapping': [
                        {
                            'source': '$.response.data.records',
                            'target': 'records',
                            'transform': 'array'
                        },
                        {
                            'source': '$.response.data.records[*].score',
                            'target': 'all_scores',
                            'transform': 'array'
                        },
                        {
                            'source': '$.response.data.records',
                            'target': 'high_scorers',
                            'transform': 'filter:item["score"] > 85|map:item["name"]'
                        }
                    ]
                },
                
                # Conditional branching
                {
                    'type': 'conditional',
                    'condition': 'len(variables["high_scorers"]) > 0',
                    'then': [
                        {
                            'type': 'parallel',
                            'tasks': [
                                {
                                    'id': 'process_high',
                                    'tool': 'data_processor',
                                    'parameters': {
                                        'records': '$records',
                                        'filter': 'priority:high'
                                    }
                                },
                                {
                                    'id': 'calculate_stats',
                                    'tool': 'statistics_calculator',
                                    'parameters': {
                                        'data': '$records'
                                    },
                                    'output_mapping': [
                                        {
                                            'source': '$.stats.average',
                                            'target': 'average_score',
                                            'transform': 'number'
                                        }
                                    ]
                                }
                            ]
                        }
                    ],
                    'else': [
                        {
                            'type': 'task',
                            'id': 'no_high_scorers',
                            'tool': 'simple_processor',
                            'parameters': {
                                'input': 'No high scorers found'
                            }
                        }
                    ]
                }
            ]
        }
        
        state = await self.controller.execute_workflow(workflow)
        print(f"Status: {state.status}")
        print(f"High scorers: {state.variables.get('high_scorers', [])}")
        print(f"Average score: {state.variables.get('average_score', 'N/A')}")
        print(f"Execution path: {state.execution_path}")
    
    async def demo_output_mapping(self):
        """Demonstrate output mapping capabilities"""
        print("\n=== Output Mapping Demo ===")
        
        # Sample complex output
        sample_output = {
            "users": [
                {"id": 1, "name": "Alice", "scores": [90, 95, 88]},
                {"id": 2, "name": "Bob", "scores": [78, 82, 85]},
                {"id": 3, "name": "Charlie", "scores": [92, 88, 90]}
            ],
            "metadata": {
                "total": 3,
                "page": 1
            }
        }
        
        # Define various mappings
        mappings = [
            {
                "source": "$.users[*].name",
                "target": "user_names",
                "transform": "array"
            },
            {
                "source": "$.users[*].scores",
                "target": "all_scores_nested",
                "transform": "array"
            },
            {
                "source": "$.users",
                "target": "top_users",
                "transform": "filter:sum(item['scores'])/len(item['scores']) > 85|map:item['name']"
            },
            {
                "source": "$.metadata.total",
                "target": "user_count",
                "transform": "number"
            }
        ]
        
        # Apply mappings
        result = self.mapper.map_output(sample_output, mappings)
        print("Mapped results:")
        print(json.dumps(result, indent=2))
        
        # Validate mappings
        print("\nValidation results:")
        for mapping in mappings:
            validation = self.mapper.validate_mapping(mapping, sample_output)
            print(f"- {mapping['source']} -> {mapping['target']}: {validation['valid']}")
    
    def _convert_legacy_mappings(self, workflow: dict):
        """Convert old-style output mappings to new format"""
        for step in workflow.get('steps', []):
            if 'output_mapping' in step and isinstance(step['output_mapping'], dict):
                # Convert dict to list of mappings
                new_mappings = []
                for key, value in step['output_mapping'].items():
                    new_mappings.append({
                        'source': f'$.{key}',
                        'target': value
                    })
                step['output_mapping'] = new_mappings
    
    async def demo_error_handling(self):
        """Demonstrate error handling and retry logic"""
        print("\n=== Error Handling Demo ===")
        
        # Register a flaky tool
        attempt_count = {'count': 0}
        
        def flaky_tool(**kwargs):
            attempt_count['count'] += 1
            if attempt_count['count'] < 3:
                raise Exception(f"Simulated failure (attempt {attempt_count['count']})")
            return {"status": "success", "attempt": attempt_count['count']}
        
        self.controller.register_tool('flaky_tool', flaky_tool)
        
        workflow = {
            'id': 'error_demo',
            'steps': [
                {
                    'type': 'task',
                    'id': 'flaky_task',
                    'tool': 'flaky_tool',
                    'retry': {
                        'max_attempts': 3,
                        'delay': 0.5
                    },
                    'output_mapping': [
                        {
                            'source': '$.attempt',
                            'target': 'successful_attempt'
                        }
                    ]
                }
            ]
        }
        
        state = await self.controller.execute_workflow(workflow)
        print(f"Status: {state.status}")
        print(f"Successful on attempt: {state.variables.get('successful_attempt')}")
        
        # Reset counter and test continue_on_error
        attempt_count['count'] = 0
        
        def always_fails(**kwargs):
            raise Exception("This always fails")
        
        self.controller.register_tool('always_fails', always_fails)
        
        workflow2 = {
            'id': 'continue_demo',
            'steps': [
                {
                    'type': 'task',
                    'id': 'will_fail',
                    'tool': 'always_fails',
                    'continue_on_error': True
                },
                {
                    'type': 'task',
                    'id': 'will_succeed',
                    'tool': 'simple_processor',
                    'parameters': {'input': 'This runs despite previous failure'}
                }
            ]
        }
        
        state2 = await self.controller.execute_workflow(workflow2)
        print(f"\nContinue on error - Status: {state2.status}")
        print(f"Task results: {[f'{k}: {v.status.value}' for k, v in state2.task_results.items()]}")
    
    async def run_all_demos(self):
        """Run all demonstration scenarios"""
        await self.demo_simple_workflow()
        await self.demo_advanced_features()
        await self.demo_output_mapping()
        await self.demo_error_handling()
        
        print("\n=== Demo Complete ===")
        print("The orchestration system supports:")
        print("- Backward compatible simple workflows")
        print("- Complex output mapping with transformations")
        print("- Conditional branching and parallel execution")
        print("- Error handling and retry logic")
        print("- State persistence and workflow resumption")


# Integration with TES tools
class TESIntegration:
    """Shows how to integrate with TES batch tools"""
    
    @staticmethod
    def create_tes_workflow():
        """Create a workflow using TES tools"""
        return {
            'id': 'tes_integration_example',
            'name': 'TES Tool Integration',
            'steps': [
                # Use TodoWrite to create task list
                {
                    'type': 'task',
                    'id': 'create_todos',
                    'tool': 'TodoWrite',
                    'parameters': {
                        'todos': [
                            {
                                'id': 'design',
                                'content': 'Design system architecture',
                                'status': 'pending',
                                'priority': 'high'
                            },
                            {
                                'id': 'implement',
                                'content': 'Implement core features',
                                'status': 'pending',
                                'priority': 'medium'
                            }
                        ]
                    }
                },
                
                # Parallel task execution
                {
                    'type': 'parallel',
                    'tasks': [
                        {
                            'id': 'research_task',
                            'tool': 'Task',
                            'parameters': {
                                'agent_type': 'Researcher',
                                'description': 'Research best practices for system design'
                            }
                        },
                        {
                            'id': 'analysis_task',
                            'tool': 'Task',
                            'parameters': {
                                'agent_type': 'Analyst',
                                'description': 'Analyze existing codebase'
                            }
                        }
                    ]
                },
                
                # Store results in memory
                {
                    'type': 'task',
                    'id': 'store_results',
                    'tool': 'Memory',
                    'parameters': {
                        'action': 'store',
                        'key': 'research_findings',
                        'value': '$research_output'
                    }
                }
            ]
        }


if __name__ == '__main__':
    demo = OrchestrationDemo()
    
    # Run all demos
    asyncio.run(demo.run_all_demos())
    
    # Show TES integration example
    print("\n=== TES Integration Example ===")
    tes_workflow = TESIntegration.create_tes_workflow()
    print(yaml.dump(tes_workflow, default_flow_style=False))