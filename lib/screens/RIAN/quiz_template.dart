// FILE: lib/quiz_template.dart
import 'package:flutter/material.dart';

/// Model sederhana untuk satu soal
class Question {
  final int id;
  final String question;
  final List<String> choices; // kosong untuk essay
  final int? answerIndex; // index yang benar (opsional)

  Question({
    required this.id,
    required this.question,
    required this.choices,
    this.answerIndex,
  });
}

/// Halaman Quiz UI (disesuaikan agar mirip screenshot)
class QuizPage extends StatefulWidget {
  final String title;
  final List<Question> questions;
  final int initialIndex;

  const QuizPage({
    super.key,
    required this.questions,
    this.title = 'Quiz',
    this.initialIndex = 0,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late int currentIndex;
  late List<int?> selectedAnswers;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex.clamp(0, widget.questions.length - 1);
    selectedAnswers = List<int?>.filled(widget.questions.length, null);
  }

  void selectChoice(int choiceIndex) {
    setState(() {
      selectedAnswers[currentIndex] = choiceIndex;
    });
  }

  void goNext() {
    if (currentIndex < widget.questions.length - 1) {
      setState(() => currentIndex++);
    } else {
      _showFinishDialog();
    }
  }

  void goPrevious() {
    if (currentIndex > 0) {
      setState(() => currentIndex--);
    }
  }

  void _showFinishDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Selesai'),
        content: const Text('Kamu sudah sampai di akhir kuis.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // tutup dialog
              Navigator.of(context).pop(); // kembali ke halaman sebelumnya
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  // Membuat kotak opsi sesuai desain screenshot
  Widget buildOptionBox(String text, int choiceIndex, bool isSelected) {
    // Warna desain
    const Color accent = Color(0xFF3FC0FF); // biru terang
    const Color selectedBg = Color(0xFFBFF0FF); // latar opsi terpilih
    const Color cardBorder = Color(0xFFE6EEF6);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () => selectChoice(choiceIndex),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? accent : const Color(0xFFE6EEF6),
              width: isSelected ? 1.6 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accent.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    )
                  ]
                : [],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lingkaran huruf
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? accent : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? accent : const Color(0xFFD6DEE9),
                    width: isSelected ? 0 : 1.0,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  String.fromCharCode(65 + choiceIndex),
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF3A4A5A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF0D2437) : const Color(0xFF233445),
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Header card: nomor soal + teks + timer bubble
  Widget buildHeader(Question q) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Teks (nomor + isi) di kiri
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Soal ${q.id}.',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              // Gunakan Text dengan softWrap dan maxLines agar mirip layout screenshot
              Text(
                q.question,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),
        // Bubble waktu di kanan
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF7FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD7EEFC)),
          ),
          child: Row(
            children: const [
              Icon(Icons.access_time, size: 14, color: Color(0xFF2C7DB8)),
              SizedBox(width: 6),
              Text('23:34', style: TextStyle(color: Color(0xFF2C7DB8), fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.questions[currentIndex];
    final isMultipleChoice = q.choices.isNotEmpty;
    final selected = selectedAnswers[currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF233445)),
        ),
        title: Text(widget.title, style: const TextStyle(color: Color(0xFF233445), fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14),
        child: Column(
          children: [
            // Card utama
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE7EEF6)),
                boxShadow: const [
                  BoxShadow(color: Color(0x0a000000), blurRadius: 6, offset: Offset(0,2))
                ],
              ),
              child: Column(
                children: [
                  buildHeader(q),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Pertanyaan:',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (isMultipleChoice)
                    Column(
                      children: List.generate(q.choices.length, (i) {
                        final isSel = selected != null && selected == i;
                        return buildOptionBox(q.choices[i], i, isSel);
                      }),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F9FB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE6EEF6)),
                      ),
                      child: const Text(
                        'Tipe soal: Essay (tidak ada pilihan).',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                ],
              ),
            ),

            const Spacer(),

            // Bottom navigation: Sebelumnya | Selanjutnya
            Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    if (currentIndex > 0)
      SizedBox(
        height: 44,
        child: OutlinedButton(
          onPressed: goPrevious,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFE6EEF6)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 18),
          ),
          child: const Text(
            'Sebelumnya',
            style: TextStyle(
              color: Color(0xFF3A4A5A),
            ),
          ),
        ),
      )
    else
      const SizedBox(width: 110), // biar tombol kanan tetap di kanan

    // Selanjutnya (filled biru)
    SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: goNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3FC0FF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: Text(
          currentIndex == widget.questions.length - 1 ? 'Selesai' : 'Selanjutnya',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    ),
  ],
),


            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

/// Sample dummy data (untuk preview UI)
List<Question> sampleQuestions = [
  Question(
    id: 1,
    question:
        'Tanaman diletakkan dalam ruangan berisi CO2. Suatu tanaman diberi cahaya, satu lagi gelap. Apa perbedaan utama distribusi CO2 dalam kedua tanaman tersebut?',
    choices: [
      'Tanaman bercahaya menyimpan CO2 dalam glukosa hasil fotosintesis, tanaman gelap menyimpan CO2 dalam ATP',
      'Alel Tanaman bercahaya memasukkan CO2 ke dalam glukosa melalui siklus Calvin, tanaman gelap tidak dapat mengikat CO2 bersifat lethal pada homozigot',
      'Tanaman bercahaya menghasilkan O2 berlebih',
      'Tanaman bercahaya mengakumulasi CO2 dalam klorofil',
    ],
    answerIndex: 1,
  ),
  Question(
    id: 2,
    question:
        'Seekor tanaman berbunga merah disilangkan dengan tanaman berbunga merah lainnya. Dari 200 biji yang ditanam, hanya 140 tumbuh. Apa penyebab rasio tersebut?',
    choices: [
      'Alel dominan bersifat lethal pada homozigot',
      'Alel resesif bersifat lethal pada homozigot',
      'Alel dominan tidak dapat diekspresikan penuh (incomplete dominance)',
      'Mutasi spontan selama perkembangan embrio',
    ],
    answerIndex: 0,
  ),
  Question(
    id: 3,
    question:
        'Soal essay: Jelaskan proses fotosintesis singkat pada tumbuhan dan faktor yang mempengaruhinya.',
    choices: [],
    answerIndex: null,
  ),
];
