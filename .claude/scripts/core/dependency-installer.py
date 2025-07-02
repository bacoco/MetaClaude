#!/usr/bin/env python3
"""
MetaClaude Script Dependency Installer
Handles automatic installation of dependencies for Python, Node, and system packages
"""

import json
import subprocess
import sys
import os
import tempfile
import shutil
import argparse
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Set
import venv
from dataclasses import dataclass
from enum import Enum
import hashlib
import pickle
from datetime import datetime, timedelta


class PackageManager(Enum):
    """Supported package managers"""
    PIP = "pip"
    NPM = "npm"
    APT = "apt"
    BREW = "brew"
    YUM = "yum"
    SYSTEM = "system"


@dataclass
class Dependency:
    """Represents a dependency to install"""
    name: str
    version_spec: str
    manager: PackageManager
    
    @property
    def cache_key(self):
        """Generate a cache key for this dependency"""
        return f"{self.manager.value}:{self.name}:{self.version_spec}"


@dataclass
class InstallResult:
    """Result of a dependency installation"""
    dependency: Dependency
    success: bool
    message: str
    rollback_command: Optional[str] = None


class DependencyCache:
    """Simple cache for installed dependencies"""
    
    def __init__(self, cache_dir: Optional[Path] = None):
        self.cache_dir = cache_dir or Path.home() / ".claude" / "cache" / "dependencies"
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        self.cache_file = self.cache_dir / "installed.pkl"
        self._load_cache()
    
    def _load_cache(self):
        """Load cache from disk"""
        if self.cache_file.exists():
            try:
                with open(self.cache_file, 'rb') as f:
                    self.cache = pickle.load(f)
            except Exception:
                self.cache = {}
        else:
            self.cache = {}
    
    def _save_cache(self):
        """Save cache to disk"""
        with open(self.cache_file, 'wb') as f:
            pickle.dump(self.cache, f)
    
    def is_installed(self, dep: Dependency) -> bool:
        """Check if a dependency is cached as installed"""
        if dep.cache_key not in self.cache:
            return False
        
        # Check if cache entry is still valid (24 hours)
        install_time = self.cache[dep.cache_key]['time']
        if datetime.now() - install_time > timedelta(hours=24):
            del self.cache[dep.cache_key]
            self._save_cache()
            return False
        
        return True
    
    def mark_installed(self, dep: Dependency):
        """Mark a dependency as installed"""
        self.cache[dep.cache_key] = {
            'time': datetime.now(),
            'dependency': dep
        }
        self._save_cache()
    
    def clear(self):
        """Clear the cache"""
        self.cache = {}
        self._save_cache()


class DependencyInstaller:
    """Handles dependency installation across different package managers"""
    
    def __init__(self, use_venv: bool = True, cache_enabled: bool = True):
        self.use_venv = use_venv
        self.cache = DependencyCache() if cache_enabled else None
        self.venv_dir = None
        self.rollback_log = []
        
        # Detect available package managers
        self.available_managers = self._detect_package_managers()
    
    def _detect_package_managers(self) -> Set[PackageManager]:
        """Detect which package managers are available"""
        available = set()
        
        # Check for Python/pip
        if shutil.which('python3') and shutil.which('pip3'):
            available.add(PackageManager.PIP)
        
        # Check for Node/npm
        if shutil.which('node') and shutil.which('npm'):
            available.add(PackageManager.NPM)
        
        # Check for system package managers
        if shutil.which('apt-get'):
            available.add(PackageManager.APT)
        elif shutil.which('brew'):
            available.add(PackageManager.BREW)
        elif shutil.which('yum'):
            available.add(PackageManager.YUM)
        
        return available
    
    def _guess_package_manager(self, dep_name: str) -> PackageManager:
        """Guess the package manager based on dependency name"""
        # Common Python packages
        python_packages = {'pandas', 'numpy', 'requests', 'flask', 'django', 'pytest',
                          'pyyaml', 'radon', 'lizard'}
        
        # Common Node packages
        node_packages = {'express', 'react', 'vue', 'faker', 'json-schema-faker',
                        'lodash', 'axios', 'webpack'}
        
        # Common system tools
        system_tools = {'git', 'jq', 'curl', 'wget', 'make', 'gcc', 'gh', 'ajv-cli'}
        
        dep_lower = dep_name.lower()
        
        if dep_lower in python_packages:
            return PackageManager.PIP
        elif dep_lower in node_packages:
            return PackageManager.NPM
        elif dep_lower in system_tools:
            # Return the available system package manager
            if PackageManager.BREW in self.available_managers:
                return PackageManager.BREW
            elif PackageManager.APT in self.available_managers:
                return PackageManager.APT
            elif PackageManager.YUM in self.available_managers:
                return PackageManager.YUM
        
        # Default fallback
        if dep_lower.endswith(('.py', '-py', '_py')):
            return PackageManager.PIP
        elif dep_lower.endswith(('.js', '-js', '_js', '-cli')):
            return PackageManager.NPM
        else:
            return PackageManager.SYSTEM
    
    def _create_venv(self) -> Path:
        """Create a virtual environment for Python dependencies"""
        self.venv_dir = Path(tempfile.mkdtemp(prefix='claude_venv_'))
        venv.create(self.venv_dir, with_pip=True)
        
        # Get paths for the venv
        if sys.platform == 'win32':
            self.venv_python = self.venv_dir / 'Scripts' / 'python.exe'
            self.venv_pip = self.venv_dir / 'Scripts' / 'pip.exe'
        else:
            self.venv_python = self.venv_dir / 'bin' / 'python'
            self.venv_pip = self.venv_dir / 'bin' / 'pip'
        
        return self.venv_dir
    
    def _parse_version_spec(self, spec: str) -> Tuple[str, str]:
        """Parse version specification into operator and version"""
        if spec == "*" or spec == "latest":
            return "", ""
        
        # Handle npm-style specs
        if spec.startswith("^"):
            return "^", spec[1:]
        elif spec.startswith("~"):
            return "~", spec[1:]
        elif spec.startswith(">="):
            return ">=", spec[2:]
        elif spec.startswith(">"):
            return ">", spec[1:]
        elif spec.startswith("<="):
            return "<=", spec[2:]
        elif spec.startswith("<"):
            return "<", spec[1:]
        elif spec.startswith("=="):
            return "==", spec[2:]
        else:
            # Assume exact version
            return "==", spec
    
    def _install_pip_dependency(self, dep: Dependency) -> InstallResult:
        """Install a Python package using pip"""
        try:
            pip_cmd = str(self.venv_pip) if self.use_venv and self.venv_dir else 'pip3'
            
            # Parse version spec
            op, version = self._parse_version_spec(dep.version_spec)
            
            if not version:
                package_spec = dep.name
            else:
                # Convert npm-style to pip-style
                if op == "^":
                    # Caret means compatible version (>= version, < next major)
                    package_spec = f"{dep.name}>={version}"
                elif op == "~":
                    # Tilde means approximately equivalent (>= version, < next minor)
                    package_spec = f"{dep.name}~={version}"
                else:
                    package_spec = f"{dep.name}{op}{version}"
            
            # Check if already installed
            check_cmd = [pip_cmd, 'show', dep.name]
            result = subprocess.run(check_cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                # Package already installed, check version
                for line in result.stdout.split('\n'):
                    if line.startswith('Version:'):
                        installed_version = line.split(':')[1].strip()
                        rollback_cmd = f"{pip_cmd} install {dep.name}=={installed_version}"
                        break
            else:
                rollback_cmd = f"{pip_cmd} uninstall -y {dep.name}"
            
            # Install the package
            install_cmd = [pip_cmd, 'install', package_spec]
            result = subprocess.run(install_cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                return InstallResult(
                    dependency=dep,
                    success=True,
                    message=f"Successfully installed {package_spec}",
                    rollback_command=rollback_cmd
                )
            else:
                return InstallResult(
                    dependency=dep,
                    success=False,
                    message=f"Failed to install {package_spec}: {result.stderr}"
                )
        
        except Exception as e:
            return InstallResult(
                dependency=dep,
                success=False,
                message=f"Error installing {dep.name}: {str(e)}"
            )
    
    def _install_npm_dependency(self, dep: Dependency) -> InstallResult:
        """Install a Node package using npm"""
        try:
            # Parse version spec
            if dep.version_spec == "*" or dep.version_spec == "latest":
                package_spec = dep.name
            else:
                package_spec = f"{dep.name}@{dep.version_spec}"
            
            # Check if globally installed
            check_cmd = ['npm', 'list', '-g', dep.name, '--depth=0']
            result = subprocess.run(check_cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                # Extract installed version for rollback
                rollback_cmd = None  # npm doesn't have easy rollback for globals
            else:
                rollback_cmd = f"npm uninstall -g {dep.name}"
            
            # Install globally
            install_cmd = ['npm', 'install', '-g', package_spec]
            result = subprocess.run(install_cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                return InstallResult(
                    dependency=dep,
                    success=True,
                    message=f"Successfully installed {package_spec}",
                    rollback_command=rollback_cmd
                )
            else:
                return InstallResult(
                    dependency=dep,
                    success=False,
                    message=f"Failed to install {package_spec}: {result.stderr}"
                )
        
        except Exception as e:
            return InstallResult(
                dependency=dep,
                success=False,
                message=f"Error installing {dep.name}: {str(e)}"
            )
    
    def _install_system_dependency(self, dep: Dependency, manager: PackageManager) -> InstallResult:
        """Install a system package"""
        try:
            if manager == PackageManager.BREW:
                # Check if installed
                check_cmd = ['brew', 'list', dep.name]
                result = subprocess.run(check_cmd, capture_output=True, text=True)
                
                if result.returncode == 0:
                    return InstallResult(
                        dependency=dep,
                        success=True,
                        message=f"{dep.name} already installed via Homebrew"
                    )
                
                # Install
                install_cmd = ['brew', 'install', dep.name]
                rollback_cmd = f"brew uninstall {dep.name}"
            
            elif manager == PackageManager.APT:
                # Update package list first
                subprocess.run(['sudo', 'apt-get', 'update'], capture_output=True)
                
                # Install
                install_cmd = ['sudo', 'apt-get', 'install', '-y', dep.name]
                rollback_cmd = f"sudo apt-get remove -y {dep.name}"
            
            elif manager == PackageManager.YUM:
                # Install
                install_cmd = ['sudo', 'yum', 'install', '-y', dep.name]
                rollback_cmd = f"sudo yum remove -y {dep.name}"
            
            else:
                return InstallResult(
                    dependency=dep,
                    success=False,
                    message=f"Unsupported system package manager: {manager}"
                )
            
            # Run installation
            result = subprocess.run(install_cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                return InstallResult(
                    dependency=dep,
                    success=True,
                    message=f"Successfully installed {dep.name} via {manager.value}",
                    rollback_command=rollback_cmd
                )
            else:
                return InstallResult(
                    dependency=dep,
                    success=False,
                    message=f"Failed to install {dep.name}: {result.stderr}"
                )
        
        except Exception as e:
            return InstallResult(
                dependency=dep,
                success=False,
                message=f"Error installing {dep.name}: {str(e)}"
            )
    
    def install_dependency(self, name: str, version_spec: str, manager: Optional[PackageManager] = None) -> InstallResult:
        """Install a single dependency"""
        # Determine package manager if not specified
        if not manager:
            manager = self._guess_package_manager(name)
        
        dep = Dependency(name, version_spec, manager)
        
        # Check cache
        if self.cache and self.cache.is_installed(dep):
            return InstallResult(
                dependency=dep,
                success=True,
                message=f"{name} already installed (cached)"
            )
        
        # Install based on manager
        if manager == PackageManager.PIP:
            result = self._install_pip_dependency(dep)
        elif manager == PackageManager.NPM:
            result = self._install_npm_dependency(dep)
        elif manager in {PackageManager.APT, PackageManager.BREW, PackageManager.YUM}:
            result = self._install_system_dependency(dep, manager)
        else:
            result = InstallResult(
                dependency=dep,
                success=False,
                message=f"Unknown package manager: {manager}"
            )
        
        # Update cache on success
        if result.success and self.cache:
            self.cache.mark_installed(dep)
        
        # Track for rollback
        if result.rollback_command:
            self.rollback_log.append(result.rollback_command)
        
        return result
    
    def install_from_registry(self, script_id: str, registry_path: Optional[str] = None) -> List[InstallResult]:
        """Install all dependencies for a script from the registry"""
        # Load registry
        if not registry_path:
            registry_path = Path(__file__).parent.parent / "registry.json"
        
        with open(registry_path, 'r') as f:
            registry = json.load(f)
        
        # Find script
        script = None
        for s in registry['scripts']:
            if s['id'] == script_id or s['id'].startswith(f"{script_id}@"):
                script = s
                break
        
        if not script:
            return [InstallResult(
                dependency=Dependency("unknown", "*", PackageManager.SYSTEM),
                success=False,
                message=f"Script {script_id} not found in registry"
            )]
        
        # Get dependencies
        dependencies = script.get('dependencies', {})
        if isinstance(dependencies, list):
            # Old format - convert to dict
            dependencies = {dep: "*" for dep in dependencies}
        
        results = []
        
        # Create venv if needed
        if self.use_venv and any(self._guess_package_manager(d) == PackageManager.PIP for d in dependencies):
            self._create_venv()
        
        # Install each dependency
        for dep_name, version_spec in dependencies.items():
            result = self.install_dependency(dep_name, version_spec)
            results.append(result)
            
            if not result.success:
                print(f"Warning: Failed to install {dep_name}: {result.message}")
        
        return results
    
    def rollback(self):
        """Rollback all installations from this session"""
        print("Rolling back installations...")
        
        for cmd in reversed(self.rollback_log):
            if cmd:
                print(f"Executing: {cmd}")
                subprocess.run(cmd.split(), capture_output=True)
        
        # Clean up venv if created
        if self.venv_dir and self.venv_dir.exists():
            shutil.rmtree(self.venv_dir)
        
        self.rollback_log.clear()
    
    def cleanup(self):
        """Clean up temporary resources"""
        if self.venv_dir and self.venv_dir.exists():
            shutil.rmtree(self.venv_dir)


def main():
    """CLI interface for dependency installer"""
    parser = argparse.ArgumentParser(description="MetaClaude Script Dependency Installer")
    parser.add_argument('script_id', help='Script ID to install dependencies for')
    parser.add_argument('--no-venv', action='store_true', help='Do not use virtual environment for Python packages')
    parser.add_argument('--no-cache', action='store_true', help='Do not use dependency cache')
    parser.add_argument('--rollback', action='store_true', help='Rollback installations on failure')
    parser.add_argument('--registry', help='Path to registry.json file')
    
    args = parser.parse_args()
    
    installer = DependencyInstaller(
        use_venv=not args.no_venv,
        cache_enabled=not args.no_cache
    )
    
    try:
        print(f"Installing dependencies for {args.script_id}...")
        results = installer.install_from_registry(args.script_id, args.registry)
        
        # Summary
        success_count = sum(1 for r in results if r.success)
        total_count = len(results)
        
        print(f"\nInstallation complete: {success_count}/{total_count} successful")
        
        # Show failures
        failures = [r for r in results if not r.success]
        if failures:
            print("\nFailed installations:")
            for result in failures:
                print(f"  - {result.dependency.name}: {result.message}")
            
            if args.rollback:
                installer.rollback()
                return 1
        
        return 0
    
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        if args.rollback:
            installer.rollback()
        return 1
    
    finally:
        installer.cleanup()


if __name__ == "__main__":
    sys.exit(main())