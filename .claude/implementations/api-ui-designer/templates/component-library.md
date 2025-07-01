# Component Library Reference

Comprehensive catalog of UI components generated from API specifications with their properties, variations, and usage examples.

## Table of Contents
- [Form Components](#form-components)
- [Display Components](#display-components)
- [Layout Components](#layout-components)
- [Data Components](#data-components)
- [Feedback Components](#feedback-components)
- [Navigation Components](#navigation-components)
- [Specialized Components](#specialized-components)

## Form Components

### TextInput
Basic text input field with validation support.

```tsx
interface TextInputProps {
  name: string;
  label?: string;
  placeholder?: string;
  value?: string;
  onChange?: (value: string) => void;
  error?: boolean;
  helperText?: string;
  required?: boolean;
  disabled?: boolean;
  readOnly?: boolean;
  maxLength?: number;
  pattern?: string;
  icon?: string;
  size?: 'small' | 'medium' | 'large';
}
```

**API Mapping:**
- `type: string` with no format
- `minLength` → validation
- `maxLength` → maxLength prop
- `pattern` → pattern validation

**Example:**
```jsx
<TextInput
  name="username"
  label="Username"
  required
  maxLength={30}
  pattern="^[a-zA-Z0-9_]+$"
  helperText="Only letters, numbers, and underscores"
/>
```

### EmailInput
Specialized input for email addresses with built-in validation.

```tsx
interface EmailInputProps extends TextInputProps {
  domains?: string[]; // Restrict to specific domains
  validateOnBlur?: boolean;
  showSuggestions?: boolean;
}
```

**API Mapping:**
- `type: string, format: email`
- Custom domain validation

**Example:**
```jsx
<EmailInput
  name="email"
  label="Email Address"
  domains={['company.com', 'subsidiary.com']}
  showSuggestions
  validateOnBlur
/>
```

### PasswordInput
Secure password input with strength meter and visibility toggle.

```tsx
interface PasswordInputProps extends TextInputProps {
  showToggle?: boolean;
  showStrengthMeter?: boolean;
  minStrength?: 'weak' | 'medium' | 'strong';
  requirements?: string[];
  match?: string; // Field name to match (for confirmation)
}
```

**API Mapping:**
- `type: string, format: password`
- Pattern validation for strength requirements

**Example:**
```jsx
<PasswordInput
  name="password"
  label="Password"
  showToggle
  showStrengthMeter
  minStrength="strong"
  requirements={[
    "Minimum 8 characters",
    "One uppercase letter",
    "One number",
    "One special character"
  ]}
/>
```

### NumberInput
Numeric input with min/max constraints and step control.

```tsx
interface NumberInputProps {
  name: string;
  label?: string;
  value?: number;
  onChange?: (value: number) => void;
  min?: number;
  max?: number;
  step?: number;
  precision?: number;
  showControls?: boolean;
  format?: 'decimal' | 'percent' | 'currency';
  currency?: string;
  locale?: string;
}
```

**API Mapping:**
- `type: number` or `type: integer`
- `minimum` → min
- `maximum` → max
- `multipleOf` → step

**Example:**
```jsx
<NumberInput
  name="price"
  label="Price"
  min={0}
  max={999999}
  step={0.01}
  format="currency"
  currency="USD"
  showControls
/>
```

### Select
Dropdown selection component with search and multi-select support.

```tsx
interface SelectProps {
  name: string;
  label?: string;
  options: Array<{
    value: string;
    label: string;
    disabled?: boolean;
    icon?: string;
  }>;
  value?: string | string[];
  onChange?: (value: string | string[]) => void;
  multiple?: boolean;
  searchable?: boolean;
  clearable?: boolean;
  placeholder?: string;
  groupBy?: string;
  maxSelections?: number;
}
```

**API Mapping:**
- `enum` values → options
- `type: array` with enum → multiple select

**Example:**
```jsx
<Select
  name="role"
  label="User Role"
  options={[
    { value: 'admin', label: 'Administrator', icon: 'shield' },
    { value: 'user', label: 'Regular User', icon: 'user' },
    { value: 'guest', label: 'Guest', icon: 'visitor' }
  ]}
  searchable
  clearable
/>
```

### DatePicker
Date selection with calendar widget and range support.

```tsx
interface DatePickerProps {
  name: string;
  label?: string;
  value?: Date | string;
  onChange?: (date: Date | string) => void;
  min?: Date | string;
  max?: Date | string;
  format?: string;
  showTime?: boolean;
  disableDates?: (date: Date) => boolean;
  range?: boolean;
  presets?: Array<{
    label: string;
    value: () => Date | [Date, Date];
  }>;
}
```

**API Mapping:**
- `type: string, format: date`
- `type: string, format: date-time` → showTime=true

**Example:**
```jsx
<DatePicker
  name="startDate"
  label="Start Date"
  min={new Date()}
  format="MM/DD/YYYY"
  presets={[
    { label: 'Today', value: () => new Date() },
    { label: 'Tomorrow', value: () => addDays(new Date(), 1) },
    { label: 'Next Week', value: () => addWeeks(new Date(), 1) }
  ]}
/>
```

### FileUpload
File upload component with drag-and-drop and preview.

```tsx
interface FileUploadProps {
  name: string;
  label?: string;
  accept?: string | string[];
  multiple?: boolean;
  maxSize?: number;
  maxFiles?: number;
  onUpload?: (files: File[]) => Promise<void>;
  preview?: boolean;
  dragDrop?: boolean;
  camera?: boolean; // Enable camera capture
  compress?: boolean; // Auto-compress images
}
```

**API Mapping:**
- `type: string, format: binary`
- `type: array` with format: binary → multiple=true

**Example:**
```jsx
<FileUpload
  name="documents"
  label="Upload Documents"
  accept={['.pdf', '.doc', '.docx']}
  multiple
  maxFiles={5}
  maxSize={10 * 1024 * 1024} // 10MB
  dragDrop
  preview
/>
```

### Switch
Toggle switch for boolean values.

```tsx
interface SwitchProps {
  name: string;
  label?: string;
  value?: boolean;
  onChange?: (value: boolean) => void;
  disabled?: boolean;
  color?: 'primary' | 'secondary' | 'success' | 'danger';
  size?: 'small' | 'medium' | 'large';
  labelPlacement?: 'start' | 'end' | 'top' | 'bottom';
}
```

**API Mapping:**
- `type: boolean`

**Example:**
```jsx
<Switch
  name="isActive"
  label="Active"
  color="success"
  labelPlacement="end"
/>
```

### RichTextEditor
WYSIWYG editor for formatted text content.

```tsx
interface RichTextEditorProps {
  name: string;
  label?: string;
  value?: string;
  onChange?: (html: string) => void;
  toolbar?: string[] | 'basic' | 'full';
  height?: number | string;
  placeholder?: string;
  mentions?: {
    users?: boolean;
    hashtags?: boolean;
  };
  uploadImage?: (file: File) => Promise<string>;
}
```

**API Mapping:**
- Long text fields
- Content fields
- Description fields with formatting needs

**Example:**
```jsx
<RichTextEditor
  name="content"
  label="Article Content"
  toolbar={['bold', 'italic', 'underline', 'link', 'image', 'code']}
  height={400}
  uploadImage={async (file) => {
    const url = await uploadToS3(file);
    return url;
  }}
/>
```

## Display Components

### DataTable
Advanced table with sorting, filtering, and pagination.

```tsx
interface DataTableProps<T> {
  data: T[];
  columns: Array<{
    field: keyof T;
    header: string;
    sortable?: boolean;
    filterable?: boolean;
    width?: number | string;
    render?: (value: any, row: T) => React.ReactNode;
  }>;
  pagination?: {
    page: number;
    pageSize: number;
    total: number;
    pageSizeOptions?: number[];
  };
  onSort?: (field: string, order: 'asc' | 'desc') => void;
  onFilter?: (filters: Record<string, any>) => void;
  onPageChange?: (page: number, pageSize: number) => void;
  selection?: 'single' | 'multiple';
  onSelectionChange?: (selected: T[]) => void;
  actions?: Array<{
    icon: string;
    label: string;
    onClick: (row: T) => void;
    show?: (row: T) => boolean;
  }>;
  bulkActions?: Array<{
    label: string;
    onClick: (selected: T[]) => void;
    requireConfirm?: boolean;
  }>;
  expandable?: {
    render: (row: T) => React.ReactNode;
  };
}
```

**API Mapping:**
- GET endpoints returning arrays
- Paginated responses

**Example:**
```jsx
<DataTable
  data={users}
  columns={[
    { field: 'name', header: 'Name', sortable: true },
    { field: 'email', header: 'Email', sortable: true },
    {
      field: 'status',
      header: 'Status',
      render: (status) => (
        <Badge color={status === 'active' ? 'success' : 'default'}>
          {status}
        </Badge>
      )
    }
  ]}
  pagination={{
    page: 1,
    pageSize: 20,
    total: 150
  }}
  selection="multiple"
  bulkActions={[
    { label: 'Delete Selected', onClick: handleBulkDelete }
  ]}
/>
```

### DetailView
Structured display of single record details.

```tsx
interface DetailViewProps {
  data: Record<string, any>;
  sections: Array<{
    title: string;
    fields: Array<{
      label: string;
      value: string | ((data: any) => React.ReactNode);
      span?: number; // Grid columns
      copyable?: boolean;
    }>;
    collapsible?: boolean;
  }>;
  layout?: 'vertical' | 'horizontal' | 'grid';
  actions?: Array<{
    label: string;
    onClick: () => void;
    variant?: 'primary' | 'secondary' | 'danger';
  }>;
}
```

**API Mapping:**
- GET endpoints returning single objects
- Nested object structures

**Example:**
```jsx
<DetailView
  data={user}
  sections={[
    {
      title: 'Personal Information',
      fields: [
        { label: 'Name', value: 'fullName' },
        { label: 'Email', value: 'email', copyable: true },
        { label: 'Phone', value: 'phone' }
      ]
    },
    {
      title: 'Account Details',
      fields: [
        { label: 'Role', value: (data) => <Badge>{data.role}</Badge> },
        { label: 'Status', value: (data) => <StatusBadge status={data.status} /> },
        { label: 'Member Since', value: (data) => formatDate(data.createdAt) }
      ]
    }
  ]}
  actions={[
    { label: 'Edit', onClick: handleEdit },
    { label: 'Delete', onClick: handleDelete, variant: 'danger' }
  ]}
/>
```

### Card
Flexible container for content display.

```tsx
interface CardProps {
  title?: string;
  subtitle?: string;
  image?: string;
  content?: React.ReactNode;
  actions?: React.ReactNode;
  hoverable?: boolean;
  onClick?: () => void;
  variant?: 'elevated' | 'outlined' | 'filled';
  loading?: boolean;
}
```

**Example:**
```jsx
<Card
  title="Product Name"
  subtitle="$99.99"
  image="/product-image.jpg"
  content={
    <div>
      <p>Product description...</p>
      <Rating value={4.5} count={123} />
    </div>
  }
  actions={
    <>
      <Button variant="primary">Add to Cart</Button>
      <Button variant="text">View Details</Button>
    </>
  }
  hoverable
  onClick={handleProductClick}
/>
```

### Badge
Status indicators and labels.

```tsx
interface BadgeProps {
  children: React.ReactNode;
  color?: 'primary' | 'secondary' | 'success' | 'danger' | 'warning' | 'info';
  variant?: 'filled' | 'outlined' | 'light';
  size?: 'small' | 'medium' | 'large';
  icon?: string;
  removable?: boolean;
  onRemove?: () => void;
}
```

**API Mapping:**
- Enum fields
- Status fields
- Category/tag fields

**Example:**
```jsx
<Badge
  color="success"
  variant="light"
  icon="check-circle"
>
  Active
</Badge>
```

## Layout Components

### Form
Form container with validation and submission handling.

```tsx
interface FormProps {
  onSubmit: (values: any) => Promise<void>;
  initialValues?: Record<string, any>;
  validation?: Record<string, any>; // Validation schema
  layout?: 'vertical' | 'horizontal' | 'inline';
  sections?: Array<{
    title?: string;
    description?: string;
    fields: React.ReactNode;
    collapsible?: boolean;
  }>;
  submitText?: string;
  cancelText?: string;
  onCancel?: () => void;
  showReset?: boolean;
  autoSave?: boolean;
  confirmLeave?: boolean;
}
```

**Example:**
```jsx
<Form
  onSubmit={handleSubmit}
  initialValues={userData}
  validation={userValidationSchema}
  layout="vertical"
  sections={[
    {
      title: 'Basic Information',
      fields: (
        <>
          <TextInput name="firstName" label="First Name" required />
          <TextInput name="lastName" label="Last Name" required />
          <EmailInput name="email" label="Email" required />
        </>
      )
    },
    {
      title: 'Additional Details',
      collapsible: true,
      fields: (
        <>
          <PhoneInput name="phone" label="Phone" />
          <DatePicker name="birthDate" label="Birth Date" />
        </>
      )
    }
  ]}
  confirmLeave
/>
```

### Modal
Dialog component for forms and content.

```tsx
interface ModalProps {
  open: boolean;
  onClose: () => void;
  title?: string;
  size?: 'small' | 'medium' | 'large' | 'fullscreen';
  children: React.ReactNode;
  actions?: React.ReactNode;
  closeOnEscape?: boolean;
  closeOnOverlayClick?: boolean;
  showCloseButton?: boolean;
}
```

**Example:**
```jsx
<Modal
  open={isOpen}
  onClose={handleClose}
  title="Edit User"
  size="medium"
  actions={
    <>
      <Button variant="text" onClick={handleClose}>Cancel</Button>
      <Button variant="primary" onClick={handleSave}>Save</Button>
    </>
  }
>
  <UserForm user={selectedUser} />
</Modal>
```

### Tabs
Tabbed interface for organizing content.

```tsx
interface TabsProps {
  tabs: Array<{
    id: string;
    label: string;
    icon?: string;
    content: React.ReactNode;
    disabled?: boolean;
    badge?: string | number;
  }>;
  defaultTab?: string;
  onChange?: (tabId: string) => void;
  variant?: 'standard' | 'pills' | 'underlined';
  orientation?: 'horizontal' | 'vertical';
  lazy?: boolean; // Lazy load tab content
}
```

**Example:**
```jsx
<Tabs
  tabs={[
    {
      id: 'profile',
      label: 'Profile',
      icon: 'user',
      content: <ProfileForm />
    },
    {
      id: 'security',
      label: 'Security',
      icon: 'lock',
      content: <SecuritySettings />,
      badge: 2
    },
    {
      id: 'notifications',
      label: 'Notifications',
      icon: 'bell',
      content: <NotificationPreferences />
    }
  ]}
  variant="underlined"
  lazy
/>
```

## Data Components

### Chart
Flexible charting component with multiple visualization types.

```tsx
interface ChartProps {
  type: 'line' | 'bar' | 'pie' | 'donut' | 'area' | 'scatter';
  data: {
    labels: string[];
    datasets: Array<{
      label: string;
      data: number[];
      backgroundColor?: string | string[];
      borderColor?: string;
    }>;
  };
  options?: {
    title?: string;
    legend?: boolean;
    tooltips?: boolean;
    responsive?: boolean;
    maintainAspectRatio?: boolean;
    scales?: any; // Chart.js scales config
  };
  height?: number | string;
  width?: number | string;
}
```

**API Mapping:**
- Analytics endpoints
- Time-series data
- Statistical data

**Example:**
```jsx
<Chart
  type="line"
  data={{
    labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
    datasets: [
      {
        label: 'Revenue',
        data: [12000, 19000, 15000, 25000, 22000, 30000],
        borderColor: '#1976d2',
        backgroundColor: 'rgba(25, 118, 210, 0.1)'
      }
    ]
  }}
  options={{
    title: 'Monthly Revenue',
    scales: {
      y: {
        beginAtZero: true,
        ticks: {
          callback: (value) => `$${value.toLocaleString()}`
        }
      }
    }
  }}
  height={300}
/>
```

### StatCard
Statistical display card with trends.

```tsx
interface StatCardProps {
  title: string;
  value: number | string;
  previousValue?: number;
  format?: 'number' | 'currency' | 'percent';
  icon?: string;
  color?: string;
  trend?: 'up' | 'down' | 'neutral';
  sparkline?: number[];
  onClick?: () => void;
}
```

**Example:**
```jsx
<StatCard
  title="Total Revenue"
  value={45231}
  previousValue={41200}
  format="currency"
  icon="dollar"
  color="success"
  trend="up"
  sparkline={[10, 15, 12, 25, 22, 30, 28, 35, 32, 45]}
  onClick={() => navigate('/analytics/revenue')}
/>
```

## Feedback Components

### Toast
Non-intrusive notification messages.

```tsx
interface ToastProps {
  message: string;
  type?: 'success' | 'error' | 'warning' | 'info';
  duration?: number;
  position?: 'top' | 'bottom' | 'top-left' | 'top-right' | 'bottom-left' | 'bottom-right';
  action?: {
    label: string;
    onClick: () => void;
  };
}

// Usage via hook
const toast = useToast();
toast.show({
  message: 'User created successfully',
  type: 'success',
  duration: 5000
});
```

### LoadingState
Loading indicators and skeletons.

```tsx
interface LoadingStateProps {
  type?: 'spinner' | 'skeleton' | 'progress' | 'dots';
  size?: 'small' | 'medium' | 'large';
  text?: string;
  overlay?: boolean;
  progress?: number; // For progress type
  skeletonConfig?: {
    lines?: number;
    avatar?: boolean;
    image?: boolean;
  };
}
```

**Example:**
```jsx
<LoadingState
  type="skeleton"
  skeletonConfig={{
    lines: 3,
    avatar: true
  }}
/>
```

### EmptyState
Placeholder for empty content.

```tsx
interface EmptyStateProps {
  title: string;
  description?: string;
  icon?: string;
  image?: string;
  action?: {
    label: string;
    onClick: () => void;
  };
  suggestions?: Array<{
    label: string;
    onClick: () => void;
  }>;
}
```

**Example:**
```jsx
<EmptyState
  title="No products found"
  description="Try adjusting your filters or search terms"
  icon="package"
  action={{
    label: 'Clear Filters',
    onClick: clearFilters
  }}
  suggestions={[
    { label: 'Browse all products', onClick: () => navigate('/products') },
    { label: 'Contact support', onClick: () => openChat() }
  ]}
/>
```

## Navigation Components

### Breadcrumb
Navigation path indicator.

```tsx
interface BreadcrumbProps {
  items: Array<{
    label: string;
    href?: string;
    onClick?: () => void;
    icon?: string;
  }>;
  separator?: string | React.ReactNode;
  maxItems?: number;
}
```

**Example:**
```jsx
<Breadcrumb
  items={[
    { label: 'Home', href: '/' },
    { label: 'Products', href: '/products' },
    { label: 'Electronics', href: '/products/electronics' },
    { label: 'Laptop Pro X1' }
  ]}
  separator="/"
  maxItems={4}
/>
```

### Pagination
Page navigation component.

```tsx
interface PaginationProps {
  current: number;
  total: number;
  pageSize: number;
  onChange: (page: number, pageSize?: number) => void;
  showSizeChanger?: boolean;
  pageSizeOptions?: number[];
  showQuickJumper?: boolean;
  showTotal?: boolean | ((total: number, range: [number, number]) => string);
  size?: 'small' | 'medium' | 'large';
}
```

**Example:**
```jsx
<Pagination
  current={currentPage}
  total={500}
  pageSize={20}
  onChange={handlePageChange}
  showSizeChanger
  pageSizeOptions={[10, 20, 50, 100]}
  showQuickJumper
  showTotal={(total, range) => `${range[0]}-${range[1]} of ${total} items`}
/>
```

## Specialized Components

### AddressInput
Smart address input with autocomplete.

```tsx
interface AddressInputProps {
  name: string;
  label?: string;
  value?: Address;
  onChange?: (address: Address) => void;
  googleMapsApiKey?: string;
  countriesWhitelist?: string[];
  showMap?: boolean;
  required?: boolean;
}

interface Address {
  street: string;
  city: string;
  state: string;
  country: string;
  postalCode: string;
  coordinates?: {
    lat: number;
    lng: number;
  };
}
```

**Example:**
```jsx
<AddressInput
  name="shippingAddress"
  label="Shipping Address"
  googleMapsApiKey={process.env.GOOGLE_MAPS_KEY}
  countriesWhitelist={['US', 'CA', 'MX']}
  showMap
  required
/>
```

### CurrencyInput
Formatted currency input with locale support.

```tsx
interface CurrencyInputProps {
  name: string;
  label?: string;
  value?: number;
  onChange?: (value: number) => void;
  currency?: string;
  locale?: string;
  min?: number;
  max?: number;
  allowNegative?: boolean;
  showSymbol?: boolean;
}
```

**Example:**
```jsx
<CurrencyInput
  name="price"
  label="Product Price"
  currency="USD"
  locale="en-US"
  min={0}
  max={999999.99}
  showSymbol
/>
```

### PhoneInput
International phone number input.

```tsx
interface PhoneInputProps {
  name: string;
  label?: string;
  value?: string;
  onChange?: (value: string, country: any) => void;
  defaultCountry?: string;
  preferredCountries?: string[];
  onlyCountries?: string[];
  format?: boolean;
  showFlags?: boolean;
}
```

**Example:**
```jsx
<PhoneInput
  name="phone"
  label="Phone Number"
  defaultCountry="us"
  preferredCountries={['us', 'ca', 'mx']}
  format
  showFlags
/>
```

### TagInput
Multi-value tag input component.

```tsx
interface TagInputProps {
  name: string;
  label?: string;
  value?: string[];
  onChange?: (tags: string[]) => void;
  suggestions?: string[];
  allowCreate?: boolean;
  maxTags?: number;
  validation?: (tag: string) => boolean | string;
  placeholder?: string;
}
```

**Example:**
```jsx
<TagInput
  name="skills"
  label="Skills"
  suggestions={['JavaScript', 'React', 'Node.js', 'Python']}
  allowCreate
  maxTags={10}
  validation={(tag) => tag.length >= 2 || 'Tag must be at least 2 characters'}
  placeholder="Add a skill..."
/>
```

### JsonEditor
JSON data editor with syntax highlighting.

```tsx
interface JsonEditorProps {
  name: string;
  label?: string;
  value?: object;
  onChange?: (value: object) => void;
  schema?: object; // JSON Schema for validation
  height?: number | string;
  readOnly?: boolean;
  collapsed?: boolean;
  theme?: 'light' | 'dark';
}
```

**Example:**
```jsx
<JsonEditor
  name="configuration"
  label="API Configuration"
  value={config}
  onChange={setConfig}
  schema={configSchema}
  height={400}
  theme="dark"
  collapsed
/>
```

## Component Composition Patterns

### Form with Wizard
Multi-step form with progress indication.

```jsx
<WizardForm
  steps={[
    {
      title: 'Account Information',
      component: (
        <>
          <EmailInput name="email" required />
          <PasswordInput name="password" required />
          <PasswordInput name="confirmPassword" match="password" required />
        </>
      ),
      validation: accountSchema
    },
    {
      title: 'Personal Details',
      component: (
        <>
          <TextInput name="firstName" required />
          <TextInput name="lastName" required />
          <DatePicker name="birthDate" max={new Date()} />
        </>
      ),
      validation: personalSchema
    },
    {
      title: 'Preferences',
      component: (
        <>
          <Select name="language" options={languages} />
          <Switch name="newsletter" label="Subscribe to newsletter" />
          <TagInput name="interests" suggestions={interestSuggestions} />
        </>
      )
    }
  ]}
  onComplete={handleComplete}
  showProgress
  allowSkip={[2]} // Allow skipping step 3
/>
```

### Master-Detail Layout
Split view with list and detail panels.

```jsx
<MasterDetailLayout
  master={{
    component: (
      <DataTable
        data={users}
        columns={columns}
        onRowClick={setSelectedUser}
        selection="single"
      />
    ),
    width: '40%'
  }}
  detail={{
    component: selectedUser ? (
      <DetailView
        data={selectedUser}
        sections={userDetailSections}
        actions={userActions}
      />
    ) : (
      <EmptyState
        title="Select a user"
        description="Choose a user from the list to view details"
      />
    )
  }}
  divider
  collapsible="master"
/>
```

### Dashboard Layout
Grid-based dashboard with widgets.

```jsx
<Dashboard
  widgets={[
    {
      id: 'revenue',
      gridArea: { x: 0, y: 0, w: 6, h: 2 },
      component: <RevenueChart period={period} />
    },
    {
      id: 'stats',
      gridArea: { x: 6, y: 0, w: 6, h: 2 },
      component: (
        <StatCardGroup>
          <StatCard title="Total Sales" value={totalSales} trend="up" />
          <StatCard title="New Customers" value={newCustomers} />
          <StatCard title="Conversion Rate" value={conversionRate} format="percent" />
        </StatCardGroup>
      )
    },
    {
      id: 'recentOrders',
      gridArea: { x: 0, y: 2, w: 8, h: 4 },
      component: <RecentOrdersTable />
    },
    {
      id: 'topProducts',
      gridArea: { x: 8, y: 2, w: 4, h: 4 },
      component: <TopProductsList limit={10} />
    }
  ]}
  columns={12}
  rowHeight={60}
  gap={16}
  editable // Allow rearranging widgets
  onLayoutChange={saveLayout}
/>
```

This component library provides a comprehensive set of UI components that can be automatically generated from API specifications, with full type safety and consistent behavior across your application.