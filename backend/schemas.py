from pydantic import BaseModel, EmailStr, Field
from decimal import Decimal
from typing import Optional
from datetime import datetime
# ==========================
# USER SCHEMAS
# ==========================
class UserBase(BaseModel):
    name: str
    email: EmailStr
    upi_id: Optional[str] = None

class UserCreate(UserBase):
    pass

class UserResponse(UserBase):
    id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

# ==========================
# SQUAD SCHEMAS
# ==========================
class SquadBase(BaseModel):
    name: str

class SquadCreate(SquadBase):
    pass

class SquadResponse(SquadBase):
    id: int
    invite_code: str
    creator_id: int
    created_at: datetime

    class Config:
        from_attributes = True

class MatchBase(BaseModel):
    title: str
    date_time: datetime
    turf_details: Optional[str] = None
    total_cost: Decimal = Field(default=Decimal('0.00'), max_digits=10, decimal_places=2)
    max_slots: int = 10
    is_public: bool = False

class MatchCreate(MatchBase):
    squad_id: int

class MatchResponse(MatchBase):
    id: int
    squad_id: int

    class Config:
        from_attributes = True


# ==========================
# RSVP SCHEMAS
# ==========================
class RSVPBase(BaseModel):
    match_id: int
    user_id: int

class RSVPToggle(RSVPBase):
    pass

class RSVPResponse(RSVPBase):
    id: int
    status: str
    created_at: datetime

    class Config:
        from_attributes = True