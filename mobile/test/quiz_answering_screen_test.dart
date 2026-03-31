import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/models.dart';
import 'package:mobile/screens/quiz_answering_screen.dart';

void main() {
  group('QuizAnsweringScreen Tests', () {
    late Quiz testQuiz;

    setUp(() {
      // Create test quiz with all three question types
      testQuiz = Quiz(
        subject: 'Mathematics',
        unit: 1,
        riskLevel: 'Medium',
        totalQuestions: 3,
        questions: [
          // MCQ Question
          QuizQuestion(
            id: 1,
            question: 'What is 2 + 2?',
            optionA: '3',
            optionB: '4',
            optionC: '5',
            optionD: '6',
            correctAnswer: 'Option B',
            difficultyLevel: 'Easy',
            questionType: 'MCQ',
          ),
          // MCS Question
          QuizQuestion(
            id: 2,
            question: 'Which of the following are prime numbers?',
            optionA: '2',
            optionB: '3',
            optionC: '4',
            optionD: '5',
            correctAnswer: 'Option A, Option B, Option D',
            difficultyLevel: 'Medium',
            questionType: 'MCS',
          ),
          // NAT Question
          QuizQuestion(
            id: 3,
            question: 'What is the value of PI (3 decimal places)?',
            optionA: null,
            optionB: null,
            optionC: null,
            optionD: null,
            correctAnswer: '3.142',
            difficultyLevel: 'Hard',
            questionType: 'NAT',
          ),
        ],
      );
    });

    testWidgets('Quiz screen renders with all three question types',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuizAnsweringScreen(
            quiz: testQuiz,
            subject: 'Mathematics',
            unit: 1,
            riskLevel: 'Medium',
          ),
        ),
      );

      // Verify initial state
      expect(find.text('Quiz - Mathematics'), findsOneWidget);
      expect(find.text('Question 1 of 3'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('MCQ question displays radio buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuizAnsweringScreen(
            quiz: testQuiz,
            subject: 'Mathematics',
            unit: 1,
            riskLevel: 'Medium',
          ),
        ),
      );

      // Verify MCQ UI elements
      expect(find.text('Select one option:'), findsOneWidget);
      expect(find.text('MCQ - Single Answer'), findsOneWidget);
      expect(find.byType(Radio<String>), findsWidgets);
      expect(find.text('3'), findsWidgets); // Option A
      expect(find.text('4'), findsWidgets); // Option B
      expect(find.text('5'), findsWidgets); // Option C
      expect(find.text('6'), findsWidgets); // Option D
    });

    testWidgets('MCQ answer selection works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuizAnsweringScreen(
            quiz: testQuiz,
            subject: 'Mathematics',
            unit: 1,
            riskLevel: 'Medium',
          ),
        ),
      );

      // Tap option B (correct answer)
      await tester.tap(find.byType(Radio<String>).first);
      await tester.pump();

      // Verify chip shows 1 answer selected
      expect(find.text('1/3 answered'), findsOneWidget);
    });

    testWidgets('Navigation to MCS question works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuizAnsweringScreen(
            quiz: testQuiz,
            subject: 'Mathematics',
            unit: 1,
            riskLevel: 'Medium',
          ),
        ),
      );

      // Answer first question
      await tester.tap(find.byType(Radio<String>).first);
      await tester.pump();

      // Click Next
      await tester.tap(find.text('Next'));
      await tester.pump();

      // Verify we're on question 2 (MCS)
      expect(find.text('Question 2 of 3'), findsOneWidget);
      expect(find.text('Select all correct options:'), findsOneWidget);
      expect(find.text('MCS - Multiple Answers'), findsOneWidget);
    });

    testWidgets('MCS question displays checkboxes', (WidgetTester tester) async {
      // Navigate to MCS question first
      testQuiz = Quiz(
        subject: 'Mathematics',
        unit: 1,
        riskLevel: 'Medium',
        totalQuestions: 1,
        questions: [
          QuizQuestion(
            id: 2,
            question: 'Which of the following are prime numbers?',
            optionA: '2',
            optionB: '3',
            optionC: '4',
            optionD: '5',
            correctAnswer: 'Option A, Option B, Option D',
            difficultyLevel: 'Medium',
            questionType: 'MCS',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: QuizAnsweringScreen(
            quiz: testQuiz,
            subject: 'Mathematics',
            unit: 1,
            riskLevel: 'Medium',
          ),
        ),
      );

      // Verify MCS UI elements
      expect(find.text('Select all correct options:'), findsOneWidget);
      expect(find.text('MCS - Multiple Answers'), findsOneWidget);
      expect(find.byType(Checkbox), findsWidgets);
      expect(find.text('You must select all correct answers'), findsOneWidget);
    });

    testWidgets('MCS answer selection works', (WidgetTester tester) async {
      testQuiz = Quiz(
        subject: 'Mathematics',
        unit: 1,
        riskLevel: 'Medium',
        totalQuestions: 1,
        questions: [
          QuizQuestion(
            id: 2,
            question: 'Which of the following are prime numbers?',
            optionA: '2',
            optionB: '3',
            optionC: '4',
            optionD: '5',
            correctAnswer: 'Option A, Option B, Option D',
            difficultyLevel: 'Medium',
            questionType: 'MCS',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: QuizAnsweringScreen(
            quiz: testQuiz,
            subject: 'Mathematics',
            unit: 1,
            riskLevel: 'Medium',
          ),
        ),
      );

      // Select multiple options
      await tester.tap(find.byType(Checkbox).at(0)); // Option A
      await tester.pump();
      await tester.tap(find.byType(Checkbox).at(1)); // Option B
      await tester.pump();

      // Verify both are selected
      expect(find.text('1/1 answered'), findsOneWidget);
    });

    testWidgets('Navigation to NAT question works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuizAnsweringScreen(
            quiz: testQuiz,
            subject: 'Mathematics',
            unit: 1,
            riskLevel: 'Medium',
          ),
        ),
      );

      // Answer first two questions
      await tester.tap(find.byType(Radio<String>).first);
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pump();

      // Answer MCS
      await tester.tap(find.byType(Checkbox).at(0));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pump();

      // Verify we're on question 3 (NAT)
      expect(find.text('Question 3 of 3'), findsOneWidget);
      expect(find.text('Enter the numeric answer:'), findsOneWidget);
      expect(find.text('NAT - Numeric Answer'), findsOneWidget);
    });

    testWidgets('NAT question displays input field', (WidgetTester tester) async {
      testQuiz = Quiz(
        subject: 'Mathematics',
        unit: 1,
        riskLevel: 'Medium',
        totalQuestions: 1,
        questions: [
          QuizQuestion(
            id: 3,
            question: 'What is the value of PI (3 decimal places)?',
            optionA: null,
            optionB: null,
            optionC: null,
            optionD: null,
            correctAnswer: '3.142',
            difficultyLevel: 'Hard',
            questionType: 'NAT',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: QuizAnsweringScreen(
            quiz: testQuiz,
            subject: 'Mathematics',
            unit: 1,
            riskLevel: 'Medium',
          ),
        ),
      );

      // Verify NAT UI elements
      expect(find.text('Enter the numeric answer:'), findsOneWidget);
      expect(find.text('NAT - Numeric Answer'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Answer is evaluated with ±0.01 tolerance'), findsOneWidget);
    });

    testWidgets('NAT answer input works', (WidgetTester tester) async {
      testQuiz = Quiz(
        subject: 'Mathematics',
        unit: 1,
        riskLevel: 'Medium',
        totalQuestions: 1,
        questions: [
          QuizQuestion(
            id: 3,
            question: 'What is the value of PI?',
            optionA: null,
            optionB: null,
            optionC: null,
            optionD: null,
            correctAnswer: '3.142',
            difficultyLevel: 'Hard',
            questionType: 'NAT',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: QuizAnsweringScreen(
            quiz: testQuiz,
            subject: 'Mathematics',
            unit: 1,
            riskLevel: 'Medium',
          ),
        ),
      );

      // Enter numeric answer
      await tester.enterText(find.byType(TextField), '3.14');
      await tester.pump();

      // Verify answer was entered
      expect(find.text('1/1 answered'), findsOneWidget);
    });

    testWidgets('Navigation buttons work correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuizAnsweringScreen(
            quiz: testQuiz,
            subject: 'Mathematics',
            unit: 1,
            riskLevel: 'Medium',
          ),
        ),
      );

      // Previous button should be disabled on first question
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // Answer first question
      await tester.tap(find.byType(Radio<String>).first);
      await tester.pump();

      // Click Next
      await tester.tap(find.text('Next'));
      await tester.pump();

      // Now we should be on question 2
      expect(find.text('Question 2 of 3'), findsOneWidget);

      // Previous button should be enabled
      final previousButton = find.byIcon(Icons.arrow_back);
      expect(previousButton, findsOneWidget);

      // Click Previous
      await tester.tap(previousButton);
      await tester.pump();

      // Should be back on question 1
      expect(find.text('Question 1 of 3'), findsOneWidget);
    });

    testWidgets('Submit button is disabled when not on last question',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuizAnsweringScreen(
            quiz: testQuiz,
            subject: 'Mathematics',
            unit: 1,
            riskLevel: 'Medium',
          ),
        ),
      );

      // Should show Next button on first question
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Submit'), findsNothing);
    });

    testWidgets('Question type badge displays correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuizAnsweringScreen(
            quiz: testQuiz,
            subject: 'Mathematics',
            unit: 1,
            riskLevel: 'Medium',
          ),
        ),
      );

      // MCQ badge
      expect(find.text('MCQ - Single Answer'), findsOneWidget);

      // Navigate to next question
      await tester.tap(find.byType(Radio<String>).first);
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pump();

      // MCS badge
      expect(find.text('MCS - Multiple Answers'), findsOneWidget);

      // Navigate to next question
      await tester.tap(find.byType(Checkbox).at(0));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pump();

      // NAT badge
      expect(find.text('NAT - Numeric Answer'), findsOneWidget);
    });
  });
}
