from sqlalchemy.orm import Session
import backend.models as models, backend.schemas as schemas
import random
import string

def get_user_by_email(db: Session, email: str):
    # Queries the database to see if a user with this email already exists
    return db.query(models.User).filter(models.User.email == email).first()

def create_user(db: Session, user: schemas.UserCreate):
    # Convert Pydantic schema to SQLAlchemy model
    db_user = models.User(name=user.name, email=user.email, upi_id=user.upi_id)
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