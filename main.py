from fastapi import FastAPI

# Initialize the core application
app = FastAPI(
    title="Turf Manager API",
    description="Backend API for the Community Sports Organizer",
    version="1.0.0"
)

# Create a health-check endpoint
@app.get("/ping")
async def ping():
    return {
        "status": "success", 
        "message": "The Turf Manager backend is officially live!"
    }