import joblib
import numpy as np
from pathlib import Path
from typing import Dict, Any
from sqlalchemy.orm import Session
from sqlalchemy import func
import models

class MLService:
    def __init__(self):
        self.model = None
        self.scaler = None
        # ml_service.py is in backend/, models are in backend/ml_models/
        self.model_path = Path(__file__).parent / "ml_models" / "best_model.pkl"
        self.scaler_path = Path(__file__).parent / "ml_models" / "feature_scaler.pkl"
        
        self.subject_model_path = Path(__file__).parent / "ml_models" / "subject_model.pkl"
        self.subject_scaler_path = Path(__file__).parent / "ml_models" / "subject_scaler.pkl"
        
        self.subject_model = None
        self.subject_scaler = None
        self.load_model()
    
    def load_model(self):
        """Load the trained model and scaler"""
        try:
            if self.model_path.exists():
                self.model = joblib.load(self.model_path)
                print("ML model loaded successfully")
            else:
                print("Warning: ML model not found. Please train the model first.")
            
            if self.scaler_path.exists():
                self.scaler = joblib.load(self.scaler_path)
                print("Feature scaler loaded successfully")
                
            if self.subject_model_path.exists():
                self.subject_model = joblib.load(self.subject_model_path)
                print("Subject ML model loaded successfully")
            if self.subject_scaler_path.exists():
                self.subject_scaler = joblib.load(self.subject_scaler_path)
                print("Subject feature scaler loaded successfully")
                
        except Exception as e:
            print(f"Error loading model: {e}")
    
    def get_student_model(self, dept: str):
        dept = dept.upper()
        if dept == 'CSE': return models.StudentCSE
        elif dept == 'ECE': return models.StudentECE
        elif dept == 'EEE': return models.StudentEEE
        elif dept == 'MECH': return models.StudentMECH
        elif dept == 'CIVIL': return models.StudentCIVIL
        elif dept == 'BIO': return models.StudentBIO
        elif dept == 'AIDS': return models.StudentAIDS
        return None

    def extract_features(self, db: Session, reg_no: str) -> Dict[str, float]:
        """Extract features for a student"""
        # Find student across all dept tables using reg_no
        student = None
        for model in [models.StudentCSE, models.StudentECE, models.StudentEEE, models.StudentMECH, models.StudentCIVIL, models.StudentBIO, models.StudentAIDS]:
            student = db.query(model).filter(model.reg_no == reg_no).first()
            if student:
                break
        
        if not student:
            return {
                'attendance_percentage': 0,
                'internal_avg': 0,
                'external_gpa': 0,
                'activity_count': 0,
                'backlog_count': 0,
                'credit_weighted_internal_avg': 0,
                'high_credit_low_score_count': 0
            }
        
        # reg_no is already available


        # Get attendance percentage
        total_days = db.query(models.Attendance).filter(
            models.Attendance.reg_no == reg_no
        ).count()
        
        present_days = db.query(models.Attendance).filter(
            models.Attendance.reg_no == reg_no,
            models.Attendance.status.in_(['Present', 'P', 'OD'])
        ).count()
        
        avg_attendance = (present_days / total_days * 100) if total_days > 0 else 0
        
        # Get internal marks average (Using all available components)
        # Calculate subject-wise internal marks and then average them
        marks = db.query(models.Mark).filter(
            models.Mark.reg_no == reg_no
        ).all()
        
        total_internal_percentage = 0
        subject_count = 0
        
        for mark in marks:
            # Skip lab subjects from dragging down the overall internal average
            subject = db.query(models.Subject).filter(
                func.lower(models.Subject.subject_code) == mark.subject_code.lower()
            ).first()
            if subject and subject.category == 'LAB':
                continue
                
            # Calculate Internal 1
            st1, st2 = float(mark.slip_test_1 or 0), float(mark.slip_test_2 or 0)
            a1, a2 = float(mark.assignment_1 or 0), float(mark.assignment_2 or 0)
            cia1 = float(mark.cia_1 or 0)
            
            # Check if Internal 1 has any data
            has_int1 = (st1 + st2 + a1 + a2 + cia1) > 0
            int1_score = 0
            if has_int1:
                # Only average over tests that were actually entered (non-zero)
                st1_vals = [v for v in [st1, st2] if v > 0]
                st_avg1 = sum(st1_vals) / len(st1_vals) if st1_vals else 0
                a1_vals = [v for v in [a1, a2] if v > 0]
                assign_avg1 = sum(a1_vals) / len(a1_vals) if a1_vals else 0
                raw_int1 = (0.3 * st_avg1) + (0.2 * assign_avg1) + (0.5 * cia1)
                
                # Dynamic max based on what's available: ST=20, Assign=10, CIA=60
                max_int1 = (0.3 * 20 if st1_vals else 0) + (0.2 * 10 if a1_vals else 0) + (0.5 * 60 if cia1 > 0 else 0)
                int1_score = (raw_int1 / max_int1) * 100 if max_int1 > 0 else 0
            
            # Calculate Internal 2
            st3, st4 = float(mark.slip_test_3 or 0), float(mark.slip_test_4 or 0)
            a3, a4, a5 = float(mark.assignment_3 or 0), float(mark.assignment_4 or 0), float(mark.assignment_5 or 0)
            cia2 = float(mark.cia_2 or 0)
            model = float(mark.model or 0)
            
            has_int2 = (st3 + st4 + a3 + a4 + a5 + cia2 + model) > 0
            int2_score = 0
            if has_int2:
                # Only average over tests that were actually entered (non-zero)
                st2_vals = [v for v in [st3, st4] if v > 0]
                st_avg2 = sum(st2_vals) / len(st2_vals) if st2_vals else 0
                a2_vals = [v for v in [a3, a4, a5] if v > 0]
                assign_avg2 = sum(a2_vals) / len(a2_vals) if a2_vals else 0
                raw_int2 = (0.25 * st_avg2) + (0.15 * assign_avg2) + (0.3 * cia2) + (0.3 * model)
                
                # Dynamic max based on what's available: ST=20, Assign=10, CIA=60, Model=100
                max_int2 = (0.25 * 20 if st2_vals else 0) + (0.15 * 10 if a2_vals else 0) + (0.3 * 60 if cia2 > 0 else 0) + (0.3 * 100 if model > 0 else 0)
                int2_score = (raw_int2 / max_int2) * 100 if max_int2 > 0 else 0
                
            # Final Subject Internal Calculation
            if has_int1 and has_int2:
                final_subject_internal = (0.4 * int1_score) + (0.6 * int2_score)
            elif has_int1:
                final_subject_internal = int1_score
            elif has_int2:
                final_subject_internal = int2_score
            else:
                final_subject_internal = 0
                
            if has_int1 or has_int2:
                total_internal_percentage += final_subject_internal
                subject_count += 1
                
        internal_avg = (total_internal_percentage / subject_count) if subject_count > 0 else 0
        
        # Calculate external GPA (Simplified based on grades)
        # O=10, A+=9, A=8, B+=7, B=6, C=5, F/AREAR=0
        grades = db.query(models.Mark.university_result_grade).filter(
            models.Mark.reg_no == reg_no
        ).all()
        
        total_points = 0
        count = 0
        backlog_count = 0
        
        grade_map = {'O': 10, 'A+': 9, 'A': 8, 'B+': 7, 'B': 6, 'C': 5}
        
        for g in grades:
            grade = g[0]
            if grade in grade_map:
                total_points += grade_map[grade]
                count += 1
            elif grade == 'AREAR' or grade == 'F':
                backlog_count += 1
                count += 1
                
        external_gpa = total_points / count if count > 0 else 0
        
        # Count activities
        # Note: ActivityParticipation.student_id was renamed to reg_no in models.py
        activity_count = db.query(func.count(models.ActivityParticipation.participation_id)).filter(
            models.ActivityParticipation.reg_no == reg_no
        ).scalar() or 0
        
        # Feature 4-5: Credit-weighted internal average using subjects table
        credit_weighted_internal_avg = 0
        high_credit_low_score_count = 0
        total_weighted_score = 0
        total_credits = 0

        for mark in marks:
            # Skip lab subjects from dragging down the credit-weighted internal average
            subject = db.query(models.Subject).filter(
                func.lower(models.Subject.subject_code) == mark.subject_code.lower()
            ).first()
            if subject and subject.category == 'LAB':
                continue
                
            has_data = False
            # Re-compute per-subject internal score for credit weighting
            st1, st2 = float(mark.slip_test_1 or 0), float(mark.slip_test_2 or 0)
            a1, a2 = float(mark.assignment_1 or 0), float(mark.assignment_2 or 0)
            cia1_ = float(mark.cia_1 or 0)
            has_i1 = (st1 + st2 + a1 + a2 + cia1_) > 0
            i1 = 0
            if has_i1:
                _st1v = [v for v in [st1, st2] if v > 0]
                _a1v = [v for v in [a1, a2] if v > 0]
                raw_i1 = (0.3 * (sum(_st1v)/len(_st1v) if _st1v else 0)) + (0.2 * (sum(_a1v)/len(_a1v) if _a1v else 0)) + (0.5 * cia1_)
                max_i1 = (0.3 * 20 if _st1v else 0) + (0.2 * 10 if _a1v else 0) + (0.5 * 60 if cia1_ > 0 else 0)
                i1 = (raw_i1 / max_i1) * 100 if max_i1 > 0 else 0

            st3, st4 = float(mark.slip_test_3 or 0), float(mark.slip_test_4 or 0)
            a3_, a4_, a5_ = float(mark.assignment_3 or 0), float(mark.assignment_4 or 0), float(mark.assignment_5 or 0)
            cia2_ = float(mark.cia_2 or 0)
            mdl = float(mark.model or 0)
            has_i2 = (st3 + st4 + a3_ + a4_ + a5_ + cia2_ + mdl) > 0
            i2 = 0
            if has_i2:
                _st2v = [v for v in [st3, st4] if v > 0]
                _a2v = [v for v in [a3_, a4_, a5_] if v > 0]
                raw_i2 = (0.25*(sum(_st2v)/len(_st2v) if _st2v else 0))+(0.15*(sum(_a2v)/len(_a2v) if _a2v else 0))+(0.3*cia2_)+(0.3*mdl)
                max_i2 = (0.25 * 20 if _st2v else 0) + (0.15 * 10 if _a2v else 0) + (0.3 * 60 if cia2_ > 0 else 0) + (0.3 * 100 if mdl > 0 else 0)
                i2 = (raw_i2 / max_i2) * 100 if max_i2 > 0 else 0

            if has_i1 and has_i2:
                subj_score = 0.4 * i1 + 0.6 * i2
                has_data = True
            elif has_i1:
                subj_score = i1
                has_data = True
            elif has_i2:
                subj_score = i2
                has_data = True
            else:
                subj_score = 0

            if has_data:
                # Look up credit from subjects table
                subj_record = db.query(models.Subject).filter(
                    models.Subject.subject_code == mark.subject_code
                ).first()
                credit = float(subj_record.credits) if subj_record and subj_record.credits else 3.0  # default 3
                total_weighted_score += subj_score * credit
                total_credits += credit

                # Flag high-credit subjects with low scores
                if credit >= 4 and subj_score < 50:
                    high_credit_low_score_count += 1

        credit_weighted_internal_avg = (total_weighted_score / total_credits) if total_credits > 0 else internal_avg

        return {
            'attendance_percentage': avg_attendance,
            'internal_avg': internal_avg,
            'external_gpa': external_gpa,
            'activity_count': activity_count,
            'backlog_count': backlog_count,
            'credit_weighted_internal_avg': credit_weighted_internal_avg,
            'high_credit_low_score_count': high_credit_low_score_count
        }
    
    def predict_risk(self, db: Session, reg_no: str) -> Dict[str, Any]:
        """Predict academic risk for a student"""
        # Extract features
        features = self.extract_features(db, reg_no)
        
        # Get student's global preference
        student_pref = None
        for model in [models.StudentCSE, models.StudentECE, models.StudentEEE, models.StudentMECH, models.StudentCIVIL, models.StudentBIO, models.StudentAIDS]:
            student = db.query(model).filter(model.reg_no == reg_no).first()
            if student:
                student_pref = student.learning_path_preference
                break

        # Create feature array
        feature_array = np.array([[
            features['attendance_percentage'],
            features['internal_avg'],
            features['external_gpa'],
            features['activity_count'],
            features['backlog_count']
        ]])
        
        # If model is not loaded, use rule-based prediction
        if self.model is None or self.scaler is None:
            return self._rule_based_prediction(features, student_pref)
        
        # Scale features
        feature_scaled = self.scaler.transform(feature_array)
        
        # Predict
        prediction = self.model.predict(feature_scaled)[0]
        probability = self.model.predict_proba(feature_scaled)[0]
        
        # Map prediction to risk level
        risk_level_map = {0: "Low", 1: "Medium", 2: "High"}
        risk_level = risk_level_map.get(prediction, "Medium")
        
        # Calculate risk score (0-100)
        risk_score = probability[prediction] * 100
        
        # Generate reasons
        reasons = self._generate_reasons(features)
        
        return {
            'risk_level': risk_level,
            'risk_score': risk_score,
            'reasons': reasons,
            'learning_path_preference': student_pref,
            **features
        }
    
    def _rule_based_prediction(self, features: Dict[str, float], student_pref: str = None) -> Dict[str, Any]:
        """Fallback rule-based prediction when model is not available"""
        risk_score = 0
        reasons = []
        
        # Attendance check
        if features['attendance_percentage'] < 75:
            risk_score += 30
            reasons.append(f"Low attendance: {features['attendance_percentage']:.1f}%")
        elif features['attendance_percentage'] < 85:
            risk_score += 15
        
        # Internal marks check
        if features['internal_avg'] < 50:
            risk_score += 25
            reasons.append(f"Low internal marks: {features['internal_avg']:.1f}")
        elif features['internal_avg'] < 70:
            risk_score += 10
        
        # External GPA check
        if features['external_gpa'] < 5:
            risk_score += 25
            reasons.append(f"Low GPA: {features['external_gpa']:.1f}")
        elif features['external_gpa'] < 7:
            risk_score += 10
        
        # Activity participation
        if features['activity_count'] == 0:
            risk_score += 10
            reasons.append("No extracurricular activities")
        
        # Backlogs
        if features['backlog_count'] > 0:
            risk_score += features['backlog_count'] * 10
            reasons.append(f"{features['backlog_count']} backlog(s)")
        
        # Credit-weighted checks (Features 4-5)
        cw_avg = features.get('credit_weighted_internal_avg', features['internal_avg'])
        if cw_avg < 50:
            risk_score += 10
            reasons.append(f"Low credit-weighted avg: {cw_avg:.1f}")

        hc_low = features.get('high_credit_low_score_count', 0)
        if hc_low > 0:
            risk_score += hc_low * 8
            reasons.append(f"{int(hc_low)} high-credit subject(s) at risk")

        # Determine risk level
        if risk_score >= 60:
            risk_level = "High"
        elif risk_score >= 30:
            risk_level = "Medium"
        else:
            risk_level = "Low"
            if not reasons:
                reasons.append("Good academic performance")
        
        return {
            'risk_level': risk_level,
            'risk_score': min(risk_score, 100),
            'reasons': "; ".join(reasons) if reasons else "Good performance",
            'learning_path_preference': student_pref,
            **features
        }
    
    def _generate_reasons(self, features: Dict[str, float]) -> str:
        """Generate human-readable reasons for the prediction"""
        reasons = []
        
        if features['attendance_percentage'] < 75:
            reasons.append(f"Low attendance ({features['attendance_percentage']:.1f}%)")
        if features['internal_avg'] < 60:
            reasons.append(f"Low internal marks ({features['internal_avg']:.1f})")
        if features['external_gpa'] < 6:
            reasons.append(f"Low GPA ({features['external_gpa']:.1f})")
        if features['activity_count'] == 0:
            reasons.append("No extracurricular activities")
        if features['backlog_count'] > 0:
            reasons.append(f"{features['backlog_count']} backlog(s)")
        hc_low = features.get('high_credit_low_score_count', 0)
        if hc_low > 0:
            reasons.append(f"{int(hc_low)} high-credit subject(s) struggling")
        
        if not reasons:
            reasons.append("Good overall performance")
        
        return "; ".join(reasons)

    def save_prediction(self, db: Session, reg_no: str, prediction_result: Dict[str, Any]):
        """Save prediction result to database"""
        try:
            db_prediction = models.RiskPrediction(
                reg_no=reg_no,
                risk_level=prediction_result['risk_level'],
                risk_score=prediction_result['risk_score'],
                attendance_percentage=prediction_result['attendance_percentage'],
                internal_avg=prediction_result['internal_avg'],
                external_gpa=prediction_result['external_gpa'],
                activity_count=prediction_result['activity_count'],
                backlog_count=prediction_result['backlog_count'],
                reasons=prediction_result['reasons']
            )
            db.add(db_prediction)
            db.commit()
            db.refresh(db_prediction)
            print(f"Saved risk prediction for {reg_no}: {prediction_result['risk_level']} ({prediction_result['risk_score']:.1f}%)")
            return db_prediction
        except Exception as e:
            print(f"Error saving prediction for {reg_no}: {e}")
            db.rollback()
            return None

    def calculate_subject_risk(self, db: Session, reg_no: str, subject_code: str) -> Dict[str, Any]:
        """Calculate risk specifically for a given subject"""
        # Case insensitive match for subject code
        mark = db.query(models.Mark).filter(
            models.Mark.reg_no == reg_no,
            func.lower(models.Mark.subject_code) == subject_code.lower()
        ).first()
        
        if not mark:
            return {'risk_level': 'Unknown', 'score': 0, 'basis': 'No Data'}
            
        # Check if it's a Lab paper
        subject = db.query(models.Subject).filter(
            func.lower(models.Subject.subject_code) == subject_code.lower()
        ).first()
        
        if subject and subject.category == 'LAB':
            # Lab papers don't have standard internals like slip tests/CIAs, so they look like 0 marks.
            # Skip ML prediction and assign Low risk automatically to prevent false positives.
            return {'risk_level': 'Low', 'score': 100, 'basis': 'Lab Practical (Skipped)'}
            
        # Internal 1
        st1, st2 = float(mark.slip_test_1 or 0), float(mark.slip_test_2 or 0)
        a1, a2 = float(mark.assignment_1 or 0), float(mark.assignment_2 or 0)
        cia1 = float(mark.cia_1 or 0)
        
        # Internal 2
        st3, st4 = float(mark.slip_test_3 or 0), float(mark.slip_test_4 or 0)
        a3, a4, a5 = float(mark.assignment_3 or 0), float(mark.assignment_4 or 0), float(mark.assignment_5 or 0)
        cia2 = float(mark.cia_2 or 0)
        model = float(mark.model or 0)
        
        # Attendance 
        # For simplicity in this demo, calculate an aggregate matching the student's overall attendance
        total_days = db.query(models.Attendance).filter(models.Attendance.reg_no == reg_no).count()
        present_days = db.query(models.Attendance).filter(models.Attendance.reg_no == reg_no, models.Attendance.status.in_(['Present', 'P', 'OD'])).count()
        attendance = (present_days / total_days * 100) if total_days > 0 else 0
            
        feature_array = np.array([[
            round(st1, 2), round(st2, 2), round(a1, 2), round(a2, 2), round(cia1, 2),
            round(st3, 2), round(st4, 2), round(a3, 2), round(a4, 2), round(a5, 2), round(cia2, 2), round(model, 2),
            round(attendance, 2)
        ]])
        
        # Robust Rule-based Calculation (Always calculate this first for verification)
        has_int1 = (st1 + st2 + a1 + a2 + cia1) > 0
        int1_score = 0
        if has_int1:
            _st1v = [v for v in [st1, st2] if v > 0]
            st_avg1 = sum(_st1v) / len(_st1v) if _st1v else 0
            _a1v = [v for v in [a1, a2] if v > 0]
            assign_avg1 = sum(_a1v) / len(_a1v) if _a1v else 0
            raw_int1 = (0.3 * st_avg1) + (0.2 * assign_avg1) + (0.5 * cia1)
            max_int1 = (0.3 * 20 if _st1v else 0) + (0.2 * 10 if _a1v else 0) + (0.5 * 60 if cia1 > 0 else 0)
            int1_score = (raw_int1 / max_int1) * 100 if max_int1 > 0 else 0
        
        has_int2 = (st3 + st4 + a3 + a4 + a5 + cia2 + model) > 0
        int2_score = 0
        if has_int2:
            _st2v = [v for v in [st3, st4] if v > 0]
            st_avg2 = sum(_st2v) / len(_st2v) if _st2v else 0
            _a2v = [v for v in [a3, a4, a5] if v > 0]
            assign_avg2 = sum(_a2v) / len(_a2v) if _a2v else 0
            raw_int2 = (0.25 * st_avg2) + (0.15 * assign_avg2) + (0.3 * cia2) + (0.3 * model)
            max_int2 = (0.25 * 20 if _st2v else 0) + (0.15 * 10 if _a2v else 0) + (0.3 * 60 if cia2 > 0 else 0) + (0.3 * 100 if model > 0 else 0)
            int2_score = (raw_int2 / max_int2) * 100 if max_int2 > 0 else 0
            
        if has_int1 and has_int2:
            final_rule_score = (0.4 * int1_score) + (0.6 * int2_score)
            basis_rule = "Rule-based: Full Data"
        elif has_int1:
            final_rule_score = int1_score
            basis_rule = "Rule-based: Internal 1 Only"
        elif has_int2:
            final_rule_score = int2_score
            basis_rule = "Rule-based: Internal 2 Only"
        else:
            final_rule_score = 0
            basis_rule = "Rule-based: No Data"

        if final_rule_score < 50:
            rule_risk = "High"
        elif final_rule_score < 65:
            rule_risk = "Medium"
        else:
            rule_risk = "Low"

        # ML Model Path
        if self.subject_model and self.subject_scaler and has_int1 and has_int2:
            # Only use ML if both internals have data, otherwise it's too biased by zeros
            scaled = self.subject_scaler.transform(feature_array)
            pred = self.subject_model.predict(scaled)[0]
            probability = self.subject_model.predict_proba(scaled)[0]
            
            risk_level_map = {0: "Low", 1: "Medium", 2: "High"}
            ml_risk = risk_level_map.get(pred, "Low")
            ml_score = probability[pred] * 100
            
            # If ML says High but Rule says Low (due to zeros), respect the rule
            if ml_risk == "High" and rule_risk == "Low":
                return {
                    'risk_level': rule_risk,
                    'score': final_rule_score,
                    'basis': f"{basis_rule} (ML Overridden)"
                }
                
            return {
                'risk_level': ml_risk,
                'score': ml_score,
                'basis': "ML Model (Logistic Regression)"
            }
        else:
            return {
                'risk_level': rule_risk,
                'score': final_rule_score,
                'basis': basis_rule
            }

# Singleton instance
ml_service = MLService()
