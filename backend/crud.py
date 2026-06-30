from sqlalchemy.orm import Session
import models
import schemas
import random
import string

def get_user_by_email(db: Session, email: str):
    # Queries the database to see if a user with this email already exists
    return db.query(models.User).filter(models.User.email == email).first()

def create_user(db: Session, user: schemas.UserCreate):
    # Convert Pydantic schema to SQLAlchemy model
    db_user = models.User(name=user.name, email=user.email, upi_id=user.upi_id, password=user.password)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def generate_invite_code():
    # Generates a random 6-character code like "SQ-A9X2BF"
    return "SQ-" + "".join(random.choices(string.ascii_uppercase + string.digits, k=6))

def create_squad(db: Session, squad: schemas.SquadCreate, creator_id: int):
    db_squad = models.Squad(
        name=squad.name,
        invite_code=generate_invite_code(),
        creator_id=creator_id
    )
    db.add(db_squad)
    db.commit()
    db.refresh(db_squad)
    return db_squad

def create_match(db: Session, match: schemas.MatchCreate):
    db_match = models.Match(
        squad_id=match.squad_id,
        title=match.title,
        date_time=match.date_time,
        turf_details=match.turf_details,
        total_cost=match.total_cost,
        max_slots=match.max_slots,
        is_public=match.is_public
    )
    db.add(db_match)
    db.commit()
    db.refresh(db_match)
    return db_match

def create_rsvp(db: Session, rsvp: schemas.RSVPToggle):
    # 1. Fetch the match to see its max_slots capacity
    match = db.query(models.Match).filter(models.Match.id == rsvp.match_id).first()
    if not match:
        return None # We will let the endpoint handle the 404 error

    # 2. Count how many ACTIVE players are already in this match
    active_count = db.query(models.RSVP).filter(
        models.RSVP.match_id == rsvp.match_id,
        models.RSVP.status == models.RSVPStatus.ACTIVE
    ).count()

    # 3. The Logic: If turf is full, waitlist them. Otherwise, they are active.
    new_status = models.RSVPStatus.ACTIVE
    if active_count >= match.max_slots:
        new_status = models.RSVPStatus.WAITLISTED

    # 4. Save to database
    db_rsvp = models.RSVP(
        match_id=rsvp.match_id,
        user_id=rsvp.user_id,
        status=new_status
    )
    db.add(db_rsvp)
    db.commit()
    db.refresh(db_rsvp)
    return db_rsvp

def get_squads(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.Squad).offset(skip).limit(limit).all()

def get_match_ledger(db: Session, match_id: int):
    # 1. Fetch the specific match
    match = db.query(models.Match).filter(models.Match.id == match_id).first()
    if not match:
        return None

    # 2. Fetch only the ACTIVE players (ignore waitlisted/cancelled)
    active_rsvps = db.query(models.RSVP).filter(
        models.RSVP.match_id == match_id,
        models.RSVP.status == models.RSVPStatus.ACTIVE
    ).all()

    active_count = len(active_rsvps)
    
    # 3. The Math Engine: Calculate the exact split
    per_head = 0.0
    if active_count > 0 and match.total_cost:
        per_head = float(match.total_cost) / active_count

    # 4. Gather the player details (we need their UPI IDs later!)
    players = []
    for rsvp in active_rsvps:
        user = db.query(models.User).filter(models.User.id == rsvp.user_id).first()
        if user:
            players.append({
                "user_id": user.id,
                "name": user.name,
                "upi_id": user.upi_id
            })

    # 5. Return the full financial payload
    return {
        "match_id": match.id,
        "title": match.title,
        "total_cost": float(match.total_cost) if match.total_cost else 0,
        "active_players": active_count,
        "cost_per_head": round(per_head, 2), # Round to 2 decimal places for currency
        "squad_id": match.squad_id,
        "players": players
    }

def get_matches(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.Match).order_by(models.Match.date_time.desc()).offset(skip).limit(limit).all()