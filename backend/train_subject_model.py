import os
import joblib
import pandas as pd
import numpy as np
import random
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import classification_report, accuracy_score
from pathlib import Path

# Set random seed for reproducibility
np.random.seed(42)
random.seed(42)

def generate_subject_synthetic_data(num_records=5000):
    """
    Generate synthetic data for an individual subject.
    Features: [st1, st2, a1, a2, cia1, st3, st4, a3, a4, a5, cia2, model_exam, attendance]
    Label: Risk (0=Low, 1=Medium, 2=High)
    """
    print(f"Generating synthetic subject-level data for {num_records} records...")
    
    data = []
    labels = []
    
    # Profiles
    profiles = [
        {"type": "Excellent", "prob": 0.2, "att_range": (90, 100), "study_factor": 1.2},
        {"type": "Good", "prob": 0.4, "att_range": (80, 95), "study_factor": 1.0},
        {"type": "Average", "prob": 0.3, "att_range": (65, 85), "study_factor": 0.8},
        {"type": "Struggling", "prob": 0.1, "att_range": (40, 75), "study_factor": 0.6},
    ]
    
    for _ in range(num_records):
        profile = np.random.choice(profiles, p=[p["prob"] for p in profiles])
        
        # Attendance
        attendance = random.uniform(*profile["att_range"])
        capability = (attendance / 100) * profile["study_factor"] + random.uniform(-0.1, 0.1)
        capability = max(0.1, min(1.0, capability))
        
        # INTERNAL 1
        st1 = min(20, max(0, random.normalvariate(20 * capability, 3)))
        st2 = min(20, max(0, random.normalvariate(20 * capability, 3)))
        a1 = min(10, max(0, random.normalvariate(10 * capability, 1.5)))
        a2 = min(10, max(0, random.normalvariate(10 * capability, 1.5)))
        cia1 = min(60, max(0, random.normalvariate(60 * capability, 8)))
        
        st_avg_1 = (st1 + st2) / 2
        assign_avg_1 = (a1 + a2) / 2
        internal_1_raw = (0.3 * st_avg_1) + (0.2 * assign_avg_1) + (0.5 * cia1)
        internal_1_norm = (internal_1_raw / 38) * 100
        
        # INTERNAL 2
        change = random.uniform(-0.1, 0.15) 
        capability_2 = max(0.1, min(1.0, capability + change))
        st3 = min(20, max(0, random.normalvariate(20 * capability_2, 3)))
        st4 = min(20, max(0, random.normalvariate(20 * capability_2, 3)))
        a3 = min(10, max(0, random.normalvariate(10 * capability_2, 1.5)))
        a4 = min(10, max(0, random.normalvariate(10 * capability_2, 1.5)))
        a5 = min(10, max(0, random.normalvariate(10 * capability_2, 1.5)))
        cia2 = min(60, max(0, random.normalvariate(60 * capability_2, 8)))
        model_exam = min(100, max(0, random.normalvariate(100 * capability_2, 12)))
        
        st_avg_2 = (st3 + st4) / 2
        assign_avg_2 = (a3 + a4 + a5) / 3
        internal_2_raw = (0.25 * st_avg_2) + (0.15 * assign_avg_2) + (0.3 * cia2) + (0.3 * model_exam)
        internal_2_norm = (internal_2_raw / 54.5) * 100
        
        # FINAL SCORE logic mimicking actual backend evaluation
        final_score = (0.4 * internal_1_norm) + (0.6 * internal_2_norm)
        
        # Assign strict rules for labeling
        if final_score < 50:
            label = 2  # High
        elif final_score < 65:
            label = 1  # Medium
        else:
            label = 0  # Low
            
        row = [
            round(st1, 2), round(st2, 2), round(a1, 2), round(a2, 2), round(cia1, 2),
            round(st3, 2), round(st4, 2), round(a3, 2), round(a4, 2), round(a5, 2), round(cia2, 2), round(model_exam, 2),
            round(attendance, 2)
        ]
        
        data.append(row)
        labels.append(label)
        
    return np.array(data), np.array(labels)

def train_subject_model():
    print("=" * 60)
    print("  EduPulse — Subject-Level LR Model Training Pipeline")
    print("=" * 60)
    
    X, y = generate_subject_synthetic_data(5000)
    
    print(f"\nDataset shape: {X.shape}")
    unique, counts = np.unique(y, return_counts=True)
    label_names = {0: "Low", 1: "Medium", 2: "High"}
    for u, c in zip(unique, counts):
        print(f"  {label_names[u]} Risk ({u}): {c} samples ({c/len(y)*100:.1f}%)")
    
    # Split
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )
    
    # Scale
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)
    
    # Train Logistic Regression
    print("\nTraining Logistic Regression...")
    model = LogisticRegression(solver='lbfgs', max_iter=1000, random_state=42)
    model.fit(X_train_scaled, y_train)
    
    y_pred = model.predict(X_test_scaled)
    acc = accuracy_score(y_test, y_pred)
    
    print(f"\nAccuracy: {acc:.4f} ({acc*100:.1f}%)")
    print("\nClassification Report:")
    print(classification_report(y_test, y_pred, target_names=["Low Risk", "Medium Risk", "High Risk"]))
    
    output_dir = Path("ml_models")
    output_dir.mkdir(exist_ok=True)
    
    # Save Model
    # Since Logistic Regression is strict, we'll save it as subject_model.pkl
    joblib.dump(model, output_dir / "subject_model.pkl")
    joblib.dump(scaler, output_dir / "subject_scaler.pkl")
    
    print(f"\nSaved model to ml_models/subject_model.pkl")
    print(f"Saved scaler to ml_models/subject_scaler.pkl")
    print("Training Complete ✅")

if __name__ == "__main__":
    train_subject_model()
