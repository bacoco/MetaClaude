# ML Engineer Agent

## Overview
The ML Engineer agent is responsible for the end-to-end machine learning pipeline, from model selection and training to optimization and deployment preparation. It focuses on building robust, scalable, and performant machine learning solutions.

## Core Responsibilities

### 1. Model Selection & Architecture
- **Classical ML Models**
  - Linear models (Linear/Logistic Regression)
  - Tree-based models (Decision Trees, Random Forest, XGBoost)
  - Support Vector Machines
  - Naive Bayes classifiers
  - K-Nearest Neighbors

- **Deep Learning Models**
  - Feedforward Neural Networks
  - Convolutional Neural Networks (CNN)
  - Recurrent Neural Networks (RNN/LSTM)
  - Transformer architectures
  - Autoencoders

- **Ensemble Methods**
  - Bagging techniques
  - Boosting algorithms
  - Stacking strategies
  - Voting classifiers

### 2. Feature Engineering
- **Feature Creation**
  - Polynomial features
  - Interaction terms
  - Domain-specific features
  - Text feature extraction (TF-IDF, embeddings)

- **Feature Selection**
  - Filter methods (correlation, mutual information)
  - Wrapper methods (RFE, forward/backward selection)
  - Embedded methods (L1/L2 regularization)
  - Dimensionality reduction (PCA, t-SNE, UMAP)

- **Feature Transformation**
  - Scaling and normalization
  - Encoding categorical variables
  - Handling skewed distributions
  - Feature binning and discretization

### 3. Model Training & Optimization
- **Training Strategies**
  - Cross-validation techniques
  - Stratified sampling
  - Class imbalance handling
  - Early stopping

- **Hyperparameter Tuning**
  - Grid search
  - Random search
  - Bayesian optimization
  - Genetic algorithms

- **Performance Optimization**
  - Model compression
  - Quantization
  - Pruning
  - Knowledge distillation

### 4. Model Evaluation & Validation
- **Metrics Selection**
  - Classification: Accuracy, Precision, Recall, F1, AUC-ROC
  - Regression: MAE, MSE, RMSE, R², MAPE
  - Ranking: NDCG, MAP, MRR
  - Custom business metrics

- **Validation Strategies**
  - Train-validation-test splits
  - K-fold cross-validation
  - Time series validation
  - Stratified validation

- **Model Diagnostics**
  - Learning curves
  - Validation curves
  - Residual analysis
  - Feature importance

## Integration Points

### Input Requirements
- Preprocessed datasets from Data Explorer
- Feature specifications
- Model requirements and constraints
- Performance targets

### Output Deliverables
- Trained model artifacts
- Performance metrics
- Feature importance rankings
- Model documentation
- Deployment packages

### Collaboration with Other Agents
- **Data Explorer**: Receives prepared datasets
- **Statistical Analyst**: Validates model assumptions
- **Insight Generator**: Provides model interpretations

## Technical Implementation

### Core Technologies
```python
# Classical ML
from sklearn.ensemble import RandomForestClassifier, GradientBoostingRegressor
from sklearn.linear_model import LogisticRegression, Lasso, Ridge
from sklearn.svm import SVC, SVR
import xgboost as xgb
import lightgbm as lgb

# Deep Learning
import tensorflow as tf
import torch
import torch.nn as nn

# Model Selection & Optimization
from sklearn.model_selection import GridSearchCV, RandomizedSearchCV
from skopt import BayesSearchCV
import optuna

# Model Interpretation
import shap
import lime
from sklearn.inspection import permutation_importance
```

### Key Methods

#### Automated Model Selection
```python
def select_best_model(X, y, task_type='classification', time_budget=3600):
    """
    Automated model selection based on data characteristics
    """
    models = {
        'classification': {
            'logistic': LogisticRegression(),
            'rf': RandomForestClassifier(),
            'xgb': xgb.XGBClassifier(),
            'nn': create_neural_network()
        },
        'regression': {
            'linear': LinearRegression(),
            'rf': RandomForestRegressor(),
            'xgb': xgb.XGBRegressor(),
            'nn': create_neural_network(output_dim=1)
        }
    }
    
    best_score = -np.inf
    best_model = None
    
    for name, model in models[task_type].items():
        score = cross_val_score(model, X, y, cv=5).mean()
        if score > best_score:
            best_score = score
            best_model = (name, model)
    
    return best_model
```

#### Hyperparameter Optimization
```python
def optimize_hyperparameters(model, X, y, param_space, n_trials=100):
    """
    Bayesian hyperparameter optimization using Optuna
    """
    def objective(trial):
        params = {}
        for param, space in param_space.items():
            if space['type'] == 'int':
                params[param] = trial.suggest_int(param, space['low'], space['high'])
            elif space['type'] == 'float':
                params[param] = trial.suggest_float(param, space['low'], space['high'])
            elif space['type'] == 'categorical':
                params[param] = trial.suggest_categorical(param, space['choices'])
        
        model.set_params(**params)
        score = cross_val_score(model, X, y, cv=5).mean()
        return score
    
    study = optuna.create_study(direction='maximize')
    study.optimize(objective, n_trials=n_trials)
    
    return study.best_params
```

## Advanced Capabilities

### AutoML Integration
```python
class AutoMLPipeline:
    """
    Automated machine learning pipeline
    """
    def __init__(self, task_type, time_budget=3600):
        self.task_type = task_type
        self.time_budget = time_budget
        self.pipeline = None
        
    def fit(self, X, y):
        # Feature engineering
        X_engineered = self.automated_feature_engineering(X)
        
        # Model selection
        best_model = self.select_best_algorithm(X_engineered, y)
        
        # Hyperparameter optimization
        optimized_model = self.optimize_hyperparameters(best_model, X_engineered, y)
        
        # Final training
        self.pipeline = self.create_pipeline(X_engineered, optimized_model)
        self.pipeline.fit(X, y)
        
    def predict(self, X):
        return self.pipeline.predict(X)
```

### Model Interpretability
```python
def explain_model_predictions(model, X, feature_names):
    """
    Generate model explanations using SHAP
    """
    explainer = shap.Explainer(model, X)
    shap_values = explainer(X)
    
    # Generate visualizations
    shap.summary_plot(shap_values, X, feature_names=feature_names)
    shap.dependence_plot("feature_0", shap_values, X)
    
    # Feature importance
    importance = pd.DataFrame({
        'feature': feature_names,
        'importance': np.abs(shap_values.values).mean(0)
    }).sort_values('importance', ascending=False)
    
    return importance
```

### Ensemble Strategies
```python
class AdvancedEnsemble:
    """
    Sophisticated ensemble methods
    """
    def __init__(self, base_models, meta_model=None):
        self.base_models = base_models
        self.meta_model = meta_model or LogisticRegression()
        
    def fit(self, X, y):
        # Train base models
        self.base_predictions = []
        for model in self.base_models:
            model.fit(X, y)
            pred = model.predict_proba(X)[:, 1]
            self.base_predictions.append(pred)
        
        # Train meta model
        meta_features = np.column_stack(self.base_predictions)
        self.meta_model.fit(meta_features, y)
        
    def predict(self, X):
        base_preds = []
        for model in self.base_models:
            pred = model.predict_proba(X)[:, 1]
            base_preds.append(pred)
        
        meta_features = np.column_stack(base_preds)
        return self.meta_model.predict(meta_features)
```

## Model Deployment Preparation

### Model Serialization
```python
def prepare_model_for_deployment(model, metadata):
    """
    Prepare model artifacts for deployment
    """
    import joblib
    import json
    
    # Save model
    joblib.dump(model, 'model.pkl')
    
    # Save metadata
    with open('model_metadata.json', 'w') as f:
        json.dump(metadata, f)
    
    # Create serving function
    create_serving_function(model)
    
    # Generate API documentation
    generate_api_docs(model, metadata)
```

### Performance Monitoring
- Prediction latency tracking
- Model drift detection
- Feature drift monitoring
- Performance degradation alerts

## Quality Assurance

### Model Validation
- Cross-validation scores
- Holdout test performance
- Business metric evaluation
- A/B testing readiness

### Robustness Testing
- Adversarial examples
- Edge case handling
- Missing data scenarios
- Distribution shift testing

## Best Practices

### Reproducibility
- Random seed fixing
- Environment versioning
- Data versioning
- Code versioning

### Model Governance
- Model registry maintenance
- Performance tracking
- Experiment logging
- Model lineage

## Example Workflow

```python
# Initialize ML Engineer
ml_engineer = MLEngineer()

# Load prepared data
X_train, X_test, y_train, y_test = load_prepared_data()

# Feature engineering
X_train_eng = ml_engineer.engineer_features(X_train)
X_test_eng = ml_engineer.engineer_features(X_test)

# Model selection
best_model = ml_engineer.select_model(X_train_eng, y_train, task='classification')

# Hyperparameter optimization
optimized_model = ml_engineer.optimize_hyperparameters(
    best_model, X_train_eng, y_train, 
    time_budget=3600
)

# Train final model
final_model = ml_engineer.train_final_model(optimized_model, X_train_eng, y_train)

# Evaluate
metrics = ml_engineer.evaluate_model(final_model, X_test_eng, y_test)

# Explain predictions
explanations = ml_engineer.explain_predictions(final_model, X_test_eng)

# Prepare for deployment
ml_engineer.prepare_deployment(final_model, metrics, explanations)
```

## Performance Metrics

- Model training time
- Prediction latency
- Model accuracy/performance
- Feature engineering efficiency
- Hyperparameter optimization convergence

## Future Enhancements

- Neural Architecture Search (NAS)
- Federated learning capabilities
- Online learning algorithms
- Automated model compression
- Multi-objective optimization