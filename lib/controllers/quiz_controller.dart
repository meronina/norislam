import '../data/models/question_model.dart';

class QuizController {
  List<Question> questions = [];
  int index = 0;
  int score = 0;

  void setQuestions(List<Question> list) {
    questions = list;
    index = 0;
    score = 0;
  }

  Question get currentQuestion => questions[index];

  void answer(int selected) {
    if (selected == currentQuestion.correctIndex) {
      score++;
    }
  }

  bool next() {
    if (index + 1 < questions.length) {
      index++;
      return true;
    }
    return false;
  }
}
