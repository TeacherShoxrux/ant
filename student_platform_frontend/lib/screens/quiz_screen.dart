import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
  final PageController _pageController = PageController();
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
    _pageController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _submitQuiz() async {
    if (_isFinished) return;
    
    // Check if all questions are answered
    if (_userAnswers.length < _questions.length) {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Diqqat!'),
          content: Text('Siz barcha savollarga javob bermadingiz (${_userAnswers.length}/${_questions.length}). Testni baribir yakunlaysizmi?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Yo\'q')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ha, yakunlash')),
          ],
        ),
      );
      if (confirm != true) return;
    }

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
        Navigator.pop(context); // Close loading
        _showResultDialog(result);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xatolik yuz berdi: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isFinished = false);
      }
    }
  }

  void _showResultDialog(Map<String, dynamic>? result) {
    final score = (result?['score'] as num?)?.toDouble() ?? 0.0;
    final isSuccess = score >= 60;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSuccess ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
                color: isSuccess ? Colors.orange : Colors.grey,
                size: 100,
              ).animate().scale(duration: 600.ms, curve: Curves.bounceOut),
              const SizedBox(height: 24),
              Text(
                isSuccess ? 'Tabriklaymiz!' : 'Harakatdan to\'xtamang!',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                isSuccess ? 'Siz testdan muvaffaqiyatli o\'tdingiz.' : 'Keyingi safar albatta o\'tasiz.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isSuccess ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isSuccess ? Colors.green.shade100 : Colors.orange.shade100),
                ),
                child: Column(
                  children: [
                    Text(
                      '${score.toStringAsFixed(0)} %',
                      style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: isSuccess ? Colors.green : Colors.orange),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'To\'g\'ri javoblar: ${result?['correctCount'] ?? 0} / ${result?['totalQuestions'] ?? 0}',
                      style: TextStyle(fontWeight: FontWeight.w600, color: isSuccess ? Colors.green.shade800 : Colors.orange.shade800),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Asosiy sahifaga qaytish', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.quiz.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('${_userAnswers.length} / ${_questions.length} bajarildi', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        actions: [
          _buildTimerWidget(),
        ],
      ),
      body: Row(
        children: [
          // Left Sidebar Navigator
          _buildQuestionNavigator(),
          
          // Main Question View
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _questions.length,
              onPageChanged: (index) => setState(() => _currentQuestionIndex = index),
              itemBuilder: (context, index) {
                return _buildQuestionItem(_questions[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerWidget() {
    final bool isUrgent = _secondsRemaining < 60;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isUrgent ? Colors.red.shade50 : const Color(0xFF1E3A8A).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isUrgent ? Colors.red.shade200 : const Color(0xFF1E3A8A).withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: isUrgent ? Colors.red : const Color(0xFF1E3A8A), size: 20),
          const SizedBox(width: 8),
          Text(
            _formatTime(_secondsRemaining),
            style: TextStyle(
              color: isUrgent ? Colors.red : const Color(0xFF1E3A8A),
              fontWeight: FontWeight.bold,
              fontSize: 18,
              fontFamily: 'Courier',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionNavigator() {
    return Container(
      width: 320,
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Savollar Ro\'yxati', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
          const SizedBox(height: 8),
          const Text('Barcha savollarga javob berishga harakat qiling.', style: TextStyle(fontSize: 13, color: Colors.blueGrey)),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                bool isCurrent = _currentQuestionIndex == index;
                bool isAnswered = _userAnswers.containsKey(_questions[index].id);
                
                return InkWell(
                  onTap: () {
                    _pageController.animateToPage(index, duration: 400.ms, curve: Curves.easeInOut);
                  },
                  child: AnimatedContainer(
                    duration: 300.ms,
                    decoration: BoxDecoration(
                      color: isCurrent 
                          ? const Color(0xFF1E3A8A) 
                          : (isAnswered ? Colors.green.shade500 : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrent 
                            ? const Color(0xFF1E3A8A) 
                            : (isAnswered ? Colors.green : Colors.grey.shade200),
                        width: 2,
                      ),
                      boxShadow: isCurrent ? [BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: (isCurrent || isAnswered) ? Colors.white : Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _submitQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Testni Yakunlash', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionItem(TestQuestion question, int index) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(48.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: const Color(0xFF1E3A8A).withOpacity(0.1), borderRadius: BorderRadius.circular(30)),
                          child: Text('Savol ${index + 1}', style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                        ),
                        const Spacer(),
                        Text('${index + 1} / ${_questions.length}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    if (question.imagePath != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.network(
                            '${ApiService.serverUrl}${question.imagePath}',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 400,
                            errorBuilder: (ctx, _, __) => Container(height: 200, color: Colors.grey.shade100, child: const Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                          ),
                        ),
                      ),
                    Text(
                      question.title,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), height: 1.3),
                    ),
                    if (question.question.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        question.question,
                        style: TextStyle(fontSize: 18, color: Colors.blueGrey.shade800, height: 1.6),
                      ),
                    ],
                    const SizedBox(height: 48),
                    
                    const Text('JAVOB VARIANTLARINI TANLANG:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                    const SizedBox(height: 24),
                    
                    ...question.options.map((opt) => _buildOptionItem(question.id, opt)),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
              
              const SizedBox(height: 40),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavButton(
                    onPressed: index > 0 ? () => _pageController.previousPage(duration: 400.ms, curve: Curves.easeInOut) : null,
                    icon: Icons.arrow_back_ios_new_rounded,
                    label: 'Oldingi',
                  ),
                  _buildNavButton(
                    onPressed: index < _questions.length - 1 
                        ? () => _pageController.nextPage(duration: 400.ms, curve: Curves.easeInOut) 
                        : _submitQuiz,
                    icon: index < _questions.length - 1 ? Icons.arrow_forward_ios_rounded : Icons.check_circle_rounded,
                    label: index < _questions.length - 1 ? 'Keyingi' : 'Yakunlash',
                    isPrimary: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionItem(int questionId, TestOption opt) {
    bool isSelected = _userAnswers[questionId] == opt.id;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          setState(() {
            _userAnswers[questionId] = opt.id;
          });
          // Small delay then auto-next
          if (_currentQuestionIndex < _questions.length - 1) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) _pageController.nextPage(duration: 400.ms, curve: Curves.easeInOut);
            });
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: 300.ms,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E3A8A).withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade200,
              width: 2.5,
            ),
            boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))] : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: 300.ms,
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
                  border: Border.all(color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade300, width: 2),
                ),
                child: isSelected ? const Icon(Icons.check, size: 20, color: Colors.white) : null,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  opt.optionText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? const Color(0xFF1E3A8A) : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({required VoidCallback? onPressed, required IconData icon, required String label, bool isPrimary = false}) {
    return SizedBox(
      height: 60,
      width: 180,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? const Color(0xFF1E3A8A) : Colors.white,
          foregroundColor: isPrimary ? Colors.white : const Color(0xFF1E3A8A),
          disabledBackgroundColor: Colors.grey.shade200,
          elevation: isPrimary ? 4 : 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: isPrimary ? BorderSide.none : BorderSide(color: Colors.grey.shade300)),
        ),
      ),
    );
  }
}
