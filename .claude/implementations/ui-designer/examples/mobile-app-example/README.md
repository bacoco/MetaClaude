# Mobile App Example: HealthTracker

Complete example of using UI Designer Orchestrator to design a health and fitness tracking mobile application.

## Project Overview

**App Name**: HealthTracker  
**Type**: Native Mobile App (iOS/Android)  
**Target Audience**: Health-conscious individuals aged 25-45  
**Timeline**: 2 weeks  

## Step 1: Initialize Project

```
"Create a health tracking mobile app called HealthTracker"
```

### Initial Brief
```
Create a mobile app for tracking daily health metrics including steps, water intake, 
sleep, and mood. The app should feel encouraging, personal, and scientifically accurate 
while being simple enough for daily use. Target users are busy professionals who want 
to improve their health habits without complexity.
```

## Step 2: Research Phase

### Command Execution
```
# Extract design DNA from health app inspiration
"Extract design DNA from:
- Headspace (calming, minimal)
- MyFitnessPal (data-rich, functional)  
- Apple Health (clean, authoritative)
- Calm (peaceful, organic)"
```

### Research Output
```json
{
  "personas": {
    "primary": "Emma Watson - Busy Marketing Manager",
    "characteristics": [
      "Wants quick daily logging",
      "Motivated by progress visualization",
      "Prefers gentle reminders",
      "Values privacy and data security"
    ]
  },
  "designDNA": {
    "colors": {
      "primary": "#4CD964",  // Fresh green for positivity
      "secondary": "#5AC8FA", // Calm blue for trust
      "accent": "#FF9500",    // Warm orange for energy
      "neutral": "#F2F2F7"    // Soft backgrounds
    },
    "personality": ["Encouraging", "Scientific", "Personal", "Calm"]
  }
}
```

## Step 3: MVP Concept

### Command
```
"Generate an MVP concept for HealthTracker - mobile app for daily health tracking with focus on building positive habits through gentle encouragement and clear progress visualization"
```

### MVP Features
1. **Daily Check-in** (Core)
   - Quick mood selection
   - Water intake counter
   - Sleep hours input
   - Step count (auto)

2. **Progress Dashboard** (Core)
   - Weekly trends
   - Streak tracking
   - Personal records
   - Health score

3. **Gentle Reminders** (Core)
   - Customizable notifications
   - Positive reinforcement
   - No guilt messaging

4. **Data Insights** (Nice-to-have)
   - Correlation discovery
   - Personalized tips
   - Export capabilities

## Step 4: Design System

### Command
```
"Create the design system using the design system first pattern"
```

### Generated System
```javascript
const healthTrackerTokens = {
  colors: {
    // Health-focused palette
    primary: {
      fresh: '#4CD964',      // Primary green
      fresh_light: '#A0E7A8',
      fresh_dark: '#34A853'
    },
    secondary: {
      calm: '#5AC8FA',       // Secondary blue
      calm_light: '#B3E5FC',
      calm_dark: '#0288D1'
    },
    semantic: {
      energy: '#FF9500',     // Energy orange
      rest: '#AF52DE',       // Rest purple
      warning: '#FFCC00',    // Gentle warning
      success: '#4CD964'     // Same as primary
    }
  },
  
  typography: {
    // Friendly, readable fonts
    primary: 'SF Pro Display',
    body: 'SF Pro Text',
    scale: {
      hero: 34,
      title: 28,
      heading: 22,
      body: 17,
      caption: 13
    }
  },
  
  spacing: {
    // Comfortable mobile spacing
    unit: 8,
    touchTarget: 48,
    cardPadding: 16,
    sectionGap: 24
  },
  
  mobile: {
    // Mobile-specific tokens
    cornerRadius: 16,
    elevation: {
      low: '0 2px 8px rgba(0,0,0,0.1)',
      medium: '0 4px 16px rgba(0,0,0,0.15)',
      high: '0 8px 24px rgba(0,0,0,0.2)'
    }
  }
};
```

## Step 5: UI Generation

### Command
```
"Create UI variations for:
- Onboarding flow (3 screens)
- Home dashboard  
- Daily check-in flow
- Progress/trends screen
- Settings/profile"
```

### Generated Variations

#### Home Dashboard - Selected: "Minimal Cards"
```html
<!-- React Native Component -->
<View style={styles.container}>
  <!-- Header -->
  <View style={styles.header}>
    <Text style={styles.greeting}>Good morning, Emma!</Text>
    <Text style={styles.date}>Thursday, January 20</Text>
  </View>
  
  <!-- Health Score Card -->
  <TouchableOpacity style={styles.scoreCard}>
    <View style={styles.scoreCircle}>
      <Text style={styles.scoreNumber}>87</Text>
      <Text style={styles.scoreLabel}>Health Score</Text>
    </View>
    <Text style={styles.scoreMessage}>You're doing great! 🌟</Text>
  </TouchableOpacity>
  
  <!-- Quick Stats Grid -->
  <View style={styles.statsGrid}>
    <MetricCard 
      icon="footsteps"
      value="7,234"
      label="Steps"
      color={colors.primary.fresh}
      progress={0.72}
    />
    <MetricCard 
      icon="water"
      value="5/8"
      label="Glasses"
      color={colors.secondary.calm}
      progress={0.625}
    />
    <MetricCard 
      icon="moon"
      value="7.5h"
      label="Sleep"
      color={colors.semantic.rest}
      progress={0.94}
    />
    <MetricCard 
      icon="heart"
      value="Good"
      label="Mood"
      color={colors.semantic.energy}
      progress={1.0}
    />
  </View>
  
  <!-- CTA Button -->
  <TouchableOpacity style={styles.checkInButton}>
    <Text style={styles.checkInText}>Complete Today's Check-in</Text>
  </TouchableOpacity>
</View>
```

#### Daily Check-in Flow
```javascript
// Mood Selection Screen
const MoodSelector = () => {
  const moods = [
    { emoji: '😊', label: 'Great', color: '#4CD964' },
    { emoji: '🙂', label: 'Good', color: '#5AC8FA' },
    { emoji: '😐', label: 'Okay', color: '#FFCC00' },
    { emoji: '😔', label: 'Low', color: '#FF9500' },
    { emoji: '😣', label: 'Stressed', color: '#FF3B30' }
  ];
  
  return (
    <View style={styles.container}>
      <Text style={styles.question}>How are you feeling today?</Text>
      <View style={styles.moodGrid}>
        {moods.map(mood => (
          <TouchableOpacity 
            key={mood.label}
            style={[styles.moodButton, { borderColor: mood.color }]}
            onPress={() => selectMood(mood)}
          >
            <Text style={styles.moodEmoji}>{mood.emoji}</Text>
            <Text style={styles.moodLabel}>{mood.label}</Text>
          </TouchableOpacity>
        ))}
      </View>
    </View>
  );
};
```

## Step 6: Accessibility & Testing

### Command
```
"Audit the accessibility of the HealthTracker mobile app"
```

### Results
- ✅ All touch targets ≥ 48px
- ✅ Color contrast ratios pass WCAG AA
- ✅ Screen reader labels implemented
- ✅ Haptic feedback for interactions
- ⚠️ Added high contrast mode option

### User Testing Insights
1. **Onboarding**: Users loved the 3-step simplicity
2. **Daily Check-in**: 30-second completion time achieved
3. **Notifications**: Gentle reminders well-received
4. **Data Viz**: Weekly trends most valued feature

## Step 7: Design Iteration

### Command
```
"Iterate on the designs based on user feedback:
- Make mood selector larger and more prominent
- Add quick-add buttons for water tracking
- Show yesterday comparison on dashboard
- Add celebration animations for streaks"
```

## Step 8: Final Export

### Command
```
"Export the design system for mobile implementation"
```

### Deliverables
1. **Design System**
   - iOS components (Swift)
   - Android components (Kotlin)
   - React Native components
   - Token documentation

2. **Screen Designs**
   - 15 complete screens
   - All states (empty, loading, error)
   - Dark mode variants
   - Tablet adaptations

3. **Prototype**
   - Interactive Figma prototype
   - Lottie animations
   - Micro-interactions documented

4. **Developer Handoff**
   - Detailed specifications
   - Asset exports (1x, 2x, 3x)
   - Animation timings
   - API requirements

## Project Outcomes

### Metrics
- **Design Time**: 2 weeks (vs 4-6 traditional)
- **Variations Generated**: 75 screens
- **User Satisfaction**: 4.8/5
- **Accessibility Score**: WCAG AA compliant

### Key Learnings
1. Vibe design approach created cohesive emotional experience
2. Parallel generation allowed rapid exploration
3. Early accessibility focus prevented costly fixes
4. User research drove successful feature prioritization

## Running This Example

```bash
# Clone the example
cd UIDesignerClaude/examples/mobile-app-example
```

### Run the workflow with Claude Code:

```
# Run the complete workflow
"Create a complete UI project for HealthTracker mobile app"

# Or run specific commands
"Extract design DNA from health app screenshots"
"Create UI variations for dashboard, check-in, and progress screens"
```

---

*Mobile App Example v1.0 | HealthTracker | Complete implementation guide*