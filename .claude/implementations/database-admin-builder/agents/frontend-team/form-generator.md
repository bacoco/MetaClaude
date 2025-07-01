# Form Generator Agent

## Purpose
Creates intelligent, dynamic forms for data entry and editing by analyzing database schemas, field types, relationships, and constraints to generate fully-functional forms with validation, conditional logic, and optimal user experience.

## Capabilities

### Form Types
- Single record create/edit forms
- Multi-step wizard forms
- Inline editing forms
- Bulk edit forms
- Search and filter forms
- Nested relationship forms
- Dynamic form builders
- Import/mapping forms
- Settings and configuration forms
- Authentication forms

### Field Generation
- Text inputs with format detection
- Numeric inputs with constraints
- Date/time pickers with ranges
- Select/dropdown from enums
- Multi-select for many-to-many
- File upload with validation
- Rich text editors
- JSON/code editors
- Custom field components
- Conditional field visibility

### Validation & Logic
- Schema-based validation rules
- Cross-field validation
- Async validation (uniqueness)
- Conditional required fields
- Dynamic field dependencies
- Real-time validation feedback
- Custom validation rules
- Submission validation
- Error recovery strategies

## Form Generation Strategy

### Schema-Driven Form Builder
```typescript
interface FormGenerator {
  generateForm(entity: Entity, mode: 'create' | 'edit'): FormDefinition {
    const form: FormDefinition = {
      id: `${entity.name}-${mode}-form`,
      title: this.generateFormTitle(entity, mode),
      description: this.generateFormDescription(entity, mode),
      sections: [],
      validation: this.generateValidationSchema(entity),
      submission: this.generateSubmissionConfig(entity, mode)
    };
    
    // Group fields into logical sections
    const fieldGroups = this.groupFieldsBySemantic(entity.fields);
    
    fieldGroups.forEach((group, index) => {
      const section: FormSection = {
        id: `section-${index}`,
        title: group.title,
        description: group.description,
        collapsible: group.fields.length > 5,
        fields: group.fields.map(field => 
          this.generateFormField(field, entity, mode)
        )
      };
      
      form.sections.push(section);
    });
    
    // Add relationship sections
    const relationships = this.analyzeRelationships(entity);
    if (relationships.length > 0) {
      form.sections.push(
        this.generateRelationshipSection(relationships, entity, mode)
      );
    }
    
    // Add metadata section for edit mode
    if (mode === 'edit') {
      form.sections.push(this.generateMetadataSection(entity));
    }
    
    return form;
  }
  
  generateFormField(field: Field, entity: Entity, mode: string): FormField {
    const baseField: FormField = {
      id: field.name,
      name: field.name,
      label: this.humanizeFieldName(field.name),
      type: this.mapFieldType(field),
      required: field.required && !field.hasDefault,
      disabled: field.readOnly || field.computed,
      placeholder: this.generatePlaceholder(field),
      helperText: field.description,
      validation: this.generateFieldValidation(field),
      conditional: this.analyzeFieldConditions(field, entity)
    };
    
    // Enhance based on field characteristics
    switch (field.type) {
      case 'string':
        return this.enhanceStringField(baseField, field);
      
      case 'number':
      case 'integer':
      case 'decimal':
        return this.enhanceNumericField(baseField, field);
      
      case 'boolean':
        return this.enhanceBooleanField(baseField, field);
      
      case 'date':
      case 'datetime':
      case 'time':
        return this.enhanceDateField(baseField, field);
      
      case 'enum':
        return this.enhanceEnumField(baseField, field);
      
      case 'json':
        return this.enhanceJsonField(baseField, field);
      
      case 'relation':
        return this.enhanceRelationField(baseField, field, entity);
      
      default:
        return baseField;
    }
  }
  
  private enhanceStringField(field: FormField, schema: Field): FormField {
    // Detect special string formats
    const patterns = {
      email: /email/i,
      url: /url|link|website/i,
      phone: /phone|mobile|contact/i,
      password: /password|secret/i,
      color: /color|colour/i,
      slug: /slug|permalink/i,
      username: /username|login/i,
      address: /address|street/i,
      postal: /zip|postal|postcode/i
    };
    
    for (const [format, pattern] of Object.entries(patterns)) {
      if (pattern.test(schema.name)) {
        field.format = format;
        field.type = this.getInputTypeForFormat(format);
        field.validation = {
          ...field.validation,
          ...this.getValidationForFormat(format)
        };
        break;
      }
    }
    
    // Handle text length
    if (schema.maxLength) {
      if (schema.maxLength > 500) {
        field.type = 'textarea';
        field.rows = Math.min(10, Math.ceil(schema.maxLength / 100));
      } else if (schema.maxLength > 1000) {
        field.type = 'richtext';
      }
      
      field.maxLength = schema.maxLength;
      field.showCharCount = schema.maxLength > 100;
    }
    
    return field;
  }
  
  private enhanceRelationField(
    field: FormField, 
    schema: Field, 
    entity: Entity
  ): FormField {
    const relation = schema.relation!;
    
    field.type = relation.type === 'many' ? 'multiselect' : 'select';
    field.async = true;
    field.searchable = true;
    field.createable = this.canCreateRelated(relation);
    
    field.dataSource = {
      endpoint: `/api/${relation.target}`,
      valueField: relation.targetField || 'id',
      labelField: this.detectLabelField(relation.target),
      searchFields: this.detectSearchFields(relation.target),
      filters: this.generateRelationFilters(relation, entity),
      preload: this.shouldPreloadOptions(relation)
    };
    
    // Add cascading behavior
    if (relation.cascade) {
      field.cascade = {
        delete: relation.cascade.includes('delete'),
        update: relation.cascade.includes('update')
      };
    }
    
    return field;
  }
}
```

### React Form Implementation
```tsx
import React, { useState, useEffect, useCallback } from 'react';
import { useForm, Controller, useFieldArray } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import {
  TextField,
  Select,
  MenuItem,
  FormControl,
  FormLabel,
  FormHelperText,
  Button,
  IconButton,
  Stepper,
  Step,
  StepLabel,
  Grid,
  Paper,
  Typography,
  Divider,
  Collapse,
  Alert,
  CircularProgress,
  Autocomplete,
  Chip,
  Switch,
  FormControlLabel,
  DatePicker,
  TimePicker,
  DateTimePicker
} from '@mui/material';
import {
  Add as AddIcon,
  Delete as DeleteIcon,
  Save as SaveIcon,
  Cancel as CancelIcon,
  ExpandMore as ExpandMoreIcon
} from '@mui/icons-material';

// Dynamic form component
export const DynamicForm: React.FC<{
  definition: FormDefinition;
  initialData?: any;
  onSubmit: (data: any) => Promise<void>;
  onCancel?: () => void;
}> = ({ definition, initialData, onSubmit, onCancel }) => {
  const [activeStep, setActiveStep] = useState(0);
  const [expandedSections, setExpandedSections] = useState<Set<string>>(
    new Set(definition.sections.filter(s => !s.collapsible).map(s => s.id))
  );
  
  // Generate Zod schema from form definition
  const validationSchema = useMemo(() => {
    return generateZodSchema(definition.validation);
  }, [definition.validation]);
  
  const {
    control,
    handleSubmit,
    watch,
    formState: { errors, isSubmitting, isDirty },
    reset,
    setValue,
    trigger
  } = useForm({
    resolver: zodResolver(validationSchema),
    defaultValues: initialData || generateDefaultValues(definition),
    mode: 'onChange'
  });
  
  // Watch for conditional field dependencies
  const watchedFields = watch();
  
  // Handle section expansion
  const toggleSection = (sectionId: string) => {
    setExpandedSections(prev => {
      const next = new Set(prev);
      if (next.has(sectionId)) {
        next.delete(sectionId);
      } else {
        next.add(sectionId);
      }
      return next;
    });
  };
  
  // Check field visibility based on conditions
  const isFieldVisible = (field: FormField): boolean => {
    if (!field.conditional) return true;
    
    return field.conditional.every(condition => {
      const fieldValue = watchedFields[condition.field];
      
      switch (condition.operator) {
        case 'equals':
          return fieldValue === condition.value;
        case 'not_equals':
          return fieldValue !== condition.value;
        case 'contains':
          return Array.isArray(fieldValue) 
            ? fieldValue.includes(condition.value)
            : String(fieldValue).includes(condition.value);
        case 'empty':
          return !fieldValue || 
            (Array.isArray(fieldValue) && fieldValue.length === 0);
        case 'not_empty':
          return fieldValue && 
            (!Array.isArray(fieldValue) || fieldValue.length > 0);
        default:
          return true;
      }
    });
  };
  
  // Render form field based on type
  const renderField = (field: FormField) => {
    if (!isFieldVisible(field)) return null;
    
    switch (field.type) {
      case 'text':
      case 'email':
      case 'url':
      case 'tel':
      case 'password':
        return (
          <Controller
            name={field.name}
            control={control}
            render={({ field: fieldProps, fieldState }) => (
              <TextField
                {...fieldProps}
                type={field.type}
                label={field.label}
                placeholder={field.placeholder}
                helperText={fieldState.error?.message || field.helperText}
                error={!!fieldState.error}
                disabled={field.disabled}
                required={field.required}
                fullWidth
                InputProps={{
                  ...field.inputProps,
                  endAdornment: field.showCharCount && (
                    <Typography variant="caption" color="textSecondary">
                      {fieldProps.value?.length || 0}/{field.maxLength}
                    </Typography>
                  )
                }}
                inputProps={{
                  maxLength: field.maxLength
                }}
              />
            )}
          />
        );
      
      case 'textarea':
        return (
          <Controller
            name={field.name}
            control={control}
            render={({ field: fieldProps, fieldState }) => (
              <TextField
                {...fieldProps}
                multiline
                rows={field.rows || 4}
                label={field.label}
                placeholder={field.placeholder}
                helperText={fieldState.error?.message || field.helperText}
                error={!!fieldState.error}
                disabled={field.disabled}
                required={field.required}
                fullWidth
                InputProps={{
                  endAdornment: field.showCharCount && (
                    <Typography variant="caption" color="textSecondary">
                      {fieldProps.value?.length || 0}/{field.maxLength}
                    </Typography>
                  )
                }}
              />
            )}
          />
        );
      
      case 'number':
        return (
          <Controller
            name={field.name}
            control={control}
            render={({ field: fieldProps, fieldState }) => (
              <TextField
                {...fieldProps}
                type="number"
                label={field.label}
                placeholder={field.placeholder}
                helperText={fieldState.error?.message || field.helperText}
                error={!!fieldState.error}
                disabled={field.disabled}
                required={field.required}
                fullWidth
                InputProps={{
                  inputProps: {
                    min: field.min,
                    max: field.max,
                    step: field.step
                  }
                }}
              />
            )}
          />
        );
      
      case 'select':
        return (
          <Controller
            name={field.name}
            control={control}
            render={({ field: fieldProps, fieldState }) => (
              <FormControl fullWidth error={!!fieldState.error}>
                <FormLabel>{field.label}</FormLabel>
                <Select
                  {...fieldProps}
                  disabled={field.disabled}
                  required={field.required}
                >
                  {field.options?.map(option => (
                    <MenuItem key={option.value} value={option.value}>
                      {option.label}
                    </MenuItem>
                  ))}
                </Select>
                <FormHelperText>
                  {fieldState.error?.message || field.helperText}
                </FormHelperText>
              </FormControl>
            )}
          />
        );
      
      case 'multiselect':
        return (
          <Controller
            name={field.name}
            control={control}
            render={({ field: fieldProps, fieldState }) => (
              <FormControl fullWidth error={!!fieldState.error}>
                <FormLabel>{field.label}</FormLabel>
                <Select
                  {...fieldProps}
                  multiple
                  disabled={field.disabled}
                  required={field.required}
                  renderValue={(selected) => (
                    <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4 }}>
                      {(selected as string[]).map((value) => (
                        <Chip
                          key={value}
                          label={
                            field.options?.find(o => o.value === value)?.label || 
                            value
                          }
                          size="small"
                        />
                      ))}
                    </div>
                  )}
                >
                  {field.options?.map(option => (
                    <MenuItem key={option.value} value={option.value}>
                      {option.label}
                    </MenuItem>
                  ))}
                </Select>
                <FormHelperText>
                  {fieldState.error?.message || field.helperText}
                </FormHelperText>
              </FormControl>
            )}
          />
        );
      
      case 'autocomplete':
        return (
          <AsyncAutocomplete
            name={field.name}
            control={control}
            label={field.label}
            placeholder={field.placeholder}
            helperText={field.helperText}
            disabled={field.disabled}
            required={field.required}
            multiple={field.multiple}
            dataSource={field.dataSource!}
            createable={field.createable}
          />
        );
      
      case 'date':
      case 'datetime':
      case 'time':
        return (
          <Controller
            name={field.name}
            control={control}
            render={({ field: fieldProps, fieldState }) => {
              const Component = 
                field.type === 'date' ? DatePicker :
                field.type === 'time' ? TimePicker :
                DateTimePicker;
              
              return (
                <Component
                  {...fieldProps}
                  label={field.label}
                  disabled={field.disabled}
                  slotProps={{
                    textField: {
                      fullWidth: true,
                      error: !!fieldState.error,
                      helperText: fieldState.error?.message || field.helperText,
                      required: field.required
                    }
                  }}
                  minDate={field.minDate}
                  maxDate={field.maxDate}
                />
              );
            }}
          />
        );
      
      case 'boolean':
      case 'switch':
        return (
          <Controller
            name={field.name}
            control={control}
            render={({ field: fieldProps }) => (
              <FormControlLabel
                control={
                  <Switch
                    {...fieldProps}
                    checked={fieldProps.value || false}
                    disabled={field.disabled}
                  />
                }
                label={field.label}
              />
            )}
          />
        );
      
      case 'array':
        return (
          <ArrayField
            name={field.name}
            control={control}
            label={field.label}
            fields={field.arrayFields!}
            minItems={field.minItems}
            maxItems={field.maxItems}
          />
        );
      
      case 'richtext':
        return (
          <RichTextEditor
            name={field.name}
            control={control}
            label={field.label}
            placeholder={field.placeholder}
            helperText={field.helperText}
            disabled={field.disabled}
            required={field.required}
          />
        );
      
      case 'json':
        return (
          <JsonEditor
            name={field.name}
            control={control}
            label={field.label}
            schema={field.jsonSchema}
            helperText={field.helperText}
            disabled={field.disabled}
            required={field.required}
          />
        );
      
      case 'file':
        return (
          <FileUpload
            name={field.name}
            control={control}
            label={field.label}
            accept={field.accept}
            maxSize={field.maxSize}
            multiple={field.multiple}
            helperText={field.helperText}
            disabled={field.disabled}
            required={field.required}
          />
        );
      
      default:
        return null;
    }
  };
  
  // Handle form submission
  const handleFormSubmit = async (data: any) => {
    try {
      await onSubmit(data);
    } catch (error) {
      console.error('Form submission error:', error);
      // Handle error (show toast, etc.)
    }
  };
  
  // Render form sections
  const renderSection = (section: FormSection) => (
    <Paper key={section.id} sx={{ p: 3, mb: 2 }}>
      {section.title && (
        <>
          <Typography
            variant="h6"
            onClick={() => section.collapsible && toggleSection(section.id)}
            sx={{
              cursor: section.collapsible ? 'pointer' : 'default',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between'
            }}
          >
            {section.title}
            {section.collapsible && (
              <IconButton size="small">
                <ExpandMoreIcon
                  sx={{
                    transform: expandedSections.has(section.id) 
                      ? 'rotate(180deg)' 
                      : 'rotate(0deg)',
                    transition: 'transform 0.3s'
                  }}
                />
              </IconButton>
            )}
          </Typography>
          {section.description && (
            <Typography variant="body2" color="textSecondary" sx={{ mb: 2 }}>
              {section.description}
            </Typography>
          )}
          <Divider sx={{ mb: 2 }} />
        </>
      )}
      
      <Collapse in={expandedSections.has(section.id)} timeout="auto">
        <Grid container spacing={2}>
          {section.fields.map(field => (
            <Grid
              key={field.id}
              item
              xs={12}
              sm={field.width?.sm || 12}
              md={field.width?.md || 6}
              lg={field.width?.lg || 6}
            >
              {renderField(field)}
            </Grid>
          ))}
        </Grid>
      </Collapse>
    </Paper>
  );
  
  // Multi-step form
  if (definition.steps) {
    return (
      <form onSubmit={handleSubmit(handleFormSubmit)}>
        <Stepper activeStep={activeStep} sx={{ mb: 4 }}>
          {definition.steps.map((step, index) => (
            <Step key={step.id}>
              <StepLabel>{step.label}</StepLabel>
            </Step>
          ))}
        </Stepper>
        
        {renderSection(definition.sections[activeStep])}
        
        <div style={{ display: 'flex', justifyContent: 'space-between', mt: 3 }}>
          <Button
            disabled={activeStep === 0}
            onClick={() => setActiveStep(prev => prev - 1)}
          >
            Back
          </Button>
          
          <div>
            {onCancel && (
              <Button onClick={onCancel} sx={{ mr: 1 }}>
                Cancel
              </Button>
            )}
            
            {activeStep === definition.steps.length - 1 ? (
              <Button
                type="submit"
                variant="contained"
                disabled={isSubmitting}
                startIcon={isSubmitting ? <CircularProgress size={16} /> : <SaveIcon />}
              >
                {isSubmitting ? 'Saving...' : 'Save'}
              </Button>
            ) : (
              <Button
                variant="contained"
                onClick={async () => {
                  const stepFields = definition.sections[activeStep].fields
                    .map(f => f.name);
                  const isValid = await trigger(stepFields);
                  if (isValid) {
                    setActiveStep(prev => prev + 1);
                  }
                }}
              >
                Next
              </Button>
            )}
          </div>
        </div>
      </form>
    );
  }
  
  // Single page form
  return (
    <form onSubmit={handleSubmit(handleFormSubmit)}>
      {definition.sections.map(renderSection)}
      
      <div style={{ display: 'flex', justifyContent: 'flex-end', mt: 3 }}>
        {onCancel && (
          <Button onClick={onCancel} sx={{ mr: 1 }}>
            Cancel
          </Button>
        )}
        
        <Button
          type="submit"
          variant="contained"
          disabled={isSubmitting || !isDirty}
          startIcon={isSubmitting ? <CircularProgress size={16} /> : <SaveIcon />}
        >
          {isSubmitting ? 'Saving...' : 'Save'}
        </Button>
      </div>
    </form>
  );
};

// Array field component for dynamic arrays
const ArrayField: React.FC<{
  name: string;
  control: any;
  label: string;
  fields: FormField[];
  minItems?: number;
  maxItems?: number;
}> = ({ name, control, label, fields, minItems, maxItems }) => {
  const { fields: arrayFields, append, remove } = useFieldArray({
    control,
    name
  });
  
  const canAdd = !maxItems || arrayFields.length < maxItems;
  const canRemove = !minItems || arrayFields.length > minItems;
  
  return (
    <div>
      <Typography variant="subtitle1" gutterBottom>
        {label}
      </Typography>
      
      {arrayFields.map((item, index) => (
        <Paper key={item.id} sx={{ p: 2, mb: 1 }}>
          <Grid container spacing={2} alignItems="flex-start">
            {fields.map(field => (
              <Grid key={field.id} item xs={11}>
                {/* Render nested fields */}
              </Grid>
            ))}
            <Grid item xs={1}>
              <IconButton
                onClick={() => remove(index)}
                disabled={!canRemove}
                color="error"
              >
                <DeleteIcon />
              </IconButton>
            </Grid>
          </Grid>
        </Paper>
      ))}
      
      <Button
        startIcon={<AddIcon />}
        onClick={() => append(generateDefaultValues({ sections: [{ fields }] }))}
        disabled={!canAdd}
      >
        Add {label}
      </Button>
    </div>
  );
};
```

### Vue.js Form Implementation
```vue
<template>
  <form @submit.prevent="handleSubmit" class="dynamic-form">
    <!-- Multi-step form -->
    <template v-if="definition.steps">
      <div class="stepper">
        <div
          v-for="(step, index) in definition.steps"
          :key="step.id"
          :class="['step', { active: index === activeStep, completed: index < activeStep }]"
          @click="goToStep(index)"
        >
          <div class="step-number">{{ index + 1 }}</div>
          <div class="step-label">{{ step.label }}</div>
        </div>
      </div>
      
      <FormSection
        :section="definition.sections[activeStep]"
        :errors="errors"
        :values="formData"
        @update="updateField"
      />
      
      <div class="form-actions">
        <button
          type="button"
          @click="previousStep"
          :disabled="activeStep === 0"
          class="btn btn-secondary"
        >
          Back
        </button>
        
        <div>
          <button
            v-if="onCancel"
            type="button"
            @click="onCancel"
            class="btn btn-ghost"
          >
            Cancel
          </button>
          
          <button
            v-if="activeStep < definition.steps.length - 1"
            type="button"
            @click="nextStep"
            class="btn btn-primary"
          >
            Next
          </button>
          
          <button
            v-else
            type="submit"
            :disabled="isSubmitting"
            class="btn btn-primary"
          >
            <span v-if="isSubmitting">
              <Spinner size="small" /> Saving...
            </span>
            <span v-else>Save</span>
          </button>
        </div>
      </div>
    </template>
    
    <!-- Single page form -->
    <template v-else>
      <FormSection
        v-for="section in definition.sections"
        :key="section.id"
        :section="section"
        :errors="errors"
        :values="formData"
        :expanded="expandedSections.has(section.id)"
        @toggle="toggleSection(section.id)"
        @update="updateField"
      />
      
      <div class="form-actions">
        <button
          v-if="onCancel"
          type="button"
          @click="onCancel"
          class="btn btn-ghost"
        >
          Cancel
        </button>
        
        <button
          type="submit"
          :disabled="isSubmitting || !isDirty"
          class="btn btn-primary"
        >
          <span v-if="isSubmitting">
            <Spinner size="small" /> Saving...
          </span>
          <span v-else>Save</span>
        </button>
      </div>
    </template>
  </form>
</template>

<script setup lang="ts">
import { ref, computed, watch, reactive } from 'vue';
import { useForm } from '@vuelidate/core';
import { required, email, minLength, maxLength } from '@vuelidate/validators';
import type { FormDefinition, FormSection, FormField } from '@/types/forms';

interface Props {
  definition: FormDefinition;
  initialData?: any;
  onSubmit: (data: any) => Promise<void>;
  onCancel?: () => void;
}

const props = defineProps<Props>();
const emit = defineEmits(['update:modelValue']);

// Form state
const activeStep = ref(0);
const expandedSections = ref(new Set<string>(
  props.definition.sections
    .filter(s => !s.collapsible)
    .map(s => s.id)
));
const isSubmitting = ref(false);

// Form data and validation
const formData = reactive(
  props.initialData || generateDefaultValues(props.definition)
);

// Generate validation rules from definition
const rules = computed(() => {
  return generateValidationRules(props.definition);
});

const v$ = useForm(rules, formData);

// Track if form is dirty
const isDirty = computed(() => {
  return JSON.stringify(formData) !== JSON.stringify(props.initialData || {});
});

// Watch for conditional field dependencies
const conditionalFields = computed(() => {
  const fields: Record<string, FormField> = {};
  props.definition.sections.forEach(section => {
    section.fields.forEach(field => {
      if (field.conditional) {
        fields[field.name] = field;
      }
    });
  });
  return fields;
});

// Check field visibility
function isFieldVisible(field: FormField): boolean {
  if (!field.conditional) return true;
  
  return field.conditional.every(condition => {
    const fieldValue = formData[condition.field];
    
    switch (condition.operator) {
      case 'equals':
        return fieldValue === condition.value;
      case 'not_equals':
        return fieldValue !== condition.value;
      case 'contains':
        return Array.isArray(fieldValue)
          ? fieldValue.includes(condition.value)
          : String(fieldValue).includes(condition.value);
      case 'empty':
        return !fieldValue || 
          (Array.isArray(fieldValue) && fieldValue.length === 0);
      case 'not_empty':
        return fieldValue && 
          (!Array.isArray(fieldValue) || fieldValue.length > 0);
      default:
        return true;
    }
  });
}

// Handle field updates
function updateField(name: string, value: any) {
  formData[name] = value;
  v$.value[name].$touch();
}

// Section management
function toggleSection(sectionId: string) {
  if (expandedSections.value.has(sectionId)) {
    expandedSections.value.delete(sectionId);
  } else {
    expandedSections.value.add(sectionId);
  }
}

// Step navigation
async function nextStep() {
  // Validate current step fields
  const currentSection = props.definition.sections[activeStep.value];
  const stepValid = await validateSection(currentSection);
  
  if (stepValid) {
    activeStep.value++;
  }
}

function previousStep() {
  activeStep.value--;
}

function goToStep(index: number) {
  if (index < activeStep.value) {
    activeStep.value = index;
  }
}

// Validation
async function validateSection(section: FormSection): Promise<boolean> {
  const sectionFields = section.fields.map(f => f.name);
  let isValid = true;
  
  for (const fieldName of sectionFields) {
    if (v$.value[fieldName]) {
      await v$.value[fieldName].$validate();
      if (v$.value[fieldName].$error) {
        isValid = false;
      }
    }
  }
  
  return isValid;
}

// Form submission
async function handleSubmit() {
  const isValid = await v$.value.$validate();
  
  if (!isValid) {
    // Find first error and focus
    const firstError = Object.keys(v$.value).find(
      key => v$.value[key].$error
    );
    if (firstError) {
      const element = document.querySelector(`[name="${firstError}"]`);
      element?.focus();
    }
    return;
  }
  
  isSubmitting.value = true;
  
  try {
    await props.onSubmit(formData);
  } catch (error) {
    console.error('Form submission error:', error);
    // Handle error
  } finally {
    isSubmitting.value = false;
  }
}

// Generate default values from definition
function generateDefaultValues(definition: FormDefinition): any {
  const defaults: any = {};
  
  definition.sections.forEach(section => {
    section.fields.forEach(field => {
      if (field.defaultValue !== undefined) {
        defaults[field.name] = field.defaultValue;
      } else {
        switch (field.type) {
          case 'array':
            defaults[field.name] = [];
            break;
          case 'boolean':
          case 'switch':
            defaults[field.name] = false;
            break;
          case 'multiselect':
            defaults[field.name] = [];
            break;
          default:
            defaults[field.name] = null;
        }
      }
    });
  });
  
  return defaults;
}

// Generate validation rules
function generateValidationRules(definition: FormDefinition): any {
  const rules: any = {};
  
  definition.sections.forEach(section => {
    section.fields.forEach(field => {
      const fieldRules: any = {};
      
      if (field.required) {
        fieldRules.required = required;
      }
      
      if (field.type === 'email') {
        fieldRules.email = email;
      }
      
      if (field.minLength) {
        fieldRules.minLength = minLength(field.minLength);
      }
      
      if (field.maxLength) {
        fieldRules.maxLength = maxLength(field.maxLength);
      }
      
      if (field.validation?.custom) {
        fieldRules.custom = field.validation.custom;
      }
      
      if (Object.keys(fieldRules).length > 0) {
        rules[field.name] = fieldRules;
      }
    });
  });
  
  return rules;
}
</script>

<!-- Form Section Component -->
<template>
  <div class="form-section" :class="{ collapsed: !isExpanded }">
    <div
      v-if="section.title"
      class="section-header"
      :class="{ clickable: section.collapsible }"
      @click="section.collapsible && $emit('toggle')"
    >
      <h3 class="section-title">{{ section.title }}</h3>
      <ChevronDownIcon
        v-if="section.collapsible"
        class="collapse-icon"
        :class="{ rotated: isExpanded }"
      />
    </div>
    
    <p v-if="section.description" class="section-description">
      {{ section.description }}
    </p>
    
    <transition name="collapse">
      <div v-show="isExpanded" class="section-content">
        <div class="form-grid">
          <FormField
            v-for="field in visibleFields"
            :key="field.id"
            :field="field"
            :value="values[field.name]"
            :error="errors[field.name]"
            :class="getFieldClasses(field)"
            @update="(value) => $emit('update', field.name, value)"
          />
        </div>
      </div>
    </transition>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import type { FormSection, FormField } from '@/types/forms';

interface Props {
  section: FormSection;
  values: Record<string, any>;
  errors: Record<string, string>;
  expanded?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  expanded: true
});

const emit = defineEmits(['toggle', 'update']);

const isExpanded = computed(() => 
  props.section.collapsible ? props.expanded : true
);

const visibleFields = computed(() =>
  props.section.fields.filter(field => isFieldVisible(field, props.values))
);

function isFieldVisible(field: FormField, values: Record<string, any>): boolean {
  if (!field.conditional) return true;
  
  return field.conditional.every(condition => {
    const fieldValue = values[condition.field];
    
    switch (condition.operator) {
      case 'equals':
        return fieldValue === condition.value;
      case 'not_equals':
        return fieldValue !== condition.value;
      case 'contains':
        return Array.isArray(fieldValue)
          ? fieldValue.includes(condition.value)
          : String(fieldValue).includes(condition.value);
      case 'empty':
        return !fieldValue || 
          (Array.isArray(fieldValue) && fieldValue.length === 0);
      case 'not_empty':
        return fieldValue && 
          (!Array.isArray(fieldValue) || fieldValue.length > 0);
      default:
        return true;
    }
  });
}

function getFieldClasses(field: FormField) {
  return {
    [`col-span-${field.width?.default || 12}`]: true,
    [`sm:col-span-${field.width?.sm || field.width?.default || 12}`]: true,
    [`md:col-span-${field.width?.md || field.width?.sm || 6}`]: true,
    [`lg:col-span-${field.width?.lg || field.width?.md || 6}`]: true
  };
}
</script>
```

### Form Configuration Templates
```typescript
// Common form patterns
export const formTemplates = {
  // User registration form
  userRegistration: {
    sections: [
      {
        title: 'Account Information',
        fields: [
          {
            name: 'email',
            type: 'email',
            label: 'Email Address',
            required: true,
            validation: {
              async: true,
              endpoint: '/api/validate/email'
            }
          },
          {
            name: 'password',
            type: 'password',
            label: 'Password',
            required: true,
            validation: {
              minLength: 8,
              pattern: /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/,
              message: 'Password must contain uppercase, lowercase, and number'
            }
          },
          {
            name: 'confirmPassword',
            type: 'password',
            label: 'Confirm Password',
            required: true,
            validation: {
              match: 'password',
              message: 'Passwords must match'
            }
          }
        ]
      },
      {
        title: 'Personal Information',
        fields: [
          {
            name: 'firstName',
            type: 'text',
            label: 'First Name',
            required: true,
            width: { md: 6 }
          },
          {
            name: 'lastName',
            type: 'text',
            label: 'Last Name',
            required: true,
            width: { md: 6 }
          },
          {
            name: 'dateOfBirth',
            type: 'date',
            label: 'Date of Birth',
            maxDate: new Date()
          },
          {
            name: 'phone',
            type: 'tel',
            label: 'Phone Number',
            format: 'phone'
          }
        ]
      }
    ]
  },
  
  // Product creation form
  productCreation: {
    sections: [
      {
        title: 'Basic Information',
        fields: [
          {
            name: 'name',
            type: 'text',
            label: 'Product Name',
            required: true,
            maxLength: 100
          },
          {
            name: 'sku',
            type: 'text',
            label: 'SKU',
            required: true,
            validation: {
              pattern: /^[A-Z0-9-]+$/,
              message: 'SKU must contain only uppercase letters, numbers, and hyphens'
            }
          },
          {
            name: 'category',
            type: 'autocomplete',
            label: 'Category',
            required: true,
            dataSource: {
              endpoint: '/api/categories',
              labelField: 'name',
              valueField: 'id'
            }
          },
          {
            name: 'description',
            type: 'richtext',
            label: 'Description'
          }
        ]
      },
      {
        title: 'Pricing & Inventory',
        fields: [
          {
            name: 'price',
            type: 'number',
            label: 'Price',
            required: true,
            min: 0,
            step: 0.01,
            width: { md: 6 }
          },
          {
            name: 'comparePrice',
            type: 'number',
            label: 'Compare at Price',
            min: 0,
            step: 0.01,
            width: { md: 6 }
          },
          {
            name: 'trackInventory',
            type: 'switch',
            label: 'Track Inventory'
          },
          {
            name: 'quantity',
            type: 'number',
            label: 'Quantity',
            min: 0,
            conditional: [{
              field: 'trackInventory',
              operator: 'equals',
              value: true
            }]
          }
        ]
      },
      {
        title: 'Images',
        fields: [
          {
            name: 'images',
            type: 'file',
            label: 'Product Images',
            multiple: true,
            accept: 'image/*',
            maxSize: 5 * 1024 * 1024, // 5MB
            maxFiles: 10
          }
        ]
      }
    ]
  }
};
```

## Integration Points
- Receives field definitions from Schema Analyzer
- Uses validation rules from Validation Engineer
- Coordinates with UI Component Builder for field rendering
- Integrates with Theme Customizer for styling
- Works with Access Control Manager for field permissions

## Best Practices
1. Group related fields into logical sections
2. Use progressive disclosure for complex forms
3. Provide clear validation messages
4. Implement auto-save for long forms
5. Use appropriate input types for better UX
6. Support keyboard navigation
7. Provide contextual help and tooltips
8. Handle loading states for async operations
9. Implement proper error recovery
10. Optimize for mobile form filling