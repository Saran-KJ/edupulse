# ML Model Training Guide

## Overview

This directory contains the machine learning pipeline for predicting student academic risk based on performance metrics.

## Files

- `generate_sample_data.py` - Generates synthetic training data
- `train_model.py` - Trains and evaluates ML models
- `requirements.txt` - Python dependencies for ML
- `training_data.csv` - Generated training dataset (created after running generate_sample_data.py)
- `best_model.pkl` - Saved best model (created after training)
- `feature_scaler.pkl` - Feature scaler (created after training)

## Setup

```bash
# Install dependencies
pip install -r requirements.txt
```

## Usage

### Step 1: Generate Training Data

```bash
python generate_sample_data.py
```

This creates `training_data.csv` with 500 synthetic student records containing:
- Attendance percentage
- Internal marks average
- External GPA
- Activity count
- Backlog count
- Risk level (target variable)

### Step 2: Train Models

```bash
python train_model.py
```

This script will:
1. Load the training data
2. Split into train/test sets (80/20)
3. Scale features using StandardScaler
4. Train three models:
   - Logistic Regression
   - Random Forest
   - XGBoost
5. Evaluate each model with:
   - Accuracy
   - F1 Score
   - Confusion Matrix
   - Cross-validation scores
6. Select the best model based on F1 score
7. Save the best model and scaler

### Output

The training script produces:
- Console output with detailed metrics
- Confusion matrix plots (PNG files)
- Feature importance plot (for tree-based models)
- `best_model.pkl` - Saved model
- `feature_scaler.pkl` - Saved scaler

## Model Features

### Input Features

1. **attendance_percentage** (0-100): Student's overall attendance
2. **internal_avg** (0-100): Average internal assessment marks
3. **external_gpa** (0-10): GPA from external exams
4. **activity_count** (0+): Number of extracurricular activities
5. **backlog_count** (0+): Number of failed subjects

### Output

- **risk_level**: Low (0), Medium (1), or High (2)
- **risk_score**: Probability score (0-100)
- **reasons**: Human-readable explanation

## Using the Model

The trained model is automatically loaded by the backend API (`backend/ml_service.py`).

To use it manually:

```python
import joblib
import numpy as np

# Load model and scaler
model = joblib.load('best_model.pkl')
scaler = joblib.load('feature_scaler.pkl')

# Prepare features
features = np.array([[
    85.0,  # attendance_percentage
    75.0,  # internal_avg
    7.5,   # external_gpa
    3,     # activity_count
    0      # backlog_count
]])

# Scale and predict
features_scaled = scaler.transform(features)
prediction = model.predict(features_scaled)[0]
probability = model.predict_proba(features_scaled)[0]

print(f"Risk Level: {prediction}")  # 0=Low, 1=Medium, 2=High
print(f"Probabilities: {probability}")
```

## Customization

### Using Real Data

Replace `generate_sample_data.py` with your actual student data:

```python
import pandas as pd

# Load your data
df = pd.read_csv('your_student_data.csv')

# Ensure columns: attendance_percentage, internal_avg, external_gpa, 
#                 activity_count, backlog_count, risk_level

# Save for training
df.to_csv('training_data.csv', index=False)
```

### Tuning Hyperparameters

Modify `train_model.py` to adjust model parameters:

```python
# Example: Random Forest with more trees
models = {
    'Random Forest': RandomForestClassifier(
        n_estimators=200,  # Increase trees
        max_depth=10,      # Limit depth
        random_state=42
    )
}
```

## Model Performance

Expected performance on synthetic data:
- Accuracy: ~85-95%
- F1 Score: ~0.85-0.95
- Cross-validation: ~0.80-0.90

Performance may vary with real-world data. Consider:
- Collecting more training samples
- Feature engineering (e.g., attendance trends, mark improvements)
- Handling class imbalance if needed
- Regular model retraining with new data

## Troubleshooting

### Issue: Low accuracy

**Solutions**:
- Collect more training data
- Check for data quality issues
- Try different feature combinations
- Adjust model hyperparameters

### Issue: Overfitting

**Solutions**:
- Increase training data
- Use cross-validation
- Add regularization
- Reduce model complexity

### Issue: Class imbalance

**Solutions**:
- Use SMOTE for oversampling
- Adjust class weights
- Use stratified sampling
