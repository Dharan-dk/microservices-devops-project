#!/bin/bash
# Local test runner with coverage for development

set -e

echo "========================================="
echo "Running Tests with Coverage Reports"
echo "========================================="

# Test order-service
echo ""
echo ">>> Testing order-service..."
cd order-service
python -m pytest tests/ \
    --cov=app \
    --cov-report=xml \
    --cov-report=html \
    --cov-report=term-missing \
    -v
cd ..

# Test user-service
echo ""
echo ">>> Testing user-service..."
cd user-service
python -m pytest tests/ \
    --cov=app \
    --cov-report=xml \
    --cov-report=html \
    --cov-report=term-missing \
    -v
cd ..

echo ""
echo "========================================="
echo "✓ All tests passed!"
echo "Coverage reports generated in htmlcov/"
echo "========================================="
