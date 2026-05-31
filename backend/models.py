from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, DECIMAL, DateTime, Enum, Table
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum
from database import Base

# ==========================================
# JUNCTION TABLE: Squad Members (Many-to-Many)
# ==========================================
squad_members = Table(
    "squad_members",
    Base.metadata,
    Column("squad_id", Integer, ForeignKey("squads.id", ondelete="CASCADE"), primary_key=True),
    Column("user_id", Integer, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
    Column("joined_at", DateTime, server_default=func.now())
)

# ==========================================
# ENUMS
# ==========================================
class RSVPStatus(str, enum.Enum):
    ACTIVE = "active"
    WAITLISTED = "waitlisted"
    CANCELLED = "cancelled"

# ==========================================
# MODELS
# ==========================================

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    email = Column(String(100), unique=True, index=True, nullable=False)
    upi_id = Column(String(100), nullable=True)
    created_at = Column(DateTime, server_default=func.now())

    # Relationships
    created_squads = relationship("Squad", back_populates="creator")
    squads = relationship("Squad", secondary=squad_members, back_populates="members")
    rsvps = relationship("RSVP", back_populates="user")


class Squad(Base):
    __tablename__ = "squads"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    invite_code = Column(String(20), unique=True, index=True, nullable=False)
    creator_id = Column(Integer, ForeignKey("users.id"))
    created_at = Column(DateTime, server_default=func.now())

    # Relationships
    creator = relationship("User", back_populates="created_squads")
    members = relationship("User", secondary=squad_members, back_populates="squads")
    matches = relationship("Match", back_populates="squad")


class Match(Base):
    __tablename__ = "matches"

    id = Column(Integer, primary_key=True, index=True)
    squad_id = Column(Integer, ForeignKey("squads.id"), nullable=False)
    title = Column(String(100), nullable=False)
    date_time = Column(DateTime, nullable=False)
    turf_details = Column(String(255), nullable=True)
    total_cost = Column(DECIMAL(10, 2), default=0.00)
    max_slots = Column(Integer, default=10)
    is_public = Column(Boolean, default=False)

    # Relationships
    squad = relationship("Squad", back_populates="matches")
    rsvps = relationship("RSVP", back_populates="match")
    ledger_entries = relationship("LedgerEntry", back_populates="match")


class RSVP(Base):
    __tablename__ = "rsvps"

    id = Column(Integer, primary_key=True, index=True)
    match_id = Column(Integer, ForeignKey("matches.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    status = Column(Enum(RSVPStatus), default=RSVPStatus.ACTIVE, nullable=False)
    created_at = Column(DateTime, server_default=func.now())

    # Relationships
    match = relationship("Match", back_populates="rsvps")
    user = relationship("User", back_populates="rsvps")


class LedgerEntry(Base):
    __tablename__ = "ledger_entries"

    id = Column(Integer, primary_key=True, index=True)
    match_id = Column(Integer, ForeignKey("matches.id"), nullable=False)
    lender_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    borrower_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    amount_due = Column(DECIMAL(10, 2), nullable=False)
    is_settled = Column(Boolean, default=False)
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())

    # Relationships
    match = relationship("Match", back_populates="ledger_entries")