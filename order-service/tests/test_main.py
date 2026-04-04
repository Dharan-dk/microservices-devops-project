"""Tests for Order Service main application."""
import sys
from pathlib import Path

# Add app directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.routes.order import calculate_order_total

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
        assert data["version"] == "1.0.0"


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
        assert len(data["items"]) == 2
        assert data["items"][0]["total_price"] == 59.98

    def test_create_order_single_item(self):
        """Test creating order with single item."""
        order_data = {
            "user_id": 2,
            "items": [{"product_id": 201, "quantity": 5, "price": 10.00}],
            "shipping_address": "456 Oak Ave, Town, State 54321",
        }
        response = client.post("/orders/", json=order_data)
        assert response.status_code == 201
        data = response.json()
        assert data["total_amount"] == 50.00

    def test_create_order_decimal_prices(self):
        """Test creating order with decimal prices."""
        order_data = {
            "user_id": 3,
            "items": [
                {"product_id": 301, "quantity": 3, "price": 12.50},
                {"product_id": 302, "quantity": 2, "price": 25.75},
            ],
            "shipping_address": "789 Pine Rd, Village, State 98765",
        }
        response = client.post("/orders/", json=order_data)
        assert response.status_code == 201
        data = response.json()
        assert data["total_amount"] == 89.00

    def test_create_order_invalid_data_minimal_address(self):
        """Test creating order with very short address."""
        order_data = {
            "user_id": 1,
            "items": [{"product_id": 101, "quantity": 1, "price": 29.99}],
            "shipping_address": "short",  # Too short (< 10 chars)
        }
        response = client.post("/orders/", json=order_data)
        assert response.status_code == 422

    def test_create_order_invalid_quantity(self):
        """Test creating order with invalid quantity."""
        order_data = {
            "user_id": 1,
            "items": [
                {"product_id": 101, "quantity": 0, "price": 29.99},
            ],
            "shipping_address": "123 Main St, City, State 12345",
        }
        response = client.post("/orders/", json=order_data)
        assert response.status_code == 422

    def test_create_order_invalid_price(self):
        """Test creating order with invalid price."""
        order_data = {
            "user_id": 1,
            "items": [
                {"product_id": 101, "quantity": 1, "price": -10.00},
            ],
            "shipping_address": "123 Main St, City, State 12345",
        }
        response = client.post("/orders/", json=order_data)
        assert response.status_code == 422


class TestOrderRetrieval:
    """Test order retrieval endpoints."""

    def test_get_order(self):
        """Test retrieving an order."""
        # Create an order first
        order_data = {
            "user_id": 10,
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
        assert data["user_id"] == 10
        assert data["total_amount"] == 99.99

    def test_get_order_not_found(self):
        """Test retrieving non-existent order."""
        response = client.get("/orders/999999")
        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()

    def test_list_all_orders(self):
        """Test listing all orders."""
        # Create multiple orders
        for i in range(3):
            order_data = {
                "user_id": 20 + i,
                "items": [{"product_id": 100 + i, "quantity": 1, "price": 50.00}],
                "shipping_address": f"{i} Test St, City, State 12345",
            }
            client.post("/orders/", json=order_data)

        # List all orders
        response = client.get("/orders/")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) >= 3

    def test_list_orders_by_user_id(self):
        """Test filtering orders by user_id."""
        user_id = 30
        # Create 2 orders for the same user
        for i in range(2):
            order_data = {
                "user_id": user_id,
                "items": [{"product_id": 300 + i, "quantity": 1, "price": 50.00}],
                "shipping_address": f"{i} Test St, City, State 12345",
            }
            client.post("/orders/", json=order_data)

        # Create an order for a different user
        other_order_data = {
            "user_id": 999,
            "items": [{"product_id": 400, "quantity": 1, "price": 50.00}],
            "shipping_address": "Other St, City, State 12345",
        }
        client.post("/orders/", json=other_order_data)

        # List orders for specific user
        response = client.get(f"/orders/?user_id={user_id}")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) == 2
        for order in data:
            assert order["user_id"] == user_id


class TestOrderUpdate:
    """Test order update endpoints."""

    def test_update_order_status_to_confirmed(self):
        """Test updating order status to confirmed."""
        # Create an order
        order_data = {
            "user_id": 40,
            "items": [{"product_id": 104, "quantity": 3, "price": 15.99}],
            "shipping_address": "789 Pine Rd, Village, State 98765",
        }
        create_response = client.post("/orders/", json=order_data)
        order_id = create_response.json()["id"]

        # Update status with query parameter
        response = client.patch(
            f"/orders/{order_id}/status?status_update=confirmed"
        )
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "confirmed"

    def test_update_order_status_to_shipped(self):
        """Test updating order status to shipped."""
        # Create an order
        order_data = {
            "user_id": 41,
            "items": [{"product_id": 105, "quantity": 1, "price": 99.00}],
            "shipping_address": "Shipping Ave, City, State 12345",
        }
        create_response = client.post("/orders/", json=order_data)
        order_id = create_response.json()["id"]

        # Update status to shipped with query parameter
        response = client.patch(
            f"/orders/{order_id}/status?status_update=shipped"
        )
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "shipped"

    def test_update_order_status_to_delivered(self):
        """Test updating order status to delivered."""
        # Create an order
        order_data = {
            "user_id": 42,
            "items": [{"product_id": 106, "quantity": 1, "price": 75.00}],
            "shipping_address": "Delivery Rd, Town, State 54321",
        }
        create_response = client.post("/orders/", json=order_data)
        order_id = create_response.json()["id"]

        # Update status to delivered with query parameter
        response = client.patch(
            f"/orders/{order_id}/status?status_update=delivered"
        )
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "delivered"

    def test_update_order_status_to_cancelled(self):
        """Test updating order status to cancelled."""
        # Create an order
        order_data = {
            "user_id": 43,
            "items": [{"product_id": 107, "quantity": 1, "price": 150.00}],
            "shipping_address": "Cancel St, Village, State 98765",
        }
        create_response = client.post("/orders/", json=order_data)
        order_id = create_response.json()["id"]

        # Update status to cancelled with query parameter
        response = client.patch(
            f"/orders/{order_id}/status?status_update=cancelled"
        )
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "cancelled"

    def test_update_nonexistent_order_status(self):
        """Test updating status of non-existent order."""
        response = client.patch(
            "/orders/999999/status?status_update=confirmed"
        )
        assert response.status_code == 404


class TestOrderDeletion:
    """Test order deletion endpoint."""

    def test_delete_order(self):
        """Test deleting an order."""
        # Create an order
        order_data = {
            "user_id": 50,
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

    def test_delete_nonexistent_order(self):
        """Test deleting non-existent order."""
        response = client.delete("/orders/999999")
        assert response.status_code == 404

    def test_delete_multiple_orders(self):
        """Test deleting multiple orders."""
        order_ids = []
        for i in range(3):
            order_data = {
                "user_id": 60 + i,
                "items": [{"product_id": 600 + i, "quantity": 1, "price": 50.00}],
                "shipping_address": f"{i} Delete St, City, State 12345",
            }
            create_response = client.post("/orders/", json=order_data)
            order_ids.append(create_response.json()["id"])

        # Delete all orders
        for order_id in order_ids:
            response = client.delete(f"/orders/{order_id}")
            assert response.status_code == 204

        # Verify all are deleted
        for order_id in order_ids:
            get_response = client.get(f"/orders/{order_id}")
            assert get_response.status_code == 404


class TestOrderUtilities:
    """Test utility functions for orders."""

    def test_calculate_order_total_single_item(self):
        """Test calculating total with single item."""
        items = [{"total_price": 29.99}]
        total = calculate_order_total(items)
        assert total == 29.99

    def test_calculate_order_total_multiple_items(self):
        """Test calculating total with multiple items."""
        items = [
            {"total_price": 29.99},
            {"total_price": 49.99},
        ]
        total = calculate_order_total(items)
        assert total == 79.98

    def test_calculate_order_total_decimal_prices(self):
        """Test calculating total with decimal prices."""
        items = [
            {"total_price": 12.50},
            {"total_price": 37.50},
        ]
        total = calculate_order_total(items)
        assert total == 50.00