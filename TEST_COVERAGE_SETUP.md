# Pytest & Coverage Configuration for SonarQube

## Summary of Changes

This setup adds comprehensive pytest and coverage integration to your CI/CD pipeline, enabling SonarQube to analyze code coverage metrics and test results.

## Files Updated/Created

### 1. **Dependencies**
- **`order-service/requirements.txt`** - Added:
  - `pytest==7.3.1` - Testing framework
  - `pytest-cov==4.0.0` - Coverage plugin for pytest
  - `coverage==7.2.7` - Coverage measurement tool

- **`user-service/requirements.txt`** - Already had these dependencies

### 2. **Test Files - Enhanced**
- **`order-service/tests/test_main.py`** - Comprehensive test suite with:
  - Health endpoints tests
  - Order creation tests
  - Order retrieval tests
  - Order update tests
  - Order deletion tests
  - Error handling (404, validation errors)

- **`user-service/tests/test_main.py`** - Comprehensive test suite with:
  - Health endpoints tests
  - User creation tests
  - User retrieval tests
  - User update tests
  - User deletion tests
  - Error handling (404, validation errors)
  - Email validation tests

### 3. **Configuration Files - New**
- **`pytest.ini`** - Pytest configuration with:
  - Test discovery patterns
  - Module path settings
  - Custom markers (unit, integration, health, slow)
  - Output options

- **`.coveragerc`** - Coverage.py configuration with:
  - Branch coverage enabled
  - Parallel test support
  - XML report generation for SonarQube
  - HTML report generation for local inspection
  - Optimized exclusion patterns

- **`sonar-project.properties`** - SonarQube settings with:
  - Python version specification (3.11)
  - Coverage report paths
  - Source/test exclusions
  - Language settings

### 4. **Pipeline - Updated**
- **`Jenkinsfile`** - Enhanced with:
  - **New Stage**: "User Service - Tests & Coverage" (before SonarQube)
  - **New Stage**: "Order Service - Tests & Coverage" (before SonarQube)
  - Updated SonarQube stages to include:
    - `-Dsonar.sources=service/app` - Specifies source directory
    - `-Dsonar.tests=service/tests` - Specifies test directory
    - `-Dsonar.python.coverage.reportPaths=service/coverage.xml` - Points to coverage report
  - Fixed syntax error in original Jenkinsfile (missing backslash)

### 5. **Helper Script - New**
- **`run_tests.sh`** - Local testing script for development:
  - Runs both services' tests sequentially
  - Generates coverage reports (XML, HTML, terminal)
  - Easy local verification before committing

## Running Tests

### Locally (for development):
```bash
# Make script executable
chmod +x run_tests.sh

# Run all tests with coverage
./run_tests.sh

# Or run individual service tests
cd order-service
python -m pytest tests/ --cov=app --cov-report=html
cd ../user-service
python -m pytest tests/ --cov=app --cov-report=html
```

### In Jenkins CI/CD Pipeline:
The pipeline automatically:
1. Checks out code
2. Runs tests with coverage for each service
3. Generates XML coverage reports (for SonarQube)
4. Runs SonarQube analysis with coverage data
5. Waits for quality gate approval before proceeding

## Coverage Reports

After running tests, coverage reports are generated:

- **Terminal Output**: Shows coverage percentage summary
- **HTML Report**: `htmlcov/index.html` - Interactive HTML visualization
- **XML Report**: `coverage.xml` - Machine-readable format used by SonarQube

## SonarQube Integration

The coverage data flows to SonarQube via:
1. Tests generate `coverage.xml` during pytest execution
2. SonarQube Scanner picks up coverage reports via `-Dsonar.python.coverage.reportPaths`
3. SonarQube displays code coverage metrics in dashboard
4. Quality gates can be set based on coverage thresholds

## Test Structure

Tests are organized into classes for better organization:

**Order Service Tests:**
- `TestHealthEndpoints` - Health check functionality
- `TestOrderCreation` - POST /orders/ endpoint
- `TestOrderRetrieval` - GET /orders/{id} endpoint
- `TestOrderUpdate` - PUT /orders/{id} endpoint
- `TestOrderDeletion` - DELETE /orders/{id} endpoint

**User Service Tests:**
- `TestHealthEndpoints` - Health check functionality
- `TestUserCreation` - POST /users/ endpoint
- `TestUserRetrieval` - GET /users/{id} and GET /users/ endpoints
- `TestUserUpdate` - PUT /users/{id} endpoint
- `TestUserDeletion` - DELETE /users/{id} endpoint

## Next Steps

1. **Install dependencies locally**:
   ```bash
   cd order-service && pip install -r requirements.txt
   cd ../user-service && pip install -r requirements.txt
   ```

2. **Run tests locally to verify**:
   ```bash
   ./run_tests.sh
   ```

3. **View coverage reports**:
   Open `htmlcov/index.html` in a browser

4. **Commit and push** - Pipeline will run automatically

5. **Monitor SonarQube dashboard** for coverage metrics
