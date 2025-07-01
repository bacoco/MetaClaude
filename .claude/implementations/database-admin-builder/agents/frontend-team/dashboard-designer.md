# Dashboard Designer Agent

## Purpose
Creates intelligent, data-driven dashboards with visualizations, metrics, and insights based on database content and business requirements.

## Capabilities

### Dashboard Features
- Key Performance Indicators (KPIs)
- Real-time metrics
- Interactive charts and graphs
- Data filtering and drill-down
- Custom widgets
- Responsive layouts
- Export functionality
- Scheduled reports

### Visualization Types
- Line charts (trends)
- Bar charts (comparisons)
- Pie/donut charts (distributions)
- Area charts (cumulative data)
- Scatter plots (correlations)
- Heat maps (density)
- Gauge charts (progress)
- Geographic maps
- Sankey diagrams
- Network graphs

## Dashboard Generation Strategy

### Automatic Metric Detection
```typescript
class MetricAnalyzer {
  analyzeSchema(schema: DatabaseSchema): DashboardMetrics {
    const metrics: DashboardMetrics = {
      counts: [],
      sums: [],
      averages: [],
      trends: [],
      distributions: [],
      relationships: []
    };
    
    // Analyze each table for potential metrics
    Object.entries(schema.tables).forEach(([tableName, table]) => {
      // Count metrics
      metrics.counts.push({
        id: `${tableName}_count`,
        name: `Total ${this.pluralize(tableName)}`,
        query: `SELECT COUNT(*) as value FROM ${tableName}`,
        icon: this.getTableIcon(tableName),
        format: 'number',
        trend: {
          query: `SELECT DATE_TRUNC('day', created_at) as date, COUNT(*) as value 
                  FROM ${tableName} 
                  WHERE created_at >= NOW() - INTERVAL '30 days'
                  GROUP BY date ORDER BY date`,
          type: 'line'
        }
      });
      
      // Analyze columns for aggregations
      Object.entries(table.columns).forEach(([columnName, column]) => {
        if (column.type === 'number' || column.type === 'decimal') {
          // Sum metrics for monetary values
          if (this.isMonetaryColumn(columnName)) {
            metrics.sums.push({
              id: `${tableName}_${columnName}_sum`,
              name: `Total ${this.humanize(columnName)}`,
              query: `SELECT SUM(${columnName}) as value FROM ${tableName}`,
              format: 'currency',
              icon: 'attach_money'
            });
          }
          
          // Average metrics
          metrics.averages.push({
            id: `${tableName}_${columnName}_avg`,
            name: `Average ${this.humanize(columnName)}`,
            query: `SELECT AVG(${columnName}) as value FROM ${tableName}`,
            format: column.format || 'number',
            precision: 2
          });
        }
        
        // Status distributions
        if (column.type === 'enum' || this.isStatusColumn(columnName)) {
          metrics.distributions.push({
            id: `${tableName}_${columnName}_distribution`,
            name: `${this.humanize(tableName)} by ${this.humanize(columnName)}`,
            query: `SELECT ${columnName} as label, COUNT(*) as value 
                    FROM ${tableName} 
                    GROUP BY ${columnName}`,
            type: 'pie',
            colorMap: this.getStatusColors(columnName)
          });
        }
        
        // Date-based trends
        if (column.type === 'date' || column.type === 'timestamp') {
          metrics.trends.push({
            id: `${tableName}_${columnName}_trend`,
            name: `${this.humanize(tableName)} Over Time`,
            query: `SELECT DATE_TRUNC('day', ${columnName}) as date, 
                           COUNT(*) as value 
                    FROM ${tableName} 
                    WHERE ${columnName} >= NOW() - INTERVAL '90 days'
                    GROUP BY date ORDER BY date`,
            type: 'area',
            timeRange: '90d'
          });
        }
      });
    });
    
    // Detect relationships for correlation charts
    schema.relationships.forEach(rel => {
      if (rel.type === 'one-to-many') {
        metrics.relationships.push({
          id: `${rel.from.table}_${rel.to.table}_correlation`,
          name: `${this.humanize(rel.from.table)} to ${this.humanize(rel.to.table)}`,
          query: `SELECT p.name as parent, COUNT(c.id) as count
                  FROM ${rel.from.table} p
                  LEFT JOIN ${rel.to.table} c ON p.id = c.${rel.to.column}
                  GROUP BY p.id, p.name
                  ORDER BY count DESC
                  LIMIT 10`,
          type: 'bar',
          orientation: 'horizontal'
        });
      }
    });
    
    return metrics;
  }
}
```

### Dashboard Layout Generation
```typescript
class DashboardLayoutGenerator {
  generateLayout(metrics: DashboardMetrics): DashboardLayout {
    const layout: DashboardLayout = {
      type: 'responsive-grid',
      rows: [],
      breakpoints: {
        lg: 1200,
        md: 996,
        sm: 768,
        xs: 480,
        xxs: 0
      },
      cols: { lg: 12, md: 10, sm: 6, xs: 4, xxs: 2 }
    };
    
    // Row 1: KPI Cards
    layout.rows.push({
      widgets: [
        ...metrics.counts.slice(0, 4).map((metric, index) => ({
          id: `kpi_${metric.id}`,
          type: 'kpi-card',
          metric: metric.id,
          layout: {
            x: index * 3,
            y: 0,
            w: 3,
            h: 2,
            minW: 2,
            minH: 2
          },
          config: {
            showTrend: true,
            trendPeriod: '7d',
            animation: true
          }
        }))
      ]
    });
    
    // Row 2: Main chart
    const primaryTrend = metrics.trends[0];
    if (primaryTrend) {
      layout.rows.push({
        widgets: [{
          id: 'main_trend_chart',
          type: 'time-series-chart',
          metric: primaryTrend.id,
          layout: {
            x: 0,
            y: 2,
            w: 8,
            h: 4,
            minW: 4,
            minH: 3
          },
          config: {
            showLegend: true,
            enableZoom: true,
            showTooltips: true,
            timeRangeSelector: true
          }
        }]
      });
    }
    
    // Add distribution chart
    const primaryDistribution = metrics.distributions[0];
    if (primaryDistribution) {
      layout.rows[1].widgets.push({
        id: 'distribution_chart',
        type: 'donut-chart',
        metric: primaryDistribution.id,
        layout: {
          x: 8,
          y: 2,
          w: 4,
          h: 4,
          minW: 3,
          minH: 3
        },
        config: {
          showLegend: true,
          showPercentages: true,
          animation: true
        }
      });
    }
    
    // Row 3: Secondary metrics
    layout.rows.push({
      widgets: [
        {
          id: 'data_table',
          type: 'data-table-widget',
          dataSource: 'recent_records',
          layout: {
            x: 0,
            y: 6,
            w: 6,
            h: 4,
            minW: 4,
            minH: 3
          },
          config: {
            pageSize: 10,
            sortable: true,
            searchable: true,
            exportable: true
          }
        },
        {
          id: 'activity_feed',
          type: 'activity-timeline',
          dataSource: 'recent_activities',
          layout: {
            x: 6,
            y: 6,
            w: 6,
            h: 4,
            minW: 3,
            minH: 3
          },
          config: {
            maxItems: 20,
            groupByDay: true,
            showAvatars: true
          }
        }
      ]
    });
    
    return layout;
  }
}
```

### React Dashboard Implementation
```tsx
// Auto-generated dashboard component
import React, { useState, useEffect } from 'react';
import { Responsive, WidthProvider } from 'react-grid-layout';
import { 
  LineChart, 
  BarChart, 
  PieChart,
  AreaChart,
  ComposedChart,
  ResponsiveContainer,
  CartesianGrid,
  XAxis,
  YAxis,
  Tooltip,
  Legend,
  Line,
  Bar,
  Area,
  Pie,
  Cell
} from 'recharts';
import { Card, CardContent, CardHeader, IconButton, Menu } from '@mui/material';
import { MoreVert, Download, Refresh, Fullscreen } from '@mui/icons-material';

const ResponsiveGridLayout = WidthProvider(Responsive);

// KPI Card Component
const KPICard: React.FC<KPICardProps> = ({ 
  title, 
  value, 
  trend, 
  format = 'number',
  icon,
  color = 'primary' 
}) => {
  const formatValue = (val: number) => {
    switch (format) {
      case 'currency':
        return new Intl.NumberFormat('en-US', {
          style: 'currency',
          currency: 'USD'
        }).format(val);
      
      case 'percentage':
        return `${(val * 100).toFixed(1)}%`;
      
      case 'number':
      default:
        return new Intl.NumberFormat('en-US').format(val);
    }
  };
  
  const trendDirection = trend?.value >= 0 ? 'up' : 'down';
  const trendColor = trend?.value >= 0 ? 'success' : 'error';
  
  return (
    <Card className="kpi-card" elevation={2}>
      <CardContent>
        <div className="kpi-header">
          <div className="kpi-icon" style={{ backgroundColor: `${color}.light` }}>
            {icon}
          </div>
          <IconButton size="small">
            <MoreVert />
          </IconButton>
        </div>
        
        <Typography variant="h3" className="kpi-value">
          {formatValue(value)}
        </Typography>
        
        <Typography variant="subtitle2" color="textSecondary">
          {title}
        </Typography>
        
        {trend && (
          <div className={`kpi-trend ${trendDirection}`}>
            <TrendingUpIcon 
              className={`trend-icon ${trendColor}`} 
              style={{
                transform: trendDirection === 'down' ? 'rotate(180deg)' : 'none'
              }}
            />
            <Typography variant="body2" color={trendColor}>
              {Math.abs(trend.value)}% {trend.period}
            </Typography>
          </div>
        )}
      </CardContent>
    </Card>
  );
};

// Time Series Chart Widget
const TimeSeriesChart: React.FC<TimeSeriesChartProps> = ({
  data,
  title,
  lines,
  timeRange,
  onTimeRangeChange
}) => {
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  
  const timeRanges = [
    { label: 'Last 24 hours', value: '24h' },
    { label: 'Last 7 days', value: '7d' },
    { label: 'Last 30 days', value: '30d' },
    { label: 'Last 90 days', value: '90d' },
    { label: 'Last year', value: '1y' }
  ];
  
  return (
    <Card className="chart-widget">
      <CardHeader
        title={title}
        action={
          <div className="chart-actions">
            <Select
              size="small"
              value={timeRange}
              onChange={(e) => onTimeRangeChange(e.target.value)}
            >
              {timeRanges.map(range => (
                <MenuItem key={range.value} value={range.value}>
                  {range.label}
                </MenuItem>
              ))}
            </Select>
            
            <IconButton size="small">
              <Refresh />
            </IconButton>
            
            <IconButton size="small">
              <Download />
            </IconButton>
            
            <IconButton size="small">
              <Fullscreen />
            </IconButton>
          </div>
        }
      />
      
      <CardContent>
        <ResponsiveContainer width="100%" height={300}>
          <LineChart data={data}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis 
              dataKey="date" 
              tickFormatter={(date) => 
                new Date(date).toLocaleDateString('en-US', {
                  month: 'short',
                  day: 'numeric'
                })
              }
            />
            <YAxis />
            <Tooltip 
              formatter={(value: number) => 
                new Intl.NumberFormat('en-US').format(value)
              }
              labelFormatter={(label) => 
                new Date(label).toLocaleDateString('en-US', {
                  weekday: 'long',
                  year: 'numeric',
                  month: 'long',
                  day: 'numeric'
                })
              }
            />
            <Legend />
            
            {lines.map((line, index) => (
              <Line
                key={line.key}
                type="monotone"
                dataKey={line.key}
                stroke={line.color || CHART_COLORS[index]}
                strokeWidth={2}
                dot={false}
                name={line.name}
              />
            ))}
          </LineChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  );
};

// Main Dashboard Component
export const Dashboard: React.FC<DashboardProps> = ({ 
  config,
  filters,
  onFilterChange 
}) => {
  const [widgets, setWidgets] = useState([]);
  const [loading, setLoading] = useState(true);
  const [refreshInterval, setRefreshInterval] = useState(30000); // 30 seconds
  
  // Fetch dashboard data
  const fetchDashboardData = async () => {
    setLoading(true);
    
    try {
      const widgetPromises = config.widgets.map(widget => 
        api.get(`/dashboard/widgets/${widget.id}/data`, {
          params: { ...filters }
        })
      );
      
      const responses = await Promise.all(widgetPromises);
      
      const widgetData = config.widgets.map((widget, index) => ({
        ...widget,
        data: responses[index].data
      }));
      
      setWidgets(widgetData);
    } catch (error) {
      console.error('Failed to fetch dashboard data:', error);
    } finally {
      setLoading(false);
    }
  };
  
  // Auto-refresh
  useEffect(() => {
    fetchDashboardData();
    
    const interval = setInterval(fetchDashboardData, refreshInterval);
    
    return () => clearInterval(interval);
  }, [filters, refreshInterval]);
  
  // Render widget based on type
  const renderWidget = (widget: Widget) => {
    switch (widget.type) {
      case 'kpi-card':
        return (
          <KPICard
            title={widget.data.title}
            value={widget.data.value}
            trend={widget.data.trend}
            format={widget.config.format}
            icon={widget.config.icon}
          />
        );
      
      case 'time-series-chart':
        return (
          <TimeSeriesChart
            data={widget.data.series}
            title={widget.data.title}
            lines={widget.config.lines}
            timeRange={widget.config.timeRange}
            onTimeRangeChange={(range) => 
              updateWidget(widget.id, { timeRange: range })
            }
          />
        );
      
      case 'donut-chart':
        return (
          <DonutChart
            data={widget.data.distribution}
            title={widget.data.title}
            colors={widget.config.colors}
          />
        );
      
      case 'data-table-widget':
        return (
          <DataTableWidget
            columns={widget.data.columns}
            rows={widget.data.rows}
            title={widget.data.title}
            pageSize={widget.config.pageSize}
          />
        );
      
      default:
        return <div>Unknown widget type: {widget.type}</div>;
    }
  };
  
  return (
    <div className="dashboard">
      <DashboardHeader
        title={config.title}
        filters={filters}
        onFilterChange={onFilterChange}
        onRefresh={fetchDashboardData}
        onExport={() => exportDashboard(widgets)}
      />
      
      {loading ? (
        <DashboardSkeleton />
      ) : (
        <ResponsiveGridLayout
          className="layout"
          layouts={config.layouts}
          breakpoints={config.breakpoints}
          cols={config.cols}
          rowHeight={60}
          isDraggable={config.editable}
          isResizable={config.editable}
          onLayoutChange={(layout) => 
            config.editable && saveLayout(layout)
          }
        >
          {widgets.map(widget => (
            <div key={widget.id} data-grid={widget.layout}>
              {renderWidget(widget)}
            </div>
          ))}
        </ResponsiveGridLayout>
      )}
    </div>
  );
};
```

### Dashboard Configuration
```typescript
// Dashboard configuration generator
class DashboardConfigurator {
  generateConfig(schema: DatabaseSchema, requirements: Requirements): DashboardConfig {
    const analyzer = new MetricAnalyzer();
    const metrics = analyzer.analyzeSchema(schema);
    
    const layoutGenerator = new DashboardLayoutGenerator();
    const layout = layoutGenerator.generateLayout(metrics);
    
    return {
      id: 'main-dashboard',
      title: requirements.dashboardTitle || 'Admin Dashboard',
      description: 'Auto-generated dashboard based on your data',
      
      widgets: this.selectBestWidgets(metrics, requirements),
      
      layout,
      
      filters: [
        {
          id: 'date_range',
          type: 'date_range',
          label: 'Date Range',
          defaultValue: 'last_30_days',
          options: [
            { value: 'today', label: 'Today' },
            { value: 'yesterday', label: 'Yesterday' },
            { value: 'last_7_days', label: 'Last 7 days' },
            { value: 'last_30_days', label: 'Last 30 days' },
            { value: 'last_90_days', label: 'Last 90 days' },
            { value: 'custom', label: 'Custom range' }
          ]
        }
      ],
      
      refresh: {
        enabled: true,
        interval: 30000,
        options: [
          { value: 10000, label: '10 seconds' },
          { value: 30000, label: '30 seconds' },
          { value: 60000, label: '1 minute' },
          { value: 300000, label: '5 minutes' },
          { value: 0, label: 'Disabled' }
        ]
      },
      
      export: {
        formats: ['pdf', 'excel', 'csv', 'png'],
        scheduled: requirements.scheduledReports || false
      },
      
      permissions: {
        view: ['admin', 'manager', 'analyst'],
        edit: ['admin'],
        export: ['admin', 'manager']
      },
      
      theme: {
        palette: 'auto', // light, dark, auto
        primaryColor: requirements.brandColor || '#1976d2',
        chartColors: [
          '#1976d2', '#dc004e', '#f57c00', '#388e3c',
          '#7b1fa2', '#c2185b', '#0288d1', '#fbc02d'
        ]
      }
    };
  }
  
  selectBestWidgets(metrics: DashboardMetrics, requirements: Requirements): Widget[] {
    const widgets: Widget[] = [];
    
    // Priority 1: KPIs (up to 4)
    const kpis = [
      ...metrics.counts.filter(m => requirements.importantTables?.includes(m.table)),
      ...metrics.sums.filter(m => m.format === 'currency'),
      ...metrics.counts
    ].slice(0, 4);
    
    widgets.push(...kpis.map(kpi => this.createKPIWidget(kpi)));
    
    // Priority 2: Main trend chart
    const mainTrend = metrics.trends.find(t => 
      requirements.importantTables?.includes(t.table)
    ) || metrics.trends[0];
    
    if (mainTrend) {
      widgets.push(this.createTrendWidget(mainTrend));
    }
    
    // Priority 3: Distribution chart
    const distribution = metrics.distributions.find(d => 
      d.name.toLowerCase().includes('status') ||
      d.name.toLowerCase().includes('type')
    ) || metrics.distributions[0];
    
    if (distribution) {
      widgets.push(this.createDistributionWidget(distribution));
    }
    
    // Priority 4: Recent records table
    if (requirements.showRecentRecords !== false) {
      widgets.push(this.createRecentRecordsWidget(
        requirements.importantTables?.[0] || 'orders'
      ));
    }
    
    // Priority 5: Activity timeline
    if (requirements.showActivityFeed !== false) {
      widgets.push(this.createActivityWidget());
    }
    
    return widgets;
  }
}
```

## Integration Points
- Receives metrics from Data Profiler
- Uses components from UI Component Builder
- Implements real-time data from API endpoints
- Coordinates with Theme Customizer for styling

## Best Practices
1. Prioritize most important metrics
2. Keep dashboards focused and uncluttered
3. Use consistent color schemes
4. Implement proper data caching
5. Ensure responsive design
6. Add export functionality
7. Include refresh controls