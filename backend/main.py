from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware 
from typing import List
from sqlalchemy.orm import Session
from sqlalchemy import text
from database import get_db, engine
import models
import schemas
import crud
import ai 
from pydantic import BaseModel

class AIRequest(BaseModel):
    query: str
# Formally bind the metadata to create tables in MySQL
models.Base.metadata.create_all(bind=engine)


# This tells Python what data to expect from Flutter
class LoginRequest(BaseModel):
    email: str
    password: str


# Initialize the core application
app = FastAPI(
    title="Turf Manager API",
    description="Backend API for the Community Sports Organizer",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://127.0.0.1:5173"], # React's default URLs
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# We add 'db: Session = Depends(get_db)' so this route can talk to MySQL
@app.post("/login")
def process_login(user: LoginRequest, db: Session = Depends(get_db)):
    print(f"Flutter attempting login for: {user.email}")
    
    # 1. Query the database for this specific email
    db_user = crud.get_user_by_email(db, email=user.email)
    
    # 2. If the email doesn't exist, or the password doesn't match, reject them
    # Note: For production, we will upgrade this to check hashed passwords using bcrypt.
    # For now, we will verify against the exact password string stored in your DB.
    if not db_user or db_user.password != user.password:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    # 3. If everything matches, let them in!
    return {
        "status": "success", 
        "message": "Welcome to the pitch!",
        "user_id": db_user.id  # Sending the ID back so Flutter knows exactly who logged in
    }

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

@app.post("/matches/", response_model=schemas.MatchResponse)
def create_match_endpoint(match: schemas.MatchCreate, db: Session = Depends(get_db)):
    # Note: In a real app, we'd verify the squad_id actually exists first!
    # For now, we assume the React frontend will send a valid squad_id.
    return crud.create_match(db=db, match=match)

@app.post("/rsvps/", response_model=schemas.RSVPResponse)
def create_rsvp_endpoint(rsvp: schemas.RSVPToggle, db: Session = Depends(get_db)):
    # Prevent Double-Booking: Check if this user is already in this match
    existing_rsvp = db.query(models.RSVP).filter(
        models.RSVP.match_id == rsvp.match_id,
        models.RSVP.user_id == rsvp.user_id
    ).first()

    if existing_rsvp:
        raise HTTPException(status_code=400, detail="User has already RSVP'd to this match")

    # Run the RSVP logic
    db_rsvp = crud.create_rsvp(db=db, rsvp=rsvp)
    
    if not db_rsvp:
        raise HTTPException(status_code=404, detail="Match not found")
        
    return db_rsvp

@app.get("/squads/", response_model=List[schemas.SquadResponse])
def read_squads_endpoint(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return crud.get_squads(db=db, skip=skip, limit=limit)

@app.get("/matches/{match_id}/ledger")
def get_match_ledger_endpoint(match_id: int, db: Session = Depends(get_db)):
    ledger_data = crud.get_match_ledger(db=db, match_id=match_id)
    
    if not ledger_data:
        raise HTTPException(status_code=404, detail="Match not found")
        
    return ledger_data


@app.get("/matches/")
def read_matches_endpoint(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return crud.get_matches(db=db, skip=skip, limit=limit)


@app.post("/ai/ask")
def ask_ai_endpoint(request: AIRequest, db: Session = Depends(get_db)):
    return ai.ask_turf_manager_ai(db=db, user_query=request.query)