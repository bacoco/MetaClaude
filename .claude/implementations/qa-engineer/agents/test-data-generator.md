# Test Data Generator Agent

## Overview
The Test Data Generator agent creates realistic, comprehensive, and compliant test data sets for various testing scenarios. It ensures tests have appropriate data that covers normal operations, edge cases, and error conditions while maintaining data privacy and regulatory compliance.

## Core Responsibilities

### 1. Data Generation
- Create synthetic test data for all data types
- Generate realistic data patterns and relationships
- Produce edge case and boundary value data
- Maintain referential integrity across data sets

### 2. Data Compliance
- Ensure GDPR/CCPA compliance
- Implement data anonymization techniques
- Manage PII (Personally Identifiable Information)
- Maintain audit trails for data usage

### 3. Data Management
- Version control for test data sets
- Data lifecycle management
- Test data refresh and cleanup
- Performance-optimized data generation

## Data Generation Strategies

### Realistic Data Patterns
```python
class RealisticDataGenerator:
    def generate_user_profile(self, locale='en_US'):
        """Generate realistic user profile data"""
        
        faker = Faker(locale)
        
        # Generate correlated data
        first_name = faker.first_name()
        last_name = faker.last_name()
        email = self.generate_email(first_name, last_name)
        
        profile = {
            'user_id': faker.uuid4(),
            'first_name': first_name,
            'last_name': last_name,
            'email': email,
            'phone': faker.phone_number(),
            'date_of_birth': faker.date_of_birth(minimum_age=18, maximum_age=80),
            'address': {
                'street': faker.street_address(),
                'city': faker.city(),
                'state': faker.state(),
                'postal_code': faker.postcode(),
                'country': faker.country_code()
            },
            'registration_date': faker.date_between(start_date='-2y', end_date='today'),
            'preferences': self.generate_user_preferences(),
            'activity_level': random.choice(['low', 'medium', 'high'])
        }
        
        return profile
    
    def generate_email(self, first_name, last_name):
        """Generate realistic email based on name"""
        
        patterns = [
            f"{first_name.lower()}.{last_name.lower()}",
            f"{first_name[0].lower()}{last_name.lower()}",
            f"{first_name.lower()}{last_name[0].lower()}",
            f"{first_name.lower()}{random.randint(1, 99)}"
        ]
        
        domains = ['gmail.com', 'yahoo.com', 'outlook.com', 'company.com']
        
        username = random.choice(patterns)
        domain = random.choice(domains)
        
        return f"{username}@{domain}"
```

### Edge Case Generation
```python
class EdgeCaseGenerator:
    def generate_edge_cases(self, field_type, constraints):
        """Generate edge case data for specific field types"""
        
        edge_cases = []
        
        if field_type == 'string':
            edge_cases.extend([
                '',  # Empty string
                ' ',  # Single space
                'A' * constraints.get('max_length', 255),  # Max length
                'Special chars: !@#$%^&*()',
                'Unicode: 你好世界 🌍',
                'SQL Injection: \'; DROP TABLE users; --',
                'XSS: <script>alert("XSS")</script>',
                None  # Null value
            ])
            
        elif field_type == 'number':
            min_val = constraints.get('min', float('-inf'))
            max_val = constraints.get('max', float('inf'))
            
            edge_cases.extend([
                min_val,  # Minimum boundary
                min_val - 1,  # Below minimum
                max_val,  # Maximum boundary
                max_val + 1,  # Above maximum
                0,  # Zero
                -1,  # Negative
                float('inf'),  # Infinity
                float('-inf'),  # Negative infinity
                float('nan'),  # Not a number
                None  # Null value
            ])
            
        elif field_type == 'date':
            edge_cases.extend([
                '1900-01-01',  # Far past
                '2999-12-31',  # Far future
                '2024-02-29',  # Leap year
                '2023-02-29',  # Invalid leap year
                'invalid-date',  # Invalid format
                None  # Null value
            ])
            
        return edge_cases
```

### Relationship Data Generation
```python
class RelationalDataGenerator:
    def generate_related_data(self, schema):
        """Generate data maintaining referential integrity"""
        
        data_sets = {}
        
        # Generate parent entities first
        for entity in schema.get_parent_entities():
            data_sets[entity.name] = self.generate_entity_data(entity)
        
        # Generate child entities with proper references
        for entity in schema.get_child_entities():
            child_data = []
            
            for i in range(entity.count):
                record = self.generate_entity_data(entity)
                
                # Add foreign key references
                for relation in entity.relations:
                    parent_data = data_sets[relation.parent_entity]
                    parent_record = random.choice(parent_data)
                    record[relation.foreign_key] = parent_record[relation.primary_key]
                
                child_data.append(record)
            
            data_sets[entity.name] = child_data
        
        return data_sets
```

## Data Privacy and Compliance

### PII Anonymization
```python
class DataAnonymizer:
    def anonymize_pii(self, data, rules):
        """Anonymize PII according to compliance rules"""
        
        anonymized = data.copy()
        
        for field, rule in rules.items():
            if field in anonymized:
                if rule == 'mask':
                    anonymized[field] = self.mask_data(anonymized[field])
                elif rule == 'hash':
                    anonymized[field] = self.hash_data(anonymized[field])
                elif rule == 'tokenize':
                    anonymized[field] = self.tokenize_data(anonymized[field])
                elif rule == 'generalize':
                    anonymized[field] = self.generalize_data(anonymized[field])
                elif rule == 'remove':
                    del anonymized[field]
        
        return anonymized
    
    def mask_data(self, value):
        """Mask sensitive data while preserving format"""
        
        if '@' in str(value):  # Email
            parts = value.split('@')
            masked_local = parts[0][0] + '*' * (len(parts[0]) - 2) + parts[0][-1]
            return f"{masked_local}@{parts[1]}"
        
        elif len(str(value)) > 4:  # General masking
            visible_chars = 2
            return value[:visible_chars] + '*' * (len(value) - visible_chars * 2) + value[-visible_chars:]
        
        return '*' * len(str(value))
```

### GDPR-Compliant Test Data
```python
def generate_gdpr_compliant_data(self, data_requirements):
    """Generate test data compliant with GDPR regulations"""
    
    compliant_data = []
    
    for requirement in data_requirements:
        # Generate base data
        record = self.generate_base_record(requirement)
        
        # Apply GDPR compliance
        record['consent'] = {
            'marketing': random.choice([True, False]),
            'data_processing': True,  # Required for testing
            'third_party_sharing': False,
            'consent_date': faker.date_between(start_date='-1y', end_date='today')
        }
        
        # Add right to be forgotten marker
        record['gdpr_flags'] = {
            'deletion_requested': False,
            'data_portability_requested': False,
            'processing_restricted': False
        }
        
        # Ensure data minimization
        record = self.apply_data_minimization(record, requirement)
        
        compliant_data.append(record)
    
    return compliant_data
```

## Specialized Data Types

### Time Series Data
```python
def generate_time_series_data(self, config):
    """Generate time series test data"""
    
    start_date = config['start_date']
    end_date = config['end_date']
    frequency = config['frequency']  # hourly, daily, etc.
    
    timestamps = pd.date_range(start=start_date, end=end_date, freq=frequency)
    
    data = []
    base_value = config.get('base_value', 100)
    
    for timestamp in timestamps:
        # Add trends
        trend = self.calculate_trend(timestamp, config.get('trend', 0))
        
        # Add seasonality
        seasonal = self.calculate_seasonality(timestamp, config.get('seasonality', {}))
        
        # Add random noise
        noise = random.gauss(0, config.get('noise_std', 5))
        
        value = base_value + trend + seasonal + noise
        
        # Add anomalies
        if random.random() < config.get('anomaly_rate', 0.01):
            value *= random.uniform(0.5, 2.0)
        
        data.append({
            'timestamp': timestamp,
            'value': value,
            'metadata': self.generate_metadata(timestamp)
        })
    
    return data
```

### Geospatial Data
```python
def generate_geospatial_data(self, config):
    """Generate geospatial test data"""
    
    data = []
    
    for i in range(config['count']):
        # Generate coordinates within bounds
        lat = random.uniform(config['lat_min'], config['lat_max'])
        lon = random.uniform(config['lon_min'], config['lon_max'])
        
        # Add realistic constraints
        if config.get('urban_bias', False):
            # Cluster around urban centers
            city_center = random.choice(config['urban_centers'])
            lat += random.gauss(city_center['lat'], 0.1)
            lon += random.gauss(city_center['lon'], 0.1)
        
        location = {
            'id': faker.uuid4(),
            'latitude': round(lat, 6),
            'longitude': round(lon, 6),
            'altitude': random.uniform(0, 1000) if config.get('include_altitude') else None,
            'accuracy': random.uniform(5, 50),  # meters
            'timestamp': faker.date_time_between(start_date='-1d', end_date='now'),
            'address': self.reverse_geocode(lat, lon) if config.get('include_address') else None
        }
        
        data.append(location)
    
    return data
```

## Data Set Management

### Version Control
```python
class TestDataVersionControl:
    def save_version(self, data_set, metadata):
        """Save versioned test data set"""
        
        version = {
            'id': self.generate_version_id(),
            'timestamp': datetime.now(),
            'data_hash': self.calculate_data_hash(data_set),
            'metadata': metadata,
            'parent_version': metadata.get('parent_version'),
            'changes': self.calculate_changes(data_set, metadata.get('parent_version'))
        }
        
        # Store data
        storage_path = f"test_data/v{version['id']}/{metadata['name']}"
        self.storage.save(storage_path, data_set)
        
        # Update version registry
        self.version_registry.add(version)
        
        return version['id']
    
    def rollback_version(self, version_id):
        """Rollback to specific test data version"""
        
        version = self.version_registry.get(version_id)
        data_set = self.storage.load(f"test_data/v{version_id}/{version['metadata']['name']}")
        
        # Create new version pointing to rollback
        rollback_metadata = version['metadata'].copy()
        rollback_metadata['rollback_from'] = self.get_current_version()
        rollback_metadata['parent_version'] = version_id
        
        return self.save_version(data_set, rollback_metadata)
```

### Data Lifecycle Management
```python
def manage_data_lifecycle(self):
    """Manage test data lifecycle - creation, usage, cleanup"""
    
    lifecycle_rules = {
        'retention_days': 30,
        'cleanup_unused': True,
        'archive_old': True,
        'compliance_check': True
    }
    
    # Identify data for cleanup
    cleanup_candidates = []
    
    for data_set in self.get_all_data_sets():
        age_days = (datetime.now() - data_set['created_date']).days
        
        if age_days > lifecycle_rules['retention_days']:
            if self.is_data_unused(data_set) and lifecycle_rules['cleanup_unused']:
                cleanup_candidates.append(data_set)
            elif lifecycle_rules['archive_old']:
                self.archive_data(data_set)
        
        # Compliance check
        if lifecycle_rules['compliance_check']:
            self.verify_compliance(data_set)
    
    # Execute cleanup
    for data_set in cleanup_candidates:
        self.cleanup_data(data_set)
    
    return {
        'cleaned_up': len(cleanup_candidates),
        'archived': self.get_archive_count(),
        'active': self.get_active_count()
    }
```

## Performance Optimization

### Lazy Generation
```python
class LazyDataGenerator:
    def __init__(self, config):
        self.config = config
        self._cache = {}
    
    def __iter__(self):
        """Iterate through data, generating on-demand"""
        
        for i in range(self.config['count']):
            if i not in self._cache:
                self._cache[i] = self.generate_record(i)
            
            yield self._cache[i]
    
    def generate_record(self, index):
        """Generate single record on demand"""
        
        record = {
            'id': index,
            'data': self.generate_data_for_index(index)
        }
        
        return record
```

### Batch Generation
```python
def generate_batch_data(self, config):
    """Generate data in optimized batches"""
    
    total_count = config['count']
    batch_size = config.get('batch_size', 1000)
    
    with ThreadPoolExecutor(max_workers=4) as executor:
        futures = []
        
        for start in range(0, total_count, batch_size):
            end = min(start + batch_size, total_count)
            future = executor.submit(self.generate_batch, start, end, config)
            futures.append(future)
        
        # Collect results
        all_data = []
        for future in as_completed(futures):
            batch_data = future.result()
            all_data.extend(batch_data)
    
    return all_data
```

## Integration Features

### API Mocking
```python
def generate_api_mock_data(self, api_spec):
    """Generate mock data based on API specification"""
    
    mock_responses = {}
    
    for endpoint in api_spec['endpoints']:
        method = endpoint['method']
        path = endpoint['path']
        
        # Generate response based on schema
        response_schema = endpoint.get('response_schema', {})
        mock_response = self.generate_from_schema(response_schema)
        
        # Add variations for different scenarios
        mock_responses[f"{method} {path}"] = {
            'success': mock_response,
            'error_400': self.generate_error_response(400, 'Bad Request'),
            'error_401': self.generate_error_response(401, 'Unauthorized'),
            'error_500': self.generate_error_response(500, 'Internal Server Error'),
            'empty': [] if response_schema.get('type') == 'array' else {},
            'pagination': self.generate_paginated_response(mock_response) if endpoint.get('paginated') else None
        }
    
    return mock_responses
```

The Test Data Generator agent ensures comprehensive test coverage through intelligent data generation, maintaining the delicate balance between realism, compliance, and testing effectiveness.