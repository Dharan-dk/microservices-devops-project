"""Tests for Order Service main application."""
import sys
from pathlib import Path

# Add app directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


class TestHealthEndpoints:
    """Test health check endpoints."""

    def test_health_check(self):
        """Test health check endpoint."""
        response = client.get("/health")
        assert response.status_code == 200
        assert response.json()["status"] == "ok"

    def test_readiness_check(self):
        """Test readiness check endpoint."""
        response = client.get("/ready")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "ready"
        assert "version" in data


class TestOrderCreation:
    """Test order creation endpoint."""

    def test_create_order(self):
        """Test creating a new order."""
        order_data = {
            "user_id": 1,
            "items": [
                {"product_id": 101, "quantity": 2, "price": 29.99},
                {"product_id": 102, "quantity": 1, "price": 49.99},
            ],
            "shipping_address": "123 Main St, City, State 12345",
        }
        response = client.post("/orders/", json=order_data)
        assert response.status_code == 201
        data = response.json()
        assert "id" in data
        assert data["user_id"] == 1
        assert data["status"] == "pending"
        assert data["total_amount"] == 109.97

    def test_create_order_invalid_data(self):
        """Test creating order with invalid data."""
        order_data = {
            "user_id": 1,
            "items": [],
            "shipping_address": "short",  # Too short
        }
        response = client.post("/orders/", json=order_data)
        assert response.status_code == 422


class TestOrderRetrieval:
    """Test order retrieval endpoints."""

    def test_get_order(self):
        """Test retrieving an order."""
        # Create an order first
        order_data = {
            "user_id": 2,
            "items": [{"product_id": 103, "quantity": 1, "price": 99.99}],
            "shipping_address": "456 Oak Ave, Town, State 54321",
        }
        create_response = client.post("/orders/", json=order_data)
        order_id = create_response.json()["id"]

        # Retrieve the order
        response = client.get(f"/orders/{order_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == order_id
        assert data["user_id"] == 2

    def test_get_order_not_found(self):
        """Test retrieving non-existent order."""
        response = client.get("/orders/99999")
        assert response.status_code == 404


class TestOrderUpdate:
    """Test order update endpoints."""

    def test_update_order_status(self):
        """Test updating order status."""
        # Create an order
        order_data = {
            "user_id": 3,
            "items": [{"product_id": 104, "quantity": 3, "price": 15.99}],
            "shipping_address": "789 Pine Rd, Village, State 98765",
        }
        create_response = client.post("/orders/", json=order_data)
        order_id = create_response.json()["id"]

        # Update status with enum string
        response = client.patch(f"/orders/{order_id}/status?status_update=confirmed")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "confirmed"


class TestOrderDeletion:
    """Test order deletion endpoint."""

    def test_delete_order(self):
        """Test deleting an order."""
        # Create an order
        order_data = {
            "user_id": 4,
            "items": [{"product_id": 105, "quantity": 1, "price": 199.99}],
            "shipping_address": "321 Elm St, City Center, State 11111",
        }
        create_response = client.post("/orders/", json=order_data)
        order_id = create_response.json()["id"]

        # Delete the order
        response = client.delete(f"/orders/{order_id}")
        assert response.status_code == 204

        # Verify it's deleted
        get_response = client.get(f"/orders/{order_id}")
        assert get_response.status_code == 404