# Navigation Architect Agent

## Purpose
Designs intelligent, hierarchical navigation structures for admin panels by analyzing database schemas, relationships, and user roles to create intuitive menu systems, breadcrumbs, and contextual navigation patterns.

## Capabilities

### Navigation Types
- Multi-level sidebar menus
- Horizontal navigation bars
- Breadcrumb trails
- Contextual sub-navigation
- Mobile-responsive navigation
- Tab-based navigation
- Command palettes
- Quick access shortcuts
- Role-based menu filtering
- Dynamic navigation based on data

### Schema Analysis for Navigation
- Entity grouping by relationships
- Logical menu categorization
- CRUD operation mapping
- Parent-child hierarchies
- Many-to-many relationship handling
- Permission-based visibility
- Frequency-based prioritization
- Related entity navigation

## Navigation Generation Strategy

### Database-Driven Menu Structure
```typescript
interface NavigationBuilder {
  analyzeSchema(schema: DatabaseSchema): NavigationStructure {
    const entities = this.extractEntities(schema);
    const relationships = this.analyzeRelationships(schema);
    const modules = this.groupIntoModules(entities, relationships);
    
    return {
      primary: this.buildPrimaryNavigation(modules),
      secondary: this.buildSecondaryNavigation(modules),
      contextual: this.buildContextualNavigation(relationships),
      breadcrumbs: this.generateBreadcrumbRules(modules),
      quickAccess: this.identifyQuickAccessItems(entities)
    };
  }
  
  groupIntoModules(entities: Entity[], relationships: Relationship[]): Module[] {
    const modules: Module[] = [];
    
    // Core entities (no foreign keys or primary entities)
    const coreEntities = entities.filter(e => 
      e.foreignKeys.length === 0 || 
      this.isPrimaryEntity(e, relationships)
    );
    
    // Group related entities
    coreEntities.forEach(core => {
      const module: Module = {
        name: this.generateModuleName(core),
        icon: this.selectModuleIcon(core),
        priority: this.calculatePriority(core),
        items: [
          {
            label: this.pluralize(core.name),
            path: `/${this.toKebabCase(core.name)}`,
            icon: this.selectEntityIcon(core),
            entity: core.name,
            operations: this.getAvailableOperations(core),
            badge: this.generateBadgeQuery(core)
          }
        ]
      };
      
      // Add related entities
      const related = this.findRelatedEntities(core, relationships);
      related.forEach(rel => {
        module.items.push({
          label: this.pluralize(rel.name),
          path: `/${this.toKebabCase(core.name)}/${this.toKebabCase(rel.name)}`,
          icon: this.selectEntityIcon(rel),
          entity: rel.name,
          operations: this.getAvailableOperations(rel),
          parent: core.name
        });
      });
      
      modules.push(module);
    });
    
    // System modules
    modules.push(
      this.createSystemModule(),
      this.createSettingsModule(),
      this.createReportsModule()
    );
    
    return this.sortModulesByPriority(modules);
  }
}
```

### React Navigation Implementation
```tsx
import React, { useState, useEffect, useMemo } from 'react';
import { useRouter } from 'next/router';
import { useAuth } from '@/hooks/useAuth';
import {
  Home,
  Users,
  Settings,
  Database,
  FileText,
  BarChart,
  Shield,
  Package,
  ShoppingCart,
  Calendar,
  Mail,
  Bell,
  Search,
  ChevronDown,
  ChevronRight,
  Menu,
  X
} from 'lucide-react';

interface NavigationItem {
  id: string;
  label: string;
  path?: string;
  icon?: React.ComponentType<any>;
  children?: NavigationItem[];
  badge?: number | string;
  permissions?: string[];
  divider?: boolean;
}

export const AdminSidebar: React.FC<{ navigation: NavigationItem[] }> = ({ 
  navigation 
}) => {
  const router = useRouter();
  const { user, hasPermission } = useAuth();
  const [expanded, setExpanded] = useState<Record<string, boolean>>({});
  const [mobileOpen, setMobileOpen] = useState(false);
  
  // Filter navigation based on permissions
  const filteredNavigation = useMemo(() => {
    return filterNavigationByPermissions(navigation, hasPermission);
  }, [navigation, user]);
  
  // Auto-expand active sections
  useEffect(() => {
    const path = router.pathname;
    const expandedSections: Record<string, boolean> = {};
    
    filteredNavigation.forEach(item => {
      if (item.children) {
        const hasActiveChild = item.children.some(child => 
          path.startsWith(child.path || '')
        );
        if (hasActiveChild) {
          expandedSections[item.id] = true;
        }
      }
    });
    
    setExpanded(expandedSections);
  }, [router.pathname, filteredNavigation]);
  
  const toggleExpanded = (itemId: string) => {
    setExpanded(prev => ({
      ...prev,
      [itemId]: !prev[itemId]
    }));
  };
  
  const isActive = (path?: string): boolean => {
    if (!path) return false;
    return router.pathname === path || router.pathname.startsWith(path + '/');
  };
  
  const renderNavItem = (item: NavigationItem, depth = 0) => {
    const hasChildren = item.children && item.children.length > 0;
    const isExpanded = expanded[item.id];
    const active = isActive(item.path);
    
    if (item.divider) {
      return <div key={item.id} className="my-2 border-t border-gray-200" />;
    }
    
    return (
      <li key={item.id}>
        <a
          href={item.path || '#'}
          onClick={(e) => {
            if (hasChildren) {
              e.preventDefault();
              toggleExpanded(item.id);
            } else if (item.path) {
              e.preventDefault();
              router.push(item.path);
              setMobileOpen(false);
            }
          }}
          className={`
            flex items-center justify-between px-3 py-2 rounded-md
            transition-colors duration-150 cursor-pointer
            ${depth > 0 ? 'ml-6' : ''}
            ${active 
              ? 'bg-primary-100 text-primary-900 font-medium' 
              : 'text-gray-700 hover:bg-gray-100'
            }
          `}
        >
          <div className="flex items-center space-x-3">
            {item.icon && (
              <item.icon className={`w-5 h-5 ${active ? 'text-primary-600' : 'text-gray-400'}`} />
            )}
            <span>{item.label}</span>
          </div>
          
          <div className="flex items-center space-x-2">
            {item.badge && (
              <span className={`
                px-2 py-0.5 text-xs rounded-full
                ${typeof item.badge === 'number' && item.badge > 0
                  ? 'bg-red-100 text-red-600'
                  : 'bg-gray-100 text-gray-600'
                }
              `}>
                {item.badge}
              </span>
            )}
            
            {hasChildren && (
              <ChevronDown
                className={`
                  w-4 h-4 transition-transform duration-200
                  ${isExpanded ? 'transform rotate-180' : ''}
                `}
              />
            )}
          </div>
        </a>
        
        {hasChildren && isExpanded && (
          <ul className="mt-1 space-y-1">
            {item.children!.map(child => renderNavItem(child, depth + 1))}
          </ul>
        )}
      </li>
    );
  };
  
  return (
    <>
      {/* Mobile menu button */}
      <button
        className="lg:hidden fixed top-4 left-4 z-50 p-2 rounded-md bg-white shadow-md"
        onClick={() => setMobileOpen(!mobileOpen)}
      >
        {mobileOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
      </button>
      
      {/* Backdrop */}
      {mobileOpen && (
        <div
          className="lg:hidden fixed inset-0 z-40 bg-black bg-opacity-50"
          onClick={() => setMobileOpen(false)}
        />
      )}
      
      {/* Sidebar */}
      <aside
        className={`
          fixed lg:static inset-y-0 left-0 z-40
          w-64 bg-white border-r border-gray-200
          transform transition-transform duration-300 ease-in-out
          ${mobileOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'}
        `}
      >
        <div className="flex flex-col h-full">
          {/* Logo/Header */}
          <div className="px-4 py-4 border-b border-gray-200">
            <h2 className="text-xl font-semibold text-gray-800">Admin Panel</h2>
          </div>
          
          {/* Search */}
          <div className="px-4 py-3">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" />
              <input
                type="text"
                placeholder="Search..."
                className="w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-500"
              />
            </div>
          </div>
          
          {/* Navigation */}
          <nav className="flex-1 px-4 pb-4 overflow-y-auto">
            <ul className="space-y-1">
              {filteredNavigation.map(item => renderNavItem(item))}
            </ul>
          </nav>
          
          {/* User section */}
          <div className="px-4 py-3 border-t border-gray-200">
            <div className="flex items-center space-x-3">
              <div className="w-8 h-8 rounded-full bg-gray-300" />
              <div className="flex-1">
                <p className="text-sm font-medium text-gray-700">{user?.name}</p>
                <p className="text-xs text-gray-500">{user?.role}</p>
              </div>
            </div>
          </div>
        </div>
      </aside>
    </>
  );
};

// Breadcrumb component
export const Breadcrumbs: React.FC = () => {
  const router = useRouter();
  const pathSegments = router.pathname.split('/').filter(Boolean);
  
  const breadcrumbs = useMemo(() => {
    return pathSegments.map((segment, index) => {
      const path = '/' + pathSegments.slice(0, index + 1).join('/');
      const label = segment
        .split('-')
        .map(word => word.charAt(0).toUpperCase() + word.slice(1))
        .join(' ');
      
      return { label, path, isLast: index === pathSegments.length - 1 };
    });
  }, [pathSegments]);
  
  return (
    <nav className="flex items-center space-x-2 text-sm">
      <a href="/" className="text-gray-500 hover:text-gray-700">
        <Home className="w-4 h-4" />
      </a>
      
      {breadcrumbs.map((crumb, index) => (
        <React.Fragment key={crumb.path}>
          <ChevronRight className="w-4 h-4 text-gray-400" />
          {crumb.isLast ? (
            <span className="text-gray-700 font-medium">{crumb.label}</span>
          ) : (
            <a
              href={crumb.path}
              className="text-gray-500 hover:text-gray-700"
              onClick={(e) => {
                e.preventDefault();
                router.push(crumb.path);
              }}
            >
              {crumb.label}
            </a>
          )}
        </React.Fragment>
      ))}
    </nav>
  );
};

// Command palette for quick navigation
export const CommandPalette: React.FC = () => {
  const [open, setOpen] = useState(false);
  const [search, setSearch] = useState('');
  const router = useRouter();
  
  // Listen for keyboard shortcut
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault();
        setOpen(true);
      }
    };
    
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);
  
  const commands = useMemo(() => {
    return generateCommandsFromNavigation(navigation).filter(cmd =>
      cmd.label.toLowerCase().includes(search.toLowerCase())
    );
  }, [search]);
  
  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogContent className="p-0 max-w-2xl">
        <div className="border-b border-gray-200 px-4 py-3">
          <input
            type="text"
            placeholder="Type a command or search..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full outline-none text-lg"
            autoFocus
          />
        </div>
        
        <div className="max-h-96 overflow-y-auto p-2">
          {commands.length === 0 ? (
            <p className="text-center text-gray-500 py-8">No results found</p>
          ) : (
            <ul className="space-y-1">
              {commands.map(cmd => (
                <li key={cmd.id}>
                  <button
                    onClick={() => {
                      router.push(cmd.path);
                      setOpen(false);
                      setSearch('');
                    }}
                    className="w-full flex items-center space-x-3 px-3 py-2 rounded hover:bg-gray-100"
                  >
                    <cmd.icon className="w-5 h-5 text-gray-400" />
                    <div className="flex-1 text-left">
                      <p className="font-medium">{cmd.label}</p>
                      <p className="text-sm text-gray-500">{cmd.description}</p>
                    </div>
                  </button>
                </li>
              ))}
            </ul>
          )}
        </div>
      </DialogContent>
    </Dialog>
  );
};
```

### Vue.js Navigation Implementation
```vue
<template>
  <div class="admin-layout">
    <!-- Mobile menu button -->
    <button
      @click="mobileMenuOpen = !mobileMenuOpen"
      class="lg:hidden fixed top-4 left-4 z-50 p-2 rounded-md bg-white shadow-md"
    >
      <MenuIcon v-if="!mobileMenuOpen" class="w-6 h-6" />
      <XIcon v-else class="w-6 h-6" />
    </button>
    
    <!-- Sidebar -->
    <aside
      :class="[
        'fixed lg:static inset-y-0 left-0 z-40',
        'w-64 bg-white border-r border-gray-200',
        'transform transition-transform duration-300',
        mobileMenuOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'
      ]"
    >
      <!-- Logo -->
      <div class="px-4 py-4 border-b border-gray-200">
        <h2 class="text-xl font-semibold">{{ appName }}</h2>
      </div>
      
      <!-- Navigation -->
      <nav class="flex-1 px-4 py-4 overflow-y-auto">
        <NavigationGroup
          v-for="group in filteredNavigation"
          :key="group.id"
          :group="group"
          :depth="0"
          @navigate="handleNavigate"
        />
      </nav>
      
      <!-- User menu -->
      <div class="px-4 py-3 border-t border-gray-200">
        <UserMenu :user="currentUser" />
      </div>
    </aside>
    
    <!-- Main content -->
    <main class="flex-1 lg:ml-64">
      <!-- Top bar -->
      <header class="bg-white border-b border-gray-200 px-4 py-3">
        <div class="flex items-center justify-between">
          <Breadcrumbs :items="breadcrumbs" />
          
          <div class="flex items-center space-x-4">
            <CommandPaletteButton @click="commandPaletteOpen = true" />
            <NotificationBell :count="unreadNotifications" />
            <QuickActions :actions="quickActions" />
          </div>
        </div>
      </header>
      
      <!-- Page content -->
      <div class="p-6">
        <slot />
      </div>
    </main>
    
    <!-- Command palette -->
    <CommandPalette
      v-model:open="commandPaletteOpen"
      :commands="allCommands"
      @select="executeCommand"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useAuth } from '@/composables/useAuth';
import { usePermissions } from '@/composables/usePermissions';
import { storeToRefs } from 'pinia';

interface NavigationGroup {
  id: string;
  label: string;
  icon?: string;
  items: NavigationItem[];
  collapsed?: boolean;
}

interface NavigationItem {
  id: string;
  label: string;
  path?: string;
  icon?: string;
  badge?: number | string;
  children?: NavigationItem[];
  permissions?: string[];
  action?: () => void;
}

const props = defineProps<{
  navigation: NavigationGroup[];
  appName?: string;
}>();

const route = useRoute();
const router = useRouter();
const { user } = storeToRefs(useAuth());
const { hasPermission } = usePermissions();

const mobileMenuOpen = ref(false);
const commandPaletteOpen = ref(false);
const expandedGroups = ref<Record<string, boolean>>({});

// Filter navigation based on permissions
const filteredNavigation = computed(() => {
  return props.navigation
    .map(group => ({
      ...group,
      items: filterItemsByPermission(group.items)
    }))
    .filter(group => group.items.length > 0);
});

// Generate breadcrumbs from current route
const breadcrumbs = computed(() => {
  const segments = route.path.split('/').filter(Boolean);
  return segments.map((segment, index) => {
    const path = '/' + segments.slice(0, index + 1).join('/');
    return {
      label: formatSegmentLabel(segment),
      path,
      isLast: index === segments.length - 1
    };
  });
});

// Generate all commands for command palette
const allCommands = computed(() => {
  const commands: Command[] = [];
  
  filteredNavigation.value.forEach(group => {
    extractCommands(group.items, commands, group.label);
  });
  
  // Add global commands
  commands.push(
    {
      id: 'new-record',
      label: 'Create New Record',
      icon: 'plus',
      shortcut: '⌘N',
      action: () => router.push('/new')
    },
    {
      id: 'search',
      label: 'Search Everything',
      icon: 'search',
      shortcut: '⌘/',
      action: () => focusGlobalSearch()
    },
    {
      id: 'settings',
      label: 'Settings',
      icon: 'settings',
      shortcut: '⌘,',
      action: () => router.push('/settings')
    }
  );
  
  return commands;
});

// Filter items by permission
function filterItemsByPermission(items: NavigationItem[]): NavigationItem[] {
  return items
    .filter(item => {
      if (item.permissions && item.permissions.length > 0) {
        return item.permissions.some(perm => hasPermission(perm));
      }
      return true;
    })
    .map(item => ({
      ...item,
      children: item.children ? filterItemsByPermission(item.children) : undefined
    }));
}

// Handle navigation
function handleNavigate(item: NavigationItem) {
  if (item.action) {
    item.action();
  } else if (item.path) {
    router.push(item.path);
    mobileMenuOpen.value = false;
  }
}

// Extract commands from navigation items
function extractCommands(
  items: NavigationItem[], 
  commands: Command[], 
  groupLabel: string
) {
  items.forEach(item => {
    if (item.path) {
      commands.push({
        id: item.id,
        label: item.label,
        description: `${groupLabel} → ${item.label}`,
        icon: item.icon,
        action: () => router.push(item.path!)
      });
    }
    
    if (item.children) {
      extractCommands(item.children, commands, `${groupLabel} → ${item.label}`);
    }
  });
}

// Auto-expand active sections
watch(() => route.path, (path) => {
  filteredNavigation.value.forEach(group => {
    const hasActiveItem = group.items.some(item => 
      isActiveItem(item, path)
    );
    if (hasActiveItem) {
      expandedGroups.value[group.id] = true;
    }
  });
}, { immediate: true });

// Check if item is active
function isActiveItem(item: NavigationItem, currentPath: string): boolean {
  if (item.path === currentPath) return true;
  if (item.path && currentPath.startsWith(item.path + '/')) return true;
  if (item.children) {
    return item.children.some(child => isActiveItem(child, currentPath));
  }
  return false;
}
</script>

<!-- Navigation group component -->
<template>
  <div class="navigation-group mb-4">
    <button
      v-if="group.label"
      @click="toggleGroup"
      class="w-full flex items-center justify-between px-2 py-1 text-sm font-medium text-gray-500 hover:text-gray-700"
    >
      <span>{{ group.label }}</span>
      <ChevronDownIcon
        :class="[
          'w-4 h-4 transition-transform',
          isExpanded ? 'rotate-180' : ''
        ]"
      />
    </button>
    
    <ul
      v-show="isExpanded"
      class="mt-1 space-y-1"
    >
      <NavigationItem
        v-for="item in group.items"
        :key="item.id"
        :item="item"
        :depth="depth"
        @navigate="$emit('navigate', $event)"
      />
    </ul>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';

const props = defineProps<{
  group: NavigationGroup;
  depth: number;
}>();

const emit = defineEmits<{
  navigate: [item: NavigationItem];
}>();

const localExpanded = ref(true);

const isExpanded = computed(() => {
  return props.group.collapsed !== undefined 
    ? !props.group.collapsed 
    : localExpanded.value;
});

function toggleGroup() {
  if (props.group.collapsed !== undefined) {
    props.group.collapsed = !props.group.collapsed;
  } else {
    localExpanded.value = !localExpanded.value;
  }
}
</script>
```

### Navigation Configuration Schema
```typescript
// Navigation configuration generator
export class NavigationConfigurator {
  generateNavigationConfig(schema: DatabaseSchema): NavigationConfig {
    const config: NavigationConfig = {
      sidebar: {
        groups: [],
        quickAccess: [],
        recentItems: true,
        searchEnabled: true
      },
      topBar: {
        breadcrumbs: true,
        search: true,
        notifications: true,
        userMenu: true,
        quickActions: []
      },
      mobile: {
        bottomNav: false,
        hamburgerMenu: true,
        swipeGestures: true
      },
      features: {
        commandPalette: true,
        contextualActions: true,
        bookmarks: true,
        history: true
      }
    };
    
    // Generate sidebar groups
    const entityGroups = this.groupEntitiesByDomain(schema);
    
    entityGroups.forEach(group => {
      const sidebarGroup: SidebarGroup = {
        id: group.id,
        label: group.label,
        icon: group.icon,
        priority: group.priority,
        items: group.entities.map(entity => ({
          id: entity.name,
          label: this.formatEntityLabel(entity),
          path: this.generateEntityPath(entity),
          icon: this.selectEntityIcon(entity),
          badge: this.generateBadgeConfig(entity),
          permissions: [`${entity.name}:read`],
          children: this.generateEntitySubItems(entity, schema)
        }))
      };
      
      config.sidebar.groups.push(sidebarGroup);
    });
    
    // Add system groups
    config.sidebar.groups.push(
      {
        id: 'reports',
        label: 'Reports & Analytics',
        icon: 'bar-chart',
        priority: 50,
        items: this.generateReportItems(schema)
      },
      {
        id: 'settings',
        label: 'Settings',
        icon: 'settings',
        priority: 100,
        items: this.generateSettingsItems(schema)
      }
    );
    
    // Configure quick actions
    config.topBar.quickActions = [
      {
        id: 'create-new',
        label: 'Create New',
        icon: 'plus',
        dropdown: this.generateCreateActions(schema)
      }
    ];
    
    // Configure mobile navigation
    if (this.shouldEnableBottomNav(schema)) {
      config.mobile.bottomNav = true;
      config.mobile.bottomNavItems = this.selectMobileNavItems(schema);
    }
    
    return config;
  }
  
  private groupEntitiesByDomain(schema: DatabaseSchema): EntityGroup[] {
    // Smart grouping logic based on naming patterns and relationships
    const groups: Map<string, EntityGroup> = new Map();
    
    schema.entities.forEach(entity => {
      const domain = this.identifyDomain(entity);
      
      if (!groups.has(domain)) {
        groups.set(domain, {
          id: this.toKebabCase(domain),
          label: domain,
          icon: this.selectDomainIcon(domain),
          priority: this.calculateDomainPriority(domain),
          entities: []
        });
      }
      
      groups.get(domain)!.entities.push(entity);
    });
    
    return Array.from(groups.values())
      .sort((a, b) => a.priority - b.priority);
  }
  
  private identifyDomain(entity: Entity): string {
    // Examples of domain identification
    const domainPatterns = [
      { pattern: /^(user|role|permission|auth)/i, domain: 'User Management' },
      { pattern: /^(product|category|inventory|stock)/i, domain: 'Products' },
      { pattern: /^(order|cart|checkout|payment)/i, domain: 'Sales' },
      { pattern: /^(customer|client|contact)/i, domain: 'Customers' },
      { pattern: /^(report|analytics|metric)/i, domain: 'Analytics' },
      { pattern: /^(setting|config|preference)/i, domain: 'Configuration' }
    ];
    
    for (const { pattern, domain } of domainPatterns) {
      if (pattern.test(entity.name)) {
        return domain;
      }
    }
    
    // Check relationships for domain hints
    const relatedEntities = this.getRelatedEntityNames(entity);
    for (const related of relatedEntities) {
      for (const { pattern, domain } of domainPatterns) {
        if (pattern.test(related)) {
          return domain;
        }
      }
    }
    
    return 'General';
  }
}
```

## Integration Points
- Receives entity structure from Schema Analyzer
- Coordinates with Dashboard Designer for layout
- Uses access patterns from Access Control Manager
- Implements icons from Theme Customizer
- Provides navigation structure to all UI components

## Best Practices
1. Keep navigation depth to maximum 3 levels
2. Group related entities logically
3. Use clear, action-oriented labels
4. Implement search for large navigation sets
5. Provide keyboard navigation support
6. Cache navigation structure for performance
7. Include visual indicators for active states
8. Support responsive navigation patterns
9. Implement permission-based filtering
10. Provide contextual navigation options