# UI Component Builder Agent

## Purpose
Generates reusable, accessible, and responsive UI components based on database schema and data patterns.

## Capabilities

### Component Types
- Form components (inputs, selects, date pickers)
- Data display components (tables, cards, lists)
- Navigation components (menus, breadcrumbs, tabs)
- Layout components (grids, containers, sidebars)
- Feedback components (alerts, toasts, modals)
- Data visualization components
- Interactive widgets
- Composite components

### Framework Support
- React (with TypeScript)
- Vue.js 3 (Composition API)
- Angular (14+)
- Svelte/SvelteKit
- Web Components
- Vanilla JavaScript

## Component Generation Strategy

### Schema-Driven Component Creation
```typescript
// Component generator based on field type
class ComponentGenerator {
  generateFormField(field: FieldSchema): ComponentDefinition {
    const baseProps = {
      name: field.name,
      label: this.humanizeFieldName(field.name),
      required: field.required,
      disabled: field.readOnly,
      placeholder: field.placeholder || `Enter ${this.humanizeFieldName(field.name)}`,
      helperText: field.description
    };
    
    switch (field.type) {
      case 'string':
        return this.generateStringInput(field, baseProps);
      
      case 'number':
      case 'integer':
        return this.generateNumberInput(field, baseProps);
      
      case 'boolean':
        return this.generateBooleanInput(field, baseProps);
      
      case 'date':
      case 'datetime':
        return this.generateDateInput(field, baseProps);
      
      case 'enum':
        return this.generateSelectInput(field, baseProps);
      
      case 'json':
        return this.generateJsonInput(field, baseProps);
      
      case 'relation':
        return this.generateRelationInput(field, baseProps);
      
      default:
        return this.generateTextInput(field, baseProps);
    }
  }
  
  generateStringInput(field: FieldSchema, baseProps: BaseProps): ComponentDefinition {
    // Detect special formats
    if (field.format === 'email') {
      return {
        component: 'EmailInput',
        props: {
          ...baseProps,
          type: 'email',
          validation: {
            pattern: '^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$',
            message: 'Please enter a valid email address'
          },
          icon: 'mail'
        }
      };
    }
    
    if (field.format === 'url') {
      return {
        component: 'UrlInput',
        props: {
          ...baseProps,
          type: 'url',
          validation: {
            pattern: '^https?://.*',
            message: 'Please enter a valid URL'
          },
          icon: 'link'
        }
      };
    }
    
    if (field.format === 'phone') {
      return {
        component: 'PhoneInput',
        props: {
          ...baseProps,
          type: 'tel',
          mask: '+1 (999) 999-9999',
          validation: {
            pattern: '^[\\+]?[(]?[0-9]{3}[)]?[-\\s\\.]?[(]?[0-9]{3}[)]?[-\\s\\.]?[0-9]{4,6}$',
            message: 'Please enter a valid phone number'
          },
          icon: 'phone'
        }
      };
    }
    
    if (field.maxLength > 255) {
      return {
        component: 'TextareaInput',
        props: {
          ...baseProps,
          rows: 4,
          maxLength: field.maxLength,
          showCharCount: true
        }
      };
    }
    
    // Default text input
    return {
      component: 'TextInput',
      props: {
        ...baseProps,
        type: 'text',
        maxLength: field.maxLength,
        minLength: field.minLength
      }
    };
  }
}
```

### React Component Implementation
```tsx
// Auto-generated React components
import React, { useState, useCallback } from 'react';
import { useForm, Controller } from 'react-hook-form';
import {
  TextField,
  Select,
  MenuItem,
  FormControl,
  FormLabel,
  FormHelperText,
  InputAdornment,
  IconButton,
  Autocomplete,
  DatePicker,
  Switch,
  Chip
} from '@mui/material';

// Generic form field wrapper
export const FormField: React.FC<FormFieldProps> = ({
  name,
  control,
  rules,
  render
}) => {
  return (
    <Controller
      name={name}
      control={control}
      rules={rules}
      render={({ field, fieldState: { error } }) => (
        <div className="form-field">
          {render({ field, error })}
        </div>
      )}
    />
  );
};

// Email input with validation
export const EmailInput: React.FC<EmailInputProps> = ({
  name,
  label,
  required,
  control,
  ...props
}) => {
  return (
    <FormField
      name={name}
      control={control}
      rules={{
        required: required && 'Email is required',
        pattern: {
          value: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
          message: 'Invalid email address'
        }
      }}
      render={({ field, error }) => (
        <TextField
          {...field}
          {...props}
          label={label}
          type="email"
          error={!!error}
          helperText={error?.message}
          fullWidth
          InputProps={{
            startAdornment: (
              <InputAdornment position="start">
                <EmailIcon />
              </InputAdornment>
            )
          }}
        />
      )}
    />
  );
};

// Relation picker with search
export const RelationPicker: React.FC<RelationPickerProps> = ({
  name,
  label,
  control,
  endpoint,
  displayField = 'name',
  valueField = 'id',
  multiple = false,
  required
}) => {
  const [options, setOptions] = useState([]);
  const [loading, setLoading] = useState(false);
  const [inputValue, setInputValue] = useState('');
  
  const fetchOptions = useCallback(
    debounce(async (search: string) => {
      setLoading(true);
      try {
        const response = await api.get(endpoint, {
          params: { search, limit: 20 }
        });
        setOptions(response.data.data);
      } catch (error) {
        console.error('Failed to fetch options:', error);
      } finally {
        setLoading(false);
      }
    }, 300),
    [endpoint]
  );
  
  useEffect(() => {
    if (inputValue) {
      fetchOptions(inputValue);
    }
  }, [inputValue, fetchOptions]);
  
  return (
    <FormField
      name={name}
      control={control}
      rules={{ required: required && `${label} is required` }}
      render={({ field, error }) => (
        <Autocomplete
          {...field}
          multiple={multiple}
          options={options}
          loading={loading}
          inputValue={inputValue}
          onInputChange={(_, value) => setInputValue(value)}
          getOptionLabel={(option) => option[displayField]}
          isOptionEqualToValue={(option, value) => 
            option[valueField] === value[valueField]
          }
          renderInput={(params) => (
            <TextField
              {...params}
              label={label}
              error={!!error}
              helperText={error?.message}
              InputProps={{
                ...params.InputProps,
                endAdornment: (
                  <>
                    {loading && <CircularProgress size={20} />}
                    {params.InputProps.endAdornment}
                  </>
                )
              }}
            />
          )}
          renderTags={(value, getTagProps) =>
            value.map((option, index) => (
              <Chip
                label={option[displayField]}
                {...getTagProps({ index })}
                size="small"
              />
            ))
          }
        />
      )}
    />
  );
};

// Advanced data table component
export const DataTable: React.FC<DataTableProps> = ({
  columns,
  data,
  onSort,
  onFilter,
  onPageChange,
  totalCount,
  loading,
  selectable = false,
  actions,
  bulkActions
}) => {
  const [selected, setSelected] = useState<string[]>([]);
  const [sortBy, setSortBy] = useState<SortConfig | null>(null);
  const [filters, setFilters] = useState<FilterConfig>({});
  
  const handleSort = (column: string) => {
    const newSort = {
      column,
      direction: 
        sortBy?.column === column && sortBy.direction === 'asc' 
          ? 'desc' 
          : 'asc'
    };
    setSortBy(newSort);
    onSort?.(newSort);
  };
  
  const handleSelectAll = (event: React.ChangeEvent<HTMLInputElement>) => {
    if (event.target.checked) {
      setSelected(data.map(row => row.id));
    } else {
      setSelected([]);
    }
  };
  
  return (
    <div className="data-table">
      {bulkActions && selected.length > 0 && (
        <div className="bulk-actions">
          <Typography variant="subtitle2">
            {selected.length} selected
          </Typography>
          {bulkActions.map(action => (
            <Button
              key={action.name}
              onClick={() => action.handler(selected)}
              startIcon={action.icon}
            >
              {action.label}
            </Button>
          ))}
        </div>
      )}
      
      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              {selectable && (
                <TableCell padding="checkbox">
                  <Checkbox
                    indeterminate={
                      selected.length > 0 && 
                      selected.length < data.length
                    }
                    checked={
                      data.length > 0 && 
                      selected.length === data.length
                    }
                    onChange={handleSelectAll}
                  />
                </TableCell>
              )}
              
              {columns.map(column => (
                <TableCell
                  key={column.key}
                  sortDirection={
                    sortBy?.column === column.key 
                      ? sortBy.direction 
                      : false
                  }
                >
                  {column.sortable ? (
                    <TableSortLabel
                      active={sortBy?.column === column.key}
                      direction={
                        sortBy?.column === column.key 
                          ? sortBy.direction 
                          : 'asc'
                      }
                      onClick={() => handleSort(column.key)}
                    >
                      {column.label}
                    </TableSortLabel>
                  ) : (
                    column.label
                  )}
                </TableCell>
              ))}
              
              {actions && <TableCell>Actions</TableCell>}
            </TableRow>
          </TableHead>
          
          <TableBody>
            {loading ? (
              <TableRow>
                <TableCell 
                  colSpan={columns.length + (selectable ? 1 : 0) + (actions ? 1 : 0)}
                  align="center"
                >
                  <CircularProgress />
                </TableCell>
              </TableRow>
            ) : data.length === 0 ? (
              <TableRow>
                <TableCell 
                  colSpan={columns.length + (selectable ? 1 : 0) + (actions ? 1 : 0)}
                  align="center"
                >
                  <EmptyState message="No data found" />
                </TableCell>
              </TableRow>
            ) : (
              data.map(row => (
                <TableRow
                  key={row.id}
                  selected={selected.includes(row.id)}
                  hover
                >
                  {selectable && (
                    <TableCell padding="checkbox">
                      <Checkbox
                        checked={selected.includes(row.id)}
                        onChange={(e) => {
                          if (e.target.checked) {
                            setSelected([...selected, row.id]);
                          } else {
                            setSelected(selected.filter(id => id !== row.id));
                          }
                        }}
                      />
                    </TableCell>
                  )}
                  
                  {columns.map(column => (
                    <TableCell key={column.key}>
                      {column.render 
                        ? column.render(row[column.key], row)
                        : row[column.key]
                      }
                    </TableCell>
                  ))}
                  
                  {actions && (
                    <TableCell>
                      <ActionMenu actions={actions} row={row} />
                    </TableCell>
                  )}
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </TableContainer>
      
      <TablePagination
        component="div"
        count={totalCount}
        onPageChange={onPageChange}
        page={page}
        rowsPerPage={rowsPerPage}
        onRowsPerPageChange={handleRowsPerPageChange}
      />
    </div>
  );
};
```

### Vue.js Component Implementation
```vue
<!-- Auto-generated Vue 3 components -->
<template>
  <div class="form-field" :class="{ 'has-error': error }">
    <label v-if="label" :for="inputId" class="form-label">
      {{ label }}
      <span v-if="required" class="required">*</span>
    </label>
    
    <div class="input-wrapper">
      <component
        :is="inputComponent"
        v-model="internalValue"
        v-bind="inputProps"
        :id="inputId"
        :class="inputClasses"
        @blur="handleBlur"
        @input="handleInput"
      />
      
      <transition name="fade">
        <span v-if="error" class="error-message">
          {{ error }}
        </span>
      </transition>
      
      <span v-if="helperText && !error" class="helper-text">
        {{ helperText }}
      </span>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref, watch } from 'vue';
import { useField } from 'vee-validate';
import { useI18n } from 'vue-i18n';

interface Props {
  name: string;
  label?: string;
  type?: string;
  required?: boolean;
  disabled?: boolean;
  placeholder?: string;
  helperText?: string;
  rules?: any;
  modelValue?: any;
}

const props = withDefaults(defineProps<Props>(), {
  type: 'text',
  required: false,
  disabled: false
});

const emit = defineEmits(['update:modelValue']);

const { t } = useI18n();

// Use vee-validate for field validation
const {
  value: fieldValue,
  errorMessage: error,
  handleBlur,
  handleChange,
  meta
} = useField(props.name, props.rules, {
  initialValue: props.modelValue
});

// Sync with v-model
const internalValue = computed({
  get: () => fieldValue.value ?? props.modelValue,
  set: (val) => {
    handleChange(val);
    emit('update:modelValue', val);
  }
});

// Determine input component based on type
const inputComponent = computed(() => {
  switch (props.type) {
    case 'textarea':
      return 'textarea';
    case 'select':
      return 'select';
    case 'checkbox':
      return 'input';
    case 'radio':
      return 'input';
    default:
      return 'input';
  }
});

const inputProps = computed(() => {
  const baseProps: any = {
    type: props.type,
    disabled: props.disabled,
    placeholder: props.placeholder || t(`placeholder.${props.name}`)
  };
  
  if (props.type === 'textarea') {
    baseProps.rows = 4;
  }
  
  return baseProps;
});

const inputClasses = computed(() => ({
  'form-input': true,
  'form-input--error': !!error.value,
  'form-input--touched': meta.touched,
  'form-input--disabled': props.disabled
}));

const inputId = computed(() => `input-${props.name}`);

const handleInput = (event: Event) => {
  const target = event.target as HTMLInputElement;
  internalValue.value = target.value;
};
</script>

<!-- Relation picker component -->
<template>
  <div class="relation-picker">
    <label v-if="label" class="form-label">
      {{ label }}
      <span v-if="required" class="required">*</span>
    </label>
    
    <Multiselect
      v-model="selected"
      :options="options"
      :multiple="multiple"
      :searchable="true"
      :loading="loading"
      :internal-search="false"
      :clear-on-select="false"
      :close-on-select="!multiple"
      :options-limit="300"
      :limit="3"
      :max-height="300"
      :show-no-results="true"
      :hide-selected="false"
      :placeholder="placeholder"
      :disabled="disabled"
      :track-by="valueField"
      :label="displayField"
      @search-change="handleSearch"
      @select="handleSelect"
      @remove="handleRemove"
    >
      <template #noResult>
        <span class="no-results">{{ t('common.noResults') }}</span>
      </template>
      
      <template #noOptions>
        <span class="no-options">{{ t('common.typeToSearch') }}</span>
      </template>
      
      <template #tag="{ option, remove }">
        <span class="multiselect__tag">
          <span>{{ option[displayField] }}</span>
          <i
            class="multiselect__tag-icon"
            @click="remove(option)"
          />
        </span>
      </template>
    </Multiselect>
    
    <span v-if="error" class="error-message">{{ error }}</span>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, onMounted } from 'vue';
import { useDebounceFn } from '@vueuse/core';
import Multiselect from 'vue-multiselect';
import { useApi } from '@/composables/useApi';

interface Props {
  modelValue: any;
  endpoint: string;
  displayField?: string;
  valueField?: string;
  multiple?: boolean;
  required?: boolean;
  label?: string;
  placeholder?: string;
  disabled?: boolean;
  preload?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  displayField: 'name',
  valueField: 'id',
  multiple: false,
  required: false,
  disabled: false,
  preload: false
});

const emit = defineEmits(['update:modelValue']);

const { api } = useApi();
const selected = ref(props.modelValue);
const options = ref([]);
const loading = ref(false);
const error = ref('');

// Fetch options from API
const fetchOptions = async (search = '') => {
  loading.value = true;
  error.value = '';
  
  try {
    const response = await api.get(props.endpoint, {
      params: {
        search,
        limit: 50,
        fields: [props.valueField, props.displayField].join(',')
      }
    });
    
    options.value = response.data.data;
  } catch (err) {
    error.value = t('errors.failedToLoadOptions');
    console.error('Failed to fetch options:', err);
  } finally {
    loading.value = false;
  }
};

// Debounced search
const handleSearch = useDebounceFn(async (search: string) => {
  if (search.length >= 2) {
    await fetchOptions(search);
  }
}, 300);

// Handle selection
const handleSelect = (option: any) => {
  if (props.multiple) {
    emit('update:modelValue', selected.value);
  } else {
    emit('update:modelValue', option[props.valueField]);
  }
};

// Handle removal
const handleRemove = (option: any) => {
  if (props.multiple) {
    emit('update:modelValue', selected.value);
  } else {
    emit('update:modelValue', null);
  }
};

// Watch for external value changes
watch(() => props.modelValue, (newValue) => {
  selected.value = newValue;
});

// Preload options if requested
onMounted(() => {
  if (props.preload) {
    fetchOptions();
  }
});
</script>
```

### Component Library Structure
```typescript
// Component library organization
export const componentLibrary = {
  // Form inputs
  inputs: {
    TextInput,
    EmailInput,
    PasswordInput,
    NumberInput,
    PhoneInput,
    UrlInput,
    TextareaInput,
    SelectInput,
    MultiSelectInput,
    RadioGroup,
    CheckboxGroup,
    SwitchInput,
    DatePicker,
    DateTimePicker,
    TimePicker,
    DateRangePicker,
    ColorPicker,
    FilePicker,
    ImageUploader,
    RichTextEditor,
    JsonEditor,
    CodeEditor,
    TagInput,
    SliderInput,
    RatingInput
  },
  
  // Data display
  display: {
    DataTable,
    DataGrid,
    DataList,
    DataCard,
    DetailView,
    Timeline,
    Calendar,
    TreeView,
    KanbanBoard
  },
  
  // Layout
  layout: {
    PageLayout,
    SidebarLayout,
    GridLayout,
    FlexLayout,
    TabLayout,
    AccordionLayout,
    StepperLayout
  },
  
  // Navigation
  navigation: {
    Navbar,
    Sidebar,
    Breadcrumb,
    Pagination,
    Tabs,
    Menu,
    Dropdown
  },
  
  // Feedback
  feedback: {
    Alert,
    Toast,
    Modal,
    Drawer,
    Popover,
    Tooltip,
    ProgressBar,
    Skeleton,
    Spinner,
    EmptyState,
    ErrorBoundary
  },
  
  // Charts
  charts: {
    LineChart,
    BarChart,
    PieChart,
    AreaChart,
    ScatterChart,
    RadarChart,
    HeatMap,
    GaugeChart
  },
  
  // Utility
  utility: {
    Avatar,
    Badge,
    Chip,
    Icon,
    Button,
    ButtonGroup,
    FloatingActionButton,
    SearchBar,
    FilterPanel,
    SortControls,
    ExportButton,
    PrintButton,
    ShareButton
  }
};
```

## Integration Points
- Receives schema from Schema Analyzer
- Uses patterns from Data Profiler
- Implements validation from Validation Engineer
- Coordinates with Theme Customizer

## Best Practices
1. Ensure all components are accessible (WCAG AA)
2. Implement proper keyboard navigation
3. Use semantic HTML elements
4. Provide loading and error states
5. Make components responsive by default
6. Include proper TypeScript types
7. Document component APIs clearly