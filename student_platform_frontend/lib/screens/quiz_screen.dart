import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class QuizScreen extends StatefulWidget {
  final TopicQuiz quiz;

  const QuizScreen({super.key, required this.quiz});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final ApiService _apiService = ApiService();
  List<TestQuestion> _questions = [];
  bool _isLoading = true;
  int _currentQuestionIndex = 0;
  Map<int, int> _userAnswers = {}; // QuestionID -> OptionID
  late Timer _timer;
  int _secondsRemaining = 0;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
    _secondsRemaining = widget.quiz.timeLimitMinutes * 60;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer.cancel();
        _submitQuiz();
      }
    });
  }

  Future<void> _fetchQuestions() async {
    final questions = await _apiService.getQuizQuestions(widget.quiz.id);
    setState(() {
      _questions = questions;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _submitQuiz() async {
    if (_isFinished) return;
    _timer.cancel();
    setState(() => _isFinished = true);

    final List<Map<String, dynamic>> answers = _userAnswers.entries.map((e) => {
      'questionId': e.key,
      'selectedOptionId': e.value,
    }).toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await _apiService.submitQuiz(widget.quiz.id, answers);
      if (mounted) {
        Navigator.pop(context); 
        _showResultDialog(result);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xatolik yuz berdi: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isFinished = false); // Allow retry
      }
    }
  }

  void _showResultDialog(Map<String, dynamic>? result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars, color: Colors.orange, size: 80),
              const SizedBox(height: 24),
              const Text('Test Yakunlandi!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('Sizning umumiy natijangiz:', style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.shade100)),
                child: Text(
                  '${result?['score'] ?? 0} %', 
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'To\'g\'ri javoblar: ${result?['correctCount'] ?? 0} / ${result?['totalQuestions'] ?? 0}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Return to topic content
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  child: const Text('OK', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_questions.isEmpty) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Savollar topilmadi.')));

    final currentQuestion = _questions[_currentQuestionIndex];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.quiz.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
        elevation: 0,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: _secondsRemaining < 60 ? Colors.red.shade50 : Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, color: _secondsRemaining < 60 ? Colors.red : Colors.indigo, size: 20),
                const SizedBox(width: 8),
                Text(
                  _formatTime(_secondsRemaining),
                  style: TextStyle(
                    color: _secondsRemaining < 60 ? Colors.red : Colors.indigo,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar Question Navigator (for larger screens) or top indicator
          Container(
            width: 280,
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Savollar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: _questions.length,
                    itemBuilder: (context, index) {
                      bool isCurrent = _currentQuestionIndex == index;
                      bool isAnswered = _userAnswers.containsKey(_questions[index].id);
                      
                      return InkWell(
                        onTap: () => setState(() => _currentQuestionIndex = index),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isCurrent 
                                ? Colors.indigo 
                                : (isAnswered ? Colors.green : Colors.transparent),
                            shape: BoxShape.circle,
                            border: Border.all(color: isAnswered ? Colors.green : Colors.grey.shade300, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: (isCurrent || isAnswered) ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitQuiz,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    child: const Text('Testni Yakunlash'),
                  ),
                ),
              ],
            ),
          ),
          
          // Question Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(widget.quiz.content, style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                      const SizedBox(height: 32),
                      
                      // Question Card
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (currentQuestion.imagePath != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 24),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    '${ApiService.baseUrl.replaceAll('/api', '')}${currentQuestion.imagePath}',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 300,
                                  ),
                                ),
                              ),
                            Text(
                              currentQuestion.title,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              currentQuestion.question,
                              style: const TextStyle(fontSize: 18, color: Colors.black87, height: 1.5),
                            ),
                            const SizedBox(height: 40),
                            
                            // Options
                            ...currentQuestion.options.map((opt) {
                              bool isSelected = _userAnswers[currentQuestion.id] == opt.id;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _userAnswers[currentQuestion.id] = opt.id;
                                    });
                                    // Auto-advance
                                    if (_currentQuestionIndex < _questions.length - 1) {
                                      Future.delayed(const Duration(milliseconds: 300), () {
                                        if (mounted) setState(() => _currentQuestionIndex++);
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.green.shade50 : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected ? Colors.green : Colors.grey.shade200,
                                        width: 2,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isSelected ? Colors.green : Colors.white,
                                            border: Border.all(color: isSelected ? Colors.green : Colors.grey.shade300, width: 2),
                                          ),
                                          child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            opt.optionText,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              color: isSelected ? Colors.green.shade900 : Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Navigation Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_currentQuestionIndex > 0)
                            ElevatedButton.icon(
                              onPressed: () => setState(() => _currentQuestionIndex--),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Oldingi'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.indigo,
                              ),
                            )
                          else
                            const SizedBox.shrink(),
                          
                          if (_currentQuestionIndex < _questions.length - 1)
                            ElevatedButton.icon(
                              onPressed: () => setState(() => _currentQuestionIndex++),
                              icon: const Icon(Icons.arrow_forward),
                              label: const Text('Keyingi'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                              ),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: _submitQuiz,
                              icon: const Icon(Icons.done_all),
                              label: const Text('Yakunlash'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
