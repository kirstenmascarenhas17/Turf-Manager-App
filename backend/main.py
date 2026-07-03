import os
from dotenv import load_dotenv
import jwt
from datetime import datetime, timedelta
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
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jwt.exceptions import PyJWTError
import string
import random

load_dotenv()

SECRET_KEY = os.getenv("JWT_SECRET_KEY")
ALGORITHM = "HS256"

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

# Secret key to sign the VIP wristbands (In production, this goes in an .env file!)
SECRET_KEY = "turf_manager_super_secret_key"
ALGORITHM = "HS256"

@app.post("/login")
def process_login(user: LoginRequest, db: Session = Depends(get_db)):
    print(f"Flutter attempting login for: {user.email}")
    
    db_user = crud.get_user_by_email(db, email=user.email)
    
    if not db_user or db_user.password != user.password:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    # --- NEW JWT LOGIC ---
    # Create the data payload for the token
    token_data = {
        "sub": str(db_user.id),          # The user's ID
        "email": db_user.email,          # The user's email
        "exp": datetime.utcnow() + timedelta(days=7)  # Token expires in 7 days
    }
    
    # Generate the actual token string
    access_token = jwt.encode(token_data, SECRET_KEY, algorithm=ALGORITHM)
    
    # Send the token back to the phone!
    return {
        "status": "success", 
        "message": "Welcome to the pitch!",
        "access_token": access_token,
        "token_type": "bearer"
    }
# This tells FastAPI where to look for the token in the request
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="swagger-login")

# --- THE BOUNCER FUNCTION ---
def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=401,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        # 1. Decode the VIP wristband using our secret key
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("email")
        if email is None:
            raise credentials_exception
    except PyJWTError:
        raise credentials_exception
        
    # 2. Check if the user still exists in the database
    user = crud.get_user_by_email(db, email=email)
    if user is None:
        raise credentials_exception
        
    # 3. If everything is good, hand the user's data to the requested route
    return user


# Make sure to add db: Session = Depends(get_db) so the route can talk to MySQL!
@app.get("/me/dashboard")
def get_user_dashboard(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # 1. Fetch the real matches from your MySQL database using the CRUD function we built in Phase 2
    real_matches = crud.get_matches(db=db, skip=0, limit=10)
    
    # 2. Format the database records into a clean dictionary so Flutter can read them easily
    formatted_matches = []
    for match in real_matches:
        formatted_matches.append({
            "id": match.id,
            "title": match.title, 
            # We convert the datetime object to a string so it travels over the network safely
            "time": match.date_time.strftime("%d/%m/%Y, %H:%M") if match.date_time else "TBD",
            "location": match.turf_details
        })

    # 3. Send the real data back to the phone!
    return {
        "status": "success",
        "message": f"Welcome back, {current_user.name}!",
        "upcoming_matches": formatted_matches
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
def create_squad_endpoint(
    squad: schemas.SquadCreate, 
    current_user: models.User = Depends(get_current_user), # <-- Let the Bouncer handle the identity
    db: Session = Depends(get_db)
):
    # 1. Generate the secure code
    letters_and_digits = string.ascii_uppercase + string.digits
    unique_code = ''.join(random.choice(letters_and_digits) for i in range(6))
    
    # 2. Package the data, extracting the ID securely from the token
    new_squad = models.Squad(
        name=squad.name,
        invite_code=unique_code,
        creator_id=current_user.id # <-- The ID is injected here behind the scenes!
    )
    
    db.add(new_squad)
    db.commit()
    db.refresh(new_squad)
    
    return new_squad

# Create a simple Pydantic schema for the input payload right above the route
class JoinSquadRequest(BaseModel):
    invite_code: str

# --- PROTECTED JOIN SQUAD ROUTE ---
@app.post("/squads/join")
def join_squad_endpoint(
    payload: JoinSquadRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # 1. Clean the incoming code (make it uppercase, remove whitespace)
    clean_code = payload.invite_code.strip().upper()
    
    # 2. Look up the squad by the invite code
    squad = db.query(models.Squad).filter(models.Squad.invite_code == clean_code).first()
    
    if not squad:
        raise HTTPException(
            status_code=404, 
            detail="Invalid invite code. Squad not found."
        )
        
    # 3. Link the user to the squad
    # Depending on your schema design, we either update a squad_id on the User table,
    # or add a row to a squad_members junction table. 
    # Here, we update the user's current squad link:
    current_user.squad_id = squad.id
    db.commit()
    
    return {
        "status": "success",
        "message": f"Successfully joined squad: {squad.name}",
        "squad_name": squad.name
    }

# --- PROTECTED CREATE MATCH ROUTE ---
@app.post("/matches/", response_model=schemas.MatchResponse)
def create_match_endpoint(
    match: schemas.MatchCreate, 
    current_user: models.User = Depends(get_current_user), # <-- The Bouncer!
    db: Session = Depends(get_db)
):
    print(f"User {current_user.name} is creating a new match: {match.title}")
    
    # Note: In a full production app, we would link this match directly to current_user.id
    # For now, we will pass it to your existing CRUD function
    return crud.create_match(db=db, match=match)

# --- PROTECTED RSVP ROUTE ---
@app.post("/rsvps/", response_model=schemas.RSVPResponse)
def create_rsvp_endpoint(
    rsvp: schemas.RSVPToggle, 
    current_user: models.User = Depends(get_current_user), # The Bouncer!
    db: Session = Depends(get_db)
):
    # 1. Force the RSVP to belong to the logged-in user securely
    rsvp.user_id = current_user.id
    
    # 2. Prevent Double-Booking
    existing_rsvp = db.query(models.RSVP).filter(
        models.RSVP.match_id == rsvp.match_id,
        models.RSVP.user_id == current_user.id
    ).first()

    if existing_rsvp:
        raise HTTPException(status_code=400, detail="You are already on the roster!")

    # 3. Save the RSVP to MySQL
    db_rsvp = crud.create_rsvp(db=db, rsvp=rsvp)
    
    if not db_rsvp:
        raise HTTPException(status_code=404, detail="Match not found")
        
    return db_rsvp

# --- 1. UPGRADED ROSTER ROUTE ---
@app.get("/matches/{match_id}/roster")
def get_match_roster(
    match_id: int, 
    current_user: models.User = Depends(get_current_user), 
    db: Session = Depends(get_db)
):
    all_rsvps = db.query(models.RSVP).filter(models.RSVP.match_id == match_id).all()
    
    user_ids = []
    for rsvp in all_rsvps:
        status_str = str(rsvp.status)
        if "going" in status_str or "ACTIVE" in status_str:
            if rsvp.user_id:
                user_ids.append(rsvp.user_id)
    
    if not user_ids:
        player_names = []
    else:
        players = db.query(models.User).filter(models.User.id.in_(user_ids)).all()
        player_names = [player.name for player in players]
    
    return {
        "match_id": match_id,
        "player_count": len(player_names),
        "players": player_names,
        # NEW: Tell Flutter if the current user is in this list!
        "is_joined": current_user.name in player_names 
    }

# --- 2. NEW LEAVE MATCH ROUTE ---
@app.delete("/matches/{match_id}/leave")
def leave_match(
    match_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Find the user's specific RSVP for this match
    rsvp = db.query(models.RSVP).filter(
        models.RSVP.match_id == match_id,
        models.RSVP.user_id == current_user.id
    ).first()

    # If it exists, delete it from the database
    if rsvp:
        db.delete(rsvp)
        db.commit()
        
    return {"status": "success", "message": "Left the match"}

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


# --- PROTECTED SQUAD CREATION ROUTE ---
@app.post("/squads/", response_model=schemas.SquadResponse)
def create_squad_endpoint(
    squad: schemas.SquadCreate, 
    current_user: models.User = Depends(get_current_user), # The Bouncer ensures only logged-in users create squads
    db: Session = Depends(get_db)
):
    # 1. Generate a secure, 6-character uppercase alphanumeric invite code
    letters_and_digits = string.ascii_uppercase + string.digits
    unique_code = ''.join(random.choice(letters_and_digits) for i in range(6))
    
    # 2. Package the data for the database
    new_squad = models.Squad(
        name=squad.name,
        invite_code=unique_code,
        creator_id=current_user.id # You are officially the captain
    )
    
    # 3. Save it to MySQL
    db.add(new_squad)
    db.commit()
    db.refresh(new_squad)
    
    # Note: In the next step, we will also add the creator to a 'squad_members' table 
    # so you are automatically in your own squad!
    
    return new_squad

# --- THE SWAGGER SECRET ENTRANCE (FIXED) ---
@app.post("/swagger-login")
def login_for_swagger(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    # 1. Find the user
    user = db.query(models.User).filter(models.User.email == form_data.username).first()
    
    if not user:
        raise HTTPException(status_code=400, detail="User not found")
        
    # 2. Build the token payload exactly like your main login route
    token_data = {
        "sub": str(user.id),
        "email": user.email,
        "exp": datetime.utcnow() + timedelta(days=7)
    }
    
    # 3. Generate the actual token string
    access_token = jwt.encode(token_data, SECRET_KEY, algorithm=ALGORITHM)
    
    # 4. Return it in the strict format Swagger requires
    return {"access_token": access_token, "token_type": "bearer"}