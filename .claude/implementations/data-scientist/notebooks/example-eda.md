# Example EDA Notebook

This notebook demonstrates the EDA Pipeline workflow using the Data Scientist specialist. It shows how to perform comprehensive exploratory data analysis on a sample dataset.

## Setup and Initialization

```python
# Import required libraries
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime

# Import MetaClaude Data Scientist components
from metaclaude.implementations.data_scientist import (
    DataExplorer,
    StatisticalAnalyst,
    InsightGenerator,
    EDAPipeline
)

# Configure display settings
pd.set_option('display.max_columns', None)
pd.set_option('display.max_rows', 100)
plt.style.use('seaborn-v0_8-darkgrid')

# Initialize agents
data_explorer = DataExplorer()
stat_analyst = StatisticalAnalyst()
insight_gen = InsightGenerator()
```

## Load Sample Dataset

```python
# For this example, we'll use a synthetic e-commerce dataset
# In practice, replace with your actual data source

# Generate sample e-commerce data
np.random.seed(42)
n_records = 10000

data = pd.DataFrame({
    'order_id': range(1, n_records + 1),
    'customer_id': np.random.randint(1, 2000, n_records),
    'order_date': pd.date_range('2023-01-01', periods=n_records, freq='h'),
    'product_category': np.random.choice(['Electronics', 'Clothing', 'Home', 'Books', 'Sports'], n_records, p=[0.3, 0.25, 0.2, 0.15, 0.1]),
    'order_value': np.random.lognormal(3.5, 1.2, n_records),
    'quantity': np.random.poisson(2, n_records) + 1,
    'payment_method': np.random.choice(['Credit Card', 'PayPal', 'Debit Card', 'Cash'], n_records, p=[0.4, 0.3, 0.2, 0.1]),
    'customer_age': np.random.normal(35, 12, n_records).clip(18, 80).astype(int),
    'customer_segment': np.random.choice(['Premium', 'Regular', 'New'], n_records, p=[0.2, 0.5, 0.3]),
    'shipping_days': np.random.poisson(3, n_records) + 1,
    'returned': np.random.choice([0, 1], n_records, p=[0.9, 0.1])
})

# Add some missing values for demonstration
missing_indices = np.random.choice(data.index, 50, replace=False)
data.loc[missing_indices, 'customer_age'] = np.nan

print(f"Dataset loaded: {data.shape[0]:,} rows, {data.shape[1]} columns")
data.head()
```

## Stage 1: Initial Data Assessment

```python
# Use Data Explorer for initial assessment
initial_assessment = data_explorer.initial_assessment(data)

print("=== Dataset Overview ===")
print(f"Shape: {initial_assessment['shape']}")
print(f"Memory Usage: {initial_assessment['memory_usage']:,.2f} MB")
print(f"\nData Types:")
for col, dtype in initial_assessment['dtypes'].items():
    print(f"  {col}: {dtype}")

# Check for duplicates
duplicates = data.duplicated().sum()
print(f"\nDuplicate Rows: {duplicates}")
```

## Stage 2: Data Quality Analysis

```python
# Analyze data quality
quality_report = data_explorer.analyze_quality(data)

# Missing values analysis
print("=== Missing Values Analysis ===")
missing_df = pd.DataFrame({
    'Column': quality_report['missing'].keys(),
    'Missing_Count': quality_report['missing'].values(),
    'Missing_Percentage': [v/len(data)*100 for v in quality_report['missing'].values()]
})
missing_df = missing_df[missing_df['Missing_Count'] > 0].sort_values('Missing_Percentage', ascending=False)
print(missing_df)

# Visualize missing patterns
import missingno as msno
msno.matrix(data, figsize=(12, 6))
plt.title('Missing Data Pattern')
plt.show()

# Data quality score
quality_score = (1 - missing_df['Missing_Percentage'].sum() / 100 / len(data.columns)) * 100
print(f"\nOverall Data Quality Score: {quality_score:.2f}%")
```

## Stage 3: Statistical Profiling

```python
# Numerical features profiling
numerical_features = data.select_dtypes(include=['int64', 'float64']).columns
numerical_stats = stat_analyst.profile_data(data[numerical_features])

print("=== Numerical Features Statistics ===")
stats_df = pd.DataFrame(numerical_stats['summary'])
print(stats_df.round(2))

# Distribution analysis
fig, axes = plt.subplots(2, 3, figsize=(15, 10))
axes = axes.ravel()

for idx, col in enumerate(numerical_features[:6]):
    data[col].hist(bins=30, ax=axes[idx], edgecolor='black')
    axes[idx].set_title(f'Distribution of {col}')
    axes[idx].set_xlabel(col)
    axes[idx].set_ylabel('Frequency')

plt.tight_layout()
plt.show()

# Test for normality
print("\n=== Normality Tests ===")
for col in numerical_features:
    if col != 'order_id':  # Skip ID column
        stat, p_value = stat_analyst.test_normality(data[col].dropna())
        print(f"{col}: p-value = {p_value:.4f} {'(Normal)' if p_value > 0.05 else '(Not Normal)'}")
```

## Stage 4: Categorical Features Analysis

```python
# Categorical features profiling
categorical_features = data.select_dtypes(include=['object']).columns

print("=== Categorical Features Analysis ===")
for col in categorical_features:
    print(f"\n{col}:")
    value_counts = data[col].value_counts()
    print(value_counts)
    print(f"Unique values: {data[col].nunique()}")

# Visualize categorical distributions
fig, axes = plt.subplots(2, 2, figsize=(12, 10))
axes = axes.ravel()

for idx, col in enumerate(categorical_features):
    data[col].value_counts().plot(kind='bar', ax=axes[idx])
    axes[idx].set_title(f'Distribution of {col}')
    axes[idx].set_xlabel(col)
    axes[idx].set_ylabel('Count')
    axes[idx].tick_params(axis='x', rotation=45)

plt.tight_layout()
plt.show()
```

## Stage 5: Correlation Analysis

```python
# Correlation matrix for numerical features
correlation_matrix = data[numerical_features].corr()

# Visualize correlation matrix
plt.figure(figsize=(10, 8))
mask = np.triu(np.ones_like(correlation_matrix, dtype=bool))
sns.heatmap(correlation_matrix, mask=mask, annot=True, cmap='coolwarm', 
            center=0, square=True, linewidths=0.5)
plt.title('Correlation Matrix of Numerical Features')
plt.show()

# Find highly correlated features
high_corr_pairs = []
for i in range(len(correlation_matrix.columns)):
    for j in range(i+1, len(correlation_matrix.columns)):
        if abs(correlation_matrix.iloc[i, j]) > 0.7:
            high_corr_pairs.append({
                'Feature1': correlation_matrix.columns[i],
                'Feature2': correlation_matrix.columns[j],
                'Correlation': correlation_matrix.iloc[i, j]
            })

if high_corr_pairs:
    print("\n=== Highly Correlated Features (|r| > 0.7) ===")
    print(pd.DataFrame(high_corr_pairs))
```

## Stage 6: Time Series Analysis

```python
# Analyze temporal patterns
data['order_hour'] = data['order_date'].dt.hour
data['order_day'] = data['order_date'].dt.day_name()
data['order_month'] = data['order_date'].dt.month

# Daily order patterns
daily_orders = data.groupby(data['order_date'].dt.date).agg({
    'order_id': 'count',
    'order_value': ['sum', 'mean']
}).reset_index()
daily_orders.columns = ['date', 'order_count', 'total_revenue', 'avg_order_value']

# Visualize time series
fig, axes = plt.subplots(3, 1, figsize=(12, 10))

# Order count over time
axes[0].plot(daily_orders['date'], daily_orders['order_count'])
axes[0].set_title('Daily Order Count')
axes[0].set_ylabel('Number of Orders')

# Revenue over time
axes[1].plot(daily_orders['date'], daily_orders['total_revenue'])
axes[1].set_title('Daily Revenue')
axes[1].set_ylabel('Revenue ($)')

# Average order value over time
axes[2].plot(daily_orders['date'], daily_orders['avg_order_value'])
axes[2].set_title('Average Order Value')
axes[2].set_ylabel('AOV ($)')
axes[2].set_xlabel('Date')

plt.tight_layout()
plt.show()

# Hourly patterns
hourly_pattern = data.groupby('order_hour')['order_id'].count()
plt.figure(figsize=(10, 5))
hourly_pattern.plot(kind='bar')
plt.title('Orders by Hour of Day')
plt.xlabel('Hour')
plt.ylabel('Number of Orders')
plt.show()
```

## Stage 7: Customer Segmentation Analysis

```python
# Customer behavior analysis
customer_summary = data.groupby('customer_id').agg({
    'order_id': 'count',
    'order_value': ['sum', 'mean'],
    'returned': 'mean',
    'shipping_days': 'mean'
}).reset_index()

customer_summary.columns = ['customer_id', 'order_count', 'total_spent', 
                           'avg_order_value', 'return_rate', 'avg_shipping_days']

# Customer segmentation based on RFM-like metrics
from sklearn.preprocessing import StandardScaler
from sklearn.cluster import KMeans

# Prepare features for clustering
clustering_features = ['order_count', 'total_spent', 'avg_order_value']
X = StandardScaler().fit_transform(customer_summary[clustering_features])

# Elbow method for optimal clusters
inertias = []
K_range = range(2, 10)
for k in K_range:
    kmeans = KMeans(n_clusters=k, random_state=42)
    kmeans.fit(X)
    inertias.append(kmeans.inertia_)

plt.figure(figsize=(8, 5))
plt.plot(K_range, inertias, 'bo-')
plt.xlabel('Number of Clusters (k)')
plt.ylabel('Inertia')
plt.title('Elbow Method for Optimal k')
plt.show()

# Apply clustering with optimal k (let's say 4)
kmeans = KMeans(n_clusters=4, random_state=42)
customer_summary['cluster'] = kmeans.fit_predict(X)

# Analyze clusters
cluster_profile = customer_summary.groupby('cluster')[clustering_features].mean()
print("\n=== Customer Cluster Profiles ===")
print(cluster_profile.round(2))
```

## Stage 8: Advanced Insights

```python
# Product category performance
category_performance = data.groupby('product_category').agg({
    'order_value': ['count', 'sum', 'mean'],
    'returned': 'mean',
    'quantity': 'mean'
}).round(2)

category_performance.columns = ['order_count', 'total_revenue', 'avg_order_value', 
                               'return_rate', 'avg_quantity']
print("\n=== Product Category Performance ===")
print(category_performance.sort_values('total_revenue', ascending=False))

# Payment method analysis
payment_analysis = pd.crosstab(data['payment_method'], data['returned'], normalize='index') * 100
print("\n=== Return Rate by Payment Method (%) ===")
print(payment_analysis.round(2))

# Customer segment behavior
segment_behavior = data.groupby('customer_segment').agg({
    'order_value': 'mean',
    'quantity': 'mean',
    'shipping_days': 'mean',
    'returned': 'mean'
}).round(2)
print("\n=== Customer Segment Behavior ===")
print(segment_behavior)
```

## Stage 9: Statistical Testing

```python
# Test if premium customers spend significantly more than regular customers
premium_spending = data[data['customer_segment'] == 'Premium']['order_value']
regular_spending = data[data['customer_segment'] == 'Regular']['order_value']

t_stat, p_value = stat_analyst.two_sample_t_test(premium_spending, regular_spending)
print(f"\n=== Premium vs Regular Customer Spending ===")
print(f"Premium Mean: ${premium_spending.mean():.2f}")
print(f"Regular Mean: ${regular_spending.mean():.2f}")
print(f"T-statistic: {t_stat:.4f}")
print(f"P-value: {p_value:.4f}")
print(f"Significant difference: {'Yes' if p_value < 0.05 else 'No'}")

# ANOVA for order values across product categories
category_groups = [group['order_value'].values for name, group in data.groupby('product_category')]
f_stat, p_value = stat_analyst.one_way_anova(*category_groups)
print(f"\n=== Order Value Differences Across Categories ===")
print(f"F-statistic: {f_stat:.4f}")
print(f"P-value: {p_value:.4f}")
print(f"Significant difference: {'Yes' if p_value < 0.05 else 'No'}")
```

## Stage 10: Generate Final Insights

```python
# Use Insight Generator to synthesize findings
all_results = {
    'data_quality': quality_report,
    'statistical_summary': numerical_stats,
    'correlation_analysis': correlation_matrix,
    'temporal_patterns': {
        'hourly': hourly_pattern.to_dict(),
        'daily_trends': daily_orders.to_dict()
    },
    'customer_segmentation': cluster_profile.to_dict(),
    'category_performance': category_performance.to_dict()
}

insights = insight_gen.synthesize_insights(all_results)

print("\n=== KEY INSIGHTS ===")
for i, insight in enumerate(insights['key_findings'], 1):
    print(f"\n{i}. {insight['finding']}")
    print(f"   Impact: {insight['impact']}")
    print(f"   Recommendation: {insight['recommendation']}")

# Generate executive summary
executive_summary = insight_gen.generate_executive_summary(insights)
print("\n=== EXECUTIVE SUMMARY ===")
print(executive_summary)
```

## Export Results

```python
# Create comprehensive EDA report
eda_report = {
    'metadata': {
        'dataset_name': 'E-commerce Orders',
        'analysis_date': datetime.now().strftime('%Y-%m-%d'),
        'rows': len(data),
        'columns': len(data.columns)
    },
    'data_quality': quality_report,
    'statistical_analysis': numerical_stats,
    'insights': insights,
    'visualizations': 'See exported figures'
}

# Save report
import json
with open('eda_report.json', 'w') as f:
    json.dump(eda_report, f, indent=2, default=str)

# Export cleaned dataset
data.to_csv('cleaned_data.csv', index=False)
print("\n✓ EDA complete! Results exported to 'eda_report.json' and 'cleaned_data.csv'")
```

## Next Steps

Based on the EDA findings, recommended next steps:

1. **Data Preparation**:
   - Handle missing values in customer_age (imputation or removal)
   - Create derived features (customer lifetime value, purchase frequency)
   - Encode categorical variables for modeling

2. **Modeling Opportunities**:
   - Customer churn prediction
   - Order value prediction
   - Product recommendation system
   - Return probability modeling

3. **Business Actions**:
   - Focus on high-value product categories
   - Optimize for peak ordering hours
   - Develop targeted campaigns for customer segments
   - Investigate high return rate products

4. **Further Analysis**:
   - Cohort analysis for customer retention
   - Market basket analysis for product associations
   - Geographic analysis if location data available
   - Seasonal decomposition for better forecasting