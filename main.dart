import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const OmkarIndianArmyApp());
}

class OmkarIndianArmyApp extends StatelessWidget {
  const OmkarIndianArmyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OMKAR INDIAN ARMY',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) return const HomeScreen();
        return const LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign-in failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B2340),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield, size: 90, color: Colors.amber),
                const SizedBox(height: 16),
                const Text('OMKAR INDIAN ARMY',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                const Text('Army GK / GS Quiz', style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 48),
                _isLoading
                    ? const CircularProgressIndicator(color: Colors.amber)
                    : ElevatedButton.icon(
                        onPressed: _handleGoogleSignIn,
                        icon: const Icon(Icons.login),
                        label: const Text('Sign in with Google'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  static const List<String> _categories = ['All', 'History', 'Geography', 'Polity', 'Science', 'Maths', 'Defence', 'Art & Culture'];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('OMKAR INDIAN ARMY'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await GoogleSignIn().signOut();
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Welcome, ${user.displayName ?? user.email ?? 'Soldier'}!',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Choose a category to start the quiz:', style: TextStyle(fontSize: 15, color: Colors.black54)),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.quiz_outlined),
                    title: Text(category),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => QuizScreen(category: category)));
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Question {
  final String questionText;
  final List<String> options;
  final int correctIndex;
  final String category;
  Question({required this.questionText, required this.options, required this.correctIndex, required this.category});
}

final List<Question> allQuestions = [
  Question(questionText: "Who was known for the quote, 'Swaraj is my birthright and I shall have it'?",
      options: ["Mahatma Gandhi", "Lala Lajpat Rai", "Bipin Chandra Pal", "Bal Gangadhar Tilak"], correctIndex: 3, category: "History"),
  Question(questionText: "Which of the following is NOT a constitutional body?",
      options: ["Goods and Services Tax Council", "Lokpal", "Finance Commission of India", "State Public Service Commission"], correctIndex: 1, category: "Polity"),
  Question(questionText: "Indian Army Day is celebrated every year on which date?",
      options: ["14 January", "15 January", "15 February", "26 January"], correctIndex: 1, category: "Defence"),
  Question(questionText: "The Indian Air Force (IAF) mainly protects the:",
      options: ["Indian land borders", "Indian Ocean", "Indian airspace", "Indian forests"], correctIndex: 2, category: "Defence"),
  Question(questionText: "The LCM of 5, 9, and 30 is:",
      options: ["90", "88", "92", "87"], correctIndex: 0, category: "Maths"),
  Question(questionText: "45% of 480 litres is equal to:",
      options: ["216 litres", "215 litres", "217 litres", "214 litres"], correctIndex: 0, category: "Maths"),
  Question(questionText: "The term 'monsoon' is derived from which word meaning 'season'?",
      options: ["Latin", "Arabic", "Hindi", "Persian"], correctIndex: 1, category: "Geography"),
  Question(questionText: "Mithila art is also commonly known as which painting?",
      options: ["Warli", "Madhubani", "Pattachitra", "Kalamkari"], correctIndex: 1, category: "Art & Culture"),
  Question(questionText: "What happens to the magnetic field of an electromagnet when current is switched off?",
      options: ["It becomes stronger", "It remains unchanged", "It reverses direction", "It loses its magnetism"], correctIndex: 3, category: "Science"),
  Question(questionText: "What is the condition called when the eye's lens becomes cloudy?",
      options: ["Myopia", "Hypermetropia", "Cataract", "Presbyopia"], correctIndex: 2, category: "Science"),
];

class QuizScreen extends StatefulWidget {
  final String category;
  const QuizScreen({super.key, required this.category});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<Question> _questions;
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedIndex;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _questions = widget.category == 'All'
        ? List.of(allQuestions)
        : allQuestions.where((q) => q.category == widget.category).toList();
    _questions.shuffle();
  }

  void _selectOption(int index) {
    if (_answered) return;
    final correctIndex = _questions[_currentIndex].correctIndex;
    setState(() {
      _selectedIndex = index;
      _answered = true;
      if (index == correctIndex) _score++;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedIndex = null;
        _answered = false;
      });
    } else {
      _showResultDialog();
    }
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Quiz Complete'),
        content: Text('Your score: $_score / ${_questions.length}', style: const TextStyle(fontSize: 18)),
        actions: [
          TextButton(onPressed: () { Navigator.of(context).pop(); Navigator.of(context).pop(); }, child: const Text('Back to Home')),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _currentIndex = 0;
                _score = 0;
                _selectedIndex = null;
                _answered = false;
                _questions.shuffle();
              });
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Color _optionColor(int index, int correctIndex) {
    if (!_answered) return Colors.white;
    if (index == correctIndex) return Colors.green.shade400;
    if (index == _selectedIndex && _selectedIndex != correctIndex) return Colors.red.shade400;
    return Colors.white;
  }

  Color _optionTextColor(int index, int correctIndex) {
    if (!_answered) return Colors.black87;
    if (index == correctIndex || (index == _selectedIndex && _selectedIndex != correctIndex)) return Colors.white;
    return Colors.black87;
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(appBar: AppBar(title: Text(widget.category)), body: const Center(child: Text('No questions found.')));
    }
    final question = _questions[_currentIndex];
    return Scaffold(
      appBar: AppBar(title: Text('${widget.category} - ${_currentIndex + 1}/${_questions.length}')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: (_currentIndex + 1) / _questions.length, backgroundColor: Colors.grey.shade300, minHeight: 6),
            const SizedBox(height: 24),
            Text(question.questionText, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: question.options.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: InkWell(
                      onTap: () => _selectOption(index),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(
                          color: _optionColor(index, question.correctIndex),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: Text(question.options[index],
                            style: TextStyle(fontSize: 16, color: _optionTextColor(index, question.correctIndex), fontWeight: FontWeight.w500)),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_answered)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextQuestion,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: Text(_currentIndex < _questions.length - 1 ? 'Next Question' : 'Finish Quiz'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
