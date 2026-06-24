import os
from google import genai
from sqlalchemy import text
from dotenv import load_dotenv

# Load the secret key
load_dotenv()
api_key = os.getenv("GEMINI_API_KEY")

def ask_turf_manager_ai(db, user_query: str):
    try:
        if not api_key:
            return {"error": "Missing API Key", "message": "The AI service is not configured correctly."}

        client = genai.Client(api_key=api_key)

        # 1. Ask AI to translate, with a fallback for casual chat
        schema_context = f"""
        You are the database manager for a Turf Scheduling App. 
        Tables: users (id, name), squads (id, name, invite_code), matches (id, title, total_cost, max_slots, date_time).
        Translate: "{user_query}" into a MySQL SELECT statement.
        Return ONLY the SQL code. No markdown, no backticks.
        If the prompt is just a greeting or conversational (not asking for data), return exactly the word: NOT_SQL
        """
        
        sql_response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=schema_context
        )
        
        # Safely handle empty responses
        raw_text = sql_response.text if sql_response.text else "NOT_SQL"
        sql_query = raw_text.strip().replace("```sql", "").replace("```", "")
        
        # 2. Only execute if it's an actual SQL query
        if sql_query == "NOT_SQL" or not sql_query.upper().startswith("SELECT"):
            raw_data = "No database query needed. The user is just chatting."
        else:
            try:
                result = db.execute(text(sql_query)).fetchall()
                if not result:
                    raw_data = "The query returned no results."
                else:
                    raw_data = str([dict(row._mapping) for row in result])
            except Exception as db_err:
                raw_data = f"Database execution failed: {db_err}"
        
        # 3. Generate the final conversational answer
        human_prompt = f"User asked: '{user_query}'. Database context: {raw_data}. Write a friendly conversational answer."
        
        final_response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=human_prompt
        )
        
        return {"ai_answer": final_response.text}
        
    except Exception as e:
        print(f"--- AI DEBUG ERROR ---: {e}")
        return {"error": str(e), "message": "The AI encountered an issue processing the data."}