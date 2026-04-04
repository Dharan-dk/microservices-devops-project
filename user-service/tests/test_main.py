"""Tests for User Service main application."""
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
        data = response.json()
        assert "status" in data

    def test_readiness_check(self):
        """Test readiness check endpoint."""
        response = client.get("/ready")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "ready"
        assert "version" in data


class TestUserCreation:
    """Test user creation endpoint."""

    def test_create_user(self):
        """Test creating a new user."""
        user_data = {"name": "John Doe", "email": "john@example.com"}
        response = client.post("/users/", json=user_data)
        assert response.status_code == 201
        data = response.json()
        assert "id" in data
        assert data["name"] == "John Doe"
        assert data["email"] == "john@example.com"

    def test_create_user_duplicate_email(self):
        """Test creating user with duplicate email."""
        user_data = {"name": "Jane Doe", "email": "jane@example.com"}
        # First user creation
        client.post("/users/", json=user_data)
        # Second user with same email should succeed (no unique constraint in demo)
        response = client.post("/users/", json=user_data)
        assert response.status_code == 201

    def test_create_user_invalid_email(self):
        """Test creating user with invalid email."""
        user_data = {"name": "Invalid User", "email": "invalid-email"}
        response = client.post("/users/", json=user_data)
        assert response.status_code == 422

    def test_create_user_missing_fields(self):
        """Test creating user with missing fields."""
        user_data = {"name": "Incomplete User"}
        response = client.post("/users/", json=user_data)
        assert response.status_code == 422


class TestUserRetrieval:
    """Test user retrieval endpoints."""

    def test_get_user(self):
        """Test retrieving a user."""
        # Create a user first
        user_data = {"name": "Alice Johnson", "email": "alice@example.com"}
        create_response = client.post("/users/", json=user_data)
        user_id = create_response.json()["id"]

        # Retrieve the user
        response = client.get(f"/users/{user_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == user_id
        assert data["name"] == "Alice Johnson"
        assert data["email"] == "alice@example.com"

    def test_get_user_not_found(self):
        """Test retrieving non-existent user."""
        response = client.get("/users/99999")
        assert response.status_code == 404

    def test_list_users(self):
        """Test listing all users."""
        # Create a couple of users
        client.post("/users/", json={"name": "User 1", "email": "user1@example.com"})
        client.post("/users/", json={"name": "User 2", "email": "user2@example.com"})

        # List users
        response = client.get("/users/")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) >= 2


class TestUserUpdate:
    """Test user update endpoints."""

    def test_update_user(self):
        """Test updating a user."""
        # Create a user first
        user_data = {"name": "Bob Smith", "email": "bob@example.com"}
        create_response = client.post("/users/", json=user_data)
        user_id = create_response.json()["id"]

        # Update the user
        update_data = {"name": "Bob Smith Updated", "email": "bob_updated@example.com"}
        response = client.put(f"/users/{user_id}", json=update_data)
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Bob Smith Updated"
        assert data["email"] == "bob_updated@example.com"

    def test_update_user_not_found(self):
        """Test updating non-existent user."""
        update_data = {"name": "Non Existent", "email": "nonexistent@example.com"}
        response = client.put("/users/99999", json=update_data)
        assert response.status_code == 404


class TestUserDeletion:
    """Test user deletion endpoint."""

    def test_delete_user(self):
        """Test deleting a user."""
        # Create a user first
        user_data = {"name": "Charlie Brown", "email": "charlie@example.com"}
        create_response = client.post("/users/", json=user_data)
        user_id = create_response.json()["id"]

        # Delete the user
        response = client.delete(f"/users/{user_id}")
        assert response.status_code == 204

        # Verify it's deleted
        get_response = client.get(f"/users/{user_id}")
        assert get_response.status_code == 404

    def test_delete_user_not_found(self):
        """Test deleting non-existent user."""
        response = client.delete("/users/99999")
        assert response.status_code == 404