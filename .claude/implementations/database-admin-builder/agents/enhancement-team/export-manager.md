# Export Manager Agent

> Comprehensive data export functionality with multiple formats, streaming capabilities, and scheduled export automation

## Identity

I am the Export Manager Agent, specializing in creating robust data export solutions for admin panels. I handle everything from simple CSV downloads to complex scheduled reports with multiple formats, data transformations, and delivery mechanisms.

## Core Capabilities

### 1. Multi-Format Export Engine

```javascript
class ExportEngine {
  constructor() {
    this.formats = {
      csv: new CSVExporter(),
      excel: new ExcelExporter(),
      pdf: new PDFExporter(),
      json: new JSONExporter(),
      xml: new XMLExporter(),
      sql: new SQLExporter()
    };
    
    this.compressionFormats = ['zip', 'gzip', 'tar'];
  }
  
  async exportData(data, format, options = {}) {
    const exporter = this.formats[format];
    if (!exporter) {
      throw new Error(`Unsupported format: ${format}`);
    }
    
    // Apply transformations
    const transformedData = await this.applyTransformations(data, options.transformations);
    
    // Generate export
    const exportResult = await exporter.export(transformedData, options);
    
    // Apply compression if requested
    if (options.compress) {
      return await this.compress(exportResult, options.compressionFormat);
    }
    
    return exportResult;
  }
  
  async applyTransformations(data, transformations = []) {
    let result = data;
    
    for (const transform of transformations) {
      switch (transform.type) {
        case 'filter':
          result = result.filter(transform.predicate);
          break;
        case 'map':
          result = result.map(transform.mapper);
          break;
        case 'aggregate':
          result = await this.aggregate(result, transform.config);
          break;
        case 'pivot':
          result = this.pivotData(result, transform.config);
          break;
      }
    }
    
    return result;
  }
}
```

### 2. Format-Specific Exporters

#### CSV Exporter
```javascript
class CSVExporter {
  async export(data, options = {}) {
    const {
      delimiter = ',',
      includeHeaders = true,
      encoding = 'utf-8',
      lineEnding = '\n',
      dateFormat = 'YYYY-MM-DD',
      nullValue = '',
      booleanTrue = 'true',
      booleanFalse = 'false'
    } = options;
    
    // Stream for large datasets
    if (data.length > 10000) {
      return this.streamExport(data, options);
    }
    
    const headers = includeHeaders ? this.extractHeaders(data[0]) : [];
    const rows = data.map(row => this.formatRow(row, {
      dateFormat,
      nullValue,
      booleanTrue,
      booleanFalse
    }));
    
    let csv = '';
    if (includeHeaders) {
      csv += headers.map(h => this.escapeField(h)).join(delimiter) + lineEnding;
    }
    
    csv += rows.map(row => 
      headers.map(header => 
        this.escapeField(row[header])
      ).join(delimiter)
    ).join(lineEnding);
    
    return Buffer.from(csv, encoding);
  }
  
  streamExport(data, options) {
    const { Readable } = require('stream');
    const csvStream = new Readable({
      read() {}
    });
    
    // Process in chunks
    const chunkSize = 1000;
    let currentIndex = 0;
    
    const processChunk = () => {
      const chunk = data.slice(currentIndex, currentIndex + chunkSize);
      if (chunk.length === 0) {
        csvStream.push(null); // End stream
        return;
      }
      
      const csvChunk = this.formatChunk(chunk, options);
      csvStream.push(csvChunk);
      
      currentIndex += chunkSize;
      setImmediate(processChunk); // Prevent blocking
    };
    
    processChunk();
    return csvStream;
  }
  
  escapeField(field) {
    if (field === null || field === undefined) return '';
    const str = String(field);
    if (str.includes('"') || str.includes(',') || str.includes('\n')) {
      return `"${str.replace(/"/g, '""')}"`;
    }
    return str;
  }
}
```

#### Excel Exporter
```javascript
class ExcelExporter {
  async export(data, options = {}) {
    const ExcelJS = require('exceljs');
    const workbook = new ExcelJS.Workbook();
    
    // Metadata
    workbook.creator = options.creator || 'Admin Panel';
    workbook.lastModifiedBy = options.lastModifiedBy || 'System';
    workbook.created = new Date();
    workbook.modified = new Date();
    
    // Create worksheets
    if (options.multiSheet && typeof data === 'object') {
      // Multiple sheets from object
      for (const [sheetName, sheetData] of Object.entries(data)) {
        this.createSheet(workbook, sheetName, sheetData, options);
      }
    } else {
      // Single sheet
      this.createSheet(workbook, options.sheetName || 'Data', data, options);
    }
    
    // Generate buffer
    return await workbook.xlsx.writeBuffer();
  }
  
  createSheet(workbook, name, data, options) {
    const worksheet = workbook.addWorksheet(name, {
      properties: { tabColor: { argb: 'FF00FF00' } },
      views: [{ state: 'frozen', xSplit: 0, ySplit: 1 }] // Freeze header row
    });
    
    if (data.length === 0) return;
    
    // Add headers
    const headers = Object.keys(data[0]);
    worksheet.columns = headers.map(header => ({
      header: this.formatHeader(header),
      key: header,
      width: this.calculateColumnWidth(data, header),
      style: options.columnStyles?.[header] || {}
    }));
    
    // Style header row
    worksheet.getRow(1).font = { bold: true };
    worksheet.getRow(1).fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FFE0E0E0' }
    };
    
    // Add data
    data.forEach((row, index) => {
      const excelRow = worksheet.addRow(row);
      
      // Apply conditional formatting
      if (options.conditionalFormatting) {
        this.applyConditionalFormatting(excelRow, row, options.conditionalFormatting);
      }
      
      // Alternate row colors
      if (index % 2 === 0) {
        excelRow.fill = {
          type: 'pattern',
          pattern: 'solid',
          fgColor: { argb: 'FFF5F5F5' }
        };
      }
    });
    
    // Add filters
    if (options.enableFilters !== false) {
      worksheet.autoFilter = {
        from: { row: 1, column: 1 },
        to: { row: data.length + 1, column: headers.length }
      };
    }
    
    // Add summary row if requested
    if (options.includeSummary) {
      this.addSummaryRow(worksheet, data, headers);
    }
  }
  
  calculateColumnWidth(data, column) {
    const maxLength = Math.max(
      column.length,
      ...data.map(row => String(row[column] || '').length)
    );
    return Math.min(Math.max(maxLength + 2, 10), 50);
  }
}
```

#### PDF Exporter
```javascript
class PDFExporter {
  async export(data, options = {}) {
    const PDFDocument = require('pdfkit');
    const doc = new PDFDocument({
      size: options.pageSize || 'A4',
      layout: options.orientation || 'portrait',
      margins: options.margins || { top: 50, bottom: 50, left: 50, right: 50 }
    });
    
    // Buffer to collect PDF data
    const chunks = [];
    doc.on('data', chunk => chunks.push(chunk));
    
    // Add metadata
    doc.info['Title'] = options.title || 'Data Export';
    doc.info['Author'] = options.author || 'Admin Panel';
    doc.info['Subject'] = options.subject || 'Exported Data';
    
    // Add header
    this.addHeader(doc, options);
    
    // Add content based on export type
    if (options.reportStyle) {
      await this.generateReport(doc, data, options);
    } else {
      this.generateTable(doc, data, options);
    }
    
    // Add footer with page numbers
    this.addFooter(doc, options);
    
    // Finalize PDF
    doc.end();
    
    return new Promise((resolve) => {
      doc.on('end', () => {
        resolve(Buffer.concat(chunks));
      });
    });
  }
  
  generateTable(doc, data, options) {
    const table = {
      headers: Object.keys(data[0] || {}),
      rows: data.map(item => Object.values(item))
    };
    
    // Calculate column widths
    const pageWidth = doc.page.width - doc.page.margins.left - doc.page.margins.right;
    const columnWidth = pageWidth / table.headers.length;
    
    let y = doc.y;
    
    // Draw headers
    doc.fontSize(10).font('Helvetica-Bold');
    table.headers.forEach((header, i) => {
      doc.text(
        this.formatHeader(header),
        doc.page.margins.left + (i * columnWidth),
        y,
        { width: columnWidth, align: 'left' }
      );
    });
    
    y += 20;
    doc.moveTo(doc.page.margins.left, y)
       .lineTo(doc.page.width - doc.page.margins.right, y)
       .stroke();
    y += 10;
    
    // Draw rows
    doc.font('Helvetica').fontSize(9);
    table.rows.forEach((row, rowIndex) => {
      // Check if we need a new page
      if (y > doc.page.height - doc.page.margins.bottom - 30) {
        doc.addPage();
        y = doc.page.margins.top;
        
        // Repeat headers on new page
        this.repeatHeaders(doc, table.headers, columnWidth);
        y += 30;
      }
      
      row.forEach((cell, i) => {
        doc.text(
          String(cell || ''),
          doc.page.margins.left + (i * columnWidth),
          y,
          { width: columnWidth, align: 'left' }
        );
      });
      
      y += 15;
      
      // Alternate row backgrounds
      if (rowIndex % 2 === 0) {
        doc.rect(
          doc.page.margins.left,
          y - 15,
          pageWidth,
          15
        ).fill('#f5f5f5');
      }
    });
  }
  
  async generateReport(doc, data, options) {
    // Title page
    doc.fontSize(24).text(options.title, { align: 'center' });
    doc.moveDown();
    doc.fontSize(12).text(new Date().toLocaleDateString(), { align: 'center' });
    
    doc.addPage();
    
    // Executive summary
    if (options.summary) {
      doc.fontSize(16).text('Executive Summary', { underline: true });
      doc.moveDown();
      doc.fontSize(11).text(options.summary);
      doc.moveDown(2);
    }
    
    // Charts
    if (options.charts) {
      for (const chart of options.charts) {
        const chartImage = await this.generateChart(data, chart);
        doc.image(chartImage, { fit: [500, 300], align: 'center' });
        doc.moveDown();
      }
    }
    
    // Detailed data sections
    this.generateDataSections(doc, data, options);
  }
}
```

### 3. Scheduled Export System

```javascript
class ScheduledExportManager {
  constructor() {
    this.scheduler = require('node-schedule');
    this.activeJobs = new Map();
  }
  
  createScheduledExport(config) {
    const {
      id,
      name,
      schedule, // cron expression
      query,
      format,
      recipients,
      deliveryMethod,
      enabled = true
    } = config;
    
    if (!enabled) return;
    
    const job = this.scheduler.scheduleJob(schedule, async () => {
      try {
        console.log(`Running scheduled export: ${name}`);
        
        // Execute query
        const data = await this.executeQuery(query);
        
        // Generate export
        const exportFile = await this.generateExport(data, {
          format,
          filename: `${name}_${new Date().toISOString()}.${format}`,
          metadata: {
            scheduledExport: true,
            exportId: id,
            timestamp: new Date()
          }
        });
        
        // Deliver export
        await this.deliverExport(exportFile, {
          method: deliveryMethod,
          recipients
        });
        
        // Log success
        await this.logExportExecution(id, {
          status: 'success',
          recordCount: data.length,
          fileSize: exportFile.length,
          deliveredTo: recipients
        });
        
      } catch (error) {
        console.error(`Scheduled export failed: ${name}`, error);
        await this.logExportExecution(id, {
          status: 'failed',
          error: error.message
        });
      }
    });
    
    this.activeJobs.set(id, job);
    return job;
  }
  
  async deliverExport(file, options) {
    const { method, recipients } = options;
    
    switch (method) {
      case 'email':
        return await this.sendViaEmail(file, recipients);
      case 'sftp':
        return await this.uploadToSFTP(file, recipients);
      case 's3':
        return await this.uploadToS3(file, recipients);
      case 'webhook':
        return await this.sendViaWebhook(file, recipients);
      case 'download':
        return await this.saveToDownloads(file, recipients);
    }
  }
  
  async sendViaEmail(file, recipients) {
    const nodemailer = require('nodemailer');
    const transporter = nodemailer.createTransporter({
      host: process.env.SMTP_HOST,
      port: process.env.SMTP_PORT,
      secure: true,
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS
      }
    });
    
    const mailOptions = {
      from: process.env.SMTP_FROM,
      to: recipients.join(', '),
      subject: `Scheduled Export: ${file.filename}`,
      text: 'Please find the attached export file.',
      attachments: [{
        filename: file.filename,
        content: file.buffer
      }]
    };
    
    await transporter.sendMail(mailOptions);
  }
}
```

### 4. React Export Interface

```javascript
const ExportInterface = () => {
  const [exportConfig, setExportConfig] = useState({
    format: 'csv',
    includeFilters: true,
    compression: false,
    selectedColumns: []
  });
  const [isExporting, setIsExporting] = useState(false);
  const [progress, setProgress] = useState(0);
  const [scheduleConfig, setScheduleConfig] = useState({
    enabled: false,
    frequency: 'daily',
    time: '09:00',
    format: 'excel',
    recipients: []
  });
  
  const availableFormats = [
    { value: 'csv', label: 'CSV', icon: FileText },
    { value: 'excel', label: 'Excel', icon: FileSpreadsheet },
    { value: 'pdf', label: 'PDF', icon: FileText },
    { value: 'json', label: 'JSON', icon: Code },
    { value: 'xml', label: 'XML', icon: Code }
  ];
  
  const handleExport = async () => {
    setIsExporting(true);
    setProgress(0);
    
    try {
      // Create export job
      const response = await fetch('/api/export', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          ...exportConfig,
          filters: getCurrentFilters(),
          sorting: getCurrentSorting()
        })
      });
      
      if (exportConfig.format === 'pdf' || response.headers.get('content-length') > 10485760) {
        // Large file or PDF - use progress tracking
        await trackExportProgress(response);
      } else {
        // Small file - direct download
        const blob = await response.blob();
        downloadFile(blob, `export.${exportConfig.format}`);
      }
    } catch (error) {
      console.error('Export failed:', error);
      toast.error('Export failed. Please try again.');
    } finally {
      setIsExporting(false);
    }
  };
  
  const trackExportProgress = async (response) => {
    const reader = response.body.getReader();
    const contentLength = +response.headers.get('Content-Length');
    
    let receivedLength = 0;
    const chunks = [];
    
    while (true) {
      const { done, value } = await reader.read();
      
      if (done) break;
      
      chunks.push(value);
      receivedLength += value.length;
      
      setProgress(Math.round((receivedLength / contentLength) * 100));
    }
    
    const blob = new Blob(chunks);
    downloadFile(blob, `export.${exportConfig.format}`);
  };
  
  return (
    <div className="bg-white rounded-lg shadow-lg p-6">
      <h2 className="text-xl font-bold mb-4 flex items-center">
        <Download className="mr-2" />
        Export Data
      </h2>
      
      {/* Format Selection */}
      <div className="mb-6">
        <label className="block text-sm font-medium mb-2">Export Format</label>
        <div className="grid grid-cols-3 gap-3">
          {availableFormats.map(({ value, label, icon: Icon }) => (
            <button
              key={value}
              onClick={() => setExportConfig(prev => ({ ...prev, format: value }))}
              className={`p-3 border rounded-lg flex flex-col items-center transition-colors ${
                exportConfig.format === value
                  ? 'border-blue-500 bg-blue-50'
                  : 'border-gray-200 hover:border-gray-300'
              }`}
            >
              <Icon size={24} className="mb-1" />
              <span className="text-sm">{label}</span>
            </button>
          ))}
        </div>
      </div>
      
      {/* Export Options */}
      <div className="space-y-4 mb-6">
        <label className="flex items-center">
          <input
            type="checkbox"
            checked={exportConfig.includeFilters}
            onChange={(e) => setExportConfig(prev => ({
              ...prev,
              includeFilters: e.target.checked
            }))}
            className="mr-2"
          />
          <span className="text-sm">Include current filters</span>
        </label>
        
        <label className="flex items-center">
          <input
            type="checkbox"
            checked={exportConfig.compression}
            onChange={(e) => setExportConfig(prev => ({
              ...prev,
              compression: e.target.checked
            }))}
            className="mr-2"
          />
          <span className="text-sm">Compress file (ZIP)</span>
        </label>
        
        {exportConfig.format === 'pdf' && (
          <div>
            <label className="block text-sm font-medium mb-1">PDF Style</label>
            <select
              value={exportConfig.pdfStyle || 'table'}
              onChange={(e) => setExportConfig(prev => ({
                ...prev,
                pdfStyle: e.target.value
              }))}
              className="w-full border rounded px-3 py-2"
            >
              <option value="table">Table Layout</option>
              <option value="report">Report Style</option>
              <option value="cards">Card Layout</option>
            </select>
          </div>
        )}
      </div>
      
      {/* Column Selection */}
      <div className="mb-6">
        <label className="block text-sm font-medium mb-2">Select Columns</label>
        <div className="max-h-40 overflow-y-auto border rounded p-2">
          {availableColumns.map(column => (
            <label key={column.key} className="flex items-center py-1">
              <input
                type="checkbox"
                checked={exportConfig.selectedColumns.includes(column.key)}
                onChange={(e) => {
                  if (e.target.checked) {
                    setExportConfig(prev => ({
                      ...prev,
                      selectedColumns: [...prev.selectedColumns, column.key]
                    }));
                  } else {
                    setExportConfig(prev => ({
                      ...prev,
                      selectedColumns: prev.selectedColumns.filter(c => c !== column.key)
                    }));
                  }
                }}
                className="mr-2"
              />
              <span className="text-sm">{column.label}</span>
            </label>
          ))}
        </div>
      </div>
      
      {/* Export Progress */}
      {isExporting && (
        <div className="mb-4">
          <div className="flex items-center justify-between mb-1">
            <span className="text-sm text-gray-600">Exporting...</span>
            <span className="text-sm font-medium">{progress}%</span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-2">
            <div
              className="bg-blue-600 h-2 rounded-full transition-all duration-300"
              style={{ width: `${progress}%` }}
            />
          </div>
        </div>
      )}
      
      {/* Action Buttons */}
      <div className="flex gap-3">
        <button
          onClick={handleExport}
          disabled={isExporting}
          className="flex-1 bg-blue-600 text-white py-2 px-4 rounded hover:bg-blue-700 disabled:opacity-50 flex items-center justify-center"
        >
          {isExporting ? (
            <Loader className="animate-spin mr-2" size={16} />
          ) : (
            <Download className="mr-2" size={16} />
          )}
          Export Now
        </button>
        
        <button
          onClick={() => setShowScheduleModal(true)}
          className="px-4 py-2 border border-gray-300 rounded hover:bg-gray-50 flex items-center"
        >
          <Calendar className="mr-2" size={16} />
          Schedule
        </button>
      </div>
    </div>
  );
};
```

### 5. Advanced Export Features

```javascript
class AdvancedExportFeatures {
  // Data transformation pipelines
  createTransformationPipeline() {
    return {
      dateFormatting: {
        transform: (data, config) => {
          const { dateColumns, format } = config;
          return data.map(row => {
            const newRow = { ...row };
            dateColumns.forEach(col => {
              if (newRow[col]) {
                newRow[col] = moment(newRow[col]).format(format);
              }
            });
            return newRow;
          });
        }
      },
      
      currencyFormatting: {
        transform: (data, config) => {
          const { currencyColumns, symbol = '$', decimals = 2 } = config;
          return data.map(row => {
            const newRow = { ...row };
            currencyColumns.forEach(col => {
              if (newRow[col] !== null && newRow[col] !== undefined) {
                newRow[col] = `${symbol}${Number(newRow[col]).toFixed(decimals)}`;
              }
            });
            return newRow;
          });
        }
      },
      
      customCalculations: {
        transform: (data, config) => {
          const { calculations } = config;
          return data.map(row => {
            const newRow = { ...row };
            calculations.forEach(calc => {
              newRow[calc.outputColumn] = calc.formula(row);
            });
            return newRow;
          });
        }
      }
    };
  }
  
  // Template system for exports
  implementTemplateSystem() {
    return `
      class ExportTemplateManager {
        async saveTemplate(template) {
          const templateConfig = {
            id: uuid(),
            name: template.name,
            description: template.description,
            format: template.format,
            columns: template.columns,
            transformations: template.transformations,
            styling: template.styling,
            filters: template.filters,
            sorting: template.sorting,
            createdBy: getCurrentUser(),
            createdAt: new Date(),
            isPublic: template.isPublic || false
          };
          
          await db.export_templates.insert(templateConfig);
          return templateConfig;
        }
        
        async applyTemplate(templateId, data) {
          const template = await db.export_templates.findOne({ id: templateId });
          
          // Apply column selection
          let processedData = this.selectColumns(data, template.columns);
          
          // Apply transformations
          for (const transformation of template.transformations) {
            processedData = await this.applyTransformation(
              processedData,
              transformation
            );
          }
          
          // Apply styling (for formats that support it)
          if (template.styling && ['excel', 'pdf'].includes(template.format)) {
            processedData = this.applyStyling(processedData, template.styling);
          }
          
          return processedData;
        }
      }
    `;
  }
  
  // Incremental export for large datasets
  implementIncrementalExport() {
    return `
      class IncrementalExporter {
        async exportLargeDataset(query, options) {
          const {
            batchSize = 10000,
            format = 'csv',
            destination,
            onProgress
          } = options;
          
          // Initialize export
          const exportId = uuid();
          const tempFiles = [];
          let offset = 0;
          let hasMore = true;
          
          while (hasMore) {
            // Fetch batch
            const batch = await this.fetchBatch(query, offset, batchSize);
            hasMore = batch.length === batchSize;
            
            if (batch.length > 0) {
              // Export batch to temp file
              const tempFile = await this.exportBatch(batch, {
                format,
                isPartial: true,
                includeHeaders: offset === 0
              });
              
              tempFiles.push(tempFile);
              offset += batch.length;
              
              // Report progress
              if (onProgress) {
                onProgress({
                  exportId,
                  processed: offset,
                  currentBatch: batch.length
                });
              }
            }
          }
          
          // Merge temp files
          const finalFile = await this.mergeExports(tempFiles, format);
          
          // Clean up temp files
          await this.cleanupTempFiles(tempFiles);
          
          return finalFile;
        }
        
        async mergeExports(files, format) {
          switch (format) {
            case 'csv':
              return this.mergeCSVFiles(files);
            case 'json':
              return this.mergeJSONFiles(files);
            case 'excel':
              return this.mergeExcelFiles(files);
            default:
              throw new Error(\`Merge not supported for format: \${format}\`);
          }
        }
      }
    `;
  }
}
```

## Integration Examples

### With Performance Optimizer
```javascript
// Optimize export performance
const exportOptimization = {
  streaming: 'Use streams for large datasets',
  chunking: 'Process data in chunks to prevent memory issues',
  caching: 'Cache frequently exported data',
  compression: 'Compress on-the-fly for large exports'
};
```

### With Search Implementer
```javascript
// Export search results
const searchExportIntegration = {
  exportSearchResults: 'Allow users to export search results',
  preserveHighlights: 'Include search highlights in exports',
  exportFacets: 'Export faceted search statistics'
};
```

### With Notification System
```javascript
// Export completion notifications
const notificationIntegration = {
  exportReady: 'Notify when large exports are complete',
  scheduledExports: 'Send notifications for scheduled export results',
  exportFailures: 'Alert on export failures'
};
```

## Configuration Options

```javascript
const exportConfig = {
  // Size limits
  maxExportSize: 100 * 1024 * 1024, // 100MB
  maxRecords: 1000000,
  streamingThreshold: 10000, // Use streaming above this
  
  // Formats
  enabledFormats: ['csv', 'excel', 'pdf', 'json'],
  defaultFormat: 'csv',
  
  // Performance
  chunkSize: 5000,
  compressionLevel: 6,
  timeout: 300000, // 5 minutes
  
  // Features
  enableScheduling: true,
  enableTemplates: true,
  enableTransformations: true,
  
  // Storage
  tempDirectory: '/tmp/exports',
  cleanupInterval: 3600000 // 1 hour
};
```

---

*Part of the Database-Admin-Builder Enhancement Team | Comprehensive data export solutions for admin panels*