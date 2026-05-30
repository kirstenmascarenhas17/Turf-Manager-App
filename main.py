from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from database import get_db, engine
import models
import schemas
import crud

# Formally bind the metadata to create tables in MySQL
models.Base.metadata.create_all(bind=engine)

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

# Create a database connection test endpoint
@app.get("/db-check")
async def test_db_connection(db: Session = Depends(get_db)):
    try:
        # Ask MySQL to run a basic math calculation to prove it's listening
        db.execute(text("SELECT 1"))
        return {
            "status": "success", 
            "message": "Database connected perfectly!"
        }
    except Exception as e:
        return {
            "status": "error", 
            "message": f"Connection failed: {str(e)}"
        }

@app.post("/users/", response_model=schemas.UserResponse)
def create_user_endpoint(user: schemas.UserCreate, db: Session = Depends(get_db)):
    # 1. Check if the email already exists
    db_user = crud.get_user_by_email(db, email=user.email)
    
    # 2. If it does, politely reject the request before hitting the database
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
        
    # 3. If it's a new email, create the user
    return crud.create_user(db=db, user=user)

@app.post("/squads/", response_model=schemas.SquadResponse)
def create_squad_endpoint(squad: schemas.SquadCreate, creator_id: int, db: Session = Depends(get_db)):
    return crud.create_squad(db=db, squad=squad, creator_id=creator_id)