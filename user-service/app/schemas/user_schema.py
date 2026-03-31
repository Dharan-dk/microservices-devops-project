"""User data schemas for request/response validation."""
from pydantic import BaseModel, EmailStr, Field


class UserCreate(BaseModel):
    """Schema for creating a new user."""

    name: str = Field(..., min_length=1, max_length=255, description="User's full name")
    email: EmailStr = Field(..., description="User's email address")

    class Config:
        """Pydantic config."""

        json_schema_extra = {
            "example": {"name": "John Doe", "email": "john@example.com"}
        }


class UserResponse(BaseModel):
    """Schema for user response data."""

    id: int = Field(..., description="User ID")
    name: str = Field(..., description="User's full name")
    email: EmailStr = Field(..., description="User's email address")

    class Config:
        """Pydantic config."""

        json_schema_extra = {
            "example": {"id": 1, "name": "John Doe", "email": "john@example.com"}
        }