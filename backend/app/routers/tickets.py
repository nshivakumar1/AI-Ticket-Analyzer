from fastapi import APIRouter, HTTPException, Query
from typing import Optional
from datetime import datetime
import logging

from ..models import (
    TicketCreate,
    TicketResponse,
    TicketUpdate,
    TicketListResponse,
    TicketFilter,
    Priority,
    Category,
    Sentiment,
    TicketStatus
)
from ..services.ai_service import AIService
from ..services.dynamodb_service import DynamoDBService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/tickets", tags=["tickets"])

ai_service = AIService()
db_service = DynamoDBService()


@router.post("", response_model=TicketResponse, status_code=201)
async def create_ticket(ticket: TicketCreate):
    """Create a new support ticket with AI analysis"""
    try:
        # Analyze ticket with AI
        analysis = await ai_service.analyze_ticket(
            subject=ticket.subject,
            body=ticket.body,
            is_vip=ticket.is_vip
        )
        
        # Prepare ticket data
        ticket_data = {
            "customer_email": ticket.customer_email,
            "customer_name": ticket.customer_name,
            "subject": ticket.subject,
            "body": ticket.body,
            "priority": analysis["priority"],
            "category": analysis["category"],
            "sentiment": analysis["sentiment"],
            "status": "New",
            "ai_suggested_reply": analysis["suggested_reply"],
            "is_vip": ticket.is_vip
        }
        
        # Save to DynamoDB
        created_ticket = db_service.create_ticket(ticket_data)
        
        # Convert to response model
        return TicketResponse(
            ticket_id=created_ticket["ticket_id"],
            created_at=datetime.fromisoformat(created_ticket["created_at"]),
            customer_email=created_ticket["customer_email"],
            customer_name=created_ticket.get("customer_name"),
            subject=created_ticket["subject"],
            body=created_ticket["body"],
            priority=Priority(created_ticket["priority"]),
            category=Category(created_ticket["category"]),
            sentiment=Sentiment(created_ticket["sentiment"]),
            status=TicketStatus(created_ticket["status"]),
            ai_suggested_reply=created_ticket["ai_suggested_reply"],
            is_vip=created_ticket.get("is_vip", False)
        )
    except Exception as e:
        logger.error(f"Error creating ticket: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to create ticket: {str(e)}")


@router.get("", response_model=TicketListResponse)
async def list_tickets(
    status: Optional[TicketStatus] = Query(None),
    priority: Optional[Priority] = Query(None),
    category: Optional[Category] = Query(None),
    sentiment: Optional[Sentiment] = Query(None),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100)
):
    """List tickets with optional filters"""
    try:
        result = db_service.list_tickets(
            status=status.value if status else None,
            priority=priority.value if priority else None,
            category=category.value if category else None,
            sentiment=sentiment.value if sentiment else None,
            page=page,
            page_size=page_size
        )
        
        # Convert to response models
        tickets = [
            TicketResponse(
                ticket_id=t["ticket_id"],
                created_at=datetime.fromisoformat(t["created_at"]),
                customer_email=t["customer_email"],
                customer_name=t.get("customer_name"),
                subject=t["subject"],
                body=t["body"],
                priority=Priority(t["priority"]),
                category=Category(t["category"]),
                sentiment=Sentiment(t["sentiment"]),
                status=TicketStatus(t["status"]),
                ai_suggested_reply=t["ai_suggested_reply"],
                is_vip=t.get("is_vip", False)
            )
            for t in result["tickets"]
        ]
        
        return TicketListResponse(
            tickets=tickets,
            total=result["total"],
            page=result["page"],
            page_size=result["page_size"]
        )
    except Exception as e:
        logger.error(f"Error listing tickets: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to list tickets: {str(e)}")


@router.get("/{ticket_id}", response_model=TicketResponse)
async def get_ticket(ticket_id: str):
    """Get a specific ticket by ID"""
    try:
        ticket = db_service.get_ticket(ticket_id)
        if not ticket:
            raise HTTPException(status_code=404, detail="Ticket not found")
        
        return TicketResponse(
            ticket_id=ticket["ticket_id"],
            created_at=datetime.fromisoformat(ticket["created_at"]),
            customer_email=ticket["customer_email"],
            customer_name=ticket.get("customer_name"),
            subject=ticket["subject"],
            body=ticket["body"],
            priority=Priority(ticket["priority"]),
            category=Category(ticket["category"]),
            sentiment=Sentiment(ticket["sentiment"]),
            status=TicketStatus(ticket["status"]),
            ai_suggested_reply=ticket["ai_suggested_reply"],
            is_vip=ticket.get("is_vip", False)
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting ticket {ticket_id}: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get ticket: {str(e)}")


@router.patch("/{ticket_id}", response_model=TicketResponse)
async def update_ticket(ticket_id: str, update: TicketUpdate):
    """Update a ticket"""
    try:
        # Check if ticket exists
        existing = db_service.get_ticket(ticket_id)
        if not existing:
            raise HTTPException(status_code=404, detail="Ticket not found")
        
        # Prepare updates
        updates = {}
        if update.subject is not None:
            updates["subject"] = update.subject
        if update.body is not None:
            updates["body"] = update.body
        if update.status is not None:
            updates["status"] = update.status.value
        
        if not updates:
            # Return existing ticket if no updates
            return TicketResponse(
                ticket_id=existing["ticket_id"],
                created_at=datetime.fromisoformat(existing["created_at"]),
                customer_email=existing["customer_email"],
                customer_name=existing.get("customer_name"),
                subject=existing["subject"],
                body=existing["body"],
                priority=Priority(existing["priority"]),
                category=Category(existing["category"]),
                sentiment=Sentiment(existing["sentiment"]),
                status=TicketStatus(existing["status"]),
                ai_suggested_reply=existing["ai_suggested_reply"],
                is_vip=existing.get("is_vip", False)
            )
        
        # Update ticket
        updated = db_service.update_ticket(ticket_id, updates)
        
        return TicketResponse(
            ticket_id=updated["ticket_id"],
            created_at=datetime.fromisoformat(updated["created_at"]),
            customer_email=updated["customer_email"],
            customer_name=updated.get("customer_name"),
            subject=updated["subject"],
            body=updated["body"],
            priority=Priority(updated["priority"]),
            category=Category(updated["category"]),
            sentiment=Sentiment(updated["sentiment"]),
            status=TicketStatus(updated["status"]),
            ai_suggested_reply=updated["ai_suggested_reply"],
            is_vip=updated.get("is_vip", False)
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating ticket {ticket_id}: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to update ticket: {str(e)}")


@router.post("/{ticket_id}/reanalyze", response_model=TicketResponse)
async def reanalyze_ticket(ticket_id: str):
    """Re-run AI analysis on an existing ticket"""
    try:
        # Get existing ticket
        ticket = db_service.get_ticket(ticket_id)
        if not ticket:
            raise HTTPException(status_code=404, detail="Ticket not found")
        
        # Re-analyze with AI
        analysis = await ai_service.analyze_ticket(
            subject=ticket["subject"],
            body=ticket["body"],
            is_vip=ticket.get("is_vip", False)
        )
        
        # Update ticket with new analysis
        updates = {
            "priority": analysis["priority"],
            "category": analysis["category"],
            "sentiment": analysis["sentiment"],
            "ai_suggested_reply": analysis["suggested_reply"]
        }
        
        # Update ticket in DynamoDB
        updated = db_service.update_ticket(ticket_id, updates)
        
        return TicketResponse(
            ticket_id=updated["ticket_id"],
            created_at=datetime.fromisoformat(updated["created_at"]),
            customer_email=updated["customer_email"],
            customer_name=updated.get("customer_name"),
            subject=updated["subject"],
            body=updated["body"],
            priority=Priority(updated["priority"]),
            category=Category(updated["category"]),
            sentiment=Sentiment(updated["sentiment"]),
            status=TicketStatus(updated["status"]),
            ai_suggested_reply=updated["ai_suggested_reply"],
            is_vip=updated.get("is_vip", False)
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error reanalyzing ticket {ticket_id}: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to reanalyze ticket: {str(e)}")

