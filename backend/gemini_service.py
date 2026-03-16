import os
import json
import requests
import google.generativeai as genai
import config as cfg

# Sentinel to signal quota/rate-limit hit so caller can fall back to Gemini
_OPENAI_QUOTA_HIT = object()

def _call_ollama(prompt: str, is_json: bool, max_retries: int = 3):
    """
    Calls the local Ollama server (OpenAI-compatible API).
    Uses model and base URL from settings (default: qwen2.5:3b @ localhost:11434).
    """
    settings = cfg.get_settings()
    model = settings.ollama_model or "qwen2.5:3b"
    url = f"{settings.ollama_base_url}/api/chat"

    system_msg = "You are a professional technical educator and software engineer."
    if is_json:
        system_msg += " Return ONLY valid raw JSON. No markdown fences, no extra text."

    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": system_msg},
            {"role": "user",   "content": prompt}
        ],
        "stream": False,
    }
    if is_json:
        payload["format"] = "json"

    for attempt in range(max_retries):
        try:
            print(f"DEBUG: Calling Ollama ({model}) [Attempt {attempt + 1}/{max_retries}]...")
            resp = requests.post(url, json=payload, timeout=180)
            resp.raise_for_status()
            text = resp.json()["message"]["content"].strip()

            if not is_json:
                print(f"✓ Ollama ({model}) responded successfully")
                return text

            # Strip markdown fences if model added them anyway
            if text.startswith("```json"): text = text[7:]
            elif text.startswith("```"):    text = text[3:]
            if text.endswith("```"):        text = text[:-3]

            data = json.loads(text.strip())
            print(f"✓ Ollama ({model}) responded successfully")
            return data

        except requests.exceptions.ConnectionError:
            print("Ollama Error: Server not running. Start with 'ollama serve'.")
            return None
        except json.JSONDecodeError as e:
            print(f"Ollama JSON Error on attempt {attempt + 1}: {e}")
            if attempt == max_retries - 1:
                return None
            # Otherwise loop continues and retries
        except Exception as e:
            print(f"Ollama Error: {e}")
            return None
    return None

def _call_openai(prompt: str, is_json: bool, api_key: str):
    """
    Helper to call OpenAI API for keys starting with 'sk-'.
    Returns:
      - parsed data on success
      - _OPENAI_QUOTA_HIT sentinel on 429 / quota errors (triggers Gemini fallback)
      - None on other errors
    """
    url = "https://api.openai.com/v1/chat/completions"
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {api_key}"
    }
    # Using gpt-4o-mini as it's fast and cost-effective for these prompts
    payload = {
        "model": "gpt-4o-mini",
        "messages": [
            {"role": "system", "content": "You are a professional technical educator and software engineer."},
            {"role": "user", "content": prompt}
        ],
        "temperature": 0.7
    }
    if is_json:
        payload["response_format"] = {"type": "json_object"}

    try:
        print(f"DEBUG: Calling OpenAI (Project Key detected)...")
        response = requests.post(url, headers=headers, json=payload, timeout=60)

        # Detect quota / rate-limit before raise_for_status
        if response.status_code == 429:
            err_msg = response.json().get("error", {}).get("message", "Rate limit exceeded")
            print(f"⚠ OpenAI quota/rate-limit hit: {err_msg}. Falling back to Gemini...")
            return _OPENAI_QUOTA_HIT

        response.raise_for_status()
        result = response.json()
        text = result['choices'][0]['message']['content'].strip()
        
        # Clean markdown if present
        if text.startswith("```json"):
            text = text[7:]
        elif text.startswith("```"):
            text = text[3:]
        if text.endswith("```"):
            text = text[:-3]
            
        data = json.loads(text.strip()) if is_json else text
        print(f"✓ Successfully called OpenAI")
        return data
    except requests.exceptions.HTTPError as e:
        status = e.response.status_code if e.response is not None else 0
        err_body = e.response.json() if e.response is not None else {}
        err_msg = err_body.get("error", {}).get("message", str(e))
        if status == 429 or "quota" in err_msg.lower() or "rate limit" in err_msg.lower():
            print(f"⚠ OpenAI quota/rate-limit hit ({status}): {err_msg}. Falling back to Gemini...")
            return _OPENAI_QUOTA_HIT
        print(f"OpenAI HTTP Error {status}: {err_msg}")
        return None
    except Exception as e:
        print(f"OpenAI API Error: {str(e)}")
        return None

def _call_ai_service(prompt: str, is_json: bool = True, override_api_key: str = None):
    """
    Generic helper to call AI services (Gemini or OpenAI) with fallback logic.
    """
    settings = cfg.get_settings()
    
    # Priority: global gemini_api_key (especially if 'ollama') -> override_api_key -> secondary global
    keys_to_try = []
    
    # If the user explicitly set 'ollama' as the global key, force it to be absolute #1 priority
    if settings.gemini_api_key and settings.gemini_api_key.lower() == "ollama":
        keys_to_try.append(settings.gemini_api_key)
        
    if override_api_key and override_api_key not in keys_to_try:
        keys_to_try.append(override_api_key)
        
    if settings.gemini_api_key and settings.gemini_api_key not in keys_to_try:
        keys_to_try.append(settings.gemini_api_key)
    
    if not keys_to_try:
        print("Error: No AI API keys found in config")
        return None

    overall_errors = []
    
    for key_idx, api_key in enumerate(keys_to_try):
        if not api_key: continue
        
        key_label = "Primary" if key_idx == 0 else "Secondary"

        # Route to local Ollama if key is set to "ollama"
        if api_key.lower() == "ollama":
            data = _call_ollama(prompt, is_json)
            if data:
                return data
            overall_errors.append(f"{key_label}[Ollama]: Failed, falling back")
            continue

        # Route to OpenAI if key starts with sk-
        if api_key.startswith("sk-"):
            data = _call_openai(prompt, is_json, api_key)
            if data is _OPENAI_QUOTA_HIT:
                # Quota hit — skip OpenAI entirely and try Gemini keys below
                overall_errors.append(f"{key_label}[OpenAI]: Quota/Rate-limit hit, falling back")
                continue
            if data:
                return data
            overall_errors.append(f"{key_label}[OpenAI]: Failed")
            continue

        # Otherwise use Gemini
        genai.configure(api_key=api_key)
        models_to_try = [
            'models/gemini-flash-latest', 
            'models/gemini-2.0-flash',
            'models/gemini-1.5-flash',
            'models/gemini-pro-latest'
        ]
        
        for model_name in models_to_try:
            try:
                print(f"DEBUG: Trying {key_label} Key | Model: {model_name}...")
                model = genai.GenerativeModel(model_name)
                gen_config = {"response_mime_type": "application/json"} if is_json else None
                response = model.generate_content(prompt, generation_config=gen_config)
                
                clean_text = response.text.strip()
                if clean_text.startswith("```json"):
                    clean_text = clean_text[7:]
                elif clean_text.startswith("```"):
                    clean_text = clean_text[3:]
                if clean_text.endswith("```"):
                    clean_text = clean_text[:-3]
                
                data = json.loads(clean_text.strip()) if is_json else clean_text
                print(f"✓ Successfully called Gemini using {key_label} Key and {model_name}")
                return data
            except Exception as e:
                err_str = str(e)
                if "429" in err_str or "quota" in err_str.lower():
                    print(f"DEBUG: {key_label} Key hit quota limit. Switching...")
                    break 
                overall_errors.append(f"{key_label}[{model_name}]: {err_str[:50]}")
                continue
    
    return None

def generate_quiz_questions(subject_name: str, unit_number: int, risk_level: str):
    risk_level_upper = risk_level.upper()
    num, diff = (20, "Basic") if risk_level_upper == "HIGH" else (25, "Moderate") if risk_level_upper == "MEDIUM" else (30, "Advanced")
        
    prompt = f"""
    Generate exactly {num} multiple choice quiz questions for "{subject_name}" Unit {unit_number}.
    Difficulty: {diff}. Syllabus relevant.
    Return output as JSON list of objects: {{"question", "option_a", "option_b", "option_c", "option_d", "correct_answer"}}.
    Return ONLY raw JSON list.
    """
    data = _call_ai_service(prompt, is_json=True)
    return data if isinstance(data, list) else []

def generate_study_strategy(risk_level: str, subjects_summary: list, global_preference: str = None):
    subjects_str = "\n".join([f"- {s['subject_title']} ({s['subject_code']}): {s['risk_level']} Risk" for s in subjects_summary])
    prompt = f"Generate personalized study strategy for {risk_level} risk. Subjects:\n{subjects_str}\n{global_preference or ''}\nReturn JSON: {{'recommendations': [], 'time_allocation': {{}}}}"
    data = _call_ai_service(prompt, is_json=True)
    return data or {"recommendations": ["Focus on weak subjects."], "time_allocation": {"General": "100%"}}

def generate_subject_plan(subject_title: str, risk_level: str, focus_type: str):
    prompt = f"Generate learning plan for {subject_title}. Risk: {risk_level}. Focus: {focus_type}. Return JSON: {{'practice_schedule': [], 'weekly_goals': []}}"
    data = _call_ai_service(prompt, is_json=True)
    return (data.get("practice_schedule"), data.get("weekly_goals")) if data else (None, None)

def generate_skill_content(skill_category: str, sub_category: str = None, level: str = "Beginner") -> dict:
    level_instruction = ""
    topic = sub_category or skill_category
    skill_lower = skill_category.lower()

    if skill_lower == "programming":
        if level == "Beginner":
            level_instruction = f"Target: {topic}. LEVEL: BEGINNER. Focus ONLY on basic syntax, variables, basic loops, and primitive types. Do not include advanced concepts like decorators or concurrency."
        elif level == "Intermediate":
            level_instruction = f"Target: {topic}. LEVEL: INTERMEDIATE. Focus on OOP, file I/O, standard libraries, exception handling, and modular programming. Include design patterns."
        else:
            level_instruction = f"Target: {topic}. LEVEL: ADVANCED. Focus on architectural patterns, memory management, performance optimisation, concurrency, metaprogramming, and advanced language-specific features."

    elif skill_lower == "aptitude":
        if level == "Beginner":
            level_instruction = f"Target: {topic}. LEVEL: BEGINNER. Cover foundational topics only: basic arithmetic, percentages, ratios, simple time & work, and basic data interpretation. Use step-by-step explanations with examples."
        elif level == "Intermediate":
            level_instruction = f"Target: {topic}. LEVEL: INTERMEDIATE. Cover permutations & combinations, probability, profit & loss, time-speed-distance, and series completion. Include shortcut techniques."
        else:
            level_instruction = f"Target: {topic}. LEVEL: ADVANCED. Cover complex data sufficiency, advanced number theory, logical reasoning chains, critical path problems, and high-difficulty placement-level problems. Focus on speed and accuracy under pressure."

    elif skill_lower == "communication":
        if level == "Beginner":
            level_instruction = f"Target: {topic}. LEVEL: BEGINNER. Cover basics of verbal communication, body language, listening skills, and simple email writing. Practical exercises for everyday professional interaction."
        elif level == "Intermediate":
            level_instruction = f"Target: {topic}. LEVEL: INTERMEDIATE. Cover persuasive speaking, group discussion techniques, structured report writing, interview communication, and conflict resolution. Include real corporate scenarios."
        else:
            level_instruction = f"Target: {topic}. LEVEL: ADVANCED. Cover executive-level presentation, cross-cultural communication, negotiation strategies, crisis communication, and leading board-level discussions. Use case studies from industry leaders."

    elif skill_lower == "leadership":
        if level == "Beginner":
            level_instruction = f"Target: {topic}. LEVEL: BEGINNER. Cover self-awareness, time management, basic team dynamics, and responsibility. Focus on foundations of personal leadership."
        elif level == "Intermediate":
            level_instruction = f"Target: {topic}. LEVEL: INTERMEDIATE. Cover team motivation, delegation, conflict management, decision-making frameworks, and project ownership. Include practical leadership scenarios."
        else:
            level_instruction = f"Target: {topic}. LEVEL: ADVANCED. Cover transformational leadership, organisational strategy, change management, stakeholder influence, and building high-performance cultures. Use global leadership case studies."

    elif skill_lower == "critical thinking":
        if level == "Beginner":
            level_instruction = f"Target: {topic}. LEVEL: BEGINNER. Cover identifying assumptions, distinguishing facts from opinions, basic logical fallacies, and simple problem decomposition techniques."
        elif level == "Intermediate":
            level_instruction = f"Target: {topic}. LEVEL: INTERMEDIATE. Cover structured argumentation, causal analysis, bias identification, SWOT analysis, and evaluating evidence quality. Include real-world case problems."
        else:
            level_instruction = f"Target: {topic}. LEVEL: ADVANCED. Cover systems thinking, Socratic method, complex ethical dilemmas, adversarial thinking, and applying critical thinking to engineering and business decisions at scale."

    prompt = f"""
    Generate an elite technical learning guide for "{topic}".
    Audience: Senior Engineering Students. Level: {level}.
    {level_instruction}
    Return JSON format:
    {{
      "summary": "string",
      "sections": [{{"title": "string", "body": "string"}}],
      "roadmap": ["string"],
      "project": {{"title": "string", "objective": "string", "description": "string", "tech_stack": ["string"]}}
    }}
    Return ONLY the raw JSON.
    """
    settings = cfg.get_settings()
    override_key = settings.programming_api_key if skill_category.lower() == "programming" and settings.programming_api_key else settings.skill_gemini_api_key
    
    data = _call_ai_service(prompt, is_json=True, override_api_key=override_key)
    
    if not data:
        # Dynamic Fallback
        return {
            "summary": f"Mastering {topic} at {level} level.",
            "sections": [
                {"title": f"Introduction to {topic} ({level})", "body": f"This section covers the core technical aspects of {topic} at the {level} level, intended for senior engineering students..."},
                {"title": f"The Engineering Perspective on {topic}", "body": f"Focusing on real-world industrial implementation of {topic} concepts with {level} complexity..."}
            ],
            "roadmap": [f"Deep dive into {topic} {level} documentation"],
            "project": {
                "title": f"{topic} {level} Capstone",
                "objective": f"Apply {level} {topic} principles to build a functional prototype.",
                "description": f"A comprehensive project covering {level} concepts.",
                "tech_stack": [topic, "Standard Library"]
            }
        }
    return data

def generate_skill_quiz(skill_category: str, difficulty: str = "Intermediate", sub_category: str = None) -> list:
    topic = sub_category or skill_category
    prompt = f"""Generate exactly 20 multiple-choice quiz questions for "{topic}" at {difficulty} level.

STRICT RULES:
- Every question MUST have exactly 4 answer options labeled A, B, C, D.
- ALL questions must be type "MCQ". Do NOT generate open-ended or numerical-only questions.
- For math/aptitude questions, always provide 4 numerical choices to pick from.
- "correct_answers" must be a list with exactly one letter: ["A"], ["B"], ["C"], or ["D"].

Return a JSON list of exactly 20 objects. Each object must have:
- "question": string
- "type": "MCQ"
- "options": list of exactly 4 strings [optionA, optionB, optionC, optionD]
- "correct_answers": ["A"] or ["B"] or ["C"] or ["D"]
- "explanation": brief explanation string

Return ONLY the raw JSON list, no markdown, no extra text."""
    settings = cfg.get_settings()
    override_key = settings.programming_api_key if skill_category.lower() == "programming" and settings.programming_api_key else settings.skill_gemini_api_key
    
    data = _call_ai_service(prompt, is_json=True, override_api_key=override_key)
    return data if isinstance(data, list) else []
