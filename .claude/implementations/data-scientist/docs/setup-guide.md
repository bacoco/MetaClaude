# Data Scientist Setup Guide

## Overview
This guide provides step-by-step instructions for setting up the Data Scientist specialist environment, including required dependencies, configuration, and integration with MetaClaude.

## System Requirements

### Minimum Requirements
- **OS**: macOS 10.14+, Ubuntu 18.04+, Windows 10+
- **Python**: 3.8 or higher
- **RAM**: 8GB minimum (16GB recommended)
- **Storage**: 10GB free space
- **CPU**: 4 cores minimum (8 cores recommended)
- **GPU**: Optional (required for deep learning workflows)

### Recommended Development Environment
- **IDE**: VS Code, PyCharm, or Jupyter Lab
- **Version Control**: Git 2.0+
- **Container**: Docker (optional)
- **Cloud Access**: AWS/GCP/Azure CLI tools (optional)

## Installation Steps

### 1. Python Environment Setup

#### Using Conda (Recommended)
```bash
# Install Miniconda if not already installed
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-$(uname -s)-$(uname -m).sh
bash Miniconda3-latest-*.sh

# Create dedicated environment
conda create -n metaclaude-datascience python=3.9
conda activate metaclaude-datascience
```

#### Using venv
```bash
# Create virtual environment
python -m venv metaclaude-datascience
source metaclaude-datascience/bin/activate  # On Windows: .\metaclaude-datascience\Scripts\activate
```

### 2. Core Dependencies Installation

#### Base Requirements
Create `requirements.txt`:
```
# Core Data Science
numpy==1.24.3
pandas==2.0.3
scipy==1.11.1
scikit-learn==1.3.0

# Visualization
matplotlib==3.7.2
seaborn==0.12.2
plotly==5.15.0

# Statistical Analysis
statsmodels==0.14.0
pingouin==0.5.3
pymc3==3.11.5

# Machine Learning
xgboost==1.7.6
lightgbm==4.0.0
catboost==1.2

# Deep Learning (Optional)
tensorflow==2.13.0
torch==2.0.1
transformers==4.31.0

# Utilities
joblib==1.3.1
tqdm==4.65.0
python-dotenv==1.0.0

# Jupyter
jupyter==1.0.0
jupyterlab==4.0.3
ipywidgets==8.0.7
```

Install dependencies:
```bash
pip install -r requirements.txt
```

#### Additional Tools
```bash
# Install additional statistical packages
pip install scikit-posthocs lifelines pmdarima

# Install data profiling tools
pip install pandas-profiling sweetviz great-expectations

# Install ML experiment tracking
pip install mlflow wandb neptune-client

# Install AutoML tools (optional)
pip install auto-sklearn h2o pycaret
```

### 3. MetaClaude Integration

#### Directory Structure Setup
```bash
# Navigate to MetaClaude implementations directory
cd /path/to/metaclaude/.claude/implementations/data-scientist

# Create necessary directories if not exists
mkdir -p {agents,workflows,docs,examples,notebooks,config,data,models,results}

# Set permissions
chmod -R 755 .
```

#### Configuration Files

Create `config/data_scientist_config.yaml`:
```yaml
# Data Scientist Configuration
version: 1.0

# Agent Settings
agents:
  data_explorer:
    enabled: true
    memory_limit: "4GB"
    chunk_size: 10000
    
  statistical_analyst:
    enabled: true
    significance_level: 0.05
    multiple_testing_correction: "bonferroni"
    
  ml_engineer:
    enabled: true
    default_cv_folds: 5
    random_state: 42
    n_jobs: -1
    
  insight_generator:
    enabled: true
    report_format: "html"
    visualization_backend: "plotly"

# Workflow Settings
workflows:
  eda_pipeline:
    max_duration: 3600  # seconds
    auto_save: true
    cache_results: true
    
  model_development:
    hyperparameter_trials: 100
    early_stopping_patience: 10
    model_registry: "mlflow"
    
  ab_testing:
    min_sample_size: 100
    max_test_duration: 30  # days
    sequential_testing: true

# Data Settings
data:
  max_file_size: "1GB"
  supported_formats: ["csv", "parquet", "json", "excel", "sql"]
  missing_value_threshold: 0.5
  outlier_detection_method: "IQR"

# Model Settings
models:
  auto_select: true
  interpretability_threshold: 0.7
  deployment_format: "pickle"
  model_versioning: true

# Compute Resources
compute:
  parallelization: true
  gpu_enabled: false
  distributed_computing: false
  memory_optimization: true

# Integration
integration:
  metaclaude_api: "http://localhost:8000"
  tool_builder_enabled: true
  memory_sync: true
  
# Logging
logging:
  level: "INFO"
  format: "json"
  destination: "logs/data_scientist.log"
  rotation: "daily"
```

### 4. Environment Variables

Create `.env` file:
```bash
# MetaClaude Integration
METACLAUDE_API_URL=http://localhost:8000
METACLAUDE_API_KEY=your-api-key

# Data Sources
DATABASE_URL=postgresql://user:password@localhost/dbname
S3_BUCKET=your-data-bucket
AZURE_STORAGE_CONNECTION=your-connection-string

# ML Tracking
MLFLOW_TRACKING_URI=http://localhost:5000
WANDB_API_KEY=your-wandb-key

# Compute Resources
DASK_SCHEDULER=tcp://localhost:8786
SPARK_MASTER=spark://localhost:7077

# API Keys (if needed)
OPENAI_API_KEY=your-openai-key
HUGGINGFACE_TOKEN=your-hf-token
```

### 5. Jupyter Configuration

#### Create Jupyter Config
```bash
jupyter notebook --generate-config
```

Edit `~/.jupyter/jupyter_notebook_config.py`:
```python
c.NotebookApp.notebook_dir = '/path/to/metaclaude/notebooks'
c.NotebookApp.token = ''
c.NotebookApp.password = ''
c.NotebookApp.open_browser = True
c.NotebookApp.port = 8888
```

#### Install Jupyter Extensions
```bash
# Install useful extensions
pip install jupyter_contrib_nbextensions
jupyter contrib nbextension install --user

# Enable specific extensions
jupyter nbextension enable varInspector/main
jupyter nbextension enable execute_time/ExecuteTime
jupyter nbextension enable collapsible_headings/main
```

### 6. Database Setup

#### PostgreSQL for Data Storage
```sql
-- Create database for MetaClaude Data Scientist
CREATE DATABASE metaclaude_ds;

-- Create schema
\c metaclaude_ds;
CREATE SCHEMA IF NOT EXISTS datasets;
CREATE SCHEMA IF NOT EXISTS experiments;
CREATE SCHEMA IF NOT EXISTS results;

-- Create tables
CREATE TABLE experiments.models (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    type VARCHAR(100),
    parameters JSONB,
    metrics JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE datasets.metadata (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    source VARCHAR(500),
    schema JSONB,
    statistics JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 7. Testing Installation

#### Verification Script
Create `test_setup.py`:
```python
#!/usr/bin/env python
"""
Test Data Scientist setup
"""
import sys
import importlib

def test_imports():
    """Test all required imports"""
    required_modules = [
        'numpy', 'pandas', 'scipy', 'sklearn',
        'matplotlib', 'seaborn', 'plotly',
        'statsmodels', 'xgboost', 'lightgbm'
    ]
    
    failed = []
    for module in required_modules:
        try:
            importlib.import_module(module)
            print(f"✓ {module}")
        except ImportError:
            print(f"✗ {module}")
            failed.append(module)
    
    return len(failed) == 0

def test_gpu():
    """Test GPU availability"""
    try:
        import torch
        gpu_available = torch.cuda.is_available()
        print(f"GPU Available: {gpu_available}")
        if gpu_available:
            print(f"GPU Count: {torch.cuda.device_count()}")
            print(f"GPU Name: {torch.cuda.get_device_name(0)}")
    except ImportError:
        print("PyTorch not installed, skipping GPU test")

def test_metaclaude_connection():
    """Test MetaClaude API connection"""
    import requests
    import os
    
    api_url = os.getenv('METACLAUDE_API_URL', 'http://localhost:8000')
    try:
        response = requests.get(f"{api_url}/health", timeout=5)
        if response.status_code == 200:
            print("✓ MetaClaude API connection successful")
        else:
            print("✗ MetaClaude API returned error")
    except Exception as e:
        print(f"✗ MetaClaude API connection failed: {e}")

if __name__ == "__main__":
    print("Testing Data Scientist Setup...\n")
    
    print("1. Testing imports:")
    imports_ok = test_imports()
    
    print("\n2. Testing GPU:")
    test_gpu()
    
    print("\n3. Testing MetaClaude connection:")
    test_metaclaude_connection()
    
    if imports_ok:
        print("\n✓ Setup completed successfully!")
        sys.exit(0)
    else:
        print("\n✗ Setup incomplete. Please install missing dependencies.")
        sys.exit(1)
```

Run test:
```bash
python test_setup.py
```

### 8. Quick Start

#### Initialize Data Scientist
```python
from metaclaude.implementations.data_scientist import DataScientistOrchestrator

# Initialize orchestrator
ds = DataScientistOrchestrator(config_path='config/data_scientist_config.yaml')

# Run EDA pipeline
results = ds.run_workflow(
    workflow='eda_pipeline',
    data_path='data/sample_dataset.csv'
)

# Run model development
model = ds.run_workflow(
    workflow='model_development',
    data=prepared_data,
    problem_type='classification',
    target_column='target'
)
```

## Troubleshooting

### Common Issues

#### 1. Import Errors
```bash
# Fix: Ensure virtual environment is activated
conda activate metaclaude-datascience
# or
source metaclaude-datascience/bin/activate
```

#### 2. Memory Issues
```python
# Fix: Use chunking for large datasets
import pandas as pd

# Read in chunks
chunk_size = 10000
chunks = pd.read_csv('large_file.csv', chunksize=chunk_size)
df = pd.concat(chunks, ignore_index=True)
```

#### 3. GPU Not Detected
```bash
# Fix: Install CUDA-compatible PyTorch
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
```

#### 4. Jupyter Kernel Issues
```bash
# Fix: Install kernel in environment
python -m ipykernel install --user --name=metaclaude-datascience
```

### Performance Optimization

#### 1. Enable Parallelization
```python
# Set in config or code
import joblib
from sklearn.ensemble import RandomForestClassifier

model = RandomForestClassifier(n_jobs=-1)  # Use all cores
```

#### 2. Use Efficient Data Types
```python
# Optimize pandas memory usage
df = pd.read_csv('data.csv')
df = df.astype({
    'category_column': 'category',
    'int_column': 'int32',
    'float_column': 'float32'
})
```

#### 3. Enable GPU Acceleration
```python
# For XGBoost
import xgboost as xgb
model = xgb.XGBClassifier(tree_method='gpu_hist', gpu_id=0)

# For deep learning
import tensorflow as tf
physical_devices = tf.config.list_physical_devices('GPU')
tf.config.experimental.set_memory_growth(physical_devices[0], True)
```

## Maintenance

### Regular Updates
```bash
# Update all packages
pip list --outdated
pip install --upgrade -r requirements.txt

# Update conda packages
conda update --all
```

### Backup Configuration
```bash
# Backup script
#!/bin/bash
BACKUP_DIR="backups/$(date +%Y%m%d)"
mkdir -p $BACKUP_DIR

cp -r config $BACKUP_DIR/
cp -r models $BACKUP_DIR/
cp .env $BACKUP_DIR/

echo "Backup completed to $BACKUP_DIR"
```

### Monitor Resource Usage
```python
# Resource monitoring script
import psutil
import GPUtil

def monitor_resources():
    # CPU usage
    cpu_percent = psutil.cpu_percent(interval=1)
    
    # Memory usage
    memory = psutil.virtual_memory()
    
    # GPU usage (if available)
    gpus = GPUtil.getGPUs()
    
    print(f"CPU Usage: {cpu_percent}%")
    print(f"Memory Usage: {memory.percent}%")
    
    if gpus:
        for gpu in gpus:
            print(f"GPU {gpu.id} Usage: {gpu.load*100}%")
            print(f"GPU {gpu.id} Memory: {gpu.memoryUsed}/{gpu.memoryTotal} MB")
```

## Next Steps

1. Complete the [ML Algorithms Guide](ml-algorithms.md)
2. Review the [Statistical Methods Guide](statistical-methods.md)
3. Explore example notebooks in `notebooks/`
4. Configure your first workflow
5. Integrate with MetaClaude's Tool Builder

## Support Resources

- **Documentation**: `.claude/implementations/data-scientist/docs/`
- **Examples**: `.claude/implementations/data-scientist/examples/`
- **Community**: MetaClaude Discord/Slack channel
- **Issues**: GitHub repository issues