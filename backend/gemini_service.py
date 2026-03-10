import os
import json
import google.generativeai as genai
import config as cfg

def _call_gemini_with_fallback(prompt: str, is_json: bool = True):
    """
    Helper to call Gemini API with model fallback logic.
    """
    settings = cfg.get_settings()
    if not settings.gemini_api_key:
        print("Error: GEMINI_API_KEY not found in settings")
        return None
        
    genai.configure(api_key=settings.gemini_api_key)
    
    models_to_try = [
        'models/gemini-2.0-flash', 
        'models/gemini-1.5-flash', 
        'models/gemini-1.5-pro',
        'models/gemini-1.5-flash-latest'
    ]
    
    error_msgs = []
    for model_name in models_to_try:
        try:
            print(f"DEBUG: Trying Gemini model: {model_name}...")
            model = genai.GenerativeModel(model_name)
            gen_config = {"response_mime_type": "application/json"} if is_json else None
            response = model.generate_content(prompt, generation_config=gen_config)
            
            clean_text = response.text.strip()
            # Clean up markdown if model didn't obey json-only rule perfectly
            if clean_text.startswith("```json"):
                clean_text = clean_text[7:]
            elif clean_text.startswith("```"):
                clean_text = clean_text[3:]
            if clean_text.endswith("```"):
                clean_text = clean_text[:-3]
            
            data = json.loads(clean_text.strip()) if is_json else clean_text
            print(f"✓ Successfully called {model_name}")
            return data
        except Exception as e:
            error_msgs.append(f"{model_name}: {str(e)}")
            continue
    
    print(f"Gemini API Error: All models failed. {'; '.join(error_msgs)}")
    return None

def generate_quiz_questions(subject_name: str, unit_number: int, risk_level: str):
    """
    Generates quiz questions using Gemini API based on subject, unit, and risk level.
    """
    risk_level_upper = risk_level.upper()
    if risk_level_upper == "HIGH":
        num, diff = 20, "Basic"
    elif risk_level_upper == "MEDIUM":
        num, diff = 25, "Moderate"
    else:
        num, diff = 30, "Advanced"
        
    prompt = f"""
    Generate exactly {num} multiple choice quiz questions for "{subject_name}" Unit {unit_number}.
    Difficulty: {diff}. Syllabus relevant.
    Return output as JSON list of objects: {{"question", "option_a", "option_b", "option_c", "option_d", "correct_answer"}}.
    Return ONLY raw JSON list.
    """
    
    data = _call_gemini_with_fallback(prompt, is_json=True)
    if not data: return []
    
    if isinstance(data, list): return data
    if isinstance(data, dict) and "quiz" in data: return data["quiz"]
    return []

def generate_study_strategy(risk_level: str, subjects_summary: list, global_preference: str = None):
    """
    Generates an overall study strategy using Gemini based on a student's risk profile.
    """
    subjects_str = "\n".join([f"- {s['subject_title']} ({s['subject_code']}): {s['risk_level']} Risk" for s in subjects_summary])
    pref_str = f"Student Preference: {global_preference}" if global_preference else ""

    prompt = f"""
    Generate a personalized study strategy for a student with {risk_level} risk.
    Subjects Status:
    {subjects_str}
    {pref_str}

    Return JSON with:
    "recommendations": (list of strings)
    "time_allocation": (dict)
    Return ONLY raw JSON.
    """

    data = _call_gemini_with_fallback(prompt, is_json=True)
    if not data:
        return {"recommendations": ["Follow your subject-wise plans."], "time_allocation": {"General": "100%"}}
    return data

def generate_subject_plan(subject_title: str, risk_level: str, focus_type: str):
    """
    Generates a subject-specific practice schedule and weekly goals using Gemini.
    """
    prompt = f"""
    Generate a personalized learning plan for the subject "{subject_title}".
    Risk Level: {risk_level}
    Focus Type: {focus_type}

    Return JSON with:
    "practice_schedule": (list of objects with "day" and "task")
    "weekly_goals": (list of objects with "goal", "target", "unit")
    Return ONLY raw JSON.
    """

    data = _call_gemini_with_fallback(prompt, is_json=True)
    if not data: return None, None
    return data.get("practice_schedule"), data.get("weekly_goals")
