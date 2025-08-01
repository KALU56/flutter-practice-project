import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/question_model.dart';

class QuizScreen extends StatefulWidget {
  final String category;
  const QuizScreen({super.key, required this.category});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Question> questions = [];
  int currentIndex = 0;
  int score = 0;
  bool answered = false;
  int? selectedAnswer;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  Future<void> loadQuestions() async {
    final jsonString = await rootBundle.loadString('assets/questions.json');
    final List<dynamic> jsonData = json.decode(jsonString);

    final loadedQuestions = jsonData
        .map((item) => Question.fromJson(item))
        .where((q) => q.category == widget.category)
        .toList();

    setState(() {
      questions = loadedQuestions;
      isLoading = false;
    });
  }

  void checkAnswer(int index) {
    if (answered) return;
    setState(() {
      selectedAnswer = index;
      answered = true;
      if (index == questions[currentIndex].correctIndex) {
        score++;
      }
    });
  }

  void nextQuestion() {
    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
        answered = false;
        selectedAnswer = null;
      });
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Quiz Completed! 🎉'),
          content: Text('Your score: $score / ${questions.length}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // back to categories
              },
              child: const Text('Back to Categories'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.category)),
        body: const Center(child: Text('No questions available for this category.')),
      );
    }

    final question = questions[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${currentIndex + 1} / ${questions.length}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 12),
            Text(
              question.questionText,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            /// 🔁 Answer Choices with Styling
            ...List.generate(question.options.length, (index) {
              bool isCorrect = index == question.correctIndex;
              bool isSelected = index == selectedAnswer;

              Color backgroundColor = Colors.deepPurple;
              Color borderColor = Colors.transparent;
              Color textColor = Colors.white;

              if (answered) {
                if (isCorrect) {
                  backgroundColor = Colors.green;
                  borderColor = Colors.green.shade700;
                } else if (isSelected && !isCorrect) {
                  backgroundColor = Colors.red;
                  borderColor = Colors.red.shade700;
                } else {
                  backgroundColor = Colors.grey.shade300;
                  textColor = Colors.black87;
                }
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: backgroundColor,
                    foregroundColor: textColor,
                    side: BorderSide(color: borderColor, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: answered ? null : () => checkAnswer(index),
                  child: Text(
                    question.options[index],
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              );
            }),

            const Spacer(),

            /// ➡️ Next or Finish Button
            if (answered)
              Center(
                child: ElevatedButton(
                  onPressed: nextQuestion,
                  child: Text(
                    currentIndex == questions.length - 1 ? 'Finish' : 'Next',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
