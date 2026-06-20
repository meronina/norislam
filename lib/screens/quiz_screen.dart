import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import '../services/progress_service.dart';
import '../services/question_service.dart';
import '../services/level_service.dart';
import '../data/models/question_model.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  final String category;
  final int resumeIndex;
  final int resumeScore;

  const QuizScreen({
    super.key,
    required this.category,
    this.resumeIndex = 0,
    this.resumeScore = 0,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Question> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _isLoading = true;
  bool _isAnswered = false;
  int? _selectedAnswerIndex;
  List<int> _shuffledOptionIndices = [];

  final AudioPlayer _audioPlayer = AudioPlayer();
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.resumeIndex;
    _score = widget.resumeScore;
    _loadQuestions();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _audioPlayer.setVolume(0.75);
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    try {
      final currentLevel =
          await LevelService.instance.getCurrentDifficultyLevel();
      final questions = await QuestionService.instance
          .getQuestionsByCategoryAndDifficulty(widget.category, currentLevel);
      if (mounted) {
        setState(() {
          _questions = questions;
          _isLoading = false;
          _shuffleOptionsForCurrentQuestion();
        });
      }
    } catch (e) {
      debugPrint('خطأ في تحميل الأسئلة: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل تحميل الأسئلة')),
        );
      }
    }
  }

  void _shuffleOptionsForCurrentQuestion() {
    if (_questions.isEmpty || _currentIndex >= _questions.length) {
      _shuffledOptionIndices = [];
      return;
    }

    final optionCount = _questions[_currentIndex].options.length;
    _shuffledOptionIndices = List.generate(optionCount, (index) => index);
    _shuffledOptionIndices.shuffle();
  }

  Future<void> _playSound(String soundName) async {
    try {
      await _audioPlayer.play(AssetSource('sounds/$soundName'));
    } catch (e) {
      debugPrint('خطأ في الصوت: $e');
    }
  }

  Future<void> _checkAnswer(int selectedIndex) async {
    if (_isAnswered) return;

    final currentQuestion = _questions[_currentIndex];
    final bool isCorrect =
        _shuffledOptionIndices[selectedIndex] == currentQuestion.correctIndex;

    setState(() {
      _isAnswered = true;
      _selectedAnswerIndex = selectedIndex;
    });

    if (isCorrect) {
      await _playSound('correct.mp3');
      _score++;
      _confettiController.play();
      await LevelService.instance.addXp(currentQuestion.difficulty);
    } else {
      await _playSound('wrong.mp3');
    }

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;

      if (_currentIndex + 1 < _questions.length) {
        setState(() {
          _currentIndex++;
          _isAnswered = false;
          _selectedAnswerIndex = null;
          _shuffleOptionsForCurrentQuestion();
        });
        ProgressService.instance.saveProgress(
          category: widget.category,
          currentIndex: _currentIndex,
          score: _score,
          total: _questions.length,
        );
      } else {
        ProgressService.instance.clearSavedProgress();
        _confettiController.play();

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ResultScreen(
                  score: _score,
                  total: _questions.length,
                  category: widget.category,
                ),
              ),
            );
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_questions.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.quiz_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('لا توجد أسئلة في هذه الفئة',
                  style: TextStyle(fontSize: 18)),
              ElevatedButton.icon(
                onPressed: _loadQuestions,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    final currentQ = _questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(currentQ.categoryId),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / _questions.length,
            backgroundColor: Colors.grey.shade300,
            color: Colors.teal,
            minHeight: 6,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Card(
                key: ValueKey(_currentIndex),
                elevation: 10,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Text(
                    currentQ.question,
                    style: const TextStyle(
                        fontSize: 21, fontWeight: FontWeight.w700, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      MediaQuery.of(context).size.width > 600 ? 2 : 1,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  childAspectRatio: 3.1,
                ),
                itemCount: currentQ.options.length,
                itemBuilder: (context, index) {
                  final option =
                      currentQ.options[_shuffledOptionIndices[index]];
                  final isSelected = _selectedAnswerIndex == index;
                  final isCorrect = _isAnswered &&
                      _shuffledOptionIndices[index] == currentQ.correctIndex;
                  final isWrong = _isAnswered && isSelected && !isCorrect;

                  return GestureDetector(
                    onTap: _isAnswered
                        ? null
                        : () async => await _checkAnswer(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? Colors.green.shade100
                            : isWrong
                                ? Colors.red.shade100
                                : isSelected
                                    ? Colors.blue.shade100
                                    : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isCorrect
                              ? Colors.green
                              : isWrong
                                  ? Colors.red
                                  : isSelected
                                      ? Colors.blue
                                      : Colors.teal.shade400,
                          width: isSelected || isCorrect || isWrong ? 3.5 : 1.8,
                        ),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 20),
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 17.5,
                              fontWeight: FontWeight.w600,
                              color: isCorrect
                                  ? Colors.green.shade900
                                  : isWrong
                                      ? Colors.red.shade900
                                      : Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _confettiController.dispose();
    super.dispose();
  }
}
