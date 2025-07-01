# Example Model Training Notebook

This notebook demonstrates the Model Development workflow using the Data Scientist specialist. It shows the complete process from data preparation through model deployment preparation.

## Setup and Initialization

```python
# Import required libraries
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime
import warnings
warnings.filterwarnings('ignore')

# Import ML libraries
from sklearn.model_selection import train_test_split, cross_val_score, StratifiedKFold
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.metrics import classification_report, confusion_matrix, roc_auc_score, roc_curve
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
import xgboost as xgb
import lightgbm as lgb

# Import MetaClaude Data Scientist components
from metaclaude.implementations.data_scientist import (
    MLEngineer,
    StatisticalAnalyst,
    InsightGenerator,
    ModelDevelopmentWorkflow
)

# Initialize agents
ml_engineer = MLEngineer()
stat_analyst = StatisticalAnalyst()
insight_gen = InsightGenerator()

# Set random seed for reproducibility
np.random.seed(42)
```

## Problem Definition

```python
# Define the business problem
problem_definition = {
    'business_objective': 'Predict customer churn to enable proactive retention strategies',
    'ml_task': 'binary_classification',
    'target_variable': 'churned',
    'success_metrics': {
        'primary': 'f1_score',  # Balance between precision and recall
        'secondary': ['precision', 'recall', 'auc_roc'],
        'business': 'customer_retention_rate'
    },
    'constraints': {
        'inference_time': '< 100ms',
        'model_interpretability': 'required',
        'deployment_environment': 'cloud_api'
    },
    'baseline_performance': 0.65  # Current rule-based system F1 score
}

print("=== Problem Definition ===")
for key, value in problem_definition.items():
    print(f"{key}: {value}")
```

## Load and Prepare Data

```python
# Generate synthetic customer churn dataset
# In practice, replace with your actual data

n_customers = 10000

# Create features
data = pd.DataFrame({
    'customer_id': range(1, n_customers + 1),
    'tenure_months': np.random.exponential(24, n_customers).clip(1, 120).astype(int),
    'monthly_charges': np.random.gamma(2, 30, n_customers),
    'total_charges': np.nan,  # Will calculate based on tenure and monthly
    'contract_type': np.random.choice(['Month-to-month', 'One year', 'Two year'], 
                                     n_customers, p=[0.5, 0.3, 0.2]),
    'payment_method': np.random.choice(['Bank transfer', 'Credit card', 'Electronic check', 'Mailed check'], 
                                      n_customers, p=[0.3, 0.3, 0.3, 0.1]),
    'paperless_billing': np.random.choice([0, 1], n_customers, p=[0.4, 0.6]),
    'num_services': np.random.poisson(3, n_customers) + 1,
    'tech_support_calls': np.random.poisson(2, n_customers),
    'satisfaction_score': np.random.beta(7, 3, n_customers) * 5,  # 1-5 scale
    'last_interaction_days': np.random.exponential(30, n_customers).astype(int)
})

# Calculate total charges
data['total_charges'] = data['tenure_months'] * data['monthly_charges'] * (1 + np.random.normal(0, 0.1, n_customers))

# Create churn target based on logical rules + randomness
churn_probability = (
    (data['contract_type'] == 'Month-to-month').astype(float) * 0.3 +
    (data['satisfaction_score'] < 3).astype(float) * 0.4 +
    (data['tech_support_calls'] > 5).astype(float) * 0.2 +
    (data['tenure_months'] < 12).astype(float) * 0.1 +
    np.random.normal(0, 0.1, n_customers)
).clip(0, 1)

data['churned'] = (churn_probability > np.random.uniform(0, 1, n_customers)).astype(int)

print(f"Dataset shape: {data.shape}")
print(f"Churn rate: {data['churned'].mean():.2%}")
print("\nFirst few rows:")
data.head()
```

## Exploratory Data Analysis

```python
# Quick EDA for modeling
print("=== Target Variable Distribution ===")
print(data['churned'].value_counts())
print(f"\nClass balance: {data['churned'].value_counts(normalize=True).round(3).to_dict()}")

# Visualize target distribution
plt.figure(figsize=(6, 4))
data['churned'].value_counts().plot(kind='bar')
plt.title('Churn Distribution')
plt.xlabel('Churned (0=No, 1=Yes)')
plt.ylabel('Count')
plt.xticks(rotation=0)
plt.show()

# Feature distributions by target
fig, axes = plt.subplots(2, 3, figsize=(15, 10))
axes = axes.ravel()

numerical_features = ['tenure_months', 'monthly_charges', 'total_charges', 
                     'satisfaction_score', 'tech_support_calls', 'last_interaction_days']

for idx, feature in enumerate(numerical_features):
    data.boxplot(column=feature, by='churned', ax=axes[idx])
    axes[idx].set_title(f'{feature} by Churn Status')

plt.tight_layout()
plt.show()

# Correlation with target
correlations = data[numerical_features + ['churned']].corr()['churned'].sort_values(ascending=False)
print("\n=== Feature Correlations with Churn ===")
print(correlations.round(3))
```

## Feature Engineering

```python
# Create new features based on domain knowledge
feature_engineering_pipeline = ml_engineer.create_feature_pipeline()

# Tenure-based features
data['tenure_group'] = pd.cut(data['tenure_months'], 
                              bins=[0, 12, 24, 48, 120], 
                              labels=['0-1yr', '1-2yr', '2-4yr', '4+yr'])

# Charges features
data['avg_monthly_charges'] = data['total_charges'] / data['tenure_months']
data['charges_per_service'] = data['monthly_charges'] / data['num_services']

# Interaction features
data['support_calls_per_tenure'] = data['tech_support_calls'] / (data['tenure_months'] + 1)
data['high_value_customer'] = ((data['total_charges'] > data['total_charges'].quantile(0.75)) & 
                               (data['tenure_months'] > 24)).astype(int)

# Engagement score
data['engagement_score'] = (
    (data['paperless_billing'] * 0.2) +
    (1 / (data['last_interaction_days'] + 1) * 10) +
    (data['satisfaction_score'] / 5 * 0.5)
)

print("=== Feature Engineering Complete ===")
print(f"New total features: {len(data.columns) - 1}")  # Exclude target
print("\nNew features created:")
new_features = ['tenure_group', 'avg_monthly_charges', 'charges_per_service', 
                'support_calls_per_tenure', 'high_value_customer', 'engagement_score']
for feature in new_features:
    print(f"  - {feature}")
```

## Data Preprocessing

```python
# Separate features and target
target = 'churned'
features_to_drop = ['customer_id', 'churned']
feature_columns = [col for col in data.columns if col not in features_to_drop]

X = data[feature_columns].copy()
y = data[target].copy()

# Handle categorical variables
categorical_columns = X.select_dtypes(include=['object']).columns.tolist()
numerical_columns = X.select_dtypes(include=['int64', 'float64']).columns.tolist()

print(f"Categorical features ({len(categorical_columns)}): {categorical_columns}")
print(f"Numerical features ({len(numerical_columns)}): {numerical_columns}")

# Encode categorical variables
from sklearn.preprocessing import OneHotEncoder
from sklearn.compose import ColumnTransformer

# Create preprocessing pipeline
preprocessor = ColumnTransformer(
    transformers=[
        ('num', StandardScaler(), numerical_columns),
        ('cat', OneHotEncoder(drop='first', sparse_output=False), categorical_columns)
    ])

# Fit and transform
X_processed = preprocessor.fit_transform(X)

# Get feature names after encoding
cat_encoder = preprocessor.named_transformers_['cat']
cat_feature_names = cat_encoder.get_feature_names_out(categorical_columns).tolist()
all_feature_names = numerical_columns + cat_feature_names

print(f"\nTotal features after preprocessing: {X_processed.shape[1]}")

# Convert back to DataFrame for easier handling
X_processed = pd.DataFrame(X_processed, columns=all_feature_names)
```

## Train-Test Split

```python
# Stratified split to maintain class balance
X_train, X_test, y_train, y_test = train_test_split(
    X_processed, y, 
    test_size=0.2, 
    random_state=42, 
    stratify=y
)

# Further split train into train and validation
X_train, X_val, y_train, y_val = train_test_split(
    X_train, y_train, 
    test_size=0.25,  # 0.25 * 0.8 = 0.2 of total data
    random_state=42, 
    stratify=y_train
)

print("=== Data Split ===")
print(f"Training set: {X_train.shape[0]} samples ({y_train.mean():.2%} positive)")
print(f"Validation set: {X_val.shape[0]} samples ({y_val.mean():.2%} positive)")
print(f"Test set: {X_test.shape[0]} samples ({y_test.mean():.2%} positive)")
```

## Model Selection and Training

```python
# Initialize multiple models for comparison
models = {
    'Logistic Regression': LogisticRegression(random_state=42, max_iter=1000),
    'Random Forest': RandomForestClassifier(n_estimators=100, random_state=42, n_jobs=-1),
    'XGBoost': xgb.XGBClassifier(random_state=42, eval_metric='logloss', use_label_encoder=False),
    'LightGBM': lgb.LGBMClassifier(random_state=42, verbose=-1)
}

# Train and evaluate each model
model_results = {}

for name, model in models.items():
    print(f"\n=== Training {name} ===")
    
    # Train model
    start_time = datetime.now()
    model.fit(X_train, y_train)
    training_time = (datetime.now() - start_time).total_seconds()
    
    # Make predictions
    y_pred_train = model.predict(X_train)
    y_pred_val = model.predict(X_val)
    y_pred_proba_val = model.predict_proba(X_val)[:, 1]
    
    # Calculate metrics
    from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score
    
    metrics = {
        'train_accuracy': accuracy_score(y_train, y_pred_train),
        'val_accuracy': accuracy_score(y_val, y_pred_val),
        'precision': precision_score(y_val, y_pred_val),
        'recall': recall_score(y_val, y_pred_val),
        'f1_score': f1_score(y_val, y_pred_val),
        'auc_roc': roc_auc_score(y_val, y_pred_proba_val),
        'training_time': training_time
    }
    
    model_results[name] = {
        'model': model,
        'metrics': metrics,
        'predictions': y_pred_val,
        'probabilities': y_pred_proba_val
    }
    
    print(f"Validation F1 Score: {metrics['f1_score']:.4f}")
    print(f"Validation AUC-ROC: {metrics['auc_roc']:.4f}")
    print(f"Training Time: {training_time:.2f}s")

# Compare models
comparison_df = pd.DataFrame({name: results['metrics'] for name, results in model_results.items()}).T
print("\n=== Model Comparison ===")
print(comparison_df.round(4))

# Select best model based on primary metric (F1 score)
best_model_name = comparison_df['f1_score'].idxmax()
best_model = model_results[best_model_name]['model']
print(f"\nBest model: {best_model_name} (F1 Score: {comparison_df.loc[best_model_name, 'f1_score']:.4f})")
```

## Hyperparameter Optimization

```python
# Optimize the best model's hyperparameters
print(f"\n=== Hyperparameter Optimization for {best_model_name} ===")

from sklearn.model_selection import RandomizedSearchCV

# Define parameter grid based on model type
if best_model_name == 'Random Forest':
    param_dist = {
        'n_estimators': [100, 200, 300, 500],
        'max_depth': [10, 20, 30, None],
        'min_samples_split': [2, 5, 10],
        'min_samples_leaf': [1, 2, 4],
        'max_features': ['sqrt', 'log2', None],
        'bootstrap': [True, False]
    }
elif best_model_name == 'XGBoost':
    param_dist = {
        'n_estimators': [100, 200, 300],
        'max_depth': [3, 5, 7, 9],
        'learning_rate': [0.01, 0.05, 0.1, 0.3],
        'subsample': [0.8, 0.9, 1.0],
        'colsample_bytree': [0.8, 0.9, 1.0],
        'gamma': [0, 0.1, 0.2]
    }
elif best_model_name == 'LightGBM':
    param_dist = {
        'n_estimators': [100, 200, 300],
        'num_leaves': [31, 50, 100],
        'learning_rate': [0.01, 0.05, 0.1],
        'feature_fraction': [0.8, 0.9, 1.0],
        'bagging_fraction': [0.8, 0.9, 1.0],
        'min_child_samples': [20, 30, 40]
    }
else:  # Logistic Regression
    param_dist = {
        'C': [0.001, 0.01, 0.1, 1, 10, 100],
        'penalty': ['l1', 'l2'],
        'solver': ['liblinear', 'saga'],
        'class_weight': [None, 'balanced']
    }

# Perform random search
random_search = RandomizedSearchCV(
    estimator=models[best_model_name],
    param_distributions=param_dist,
    n_iter=50,
    cv=StratifiedKFold(n_splits=5),
    scoring='f1',
    n_jobs=-1,
    random_state=42,
    verbose=1
)

# Fit random search
random_search.fit(X_train, y_train)

print(f"\nBest parameters: {random_search.best_params_}")
print(f"Best CV F1 Score: {random_search.best_score_:.4f}")

# Use the optimized model
optimized_model = random_search.best_estimator_
```

## Model Evaluation

```python
# Evaluate optimized model on validation set
y_pred_val = optimized_model.predict(X_val)
y_pred_proba_val = optimized_model.predict_proba(X_val)[:, 1]

print("=== Optimized Model Performance on Validation Set ===")
print("\nClassification Report:")
print(classification_report(y_val, y_pred_val))

# Confusion Matrix
cm = confusion_matrix(y_val, y_pred_val)
plt.figure(figsize=(8, 6))
sns.heatmap(cm, annot=True, fmt='d', cmap='Blues')
plt.title('Confusion Matrix - Validation Set')
plt.ylabel('True Label')
plt.xlabel('Predicted Label')
plt.show()

# ROC Curve
fpr, tpr, thresholds = roc_curve(y_val, y_pred_proba_val)
auc = roc_auc_score(y_val, y_pred_proba_val)

plt.figure(figsize=(8, 6))
plt.plot(fpr, tpr, color='darkorange', lw=2, label=f'ROC curve (AUC = {auc:.3f})')
plt.plot([0, 1], [0, 1], color='navy', lw=2, linestyle='--')
plt.xlim([0.0, 1.0])
plt.ylim([0.0, 1.05])
plt.xlabel('False Positive Rate')
plt.ylabel('True Positive Rate')
plt.title('ROC Curve - Validation Set')
plt.legend(loc="lower right")
plt.show()

# Feature Importance
if hasattr(optimized_model, 'feature_importances_'):
    feature_importance = pd.DataFrame({
        'feature': all_feature_names,
        'importance': optimized_model.feature_importances_
    }).sort_values('importance', ascending=False)
    
    plt.figure(figsize=(10, 8))
    top_features = feature_importance.head(15)
    plt.barh(top_features['feature'], top_features['importance'])
    plt.xlabel('Feature Importance')
    plt.title('Top 15 Most Important Features')
    plt.gca().invert_yaxis()
    plt.tight_layout()
    plt.show()
    
    print("\nTop 10 Most Important Features:")
    print(feature_importance.head(10).to_string(index=False))
```

## Cross-Validation

```python
# Perform thorough cross-validation
cv_scores = cross_val_score(
    optimized_model, 
    X_train, 
    y_train, 
    cv=StratifiedKFold(n_splits=5, shuffle=True, random_state=42),
    scoring='f1',
    n_jobs=-1
)

print("=== Cross-Validation Results ===")
print(f"F1 Scores: {cv_scores.round(4)}")
print(f"Mean F1 Score: {cv_scores.mean():.4f} (+/- {cv_scores.std() * 2:.4f})")

# Visualize CV results
plt.figure(figsize=(8, 5))
plt.boxplot(cv_scores)
plt.ylabel('F1 Score')
plt.title('Cross-Validation F1 Scores')
plt.axhline(y=cv_scores.mean(), color='r', linestyle='--', label=f'Mean: {cv_scores.mean():.4f}')
plt.legend()
plt.show()
```

## Final Model Testing

```python
# Train final model on combined train+validation data
X_train_full = pd.concat([X_train, X_val])
y_train_full = pd.concat([y_train, y_val])

final_model = random_search.best_estimator_.__class__(**random_search.best_params_)
final_model.fit(X_train_full, y_train_full)

# Evaluate on test set
y_pred_test = final_model.predict(X_test)
y_pred_proba_test = final_model.predict_proba(X_test)[:, 1]

print("=== Final Model Performance on Test Set ===")
print("\nClassification Report:")
print(classification_report(y_test, y_pred_test))

# Final metrics
final_metrics = {
    'accuracy': accuracy_score(y_test, y_pred_test),
    'precision': precision_score(y_test, y_pred_test),
    'recall': recall_score(y_test, y_pred_test),
    'f1_score': f1_score(y_test, y_pred_test),
    'auc_roc': roc_auc_score(y_test, y_pred_proba_test)
}

print("\nFinal Test Metrics:")
for metric, value in final_metrics.items():
    print(f"{metric}: {value:.4f}")

# Compare to baseline
improvement = (final_metrics['f1_score'] - problem_definition['baseline_performance']) / problem_definition['baseline_performance'] * 100
print(f"\nImprovement over baseline: {improvement:.1f}%")
```

## Model Interpretation

```python
# SHAP analysis for model interpretation
try:
    import shap
    
    # Create SHAP explainer
    if best_model_name in ['Random Forest', 'XGBoost', 'LightGBM']:
        explainer = shap.TreeExplainer(final_model)
    else:
        explainer = shap.LinearExplainer(final_model, X_train_full)
    
    # Calculate SHAP values for test set
    shap_values = explainer.shap_values(X_test)
    
    # If binary classification and tree model, take values for positive class
    if isinstance(shap_values, list):
        shap_values = shap_values[1]
    
    # Summary plot
    plt.figure(figsize=(10, 8))
    shap.summary_plot(shap_values, X_test, feature_names=all_feature_names, show=False)
    plt.title('SHAP Feature Importance Summary')
    plt.tight_layout()
    plt.show()
    
    # Feature importance bar plot
    plt.figure(figsize=(10, 6))
    shap.summary_plot(shap_values, X_test, feature_names=all_feature_names, plot_type="bar", show=False)
    plt.title('Mean SHAP Value (Feature Importance)')
    plt.tight_layout()
    plt.show()
    
except ImportError:
    print("SHAP not installed. Skipping interpretability analysis.")
```

## Business Impact Analysis

```python
# Calculate business metrics
n_test_customers = len(y_test)
n_actual_churners = y_test.sum()
n_predicted_churners = y_pred_test.sum()
n_correct_predictions = ((y_test == 1) & (y_pred_test == 1)).sum()

# Assuming business values
customer_lifetime_value = 1000  # Average CLV
retention_cost = 50  # Cost of retention campaign
retention_success_rate = 0.4  # 40% of targeted customers can be retained

# Calculate savings
saved_customers = n_correct_predictions * retention_success_rate
revenue_saved = saved_customers * customer_lifetime_value
campaign_cost = n_predicted_churners * retention_cost
net_benefit = revenue_saved - campaign_cost

print("=== Business Impact Analysis ===")
print(f"Test set customers: {n_test_customers:,}")
print(f"Actual churners: {n_actual_churners:,} ({n_actual_churners/n_test_customers:.1%})")
print(f"Predicted churners: {n_predicted_churners:,}")
print(f"Correctly identified churners: {n_correct_predictions:,}")
print(f"\nAssuming ${customer_lifetime_value} CLV and {retention_success_rate:.0%} retention success:")
print(f"Customers saved: {int(saved_customers):,}")
print(f"Revenue saved: ${revenue_saved:,.0f}")
print(f"Campaign cost: ${campaign_cost:,.0f}")
print(f"Net benefit: ${net_benefit:,.0f}")
print(f"ROI: {(net_benefit/campaign_cost)*100:.0f}%")
```

## Model Deployment Preparation

```python
# Prepare model for deployment
import joblib
import json

# Create deployment package
deployment_package = {
    'model': final_model,
    'preprocessor': preprocessor,
    'feature_names': all_feature_names,
    'model_metadata': {
        'model_type': best_model_name,
        'hyperparameters': random_search.best_params_,
        'performance_metrics': final_metrics,
        'training_date': datetime.now().isoformat(),
        'features_used': feature_columns,
        'target_variable': target
    }
}

# Save model artifacts
joblib.dump(deployment_package['model'], 'churn_model.pkl')
joblib.dump(deployment_package['preprocessor'], 'preprocessor.pkl')

# Save metadata
with open('model_metadata.json', 'w') as f:
    json.dump(deployment_package['model_metadata'], f, indent=2)

print("=== Model Deployment Package Created ===")
print("Files created:")
print("  - churn_model.pkl")
print("  - preprocessor.pkl") 
print("  - model_metadata.json")

# Create prediction function for API
def predict_churn(customer_data):
    """
    Predict churn probability for a customer
    
    Args:
        customer_data: dict with customer features
        
    Returns:
        dict with prediction and probability
    """
    # Convert to DataFrame
    df = pd.DataFrame([customer_data])
    
    # Apply preprocessing
    features_processed = preprocessor.transform(df[feature_columns])
    
    # Make prediction
    prediction = final_model.predict(features_processed)[0]
    probability = final_model.predict_proba(features_processed)[0, 1]
    
    return {
        'prediction': int(prediction),
        'churn_probability': float(probability),
        'risk_level': 'High' if probability > 0.7 else 'Medium' if probability > 0.3 else 'Low'
    }

# Test prediction function
test_customer = {
    'tenure_months': 6,
    'monthly_charges': 75.0,
    'total_charges': 450.0,
    'contract_type': 'Month-to-month',
    'payment_method': 'Electronic check',
    'paperless_billing': 1,
    'num_services': 2,
    'tech_support_calls': 5,
    'satisfaction_score': 2.5,
    'last_interaction_days': 45
}

# Add engineered features
test_customer['tenure_group'] = '0-1yr'
test_customer['avg_monthly_charges'] = test_customer['total_charges'] / test_customer['tenure_months']
test_customer['charges_per_service'] = test_customer['monthly_charges'] / test_customer['num_services']
test_customer['support_calls_per_tenure'] = test_customer['tech_support_calls'] / (test_customer['tenure_months'] + 1)
test_customer['high_value_customer'] = 0
test_customer['engagement_score'] = 0.3

prediction_result = predict_churn(test_customer)
print("\n=== Test Prediction ===")
print(f"Test customer prediction: {prediction_result}")
```

## Model Monitoring Setup

```python
# Define monitoring metrics and thresholds
monitoring_config = {
    'performance_metrics': {
        'f1_score': {
            'baseline': final_metrics['f1_score'],
            'threshold': 0.05,  # Alert if drops by more than 5%
            'frequency': 'daily'
        },
        'precision': {
            'baseline': final_metrics['precision'],
            'threshold': 0.05,
            'frequency': 'daily'
        },
        'recall': {
            'baseline': final_metrics['recall'],
            'threshold': 0.05,
            'frequency': 'daily'
        }
    },
    'data_drift_monitoring': {
        'numerical_features': numerical_columns,
        'categorical_features': categorical_columns,
        'method': 'kolmogorov_smirnov',
        'threshold': 0.05
    },
    'prediction_monitoring': {
        'prediction_distribution': {
            'baseline_positive_rate': y_train_full.mean(),
            'threshold': 0.1  # Alert if changes by more than 10%
        },
        'confidence_distribution': {
            'track_percentiles': [25, 50, 75, 90, 95]
        }
    }
}

# Save monitoring configuration
with open('monitoring_config.json', 'w') as f:
    json.dump(monitoring_config, f, indent=2)

print("=== Model Monitoring Configuration ===")
print("Monitoring setup saved to 'monitoring_config.json'")
print("\nKey monitoring aspects:")
print("  - Performance metrics (F1, Precision, Recall)")
print("  - Data drift detection")
print("  - Prediction distribution shifts")
```

## Summary and Next Steps

```python
# Generate comprehensive summary
summary = {
    'project': 'Customer Churn Prediction',
    'model_selected': best_model_name,
    'performance': {
        'test_f1_score': final_metrics['f1_score'],
        'improvement_over_baseline': f"{improvement:.1f}%",
        'cross_validation_mean': cv_scores.mean(),
        'cross_validation_std': cv_scores.std()
    },
    'business_impact': {
        'estimated_revenue_saved': f"${revenue_saved:,.0f}",
        'roi': f"{(net_benefit/campaign_cost)*100:.0f}%"
    },
    'key_insights': [
        f"Top predictor: {feature_importance.iloc[0]['feature']}",
        f"Model achieves {final_metrics['recall']:.1%} recall (catches {final_metrics['recall']:.0%} of churners)",
        f"Precision of {final_metrics['precision']:.1%} means {final_metrics['precision']:.0%} of predictions are correct"
    ],
    'deployment_status': 'Ready for deployment',
    'next_steps': [
        'Deploy model to production API',
        'Set up real-time monitoring dashboard',
        'A/B test retention campaigns on predicted churners',
        'Schedule monthly model retraining',
        'Explore additional features (customer interactions, product usage)'
    ]
}

print("\n=== PROJECT SUMMARY ===")
for key, value in summary.items():
    if isinstance(value, dict):
        print(f"\n{key.upper()}:")
        for k, v in value.items():
            print(f"  {k}: {v}")
    elif isinstance(value, list):
        print(f"\n{key.upper()}:")
        for item in value:
            print(f"  - {item}")
    else:
        print(f"{key}: {value}")

# Save summary
with open('project_summary.json', 'w') as f:
    json.dump(summary, f, indent=2)
    
print("\n✓ Model training complete! All artifacts saved.")
```