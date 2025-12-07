import os
import logging
from datetime import datetime
from typing import Optional, List, Dict, Any
import boto3
from boto3.dynamodb.conditions import Key, Attr
from botocore.exceptions import ClientError
import uuid

logger = logging.getLogger(__name__)


class DynamoDBService:
    """Service for DynamoDB operations"""
    
    def __init__(self):
        self.table_name = os.getenv("DYNAMODB_TABLE_NAME", "tickets")
        self.dynamodb = boto3.resource(
            'dynamodb',
            region_name=os.getenv("AWS_REGION", "us-east-1")
        )
        self.table = self.dynamodb.Table(self.table_name)
    
    def create_ticket(self, ticket_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new ticket in DynamoDB"""
        ticket_id = str(uuid.uuid4())
        now = datetime.utcnow().isoformat()
        
        item = {
            "ticket_id": ticket_id,
            "created_at": now,
            "updated_at": now,
            "customer_email": ticket_data["customer_email"],
            "customer_name": ticket_data.get("customer_name"),
            "subject": ticket_data["subject"],
            "body": ticket_data["body"],
            "priority": ticket_data["priority"],
            "category": ticket_data["category"],
            "sentiment": ticket_data["sentiment"],
            "status": ticket_data.get("status", "New"),
            "ai_suggested_reply": ticket_data["ai_suggested_reply"],
            "is_vip": ticket_data.get("is_vip", False)
        }
        
        try:
            self.table.put_item(Item=item)
            logger.info(f"Created ticket {ticket_id}")
            return item
        except ClientError as e:
            logger.error(f"Error creating ticket: {e}")
            raise
    
    def get_ticket(self, ticket_id: str) -> Optional[Dict[str, Any]]:
        """Get a ticket by ID"""
        try:
            response = self.table.get_item(Key={"ticket_id": ticket_id})
            return response.get("Item")
        except ClientError as e:
            logger.error(f"Error getting ticket {ticket_id}: {e}")
            raise
    
    def list_tickets(
        self,
        status: Optional[str] = None,
        priority: Optional[str] = None,
        category: Optional[str] = None,
        sentiment: Optional[str] = None,
        page: int = 1,
        page_size: int = 20
    ) -> Dict[str, Any]:
        """List tickets with optional filters"""
        try:
            # Build filter expression
            filter_expr = None
            conditions = []
            
            if status:
                conditions.append(Attr("status").eq(status))
            if priority:
                conditions.append(Attr("priority").eq(priority))
            if category:
                conditions.append(Attr("category").eq(category))
            if sentiment:
                conditions.append(Attr("sentiment").eq(sentiment))
            
            if conditions:
                filter_expr = conditions[0]
                for condition in conditions[1:]:
                    filter_expr = filter_expr & condition
            
            # Scan with filter
            scan_kwargs = {}
            if filter_expr:
                scan_kwargs["FilterExpression"] = filter_expr
            
            response = self.table.scan(**scan_kwargs)
            items = response.get("Items", [])
            
            # Sort by created_at (newest first)
            items.sort(key=lambda x: x.get("created_at", ""), reverse=True)
            
            # Pagination
            total = len(items)
            start = (page - 1) * page_size
            end = start + page_size
            paginated_items = items[start:end]
            
            return {
                "tickets": paginated_items,
                "total": total,
                "page": page,
                "page_size": page_size
            }
        except ClientError as e:
            logger.error(f"Error listing tickets: {e}")
            raise
    
    def update_ticket(
        self, 
        ticket_id: str, 
        updates: Dict[str, Any]
    ) -> Optional[Dict[str, Any]]:
        """Update a ticket"""
        try:
            # Build update expression
            update_expr_parts = []
            expr_attr_names = {}
            expr_attr_values = {}
            
            # Fields that can be updated
            updatable_fields = {
                "subject": "subject",
                "body": "body",
                "status": "status",
                "priority": "priority",
                "category": "category",
                "sentiment": "sentiment",
                "ai_suggested_reply": "ai_suggested_reply"
            }
            
            for field, attr_name in updatable_fields.items():
                if field in updates:
                    update_expr_parts.append(f"#{attr_name} = :{attr_name}")
                    expr_attr_names[f"#{attr_name}"] = field
                    expr_attr_values[f":{attr_name}"] = updates[field]
            
            # Always update updated_at
            update_expr_parts.append("updated_at = :updated_at")
            expr_attr_values[":updated_at"] = datetime.utcnow().isoformat()
            
            if not update_expr_parts:
                # No updates to make, just return existing
                return self.get_ticket(ticket_id)
            
            update_expr = "SET " + ", ".join(update_expr_parts)
            
            kwargs = {
                "Key": {"ticket_id": ticket_id},
                "UpdateExpression": update_expr,
                "ExpressionAttributeValues": expr_attr_values,
                "ReturnValues": "ALL_NEW"
            }
            
            if expr_attr_names:
                kwargs["ExpressionAttributeNames"] = expr_attr_names
            
            response = self.table.update_item(**kwargs)
            logger.info(f"Updated ticket {ticket_id}")
            return response.get("Attributes")
        except ClientError as e:
            logger.error(f"Error updating ticket {ticket_id}: {e}")
            raise

