"""Main FastAPI application."""
from fastapi import FastAPI
from app.routes import user
from app.core.config import settings
from app.utils.logger import logger

# Create FastAPI application
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="User management microservice API",
)


# Include routers
app.include_router(user.router, prefix="/users", tags=["Users"])


@app.get("/health")
def health_check() -> dict:
    """Health check endpoint for load balancers."""
    logger.debug("Health check endpoint called")
    return {"status": "ok"}


@app.get("/ready")
def readiness_check() -> dict:
    """Readiness check endpoint for Kubernetes."""
    logger.debug("Readiness check endpoint called")
    return {"status": "ready", "version": settings.APP_VERSION}


@app.on_event("startup")
async def startup_event() -> None:
    """Execute on application startup."""
    logger.info(f"Starting {settings.APP_NAME} v{settings.APP_VERSION}")


@app.on_event("shutdown")
async def shutdown_event() -> None:
    """Execute on application shutdown."""
    logger.info("Shutting down application")