"""Order routes for CRUD operations."""
from fastapi import APIRouter, HTTPException, status
from app.schemas.order_schema import OrderCreate, OrderResponse, OrderStatus
from app.utils.logger import logger
from datetime import datetime

router = APIRouter()

# In-memory storage for orders (demonstration only)
order_db: dict[int, dict] = {}
order_counter = 0


def calculate_order_total(items: list[dict]) -> float:
    """Calculate total order amount from items."""
    return sum(item["total_price"] for item in items)


@router.post("/", response_model=OrderResponse, status_code=status.HTTP_201_CREATED)
def create_order(order: OrderCreate) -> OrderResponse:
    """Create a new order and return it with assigned ID."""
    global order_counter
    order_counter += 1

    # Process items
    processed_items = []
    for item in order.items:
        processed_item = {
            "product_id": item.product_id,
            "quantity": item.quantity,
            "price": item.price,
            "total_price": item.quantity * item.price,
        }
        processed_items.append(processed_item)

    # Create order
    total_amount = calculate_order_total(processed_items)
    new_order = {
        "id": order_counter,
        "user_id": order.user_id,
        "items": processed_items,
        "status": OrderStatus.PENDING,
        "total_amount": total_amount,
        "shipping_address": order.shipping_address,
        "created_at": datetime.utcnow().isoformat(),
    }
    order_db[order_counter] = new_order
    logger.info(f"Order created: id={order_counter}, user_id={order.user_id}, total=${total_amount}")
    return new_order


@router.get("/{order_id}", response_model=OrderResponse)
def get_order(order_id: int) -> OrderResponse:
    """Retrieve an order by ID."""
    if order_id not in order_db:
        logger.warning(f"Order not found: id={order_id}")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Order with id {order_id} not found",
        )
    logger.info(f"Order retrieved: id={order_id}")
    return order_db[order_id]


@router.get("/", response_model=list[OrderResponse])
def list_orders(user_id: int | None = None) -> list[OrderResponse]:
    """List orders, optionally filtered by user_id."""
    if user_id is not None:
        orders = [o for o in order_db.values() if o["user_id"] == user_id]
        logger.info(f"Listed {len(orders)} orders for user {user_id}")
        return orders
    logger.info(f"Listed all orders (total: {len(order_db)})")
    return list(order_db.values())


@router.patch("/{order_id}/status", response_model=OrderResponse)
def update_order_status(order_id: int, status: OrderStatus) -> OrderResponse:
    """Update order status."""
    if order_id not in order_db:
        logger.warning(f"Order not found: id={order_id}")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Order with id {order_id} not found",
        )
    
    order_db[order_id]["status"] = status
    logger.info(f"Order status updated: id={order_id}, status={status}")
    return order_db[order_id]


@router.delete("/{order_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_order(order_id: int) -> None:
    """Delete an order."""
    if order_id not in order_db:
        logger.warning(f"Order not found for deletion: id={order_id}")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Order with id {order_id} not found",
        )
    del order_db[order_id]
    logger.info(f"Order deleted: id={order_id}")
