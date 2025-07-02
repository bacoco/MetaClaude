# Table Builder - React TypeScript Implementation

## Complete DataTable Component

```typescript
import React, { useState, useMemo, useCallback, useEffect } from 'react';
import { 
  flexRender,
  getCoreRowModel,
  getFilteredRowModel,
  getPaginationRowModel,
  getSortedRowModel,
  useReactTable,
  ColumnDef,
  SortingState,
  FilterFn,
  ColumnFiltersState
} from '@tanstack/react-table';
import { ChevronUp, ChevronDown, Search, Download } from 'lucide-react';

interface DataTableProps<T> {
  data: T[];
  columns: ColumnDef<T>[];
  pageSize?: number;
  enableSorting?: boolean;
  enableFiltering?: boolean;
  enablePagination?: boolean;
  enableSelection?: boolean;
  enableExport?: boolean;
  onRowClick?: (row: T) => void;
  onSelectionChange?: (selectedRows: T[]) => void;
}

export function DataTable<T extends Record<string, any>>({
  data,
  columns,
  pageSize = 10,
  enableSorting = true,
  enableFiltering = true,
  enablePagination = true,
  enableSelection = false,
  enableExport = false,
  onRowClick,
  onSelectionChange
}: DataTableProps<T>) {
  const [sorting, setSorting] = useState<SortingState>([]);
  const [columnFilters, setColumnFilters] = useState<ColumnFiltersState>([]);
  const [globalFilter, setGlobalFilter] = useState('');
  const [rowSelection, setRowSelection] = useState({});

  // Add selection column if enabled
  const tableColumns = useMemo(() => {
    if (enableSelection) {
      return [
        {
          id: 'select',
          header: ({ table }) => (
            <input
              type="checkbox"
              checked={table.getIsAllPageRowsSelected()}
              onChange={table.getToggleAllPageRowsSelectedHandler()}
              className="w-4 h-4 rounded border-gray-300"
            />
          ),
          cell: ({ row }) => (
            <input
              type="checkbox"
              checked={row.getIsSelected()}
              onChange={row.getToggleSelectedHandler()}
              className="w-4 h-4 rounded border-gray-300"
            />
          ),
          size: 40,
        },
        ...columns
      ];
    }
    return columns;
  }, [columns, enableSelection]);

  const table = useReactTable({
    data,
    columns: tableColumns,
    state: {
      sorting,
      columnFilters,
      globalFilter,
      rowSelection
    },
    onSortingChange: setSorting,
    onColumnFiltersChange: setColumnFilters,
    onGlobalFilterChange: setGlobalFilter,
    onRowSelectionChange: setRowSelection,
    getCoreRowModel: getCoreRowModel(),
    getSortedRowModel: enableSorting ? getSortedRowModel() : undefined,
    getFilteredRowModel: enableFiltering ? getFilteredRowModel() : undefined,
    getPaginationRowModel: enablePagination ? getPaginationRowModel() : undefined,
    initialState: {
      pagination: {
        pageSize
      }
    }
  });

  // Handle selection changes
  useEffect(() => {
    if (onSelectionChange && enableSelection) {
      const selectedRows = table.getSelectedRowModel().rows.map(row => row.original);
      onSelectionChange(selectedRows);
    }
  }, [rowSelection, onSelectionChange, enableSelection]);

  // Export functionality
  const handleExport = useCallback(() => {
    const visibleData = table.getFilteredRowModel().rows.map(row => row.original);
    const csv = convertToCSV(visibleData);
    downloadCSV(csv, 'table-export.csv');
  }, [table]);

  return (
    <div className="w-full space-y-4">
      {/* Header Actions */}
      <div className="flex items-center justify-between">
        {enableFiltering && (
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
            <input
              type="text"
              value={globalFilter}
              onChange={(e) => setGlobalFilter(e.target.value)}
              placeholder="Search all columns..."
              className="pl-10 pr-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
        )}
        
        {enableExport && (
          <button
            onClick={handleExport}
            className="flex items-center gap-2 px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600"
          >
            <Download className="h-4 w-4" />
            Export
          </button>
        )}
      </div>

      {/* Table */}
      <div className="overflow-x-auto border rounded-lg">
        <table className="w-full">
          <thead className="bg-gray-50 border-b">
            {table.getHeaderGroups().map(headerGroup => (
              <tr key={headerGroup.id}>
                {headerGroup.headers.map(header => (
                  <th
                    key={header.id}
                    className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                  >
                    {header.isPlaceholder ? null : (
                      <div
                        className={`flex items-center gap-2 ${
                          header.column.getCanSort() ? 'cursor-pointer select-none' : ''
                        }`}
                        onClick={header.column.getToggleSortingHandler()}
                      >
                        {flexRender(header.column.columnDef.header, header.getContext())}
                        {header.column.getCanSort() && (
                          <span className="text-gray-400">
                            {header.column.getIsSorted() === 'asc' ? (
                              <ChevronUp className="h-4 w-4" />
                            ) : header.column.getIsSorted() === 'desc' ? (
                              <ChevronDown className="h-4 w-4" />
                            ) : (
                              <div className="h-4 w-4" />
                            )}
                          </span>
                        )}
                      </div>
                    )}
                  </th>
                ))}
              </tr>
            ))}
          </thead>
          
          <tbody className="bg-white divide-y divide-gray-200">
            {table.getRowModel().rows.map(row => (
              <tr
                key={row.id}
                className={`${
                  onRowClick ? 'cursor-pointer hover:bg-gray-50' : ''
                } ${row.getIsSelected() ? 'bg-blue-50' : ''}`}
                onClick={() => onRowClick?.(row.original)}
              >
                {row.getVisibleCells().map(cell => (
                  <td key={cell.id} className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {flexRender(cell.column.columnDef.cell, cell.getContext())}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      {enablePagination && (
        <div className="flex items-center justify-between">
          <div className="text-sm text-gray-700">
            Showing {table.getState().pagination.pageIndex * pageSize + 1} to{' '}
            {Math.min(
              (table.getState().pagination.pageIndex + 1) * pageSize,
              data.length
            )}{' '}
            of {data.length} results
          </div>
          
          <div className="flex gap-2">
            <button
              onClick={() => table.previousPage()}
              disabled={!table.getCanPreviousPage()}
              className="px-4 py-2 border rounded-lg disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-50"
            >
              Previous
            </button>
            <button
              onClick={() => table.nextPage()}
              disabled={!table.getCanNextPage()}
              className="px-4 py-2 border rounded-lg disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-50"
            >
              Next
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

// Utility functions
function convertToCSV(data: any[]): string {
  if (data.length === 0) return '';
  
  const headers = Object.keys(data[0]);
  const csvHeaders = headers.join(',');
  
  const csvRows = data.map(row => 
    headers.map(header => {
      const value = row[header];
      return typeof value === 'string' && value.includes(',') 
        ? `"${value}"` 
        : value;
    }).join(',')
  );
  
  return [csvHeaders, ...csvRows].join('\\n');
}

function downloadCSV(csv: string, filename: string) {
  const blob = new Blob([csv], { type: 'text/csv' });
  const url = window.URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
  window.URL.revokeObjectURL(url);
}
```

## Column Definitions Generator

```typescript
interface FieldDefinition {
  name: string;
  type: string;
  nullable: boolean;
  primaryKey?: boolean;
  foreignKey?: string;
  unique?: boolean;
  defaultValue?: any;
}

export function generateTableColumns(
  entity: { name: string; fields: FieldDefinition[] },
  options: { enableActions?: boolean; enableInlineEdit?: boolean }
): ColumnDef<any>[] {
  const columns: ColumnDef<any>[] = entity.fields
    .filter(field => !field.primaryKey || options.enableInlineEdit)
    .map(field => ({
      accessorKey: field.name,
      header: formatFieldName(field.name),
      cell: ({ getValue, row, column, table }) => {
        const value = getValue();
        
        // Handle different field types
        switch (field.type) {
          case 'boolean':
            return (
              <span className={`px-2 py-1 rounded-full text-xs ${
                value ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'
              }`}>
                {value ? 'Yes' : 'No'}
              </span>
            );
            
          case 'date':
          case 'datetime':
            return value ? new Date(value).toLocaleDateString() : '-';
            
          case 'decimal':
          case 'money':
            return value ? `$${parseFloat(value).toFixed(2)}` : '-';
            
          case 'email':
            return value ? (
              <a href={`mailto:${value}`} className="text-blue-600 hover:underline">
                {value}
              </a>
            ) : '-';
            
          case 'url':
            return value ? (
              <a href={value} target="_blank" rel="noopener noreferrer" 
                 className="text-blue-600 hover:underline">
                {value}
              </a>
            ) : '-';
            
          case 'json':
            return (
              <pre className="text-xs bg-gray-100 p-1 rounded">
                {JSON.stringify(value, null, 2)}
              </pre>
            );
            
          default:
            return value?.toString() || '-';
        }
      },
      filterFn: getFilterFunction(field.type),
      sortingFn: getSortingFunction(field.type),
      size: getColumnWidth(field)
    }));

  // Add actions column if enabled
  if (options.enableActions) {
    columns.push({
      id: 'actions',
      header: 'Actions',
      cell: ({ row }) => (
        <div className="flex gap-2">
          <button className="text-blue-600 hover:underline text-sm">Edit</button>
          <button className="text-red-600 hover:underline text-sm">Delete</button>
        </div>
      ),
      size: 100
    });
  }

  return columns;
}

// Helper functions
function formatFieldName(fieldName: string): string {
  return fieldName
    .replace(/_/g, ' ')
    .replace(/([a-z])([A-Z])/g, '$1 $2')
    .replace(/\\b\\w/g, l => l.toUpperCase());
}

function getFilterFunction(fieldType: string): FilterFn<any> | undefined {
  switch (fieldType) {
    case 'number':
    case 'decimal':
    case 'money':
      return 'inNumberRange';
    case 'date':
    case 'datetime':
      return 'inDateRange';
    default:
      return 'includesString';
  }
}

function getSortingFunction(fieldType: string) {
  switch (fieldType) {
    case 'date':
    case 'datetime':
      return 'datetime';
    case 'number':
    case 'decimal':
    case 'money':
      return 'alphanumeric';
    default:
      return 'text';
  }
}

function getColumnWidth(field: FieldDefinition): number {
  switch (field.type) {
    case 'boolean': return 80;
    case 'date': return 120;
    case 'datetime': return 150;
    case 'email': return 200;
    case 'url': return 250;
    case 'text': return 300;
    default: return 150;
  }
}
```

## Virtual Scrolling for Large Datasets

```typescript
import { useVirtualizer } from '@tanstack/react-virtual';

export function VirtualizedTable<T>({ 
  data, 
  columns,
  rowHeight = 50 
}: { 
  data: T[]; 
  columns: ColumnDef<T>[];
  rowHeight?: number;
}) {
  const parentRef = useRef<HTMLDivElement>(null);
  
  const table = useReactTable({
    data,
    columns,
    getCoreRowModel: getCoreRowModel(),
  });

  const { rows } = table.getRowModel();

  const virtualizer = useVirtualizer({
    count: rows.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => rowHeight,
    overscan: 10,
  });

  return (
    <div ref={parentRef} className="h-[600px] overflow-auto">
      <div style={{ height: `${virtualizer.getTotalSize()}px`, position: 'relative' }}>
        {virtualizer.getVirtualItems().map((virtualRow) => {
          const row = rows[virtualRow.index];
          return (
            <div
              key={row.id}
              style={{
                position: 'absolute',
                top: 0,
                left: 0,
                width: '100%',
                height: `${virtualRow.size}px`,
                transform: `translateY(${virtualRow.start}px)`,
              }}
            >
              <div className="flex">
                {row.getVisibleCells().map((cell) => (
                  <div key={cell.id} className="flex-1 p-2">
                    {flexRender(cell.column.columnDef.cell, cell.getContext())}
                  </div>
                ))}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
```

---

*Full implementation examples - Load only when needed*