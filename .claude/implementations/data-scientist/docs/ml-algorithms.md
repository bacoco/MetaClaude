# Machine Learning Algorithms Guide

## Overview
This guide provides comprehensive coverage of machine learning algorithms used by the Data Scientist specialist, including their principles, use cases, implementation details, and best practices.

## Algorithm Categories

### 1. Supervised Learning

#### Linear Models

##### Linear Regression
**Purpose**: Predict continuous values using linear relationships  
**Use Cases**: Price prediction, trend analysis, forecasting

```python
from sklearn.linear_model import LinearRegression

# Basic implementation
model = LinearRegression()
model.fit(X_train, y_train)
predictions = model.predict(X_test)

# Key parameters
model = LinearRegression(
    fit_intercept=True,    # Include bias term
    normalize=False,       # Normalize features (deprecated)
    copy_X=True,          # Copy input data
    n_jobs=None           # Parallel jobs
)
```

**Assumptions**:
- Linear relationship between features and target
- Independence of observations
- Homoscedasticity (constant variance)
- Normality of residuals
- No multicollinearity

##### Logistic Regression
**Purpose**: Binary/multiclass classification using logistic function  
**Use Cases**: Churn prediction, fraud detection, medical diagnosis

```python
from sklearn.linear_model import LogisticRegression

# Implementation with regularization
model = LogisticRegression(
    penalty='l2',          # Regularization type ('l1', 'l2', 'elasticnet')
    C=1.0,                # Inverse regularization strength
    solver='lbfgs',       # Optimization algorithm
    max_iter=100,         # Maximum iterations
    class_weight='balanced'  # Handle imbalanced classes
)
```

**Advantages**:
- Interpretable coefficients
- Probability outputs
- Works well with high-dimensional data
- No tuning required

#### Tree-Based Models

##### Decision Trees
**Purpose**: Hierarchical decision-making using feature splits  
**Use Cases**: Rule extraction, feature interaction, mixed data types

```python
from sklearn.tree import DecisionTreeClassifier

model = DecisionTreeClassifier(
    criterion='gini',           # Split criterion ('gini', 'entropy')
    max_depth=None,            # Maximum tree depth
    min_samples_split=2,       # Minimum samples to split
    min_samples_leaf=1,        # Minimum samples in leaf
    max_features=None,         # Features to consider
    class_weight='balanced'    # Handle imbalanced classes
)

# Feature importance
importances = model.feature_importances_
```

**Pruning Strategies**:
- Pre-pruning: max_depth, min_samples_split, min_samples_leaf
- Post-pruning: cost complexity pruning (ccp_alpha)

##### Random Forest
**Purpose**: Ensemble of decision trees with bagging  
**Use Cases**: General-purpose classification/regression, feature importance

```python
from sklearn.ensemble import RandomForestClassifier

model = RandomForestClassifier(
    n_estimators=100,          # Number of trees
    max_depth=None,            # Maximum depth
    min_samples_split=2,       # Minimum samples to split
    min_samples_leaf=1,        # Minimum samples in leaf
    max_features='sqrt',       # Features per tree
    bootstrap=True,            # Bootstrap samples
    oob_score=True,           # Out-of-bag score
    n_jobs=-1,                # Parallel processing
    random_state=42
)

# Out-of-bag evaluation
oob_score = model.oob_score_
```

**Hyperparameter Tuning Priority**:
1. n_estimators (more is generally better)
2. max_features (sqrt for classification, 1/3 for regression)
3. max_depth (prevent overfitting)
4. min_samples_leaf (regularization)

##### Gradient Boosting (XGBoost/LightGBM)
**Purpose**: Sequential tree boosting with gradient descent  
**Use Cases**: Competition winning, high accuracy requirements

```python
import xgboost as xgb

# XGBoost implementation
model = xgb.XGBClassifier(
    n_estimators=100,          # Number of trees
    max_depth=6,               # Maximum depth
    learning_rate=0.3,         # Step size shrinkage
    subsample=1.0,             # Subsample ratio
    colsample_bytree=1.0,      # Feature sampling
    reg_alpha=0,               # L1 regularization
    reg_lambda=1,              # L2 regularization
    scale_pos_weight=1,        # Balance classes
    tree_method='hist'         # Fast histogram method
)

# Early stopping
model.fit(
    X_train, y_train,
    eval_set=[(X_val, y_val)],
    early_stopping_rounds=10,
    eval_metric='auc'
)
```

**LightGBM Advantages**:
```python
import lightgbm as lgb

model = lgb.LGBMClassifier(
    boosting_type='gbdt',      # 'gbdt', 'dart', 'goss'
    num_leaves=31,             # Maximum leaves
    learning_rate=0.05,        # Step size
    feature_fraction=0.9,      # Feature sampling
    bagging_fraction=0.8,      # Data sampling
    bagging_freq=5,            # Bagging frequency
    verbose=0,
    categorical_feature='auto'  # Auto detect categoricals
)
```

#### Support Vector Machines

##### SVM Classification
**Purpose**: Find optimal hyperplane for classification  
**Use Cases**: Text classification, image recognition, bioinformatics

```python
from sklearn.svm import SVC

# RBF kernel SVM
model = SVC(
    C=1.0,                    # Regularization
    kernel='rbf',             # Kernel type
    gamma='scale',            # Kernel coefficient
    probability=True,         # Enable probability estimates
    class_weight='balanced'   # Handle imbalanced data
)

# Kernel options
kernels = {
    'linear': 'Linear separation',
    'poly': 'Polynomial transformation',
    'rbf': 'Radial basis function',
    'sigmoid': 'Sigmoid transformation'
}
```

### 2. Unsupervised Learning

#### Clustering Algorithms

##### K-Means
**Purpose**: Partition data into K clusters  
**Use Cases**: Customer segmentation, image compression, anomaly detection

```python
from sklearn.cluster import KMeans

model = KMeans(
    n_clusters=5,             # Number of clusters
    init='k-means++',         # Initialization method
    n_init=10,                # Number of runs
    max_iter=300,             # Maximum iterations
    algorithm='auto'          # Algorithm variant
)

# Elbow method for optimal K
inertias = []
for k in range(1, 11):
    km = KMeans(n_clusters=k)
    km.fit(X)
    inertias.append(km.inertia_)
```

##### DBSCAN
**Purpose**: Density-based clustering  
**Use Cases**: Arbitrary shaped clusters, noise detection

```python
from sklearn.cluster import DBSCAN

model = DBSCAN(
    eps=0.5,                  # Maximum distance between points
    min_samples=5,            # Minimum points in neighborhood
    metric='euclidean',       # Distance metric
    algorithm='auto'          # Algorithm for neighbors
)

# Identify noise points
labels = model.labels_
noise_mask = labels == -1
```

##### Hierarchical Clustering
**Purpose**: Build hierarchy of clusters  
**Use Cases**: Taxonomy creation, dendrograms

```python
from sklearn.cluster import AgglomerativeClustering
from scipy.cluster.hierarchy import dendrogram, linkage

# Agglomerative clustering
model = AgglomerativeClustering(
    n_clusters=None,          # Number of clusters
    distance_threshold=0,     # Distance threshold
    linkage='ward'           # Linkage criterion
)

# Create dendrogram
linkage_matrix = linkage(X, method='ward')
dendrogram(linkage_matrix)
```

#### Dimensionality Reduction

##### Principal Component Analysis (PCA)
**Purpose**: Linear dimensionality reduction  
**Use Cases**: Visualization, noise reduction, feature extraction

```python
from sklearn.decomposition import PCA

model = PCA(
    n_components=0.95,        # Variance to preserve
    svd_solver='auto',        # SVD solver
    whiten=False             # Whitening transformation
)

# Explained variance analysis
explained_variance_ratio = model.explained_variance_ratio_
cumulative_variance = explained_variance_ratio.cumsum()
```

##### t-SNE
**Purpose**: Non-linear dimensionality reduction for visualization  
**Use Cases**: High-dimensional data visualization

```python
from sklearn.manifold import TSNE

model = TSNE(
    n_components=2,           # Output dimensions
    perplexity=30,           # Balance local/global
    learning_rate=200,       # Learning rate
    n_iter=1000,             # Iterations
    metric='euclidean'       # Distance metric
)

# Best practices
# 1. Scale data first
# 2. Try different perplexities (5-50)
# 3. Multiple runs for stability
```

### 3. Deep Learning

#### Neural Network Architectures

##### Feedforward Networks
**Purpose**: General-purpose deep learning  
**Use Cases**: Tabular data, non-linear patterns

```python
import tensorflow as tf

model = tf.keras.Sequential([
    tf.keras.layers.Dense(128, activation='relu', input_shape=(n_features,)),
    tf.keras.layers.Dropout(0.3),
    tf.keras.layers.Dense(64, activation='relu'),
    tf.keras.layers.Dropout(0.3),
    tf.keras.layers.Dense(n_classes, activation='softmax')
])

model.compile(
    optimizer='adam',
    loss='categorical_crossentropy',
    metrics=['accuracy']
)

# Advanced techniques
callbacks = [
    tf.keras.callbacks.EarlyStopping(patience=10),
    tf.keras.callbacks.ReduceLROnPlateau(patience=5),
    tf.keras.callbacks.ModelCheckpoint('best_model.h5')
]
```

##### Convolutional Neural Networks (CNN)
**Purpose**: Image and spatial data processing  
**Use Cases**: Image classification, object detection

```python
model = tf.keras.Sequential([
    tf.keras.layers.Conv2D(32, (3, 3), activation='relu', input_shape=(224, 224, 3)),
    tf.keras.layers.MaxPooling2D((2, 2)),
    tf.keras.layers.Conv2D(64, (3, 3), activation='relu'),
    tf.keras.layers.MaxPooling2D((2, 2)),
    tf.keras.layers.Conv2D(128, (3, 3), activation='relu'),
    tf.keras.layers.GlobalAveragePooling2D(),
    tf.keras.layers.Dense(128, activation='relu'),
    tf.keras.layers.Dense(n_classes, activation='softmax')
])
```

##### Recurrent Neural Networks (RNN/LSTM)
**Purpose**: Sequential data processing  
**Use Cases**: Time series, NLP, speech recognition

```python
model = tf.keras.Sequential([
    tf.keras.layers.LSTM(128, return_sequences=True, input_shape=(timesteps, features)),
    tf.keras.layers.LSTM(64, return_sequences=False),
    tf.keras.layers.Dense(32, activation='relu'),
    tf.keras.layers.Dense(1)
])

# Bidirectional LSTM
model = tf.keras.Sequential([
    tf.keras.layers.Bidirectional(
        tf.keras.layers.LSTM(64, return_sequences=True)
    ),
    tf.keras.layers.Bidirectional(
        tf.keras.layers.LSTM(32)
    ),
    tf.keras.layers.Dense(1)
])
```

## Algorithm Selection Guide

### Decision Tree
```python
def select_algorithm(data_profile, problem_type, requirements):
    """
    Intelligent algorithm selection based on data and requirements
    """
    n_samples, n_features = data_profile['shape']
    
    if problem_type == 'classification':
        if n_samples < 1000:
            return 'LogisticRegression'  # Small data
        elif requirements.get('interpretability', False):
            return 'DecisionTree'  # Need interpretability
        elif n_features > n_samples:
            return 'SVC'  # High dimensional
        else:
            return 'RandomForest'  # General purpose
    
    elif problem_type == 'regression':
        if data_profile.get('linear_relationship', False):
            return 'LinearRegression'
        else:
            return 'GradientBoosting'
    
    elif problem_type == 'clustering':
        if requirements.get('n_clusters') is not None:
            return 'KMeans'
        else:
            return 'DBSCAN'
```

### Performance vs Interpretability Trade-off
```
High Interpretability <-------------------> High Performance
Linear Models          Trees    Ensembles    Deep Learning
- Linear Regression    - DT     - RF         - Neural Nets
- Logistic Reg        - CART   - XGBoost    - CNN/RNN
```

## Optimization Strategies

### Hyperparameter Optimization
```python
from sklearn.model_selection import RandomizedSearchCV
from scipy.stats import randint, uniform

# Define parameter distributions
param_distributions = {
    'n_estimators': randint(100, 1000),
    'max_depth': randint(3, 20),
    'min_samples_split': randint(2, 20),
    'min_samples_leaf': randint(1, 10),
    'max_features': ['sqrt', 'log2', None]
}

# Random search
search = RandomizedSearchCV(
    estimator=RandomForestClassifier(),
    param_distributions=param_distributions,
    n_iter=100,
    cv=5,
    scoring='roc_auc',
    n_jobs=-1,
    random_state=42
)
```

### Ensemble Strategies
```python
from sklearn.ensemble import VotingClassifier, StackingClassifier

# Voting ensemble
voting_clf = VotingClassifier(
    estimators=[
        ('lr', LogisticRegression()),
        ('rf', RandomForestClassifier()),
        ('xgb', XGBClassifier())
    ],
    voting='soft'  # Use probabilities
)

# Stacking ensemble
stacking_clf = StackingClassifier(
    estimators=[
        ('rf', RandomForestClassifier()),
        ('xgb', XGBClassifier())
    ],
    final_estimator=LogisticRegression(),
    cv=5  # Cross-validation for meta-features
)
```

## Best Practices

### Feature Engineering Impact
1. **Scaling**: Critical for distance-based algorithms (SVM, KNN)
2. **Encoding**: Tree-based models handle categoricals differently
3. **Interactions**: Linear models need explicit interaction terms
4. **Polynomials**: Can help linear models capture non-linearity

### Model Validation
```python
from sklearn.model_selection import cross_validate

# Comprehensive validation
scores = cross_validate(
    estimator=model,
    X=X,
    y=y,
    cv=5,
    scoring=['accuracy', 'precision', 'recall', 'f1', 'roc_auc'],
    return_train_score=True
)
```

### Handling Imbalanced Data
1. **Algorithm Level**: class_weight='balanced'
2. **Data Level**: SMOTE, RandomUnderSampler
3. **Ensemble Level**: BalancedRandomForest
4. **Metric Level**: Use appropriate metrics (AUC, F1)

## Future Trends

### AutoML Integration
- Automated feature engineering
- Neural architecture search
- Hyperparameter optimization
- Model selection

### Emerging Algorithms
- Transformer models for tabular data
- Graph neural networks
- Federated learning algorithms
- Quantum machine learning