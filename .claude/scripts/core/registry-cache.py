#!/usr/bin/env python3
"""
Registry Cache System for MetaClaude
In-memory LRU cache with file watching and optional Redis backend
Thread-safe implementation for high-performance script lookups
"""

import json
import os
import time
import threading
import hashlib
from pathlib import Path
from typing import Dict, Any, Optional, Tuple, List, Union
from collections import OrderedDict
from dataclasses import dataclass, field
import logging
from datetime import datetime, timedelta

# Optional dependencies
try:
    import redis
    REDIS_AVAILABLE = True
except ImportError:
    REDIS_AVAILABLE = False

try:
    from watchdog.observers import Observer
    from watchdog.events import FileSystemEventHandler, FileModifiedEvent
    WATCHDOG_AVAILABLE = True
except ImportError:
    WATCHDOG_AVAILABLE = False


@dataclass
class CacheEntry:
    """Single cache entry with metadata"""
    key: str
    value: Any
    size_bytes: int
    created_at: datetime
    accessed_at: datetime
    access_count: int = 0
    ttl_seconds: Optional[float] = None
    
    def is_expired(self) -> bool:
        """Check if entry has expired based on TTL"""
        if self.ttl_seconds is None:
            return False
        age = (datetime.now() - self.created_at).total_seconds()
        return age > self.ttl_seconds
    
    def touch(self):
        """Update access time and count"""
        self.accessed_at = datetime.now()
        self.access_count += 1


@dataclass
class CacheStats:
    """Cache performance statistics"""
    hits: int = 0
    misses: int = 0
    evictions: int = 0
    expirations: int = 0
    total_requests: int = 0
    total_size_bytes: int = 0
    entry_count: int = 0
    last_reset: datetime = field(default_factory=datetime.now)
    
    def hit_rate(self) -> float:
        """Calculate cache hit rate"""
        if self.total_requests == 0:
            return 0.0
        return self.hits / self.total_requests
    
    def reset(self):
        """Reset statistics"""
        self.hits = 0
        self.misses = 0
        self.evictions = 0
        self.expirations = 0
        self.total_requests = 0
        self.last_reset = datetime.now()


class RegistryFileWatcher(FileSystemEventHandler):
    """Watch registry file for changes"""
    
    def __init__(self, file_path: Path, callback):
        self.file_path = file_path
        self.callback = callback
        self.last_modified = None
        
    def on_modified(self, event):
        if not isinstance(event, FileModifiedEvent):
            return
            
        if Path(event.src_path).resolve() == self.file_path.resolve():
            # Debounce rapid modifications
            current_time = time.time()
            if self.last_modified and (current_time - self.last_modified) < 0.5:
                return
            
            self.last_modified = current_time
            self.callback()


class LRUCache:
    """Thread-safe LRU cache implementation"""
    
    def __init__(self, max_size: int = 100, max_memory_mb: float = 100):
        self.max_size = max_size
        self.max_memory_bytes = int(max_memory_mb * 1024 * 1024)
        self.cache: OrderedDict[str, CacheEntry] = OrderedDict()
        self.lock = threading.RLock()
        self.stats = CacheStats()
        
    def get(self, key: str) -> Optional[Any]:
        """Get value from cache"""
        with self.lock:
            self.stats.total_requests += 1
            
            if key not in self.cache:
                self.stats.misses += 1
                return None
            
            entry = self.cache[key]
            
            # Check expiration
            if entry.is_expired():
                self._remove_entry(key)
                self.stats.expirations += 1
                self.stats.misses += 1
                return None
            
            # Move to end (most recently used)
            self.cache.move_to_end(key)
            entry.touch()
            
            self.stats.hits += 1
            return entry.value
    
    def put(self, key: str, value: Any, ttl_seconds: Optional[float] = None):
        """Put value in cache"""
        with self.lock:
            # Calculate size
            size_bytes = self._estimate_size(value)
            
            # Remove existing entry if present
            if key in self.cache:
                self._remove_entry(key)
            
            # Check if we need to evict entries
            self._ensure_capacity(size_bytes)
            
            # Create and add new entry
            entry = CacheEntry(
                key=key,
                value=value,
                size_bytes=size_bytes,
                created_at=datetime.now(),
                accessed_at=datetime.now(),
                ttl_seconds=ttl_seconds
            )
            
            self.cache[key] = entry
            self.stats.total_size_bytes += size_bytes
            self.stats.entry_count = len(self.cache)
    
    def remove(self, key: str) -> bool:
        """Remove entry from cache"""
        with self.lock:
            if key in self.cache:
                self._remove_entry(key)
                return True
            return False
    
    def clear(self):
        """Clear all cache entries"""
        with self.lock:
            self.cache.clear()
            self.stats.total_size_bytes = 0
            self.stats.entry_count = 0
    
    def get_stats(self) -> Dict[str, Any]:
        """Get cache statistics"""
        with self.lock:
            return {
                'hits': self.stats.hits,
                'misses': self.stats.misses,
                'evictions': self.stats.evictions,
                'expirations': self.stats.expirations,
                'hit_rate': f"{self.stats.hit_rate():.2%}",
                'total_requests': self.stats.total_requests,
                'entry_count': self.stats.entry_count,
                'total_size_mb': self.stats.total_size_bytes / (1024 * 1024),
                'max_size': self.max_size,
                'max_memory_mb': self.max_memory_bytes / (1024 * 1024),
                'uptime_seconds': (datetime.now() - self.stats.last_reset).total_seconds()
            }
    
    def _remove_entry(self, key: str):
        """Remove entry and update stats"""
        if key in self.cache:
            entry = self.cache[key]
            self.stats.total_size_bytes -= entry.size_bytes
            del self.cache[key]
            self.stats.entry_count = len(self.cache)
    
    def _ensure_capacity(self, required_bytes: int):
        """Ensure cache has capacity for new entry"""
        # Evict by count
        while len(self.cache) >= self.max_size:
            self._evict_lru()
        
        # Evict by memory
        while (self.stats.total_size_bytes + required_bytes) > self.max_memory_bytes:
            if not self.cache:
                break
            self._evict_lru()
    
    def _evict_lru(self):
        """Evict least recently used entry"""
        if self.cache:
            key, entry = self.cache.popitem(last=False)
            self.stats.total_size_bytes -= entry.size_bytes
            self.stats.evictions += 1
            self.stats.entry_count = len(self.cache)
    
    def _estimate_size(self, obj: Any) -> int:
        """Estimate object size in bytes"""
        # Simple estimation - can be improved
        return len(json.dumps(obj, default=str).encode('utf-8'))


class RedisCache:
    """Redis-backed cache implementation"""
    
    def __init__(self, redis_url: str = "redis://localhost:6379", 
                 prefix: str = "metaclaude:registry:",
                 ttl_seconds: int = 3600):
        self.redis_client = redis.from_url(redis_url)
        self.prefix = prefix
        self.ttl_seconds = ttl_seconds
        self.stats = CacheStats()
        
    def get(self, key: str) -> Optional[Any]:
        """Get value from Redis"""
        self.stats.total_requests += 1
        
        try:
            full_key = f"{self.prefix}{key}"
            data = self.redis_client.get(full_key)
            
            if data is None:
                self.stats.misses += 1
                return None
            
            self.stats.hits += 1
            return json.loads(data)
            
        except Exception as e:
            logging.error(f"Redis get error: {e}")
            self.stats.misses += 1
            return None
    
    def put(self, key: str, value: Any, ttl_seconds: Optional[int] = None):
        """Put value in Redis"""
        try:
            full_key = f"{self.prefix}{key}"
            data = json.dumps(value, default=str)
            ttl = ttl_seconds or self.ttl_seconds
            
            self.redis_client.setex(full_key, ttl, data)
            
        except Exception as e:
            logging.error(f"Redis put error: {e}")
    
    def remove(self, key: str) -> bool:
        """Remove entry from Redis"""
        try:
            full_key = f"{self.prefix}{key}"
            return self.redis_client.delete(full_key) > 0
        except Exception as e:
            logging.error(f"Redis remove error: {e}")
            return False
    
    def clear(self):
        """Clear all cache entries"""
        try:
            pattern = f"{self.prefix}*"
            keys = self.redis_client.keys(pattern)
            if keys:
                self.redis_client.delete(*keys)
        except Exception as e:
            logging.error(f"Redis clear error: {e}")
    
    def get_stats(self) -> Dict[str, Any]:
        """Get cache statistics"""
        try:
            info = self.redis_client.info('memory')
            keys_count = self.redis_client.dbsize()
            
            return {
                'hits': self.stats.hits,
                'misses': self.stats.misses,
                'hit_rate': f"{self.stats.hit_rate():.2%}",
                'total_requests': self.stats.total_requests,
                'redis_memory_mb': info.get('used_memory', 0) / (1024 * 1024),
                'redis_keys': keys_count,
                'connected': True
            }
        except Exception as e:
            logging.error(f"Redis stats error: {e}")
            return {'connected': False, 'error': str(e)}


class RegistryCache:
    """Main registry cache with file watching and multi-backend support"""
    
    def __init__(self, 
                 registry_path: Union[str, Path],
                 cache_size: int = 100,
                 cache_memory_mb: float = 100,
                 redis_url: Optional[str] = None,
                 enable_watching: bool = True,
                 ttl_seconds: Optional[float] = None):
        
        self.registry_path = Path(registry_path)
        self.ttl_seconds = ttl_seconds
        self.enable_watching = enable_watching and WATCHDOG_AVAILABLE
        
        # Initialize caches
        self.lru_cache = LRUCache(cache_size, cache_memory_mb)
        self.redis_cache = None
        
        if redis_url and REDIS_AVAILABLE:
            try:
                self.redis_cache = RedisCache(redis_url)
                logging.info("Redis cache initialized")
            except Exception as e:
                logging.warning(f"Failed to initialize Redis cache: {e}")
        
        # File watching
        self.observer = None
        self.file_hash = None
        self._registry_data = None
        self._registry_lock = threading.RLock()
        
        # Load initial data
        self._load_registry()
        
        # Start file watcher
        if self.enable_watching:
            self._start_watcher()
    
    def get_script(self, script_id: str) -> Optional[Dict[str, Any]]:
        """Get script by ID with caching"""
        cache_key = f"script:{script_id}"
        
        # Try LRU cache first
        script = self.lru_cache.get(cache_key)
        if script is not None:
            return script
        
        # Try Redis cache
        if self.redis_cache:
            script = self.redis_cache.get(cache_key)
            if script is not None:
                # Populate LRU cache
                self.lru_cache.put(cache_key, script, self.ttl_seconds)
                return script
        
        # Load from registry
        with self._registry_lock:
            if self._registry_data:
                for script in self._registry_data.get('scripts', []):
                    if script.get('id') == script_id:
                        # Cache the result
                        self.lru_cache.put(cache_key, script, self.ttl_seconds)
                        if self.redis_cache:
                            self.redis_cache.put(cache_key, script)
                        return script
        
        return None
    
    def get_scripts_by_specialist(self, specialist: str) -> List[Dict[str, Any]]:
        """Get all scripts for a specialist"""
        cache_key = f"specialist:{specialist}"
        
        # Try LRU cache
        scripts = self.lru_cache.get(cache_key)
        if scripts is not None:
            return scripts
        
        # Try Redis cache
        if self.redis_cache:
            scripts = self.redis_cache.get(cache_key)
            if scripts is not None:
                self.lru_cache.put(cache_key, scripts, self.ttl_seconds)
                return scripts
        
        # Load from registry
        with self._registry_lock:
            if self._registry_data:
                scripts = [
                    script for script in self._registry_data.get('scripts', [])
                    if script.get('specialist') == specialist
                ]
                
                # Cache the result
                self.lru_cache.put(cache_key, scripts, self.ttl_seconds)
                if self.redis_cache:
                    self.redis_cache.put(cache_key, scripts)
                
                return scripts
        
        return []
    
    def get_all_scripts(self) -> List[Dict[str, Any]]:
        """Get all scripts"""
        cache_key = "all_scripts"
        
        # Try LRU cache
        scripts = self.lru_cache.get(cache_key)
        if scripts is not None:
            return scripts
        
        # Load from registry
        with self._registry_lock:
            if self._registry_data:
                scripts = self._registry_data.get('scripts', [])
                self.lru_cache.put(cache_key, scripts, self.ttl_seconds)
                return scripts
        
        return []
    
    def invalidate(self):
        """Invalidate all caches"""
        logging.info("Invalidating all caches")
        self.lru_cache.clear()
        if self.redis_cache:
            self.redis_cache.clear()
        self._load_registry()
    
    def get_stats(self) -> Dict[str, Any]:
        """Get combined cache statistics"""
        stats = {
            'lru_cache': self.lru_cache.get_stats(),
            'registry_path': str(self.registry_path),
            'file_watching': self.enable_watching,
            'last_modified': self._get_file_modified_time()
        }
        
        if self.redis_cache:
            stats['redis_cache'] = self.redis_cache.get_stats()
        
        return stats
    
    def close(self):
        """Clean up resources"""
        if self.observer and self.observer.is_alive():
            self.observer.stop()
            self.observer.join()
    
    def _load_registry(self):
        """Load registry file"""
        try:
            if not self.registry_path.exists():
                logging.error(f"Registry file not found: {self.registry_path}")
                return
            
            # Check file hash to avoid unnecessary reloads
            new_hash = self._calculate_file_hash()
            if new_hash == self.file_hash:
                return
            
            with open(self.registry_path, 'r') as f:
                data = json.load(f)
            
            with self._registry_lock:
                self._registry_data = data
                self.file_hash = new_hash
            
            # Invalidate caches on reload
            self.invalidate()
            
            logging.info(f"Registry loaded: {len(data.get('scripts', []))} scripts")
            
        except Exception as e:
            logging.error(f"Failed to load registry: {e}")
    
    def _calculate_file_hash(self) -> str:
        """Calculate file hash for change detection"""
        try:
            with open(self.registry_path, 'rb') as f:
                return hashlib.md5(f.read()).hexdigest()
        except Exception:
            return ""
    
    def _get_file_modified_time(self) -> Optional[str]:
        """Get file modification time"""
        try:
            mtime = os.path.getmtime(self.registry_path)
            return datetime.fromtimestamp(mtime).isoformat()
        except Exception:
            return None
    
    def _start_watcher(self):
        """Start file system watcher"""
        if not WATCHDOG_AVAILABLE:
            logging.warning("watchdog not available, file watching disabled")
            return
        
        try:
            event_handler = RegistryFileWatcher(
                self.registry_path,
                self._on_file_changed
            )
            
            self.observer = Observer()
            self.observer.schedule(
                event_handler,
                str(self.registry_path.parent),
                recursive=False
            )
            
            self.observer.start()
            logging.info("File watcher started")
            
        except Exception as e:
            logging.error(f"Failed to start file watcher: {e}")
    
    def _on_file_changed(self):
        """Handle file change event"""
        logging.info("Registry file changed, reloading...")
        self._load_registry()


# Convenience functions for global cache instance
_global_cache: Optional[RegistryCache] = None


def init_cache(registry_path: Union[str, Path], **kwargs) -> RegistryCache:
    """Initialize global cache instance"""
    global _global_cache
    _global_cache = RegistryCache(registry_path, **kwargs)
    return _global_cache


def get_cache() -> Optional[RegistryCache]:
    """Get global cache instance"""
    return _global_cache


def close_cache():
    """Close global cache instance"""
    global _global_cache
    if _global_cache:
        _global_cache.close()
        _global_cache = None


if __name__ == "__main__":
    # Example usage and testing
    import argparse
    
    parser = argparse.ArgumentParser(description="Registry Cache Testing")
    parser.add_argument("--registry", required=True, help="Path to registry.json")
    parser.add_argument("--redis", help="Redis URL")
    parser.add_argument("--test", action="store_true", help="Run tests")
    
    args = parser.parse_args()
    
    # Configure logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    # Initialize cache
    cache = init_cache(
        args.registry,
        redis_url=args.redis,
        cache_size=100,
        cache_memory_mb=50
    )
    
    if args.test:
        print("Running cache tests...")
        
        # Test script lookup
        print("\n1. Testing script lookup:")
        test_id = "data-yaml-to-json"
        script = cache.get_script(test_id)
        if script:
            print(f"   Found: {script.get('name')}")
        else:
            print(f"   Not found: {test_id}")
        
        # Test specialist lookup
        print("\n2. Testing specialist lookup:")
        specialist = "data-processor"
        scripts = cache.get_scripts_by_specialist(specialist)
        print(f"   Found {len(scripts)} scripts for {specialist}")
        
        # Test cache performance
        print("\n3. Testing cache performance:")
        import timeit
        
        def test_cached():
            cache.get_script(test_id)
        
        # Warm up cache
        cache.get_script(test_id)
        
        # Time cached access
        time_taken = timeit.timeit(test_cached, number=10000)
        print(f"   10,000 cached lookups: {time_taken:.3f}s")
        print(f"   Average: {time_taken/10000*1000:.3f}ms per lookup")
        
        # Show stats
        print("\n4. Cache statistics:")
        stats = cache.get_stats()
        print(json.dumps(stats, indent=2))
    
    # Keep running for file watching
    try:
        print("\nCache initialized. Press Ctrl+C to exit...")
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\nShutting down...")
    finally:
        close_cache()