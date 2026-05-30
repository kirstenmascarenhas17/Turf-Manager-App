from sqlalchemy.orm import Session
import models, schemas
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