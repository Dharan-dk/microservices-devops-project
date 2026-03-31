"""Order data schemas for request/response validation."""
from pydantic import BaseModel, Field
from typing import List
from enum import Enum


class OrderStatus(str, Enum):
    """Order status enumeration."""

    PENDING = "pending"
    CONFIRMED = "confirmed"
    SHIPPED = "shipped"
    DELIVERED = "delivered"
    CANCELLED = "cancelled"


class OrderItemCreate(BaseModel):
    """Schema for order items during creation."""

    product_id: int = Field(..., description="Product ID")
    quantity: int = Field(..., gt=0, description="Quantity of product")
    price: float = Field(..., gt=0, description="Price per unit")

    class Config:
        """Pydantic config."""

        json_schema_extra = {
            "example": {"product_id": 101, "quantity": 2, "price": 29.99}
        }


class OrderItem(OrderItemCreate):
    """Schema for order items in response."""

    total_price: float = Field(..., description="Total price for this item")

    class Config:
        """Pydantic config."""

        json_schema_extra = {
            "example": {
                "product_id": 101,
                "quantity": 2,
                "price": 29.99,
                "total_price": 59.98,
            }
        }


class OrderCreate(BaseModel):
    """Schema for creating a new order."""

    user_id: int = Field(..., description="ID of the user ordering")
    items: List[OrderItemCreate] = Field(..., description="List of items in order")
    shipping_address: str = Field(
        ..., min_length=10, max_length=500, description="Shipping address"
    )

    class Config:
        """Pydantic config."""

        json_schema_extra = {
            "example": {
                "user_id": 1,
                "items": [{"product_id": 101, "quantity": 2, "price": 29.99}],
                "shipping_address": "123 Main St, City, State 12345",
            }
        }


class OrderResponse(BaseModel):
    """Schema for order response data."""

    id: int = Field(..., description="Order ID")
    user_id: int = Field(..., description="User ID")
    items: List[OrderItem] = Field(..., description="Items in order")
    status: OrderStatus = Field(..., description="Current order status")
    total_amount: float = Field(..., description="Total order amount")
    shipping_address: str = Field(..., description="Shipping address")
    created_at: str = Field(..., description="Order creation timestamp")

    class Config:
        """Pydantic config."""

        json_schema_extra = {
            "example": {
                "id": 1,
                "user_id": 1,
                "items": [
                    {
                        "product_id": 101,
                        "quantity": 2,
                        "price": 29.99,
                        "total_price": 59.98,
                    }
                ],
                "status": "pending",
                "total_amount": 59.98,
                "shipping_address": "123 Main St, City, State 12345",
                "created_at": "2024-01-15T10:30:00",
            }
        }
