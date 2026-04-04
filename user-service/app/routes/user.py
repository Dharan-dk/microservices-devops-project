"""User routes for CRUD operations."""
from fastapi import APIRouter, HTTPException, status
from app.schemas.user_schema import UserCreate, UserResponse
from app.utils.logger import logger

router = APIRouter()

# In-memory storage for users (demonstration only)
user_db: dict[int, dict] = {}
user_counter = 0


@router.post("/", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def create_user(user: UserCreate) -> UserResponse:
    """Create a new user and return it with assigned ID."""
    global user_counter
    user_counter += 1
    new_user = {"id": user_counter, **user.model_dump()}
    user_db[user_counter] = new_user
    logger.info(f"User created: id={user_counter}, email={user.email}")
    return new_user


@router.get("/{user_id}", response_model=UserResponse)
def get_user(user_id: int) -> UserResponse:
    """Retrieve a user by ID."""
    if user_id not in user_db:
        logger.warning(f"User not found: id={user_id}")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User with id {user_id} not found",
        )
    logger.info(f"User retrieved: id={user_id}")
    return user_db[user_id]


@router.get("/", response_model=list[UserResponse])
def list_users() -> list[UserResponse]:
    """List all users."""
    logger.info(f"Listing all users (total: {len(user_db)})")
    return list(user_db.values())


@router.put("/{user_id}", response_model=UserResponse)
def update_user(user_id: int, user: UserCreate) -> UserResponse:
    """Update a user by ID."""
    if user_id not in user_db:
        logger.warning(f"User not found: id={user_id}")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User with id {user_id} not found",
        )
    updated_user = {"id": user_id, **user.model_dump()}
    user_db[user_id] = updated_user
    logger.info(f"User updated: id={user_id}, email={user.email}")
    return updated_user


@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_user(user_id: int) -> None:
    """Delete a user by ID."""
    if user_id not in user_db:
        logger.warning(f"User not found for deletion: id={user_id}")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User with id {user_id} not found",
        )
    del user_db[user_id]
    logger.info(f"User deleted: id={user_id}")