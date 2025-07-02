#!/usr/bin/env python3
"""
Advanced Workflow Controller for TES Orchestration
Manages complex workflows with conditional branching, parallel execution, and state management
"""

import asyncio
import json
import time
import uuid
from typing import Any, Dict, List, Optional, Union, Callable, Set
from dataclasses import dataclass, field
from enum import Enum
from concurrent.futures import ThreadPoolExecutor, as_completed
import yaml
import logging
from datetime import datetime
import pickle
import os
from pathlib import Path

from output_mapper import OutputMapper


class ExecutionMode(Enum):
    """Workflow execution modes"""
    SEQUENTIAL = "sequential"
    PARALLEL = "parallel"
    CONDITIONAL = "conditional"
    LOOP = "loop"
    RETRY = "retry"


class TaskStatus(Enum):
    """Task execution status"""
    PENDING = "pending"
    RUNNING = "running"
    SUCCESS = "success"
    FAILED = "failed"
    SKIPPED = "skipped"
    RETRYING = "retrying"


@dataclass
class TaskResult:
    """Result of task execution"""
    task_id: str
    status: TaskStatus
    output: Any
    error: Optional[str] = None
    duration: float = 0.0
    attempts: int = 1
    timestamp: datetime = field(default_factory=datetime.now)


@dataclass
class WorkflowState:
    """Maintains workflow execution state"""
    workflow_id: str
    variables: Dict[str, Any] = field(default_factory=dict)
    task_results: Dict[str, TaskResult] = field(default_factory=dict)
    execution_path: List[str] = field(default_factory=list)
    start_time: datetime = field(default_factory=datetime.now)
    end_time: Optional[datetime] = None
    status: str = "running"


class ConditionEvaluator:
    """Evaluates workflow conditions"""
    
    @staticmethod
    def evaluate(condition: Union[str, Dict], variables: Dict[str, Any]) -> bool:
        """Evaluate a condition against variables"""
        if isinstance(condition, str):
            # Simple expression evaluation
            try:
                # Create safe evaluation context
                safe_vars = {
                    'variables': variables,
                    'true': True,
                    'false': False,
                    'null': None,
                    'len': len,
                    'str': str,
                    'int': int,
                    'float': float,
                    'bool': bool
                }
                return bool(eval(condition, {"__builtins__": {}}, safe_vars))
            except Exception as e:
                logging.error(f"Error evaluating condition '{condition}': {e}")
                return False
        
        elif isinstance(condition, dict):
            # Complex condition with operators
            if 'and' in condition:
                return all(ConditionEvaluator.evaluate(c, variables) for c in condition['and'])
            elif 'or' in condition:
                return any(ConditionEvaluator.evaluate(c, variables) for c in condition['or'])
            elif 'not' in condition:
                return not ConditionEvaluator.evaluate(condition['not'], variables)
            elif 'equals' in condition:
                left = ConditionEvaluator._resolve_value(condition['equals'][0], variables)
                right = ConditionEvaluator._resolve_value(condition['equals'][1], variables)
                return left == right
            elif 'greater' in condition:
                left = ConditionEvaluator._resolve_value(condition['greater'][0], variables)
                right = ConditionEvaluator._resolve_value(condition['greater'][1], variables)
                return left > right
            elif 'less' in condition:
                left = ConditionEvaluator._resolve_value(condition['less'][0], variables)
                right = ConditionEvaluator._resolve_value(condition['less'][1], variables)
                return left < right
            elif 'in' in condition:
                value = ConditionEvaluator._resolve_value(condition['in'][0], variables)
                collection = ConditionEvaluator._resolve_value(condition['in'][1], variables)
                return value in collection
            elif 'exists' in condition:
                var_path = condition['exists']
                return ConditionEvaluator._variable_exists(var_path, variables)
        
        return False
    
    @staticmethod
    def _resolve_value(value: Any, variables: Dict[str, Any]) -> Any:
        """Resolve a value that might be a variable reference"""
        if isinstance(value, str) and value.startswith('$'):
            var_name = value[1:]
            return variables.get(var_name, None)
        return value
    
    @staticmethod
    def _variable_exists(path: str, variables: Dict[str, Any]) -> bool:
        """Check if a variable path exists"""
        parts = path.split('.')
        current = variables
        for part in parts:
            if isinstance(current, dict) and part in current:
                current = current[part]
            else:
                return False
        return True


class WorkflowController:
    """Controls workflow execution with advanced features"""
    
    def __init__(self, max_parallel_tasks: int = 10, state_dir: str = ".workflow_state"):
        self.max_parallel_tasks = max_parallel_tasks
        self.state_dir = Path(state_dir)
        self.state_dir.mkdir(exist_ok=True)
        self.output_mapper = OutputMapper()
        self.executor = ThreadPoolExecutor(max_workers=max_parallel_tasks)
        self.condition_evaluator = ConditionEvaluator()
        self.tool_registry: Dict[str, Callable] = {}
        
        # Setup logging
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)
    
    def register_tool(self, name: str, handler: Callable):
        """Register a tool handler"""
        self.tool_registry[name] = handler
    
    async def execute_workflow(self, workflow: Dict[str, Any], initial_variables: Dict[str, Any] = None) -> WorkflowState:
        """Execute a complete workflow"""
        workflow_id = workflow.get('id', str(uuid.uuid4()))
        state = WorkflowState(
            workflow_id=workflow_id,
            variables=initial_variables or {}
        )
        
        try:
            # Load saved state if resuming
            if workflow.get('resume', False):
                state = self._load_state(workflow_id) or state
            
            # Execute workflow steps
            steps = workflow.get('steps', [])
            await self._execute_steps(steps, state)
            
            state.status = "completed"
            state.end_time = datetime.now()
            
        except Exception as e:
            self.logger.error(f"Workflow failed: {e}")
            state.status = "failed"
            state.end_time = datetime.now()
            raise
        
        finally:
            # Save final state
            self._save_state(state)
        
        return state
    
    async def _execute_steps(self, steps: List[Dict[str, Any]], state: WorkflowState):
        """Execute a list of workflow steps"""
        for step in steps:
            step_type = step.get('type', 'task')
            
            if step_type == 'task':
                await self._execute_task(step, state)
            elif step_type == 'parallel':
                await self._execute_parallel(step, state)
            elif step_type == 'conditional':
                await self._execute_conditional(step, state)
            elif step_type == 'loop':
                await self._execute_loop(step, state)
            elif step_type == 'compose':
                await self._execute_compose(step, state)
    
    async def _execute_task(self, task: Dict[str, Any], state: WorkflowState):
        """Execute a single task"""
        task_id = task.get('id', str(uuid.uuid4()))
        tool_name = task['tool']
        
        # Check dependencies
        dependencies = task.get('depends_on', [])
        if not self._check_dependencies(dependencies, state):
            result = TaskResult(
                task_id=task_id,
                status=TaskStatus.SKIPPED,
                output=None,
                error="Dependencies not met"
            )
            state.task_results[task_id] = result
            return
        
        # Prepare parameters with variable substitution
        params = self._resolve_parameters(task.get('parameters', {}), state.variables)
        
        # Retry logic
        max_attempts = task.get('retry', {}).get('max_attempts', 1)
        retry_delay = task.get('retry', {}).get('delay', 1)
        
        for attempt in range(max_attempts):
            try:
                start_time = time.time()
                
                # Execute tool
                if tool_name in self.tool_registry:
                    output = await self._execute_tool(tool_name, params)
                else:
                    raise ValueError(f"Unknown tool: {tool_name}")
                
                duration = time.time() - start_time
                
                # Process output mapping
                if 'output_mapping' in task:
                    mapped_vars = self.output_mapper.map_output(output, task['output_mapping'])
                    state.variables.update(mapped_vars)
                
                # Success
                result = TaskResult(
                    task_id=task_id,
                    status=TaskStatus.SUCCESS,
                    output=output,
                    duration=duration,
                    attempts=attempt + 1
                )
                state.task_results[task_id] = result
                state.execution_path.append(f"{task_id}:success")
                break
                
            except Exception as e:
                if attempt < max_attempts - 1:
                    self.logger.warning(f"Task {task_id} failed (attempt {attempt + 1}), retrying...")
                    await asyncio.sleep(retry_delay)
                else:
                    # Final failure
                    result = TaskResult(
                        task_id=task_id,
                        status=TaskStatus.FAILED,
                        output=None,
                        error=str(e),
                        attempts=attempt + 1
                    )
                    state.task_results[task_id] = result
                    state.execution_path.append(f"{task_id}:failed")
                    
                    if task.get('continue_on_error', False):
                        self.logger.error(f"Task {task_id} failed but continuing: {e}")
                    else:
                        raise
    
    async def _execute_parallel(self, parallel_block: Dict[str, Any], state: WorkflowState):
        """Execute tasks in parallel"""
        tasks = parallel_block.get('tasks', [])
        
        # Create async tasks
        async_tasks = []
        for task in tasks:
            async_tasks.append(self._execute_task(task, state))
        
        # Wait for all tasks to complete
        await asyncio.gather(*async_tasks, return_exceptions=True)
    
    async def _execute_conditional(self, conditional: Dict[str, Any], state: WorkflowState):
        """Execute conditional branching"""
        condition = conditional['condition']
        
        if self.condition_evaluator.evaluate(condition, state.variables):
            # Execute 'then' branch
            if 'then' in conditional:
                await self._execute_steps(conditional['then'], state)
        else:
            # Execute 'else' branch
            if 'else' in conditional:
                await self._execute_steps(conditional['else'], state)
    
    async def _execute_loop(self, loop: Dict[str, Any], state: WorkflowState):
        """Execute loop construct"""
        loop_type = loop.get('loop_type', 'for')
        
        if loop_type == 'for':
            # For loop over collection
            collection_ref = loop['collection']
            collection = self._resolve_value(collection_ref, state.variables)
            var_name = loop.get('variable', 'item')
            
            for item in collection:
                # Set loop variable
                state.variables[var_name] = item
                
                # Execute loop body
                await self._execute_steps(loop['body'], state)
                
        elif loop_type == 'while':
            # While loop with condition
            while self.condition_evaluator.evaluate(loop['condition'], state.variables):
                await self._execute_steps(loop['body'], state)
                
                # Prevent infinite loops
                if 'max_iterations' in loop:
                    loop['_iterations'] = loop.get('_iterations', 0) + 1
                    if loop['_iterations'] >= loop['max_iterations']:
                        self.logger.warning("Max iterations reached, breaking loop")
                        break
    
    async def _execute_compose(self, compose: Dict[str, Any], state: WorkflowState):
        """Execute tool composition (pipe outputs)"""
        tasks = compose['tasks']
        previous_output = None
        
        for i, task in enumerate(tasks):
            # Use previous output as input if piping
            if i > 0 and previous_output is not None:
                if 'parameters' not in task:
                    task['parameters'] = {}
                task['parameters']['_piped_input'] = previous_output
            
            # Execute task
            await self._execute_task(task, state)
            
            # Get output for next task
            task_id = task.get('id', str(uuid.uuid4()))
            if task_id in state.task_results:
                previous_output = state.task_results[task_id].output
    
    async def _execute_tool(self, tool_name: str, params: Dict[str, Any]) -> Any:
        """Execute a tool with given parameters"""
        handler = self.tool_registry[tool_name]
        
        # Check if handler is async
        if asyncio.iscoroutinefunction(handler):
            return await handler(**params)
        else:
            # Run sync function in executor
            loop = asyncio.get_event_loop()
            return await loop.run_in_executor(self.executor, handler, params)
    
    def _check_dependencies(self, dependencies: List[str], state: WorkflowState) -> bool:
        """Check if all dependencies are satisfied"""
        for dep in dependencies:
            if dep not in state.task_results:
                return False
            if state.task_results[dep].status != TaskStatus.SUCCESS:
                return False
        return True
    
    def _resolve_parameters(self, params: Dict[str, Any], variables: Dict[str, Any]) -> Dict[str, Any]:
        """Resolve parameter values with variable substitution"""
        resolved = {}
        
        for key, value in params.items():
            resolved[key] = self._resolve_value(value, variables)
        
        return resolved
    
    def _resolve_value(self, value: Any, variables: Dict[str, Any]) -> Any:
        """Resolve a value that might contain variable references"""
        if isinstance(value, str):
            # Variable reference
            if value.startswith('$'):
                var_name = value[1:]
                return variables.get(var_name, value)
            
            # Template string with variables
            import re
            pattern = r'\$\{([^}]+)\}'
            
            def replacer(match):
                var_name = match.group(1)
                return str(variables.get(var_name, match.group(0)))
            
            return re.sub(pattern, replacer, value)
        
        elif isinstance(value, dict):
            # Recursively resolve dictionary values
            return {k: self._resolve_value(v, variables) for k, v in value.items()}
        
        elif isinstance(value, list):
            # Recursively resolve list items
            return [self._resolve_value(item, variables) for item in value]
        
        return value
    
    def _save_state(self, state: WorkflowState):
        """Save workflow state to disk"""
        state_file = self.state_dir / f"{state.workflow_id}.pkl"
        with open(state_file, 'wb') as f:
            pickle.dump(state, f)
    
    def _load_state(self, workflow_id: str) -> Optional[WorkflowState]:
        """Load workflow state from disk"""
        state_file = self.state_dir / f"{workflow_id}.pkl"
        if state_file.exists():
            with open(state_file, 'rb') as f:
                return pickle.load(f)
        return None
    
    def get_workflow_status(self, workflow_id: str) -> Optional[Dict[str, Any]]:
        """Get current status of a workflow"""
        state = self._load_state(workflow_id)
        if state:
            return {
                'workflow_id': state.workflow_id,
                'status': state.status,
                'variables': state.variables,
                'execution_path': state.execution_path,
                'task_count': len(state.task_results),
                'successful_tasks': sum(1 for r in state.task_results.values() if r.status == TaskStatus.SUCCESS),
                'failed_tasks': sum(1 for r in state.task_results.values() if r.status == TaskStatus.FAILED),
                'duration': (state.end_time - state.start_time).total_seconds() if state.end_time else None
            }
        return None


# Example usage
if __name__ == '__main__':
    import asyncio
    
    # Example workflow definition
    workflow = {
        'id': 'example_workflow',
        'name': 'Advanced Orchestration Example',
        'steps': [
            {
                'type': 'task',
                'id': 'fetch_data',
                'tool': 'http_get',
                'parameters': {
                    'url': 'https://api.example.com/data'
                },
                'output_mapping': [
                    {
                        'source': '$.data.items',
                        'target': 'items',
                        'transform': 'array'
                    }
                ]
            },
            {
                'type': 'conditional',
                'condition': 'len(variables["items"]) > 0',
                'then': [
                    {
                        'type': 'parallel',
                        'tasks': [
                            {
                                'id': 'process_item_1',
                                'tool': 'process',
                                'parameters': {'item': '$items[0]'}
                            },
                            {
                                'id': 'process_item_2', 
                                'tool': 'process',
                                'parameters': {'item': '$items[1]'}
                            }
                        ]
                    }
                ],
                'else': [
                    {
                        'type': 'task',
                        'id': 'handle_empty',
                        'tool': 'log',
                        'parameters': {'message': 'No items to process'}
                    }
                ]
            }
        ]
    }
    
    # Create controller and run workflow
    controller = WorkflowController()
    
    # Register dummy tools for example
    controller.register_tool('http_get', lambda url: {'data': {'items': ['item1', 'item2', 'item3']}})
    controller.register_tool('process', lambda item: {'processed': item.upper()})
    controller.register_tool('log', lambda message: print(message))
    
    # Run workflow
    async def run():
        state = await controller.execute_workflow(workflow)
        print(f"Workflow completed: {state.status}")
        print(f"Final variables: {state.variables}")
    
    asyncio.run(run())