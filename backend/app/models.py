from datetime import datetime
from enum import Enum
from typing import Optional, List
from pydantic import BaseModel, EmailStr, Field


class Priority(str, Enum):
    P1 = "P1"  # Critical
    P2 = "P2"  # High
    P3 = "P3"  # Medium
    P4 = "P4"  # Low


class Category(str, Enum):
    BILLING = "Billing"
    LOGIN = "Login"
    PERFORMANCE = "Performance"
    BUG = "Bug"
    FEATURE_REQUEST = "Feature Request"
    ACCESS = "Access"
    OTHER = "Other"


class Sentiment(str, Enum):
    ANGRY = "Angry"
    NEUTRAL = "Neutral"
    POSITIVE = "Positive"


class TicketStatus(str, Enum):
    NEW = "New"
    IN_PROGRESS = "In-Progress"
    RESOLVED = "Resolved"


class TicketCreate(BaseModel):
    customer_email: EmailStr
    subject: str = Field(..., min_length=1, max_length=200)
    body: str = Field(..., min_length=1, max_length=5000)
    customer_name: Optional[str] = None
    is_vip: bool = False


class TicketResponse(BaseModel):
    ticket_id: str
    created_at: datetime
    customer_email: str
    customer_name: Optional[str]
    subject: str
    body: str
    priority: Priority
    category: Category
    sentiment: Sentiment
    status: TicketStatus
    ai_suggested_reply: str
    is_vip: bool

    class Config:
        from_attributes = True


class TicketUpdate(BaseModel):
    subject: Optional[str] = None
    body: Optional[str] = None
    status: Optional[TicketStatus] = None


class TicketListResponse(BaseModel):
    tickets: List[TicketResponse]
    total: int
    page: int
    page_size: int


class TicketFilter(BaseModel):
    status: Optional[TicketStatus] = None
    priority: Optional[Priority] = None
    category: Optional[Category] = None
    sentiment: Optional[Sentiment] = None
    page: int = Field(default=1, ge=1)
    page_size: int = Field(default=20, ge=1, le=100)

