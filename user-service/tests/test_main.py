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
        assert data["status"] == "ok"

    def test_readiness_check(self):
        """Test readiness check endpoint."""
        response = client.get("/ready")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "ready"
        assert "version" in data
        assert data["version"] == "1.0.0"


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

    def test_create_user_with_special_characters_in_name(self):
        """Test creating user with special characters in name."""
        user_data = {"name": "José García-López", "email": "jose@example.com"}
        response = client.post("/users/", json=user_data)
        assert response.status_code == 201
        data = response.json()
        assert data["name"] == "José García-López"

    def test_create_user_long_name(self):
        """Test creating user with long name."""
        user_data = {"name": "A" * 255, "email": "longname@example.com"}
        response = client.post("/users/", json=user_data)
        assert response.status_code == 201
        data = response.json()
        assert len(data["name"]) == 255

    def test_create_user_name_too_long(self):
        """Test creating user with name exceeding limit."""
        user_data = {"name": "A" * 256, "email": "toolongname@example.com"}
        response = client.post("/users/", json=user_data)
        assert response.status_code == 422

    def test_create_user_empty_name(self):
        """Test creating user with empty name."""
        user_data = {"name": "", "email": "empty@example.com"}
        response = client.post("/users/", json=user_data)
        assert response.status_code == 422

    def test_create_user_duplicate_email(self):
        """Test creating user with duplicate email (no unique constraint)."""
        user_data = {"name": "Jane Doe", "email": "jane@example.com"}
        # First user creation
        response1 = client.post("/users/", json=user_data)
        assert response1.status_code == 201
        # Second user with same email should succeed (no unique constraint in demo)
        response2 = client.post("/users/", json=user_data)
        assert response2.status_code == 201
        assert response1.json()["id"] != response2.json()["id"]

    def test_create_user_invalid_email(self):
        """Test creating user with invalid email."""
        user_data = {"name": "Invalid User", "email": "invalid-email"}
        response = client.post("/users/", json=user_data)
        assert response.status_code == 422

    def test_create_user_invalid_email_no_at(self):
        """Test creating user with email missing @."""
        user_data = {"name": "No At User", "email": "noemat.example.com"}
        response = client.post("/users/", json=user_data)
        assert response.status_code == 422

    def test_create_user_invalid_email_no_domain(self):
        """Test creating user with email missing domain."""
        user_data = {"name": "No Domain User", "email": "user@"}
        response = client.post("/users/", json=user_data)
        assert response.status_code == 422

    def test_create_user_missing_fields(self):
        """Test creating user with missing fields."""
        user_data = {"name": "Incomplete User"}
        response = client.post("/users/", json=user_data)
        assert response.status_code == 422

    def test_create_user_missing_name(self):
        """Test creating user with missing name."""
        user_data = {"email": "noname@example.com"}
        response = client.post("/users/", json=user_data)
        assert response.status_code == 422

    def test_create_user_empty_dict(self):
        """Test creating user with empty dict."""
        response = client.post("/users/", json={})
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
        response = client.get("/users/999999")
        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()

    def test_list_users_empty(self):
        """Test listing users when empty."""
        response = client.get("/users/")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)

    def test_list_users_multiple(self):
        """Test listing multiple users."""
        # Create multiple users
        user_ids = []
        for i in range(5):
            user_data = {"name": f"User {i}", "email": f"user{i}@example.com"}
            create_response = client.post("/users/", json=user_data)
            user_ids.append(create_response.json()["id"])

        # List users
        response = client.get("/users/")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) >= 5
        # Check all created users are in list
        listed_ids = [u["id"] for u in data]
        for uid in user_ids:
            assert uid in listed_ids


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
        assert data["id"] == user_id
        assert data["name"] == "Bob Smith Updated"
        assert data["email"] == "bob_updated@example.com"

    def test_update_user_name_only(self):
        """Test updating only user name."""
        # Create a user first
        user_data = {"name": "Carol King", "email": "carol@example.com"}
        create_response = client.post("/users/", json=user_data)
        user_id = create_response.json()["id"]

        # Update only name
        update_data = {"name": "Carol King Updated", "email": "carol@example.com"}
        response = client.put(f"/users/{user_id}", json=update_data)
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Carol King Updated"

    def test_update_user_email_only(self):
        """Test updating only user email."""
        # Create a user first
        user_data = {"name": "David Brown", "email": "david@example.com"}
        create_response = client.post("/users/", json=user_data)
        user_id = create_response.json()["id"]

        # Update only email
        update_data = {"name": "David Brown", "email": "david_new@example.com"}
        response = client.put(f"/users/{user_id}", json=update_data)
        assert response.status_code == 200
        data = response.json()
        assert data["email"] == "david_new@example.com"

    def test_update_user_not_found(self):
        """Test updating non-existent user."""
        update_data = {"name": "Non Existent", "email": "nonexistent@example.com"}
        response = client.put("/users/999999", json=update_data)
        assert response.status_code == 404

    def test_update_user_invalid_email(self):
        """Test updating user with invalid email."""
        # Create a user first
        user_data = {"name": "Eve Green", "email": "eve@example.com"}
        create_response = client.post("/users/", json=user_data)
        user_id = create_response.json()["id"]

        # Try to update with invalid email
        update_data = {"name": "Eve Green", "email": "invalid-email"}
        response = client.put(f"/users/{user_id}", json=update_data)
        assert response.status_code == 422

    def test_update_user_invalid_name(self):
        """Test updating user with invalid name (too long)."""
        # Create a user first
        user_data = {"name": "Frank Lee", "email": "frank@example.com"}
        create_response = client.post("/users/", json=user_data)
        user_id = create_response.json()["id"]

        # Try to update with name too long
        update_data = {"name": "A" * 256, "email": "frank@example.com"}
        response = client.put(f"/users/{user_id}", json=update_data)
        assert response.status_code == 422


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
        response = client.delete("/users/999999")
        assert response.status_code == 404

    def test_delete_multiple_users(self):
        """Test deleting multiple users."""
        user_ids = []
        for i in range(3):
            user_data = {"name": f"Delete User {i}", "email": f"delete{i}@example.com"}
            create_response = client.post("/users/", json=user_data)
            user_ids.append(create_response.json()["id"])

        # Delete all users
        for user_id in user_ids:
            response = client.delete(f"/users/{user_id}")
            assert response.status_code == 204

        # Verify all are deleted
        for user_id in user_ids:
            get_response = client.get(f"/users/{user_id}")
            assert get_response.status_code == 404


class TestUserIntegration:
    """Integration tests for user operations."""

    def test_create_retrieve_update_delete_flow(self):
        """Test complete CRUD flow."""
        # Create
        user_data = {"name": "Flow User", "email": "flow@example.com"}
        create_response = client.post("/users/", json=user_data)
        assert create_response.status_code == 201
        user_id = create_response.json()["id"]

        # Retrieve
        get_response = client.get(f"/users/{user_id}")
        assert get_response.status_code == 200
        assert get_response.json()["name"] == "Flow User"

        # Update
        update_data = {"name": "Flow User Updated", "email": "flow_updated@example.com"}
        update_response = client.put(f"/users/{user_id}", json=update_data)
        assert update_response.status_code == 200
        assert update_response.json()["name"] == "Flow User Updated"

        # Delete
        delete_response = client.delete(f"/users/{user_id}")
        assert delete_response.status_code == 204

        # Verify deletion
        final_get_response = client.get(f"/users/{user_id}")
        assert final_get_response.status_code == 404

    def test_list_shows_updates(self):
        """Test that list reflects updates."""
        # Create a user
        user_data = {"name": "Original Name", "email": "original@example.com"}
        create_response = client.post("/users/", json=user_data)
        user_id = create_response.json()["id"]

        # Get initial list
        list_response1 = client.get("/users/")
        initial_count = len(list_response1.json())

        # Update user
        update_data = {"name": "Updated Name", "email": "original@example.com"}
        client.put(f"/users/{user_id}", json=update_data)

        # Get list again - should have same count but updated data
        list_response2 = client.get("/users/")
        assert len(list_response2.json()) == initial_count

        # Find updated user in list
        users = list_response2.json()
        updated_user = next((u for u in users if u["id"] == user_id), None)
        assert updated_user is not None
        assert updated_user["name"] == "Updated Name"