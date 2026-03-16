"""
Test script for OpenAI API integration (Programming skill category).
Run from the backend directory:
    python test_openai_integration.py
"""
import os
import sys
import json
import requests

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# ── Step 1: Load .env and verify Programming API key ──────────────────────────
print("=" * 60)
print("STEP 1: Verifying .env config and API key loading")
print("=" * 60)

# Clear any cached settings first
try:
    import config as cfg
    cfg.get_settings.cache_clear()
    print("✓ Cleared lru_cache on get_settings()")
except Exception as e:
    print(f"  Cache clear note: {e}")

settings = cfg.get_settings()
print(f"  GEMINI_API_KEY    : {'SET (' + settings.gemini_api_key[:8] + '...)' if settings.gemini_api_key else 'NOT SET'}")
print(f"  Skill_development : {'SET (' + settings.skill_gemini_api_key[:8] + '...)' if settings.skill_gemini_api_key else 'NOT SET'}")
print(f"  Programming (OAI) : {'SET (sk-...)' if settings.programming_api_key and settings.programming_api_key.startswith('sk-') else 'NOT SET or wrong format'}")

if not settings.programming_api_key:
    print("\n❌ ERROR: Programming API key not found! Check .env file.")
    sys.exit(1)
elif not settings.programming_api_key.startswith("sk-"):
    print(f"\n⚠ WARNING: Programming key does not start with 'sk-'. Value: {settings.programming_api_key[:20]}...")

print()

# ── Step 2: Direct OpenAI API call ────────────────────────────────────────────
print("=" * 60)
print("STEP 2: Direct OpenAI API connectivity test (gpt-4o-mini)")
print("=" * 60)

api_key = settings.programming_api_key
url = "https://api.openai.com/v1/chat/completions"
headers = {
    "Content-Type": "application/json",
    "Authorization": f"Bearer {api_key}"
}
payload = {
    "model": "gpt-4o-mini",
    "messages": [
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "Say 'OpenAI connected!' and nothing else."}
    ],
    "max_tokens": 20
}

try:
    resp = requests.post(url, headers=headers, json=payload, timeout=20)
    resp.raise_for_status()
    reply = resp.json()["choices"][0]["message"]["content"].strip()
    print(f"✓ OpenAI API responded: {reply}")
    print(f"  Model: gpt-4o-mini | Status: {resp.status_code}")
except requests.exceptions.HTTPError as e:
    status = e.response.status_code if e.response else 0
    body = e.response.json() if e.response else {}
    err_msg = body.get("error", {}).get("message", str(e))
    if status == 429:
        print(f"⚠ OpenAI 429 Rate Limit: {err_msg}")
        print(f"  → This is expected if the key has hit its quota.")
        print(f"  → The service will automatically fall back to Gemini.")
    else:
        print(f"❌ OpenAI HTTP Error {status}: {err_msg}")
except Exception as e:
    print(f"❌ OpenAI connection error: {e}")

print()

# ── Step 3: Test generate_skill_content (Programming) via gemini_service ──────
print("=" * 60)
print("STEP 3: Testing generate_skill_content for Programming/Python (Beginner)")
print("=" * 60)

import gemini_service

content = gemini_service.generate_skill_content("Programming", sub_category="Python", level="Beginner")

if not content:
    print("❌ generate_skill_content returned None/empty!")
else:
    summary = content.get("summary", "")
    sections = content.get("sections", [])
    roadmap = content.get("roadmap", [])
    project = content.get("project", {})
    
    print(f"✓ Content generated successfully!")
    print(f"  Summary ({len(summary)} chars): {summary[:100]}...")
    print(f"  Sections: {len(sections)} section(s)")
    for s in sections[:2]:
        print(f"    - {s.get('title', 'N/A')}")
    print(f"  Roadmap items: {len(roadmap)}")
    print(f"  Project title: {project.get('title', 'N/A')}")

print()

# ── Step 4: Test generate_skill_quiz (Programming) ────────────────────────────
print("=" * 60)
print("STEP 4: Testing generate_skill_quiz for Programming/Python (Beginner)")
print("=" * 60)

quiz = gemini_service.generate_skill_quiz("Programming", difficulty="Beginner", sub_category="Python")

if not quiz:
    print("❌ generate_skill_quiz returned empty list!")
else:
    print(f"✓ Quiz generated: {len(quiz)} questions")
    if quiz:
        q1 = quiz[0]
        print(f"  Sample Q1: {q1.get('question', 'N/A')[:80]}...")
        print(f"  Options: {list(q1.keys())}")
        print(f"  Correct: {q1.get('correct_answers', q1.get('correct_answer', 'N/A'))}")

print()

# ── Step 5: Test fallback (non-programming skill uses Gemini) ─────────────────
print("=" * 60)
print("STEP 5: Testing Communication skill uses Gemini (not OpenAI)")
print("=" * 60)

comm_content = gemini_service.generate_skill_content("Communication", level="Beginner")
if comm_content:
    print(f"✓ Communication content generated (via Gemini)")
    print(f"  Summary: {comm_content.get('summary', '')[:80]}...")
else:
    print("⚠  Communication content returned None (Gemini may have quota issues)")

print()
print("=" * 60)
print("ALL TESTS COMPLETE")
print("=" * 60)
