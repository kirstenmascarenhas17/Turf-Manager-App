from pydantic import BaseModel, EmailStr
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