import os
import logging
from typing import Dict, Any
import openai
from openai import AsyncOpenAI
from ..models import Priority, Category, Sentiment

logger = logging.getLogger(__name__)

# Initialize OpenAI client
client = AsyncOpenAI(api_key=os.getenv("OPENAI_API_KEY"))


class AIService:
    """Service for AI-powered ticket analysis using OpenAI API"""
    
    def __init__(self):
        self.api_key = os.getenv("OPENAI_API_KEY")
        if not self.api_key:
            logger.warning("OPENAI_API_KEY not set, using fallback rules")
    
    async def analyze_ticket(
        self, 
        subject: str, 
        body: str, 
        is_vip: bool = False
    ) -> Dict[str, Any]:
        """
        Analyze ticket and return priority, category, sentiment, and suggested reply.
        Falls back to rule-based analysis if AI API fails.
        """
        try:
            if self.api_key:
                return await self._analyze_with_ai(subject, body, is_vip)
            else:
                return self._analyze_with_rules(subject, body, is_vip)
        except Exception as e:
            logger.error(f"AI analysis failed: {e}, falling back to rules")
            return self._analyze_with_rules(subject, body, is_vip)
    
    async def _analyze_with_ai(
        self, 
        subject: str, 
        body: str, 
        is_vip: bool
    ) -> Dict[str, Any]:
        """Use OpenAI API for analysis"""
        prompt = f"""Analyze this support ticket and provide:
1. Priority (P1=Critical, P2=High, P3=Medium, P4=Low)
2. Category (Billing, Login, Performance, Bug, Feature Request, Access, Other)
3. Sentiment (Angry, Neutral, Positive)
4. A professional suggested reply (2-3 sentences)

Subject: {subject}
Body: {body}
VIP Customer: {is_vip}

Respond in JSON format:
{{
    "priority": "P1|P2|P3|P4",
    "category": "Category name",
    "sentiment": "Angry|Neutral|Positive",
    "suggested_reply": "Your suggested reply here"
}}"""

        try:
            response = await client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=[
                    {"role": "system", "content": "You are a support ticket analyzer. Always respond with valid JSON."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.3,
                max_tokens=500,
                timeout=10.0
            )
            
            import json
            result_text = response.choices[0].message.content.strip()
            # Remove markdown code blocks if present
            if result_text.startswith("```"):
                result_text = result_text.split("```")[1]
                if result_text.startswith("json"):
                    result_text = result_text[4:]
            result_text = result_text.strip()
            
            result = json.loads(result_text)
            
            # Apply business rules
            priority = self._apply_business_rules(
                result.get("priority", "P3"),
                subject,
                body,
                is_vip
            )
            
            return {
                "priority": priority,
                "category": result.get("category", "Other"),
                "sentiment": result.get("sentiment", "Neutral"),
                "suggested_reply": result.get("suggested_reply", "Thank you for contacting support. We will investigate this issue.")
            }
        except Exception as e:
            logger.error(f"OpenAI API error: {e}")
            raise
    
    def _analyze_with_rules(
        self, 
        subject: str, 
        body: str, 
        is_vip: bool
    ) -> Dict[str, Any]:
        """Fallback rule-based analysis"""
        text = (subject + " " + body).lower()
        
        # Priority detection
        priority = "P3"  # Default
        critical_keywords = ["down", "outage", "can't login", "cannot access", "broken", "urgent"]
        high_keywords = ["slow", "error", "issue", "problem", "not working"]
        
        if any(keyword in text for keyword in critical_keywords):
            priority = "P1"
        elif any(keyword in text for keyword in high_keywords):
            priority = "P2"
        
        # VIP bump
        if is_vip and priority in ["P3", "P4"]:
            priority = "P2"
        
        # Category detection
        category = "Other"
        if any(word in text for word in ["billing", "payment", "charge", "invoice", "refund"]):
            category = "Billing"
        elif any(word in text for word in ["login", "password", "access", "account"]):
            category = "Login"
        elif any(word in text for word in ["slow", "performance", "lag", "timeout"]):
            category = "Performance"
        elif any(word in text for word in ["bug", "error", "broken", "crash"]):
            category = "Bug"
        elif any(word in text for word in ["feature", "request", "suggestion", "enhancement"]):
            category = "Feature Request"
        
        # Sentiment detection
        sentiment = "Neutral"
        angry_words = ["angry", "frustrated", "terrible", "awful", "horrible", "disappointed"]
        positive_words = ["thank", "great", "appreciate", "love", "excellent"]
        
        if any(word in text for word in angry_words):
            sentiment = "Angry"
        elif any(word in text for word in positive_words):
            sentiment = "Positive"
        
        # Suggested reply
        suggested_reply = f"Thank you for contacting support regarding: {subject}. "
        if sentiment == "Angry":
            suggested_reply += "We sincerely apologize for the inconvenience. "
        suggested_reply += "Our team is investigating this issue and will provide an update shortly."
        
        return {
            "priority": priority,
            "category": category,
            "sentiment": sentiment,
            "suggested_reply": suggested_reply
        }
    
    def _apply_business_rules(
        self, 
        ai_priority: str, 
        subject: str, 
        body: str, 
        is_vip: bool
    ) -> str:
        """Apply business rules to AI-suggested priority"""
        text = (subject + " " + body).lower()
        
        # Critical keywords override
        critical_keywords = ["down", "outage", "can't login", "cannot access"]
        if any(keyword in text for keyword in critical_keywords):
            return "P1"
        
        # VIP bump
        if is_vip:
            priority_map = {"P4": "P3", "P3": "P2", "P2": "P2", "P1": "P1"}
            return priority_map.get(ai_priority, "P2")
        
        return ai_priority


