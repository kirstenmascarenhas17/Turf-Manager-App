import os
import google.generativeai as genai
from sqlalchemy import text
from sqlalchemy.orm import Session
from dotenv import load_dotenv

# Load the secret key from your .env file
load_dotenv()
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

# Initialize the fast model
model = genai.GenerativeModel('gemini-1.5-flash')

def ask_turf_manager_ai(db: Session, user_query: str):
    # Phase 1: Text-to-SQL Translation
    schema_context = f"""
    You are the database manager for a Turf Scheduling App. 
    Here is the MySQL database schema:
    - users (id, name, email, upi_id)
    - squads (id, name, invite_code, creator_id)
    - matches (id, squad_id, title, date_time, turf_details, total_cost, max_slots)
    - rsvps (id, match_id, user_id, status)
    
    Task: Translate the following user query into a valid MySQL SELECT statement.
    Return STRICTLY the SQL code. No markdown, no backticks, no explanations.
    
    User Query: {user_query}
    """
    
    try:
        # Get the SQL string from Gemini
        sql_response = model.generate_content(schema_context)
        sql_query = sql_response.text.strip().replace("```sql", "").replace("```", "")
        
        # Phase 2: Execute the SQL against your local MySQL database
        # (Note: In a massive production app, you would heavily sanitize this for security, 
        # but this is perfect for your portfolio architecture!)
        result = db.execute(text(sql_query)).fetchall()
        
        # Convert the SQL rows into a readable string
        raw_data = str([dict(row._mapping) for row in result])
        
        # Phase 3: Data-to-Text Summary
        human_prompt = f"""
        The user asked: "{user_query}"
        The database returned this raw data: {raw_data}
        Write a short, friendly, conversational response to the user based on this data.
        If the data is empty, tell them no records were found.
        """
        
        final_response = model.generate_content(human_prompt)
        
        return {
            "query": user_query,
            "sql_executed": sql_query,
            "ai_answer": final_response.text
        }
        
    except Exception as e:
        return {"error": str(e), "message": "The AI encountered an issue processing the data."}