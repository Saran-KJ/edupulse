import os
import joblib
import pandas as pd
import numpy as np
import random
from xgboost import XGBClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import classification_report, accuracy_score
from pathlib import Path

# Set random seed for reproducibility
np.random.seed(42)
random.seed(42)

def calculate_grades(marks):
    """
    Simulate university grading based on marks (out of 100).
    O: 90-100 (10 pts)
    A+: 80-89 (9 pts)
    A: 70-79 (8 pts)
    B+: 60-69 (7 pts)
    B: 50-59 (6 pts)
    C: 40-49 (5 pts) -> Pass
    U: < 40 (0 pts) -> Arrear
    """
    points = []
    arrears = 0
    
    for mark in marks:
        if mark >= 90: points.append(10)
        elif mark >= 80: points.append(9)
        elif mark >= 70: points.append(8)
        elif mark >= 60: points.append(7)
        elif mark >= 50: points.append(6)
        elif mark >= 40: points.append(5) 
        else:
            points.append(0)
            arrears += 1
            
    gpa = sum(points) / len(points) if points else 0
    return gpa, arrears

def generate_synthetic_student_data(num_students=500):
    """
    Generates synthetic student data for 7 semesters with specific internal mark logic.
    """
    print(f"Generating synthetic data for {num_students} students...")
    
    data = []
    labels = []
    
    # Define student profiles to creating realistic clusters
    profiles = [
        {"type": "Excellent", "prob": 0.2, "att_range": (90, 100), "study_factor": 1.2},
        {"type": "Good", "prob": 0.4, "att_range": (80, 95), "study_factor": 1.0},
        {"type": "Average", "prob": 0.3, "att_range": (65, 85), "study_factor": 0.8},
        {"type": "Struggling", "prob": 0.1, "att_range": (40, 75), "study_factor": 0.6},
    ]
    
    for _ in range(num_students):
        profile = np.random.choice(profiles, p=[p["prob"] for p in profiles])
        
        # 1. Attendance
        attendance = random.uniform(*profile["att_range"])
        capability = (attendance / 100) * profile["study_factor"] + random.uniform(-0.1, 0.1)
        capability = max(0.1, min(1.0, capability))
        
        # INTERNAL 1 COMPONENTS
        st1 = min(20, max(0, random.normalvariate(20 * capability, 3)))
        st2 = min(20, max(0, random.normalvariate(20 * capability, 3)))
        a1 = min(10, max(0, random.normalvariate(10 * capability, 1.5)))
        a2 = min(10, max(0, random.normalvariate(10 * capability, 1.5)))
        cia1 = min(60, max(0, random.normalvariate(60 * capability, 8)))
        
        st_avg_1 = (st1 + st2) / 2
        assign_avg_1 = (a1 + a2) / 2
        internal_1_raw = (0.3 * st_avg_1) + (0.2 * assign_avg_1) + (0.5 * cia1)
        internal_1_norm = (internal_1_raw / 38) * 100
        
        # INTERNAL 2 COMPONENTS
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
        
        # FINAL INTERNAL MARK
        final_internal = (0.4 * internal_1_norm) + (0.6 * internal_2_norm)
        
        # UNIVERSITY EXAMS
        external_capability = (model_exam / 100) 
        subjects_marks = []
        for _ in range(6):
            mark = min(100, max(0, random.normalvariate(external_capability * 100, 10)))
            subjects_marks.append(mark)
            
        gpa, current_backlogs = calculate_grades(subjects_marks)
        
        prev_backlogs = 0
        if profile["type"] == "Struggling":
            prev_backlogs = random.randint(0, 5)
        elif profile["type"] == "Average":
            prev_backlogs = random.randint(0, 2)
        total_backlogs = prev_backlogs + current_backlogs
        
        if profile["type"] == "Excellent":
            activities = random.randint(2, 5)
        elif profile["type"] == "Good":
            activities = random.randint(1, 3)
        else:
            activities = random.randint(0, 1)
            
        # RISK LABELING RULES
        risk_score = 0
        
        if attendance < 75: risk_score += 40
        elif attendance < 80: risk_score += 15
            
        if final_internal < 50: risk_score += 40
        elif final_internal < 65: risk_score += 20
        
        if total_backlogs > 0: risk_score += (total_backlogs * 15)
        if activities == 0: risk_score += 5
            
        if risk_score >= 60: label = 2 # High
        elif risk_score >= 30: label = 1 # Medium
        else: label = 0 # Low
            
        row = [
            round(attendance, 2),
            round(final_internal, 2),
            round(gpa, 2),
            activities,
            total_backlogs
        ]
        
        data.append(row)
        labels.append(label)
        
    return np.array(data), np.array(labels)

def train_multiple_models():
    print("Starting Multi-Model Training Pipeline...")
    
    try:
        # 1. Generate Data
        X, y = generate_synthetic_student_data(500)
        
        print(f"Dataset shape: {X.shape}")
        
        # Split data
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
        
        # Scale features
        scaler = StandardScaler()
        X_train_scaled = scaler.fit_transform(X_train)
        X_test_scaled = scaler.transform(X_test)
        
        # 2. Define Models
        models = {
            "Logistic Regression": LogisticRegression(multi_class='multinomial', solver='lbfgs', max_iter=1000),
            "Random Forest": RandomForestClassifier(n_estimators=100, max_depth=10, random_state=42),
            "XGBoost": XGBClassifier(
                n_estimators=200, 
                learning_rate=0.05, 
                max_depth=6, 
                use_label_encoder=False, 
                eval_metric='mlogloss',
                objective='multi:softprob',
                num_class=3
            )
        }
        
        results = {}
        best_model_name = ""
        best_accuracy = 0
        best_model_obj = None
        
        output_dir = Path("ml_models")
        output_dir.mkdir(exist_ok=True)
        
        # 3. Train and Evaluate Loop
        print("\n--- Model Training & Evaluation ---")
        for name, model in models.items():
            print(f"\nTraining {name}...")
            model.fit(X_train_scaled, y_train)
            
            y_pred = model.predict(X_test_scaled)
            accuracy = accuracy_score(y_test, y_pred)
            results[name] = accuracy
            
            print(f"{name} Accuracy: {accuracy:.4f}")
            
            # Save individual model
            filename = f"model_{name.lower().replace(' ', '_')}.pkl"
            joblib.dump(model, output_dir / filename)
            
            if accuracy > best_accuracy:
                best_accuracy = accuracy
                best_model_name = name
                best_model_obj = model
        
        # 4. Save Best Model
        print(f"\n🏆 Best Model: {best_model_name} with {best_accuracy:.4f} accuracy")
        
        joblib.dump(best_model_obj, output_dir / "best_model.pkl")
        joblib.dump(scaler, output_dir / "feature_scaler.pkl")
        
        print(f"Updated ml_models/best_model.pkl with {best_model_name}")
        print("Training pipeline completed!")
        
    except Exception as e:
        print(f"An error occurred during training: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    train_multiple_models()
