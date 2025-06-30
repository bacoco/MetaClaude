# Audit Accessibility Command

Comprehensive accessibility review and recommendations to ensure WCAG AAA compliance and inclusive design.

## Command Usage
```bash
clause --project UIDesignOrchestrator/project:audit-accessibility "component or page to audit"
```

## Audit Process

### 1. Automated Scanning
```javascript
const automatedAudit = {
  tools: ['axe-core', 'pa11y', 'lighthouse'],
  
  async runAudit(target) {
    const results = {
      colorContrast: await checkColorContrast(target),
      semanticHTML: await validateSemantics(target),
      ariaUsage: await checkARIA(target),
      keyboardNav: await testKeyboardAccess(target),
      imageAlts: await checkImages(target),
      formLabels: await validateForms(target),
      headingStructure: await checkHeadings(target),
      landmarks: await validateLandmarks(target)
    };
    
    return {
      score: calculateWCAGScore(results),
      violations: extractViolations(results),
      warnings: extractWarnings(results),
      passes: extractPasses(results)
    };
  }
};
```

### 2. Manual Testing Checklist
```yaml
screen_reader_tests:
  nvda_windows:
    - Navigate with headings (H key)
    - Check form announcements
    - Verify dynamic content updates
    - Test data table navigation
    
  voiceover_mac:
    - Rotor navigation check
    - Image descriptions audit
    - Interactive element labels
    - Page structure clarity
    
  mobile_readers:
    - TalkBack gesture navigation
    - VoiceOver touch exploration
    - Focus order verification
    - Touch target sizing

keyboard_navigation:
  - Tab through all interactive elements
  - Check visible focus indicators
  - Test escape key for modals
  - Verify no keyboard traps
  - Test custom keyboard shortcuts
  - Check skip links functionality

cognitive_accessibility:
  - Plain language usage
  - Clear instructions
  - Error prevention
  - Consistent navigation
  - Progress indicators
  - Timeout warnings
```

### 3. Component-Specific Audits

#### Modal/Dialog Audit
```javascript
const modalAudit = {
  structure: {
    role: 'Check role="dialog" present',
    ariaModal: 'Verify aria-modal="true"',
    labelledby: 'Ensure aria-labelledby points to heading',
    describedby: 'Check aria-describedby for description'
  },
  
  focus: {
    management: 'Focus moves to modal on open',
    trap: 'Focus trapped within modal',
    return: 'Focus returns to trigger on close',
    firstElement: 'Focus on close button or first interactive'
  },
  
  keyboard: {
    escape: 'ESC key closes modal',
    tab: 'Tab cycles through modal only',
    enter: 'Enter submits forms/activates buttons'
  },
  
  screen_reader: {
    announcement: 'Modal opening announced',
    context: 'User knows they\'re in a modal',
    instructions: 'Available actions clear'
  }
};
```

#### Form Audit
```javascript
const formAudit = {
  labels: {
    association: 'All inputs have associated labels',
    visibility: 'Labels visible (not placeholder only)',
    required: 'Required fields marked accessibly',
    groups: 'Related fields grouped with fieldset/legend'
  },
  
  errors: {
    announcement: 'Errors announced on occurrence',
    identification: 'Error fields clearly marked',
    description: 'Helpful error messages provided',
    association: 'Errors linked to fields with aria-describedby'
  },
  
  instructions: {
    placement: 'Help text before form',
    clarity: 'Instructions clear and concise',
    format: 'Format examples provided (date, phone)',
    context: 'Purpose of form clear'
  },
  
  validation: {
    inline: 'Real-time validation accessible',
    summary: 'Error summary at form top',
    success: 'Success confirmations clear',
    prevention: 'Confirmation for destructive actions'
  }
};
```

#### Navigation Audit
```javascript
const navigationAudit = {
  structure: {
    landmark: '<nav> element or role="navigation"',
    label: 'aria-label for multiple navs',
    heading: 'Navigation preceded by heading',
    list: 'Links in unordered list'
  },
  
  state: {
    current: 'aria-current="page" for active',
    expanded: 'aria-expanded for submenus',
    popup: 'aria-haspopup for dropdowns'
  },
  
  mobile: {
    trigger: 'Menu button properly labeled',
    state: 'Open/closed state announced',
    gesture: 'Touch-friendly interactions',
    alternative: 'Non-JS fallback available'
  }
};
```

### 4. Report Generation

#### Executive Summary
```markdown
# Accessibility Audit Report

**Date**: 2024-01-20
**Auditor**: UI Designer Claude
**Target**: E-commerce Checkout Flow
**Overall Score**: 87/100 (WCAG AA Partial)

## Summary
- ✅ **23** Passed Criteria
- ⚠️ **5** Warnings
- ❌ **3** Violations
- 🎯 **Target**: WCAG AAA Compliance

## Critical Issues

### 1. Insufficient Color Contrast ❌
**Location**: Form input placeholder text
**Current**: 2.9:1 ratio
**Required**: 4.5:1 minimum
**Impact**: Low vision users cannot read placeholders
**Fix**: Change color from #999999 to #767676

### 2. Missing Form Labels ❌
**Location**: Credit card number input
**Current**: Placeholder only
**Required**: Visible or screen reader accessible label
**Impact**: Screen reader users lack context
**Fix**: Add <label> or aria-label

### 3. Keyboard Trap ❌
**Location**: Date picker widget
**Current**: Cannot escape with keyboard
**Required**: ESC key or focus management
**Impact**: Keyboard users stuck
**Fix**: Implement proper focus trap with escape
```

#### Detailed Findings
```javascript
const detailedFindings = {
  colorContrast: {
    violations: [
      {
        element: 'input::placeholder',
        foreground: '#999999',
        background: '#FFFFFF',
        ratio: 2.9,
        required: 4.5,
        suggestion: '#767676'
      }
    ],
    warnings: [
      {
        element: '.secondary-text',
        ratio: 4.3,
        note: 'Close to minimum, consider increasing'
      }
    ]
  },
  
  semanticHTML: {
    issues: [
      {
        element: 'div.button',
        issue: 'Non-semantic element used as button',
        fix: 'Use <button> element'
      }
    ]
  },
  
  keyboard: {
    passes: [
      'All interactive elements reachable',
      'Focus indicators visible',
      'Tab order logical'
    ],
    failures: [
      'Date picker traps focus',
      'Custom dropdown not keyboard accessible'
    ]
  }
};
```

### 5. Remediation Guide

#### Quick Fixes (< 1 hour)
```css
/* Fix 1: Improve color contrast */
.input::placeholder {
  color: #767676; /* Was #999999 */
}

.secondary-text {
  color: #595959; /* Was #777777 */
}

/* Fix 2: Add focus indicators */
:focus {
  outline: 3px solid #0066FF;
  outline-offset: 2px;
}

/* Fix 3: Increase touch targets */
.button, .link {
  min-height: 44px;
  min-width: 44px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}
```

#### Code Fixes (1-4 hours)
```html
<!-- Fix: Add proper labels -->
<div class="form-group">
  <label for="card-number" class="form-label">
    Card Number
    <span class="required" aria-label="required">*</span>
  </label>
  <input 
    type="text" 
    id="card-number"
    aria-required="true"
    aria-describedby="card-error card-help"
  >
  <span id="card-help" class="help-text">
    Enter without spaces or dashes
  </span>
  <span id="card-error" class="error-text" role="alert">
    <!-- Error messages inserted here -->
  </span>
</div>

<!-- Fix: Semantic button -->
<button 
  type="button" 
  class="btn-primary"
  aria-label="Add to cart"
>
  <svg aria-hidden="true">...</svg>
  <span>Add to Cart</span>
</button>
```

#### Component Replacements (4+ hours)
```javascript
// Replace inaccessible date picker
import { DatePicker } from '@accessible/date-picker';

const AccessibleDatePicker = () => (
  <DatePicker
    label="Select delivery date"
    minDate={tomorrow}
    maxDate={nextMonth}
    onChange={handleDateChange}
    // Built-in keyboard navigation
    // Screen reader support
    // Mobile friendly
  />
);
```

### 6. Testing Verification
```javascript
const verificationTests = {
  automated: {
    before: { score: 73, violations: 12 },
    after: { score: 96, violations: 1 },
    tools: ['axe-core', 'lighthouse']
  },
  
  manual: {
    screenReader: {
      tested: ['NVDA', 'VoiceOver'],
      issues_resolved: ['Form navigation', 'Error announcements']
    },
    keyboard: {
      tested: ['Tab navigation', 'Arrow keys', 'Escape'],
      issues_resolved: ['Focus trap', 'Skip links']
    }
  },
  
  user_testing: {
    participants: 3,
    disabilities: ['Low vision', 'Motor', 'Cognitive'],
    success_rate: '95%',
    feedback: 'Much easier to navigate and understand'
  }
};
```

## Best Practices Guide

### Design Phase
```yaml
accessible_design_checklist:
  colors:
    - Use color contrast analyzer during design
    - Never rely on color alone for information
    - Test with color blindness simulators
    
  typography:
    - Minimum 16px for body text
    - Line height at least 1.5
    - Sufficient paragraph spacing
    
  layout:
    - Logical reading order
    - Clear visual hierarchy
    - Consistent navigation placement
    
  interactions:
    - 44px minimum touch targets
    - Clear focus indicators
    - Predictable interactions
```

### Development Phase
```javascript
// Accessibility-first component template
const AccessibleComponent = ({ label, description, ...props }) => {
  const id = useId();
  const descId = `${id}-desc`;
  
  return (
    <div role="region" aria-labelledby={id}>
      <h2 id={id}>{label}</h2>
      {description && (
        <p id={descId} className="sr-only">
          {description}
        </p>
      )}
      <div aria-describedby={description ? descId : undefined}>
        {/* Component content */}
      </div>
    </div>
  );
};
```

## Tool Integration

| Step | Action | Tool to Use | Purpose |
|------|--------|-------------|----------|
| 1. Read component | Load existing code | `read_file("Component.jsx")` | Analyze current implementation |
| 2. Automated scan | Internal analysis | None | Check WCAG criteria internally |
| 3. Generate report | Create findings | None (in response) | Present issues and recommendations |
| 4. Fix critical issues | Update code | `write_file("Component.jsx", fixed)` | Apply accessibility fixes |
| 5. Verify changes | Check improvements | `read_file` + internal analysis | Confirm fixes work |
| 6. Document | Save audit report | `write_file("audit-report.md")` (if requested) | Preserve findings |

### Tool Usage Examples
```javascript
// Step 1: Analyze existing component
const componentCode = read_file("src/components/Card.jsx");
const auditFindings = analyzeAccessibility(componentCode);

// Step 3: Apply fixes (only if user approves)
if (userApprovessFixes) {
  write_file("src/components/Card.jsx", accessibleCode);
}

// Step 4: Generate report (only if requested)
if (userWantsReport) {
  write_file("accessibility-audit.md", auditReport);
}
```

## Success Metrics
```javascript
const successCriteria = {
  compliance: {
    wcag_aa: '100% pass rate',
    wcag_aaa: '95% pass rate (where applicable)'
  },
  
  usability: {
    task_completion: '95% with assistive tech',
    time_on_task: 'Within 150% of baseline',
    error_rate: 'Less than 5%'
  },
  
  satisfaction: {
    ease_of_use: '4.5/5 rating',
    would_recommend: '90% yes',
    perceived_accessibility: 'Excellent'
  }
};
```

---

*Audit Accessibility v1.0 | WCAG compliance tool | Inclusive design validator*