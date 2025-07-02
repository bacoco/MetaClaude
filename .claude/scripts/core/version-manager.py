#!/usr/bin/env python3
"""
MetaClaude Script Version Manager
Handles semantic versioning, dependency resolution, and version compatibility
"""

import json
import re
import sys
from typing import Dict, List, Tuple, Optional, Set
from dataclasses import dataclass, field
from pathlib import Path
import networkx as nx
from packaging import version, specifiers
import argparse


@dataclass
class ScriptVersion:
    """Represents a versioned script"""
    id: str
    base_id: str
    version: str
    dependencies: Dict[str, str] = field(default_factory=dict)
    script_dependencies: Dict[str, str] = field(default_factory=dict)
    changelog: Dict[str, str] = field(default_factory=dict)
    
    @property
    def full_id(self):
        return f"{self.base_id}@{self.version}"
    
    def satisfies(self, spec: str) -> bool:
        """Check if this version satisfies a version specification"""
        if spec == "latest" or spec == "*":
            return True
        
        try:
            # Handle npm-style version specs
            if spec.startswith("^"):
                # Caret: compatible version (>=X.Y.Z, <(X+1).0.0)
                base_version = spec[1:]
                v_base = version.parse(base_version)
                v_self = version.parse(self.version)
                return (v_self >= v_base and 
                        v_self < version.parse(f"{v_base.major + 1}.0.0"))
            elif spec.startswith("~"):
                # Tilde: approximately equivalent (>=X.Y.Z, <X.(Y+1).0)
                base_version = spec[1:]
                v_base = version.parse(base_version)
                v_self = version.parse(self.version)
                return (v_self >= v_base and 
                        v_self < version.parse(f"{v_base.major}.{v_base.minor + 1}.0"))
            else:
                # Try standard Python specifiers
                spec_obj = specifiers.SpecifierSet(spec)
                return version.parse(self.version) in spec_obj
        except Exception:
            # Exact version match fallback
            return self.version == spec


class VersionManager:
    """Manages script versions and dependencies"""
    
    def __init__(self, registry_path: str = None):
        self.registry_path = registry_path or self._find_registry()
        self.scripts: Dict[str, List[ScriptVersion]] = {}
        self.dependency_graph = nx.DiGraph()
        self._load_registry()
    
    def _find_registry(self) -> str:
        """Find the registry.json file"""
        current = Path(__file__).parent.parent
        registry = current / "registry.json"
        if registry.exists():
            return str(registry)
        raise FileNotFoundError("Could not find registry.json")
    
    def _load_registry(self):
        """Load and parse the registry"""
        with open(self.registry_path, 'r') as f:
            data = json.load(f)
        
        for script in data['scripts']:
            # Extract base ID and version
            script_id = script['id']
            if '@' in script_id:
                base_id, version_str = script_id.rsplit('@', 1)
            else:
                base_id = script_id
                version_str = script.get('version', '1.0.0')
            
            # Handle both old array format and new object format for dependencies
            deps = script.get('dependencies', {})
            if isinstance(deps, list):
                # Convert old format to new format with no version constraints
                deps = {dep: "*" for dep in deps}
            
            script_deps = script.get('scriptDependencies', {})
            changelog = script.get('changelog', {})
            
            sv = ScriptVersion(
                id=script_id,
                base_id=base_id,
                version=version_str,
                dependencies=deps,
                script_dependencies=script_deps,
                changelog=changelog
            )
            
            if base_id not in self.scripts:
                self.scripts[base_id] = []
            self.scripts[base_id].append(sv)
        
        # Sort versions for each script
        for versions in self.scripts.values():
            versions.sort(key=lambda x: version.parse(x.version), reverse=True)
    
    def resolve_version(self, script_spec: str) -> Optional[ScriptVersion]:
        """Resolve a script specification to a specific version"""
        if '@' in script_spec:
            # Specific version requested
            base_id, version_spec = script_spec.rsplit('@', 1)
        else:
            base_id = script_spec
            version_spec = "latest"
        
        if base_id not in self.scripts:
            return None
        
        versions = self.scripts[base_id]
        
        if version_spec == "latest":
            return versions[0]  # Already sorted, first is latest
        
        # Try to find a version that satisfies the spec
        for sv in versions:
            if sv.satisfies(version_spec):
                return sv
        
        return None
    
    def build_dependency_graph(self, root_script: str) -> nx.DiGraph:
        """Build a dependency graph starting from a root script"""
        graph = nx.DiGraph()
        visited = set()
        
        def add_dependencies(script_spec: str, parent: Optional[str] = None):
            if script_spec in visited:
                if parent and graph.has_edge(parent, script_spec):
                    # Circular dependency detected
                    raise ValueError(f"Circular dependency detected: {parent} -> {script_spec}")
                return
            
            visited.add(script_spec)
            sv = self.resolve_version(script_spec)
            
            if not sv:
                raise ValueError(f"Could not resolve script: {script_spec}")
            
            graph.add_node(sv.full_id, script=sv)
            
            if parent:
                graph.add_edge(parent, sv.full_id)
            
            # Add script dependencies
            for dep_id, dep_spec in sv.script_dependencies.items():
                # Don't add @ if the spec already contains version constraint symbols
                if dep_spec == "*" or dep_spec == "latest":
                    dep_full_spec = dep_id
                else:
                    dep_full_spec = f"{dep_id}@{dep_spec}"
                add_dependencies(dep_full_spec, sv.full_id)
        
        add_dependencies(root_script)
        return graph
    
    def detect_circular_dependencies(self, script_spec: str) -> List[List[str]]:
        """Detect circular dependencies in the dependency graph"""
        try:
            graph = self.build_dependency_graph(script_spec)
            cycles = list(nx.simple_cycles(graph))
            return cycles
        except ValueError as e:
            if "Circular dependency" in str(e):
                return [[script_spec]]  # Simple circular dependency
            raise
    
    def get_install_order(self, script_spec: str) -> List[ScriptVersion]:
        """Get the order in which scripts should be installed"""
        graph = self.build_dependency_graph(script_spec)
        
        # Topological sort gives us the correct installation order
        install_order = []
        for node in nx.topological_sort(graph):
            install_order.append(graph.nodes[node]['script'])
        
        return install_order
    
    def check_breaking_changes(self, old_version: str, new_version: str) -> Dict[str, List[str]]:
        """Check for breaking changes between versions"""
        old_v = version.parse(old_version)
        new_v = version.parse(new_version)
        
        breaking_changes = {
            'major': [],
            'minor': [],
            'patch': []
        }
        
        if new_v.major > old_v.major:
            breaking_changes['major'].append(
                f"Major version bump from {old_v.major} to {new_v.major} - expect breaking changes"
            )
        
        if new_v.minor > old_v.minor and new_v.major == old_v.major:
            breaking_changes['minor'].append(
                f"Minor version bump from {old_v.minor} to {new_v.minor} - new features added"
            )
        
        if new_v.micro > old_v.micro and new_v.major == old_v.major and new_v.minor == old_v.minor:
            breaking_changes['patch'].append(
                f"Patch version bump from {old_v.micro} to {new_v.micro} - bug fixes only"
            )
        
        return breaking_changes
    
    def generate_migration_guide(self, script_id: str, from_version: str, to_version: str) -> str:
        """Generate a migration guide between versions"""
        from_sv = self.resolve_version(f"{script_id}@{from_version}")
        to_sv = self.resolve_version(f"{script_id}@{to_version}")
        
        if not from_sv or not to_sv:
            return "Error: Could not find one or both versions"
        
        guide = f"# Migration Guide: {script_id}\n"
        guide += f"## From v{from_version} to v{to_version}\n\n"
        
        # Check for breaking changes
        breaking = self.check_breaking_changes(from_version, to_version)
        if breaking['major']:
            guide += "### ⚠️ Breaking Changes\n"
            for change in breaking['major']:
                guide += f"- {change}\n"
            guide += "\n"
        
        # Add changelog entries
        guide += "### Changes\n"
        from_v = version.parse(from_version)
        to_v = version.parse(to_version)
        
        for v_str, changes in sorted(to_sv.changelog.items(), key=lambda x: version.parse(x[0])):
            v = version.parse(v_str)
            if from_v < v <= to_v:
                guide += f"\n**v{v_str}:**\n{changes}\n"
        
        # Check dependency changes
        guide += "\n### Dependency Changes\n"
        
        # System dependencies
        old_deps = from_sv.dependencies
        new_deps = to_sv.dependencies
        
        added = set(new_deps.keys()) - set(old_deps.keys())
        removed = set(old_deps.keys()) - set(new_deps.keys())
        changed = {k for k in old_deps.keys() & new_deps.keys() if old_deps[k] != new_deps[k]}
        
        if added:
            guide += "\n**Added:**\n"
            for dep in added:
                guide += f"- {dep} {new_deps[dep]}\n"
        
        if removed:
            guide += "\n**Removed:**\n"
            for dep in removed:
                guide += f"- {dep}\n"
        
        if changed:
            guide += "\n**Updated:**\n"
            for dep in changed:
                guide += f"- {dep}: {old_deps[dep]} → {new_deps[dep]}\n"
        
        # Script dependencies
        old_script_deps = from_sv.script_dependencies
        new_script_deps = to_sv.script_dependencies
        
        script_added = set(new_script_deps.keys()) - set(old_script_deps.keys())
        script_removed = set(old_script_deps.keys()) - set(new_script_deps.keys())
        script_changed = {k for k in old_script_deps.keys() & new_script_deps.keys() 
                         if old_script_deps[k] != new_script_deps[k]}
        
        if script_added or script_removed or script_changed:
            guide += "\n**Script Dependencies:**\n"
            
            if script_added:
                for dep in script_added:
                    guide += f"- Added: {dep} {new_script_deps[dep]}\n"
            
            if script_removed:
                for dep in script_removed:
                    guide += f"- Removed: {dep}\n"
            
            if script_changed:
                for dep in script_changed:
                    guide += f"- Updated: {dep}: {old_script_deps[dep]} → {new_script_deps[dep]}\n"
        
        return guide
    
    def list_versions(self, script_id: str) -> List[str]:
        """List all available versions of a script"""
        if script_id not in self.scripts:
            return []
        
        return [sv.version for sv in self.scripts[script_id]]


def main():
    """CLI interface for version manager"""
    parser = argparse.ArgumentParser(description="MetaClaude Script Version Manager")
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # resolve command
    resolve_parser = subparsers.add_parser('resolve', help='Resolve a script version')
    resolve_parser.add_argument('script', help='Script specification (e.g., core/json-validator@^2.0.0)')
    
    # list command
    list_parser = subparsers.add_parser('list', help='List versions of a script')
    list_parser.add_argument('script', help='Script ID (e.g., core/json-validator)')
    
    # deps command
    deps_parser = subparsers.add_parser('deps', help='Show dependency tree')
    deps_parser.add_argument('script', help='Script specification')
    deps_parser.add_argument('--check-circular', action='store_true', help='Check for circular dependencies')
    
    # migrate command
    migrate_parser = subparsers.add_parser('migrate', help='Generate migration guide')
    migrate_parser.add_argument('script', help='Script ID')
    migrate_parser.add_argument('from_version', help='From version')
    migrate_parser.add_argument('to_version', help='To version')
    
    # install-order command
    order_parser = subparsers.add_parser('install-order', help='Get installation order')
    order_parser.add_argument('script', help='Script specification')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return 1
    
    vm = VersionManager()
    
    try:
        if args.command == 'resolve':
            result = vm.resolve_version(args.script)
            if result:
                print(f"Resolved: {result.full_id}")
                print(f"Path: scripts/{result.base_id.replace('/', '-')}-v{result.version}.sh")
            else:
                print("Could not resolve script version")
                return 1
        
        elif args.command == 'list':
            versions = vm.list_versions(args.script)
            if versions:
                print(f"Available versions for {args.script}:")
                for v in versions:
                    print(f"  - {v}")
            else:
                print(f"No versions found for {args.script}")
                return 1
        
        elif args.command == 'deps':
            if args.check_circular:
                cycles = vm.detect_circular_dependencies(args.script)
                if cycles:
                    print("Circular dependencies detected:")
                    for cycle in cycles:
                        print(f"  {' -> '.join(cycle)}")
                    return 1
                else:
                    print("No circular dependencies found")
            
            graph = vm.build_dependency_graph(args.script)
            print(f"Dependency tree for {args.script}:")
            
            # Print tree structure
            def print_tree(node, indent=0):
                print("  " * indent + f"- {node}")
                for child in graph.successors(node):
                    print_tree(child, indent + 1)
            
            root = vm.resolve_version(args.script)
            if root:
                print_tree(root.full_id)
        
        elif args.command == 'migrate':
            guide = vm.generate_migration_guide(args.script, args.from_version, args.to_version)
            print(guide)
        
        elif args.command == 'install-order':
            order = vm.get_install_order(args.script)
            print(f"Installation order for {args.script}:")
            for i, sv in enumerate(order, 1):
                deps_str = ", ".join(f"{k} {v}" for k, v in sv.dependencies.items())
                print(f"{i}. {sv.full_id} (deps: {deps_str or 'none'})")
    
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1
    
    return 0


if __name__ == "__main__":
    sys.exit(main())