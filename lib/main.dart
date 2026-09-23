import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

const _cardIndexKey = 'flashcard_index';
const _revealedKey = 'flashcard_revealed';
const _widgetProviderName = 'HomeScreenWidgetProvider';
const _imageWidgetProviderName = 'StudyImageWidgetProvider';
const _imagePathKey = 'selected_study_image';
const _imageTitleKey = 'selected_study_image_title';
const _japaneseIndexKey = 'japanese_cloze_index';
const _japaneseFeedbackKey = 'japanese_cloze_feedback';
const _japaneseAttemptsKey = 'japanese_cloze_attempts';
const _japaneseWrongOptionKey = 'japanese_cloze_wrong_option';

const flashcards = <PhotoelectricFlashcard>[
  PhotoelectricFlashcard(
    question: 'What is Einstein\'s photoelectric equation?',
    answer: 'Kₘₐₓ = hf − φ\nAlso: Kₘₐₓ = ½mv²ₘₐₓ = eVₛ',
  ),
  PhotoelectricFlashcard(
    question: 'What is the threshold frequency?',
    answer: 'The minimum frequency needed for emission.\nf₀ = φ / h',
  ),
  PhotoelectricFlashcard(
    question: 'What happens when intensity increases?',
    answer: 'At fixed f > f₀, photocurrent increases, but Kₘₐₓ and Vₛ do not.',
  ),
  PhotoelectricFlashcard(
    question: 'What happens when frequency increases?',
    answer: 'Kₘₐₓ and stopping voltage increase.\nKₘₐₓ = h(f − f₀)',
  ),
  PhotoelectricFlashcard(
    question: 'What is the threshold wavelength?',
    answer: 'The longest wavelength that can eject electrons.\nλ₀ = hc / φ',
  ),
];

class PhotoelectricFlashcard {
  const PhotoelectricFlashcard({required this.question, required this.answer});

  final String question;
  final String answer;
}

class StudyImageCard extends StatelessWidget {
  const StudyImageCard({required this.title, required this.formula, super.key});

  final String title;
  final String formula;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 180,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xff172554),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            formula,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xffbfdbfe), fontSize: 22),
          ),
        ],
      ),
    );
  }
}

const _studyImages = [
  ('Einstein equation', 'Kₘₐₓ = hf − φ'),
  ('Stopping potential', 'Kₘₐₓ = eVₛ'),
  ('Threshold wavelength', 'λ₀ = hc / φ'),
];

const japaneseClozeCards = <JapaneseClozeCard>[
  JapaneseClozeCard(
    sentence: 'わたしは ___ です。',
    translation: 'I am a student.',
    options: ['学生', '先生', '猫'],
    correctIndex: 0,
  ),
  JapaneseClozeCard(
    sentence: 'これは ___ です。',
    translation: 'This is a book.',
    options: ['本', '水', '山'],
    correctIndex: 0,
  ),
  JapaneseClozeCard(
    sentence: '毎日 ___ を飲みます。',
    translation: 'I drink water every day.',
    options: ['水', '猫', '学校'],
    correctIndex: 0,
  ),
  JapaneseClozeCard(
    sentence: '___ に行きます。',
    translation: 'I go to school.',
    options: ['学校', '本', '先生'],
    correctIndex: 0,
  ),
  JapaneseClozeCard(
    sentence: 'すしが ___ です。',
    translation: 'I like sushi.',
    options: ['好き', '行き', '飲み'],
    correctIndex: 0,
  ),
];

class JapaneseClozeCard {
  const JapaneseClozeCard({
    required this.sentence,
    required this.translation,
    required this.options,
    required this.correctIndex,
  });

  final String sentence;
  final String translation;
  final List<String> options;
  final int correctIndex;

  String get completedSentence =>
      sentence.replaceFirst('___', options[correctIndex]);
}

@pragma('vm:entry-point')
Future<void> interactiveCallback(Uri? uri) async {
  final host = uri?.host;
  if (host == 'japanese_next' || host?.startsWith('japanese_option_') == true) {
    var index = await HomeWidget.getWidgetData<int>(
      _japaneseIndexKey,
      defaultValue: 0,
    );
    var feedback = await HomeWidget.getWidgetData<String>(
      _japaneseFeedbackKey,
      defaultValue: '',
    );
    var attempts = await HomeWidget.getWidgetData<int>(
      _japaneseAttemptsKey,
      defaultValue: 0,
    );
    var wrongOption = await HomeWidget.getWidgetData<int>(
      _japaneseWrongOptionKey,
      defaultValue: -1,
    );
    index = (index ?? 0).clamp(0, japaneseClozeCards.length - 1);
    attempts ??= 0;
    wrongOption ??= -1;

    if (host == 'japanese_next') {
      if (feedback != 'correct') return;
      index = (index + 1) % japaneseClozeCards.length;
      feedback = '';
      attempts = 0;
      wrongOption = -1;
    } else {
      final optionIndex = int.tryParse(host!.split('_').last);
      if (optionIndex == null) return;
      feedback = optionIndex == japaneseClozeCards[index].correctIndex
          ? 'correct'
          : 'wrong';
      if (feedback == 'wrong') {
        attempts++;
        wrongOption = optionIndex;
      }
    }

    await HomeWidget.saveWidgetData<int>(_japaneseIndexKey, index);
    await HomeWidget.saveWidgetData<String>(_japaneseFeedbackKey, feedback);
    await HomeWidget.saveWidgetData<int>(_japaneseAttemptsKey, attempts);
    await HomeWidget.saveWidgetData<int>(_japaneseWrongOptionKey, wrongOption);
    await HomeWidget.updateWidget(name: 'JapaneseClozeWidgetProvider');
    return;
  }

  var index = await HomeWidget.getWidgetData<int>(
    _cardIndexKey,
    defaultValue: 0,
  );
  var revealed = await HomeWidget.getWidgetData<bool>(
    _revealedKey,
    defaultValue: false,
  );

  index = (index ?? 0).clamp(0, flashcards.length - 1);
  revealed ??= false;

  switch (uri?.host) {
    case 'reveal':
      revealed = true;
    case 'next':
      if (!revealed) return;
      index = (index + 1) % flashcards.length;
      revealed = false;
    default:
      return;
  }

  await HomeWidget.saveWidgetData<int>(_cardIndexKey, index);
  await HomeWidget.saveWidgetData<bool>(_revealedKey, revealed);
  await HomeWidget.updateWidget(name: _widgetProviderName);
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  HomeWidget.registerInteractivityCallback(interactiveCallback);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photoelectric Effects Flashcards',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.indigo)),
      home: const FlashcardPage(),
    );
  }
}

class FlashcardPage extends StatefulWidget {
  const FlashcardPage({super.key});

  @override
  State<FlashcardPage> createState() => _FlashcardPageState();
}

class _FlashcardPageState extends State<FlashcardPage>
    with WidgetsBindingObserver {
  int _index = 0;
  bool _revealed = false;
  int _japaneseIndex = 0;
  String _japaneseFeedback = '';
  int _japaneseAttempts = 0;
  int _japaneseWrongOption = -1;
  StreamSubscription<Uri?>? _widgetClickSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _widgetClickSubscription = HomeWidget.widgetClicked.listen((_) {
      _loadFlashcard();
      _loadJapaneseCloze();
    });
    _loadFlashcard();
    _loadJapaneseCloze();
  }

  Future<void> _loadFlashcard() async {
    final index = await HomeWidget.getWidgetData<int>(
      _cardIndexKey,
      defaultValue: 0,
    );
    final revealed = await HomeWidget.getWidgetData<bool>(
      _revealedKey,
      defaultValue: false,
    );
    if (!mounted) return;

    setState(() {
      _index = (index ?? 0).clamp(0, flashcards.length - 1);
      _revealed = revealed ?? false;
    });
  }

  Future<void> _saveFlashcard() async {
    await HomeWidget.saveWidgetData<int>(_cardIndexKey, _index);
    await HomeWidget.saveWidgetData<bool>(_revealedKey, _revealed);
    await HomeWidget.updateWidget(name: _widgetProviderName);
  }

  void _reveal() {
    setState(() => _revealed = true);
    unawaited(_saveFlashcard());
  }

  void _next() {
    if (!_revealed) return;
    setState(() {
      _index = (_index + 1) % flashcards.length;
      _revealed = false;
    });
    unawaited(_saveFlashcard());
  }

  Future<void> _setStudyImage(int imageIndex) async {
    final image = _studyImages[imageIndex];
    await HomeWidget.renderFlutterWidget(
      StudyImageCard(title: image.$1, formula: image.$2),
      logicalSize: const Size(320, 180),
      key: _imagePathKey,
    );
    await HomeWidget.saveWidgetData<String>(_imageTitleKey, image.$1);
    await HomeWidget.updateWidget(name: _imageWidgetProviderName);
  }

  Future<void> _loadJapaneseCloze() async {
    final index = await HomeWidget.getWidgetData<int>(
      _japaneseIndexKey,
      defaultValue: 0,
    );
    final feedback = await HomeWidget.getWidgetData<String>(
      _japaneseFeedbackKey,
      defaultValue: '',
    );
    final attempts = await HomeWidget.getWidgetData<int>(
      _japaneseAttemptsKey,
      defaultValue: 0,
    );
    final wrongOption = await HomeWidget.getWidgetData<int>(
      _japaneseWrongOptionKey,
      defaultValue: -1,
    );
    if (!mounted) return;
    setState(() {
      _japaneseIndex = (index ?? 0).clamp(0, japaneseClozeCards.length - 1);
      _japaneseFeedback = feedback ?? '';
      _japaneseAttempts = attempts ?? 0;
      _japaneseWrongOption = wrongOption ?? -1;
    });
  }

  Future<void> _answerJapanese(int optionIndex) async {
    final card = japaneseClozeCards[_japaneseIndex];
    final feedback = optionIndex == card.correctIndex ? 'correct' : 'wrong';
    setState(() {
      _japaneseFeedback = feedback;
      if (feedback == 'wrong') {
        _japaneseAttempts++;
        _japaneseWrongOption = optionIndex;
      }
    });
    await HomeWidget.saveWidgetData<int>(_japaneseIndexKey, _japaneseIndex);
    await HomeWidget.saveWidgetData<String>(_japaneseFeedbackKey, feedback);
    await HomeWidget.saveWidgetData<int>(
      _japaneseAttemptsKey,
      _japaneseAttempts,
    );
    await HomeWidget.saveWidgetData<int>(
      _japaneseWrongOptionKey,
      _japaneseWrongOption,
    );
    await HomeWidget.updateWidget(name: 'JapaneseClozeWidgetProvider');
  }

  Future<void> _nextJapanese() async {
    if (_japaneseFeedback != 'correct') return;
    setState(() {
      _japaneseIndex = (_japaneseIndex + 1) % japaneseClozeCards.length;
      _japaneseFeedback = '';
      _japaneseAttempts = 0;
      _japaneseWrongOption = -1;
    });
    await HomeWidget.saveWidgetData<int>(_japaneseIndexKey, _japaneseIndex);
    await HomeWidget.saveWidgetData<String>(_japaneseFeedbackKey, '');
    await HomeWidget.saveWidgetData<int>(_japaneseAttemptsKey, 0);
    await HomeWidget.saveWidgetData<int>(_japaneseWrongOptionKey, -1);
    await HomeWidget.updateWidget(name: 'JapaneseClozeWidgetProvider');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadFlashcard();
      _loadJapaneseCloze();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _widgetClickSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = flashcards[_index];
    return Scaffold(
      appBar: AppBar(title: const Text('Photoelectric Effects')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Card ${_index + 1} of ${flashcards.length}'),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) {
                    return AnimatedBuilder(
                      animation: animation,
                      child: child,
                      builder: (context, child) {
                        final angle = (1 - animation.value) * math.pi;
                        return Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(angle),
                          child: child,
                        );
                      },
                    );
                  },
                  child: Text(
                    _revealed ? card.answer : card.question,
                    key: ValueKey('${_index}_$_revealed'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _revealed ? null : _reveal,
              icon: const Icon(Icons.flip),
              label: Text(_revealed ? 'Answer revealed' : 'Reveal answer'),
            ),
            TextButton.icon(
              onPressed: _revealed ? _next : null,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next card'),
            ),
            const Divider(height: 40),
            Text(
              'Set an image widget',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('Choose a formula image to show on your home screen.'),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _studyImages.length; i++)
                  OutlinedButton(
                    onPressed: () => _setStudyImage(i),
                    child: Text(_studyImages[i].$1),
                  ),
              ],
            ),
            const Divider(height: 40),
            _JapaneseClozeSection(
              index: _japaneseIndex,
              feedback: _japaneseFeedback,
              attempts: _japaneseAttempts,
              wrongOption: _japaneseWrongOption,
              onOptionSelected: _answerJapanese,
              onNext: _nextJapanese,
            ),
          ],
        ),
      ),
    );
  }
}

class _JapaneseClozeSection extends StatelessWidget {
  const _JapaneseClozeSection({
    required this.index,
    required this.feedback,
    required this.attempts,
    required this.wrongOption,
    required this.onOptionSelected,
    required this.onNext,
  });

  final int index;
  final String feedback;
  final int attempts;
  final int wrongOption;
  final ValueChanged<int> onOptionSelected;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final card = japaneseClozeCards[index];
    final isCorrect = feedback == 'correct';
    final isWrong = feedback == 'wrong';

    return Column(
      children: [
        Text(
          'Japanese Cloze Test',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text('Card ${index + 1} of ${japaneseClozeCards.length}'),
        const SizedBox(height: 12),
        Card(
          color: isWrong
              ? Colors.red.shade50
              : isCorrect
              ? Colors.green.shade50
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  isCorrect ? card.completedSentence : card.sentence,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(card.translation, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: feedback.isEmpty
              ? const SizedBox(height: 32)
              : Row(
                  key: ValueKey(feedback),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: isCorrect ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isCorrect
                          ? 'Correct! Next card unlocked.'
                          : 'Not quite — try again.',
                      style: TextStyle(
                        color: isCorrect
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
        if (attempts > 0)
          Text(
            'Wrong attempts: $attempts',
            style: TextStyle(
              color: Colors.red.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            for (
              var optionIndex = 0;
              optionIndex < card.options.length;
              optionIndex++
            )
              FilledButton(
                onPressed: isCorrect
                    ? null
                    : () => onOptionSelected(optionIndex),
                style: FilledButton.styleFrom(
                  backgroundColor: isWrong && wrongOption == optionIndex
                      ? Colors.red.shade400
                      : null,
                ),
                child: Text(card.options[optionIndex]),
              ),
          ],
        ),
        TextButton.icon(
          onPressed: isCorrect ? onNext : null,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Next Japanese card'),
        ),
      ],
    );
  }
}
