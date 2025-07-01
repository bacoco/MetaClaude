# Table Builder Agent

## Purpose
Generates feature-rich, responsive data tables and grids for displaying database records with advanced functionality including sorting, filtering, pagination, bulk actions, and inline editing based on schema analysis and data patterns.

## Capabilities

### Table Features
- Sortable columns
- Advanced filtering
- Server-side pagination
- Column resizing
- Column reordering
- Fixed headers/columns
- Row selection
- Bulk actions
- Inline editing
- Export functionality
- Row expansion
- Nested tables
- Virtual scrolling
- Responsive design

### Data Handling
- Large dataset optimization
- Real-time updates
- Lazy loading
- Infinite scroll
- Data caching
- Optimistic updates
- Conflict resolution
- Batch operations
- Transaction support

### Visualization Options
- Standard tables
- Data grids
- Card views
- List views
- Kanban boards
- Timeline views
- Calendar views
- Tree tables
- Pivot tables
- Heat maps

## Table Generation Strategy

### Schema-Based Table Configuration
```typescript
interface TableGenerator {
  generateTableConfig(entity: Entity, options: TableOptions): TableConfiguration {
    const config: TableConfiguration = {
      id: `${entity.name}-table`,
      title: this.formatTableTitle(entity),
      columns: this.generateColumns(entity),
      features: this.determineFeatures(entity, options),
      actions: this.generateActions(entity),
      filters: this.generateFilters(entity),
      sorting: this.generateSortingConfig(entity),
      pagination: this.generatePaginationConfig(entity, options),
      selection: this.generateSelectionConfig(entity, options),
      export: this.generateExportConfig(entity)
    };
    
    // Add relationship columns
    this.addRelationshipColumns(config, entity);
    
    // Optimize for performance
    this.optimizeForDataSize(config, entity);
    
    return config;
  }
  
  generateColumns(entity: Entity): ColumnDefinition[] {
    const columns: ColumnDefinition[] = [];
    
    // Add selection column if needed
    if (this.shouldHaveSelection(entity)) {
      columns.push({
        id: 'selection',
        type: 'selection',
        width: 40,
        fixed: 'left',
        sortable: false,
        filterable: false
      });
    }
    
    // Generate data columns
    entity.fields.forEach(field => {
      if (this.shouldIncludeField(field)) {
        const column: ColumnDefinition = {
          id: field.name,
          field: field.name,
          header: this.humanizeFieldName(field.name),
          type: this.mapFieldToColumnType(field),
          dataType: field.type,
          sortable: this.isSortable(field),
          filterable: this.isFilterable(field),
          editable: this.isEditable(field),
          width: this.calculateColumnWidth(field),
          align: this.getColumnAlignment(field),
          format: this.getColumnFormat(field),
          validation: field.validation,
          visible: this.isVisibleByDefault(field)
        };
        
        // Add special rendering for certain types
        this.addSpecialRendering(column, field);
        
        columns.push(column);
      }
    });
    
    // Add computed columns
    this.addComputedColumns(columns, entity);
    
    // Add action column
    if (this.shouldHaveActions(entity)) {
      columns.push({
        id: 'actions',
        type: 'actions',
        header: 'Actions',
        width: 120,
        fixed: 'right',
        sortable: false,
        filterable: false
      });
    }
    
    return columns;
  }
  
  private addSpecialRendering(column: ColumnDefinition, field: Field): void {
    // Status columns
    if (field.name.includes('status') || field.type === 'enum') {
      column.render = 'badge';
      column.badgeConfig = this.generateBadgeConfig(field);
    }
    
    // Date columns
    if (field.type === 'date' || field.type === 'datetime') {
      column.render = 'date';
      column.dateFormat = field.type === 'datetime' 
        ? 'MMM d, yyyy HH:mm' 
        : 'MMM d, yyyy';
    }
    
    // Boolean columns
    if (field.type === 'boolean') {
      column.render = 'boolean';
      column.trueLabel = this.getTrueLabel(field.name);
      column.falseLabel = this.getFalseLabel(field.name);
    }
    
    // Currency columns
    if (field.name.includes('price') || field.name.includes('amount')) {
      column.render = 'currency';
      column.currency = 'USD';
    }
    
    // Image columns
    if (field.name.includes('image') || field.name.includes('avatar')) {
      column.render = 'image';
      column.imageConfig = {
        width: 40,
        height: 40,
        rounded: field.name.includes('avatar')
      };
    }
    
    // Relation columns
    if (field.relation) {
      column.render = 'relation';
      column.displayField = this.detectDisplayField(field.relation);
    }
  }
  
  generateFilters(entity: Entity): FilterConfiguration {
    const filters: FilterConfiguration = {
      global: {
        enabled: true,
        placeholder: `Search ${entity.name}...`,
        fields: this.getSearchableFields(entity)
      },
      advanced: [],
      quick: [],
      saved: true
    };
    
    // Generate column filters
    entity.fields.forEach(field => {
      if (this.isFilterable(field)) {
        const filter: FilterDefinition = {
          id: field.name,
          field: field.name,
          label: this.humanizeFieldName(field.name),
          type: this.getFilterType(field),
          operators: this.getFilterOperators(field),
          defaultOperator: this.getDefaultOperator(field)
        };
        
        // Add filter-specific configuration
        switch (field.type) {
          case 'enum':
            filter.options = field.enumValues?.map(v => ({
              value: v,
              label: this.humanizeEnumValue(v)
            }));
            break;
            
          case 'boolean':
            filter.options = [
              { value: true, label: 'Yes' },
              { value: false, label: 'No' }
            ];
            break;
            
          case 'date':
          case 'datetime':
            filter.dateConfig = {
              format: field.type === 'datetime' ? 'datetime' : 'date',
              quickOptions: [
                'Today', 'Yesterday', 'This Week', 
                'Last Week', 'This Month', 'Last Month'
              ]
            };
            break;
            
          case 'number':
          case 'decimal':
            filter.numberConfig = {
              min: field.min,
              max: field.max,
              step: field.type === 'decimal' ? 0.01 : 1
            };
            break;
        }
        
        filters.advanced.push(filter);
        
        // Add to quick filters if commonly used
        if (this.isQuickFilter(field)) {
          filters.quick.push(filter);
        }
      }
    });
    
    return filters;
  }
}
```

### React Table Implementation
```tsx
import React, { useState, useEffect, useMemo, useCallback, useRef } from 'react';
import {
  useReactTable,
  getCoreRowModel,
  getFilteredRowModel,
  getPaginationRowModel,
  getSortedRowModel,
  getExpandedRowModel,
  ColumnDef,
  flexRender,
  RowSelectionState,
  SortingState,
  ColumnFiltersState,
  VisibilityState,
  ExpandedState
} from '@tanstack/react-table';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
  Checkbox,
  Button,
  Input,
  Select,
  DropdownMenu,
  DropdownMenuTrigger,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  Badge,
  Skeleton,
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  Popover,
  PopoverContent,
  PopoverTrigger,
  Command,
  CommandInput,
  CommandList,
  CommandEmpty,
  CommandGroup,
  CommandItem
} from '@/components/ui';
import {
  ChevronDown,
  ChevronUp,
  ChevronsUpDown,
  Download,
  Eye,
  Filter,
  MoreHorizontal,
  Plus,
  Search,
  Settings,
  Trash,
  Edit,
  Copy,
  RefreshCw
} from 'lucide-react';
import { VirtualList } from '@tanstack/react-virtual';

interface DataTableProps<TData> {
  columns: ColumnDef<TData>[];
  data: TData[];
  loading?: boolean;
  totalCount?: number;
  pageSize?: number;
  onPageChange?: (page: number) => void;
  onPageSizeChange?: (size: number) => void;
  onSort?: (sorting: SortingState) => void;
  onFilter?: (filters: ColumnFiltersState) => void;
  onRowSelection?: (selection: RowSelectionState) => void;
  actions?: TableAction<TData>[];
  bulkActions?: BulkAction<TData>[];
  onRefresh?: () => void;
  enableSelection?: boolean;
  enableSorting?: boolean;
  enableFiltering?: boolean;
  enableColumnVisibility?: boolean;
  enableExport?: boolean;
  enableInlineEdit?: boolean;
  stickyHeader?: boolean;
  virtualScroll?: boolean;
  rowHeight?: number;
}

export function DataTable<TData extends Record<string, any>>({
  columns,
  data,
  loading = false,
  totalCount,
  pageSize = 10,
  onPageChange,
  onPageSizeChange,
  onSort,
  onFilter,
  onRowSelection,
  actions,
  bulkActions,
  onRefresh,
  enableSelection = true,
  enableSorting = true,
  enableFiltering = true,
  enableColumnVisibility = true,
  enableExport = true,
  enableInlineEdit = false,
  stickyHeader = true,
  virtualScroll = false,
  rowHeight = 48
}: DataTableProps<TData>) {
  const [rowSelection, setRowSelection] = useState<RowSelectionState>({});
  const [sorting, setSorting] = useState<SortingState>([]);
  const [columnFilters, setColumnFilters] = useState<ColumnFiltersState>([]);
  const [columnVisibility, setColumnVisibility] = useState<VisibilityState>({});
  const [expanded, setExpanded] = useState<ExpandedState>({});
  const [globalFilter, setGlobalFilter] = useState('');
  const [editingCell, setEditingCell] = useState<{
    rowId: string;
    columnId: string;
  } | null>(null);
  
  const tableContainerRef = useRef<HTMLDivElement>(null);
  
  // Enhanced columns with features
  const enhancedColumns = useMemo(() => {
    const cols: ColumnDef<TData>[] = [];
    
    // Selection column
    if (enableSelection) {
      cols.push({
        id: 'select',
        size: 40,
        header: ({ table }) => (
          <Checkbox
            checked={table.getIsAllPageRowsSelected()}
            indeterminate={table.getIsSomePageRowsSelected()}
            onCheckedChange={(value) => table.toggleAllPageRowsSelected(!!value)}
            aria-label="Select all"
          />
        ),
        cell: ({ row }) => (
          <Checkbox
            checked={row.getIsSelected()}
            onCheckedChange={(value) => row.toggleSelected(!!value)}
            aria-label="Select row"
          />
        ),
        enableSorting: false,
        enableHiding: false
      });
    }
    
    // Data columns
    cols.push(...columns);
    
    // Actions column
    if (actions && actions.length > 0) {
      cols.push({
        id: 'actions',
        size: 100,
        header: 'Actions',
        cell: ({ row }) => (
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" size="sm">
                <MoreHorizontal className="h-4 w-4" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              {actions.map((action, index) => (
                <React.Fragment key={action.id}>
                  {action.separator && index > 0 && <DropdownMenuSeparator />}
                  <DropdownMenuItem
                    onClick={() => action.onClick(row.original)}
                    disabled={action.disabled?.(row.original)}
                  >
                    {action.icon && <action.icon className="mr-2 h-4 w-4" />}
                    {action.label}
                  </DropdownMenuItem>
                </React.Fragment>
              ))}
            </DropdownMenuContent>
          </DropdownMenu>
        ),
        enableSorting: false,
        enableHiding: false
      });
    }
    
    return cols;
  }, [columns, actions, enableSelection]);
  
  // Table instance
  const table = useReactTable({
    data,
    columns: enhancedColumns,
    getCoreRowModel: getCoreRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
    getPaginationRowModel: getPaginationRowModel(),
    getSortedRowModel: getSortedRowModel(),
    getExpandedRowModel: getExpandedRowModel(),
    onRowSelectionChange: (updater) => {
      setRowSelection(updater);
      onRowSelection?.(
        typeof updater === 'function' ? updater(rowSelection) : updater
      );
    },
    onSortingChange: (updater) => {
      setSorting(updater);
      onSort?.(typeof updater === 'function' ? updater(sorting) : updater);
    },
    onColumnFiltersChange: (updater) => {
      setColumnFilters(updater);
      onFilter?.(
        typeof updater === 'function' ? updater(columnFilters) : updater
      );
    },
    onColumnVisibilityChange: setColumnVisibility,
    onExpandedChange: setExpanded,
    onGlobalFilterChange: setGlobalFilter,
    state: {
      rowSelection,
      sorting,
      columnFilters,
      columnVisibility,
      expanded,
      globalFilter
    },
    manualPagination: !!onPageChange,
    manualSorting: !!onSort,
    manualFiltering: !!onFilter,
    pageCount: totalCount ? Math.ceil(totalCount / pageSize) : undefined
  });
  
  // Virtual scrolling
  const { rows } = table.getRowModel();
  const parentRef = useRef<HTMLDivElement>(null);
  
  const virtualizer = useVirtualizer({
    count: rows.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => rowHeight,
    overscan: 10
  });
  
  const virtualRows = virtualizer.getVirtualItems();
  const totalSize = virtualizer.getTotalSize();
  
  // Bulk actions handler
  const handleBulkAction = useCallback((action: BulkAction<TData>) => {
    const selectedRows = table.getSelectedRowModel().rows.map(row => row.original);
    action.onClick(selectedRows);
    setRowSelection({});
  }, [table]);
  
  // Export handler
  const handleExport = useCallback(async (format: 'csv' | 'excel' | 'json') => {
    const exportData = table.getFilteredRowModel().rows.map(row => row.original);
    
    switch (format) {
      case 'csv':
        const csv = convertToCSV(exportData);
        downloadFile(csv, `export-${Date.now()}.csv`, 'text/csv');
        break;
      case 'excel':
        // Implement Excel export
        break;
      case 'json':
        const json = JSON.stringify(exportData, null, 2);
        downloadFile(json, `export-${Date.now()}.json`, 'application/json');
        break;
    }
  }, [table]);
  
  // Inline edit handler
  const handleInlineEdit = useCallback(
    async (rowId: string, columnId: string, value: any) => {
      // Update the data
      const rowIndex = data.findIndex((row: any) => row.id === rowId);
      if (rowIndex >= 0) {
        const updatedRow = { ...data[rowIndex], [columnId]: value };
        // Call update handler
        // await onUpdate(updatedRow);
      }
      setEditingCell(null);
    },
    [data]
  );
  
  return (
    <div className="space-y-4">
      {/* Toolbar */}
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-2">
          {/* Global search */}
          {enableFiltering && (
            <div className="relative">
              <Search className="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Search..."
                value={globalFilter}
                onChange={(e) => setGlobalFilter(e.target.value)}
                className="pl-8 w-64"
              />
            </div>
          )}
          
          {/* Column filters */}
          {enableFiltering && (
            <ColumnFilters table={table} />
          )}
          
          {/* Bulk actions */}
          {bulkActions && Object.keys(rowSelection).length > 0 && (
            <div className="flex items-center space-x-2">
              <span className="text-sm text-muted-foreground">
                {Object.keys(rowSelection).length} selected
              </span>
              {bulkActions.map(action => (
                <Button
                  key={action.id}
                  size="sm"
                  variant={action.variant || 'outline'}
                  onClick={() => handleBulkAction(action)}
                >
                  {action.icon && <action.icon className="mr-2 h-4 w-4" />}
                  {action.label}
                </Button>
              ))}
            </div>
          )}
        </div>
        
        <div className="flex items-center space-x-2">
          {/* Refresh */}
          {onRefresh && (
            <Button
              variant="outline"
              size="sm"
              onClick={onRefresh}
              disabled={loading}
            >
              <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
            </Button>
          )}
          
          {/* Export */}
          {enableExport && (
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="outline" size="sm">
                  <Download className="mr-2 h-4 w-4" />
                  Export
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent>
                <DropdownMenuItem onClick={() => handleExport('csv')}>
                  Export as CSV
                </DropdownMenuItem>
                <DropdownMenuItem onClick={() => handleExport('json')}>
                  Export as JSON
                </DropdownMenuItem>
                <DropdownMenuItem onClick={() => handleExport('excel')}>
                  Export as Excel
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          )}
          
          {/* Column visibility */}
          {enableColumnVisibility && (
            <ColumnVisibility table={table} />
          )}
        </div>
      </div>
      
      {/* Table */}
      <div className="rounded-md border">
        <div
          ref={virtualScroll ? parentRef : tableContainerRef}
          className={`relative overflow-auto ${
            virtualScroll ? 'h-[600px]' : 'max-h-[600px]'
          }`}
        >
          <Table>
            <TableHeader className={stickyHeader ? 'sticky top-0 bg-background z-10' : ''}>
              {table.getHeaderGroups().map(headerGroup => (
                <TableRow key={headerGroup.id}>
                  {headerGroup.headers.map(header => (
                    <TableHead
                      key={header.id}
                      style={{ width: header.getSize() }}
                      className={header.column.getCanSort() ? 'cursor-pointer select-none' : ''}
                      onClick={header.column.getToggleSortingHandler()}
                    >
                      {header.isPlaceholder ? null : (
                        <div className="flex items-center space-x-1">
                          {flexRender(
                            header.column.columnDef.header,
                            header.getContext()
                          )}
                          {header.column.getCanSort() && (
                            <div className="ml-auto">
                              {{
                                asc: <ChevronUp className="h-4 w-4" />,
                                desc: <ChevronDown className="h-4 w-4" />
                              }[header.column.getIsSorted() as string] ?? (
                                <ChevronsUpDown className="h-4 w-4 text-muted-foreground" />
                              )}
                            </div>
                          )}
                        </div>
                      )}
                    </TableHead>
                  ))}
                </TableRow>
              ))}
            </TableHeader>
            
            <TableBody>
              {loading ? (
                // Loading skeleton
                Array.from({ length: pageSize }).map((_, index) => (
                  <TableRow key={index}>
                    {enhancedColumns.map((column, colIndex) => (
                      <TableCell key={colIndex}>
                        <Skeleton className="h-4 w-full" />
                      </TableCell>
                    ))}
                  </TableRow>
                ))
              ) : virtualScroll ? (
                // Virtual rows
                <div
                  style={{
                    height: `${totalSize}px`,
                    width: '100%',
                    position: 'relative'
                  }}
                >
                  {virtualRows.map(virtualRow => {
                    const row = rows[virtualRow.index];
                    return (
                      <TableRow
                        key={row.id}
                        data-index={virtualRow.index}
                        style={{
                          position: 'absolute',
                          top: 0,
                          left: 0,
                          width: '100%',
                          height: `${virtualRow.size}px`,
                          transform: `translateY(${virtualRow.start}px)`
                        }}
                      >
                        {row.getVisibleCells().map(cell => (
                          <TableCell key={cell.id}>
                            {enableInlineEdit && 
                             cell.column.columnDef.enableEditing !== false &&
                             editingCell?.rowId === row.id && 
                             editingCell?.columnId === cell.column.id ? (
                              <InlineEdit
                                value={cell.getValue()}
                                onSave={(value) => 
                                  handleInlineEdit(row.id, cell.column.id, value)
                                }
                                onCancel={() => setEditingCell(null)}
                              />
                            ) : (
                              <div
                                onDoubleClick={() => 
                                  enableInlineEdit && 
                                  cell.column.columnDef.enableEditing !== false &&
                                  setEditingCell({ 
                                    rowId: row.id, 
                                    columnId: cell.column.id 
                                  })
                                }
                              >
                                {flexRender(
                                  cell.column.columnDef.cell,
                                  cell.getContext()
                                )}
                              </div>
                            )}
                          </TableCell>
                        ))}
                      </TableRow>
                    );
                  })}
                </div>
              ) : (
                // Regular rows
                table.getRowModel().rows.map(row => (
                  <TableRow
                    key={row.id}
                    data-state={row.getIsSelected() && 'selected'}
                  >
                    {row.getVisibleCells().map(cell => (
                      <TableCell key={cell.id}>
                        {enableInlineEdit && 
                         cell.column.columnDef.enableEditing !== false &&
                         editingCell?.rowId === row.id && 
                         editingCell?.columnId === cell.column.id ? (
                          <InlineEdit
                            value={cell.getValue()}
                            onSave={(value) => 
                              handleInlineEdit(row.id, cell.column.id, value)
                            }
                            onCancel={() => setEditingCell(null)}
                          />
                        ) : (
                          <div
                            onDoubleClick={() => 
                              enableInlineEdit && 
                              cell.column.columnDef.enableEditing !== false &&
                              setEditingCell({ 
                                rowId: row.id, 
                                columnId: cell.column.id 
                              })
                            }
                          >
                            {flexRender(
                              cell.column.columnDef.cell,
                              cell.getContext()
                            )}
                          </div>
                        )}
                      </TableCell>
                    ))}
                  </TableRow>
                ))
              )}
              
              {!loading && table.getRowModel().rows.length === 0 && (
                <TableRow>
                  <TableCell
                    colSpan={enhancedColumns.length}
                    className="h-24 text-center"
                  >
                    No results found
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </div>
      </div>
      
      {/* Pagination */}
      <DataTablePagination table={table} />
    </div>
  );
}

// Column visibility component
function ColumnVisibility({ table }: { table: any }) {
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="outline" size="sm">
          <Settings className="mr-2 h-4 w-4" />
          Columns
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-48">
        {table
          .getAllColumns()
          .filter((column: any) => column.getCanHide())
          .map((column: any) => (
            <DropdownMenuItem
              key={column.id}
              className="capitalize"
              onSelect={(e) => e.preventDefault()}
            >
              <Checkbox
                checked={column.getIsVisible()}
                onCheckedChange={(value) => column.toggleVisibility(!!value)}
                className="mr-2"
              />
              {column.id}
            </DropdownMenuItem>
          ))}
      </DropdownMenuContent>
    </DropdownMenu>
  );
}

// Column filters component
function ColumnFilters({ table }: { table: any }) {
  const [open, setOpen] = useState(false);
  
  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <Button variant="outline" size="sm">
          <Filter className="mr-2 h-4 w-4" />
          Filters
          {table.getState().columnFilters.length > 0 && (
            <Badge variant="secondary" className="ml-2">
              {table.getState().columnFilters.length}
            </Badge>
          )}
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-80">
        <div className="space-y-4">
          <h4 className="font-medium">Filter columns</h4>
          {table
            .getAllColumns()
            .filter((column: any) => column.getCanFilter())
            .map((column: any) => (
              <div key={column.id} className="space-y-2">
                <label className="text-sm font-medium">{column.id}</label>
                <Input
                  placeholder={`Filter ${column.id}...`}
                  value={(column.getFilterValue() ?? '') as string}
                  onChange={(e) => column.setFilterValue(e.target.value)}
                />
              </div>
            ))}
          <div className="flex justify-between">
            <Button
              variant="ghost"
              size="sm"
              onClick={() => table.resetColumnFilters()}
            >
              Clear filters
            </Button>
            <Button size="sm" onClick={() => setOpen(false)}>
              Apply
            </Button>
          </div>
        </div>
      </PopoverContent>
    </Popover>
  );
}
```

### Vue.js Table Implementation
```vue
<template>
  <div class="data-table">
    <!-- Toolbar -->
    <div class="table-toolbar">
      <div class="toolbar-left">
        <!-- Search -->
        <div v-if="enableFiltering" class="search-box">
          <SearchIcon class="search-icon" />
          <input
            v-model="globalFilter"
            type="text"
            placeholder="Search..."
            class="search-input"
          />
        </div>
        
        <!-- Filters -->
        <ColumnFilters
          v-if="enableFiltering"
          :columns="columns"
          v-model="columnFilters"
        />
        
        <!-- Bulk actions -->
        <div v-if="selectedRows.length > 0" class="bulk-actions">
          <span class="selected-count">
            {{ selectedRows.length }} selected
          </span>
          <button
            v-for="action in bulkActions"
            :key="action.id"
            @click="handleBulkAction(action)"
            :class="['btn', `btn-${action.variant || 'outline'}`]"
          >
            <component :is="action.icon" v-if="action.icon" class="icon" />
            {{ action.label }}
          </button>
        </div>
      </div>
      
      <div class="toolbar-right">
        <!-- Refresh -->
        <button
          v-if="onRefresh"
          @click="onRefresh"
          :disabled="loading"
          class="btn btn-outline"
        >
          <RefreshIcon :class="['icon', { 'animate-spin': loading }]" />
        </button>
        
        <!-- Export -->
        <ExportMenu
          v-if="enableExport"
          @export="handleExport"
        />
        
        <!-- Column visibility -->
        <ColumnVisibility
          v-if="enableColumnVisibility"
          :columns="columns"
          v-model="columnVisibility"
        />
      </div>
    </div>
    
    <!-- Table container -->
    <div class="table-container" ref="tableContainer">
      <table class="table">
        <thead :class="{ 'sticky-header': stickyHeader }">
          <tr>
            <!-- Selection column -->
            <th v-if="enableSelection" class="selection-column">
              <input
                type="checkbox"
                :checked="isAllSelected"
                :indeterminate="isSomeSelected"
                @change="toggleAllSelection"
              />
            </th>
            
            <!-- Data columns -->
            <th
              v-for="column in visibleColumns"
              :key="column.id"
              :style="{ width: column.width + 'px' }"
              :class="{
                sortable: column.sortable && enableSorting,
                'text-left': column.align === 'left',
                'text-center': column.align === 'center',
                'text-right': column.align === 'right'
              }"
              @click="column.sortable && toggleSort(column)"
            >
              <div class="header-content">
                <span>{{ column.header }}</span>
                <SortIndicator
                  v-if="column.sortable && enableSorting"
                  :direction="getSortDirection(column)"
                />
              </div>
            </th>
            
            <!-- Actions column -->
            <th v-if="actions && actions.length > 0" class="actions-column">
              Actions
            </th>
          </tr>
        </thead>
        
        <tbody v-if="loading">
          <!-- Loading skeleton -->
          <tr v-for="i in pageSize" :key="i">
            <td v-for="j in totalColumns" :key="j">
              <div class="skeleton" />
            </td>
          </tr>
        </tbody>
        
        <tbody v-else-if="virtualScroll" ref="virtualBody">
          <!-- Virtual scrolling -->
          <VirtualList
            :items="filteredData"
            :item-height="rowHeight"
            :buffer="10"
            v-slot="{ item, index }"
          >
            <TableRow
              :row="item"
              :index="index"
              :columns="visibleColumns"
              :actions="actions"
              :enable-selection="enableSelection"
              :enable-inline-edit="enableInlineEdit"
              :selected="isRowSelected(item)"
              @select="toggleRowSelection(item)"
              @edit="handleEdit"
              @action="handleAction"
            />
          </VirtualList>
        </tbody>
        
        <tbody v-else>
          <!-- Regular rows -->
          <TableRow
            v-for="(row, index) in paginatedData"
            :key="getRowKey(row, index)"
            :row="row"
            :index="index"
            :columns="visibleColumns"
            :actions="actions"
            :enable-selection="enableSelection"
            :enable-inline-edit="enableInlineEdit"
            :selected="isRowSelected(row)"
            @select="toggleRowSelection(row)"
            @edit="handleEdit"
            @action="handleAction"
          />
          
          <!-- Empty state -->
          <tr v-if="filteredData.length === 0">
            <td :colspan="totalColumns" class="empty-state">
              <EmptyState message="No data found" />
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    
    <!-- Pagination -->
    <TablePagination
      v-if="!virtualScroll"
      v-model:page="currentPage"
      v-model:page-size="currentPageSize"
      :total="filteredData.length"
      :page-sizes="[10, 20, 50, 100]"
      @update:page="handlePageChange"
      @update:page-size="handlePageSizeChange"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, reactive } from 'vue';
import { useVirtualList } from '@vueuse/core';
import type {
  Column,
  Row,
  SortDirection,
  FilterValue,
  Action,
  BulkAction
} from '@/types/table';

interface Props {
  columns: Column[];
  data: Row[];
  loading?: boolean;
  totalCount?: number;
  pageSize?: number;
  onPageChange?: (page: number) => void;
  onPageSizeChange?: (size: number) => void;
  onSort?: (column: string, direction: SortDirection) => void;
  onFilter?: (filters: Record<string, FilterValue>) => void;
  onRowSelection?: (selection: Row[]) => void;
  actions?: Action[];
  bulkActions?: BulkAction[];
  onRefresh?: () => void;
  enableSelection?: boolean;
  enableSorting?: boolean;
  enableFiltering?: boolean;
  enableColumnVisibility?: boolean;
  enableExport?: boolean;
  enableInlineEdit?: boolean;
  stickyHeader?: boolean;
  virtualScroll?: boolean;
  rowHeight?: number;
  getRowKey?: (row: Row, index: number) => string | number;
}

const props = withDefaults(defineProps<Props>(), {
  loading: false,
  pageSize: 10,
  enableSelection: true,
  enableSorting: true,
  enableFiltering: true,
  enableColumnVisibility: true,
  enableExport: true,
  enableInlineEdit: false,
  stickyHeader: true,
  virtualScroll: false,
  rowHeight: 48,
  getRowKey: (row: Row, index: number) => row.id || index
});

const emit = defineEmits([
  'update:selection',
  'sort',
  'filter',
  'page-change',
  'page-size-change',
  'refresh',
  'export',
  'edit',
  'action'
]);

// State
const currentPage = ref(1);
const currentPageSize = ref(props.pageSize);
const selectedRows = ref<Row[]>([]);
const sorting = ref<{ column: string; direction: SortDirection }[]>([]);
const columnFilters = ref<Record<string, FilterValue>>({});
const globalFilter = ref('');
const columnVisibility = ref<Record<string, boolean>>(
  Object.fromEntries(props.columns.map(col => [col.id, col.visible !== false]))
);

// Computed
const visibleColumns = computed(() =>
  props.columns.filter(col => columnVisibility.value[col.id] !== false)
);

const totalColumns = computed(() => {
  let count = visibleColumns.value.length;
  if (props.enableSelection) count++;
  if (props.actions?.length) count++;
  return count;
});

const filteredData = computed(() => {
  let result = [...props.data];
  
  // Apply global filter
  if (globalFilter.value) {
    const searchTerm = globalFilter.value.toLowerCase();
    result = result.filter(row =>
      Object.values(row).some(value =>
        String(value).toLowerCase().includes(searchTerm)
      )
    );
  }
  
  // Apply column filters
  Object.entries(columnFilters.value).forEach(([columnId, filterValue]) => {
    if (filterValue) {
      result = result.filter(row => {
        const column = props.columns.find(col => col.id === columnId);
        if (!column) return true;
        
        const value = row[columnId];
        
        // Custom filter function
        if (column.filterFn) {
          return column.filterFn(value, filterValue, row);
        }
        
        // Default filter logic
        if (typeof filterValue === 'string') {
          return String(value).toLowerCase().includes(filterValue.toLowerCase());
        }
        
        return value === filterValue;
      });
    }
  });
  
  // Apply sorting
  if (sorting.value.length > 0 && !props.onSort) {
    result.sort((a, b) => {
      for (const sort of sorting.value) {
        const column = props.columns.find(col => col.id === sort.column);
        if (!column) continue;
        
        const aVal = a[sort.column];
        const bVal = b[sort.column];
        
        // Custom sort function
        if (column.sortFn) {
          const result = column.sortFn(aVal, bVal, a, b);
          if (result !== 0) {
            return sort.direction === 'asc' ? result : -result;
          }
          continue;
        }
        
        // Default sort logic
        if (aVal < bVal) return sort.direction === 'asc' ? -1 : 1;
        if (aVal > bVal) return sort.direction === 'asc' ? 1 : -1;
      }
      return 0;
    });
  }
  
  return result;
});

const paginatedData = computed(() => {
  if (props.virtualScroll || props.onPageChange) {
    return filteredData.value;
  }
  
  const start = (currentPage.value - 1) * currentPageSize.value;
  const end = start + currentPageSize.value;
  return filteredData.value.slice(start, end);
});

const isAllSelected = computed(() =>
  filteredData.value.length > 0 &&
  filteredData.value.every(row => isRowSelected(row))
);

const isSomeSelected = computed(() =>
  selectedRows.value.length > 0 && !isAllSelected.value
);

// Methods
function isRowSelected(row: Row): boolean {
  return selectedRows.value.some(selected => 
    props.getRowKey(selected, 0) === props.getRowKey(row, 0)
  );
}

function toggleRowSelection(row: Row) {
  const index = selectedRows.value.findIndex(selected =>
    props.getRowKey(selected, 0) === props.getRowKey(row, 0)
  );
  
  if (index >= 0) {
    selectedRows.value.splice(index, 1);
  } else {
    selectedRows.value.push(row);
  }
  
  emit('update:selection', selectedRows.value);
  props.onRowSelection?.(selectedRows.value);
}

function toggleAllSelection() {
  if (isAllSelected.value) {
    selectedRows.value = [];
  } else {
    selectedRows.value = [...filteredData.value];
  }
  
  emit('update:selection', selectedRows.value);
  props.onRowSelection?.(selectedRows.value);
}

function toggleSort(column: Column) {
  if (!column.sortable || !props.enableSorting) return;
  
  const existingIndex = sorting.value.findIndex(s => s.column === column.id);
  
  if (existingIndex >= 0) {
    const existing = sorting.value[existingIndex];
    if (existing.direction === 'asc') {
      existing.direction = 'desc';
    } else {
      sorting.value.splice(existingIndex, 1);
    }
  } else {
    sorting.value.push({ column: column.id, direction: 'asc' });
  }
  
  if (props.onSort && sorting.value.length > 0) {
    const primary = sorting.value[0];
    props.onSort(primary.column, primary.direction);
  }
}

function getSortDirection(column: Column): SortDirection | null {
  const sort = sorting.value.find(s => s.column === column.id);
  return sort?.direction || null;
}

function handlePageChange(page: number) {
  currentPage.value = page;
  props.onPageChange?.(page);
}

function handlePageSizeChange(size: number) {
  currentPageSize.value = size;
  currentPage.value = 1;
  props.onPageSizeChange?.(size);
}

function handleBulkAction(action: BulkAction) {
  action.onClick(selectedRows.value);
  if (action.clearSelection !== false) {
    selectedRows.value = [];
  }
}

function handleExport(format: 'csv' | 'excel' | 'json') {
  const exportData = filteredData.value;
  
  switch (format) {
    case 'csv':
      exportToCSV(exportData, props.columns);
      break;
    case 'excel':
      exportToExcel(exportData, props.columns);
      break;
    case 'json':
      exportToJSON(exportData);
      break;
  }
  
  emit('export', { format, data: exportData });
}

function handleEdit(row: Row, column: string, value: any) {
  emit('edit', { row, column, value });
}

function handleAction(action: Action, row: Row) {
  action.onClick(row);
  emit('action', { action, row });
}

// Export utilities
function exportToCSV(data: Row[], columns: Column[]) {
  const headers = columns
    .filter(col => col.exportable !== false)
    .map(col => col.header);
  
  const rows = data.map(row =>
    columns
      .filter(col => col.exportable !== false)
      .map(col => {
        const value = row[col.id];
        if (col.exportFormatter) {
          return col.exportFormatter(value, row);
        }
        return value ?? '';
      })
  );
  
  const csv = [
    headers.join(','),
    ...rows.map(row => row.map(cell => `"${cell}"`).join(','))
  ].join('\n');
  
  downloadFile(csv, 'export.csv', 'text/csv');
}

function exportToJSON(data: Row[]) {
  const json = JSON.stringify(data, null, 2);
  downloadFile(json, 'export.json', 'application/json');
}

function downloadFile(content: string, filename: string, type: string) {
  const blob = new Blob([content], { type });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}
</script>

<!-- Table Row Component -->
<template>
  <tr
    :class="{
      selected: selected,
      'hover:bg-gray-50': true
    }"
    @click="handleRowClick"
  >
    <!-- Selection cell -->
    <td v-if="enableSelection" class="selection-cell">
      <input
        type="checkbox"
        :checked="selected"
        @change.stop="$emit('select')"
      />
    </td>
    
    <!-- Data cells -->
    <td
      v-for="column in columns"
      :key="column.id"
      :class="{
        'text-left': column.align === 'left',
        'text-center': column.align === 'center',
        'text-right': column.align === 'right',
        editable: enableInlineEdit && column.editable
      }"
      @dblclick="startEdit(column)"
    >
      <!-- Editing state -->
      <InlineEdit
        v-if="editingColumn === column.id"
        :value="row[column.id]"
        :type="column.editType || 'text'"
        :options="column.editOptions"
        @save="saveEdit"
        @cancel="cancelEdit"
      />
      
      <!-- Display state -->
      <CellRenderer
        v-else
        :column="column"
        :value="row[column.id]"
        :row="row"
      />
    </td>
    
    <!-- Actions cell -->
    <td v-if="actions && actions.length > 0" class="actions-cell">
      <div class="actions-menu">
        <button
          class="action-trigger"
          @click.stop="showActions = !showActions"
        >
          <MoreIcon />
        </button>
        
        <transition name="dropdown">
          <div
            v-if="showActions"
            class="actions-dropdown"
            @click.stop
          >
            <button
              v-for="action in actions"
              :key="action.id"
              class="action-item"
              :disabled="action.disabled?.(row)"
              @click="executeAction(action)"
            >
              <component :is="action.icon" v-if="action.icon" class="icon" />
              {{ action.label }}
            </button>
          </div>
        </transition>
      </div>
    </td>
  </tr>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import type { Column, Row, Action } from '@/types/table';

interface Props {
  row: Row;
  index: number;
  columns: Column[];
  actions?: Action[];
  enableSelection?: boolean;
  enableInlineEdit?: boolean;
  selected?: boolean;
}

const props = defineProps<Props>();
const emit = defineEmits(['select', 'edit', 'action']);

const editingColumn = ref<string | null>(null);
const showActions = ref(false);

function handleRowClick() {
  if (props.enableSelection) {
    emit('select');
  }
}

function startEdit(column: Column) {
  if (props.enableInlineEdit && column.editable) {
    editingColumn.value = column.id;
  }
}

function saveEdit(value: any) {
  if (editingColumn.value) {
    emit('edit', props.row, editingColumn.value, value);
    editingColumn.value = null;
  }
}

function cancelEdit() {
  editingColumn.value = null;
}

function executeAction(action: Action) {
  showActions.value = false;
  emit('action', action, props.row);
}
</script>
```

### Advanced Table Features
```typescript
// Cell renderers for different data types
export const cellRenderers = {
  // Badge renderer for status fields
  badge: (value: string, config: BadgeConfig) => {
    const variant = config.variants[value] || 'default';
    const color = config.colors[value] || 'gray';
    return `<Badge variant="${variant}" color="${color}">${value}</Badge>`;
  },
  
  // Progress bar renderer
  progress: (value: number, config: ProgressConfig) => {
    const percentage = Math.min(100, Math.max(0, value));
    const color = 
      percentage < 30 ? 'red' :
      percentage < 70 ? 'yellow' :
      'green';
    return `<Progress value="${percentage}" color="${color}" />`;
  },
  
  // Currency renderer
  currency: (value: number, config: CurrencyConfig) => {
    return new Intl.NumberFormat(config.locale || 'en-US', {
      style: 'currency',
      currency: config.currency || 'USD'
    }).format(value);
  },
  
  // Date renderer
  date: (value: string | Date, config: DateConfig) => {
    const date = new Date(value);
    if (config.relative) {
      return formatRelative(date);
    }
    return format(date, config.format || 'MMM d, yyyy');
  },
  
  // Link renderer
  link: (value: string, config: LinkConfig) => {
    const href = config.href || value;
    const target = config.external ? '_blank' : '_self';
    return `<a href="${href}" target="${target}">${value}</a>`;
  },
  
  // Avatar renderer
  avatar: (value: string, config: AvatarConfig) => {
    return `
      <div class="avatar-group">
        <img src="${value}" alt="" class="avatar" />
        ${config.showName ? `<span>${config.name}</span>` : ''}
      </div>
    `;
  },
  
  // Tags renderer
  tags: (value: string[], config: TagsConfig) => {
    return value.map(tag => 
      `<Tag size="${config.size || 'sm'}">${tag}</Tag>`
    ).join(' ');
  },
  
  // Boolean renderer
  boolean: (value: boolean, config: BooleanConfig) => {
    if (config.type === 'icon') {
      return value 
        ? '<CheckIcon class="text-green-500" />'
        : '<XIcon class="text-red-500" />';
    }
    return value ? config.trueLabel : config.falseLabel;
  }
};

// Advanced filtering
export class TableFilterEngine {
  applyFilters(data: any[], filters: FilterConfig[]): any[] {
    return data.filter(row => {
      return filters.every(filter => {
        const value = this.getNestedValue(row, filter.field);
        
        switch (filter.operator) {
          case 'equals':
            return value === filter.value;
          
          case 'not_equals':
            return value !== filter.value;
          
          case 'contains':
            return String(value).toLowerCase()
              .includes(String(filter.value).toLowerCase());
          
          case 'starts_with':
            return String(value).toLowerCase()
              .startsWith(String(filter.value).toLowerCase());
          
          case 'ends_with':
            return String(value).toLowerCase()
              .endsWith(String(filter.value).toLowerCase());
          
          case 'greater_than':
            return Number(value) > Number(filter.value);
          
          case 'less_than':
            return Number(value) < Number(filter.value);
          
          case 'between':
            const [min, max] = filter.value;
            const num = Number(value);
            return num >= Number(min) && num <= Number(max);
          
          case 'in':
            return filter.value.includes(value);
          
          case 'not_in':
            return !filter.value.includes(value);
          
          case 'is_empty':
            return !value || value === '';
          
          case 'is_not_empty':
            return value && value !== '';
          
          case 'before':
            return new Date(value) < new Date(filter.value);
          
          case 'after':
            return new Date(value) > new Date(filter.value);
          
          default:
            return true;
        }
      });
    });
  }
  
  private getNestedValue(obj: any, path: string): any {
    return path.split('.').reduce((acc, part) => acc?.[part], obj);
  }
}

// Row grouping
export class TableGroupingEngine {
  groupData(
    data: any[], 
    groupBy: string[], 
    aggregations: AggregationConfig[]
  ): GroupedData {
    const groups = new Map<string, any[]>();
    
    // Group data
    data.forEach(row => {
      const key = groupBy.map(field => row[field]).join('|');
      if (!groups.has(key)) {
        groups.set(key, []);
      }
      groups.get(key)!.push(row);
    });
    
    // Calculate aggregations
    const result: GroupedData = {
      groups: [],
      totals: {}
    };
    
    groups.forEach((rows, key) => {
      const groupValues = key.split('|');
      const group: DataGroup = {
        key,
        values: Object.fromEntries(
          groupBy.map((field, i) => [field, groupValues[i]])
        ),
        rows,
        aggregations: {}
      };
      
      // Calculate aggregations for this group
      aggregations.forEach(agg => {
        group.aggregations[agg.field] = this.aggregate(
          rows,
          agg.field,
          agg.function
        );
      });
      
      result.groups.push(group);
    });
    
    // Calculate totals
    aggregations.forEach(agg => {
      result.totals[agg.field] = this.aggregate(
        data,
        agg.field,
        agg.function
      );
    });
    
    return result;
  }
  
  private aggregate(
    rows: any[], 
    field: string, 
    fn: AggregationFunction
  ): any {
    const values = rows.map(row => row[field]).filter(v => v != null);
    
    switch (fn) {
      case 'sum':
        return values.reduce((sum, val) => sum + Number(val), 0);
      
      case 'avg':
        return values.length > 0
          ? values.reduce((sum, val) => sum + Number(val), 0) / values.length
          : 0;
      
      case 'min':
        return Math.min(...values.map(Number));
      
      case 'max':
        return Math.max(...values.map(Number));
      
      case 'count':
        return values.length;
      
      case 'distinct':
        return new Set(values).size;
      
      default:
        return null;
    }
  }
}
```

## Integration Points
- Receives column definitions from Schema Analyzer
- Coordinates with UI Component Builder for cell rendering
- Uses filter logic from Query Optimizer
- Implements sorting from Data Profiler patterns
- Integrates with Theme Customizer for styling

## Best Practices
1. Implement virtual scrolling for large datasets
2. Use server-side operations when possible
3. Provide keyboard navigation support
4. Cache sorting and filtering results
5. Implement responsive design patterns
6. Use optimistic updates for better UX
7. Provide clear loading and error states
8. Support accessibility standards
9. Enable column customization
10. Optimize render performance with memoization