# Statistical Methods Guide

## Overview
This guide covers the statistical methods and techniques used by the Data Scientist specialist, providing theoretical foundations, practical implementations, and best practices for rigorous data analysis.

## Foundational Concepts

### Probability Distributions

#### Normal Distribution
**Definition**: Bell-shaped continuous distribution  
**Parameters**: μ (mean), σ² (variance)  
**Use Cases**: Natural phenomena, sampling distributions, hypothesis testing

```python
import numpy as np
from scipy import stats
import matplotlib.pyplot as plt

# Generate and visualize normal distribution
mu, sigma = 100, 15
x = np.linspace(mu - 4*sigma, mu + 4*sigma, 1000)
y = stats.norm.pdf(x, mu, sigma)

# Key properties
mean = stats.norm.mean(loc=mu, scale=sigma)
variance = stats.norm.var(loc=mu, scale=sigma)
confidence_interval = stats.norm.interval(0.95, loc=mu, scale=sigma)

# Normality testing
def test_normality(data):
    """
    Comprehensive normality testing
    """
    tests = {
        'shapiro': stats.shapiro(data),
        'anderson': stats.anderson(data),
        'dagostino': stats.normaltest(data)
    }
    
    # Visual check
    fig, axes = plt.subplots(1, 2, figsize=(12, 4))
    
    # Q-Q plot
    stats.probplot(data, dist="norm", plot=axes[0])
    axes[0].set_title("Q-Q Plot")
    
    # Histogram with normal overlay
    axes[1].hist(data, bins=30, density=True, alpha=0.7)
    xmin, xmax = axes[1].get_xlim()
    x = np.linspace(xmin, xmax, 100)
    p = stats.norm.pdf(x, np.mean(data), np.std(data))
    axes[1].plot(x, p, 'r-', linewidth=2)
    
    return tests
```

#### Other Key Distributions
```python
# Binomial Distribution
n, p = 10, 0.3
binomial = stats.binom(n, p)

# Poisson Distribution
lambda_param = 3
poisson = stats.poisson(lambda_param)

# Exponential Distribution
lambda_rate = 1.5
exponential = stats.expon(scale=1/lambda_rate)

# t-Distribution
df = 10
t_dist = stats.t(df)

# Chi-Square Distribution
chi2_dist = stats.chi2(df)

# F-Distribution
dfn, dfd = 5, 10
f_dist = stats.f(dfn, dfd)
```

### Descriptive Statistics

#### Measures of Central Tendency
```python
def calculate_central_tendency(data):
    """
    Comprehensive central tendency measures
    """
    results = {
        'mean': np.mean(data),
        'median': np.median(data),
        'mode': stats.mode(data).mode[0],
        'trimmed_mean': stats.trim_mean(data, 0.1),  # 10% trimmed
        'geometric_mean': stats.gmean(data[data > 0]),
        'harmonic_mean': stats.hmean(data[data > 0])
    }
    
    # Weighted mean
    weights = np.ones_like(data) / len(data)
    results['weighted_mean'] = np.average(data, weights=weights)
    
    return results
```

#### Measures of Dispersion
```python
def calculate_dispersion(data):
    """
    Comprehensive dispersion measures
    """
    results = {
        'variance': np.var(data, ddof=1),
        'std_dev': np.std(data, ddof=1),
        'range': np.ptp(data),
        'iqr': stats.iqr(data),
        'mad': stats.median_abs_deviation(data),
        'cv': stats.variation(data)  # Coefficient of variation
    }
    
    # Percentiles
    results['percentiles'] = {
        '25th': np.percentile(data, 25),
        '50th': np.percentile(data, 50),
        '75th': np.percentile(data, 75),
        '90th': np.percentile(data, 90),
        '95th': np.percentile(data, 95)
    }
    
    return results
```

## Hypothesis Testing

### T-Tests

#### One-Sample T-Test
**Purpose**: Test if sample mean differs from population mean  
**Assumptions**: Normal distribution, independent observations

```python
def one_sample_t_test(data, population_mean, alpha=0.05):
    """
    One-sample t-test with comprehensive output
    """
    # Run test
    statistic, p_value = stats.ttest_1samp(data, population_mean)
    
    # Calculate effect size (Cohen's d)
    effect_size = (np.mean(data) - population_mean) / np.std(data, ddof=1)
    
    # Confidence interval
    confidence_interval = stats.t.interval(
        1 - alpha,
        len(data) - 1,
        loc=np.mean(data),
        scale=stats.sem(data)
    )
    
    # Power analysis
    from statsmodels.stats.power import ttest_power
    power = ttest_power(effect_size, len(data), alpha)
    
    return {
        'statistic': statistic,
        'p_value': p_value,
        'effect_size': effect_size,
        'confidence_interval': confidence_interval,
        'power': power,
        'significant': p_value < alpha
    }
```

#### Two-Sample T-Test
```python
def two_sample_t_test(group1, group2, equal_var=True, alpha=0.05):
    """
    Two-sample t-test with assumptions checking
    """
    # Test assumptions
    levene_stat, levene_p = stats.levene(group1, group2)
    
    # Run appropriate test
    if equal_var and levene_p > 0.05:
        statistic, p_value = stats.ttest_ind(group1, group2)
    else:
        statistic, p_value = stats.ttest_ind(group1, group2, equal_var=False)
    
    # Effect size (Cohen's d)
    pooled_std = np.sqrt(((len(group1)-1)*np.var(group1, ddof=1) + 
                          (len(group2)-1)*np.var(group2, ddof=1)) / 
                         (len(group1) + len(group2) - 2))
    effect_size = (np.mean(group1) - np.mean(group2)) / pooled_std
    
    return {
        'statistic': statistic,
        'p_value': p_value,
        'effect_size': effect_size,
        'equal_variance_assumed': equal_var and levene_p > 0.05,
        'levene_test': {'statistic': levene_stat, 'p_value': levene_p}
    }
```

### ANOVA (Analysis of Variance)

#### One-Way ANOVA
```python
def one_way_anova(*groups, alpha=0.05):
    """
    One-way ANOVA with post-hoc tests
    """
    # Run ANOVA
    f_stat, p_value = stats.f_oneway(*groups)
    
    # Effect size (eta squared)
    all_data = np.concatenate(groups)
    grand_mean = np.mean(all_data)
    ss_between = sum(len(g) * (np.mean(g) - grand_mean)**2 for g in groups)
    ss_total = np.sum((all_data - grand_mean)**2)
    eta_squared = ss_between / ss_total
    
    # Post-hoc tests if significant
    post_hoc = None
    if p_value < alpha:
        # Tukey HSD
        data_long = []
        group_labels = []
        for i, group in enumerate(groups):
            data_long.extend(group)
            group_labels.extend([f'Group_{i}'] * len(group))
        
        from statsmodels.stats.multicomp import pairwise_tukeyhsd
        post_hoc = pairwise_tukeyhsd(data_long, group_labels, alpha=alpha)
    
    return {
        'f_statistic': f_stat,
        'p_value': p_value,
        'eta_squared': eta_squared,
        'significant': p_value < alpha,
        'post_hoc': post_hoc
    }
```

#### Two-Way ANOVA
```python
import pandas as pd
import statsmodels.api as sm
from statsmodels.formula.api import ols

def two_way_anova(data, formula, alpha=0.05):
    """
    Two-way ANOVA with interaction effects
    """
    # Fit model
    model = ols(formula, data=data).fit()
    
    # ANOVA table
    anova_table = sm.stats.anova_lm(model, typ=2)
    
    # Effect sizes (partial eta squared)
    anova_table['eta_squared'] = anova_table['sum_sq'] / (
        anova_table['sum_sq'] + anova_table['sum_sq']['Residual']
    )
    
    # Post-hoc for main effects
    if any(anova_table['PR(>F)'][:-1] < alpha):
        # Implement post-hoc tests
        pass
    
    return {
        'anova_table': anova_table,
        'model': model,
        'r_squared': model.rsquared,
        'adjusted_r_squared': model.rsquared_adj
    }
```

### Non-Parametric Tests

#### Mann-Whitney U Test
```python
def mann_whitney_test(group1, group2, alternative='two-sided', alpha=0.05):
    """
    Mann-Whitney U test (non-parametric alternative to t-test)
    """
    statistic, p_value = stats.mannwhitneyu(
        group1, group2, 
        alternative=alternative
    )
    
    # Effect size (rank biserial correlation)
    n1, n2 = len(group1), len(group2)
    r = 1 - (2 * statistic) / (n1 * n2)
    
    # Confidence interval using bootstrap
    def bootstrap_median_diff(g1, g2, n_bootstrap=1000):
        diffs = []
        for _ in range(n_bootstrap):
            sample1 = np.random.choice(g1, size=len(g1), replace=True)
            sample2 = np.random.choice(g2, size=len(g2), replace=True)
            diffs.append(np.median(sample1) - np.median(sample2))
        return np.percentile(diffs, [2.5, 97.5])
    
    ci = bootstrap_median_diff(group1, group2)
    
    return {
        'statistic': statistic,
        'p_value': p_value,
        'effect_size': r,
        'median_difference_ci': ci,
        'significant': p_value < alpha
    }
```

#### Kruskal-Wallis Test
```python
def kruskal_wallis_test(*groups, alpha=0.05):
    """
    Kruskal-Wallis test (non-parametric ANOVA)
    """
    h_stat, p_value = stats.kruskal(*groups)
    
    # Effect size (epsilon squared)
    n_total = sum(len(g) for g in groups)
    epsilon_squared = (h_stat - len(groups) + 1) / (n_total - len(groups))
    
    # Post-hoc tests if significant
    if p_value < alpha:
        from scikit_posthocs import posthoc_dunn
        # Prepare data for post-hoc
        data_combined = np.concatenate(groups)
        group_labels = np.concatenate([[i]*len(g) for i, g in enumerate(groups)])
        post_hoc = posthoc_dunn([data_combined, group_labels])
    else:
        post_hoc = None
    
    return {
        'h_statistic': h_stat,
        'p_value': p_value,
        'epsilon_squared': epsilon_squared,
        'significant': p_value < alpha,
        'post_hoc': post_hoc
    }
```

### Chi-Square Tests

#### Chi-Square Test of Independence
```python
def chi_square_independence(contingency_table, alpha=0.05):
    """
    Chi-square test for independence between categorical variables
    """
    chi2, p_value, dof, expected = stats.chi2_contingency(contingency_table)
    
    # Effect size (Cramér's V)
    n = contingency_table.sum()
    min_dim = min(contingency_table.shape) - 1
    cramers_v = np.sqrt(chi2 / (n * min_dim))
    
    # Residuals analysis
    residuals = (contingency_table - expected) / np.sqrt(expected)
    
    return {
        'chi2_statistic': chi2,
        'p_value': p_value,
        'degrees_of_freedom': dof,
        'cramers_v': cramers_v,
        'expected_frequencies': expected,
        'standardized_residuals': residuals,
        'significant': p_value < alpha
    }
```

## Correlation and Regression

### Correlation Analysis

#### Pearson Correlation
```python
def pearson_correlation(x, y, alpha=0.05):
    """
    Pearson correlation with confidence intervals
    """
    r, p_value = stats.pearsonr(x, y)
    
    # Confidence interval using Fisher transformation
    z = np.arctanh(r)
    se = 1 / np.sqrt(len(x) - 3)
    z_crit = stats.norm.ppf(1 - alpha/2)
    ci_z = [z - z_crit*se, z + z_crit*se]
    ci_r = [np.tanh(ci_z[0]), np.tanh(ci_z[1])]
    
    # Power analysis
    from statsmodels.stats.power import normal_power_het
    power = normal_power_het(r, len(x), alpha)
    
    return {
        'correlation': r,
        'p_value': p_value,
        'confidence_interval': ci_r,
        'r_squared': r**2,
        'power': power,
        'significant': p_value < alpha
    }
```

#### Spearman Correlation
```python
def spearman_correlation(x, y, alpha=0.05):
    """
    Spearman rank correlation (non-parametric)
    """
    rho, p_value = stats.spearmanr(x, y)
    
    # Bootstrap confidence interval
    def bootstrap_spearman(x, y, n_bootstrap=1000):
        correlations = []
        for _ in range(n_bootstrap):
            indices = np.random.choice(len(x), size=len(x), replace=True)
            correlations.append(stats.spearmanr(x[indices], y[indices])[0])
        return np.percentile(correlations, [2.5, 97.5])
    
    ci = bootstrap_spearman(x, y)
    
    return {
        'correlation': rho,
        'p_value': p_value,
        'confidence_interval': ci,
        'significant': p_value < alpha
    }
```

### Regression Analysis

#### Simple Linear Regression
```python
def simple_linear_regression(x, y, alpha=0.05):
    """
    Simple linear regression with diagnostics
    """
    # Fit model
    slope, intercept, r_value, p_value, std_err = stats.linregress(x, y)
    
    # Predictions and residuals
    y_pred = slope * x + intercept
    residuals = y - y_pred
    
    # Model diagnostics
    n = len(x)
    dof = n - 2
    mse = np.sum(residuals**2) / dof
    
    # Confidence intervals for parameters
    t_crit = stats.t.ppf(1 - alpha/2, dof)
    slope_ci = [slope - t_crit*std_err, slope + t_crit*std_err]
    
    # R-squared and adjusted R-squared
    r_squared = r_value**2
    adj_r_squared = 1 - (1 - r_squared) * (n - 1) / dof
    
    # Prediction interval function
    def prediction_interval(x_new):
        y_pred = slope * x_new + intercept
        se_pred = np.sqrt(mse * (1 + 1/n + (x_new - np.mean(x))**2 / np.sum((x - np.mean(x))**2)))
        margin = t_crit * se_pred
        return [y_pred - margin, y_pred + margin]
    
    return {
        'slope': slope,
        'intercept': intercept,
        'slope_ci': slope_ci,
        'r_squared': r_squared,
        'adj_r_squared': adj_r_squared,
        'p_value': p_value,
        'residuals': residuals,
        'mse': mse,
        'prediction_interval_func': prediction_interval
    }
```

#### Multiple Linear Regression
```python
import statsmodels.api as sm

def multiple_linear_regression(X, y, alpha=0.05):
    """
    Multiple linear regression with comprehensive diagnostics
    """
    # Add constant
    X_with_const = sm.add_constant(X)
    
    # Fit model
    model = sm.OLS(y, X_with_const).fit()
    
    # Diagnostic tests
    from statsmodels.stats.diagnostic import het_breuschpagan
    from statsmodels.stats.stattools import durbin_watson
    
    # Heteroscedasticity test
    bp_test = het_breuschpagan(model.resid, model.model.exog)
    
    # Autocorrelation test
    dw_stat = durbin_watson(model.resid)
    
    # Multicollinearity (VIF)
    from statsmodels.stats.outliers_influence import variance_inflation_factor
    vif = pd.DataFrame()
    vif["Variable"] = X.columns
    vif["VIF"] = [variance_inflation_factor(X.values, i) for i in range(X.shape[1])]
    
    return {
        'model': model,
        'coefficients': model.params,
        'p_values': model.pvalues,
        'confidence_intervals': model.conf_int(alpha=alpha),
        'r_squared': model.rsquared,
        'adj_r_squared': model.rsquared_adj,
        'aic': model.aic,
        'bic': model.bic,
        'heteroscedasticity_test': {
            'statistic': bp_test[0],
            'p_value': bp_test[1]
        },
        'durbin_watson': dw_stat,
        'vif': vif
    }
```

## Time Series Analysis

### Time Series Decomposition
```python
from statsmodels.tsa.seasonal import seasonal_decompose
from statsmodels.tsa.stattools import adfuller, kpss

def time_series_analysis(ts, freq=12):
    """
    Comprehensive time series analysis
    """
    # Decomposition
    decomposition = seasonal_decompose(ts, model='additive', period=freq)
    
    # Stationarity tests
    adf_test = adfuller(ts)
    kpss_test = kpss(ts)
    
    # ACF and PACF
    from statsmodels.graphics.tsaplots import plot_acf, plot_pacf
    acf_values = sm.tsa.stattools.acf(ts, nlags=40)
    pacf_values = sm.tsa.stattools.pacf(ts, nlags=40)
    
    return {
        'decomposition': {
            'trend': decomposition.trend,
            'seasonal': decomposition.seasonal,
            'residual': decomposition.resid
        },
        'stationarity': {
            'adf_statistic': adf_test[0],
            'adf_pvalue': adf_test[1],
            'kpss_statistic': kpss_test[0],
            'kpss_pvalue': kpss_test[1],
            'is_stationary': adf_test[1] < 0.05 and kpss_test[1] > 0.05
        },
        'autocorrelation': {
            'acf': acf_values,
            'pacf': pacf_values
        }
    }
```

### ARIMA Modeling
```python
from statsmodels.tsa.arima.model import ARIMA
from pmdarima import auto_arima

def fit_arima_model(ts, auto=True):
    """
    ARIMA model fitting with automatic order selection
    """
    if auto:
        # Automatic ARIMA
        model = auto_arima(
            ts,
            seasonal=True,
            m=12,
            stepwise=True,
            suppress_warnings=True,
            D=1,
            max_p=3,
            max_q=3,
            max_P=2,
            max_Q=2
        )
    else:
        # Manual ARIMA
        model = ARIMA(ts, order=(1, 1, 1)).fit()
    
    # Model diagnostics
    residuals = model.resid
    ljung_box = sm.stats.diagnostic.acorr_ljungbox(residuals, lags=10)
    
    return {
        'model': model,
        'aic': model.aic,
        'bic': model.bic,
        'residuals': residuals,
        'ljung_box_test': {
            'statistics': ljung_box['lb_stat'],
            'p_values': ljung_box['lb_pvalue']
        }
    }
```

## Bayesian Statistics

### Bayesian Inference
```python
import pymc3 as pm

def bayesian_t_test(group1, group2):
    """
    Bayesian alternative to t-test
    """
    with pm.Model() as model:
        # Priors
        mu1 = pm.Normal('mu1', mu=0, sigma=10)
        mu2 = pm.Normal('mu2', mu=0, sigma=10)
        sigma1 = pm.HalfNormal('sigma1', sigma=10)
        sigma2 = pm.HalfNormal('sigma2', sigma=10)
        
        # Likelihood
        obs1 = pm.Normal('obs1', mu=mu1, sigma=sigma1, observed=group1)
        obs2 = pm.Normal('obs2', mu=mu2, sigma=sigma2, observed=group2)
        
        # Derived quantities
        diff_means = pm.Deterministic('diff_means', mu1 - mu2)
        effect_size = pm.Deterministic('effect_size', 
                                      diff_means / pm.math.sqrt((sigma1**2 + sigma2**2) / 2))
        
        # Inference
        trace = pm.sample(2000, return_inferencedata=True)
    
    # Posterior analysis
    posterior_diff = trace.posterior['diff_means'].values.flatten()
    prob_greater = (posterior_diff > 0).mean()
    
    return {
        'trace': trace,
        'posterior_diff_mean': posterior_diff.mean(),
        'posterior_diff_hdi': pm.hdi(posterior_diff, 0.95),
        'probability_greater': prob_greater,
        'bayes_factor': calculate_bayes_factor(trace)
    }
```

## Sample Size and Power Analysis

### Power Analysis for Different Tests
```python
from statsmodels.stats.power import (
    ttest_power, ttest_ind_solve_power,
    anova_power, chi2_power
)

def comprehensive_power_analysis(test_type, **kwargs):
    """
    Power analysis for various statistical tests
    """
    if test_type == 't_test':
        # Two-sample t-test
        power = ttest_ind_solve_power(
            effect_size=kwargs.get('effect_size', 0.5),
            nobs1=kwargs.get('n', None),
            alpha=kwargs.get('alpha', 0.05),
            power=kwargs.get('power', None),
            ratio=kwargs.get('ratio', 1)
        )
    
    elif test_type == 'anova':
        # One-way ANOVA
        power = anova_power(
            effect_size=kwargs.get('effect_size', 0.25),
            nobs=kwargs.get('n', None),
            alpha=kwargs.get('alpha', 0.05),
            k_groups=kwargs.get('k_groups', 3)
        )
    
    elif test_type == 'chi2':
        # Chi-square test
        power = chi2_power(
            effect_size=kwargs.get('effect_size', 0.3),
            nobs=kwargs.get('n', None),
            alpha=kwargs.get('alpha', 0.05),
            n_bins=kwargs.get('n_bins', 4)
        )
    
    return power
```

## Best Practices

### Assumption Checking
1. Always verify test assumptions before interpretation
2. Use robust alternatives when assumptions are violated
3. Report assumption violations transparently
4. Consider transformations when appropriate

### Multiple Testing Correction
```python
from statsmodels.stats.multitest import multipletests

def multiple_testing_correction(p_values, method='bonferroni', alpha=0.05):
    """
    Apply multiple testing correction
    """
    methods = ['bonferroni', 'holm', 'fdr_bh', 'fdr_by']
    
    results = {}
    for method in methods:
        reject, p_adjusted, alpha_sidak, alpha_bonf = multipletests(
            p_values, alpha=alpha, method=method
        )
        results[method] = {
            'reject': reject,
            'p_adjusted': p_adjusted
        }
    
    return results
```

### Effect Size Guidelines
- Small: d = 0.2, r = 0.1, η² = 0.01
- Medium: d = 0.5, r = 0.3, η² = 0.06
- Large: d = 0.8, r = 0.5, η² = 0.14

### Reporting Standards
1. Report effect sizes alongside p-values
2. Include confidence intervals
3. Specify all assumptions and violations
4. Provide power analysis when possible
5. Use appropriate visualizations