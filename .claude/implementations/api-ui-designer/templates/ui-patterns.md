# Common UI Pattern Templates

Reusable UI patterns and templates for API-driven interfaces.

## Table of Contents
- [Authentication Patterns](#authentication-patterns)
- [CRUD Patterns](#crud-patterns)
- [Search and Filter Patterns](#search-and-filter-patterns)
- [Data Visualization Patterns](#data-visualization-patterns)
- [Real-time Patterns](#real-time-patterns)
- [File Management Patterns](#file-management-patterns)
- [E-commerce Patterns](#e-commerce-patterns)
- [Admin Dashboard Patterns](#admin-dashboard-patterns)

## Authentication Patterns

### Login Flow
Complete login interface with remember me, social login, and password recovery.

```jsx
// Template: LoginPage
export const LoginPageTemplate = () => {
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const { login } = useAuth();
  const navigate = useNavigate();
  
  return (
    <AuthLayout>
      <Card className="login-card">
        <CardHeader>
          <Logo />
          <h1>Welcome Back</h1>
          <p>Sign in to your account to continue</p>
        </CardHeader>
        
        <CardContent>
          <Form
            onSubmit={async (values) => {
              setLoading(true);
              try {
                await login(values);
                navigate('/dashboard');
              } catch (error) {
                toast.error('Invalid credentials');
              } finally {
                setLoading(false);
              }
            }}
          >
            <EmailInput
              name="email"
              label="Email Address"
              required
              autoFocus
              icon="mail"
            />
            
            <PasswordInput
              name="password"
              label="Password"
              required
              showToggle
              icon="lock"
            />
            
            <div className="form-options">
              <Checkbox name="rememberMe" label="Remember me" />
              <Link to="/auth/forgot-password">Forgot password?</Link>
            </div>
            
            <Button
              type="submit"
              variant="primary"
              fullWidth
              loading={loading}
            >
              Sign In
            </Button>
          </Form>
          
          <Divider>Or continue with</Divider>
          
          <SocialLoginButtons>
            <SocialButton provider="google" />
            <SocialButton provider="github" />
            <SocialButton provider="microsoft" />
          </SocialLoginButtons>
          
          <div className="auth-footer">
            Don't have an account? <Link to="/auth/register">Sign up</Link>
          </div>
        </CardContent>
      </Card>
    </AuthLayout>
  );
};
```

### Registration Wizard
Multi-step registration with validation and progress tracking.

```jsx
// Template: RegistrationWizard
export const RegistrationWizardTemplate = () => {
  const [currentStep, setCurrentStep] = useState(0);
  const [formData, setFormData] = useState({});
  
  const steps = [
    {
      title: 'Account Setup',
      fields: ['email', 'password', 'confirmPassword'],
      component: <AccountSetupStep />,
      validation: accountSchema
    },
    {
      title: 'Personal Information',
      fields: ['firstName', 'lastName', 'phone', 'birthDate'],
      component: <PersonalInfoStep />,
      validation: personalSchema
    },
    {
      title: 'Preferences',
      fields: ['language', 'timezone', 'notifications'],
      component: <PreferencesStep />,
      optional: true
    },
    {
      title: 'Confirmation',
      component: <ConfirmationStep data={formData} />
    }
  ];
  
  return (
    <WizardLayout>
      <ProgressBar
        steps={steps.map(s => s.title)}
        current={currentStep}
      />
      
      <WizardContent>
        <AnimatePresence mode="wait">
          <motion.div
            key={currentStep}
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
          >
            {steps[currentStep].component}
          </motion.div>
        </AnimatePresence>
      </WizardContent>
      
      <WizardActions>
        <Button
          variant="text"
          onClick={() => setCurrentStep(prev => prev - 1)}
          disabled={currentStep === 0}
        >
          Previous
        </Button>
        
        {steps[currentStep].optional && (
          <Button
            variant="text"
            onClick={() => setCurrentStep(prev => prev + 1)}
          >
            Skip
          </Button>
        )}
        
        <Button
          variant="primary"
          onClick={handleNext}
        >
          {currentStep === steps.length - 1 ? 'Complete' : 'Next'}
        </Button>
      </WizardActions>
    </WizardLayout>
  );
};
```

### Two-Factor Authentication
2FA setup and verification interface.

```jsx
// Template: TwoFactorSetup
export const TwoFactorSetupTemplate = () => {
  const [method, setMethod] = useState('app');
  const [verificationCode, setVerificationCode] = useState('');
  
  return (
    <Card>
      <CardHeader>
        <Icon name="shield" size="large" color="primary" />
        <h2>Enable Two-Factor Authentication</h2>
        <p>Add an extra layer of security to your account</p>
      </CardHeader>
      
      <CardContent>
        <Tabs
          value={method}
          onChange={setMethod}
          tabs={[
            { id: 'app', label: 'Authenticator App', icon: 'smartphone' },
            { id: 'sms', label: 'SMS', icon: 'message' },
            { id: 'email', label: 'Email', icon: 'mail' }
          ]}
        />
        
        {method === 'app' && (
          <div className="2fa-app-setup">
            <Steps>
              <Step>
                <p>Install an authenticator app like Google Authenticator or Authy</p>
              </Step>
              <Step>
                <p>Scan this QR code with your authenticator app</p>
                <QRCode value={totpUri} size={200} />
                <details>
                  <summary>Can't scan? Enter this code manually</summary>
                  <CopyableText value={secret} />
                </details>
              </Step>
              <Step>
                <p>Enter the 6-digit code from your app</p>
                <OTPInput
                  value={verificationCode}
                  onChange={setVerificationCode}
                  numInputs={6}
                  autoFocus
                />
              </Step>
            </Steps>
          </div>
        )}
        
        {method === 'sms' && (
          <div className="2fa-sms-setup">
            <PhoneInput
              name="phone"
              label="Phone Number"
              required
              helperText="We'll send a verification code to this number"
            />
            <Button variant="secondary" onClick={sendSMSCode}>
              Send Code
            </Button>
          </div>
        )}
        
        <Alert type="info" icon="info">
          <strong>Backup Codes</strong>
          <p>After enabling 2FA, you'll receive backup codes to use if you lose access to your device.</p>
        </Alert>
        
        <div className="actions">
          <Button variant="text" onClick={onCancel}>
            Cancel
          </Button>
          <Button
            variant="primary"
            onClick={handleEnable2FA}
            disabled={!verificationCode}
          >
            Enable 2FA
          </Button>
        </div>
      </CardContent>
    </Card>
  );
};
```

## CRUD Patterns

### List View with Filters
Comprehensive list interface with search, filters, and bulk actions.

```jsx
// Template: ResourceListView
export const ResourceListViewTemplate = ({ resource, columns, filters }) => {
  const [selectedRows, setSelectedRows] = useState([]);
  const [view, setView] = useState('table'); // table | grid | list
  const { data, loading, pagination, refetch } = useResourceList(resource);
  
  return (
    <PageLayout
      title={`${resource} Management`}
      actions={
        <>
          <Button
            variant="primary"
            icon="plus"
            onClick={() => navigate(`/${resource}/new`)}
          >
            Create {resource}
          </Button>
          <Dropdown
            trigger={<Button variant="text" icon="download">Export</Button>}
            items={[
              { label: 'Export as CSV', onClick: () => exportData('csv') },
              { label: 'Export as Excel', onClick: () => exportData('xlsx') },
              { label: 'Export as PDF', onClick: () => exportData('pdf') }
            ]}
          />
        </>
      }
    >
      <div className="list-controls">
        <SearchInput
          placeholder={`Search ${resource}...`}
          onSearch={handleSearch}
          showAdvanced
        />
        
        <div className="view-controls">
          <FilterPanel
            filters={filters}
            onChange={handleFilterChange}
            showActiveCount
          />
          
          <ViewToggle
            value={view}
            onChange={setView}
            options={['table', 'grid', 'list']}
          />
        </div>
      </div>
      
      {selectedRows.length > 0 && (
        <BulkActionsBar
          selectedCount={selectedRows.length}
          actions={[
            { label: 'Delete', icon: 'trash', onClick: handleBulkDelete, variant: 'danger' },
            { label: 'Export', icon: 'download', onClick: handleBulkExport },
            { label: 'Update Status', icon: 'edit', onClick: handleBulkUpdate }
          ]}
          onClear={() => setSelectedRows([])}
        />
      )}
      
      <div className="list-content">
        {loading ? (
          <LoadingState type="skeleton" />
        ) : data.length === 0 ? (
          <EmptyState
            title={`No ${resource} found`}
            description="Try adjusting your filters or create a new item"
            action={{
              label: `Create ${resource}`,
              onClick: () => navigate(`/${resource}/new`)
            }}
          />
        ) : (
          <>
            {view === 'table' && (
              <DataTable
                data={data}
                columns={columns}
                selection="multiple"
                selectedRows={selectedRows}
                onSelectionChange={setSelectedRows}
                sortable
                onSort={handleSort}
              />
            )}
            
            {view === 'grid' && (
              <CardGrid>
                {data.map(item => (
                  <ResourceCard
                    key={item.id}
                    data={item}
                    selected={selectedRows.includes(item.id)}
                    onSelect={() => handleSelectItem(item.id)}
                    actions={getItemActions(item)}
                  />
                ))}
              </CardGrid>
            )}
            
            {view === 'list' && (
              <ListView>
                {data.map(item => (
                  <ListItem
                    key={item.id}
                    primary={item.name}
                    secondary={item.description}
                    meta={formatDate(item.updatedAt)}
                    selected={selectedRows.includes(item.id)}
                    onSelect={() => handleSelectItem(item.id)}
                    actions={getItemActions(item)}
                  />
                ))}
              </ListView>
            )}
          </>
        )}
      </div>
      
      <Pagination
        {...pagination}
        onChange={handlePageChange}
        showSizeChanger
        showTotal
      />
    </PageLayout>
  );
};
```

### Create/Edit Form
Unified form for creating and editing resources.

```jsx
// Template: ResourceForm
export const ResourceFormTemplate = ({ resource, id, fields, onSave }) => {
  const isEdit = !!id;
  const { data: initialData, loading } = useResource(resource, id);
  const [isDirty, setIsDirty] = useState(false);
  
  if (loading) return <LoadingState />;
  
  return (
    <PageLayout
      title={isEdit ? `Edit ${resource}` : `Create ${resource}`}
      breadcrumbs={[
        { label: resource, href: `/${resource}` },
        { label: isEdit ? 'Edit' : 'Create' }
      ]}
    >
      <Form
        initialValues={initialData}
        onSubmit={async (values) => {
          await onSave(values);
          navigate(`/${resource}`);
        }}
        onChange={() => setIsDirty(true)}
      >
        <Card>
          <CardContent>
            <FormSection title="Basic Information">
              {fields.basic.map(field => (
                <DynamicField key={field.name} {...field} />
              ))}
            </FormSection>
            
            <FormSection title="Details" collapsible defaultCollapsed={!isEdit}>
              {fields.details.map(field => (
                <DynamicField key={field.name} {...field} />
              ))}
            </FormSection>
            
            {fields.metadata && (
              <FormSection title="Metadata" collapsible defaultCollapsed>
                <JsonEditor
                  name="metadata"
                  height={200}
                  schema={metadataSchema}
                />
              </FormSection>
            )}
          </CardContent>
          
          <CardActions>
            <Button
              variant="text"
              onClick={() => {
                if (isDirty) {
                  confirm('Discard unsaved changes?') && navigate(-1);
                } else {
                  navigate(-1);
                }
              }}
            >
              Cancel
            </Button>
            
            <Button variant="secondary" type="reset">
              Reset
            </Button>
            
            <Button variant="primary" type="submit">
              {isEdit ? 'Save Changes' : 'Create'}
            </Button>
          </CardActions>
        </Card>
        
        {isEdit && (
          <Card className="danger-zone">
            <CardHeader>
              <h3>Danger Zone</h3>
            </CardHeader>
            <CardContent>
              <div className="danger-action">
                <div>
                  <h4>Delete this {resource}</h4>
                  <p>Once deleted, this cannot be undone.</p>
                </div>
                <Button
                  variant="danger"
                  onClick={() => handleDelete(id)}
                >
                  Delete {resource}
                </Button>
              </div>
            </CardContent>
          </Card>
        )}
      </Form>
    </PageLayout>
  );
};
```

### Detail View with Actions
Comprehensive detail view with related data and actions.

```jsx
// Template: ResourceDetailView
export const ResourceDetailViewTemplate = ({ resource, id, sections }) => {
  const { data, loading, refetch } = useResource(resource, id);
  const [activeTab, setActiveTab] = useState('overview');
  
  if (loading) return <LoadingState />;
  if (!data) return <NotFound />;
  
  return (
    <PageLayout
      title={data.name || `${resource} Details`}
      subtitle={`ID: ${data.id}`}
      breadcrumbs={[
        { label: resource, href: `/${resource}` },
        { label: data.name || 'Details' }
      ]}
      actions={
        <ActionMenu
          items={[
            { label: 'Edit', icon: 'edit', onClick: () => navigate(`/${resource}/${id}/edit`) },
            { label: 'Duplicate', icon: 'copy', onClick: handleDuplicate },
            { label: 'Export', icon: 'download', onClick: handleExport },
            { divider: true },
            { label: 'Delete', icon: 'trash', onClick: handleDelete, variant: 'danger' }
          ]}
        />
      }
    >
      <div className="detail-header">
        <StatusBadge status={data.status} size="large" />
        <div className="meta-info">
          <span>Created {formatDate(data.createdAt, 'relative')}</span>
          <span>•</span>
          <span>Updated {formatDate(data.updatedAt, 'relative')}</span>
        </div>
      </div>
      
      <Tabs
        value={activeTab}
        onChange={setActiveTab}
        tabs={[
          { id: 'overview', label: 'Overview', icon: 'info' },
          { id: 'activity', label: 'Activity', icon: 'clock', badge: data.activityCount },
          { id: 'related', label: 'Related', icon: 'link' },
          { id: 'settings', label: 'Settings', icon: 'settings' }
        ]}
      />
      
      <TabContent value={activeTab}>
        <TabPanel value="overview">
          <Grid container spacing={3}>
            <Grid item xs={12} md={8}>
              {sections.main.map(section => (
                <Card key={section.id} className="detail-section">
                  <CardHeader>
                    <h3>{section.title}</h3>
                    {section.editable && (
                      <IconButton
                        icon="edit"
                        size="small"
                        onClick={() => handleEditSection(section.id)}
                      />
                    )}
                  </CardHeader>
                  <CardContent>
                    <DetailGrid fields={section.fields} data={data} />
                  </CardContent>
                </Card>
              ))}
            </Grid>
            
            <Grid item xs={12} md={4}>
              {sections.sidebar.map(section => (
                <Card key={section.id} className="sidebar-section">
                  <CardHeader>
                    <h4>{section.title}</h4>
                  </CardHeader>
                  <CardContent>
                    {section.component}
                  </CardContent>
                </Card>
              ))}
            </Grid>
          </Grid>
        </TabPanel>
        
        <TabPanel value="activity">
          <ActivityTimeline
            activities={data.activities}
            onLoadMore={loadMoreActivities}
          />
        </TabPanel>
        
        <TabPanel value="related">
          <RelatedResources
            resource={resource}
            id={id}
            relations={sections.relations}
          />
        </TabPanel>
        
        <TabPanel value="settings">
          <ResourceSettings
            resource={resource}
            data={data}
            onUpdate={(updates) => {
              updateResource(id, updates);
              refetch();
            }}
          />
        </TabPanel>
      </TabContent>
    </PageLayout>
  );
};
```

## Search and Filter Patterns

### Advanced Search Interface
Full-featured search with autocomplete and filters.

```jsx
// Template: AdvancedSearch
export const AdvancedSearchTemplate = () => {
  const [query, setQuery] = useState('');
  const [filters, setFilters] = useState({});
  const [showAdvanced, setShowAdvanced] = useState(false);
  const { results, loading, suggestions } = useSearch(query, filters);
  
  return (
    <div className="advanced-search">
      <SearchBar>
        <SearchInput
          value={query}
          onChange={setQuery}
          placeholder="Search for anything..."
          size="large"
          icon="search"
          onSubmit={handleSearch}
        />
        
        <Button
          variant="text"
          icon={showAdvanced ? 'chevron-up' : 'chevron-down'}
          onClick={() => setShowAdvanced(!showAdvanced)}
        >
          Advanced
        </Button>
      </SearchBar>
      
      {suggestions.length > 0 && (
        <SearchSuggestions>
          {suggestions.map(suggestion => (
            <SuggestionItem
              key={suggestion.id}
              onClick={() => handleSuggestionClick(suggestion)}
            >
              <Icon name={suggestion.type} />
              <span dangerouslySetInnerHTML={{ 
                __html: highlightMatch(suggestion.text, query) 
              }} />
              <Badge>{suggestion.category}</Badge>
            </SuggestionItem>
          ))}
        </SearchSuggestions>
      )}
      
      <Collapse open={showAdvanced}>
        <AdvancedFilters>
          <Grid container spacing={2}>
            <Grid item xs={12} md={4}>
              <Select
                label="Category"
                name="category"
                options={categories}
                value={filters.category}
                onChange={(value) => updateFilter('category', value)}
                multiple
              />
            </Grid>
            
            <Grid item xs={12} md={4}>
              <DateRangePicker
                label="Date Range"
                value={filters.dateRange}
                onChange={(range) => updateFilter('dateRange', range)}
                presets={datePresets}
              />
            </Grid>
            
            <Grid item xs={12} md={4}>
              <Select
                label="Status"
                name="status"
                options={statuses}
                value={filters.status}
                onChange={(value) => updateFilter('status', value)}
              />
            </Grid>
            
            <Grid item xs={12}>
              <TagInput
                label="Tags"
                value={filters.tags}
                onChange={(tags) => updateFilter('tags', tags)}
                suggestions={popularTags}
              />
            </Grid>
          </Grid>
          
          <div className="filter-actions">
            <Button variant="text" onClick={clearFilters}>
              Clear All
            </Button>
            <Button variant="secondary" onClick={saveSearch}>
              Save Search
            </Button>
          </div>
        </AdvancedFilters>
      </Collapse>
      
      {(query || hasActiveFilters(filters)) && (
        <>
          <SearchResults>
            <div className="results-header">
              <h3>
                {loading ? 'Searching...' : `${results.total} results found`}
              </h3>
              
              <div className="results-controls">
                <Select
                  value={sortBy}
                  onChange={setSortBy}
                  options={sortOptions}
                  size="small"
                />
                
                <ViewToggle
                  value={viewMode}
                  onChange={setViewMode}
                  options={['list', 'grid']}
                />
              </div>
            </div>
            
            {loading ? (
              <LoadingState type="skeleton" count={5} />
            ) : results.items.length === 0 ? (
              <EmptyState
                title="No results found"
                description="Try adjusting your search terms or filters"
                suggestions={searchSuggestions}
              />
            ) : (
              <SearchResultsList
                results={results.items}
                viewMode={viewMode}
                onItemClick={handleResultClick}
              />
            )}
          </SearchResults>
          
          {results.hasMore && (
            <LoadMoreButton onClick={loadMore} loading={loadingMore}>
              Load More Results
            </LoadMoreButton>
          )}
        </>
      )}
    </div>
  );
};
```

### Faceted Search
Search with dynamic facets based on results.

```jsx
// Template: FacetedSearch
export const FacetedSearchTemplate = () => {
  const [query, setQuery] = useState('');
  const [selectedFacets, setSelectedFacets] = useState({});
  const { results, facets, loading } = useFacetedSearch(query, selectedFacets);
  
  return (
    <div className="faceted-search">
      <SearchHeader>
        <SearchInput
          value={query}
          onChange={setQuery}
          placeholder="Search products..."
          onSubmit={handleSearch}
        />
      </SearchHeader>
      
      <div className="search-layout">
        <aside className="facets-sidebar">
          <FacetFilters>
            {facets.map(facet => (
              <FacetGroup
                key={facet.field}
                title={facet.label}
                collapsible
                defaultExpanded={facet.important}
              >
                {facet.type === 'list' && (
                  <FacetList>
                    {facet.values.map(value => (
                      <FacetItem
                        key={value.value}
                        checked={selectedFacets[facet.field]?.includes(value.value)}
                        onChange={(checked) => 
                          toggleFacet(facet.field, value.value, checked)
                        }
                      >
                        <span>{value.label}</span>
                        <Badge size="small">{value.count}</Badge>
                      </FacetItem>
                    ))}
                    {facet.hasMore && (
                      <Button
                        variant="text"
                        size="small"
                        onClick={() => expandFacet(facet.field)}
                      >
                        Show more
                      </Button>
                    )}
                  </FacetList>
                )}
                
                {facet.type === 'range' && (
                  <RangeSlider
                    min={facet.min}
                    max={facet.max}
                    value={selectedFacets[facet.field] || [facet.min, facet.max]}
                    onChange={(value) => updateFacet(facet.field, value)}
                    format={facet.format}
                  />
                )}
                
                {facet.type === 'color' && (
                  <ColorGrid>
                    {facet.values.map(color => (
                      <ColorSwatch
                        key={color.value}
                        color={color.value}
                        selected={selectedFacets[facet.field]?.includes(color.value)}
                        onClick={() => toggleFacet(facet.field, color.value)}
                        tooltip={color.label}
                      />
                    ))}
                  </ColorGrid>
                )}
              </FacetGroup>
            ))}
          </FacetFilters>
          
          <Button
            variant="text"
            onClick={clearAllFacets}
            disabled={Object.keys(selectedFacets).length === 0}
          >
            Clear All Filters
          </Button>
        </aside>
        
        <main className="search-results">
          <ResultsHeader>
            <ActiveFilters
              query={query}
              facets={selectedFacets}
              onRemove={removeFacet}
              onClear={clearAllFacets}
            />
            
            <ResultsInfo>
              Showing {results.showing} of {results.total} results
            </ResultsInfo>
            
            <SortDropdown
              value={sortBy}
              onChange={setSortBy}
              options={[
                { value: 'relevance', label: 'Best Match' },
                { value: 'price-asc', label: 'Price: Low to High' },
                { value: 'price-desc', label: 'Price: High to Low' },
                { value: 'rating', label: 'Customer Rating' },
                { value: 'newest', label: 'Newest First' }
              ]}
            />
          </ResultsHeader>
          
          {loading ? (
            <ResultsSkeleton count={12} />
          ) : (
            <ResultsGrid>
              {results.items.map(item => (
                <ProductCard
                  key={item.id}
                  product={item}
                  onQuickView={() => openQuickView(item)}
                  onAddToCart={() => addToCart(item)}
                />
              ))}
            </ResultsGrid>
          )}
          
          <Pagination
            current={results.page}
            total={results.totalPages}
            onChange={handlePageChange}
          />
        </main>
      </div>
    </div>
  );
};
```

## Data Visualization Patterns

### Analytics Dashboard
Comprehensive dashboard with multiple chart types.

```jsx
// Template: AnalyticsDashboard
export const AnalyticsDashboardTemplate = () => {
  const [dateRange, setDateRange] = useState('last30days');
  const [compareMode, setCompareMode] = useState(false);
  const { metrics, charts, loading } = useAnalytics(dateRange, compareMode);
  
  return (
    <DashboardLayout>
      <DashboardHeader>
        <h1>Analytics Overview</h1>
        
        <DashboardControls>
          <DateRangePicker
            value={dateRange}
            onChange={setDateRange}
            presets={[
              { label: 'Today', value: 'today' },
              { label: 'Yesterday', value: 'yesterday' },
              { label: 'Last 7 days', value: 'last7days' },
              { label: 'Last 30 days', value: 'last30days' },
              { label: 'Last 90 days', value: 'last90days' },
              { label: 'Custom', value: 'custom' }
            ]}
          />
          
          <Switch
            checked={compareMode}
            onChange={setCompareMode}
            label="Compare to previous period"
          />
          
          <Button
            variant="secondary"
            icon="refresh"
            onClick={refreshData}
          >
            Refresh
          </Button>
          
          <ExportMenu
            formats={['pdf', 'excel', 'csv']}
            onExport={handleExport}
          />
        </DashboardControls>
      </DashboardHeader>
      
      <MetricsRow>
        <MetricCard
          title="Total Revenue"
          value={metrics.revenue}
          previousValue={compareMode ? metrics.previousRevenue : null}
          format="currency"
          icon="dollar"
          color="success"
          trend={calculateTrend(metrics.revenue, metrics.previousRevenue)}
          sparkline={metrics.revenueSparkline}
        />
        
        <MetricCard
          title="Active Users"
          value={metrics.activeUsers}
          previousValue={compareMode ? metrics.previousActiveUsers : null}
          format="number"
          icon="users"
          color="primary"
          trend={calculateTrend(metrics.activeUsers, metrics.previousActiveUsers)}
          sparkline={metrics.usersSparkline}
        />
        
        <MetricCard
          title="Conversion Rate"
          value={metrics.conversionRate}
          previousValue={compareMode ? metrics.previousConversionRate : null}
          format="percentage"
          icon="trending-up"
          color="info"
          trend={calculateTrend(metrics.conversionRate, metrics.previousConversionRate)}
          sparkline={metrics.conversionSparkline}
        />
        
        <MetricCard
          title="Avg. Order Value"
          value={metrics.avgOrderValue}
          previousValue={compareMode ? metrics.previousAvgOrderValue : null}
          format="currency"
          icon="shopping-cart"
          color="warning"
          trend={calculateTrend(metrics.avgOrderValue, metrics.previousAvgOrderValue)}
          sparkline={metrics.aovSparkline}
        />
      </MetricsRow>
      
      <ChartsGrid>
        <ChartCard title="Revenue Over Time" span={8}>
          <LineChart
            data={charts.revenue}
            compareData={compareMode ? charts.previousRevenue : null}
            height={300}
            options={{
              scales: {
                y: {
                  ticks: {
                    callback: (value) => formatCurrency(value)
                  }
                }
              }
            }}
          />
        </ChartCard>
        
        <ChartCard title="Traffic Sources" span={4}>
          <PieChart
            data={charts.trafficSources}
            height={300}
            options={{
              plugins: {
                legend: {
                  position: 'bottom'
                }
              }
            }}
          />
        </ChartCard>
        
        <ChartCard title="Conversion Funnel" span={6}>
          <FunnelChart
            data={charts.conversionFunnel}
            height={250}
            showPercentages
          />
        </ChartCard>
        
        <ChartCard title="User Activity Heatmap" span={6}>
          <HeatmapChart
            data={charts.userActivity}
            height={250}
            xLabel="Hour of Day"
            yLabel="Day of Week"
          />
        </ChartCard>
        
        <ChartCard title="Top Products" span={12}>
          <BarChart
            data={charts.topProducts}
            height={200}
            horizontal
            options={{
              indexAxis: 'y',
              scales: {
                x: {
                  ticks: {
                    callback: (value) => formatCurrency(value)
                  }
                }
              }
            }}
          />
        </ChartCard>
      </ChartsGrid>
      
      <InsightsSection>
        <h2>Key Insights</h2>
        <InsightsList>
          {metrics.insights.map((insight, index) => (
            <InsightCard
              key={index}
              type={insight.type}
              title={insight.title}
              description={insight.description}
              action={insight.action}
            />
          ))}
        </InsightsList>
      </InsightsSection>
    </DashboardLayout>
  );
};
```

## Real-time Patterns

### Live Dashboard
Real-time updating dashboard with WebSocket integration.

```jsx
// Template: LiveDashboard
export const LiveDashboardTemplate = () => {
  const [connectionStatus, setConnectionStatus] = useState('connecting');
  const [liveData, setLiveData] = useState({});
  const ws = useWebSocket('wss://api.example.com/live', {
    onOpen: () => setConnectionStatus('connected'),
    onClose: () => setConnectionStatus('disconnected'),
    onMessage: (event) => {
      const data = JSON.parse(event.data);
      updateLiveData(data);
    }
  });
  
  return (
    <LiveDashboardLayout>
      <StatusBar>
        <ConnectionIndicator status={connectionStatus} />
        <span>Last update: {formatTime(liveData.timestamp)}</span>
        <Button
          variant="text"
          size="small"
          onClick={reconnect}
          disabled={connectionStatus === 'connected'}
        >
          Reconnect
        </Button>
      </StatusBar>
      
      <LiveMetrics>
        <AnimatedMetric
          title="Active Users"
          value={liveData.activeUsers}
          icon="users"
          animation="pulse"
        />
        
        <AnimatedMetric
          title="Orders/Min"
          value={liveData.ordersPerMinute}
          icon="shopping-cart"
          animation="slide"
        />
        
        <AnimatedMetric
          title="Revenue Today"
          value={liveData.revenueToday}
          format="currency"
          icon="dollar"
          animation="count"
        />
        
        <AnimatedMetric
          title="Server Load"
          value={liveData.serverLoad}
          format="percentage"
          icon="server"
          animation="fade"
          color={getLoadColor(liveData.serverLoad)}
        />
      </LiveMetrics>
      
      <Grid container spacing={3}>
        <Grid item xs={12} md={8}>
          <Card>
            <CardHeader>
              <h3>Live Activity Stream</h3>
              <Badge color="success" pulse>LIVE</Badge>
            </CardHeader>
            <CardContent>
              <ActivityStream
                activities={liveData.activities}
                maxItems={20}
                autoScroll
                renderActivity={(activity) => (
                  <ActivityItem
                    key={activity.id}
                    type={activity.type}
                    user={activity.user}
                    action={activity.action}
                    target={activity.target}
                    timestamp={activity.timestamp}
                    highlight={activity.important}
                  />
                )}
              />
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} md={4}>
          <Card>
            <CardHeader>
              <h3>Live Map</h3>
            </CardHeader>
            <CardContent>
              <LiveMap
                markers={liveData.locations}
                center={mapCenter}
                zoom={2}
                animateMarkers
                heatmap={liveData.heatmapData}
              />
            </CardContent>
          </Card>
          
          <Card>
            <CardHeader>
              <h3>Real-time Stats</h3>
            </CardHeader>
            <CardContent>
              <RealtimeChart
                data={liveData.chartData}
                maxDataPoints={50}
                updateInterval={1000}
                showGrid
                showTooltip
              />
            </CardContent>
          </Card>
        </Grid>
      </Grid>
      
      <AlertsPanel>
        <h3>System Alerts</h3>
        <AlertsList>
          {liveData.alerts?.map(alert => (
            <Alert
              key={alert.id}
              type={alert.severity}
              title={alert.title}
              message={alert.message}
              timestamp={alert.timestamp}
              actions={[
                { label: 'View Details', onClick: () => viewAlert(alert) },
                { label: 'Dismiss', onClick: () => dismissAlert(alert.id) }
              ]}
            />
          ))}
        </AlertsList>
      </AlertsPanel>
    </LiveDashboardLayout>
  );
};
```

### Chat Interface
Real-time chat with typing indicators and presence.

```jsx
// Template: ChatInterface
export const ChatInterfaceTemplate = () => {
  const [message, setMessage] = useState('');
  const [isTyping, setIsTyping] = useState(false);
  const { messages, users, sendMessage } = useChat(channelId);
  const messagesEndRef = useRef(null);
  
  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };
  
  useEffect(scrollToBottom, [messages]);
  
  return (
    <ChatContainer>
      <ChatHeader>
        <ChannelInfo>
          <h3>{channel.name}</h3>
          <span>{users.length} members</span>
        </ChannelInfo>
        
        <HeaderActions>
          <IconButton icon="search" onClick={openSearch} />
          <IconButton icon="info" onClick={toggleInfo} />
          <OnlineUsers users={users} max={5} />
        </HeaderActions>
      </ChatHeader>
      
      <MessageList>
        <VirtualizedList
          items={messages}
          renderItem={(message) => (
            <Message
              key={message.id}
              message={message}
              isOwn={message.userId === currentUser.id}
              showAvatar={shouldShowAvatar(message)}
              onReact={handleReaction}
              onReply={setReplyTo}
              onEdit={message.userId === currentUser.id ? handleEdit : null}
            />
          )}
          groupBy="date"
          renderGroup={(date) => (
            <DateDivider date={date} />
          )}
        />
        
        {typingUsers.length > 0 && (
          <TypingIndicator users={typingUsers} />
        )}
        
        <div ref={messagesEndRef} />
      </MessageList>
      
      <MessageInput>
        {replyTo && (
          <ReplyPreview
            message={replyTo}
            onCancel={() => setReplyTo(null)}
          />
        )}
        
        <InputContainer>
          <IconButton icon="attach" onClick={handleAttachment} />
          
          <TextArea
            value={message}
            onChange={(e) => {
              setMessage(e.target.value);
              handleTyping();
            }}
            onKeyPress={(e) => {
              if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault();
                handleSend();
              }
            }}
            placeholder="Type a message..."
            autoResize
            maxRows={5}
          />
          
          <EmojiPicker
            onSelect={(emoji) => setMessage(prev => prev + emoji)}
          />
          
          <IconButton
            icon="send"
            color="primary"
            onClick={handleSend}
            disabled={!message.trim()}
          />
        </InputContainer>
      </MessageInput>
    </ChatContainer>
  );
};
```

## File Management Patterns

### File Upload Center
Comprehensive file upload with progress and management.

```jsx
// Template: FileUploadCenter
export const FileUploadCenterTemplate = () => {
  const [files, setFiles] = useState([]);
  const [uploading, setUploading] = useState(false);
  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop: handleDrop,
    accept: acceptedFileTypes,
    maxSize: maxFileSize,
    multiple: true
  });
  
  return (
    <FileUploadContainer>
      <DropZone {...getRootProps()} active={isDragActive}>
        <input {...getInputProps()} />
        
        {isDragActive ? (
          <DropMessage>
            <Icon name="upload-cloud" size="large" />
            <h3>Drop files here</h3>
          </DropMessage>
        ) : (
          <UploadPrompt>
            <Icon name="upload" size="large" />
            <h3>Drag & drop files here</h3>
            <p>or click to browse</p>
            <Button variant="secondary">Choose Files</Button>
            <small>
              Accepted formats: {acceptedFormats.join(', ')}
              <br />
              Max file size: {formatFileSize(maxFileSize)}
            </small>
          </UploadPrompt>
        )}
      </DropZone>
      
      {files.length > 0 && (
        <FileList>
          <ListHeader>
            <h3>Files ({files.length})</h3>
            <div>
              <Button
                variant="text"
                onClick={clearAll}
                disabled={uploading}
              >
                Clear All
              </Button>
              <Button
                variant="primary"
                onClick={uploadAll}
                disabled={uploading || !hasValidFiles}
              >
                Upload All
              </Button>
            </div>
          </ListHeader>
          
          <TransitionGroup>
            {files.map(file => (
              <CSSTransition
                key={file.id}
                timeout={300}
                classNames="file"
              >
                <FileItem>
                  <FilePreview file={file} />
                  
                  <FileInfo>
                    <FileName>{file.name}</FileName>
                    <FileMeta>
                      {formatFileSize(file.size)} • {file.type}
                    </FileMeta>
                    
                    {file.status === 'uploading' && (
                      <ProgressBar
                        value={file.progress}
                        showPercentage
                        animated
                      />
                    )}
                    
                    {file.status === 'error' && (
                      <ErrorMessage>{file.error}</ErrorMessage>
                    )}
                    
                    {file.status === 'complete' && (
                      <SuccessMessage>
                        <Icon name="check-circle" color="success" />
                        Uploaded successfully
                      </SuccessMessage>
                    )}
                  </FileInfo>
                  
                  <FileActions>
                    {file.status === 'pending' && (
                      <>
                        <IconButton
                          icon="edit"
                          size="small"
                          onClick={() => editFile(file)}
                        />
                        <IconButton
                          icon="trash"
                          size="small"
                          onClick={() => removeFile(file.id)}
                        />
                      </>
                    )}
                    
                    {file.status === 'uploading' && (
                      <IconButton
                        icon="x"
                        size="small"
                        onClick={() => cancelUpload(file.id)}
                      />
                    )}
                    
                    {file.status === 'complete' && (
                      <IconButton
                        icon="eye"
                        size="small"
                        onClick={() => viewFile(file)}
                      />
                    )}
                  </FileActions>
                </FileItem>
              </CSSTransition>
            ))}
          </TransitionGroup>
        </FileList>
      )}
      
      <UploadStats>
        <Stat>
          <StatLabel>Total Size</StatLabel>
          <StatValue>{formatFileSize(totalSize)}</StatValue>
        </Stat>
        <Stat>
          <StatLabel>Uploaded</StatLabel>
          <StatValue>{uploadedCount} / {files.length}</StatValue>
        </Stat>
        <Stat>
          <StatLabel>Time Remaining</StatLabel>
          <StatValue>{estimatedTime}</StatValue>
        </Stat>
      </UploadStats>
    </FileUploadContainer>
  );
};
```

## E-commerce Patterns

### Product Catalog
Product grid with filtering and quick actions.

```jsx
// Template: ProductCatalog
export const ProductCatalogTemplate = () => {
  const [view, setView] = useState('grid');
  const [filters, setFilters] = useState({});
  const [sortBy, setSortBy] = useState('featured');
  const { products, loading, pagination } = useProducts(filters, sortBy);
  
  return (
    <CatalogLayout>
      <CatalogHeader>
        <Breadcrumb
          items={[
            { label: 'Home', href: '/' },
            { label: 'Products', href: '/products' },
            { label: category.name }
          ]}
        />
        
        <CategoryHero>
          <h1>{category.name}</h1>
          <p>{category.description}</p>
        </CategoryHero>
      </CatalogHeader>
      
      <CatalogToolbar>
        <ResultCount>
          Showing {products.length} of {pagination.total} products
        </ResultCount>
        
        <ToolbarActions>
          <FilterButton
            onClick={toggleFilterPanel}
            badge={activeFilterCount}
          >
            <Icon name="filter" />
            Filters
          </FilterButton>
          
          <SortSelect
            value={sortBy}
            onChange={setSortBy}
            options={[
              { value: 'featured', label: 'Featured' },
              { value: 'newest', label: 'Newest' },
              { value: 'price-low', label: 'Price: Low to High' },
              { value: 'price-high', label: 'Price: High to Low' },
              { value: 'rating', label: 'Top Rated' },
              { value: 'bestselling', label: 'Best Selling' }
            ]}
          />
          
          <ViewToggle
            value={view}
            onChange={setView}
            options={[
              { value: 'grid', icon: 'grid' },
              { value: 'list', icon: 'list' }
            ]}
          />
        </ToolbarActions>
      </CatalogToolbar>
      
      <CatalogContent>
        <FilterPanel open={filterPanelOpen}>
          {/* Filter implementation from earlier */}
        </FilterPanel>
        
        <ProductsSection>
          {loading ? (
            <ProductSkeleton count={12} view={view} />
          ) : products.length === 0 ? (
            <NoProductsFound>
              <Icon name="package" size="large" />
              <h3>No products found</h3>
              <p>Try adjusting your filters</p>
              <Button onClick={clearFilters}>Clear Filters</Button>
            </NoProductsFound>
          ) : (
            <>
              {view === 'grid' ? (
                <ProductGrid>
                  {products.map(product => (
                    <ProductCard
                      key={product.id}
                      product={product}
                      onQuickView={() => openQuickView(product)}
                      onAddToCart={() => addToCart(product)}
                      onToggleWishlist={() => toggleWishlist(product)}
                      showBadges
                      showRating
                    />
                  ))}
                </ProductGrid>
              ) : (
                <ProductList>
                  {products.map(product => (
                    <ProductListItem
                      key={product.id}
                      product={product}
                      onAddToCart={() => addToCart(product)}
                      showDescription
                      showSpecs
                    />
                  ))}
                </ProductList>
              )}
            </>
          )}
          
          <Pagination
            {...pagination}
            onChange={handlePageChange}
            scrollToTop
          />
        </ProductsSection>
      </CatalogContent>
      
      <QuickViewModal
        product={quickViewProduct}
        open={quickViewOpen}
        onClose={closeQuickView}
      />
    </CatalogLayout>
  );
};
```

### Shopping Cart
Full-featured shopping cart with recommendations.

```jsx
// Template: ShoppingCart
export const ShoppingCartTemplate = () => {
  const { items, subtotal, tax, shipping, total, updateQuantity, removeItem } = useCart();
  const { recommendations } = useRecommendations('cart', items);
  
  return (
    <CartLayout>
      <CartHeader>
        <h1>Shopping Cart ({items.length} items)</h1>
        <Button variant="text" onClick={continueShopping}>
          Continue Shopping
        </Button>
      </CartHeader>
      
      {items.length === 0 ? (
        <EmptyCart>
          <Icon name="shopping-cart" size="large" />
          <h2>Your cart is empty</h2>
          <p>Add some products to get started</p>
          <Button variant="primary" onClick={() => navigate('/products')}>
            Browse Products
          </Button>
        </EmptyCart>
      ) : (
        <CartContent>
          <CartItems>
            <CartTable>
              <thead>
                <tr>
                  <th>Product</th>
                  <th>Price</th>
                  <th>Quantity</th>
                  <th>Total</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                {items.map(item => (
                  <CartItem key={item.id}>
                    <ProductCell>
                      <ProductImage src={item.image} alt={item.name} />
                      <ProductInfo>
                        <ProductName>{item.name}</ProductName>
                        <ProductVariants>
                          {item.variants.map(v => (
                            <span key={v.type}>{v.value}</span>
                          ))}
                        </ProductVariants>
                      </ProductInfo>
                    </ProductCell>
                    
                    <PriceCell>
                      {item.salePrice ? (
                        <>
                          <SalePrice>{formatPrice(item.salePrice)}</SalePrice>
                          <OriginalPrice>{formatPrice(item.price)}</OriginalPrice>
                        </>
                      ) : (
                        formatPrice(item.price)
                      )}
                    </PriceCell>
                    
                    <QuantityCell>
                      <QuantitySelector
                        value={item.quantity}
                        onChange={(qty) => updateQuantity(item.id, qty)}
                        min={1}
                        max={item.maxQuantity}
                      />
                    </QuantityCell>
                    
                    <TotalCell>
                      {formatPrice(item.total)}
                    </TotalCell>
                    
                    <ActionCell>
                      <IconButton
                        icon="trash"
                        onClick={() => removeItem(item.id)}
                        tooltip="Remove item"
                      />
                    </ActionCell>
                  </CartItem>
                ))}
              </tbody>
            </CartTable>
            
            <PromoCode>
              <Input
                placeholder="Enter promo code"
                value={promoCode}
                onChange={setPromoCode}
              />
              <Button onClick={applyPromo}>Apply</Button>
            </PromoCode>
          </CartItems>
          
          <CartSummary>
            <SummaryCard>
              <h3>Order Summary</h3>
              
              <SummaryRow>
                <span>Subtotal</span>
                <span>{formatPrice(subtotal)}</span>
              </SummaryRow>
              
              {discount > 0 && (
                <SummaryRow className="discount">
                  <span>Discount</span>
                  <span>-{formatPrice(discount)}</span>
                </SummaryRow>
              )}
              
              <SummaryRow>
                <span>Shipping</span>
                <span>{shipping === 0 ? 'FREE' : formatPrice(shipping)}</span>
              </SummaryRow>
              
              <SummaryRow>
                <span>Tax</span>
                <span>{formatPrice(tax)}</span>
              </SummaryRow>
              
              <Divider />
              
              <SummaryRow className="total">
                <strong>Total</strong>
                <strong>{formatPrice(total)}</strong>
              </SummaryRow>
              
              <CheckoutButton
                variant="primary"
                size="large"
                fullWidth
                onClick={proceedToCheckout}
              >
                Proceed to Checkout
              </CheckoutButton>
              
              <SecurityBadges>
                <Badge icon="lock">Secure Checkout</Badge>
                <Badge icon="shield">Buyer Protection</Badge>
              </SecurityBadges>
            </SummaryCard>
            
            <PaymentMethods>
              <h4>We Accept</h4>
              <PaymentIcons>
                <Icon name="visa" />
                <Icon name="mastercard" />
                <Icon name="amex" />
                <Icon name="paypal" />
              </PaymentIcons>
            </PaymentMethods>
          </CartSummary>
        </CartContent>
      )}
      
      {recommendations.length > 0 && (
        <Recommendations>
          <h2>You Might Also Like</h2>
          <ProductCarousel
            products={recommendations}
            slidesToShow={4}
            responsive
          />
        </Recommendations>
      )}
    </CartLayout>
  );
};
```

## Admin Dashboard Patterns

### Admin Overview
Comprehensive admin dashboard with all key metrics.

```jsx
// Template: AdminDashboard
export const AdminDashboardTemplate = () => {
  const [timeframe, setTimeframe] = useState('today');
  const { stats, activities, notifications } = useAdminData(timeframe);
  
  return (
    <AdminLayout>
      <AdminHeader>
        <h1>Dashboard</h1>
        <HeaderActions>
          <TimeframeSelector
            value={timeframe}
            onChange={setTimeframe}
            options={[
              { value: 'today', label: 'Today' },
              { value: 'week', label: 'This Week' },
              { value: 'month', label: 'This Month' },
              { value: 'year', label: 'This Year' }
            ]}
          />
          
          <NotificationDropdown
            notifications={notifications}
            unreadCount={unreadCount}
          />
          
          <AdminMenu />
        </HeaderActions>
      </AdminHeader>
      
      <QuickStats>
        <StatCard
          title="Total Revenue"
          value={stats.revenue}
          change={stats.revenueChange}
          icon="dollar"
          color="success"
          action={{ label: 'View Report', onClick: viewRevenueReport }}
        />
        
        <StatCard
          title="New Orders"
          value={stats.orders}
          change={stats.ordersChange}
          icon="shopping-cart"
          color="primary"
          action={{ label: 'Manage Orders', onClick: navigateToOrders }}
        />
        
        <StatCard
          title="Active Users"
          value={stats.users}
          change={stats.usersChange}
          icon="users"
          color="info"
          action={{ label: 'User Analytics', onClick: viewUserAnalytics }}
        />
        
        <StatCard
          title="Conversion Rate"
          value={`${stats.conversionRate}%`}
          change={stats.conversionChange}
          icon="trending-up"
          color="warning"
          action={{ label: 'Optimize', onClick: viewConversionFunnel }}
        />
      </QuickStats>
      
      <DashboardGrid>
        <MainContent>
          <RevenueChart data={stats.revenueChart} />
          
          <OrdersTable
            orders={stats.recentOrders}
            onViewOrder={viewOrder}
            onUpdateStatus={updateOrderStatus}
            compact
          />
          
          <ActivityFeed
            activities={activities}
            onViewAll={viewAllActivities}
          />
        </MainContent>
        
        <Sidebar>
          <TodoWidget
            todos={stats.todos}
            onAddTodo={addTodo}
            onToggleTodo={toggleTodo}
          />
          
          <SystemHealth
            metrics={stats.systemHealth}
            onViewDetails={viewSystemDetails}
          />
          
          <QuickActions>
            <QuickActionButton icon="plus" onClick={createProduct}>
              Add Product
            </QuickActionButton>
            <QuickActionButton icon="users" onClick={inviteUser}>
              Invite User
            </QuickActionButton>
            <QuickActionButton icon="tag" onClick={createPromotion}>
              New Promotion
            </QuickActionButton>
            <QuickActionButton icon="mail" onClick={sendNewsletter}>
              Send Newsletter
            </QuickActionButton>
          </QuickActions>
        </Sidebar>
      </DashboardGrid>
    </AdminLayout>
  );
};
```

These patterns provide comprehensive templates for building sophisticated UI interfaces from API specifications. Each pattern is designed to be customizable and can be adapted to specific requirements while maintaining consistency and best practices.