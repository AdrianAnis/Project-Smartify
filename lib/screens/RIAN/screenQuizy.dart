import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'quiz_template.dart';
import 'gemini_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: QuizyStepPage(),
    );
  }
}

class QuizyStepPage extends StatefulWidget {
  const QuizyStepPage({super.key});

  @override
  State<QuizyStepPage> createState() => _QuizyStepPageState();
}

class _QuizyStepPageState extends State<QuizyStepPage> {
  int currentStep = 0;
  String? selectedFileName;
  String? selectedCategory;
  String? selectedType;
  String? selectedTime;
  int? selectedTotal;

  final TextEditingController totalController = TextEditingController();

  final List<String> categories = ["Mudah", "Sedang", "Susah"];
  final List<String> types = ["Essay", "Pilihan Ganda"];
  final List<String> times = [
    "5 menit",
    "10 menit",
    "15 menit",
    "20 menit",
    "25 menit",
    "30 menit"
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        selectedFileName = result.files.single.name;
      });
    }
  }

  void nextStep() async {
    print("=== Tombol Selesai ditekan ===");

    if (currentStep < 4) {
      setState(() => currentStep++);
      return;
    }

    // GUARD: pastikan API key tersedia sebelum request
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('API Key belum tersedia'),
          content: const Text(
            'GEMINI_API_KEY tidak ditemukan. Pastikan file .env ada di root project dan berisi GEMINI_API_KEY=..., lalu lakukan full restart aplikasi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
      return;
    }

    // Step terakhir: panggil Gemini service (tampilkan loading)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final map = await generateQuizRaw(
        category: selectedCategory ?? 'Mudah',
        type: selectedType ?? 'Pilihan Ganda',
        time: selectedTime ?? '10 menit',
        total: selectedTotal ?? 5,
        fileText: null,
      );

      Navigator.of(context).pop(); // tutup loading

      final raw = map['raw'] as String?;
      final questions = map['questions'] as List<Question>?;

      if (questions != null && questions.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => QuizPage(questions: questions, title: 'Quizy'),
          ),
        );
      } else {
        final diag = map['diagnostic'];
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Response AI (gagal parse)'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Raw AI output (Cek format JSON):'),
                  const SizedBox(height: 8),
                  Text(map['raw']?.toString() ?? 'Kosong'),
                  const SizedBox(height: 12),
                  const Text('Diagnostic:'),
                  const SizedBox(height: 8),
                  Text(diag?.toString() ?? 'Tidak ada diagnostic'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tutup'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => QuizPage(
                        questions: sampleQuestions,
                        title: 'Preview (dummy)',
                      ),
                    ),
                  );
                },
                child: const Text('Lihat Preview Dummy'),
              ),
            ],
          ),
        );
      }
    } catch (e, st) {
      Navigator.of(context).pop();
      print('Error saat request API: ${e.runtimeType}: $e');
      print('Stacktrace:\n$st');
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error request (Periksa koneksi)'),
          content: SingleChildScrollView(
            child: Text('${e.runtimeType}: ${e.toString()}'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
    }
  }

  bool isValidInput() {
    switch (currentStep) {
      case 0:
        return true;
      case 1:
        return selectedCategory != null;
      case 2:
        return selectedType != null;
      case 3:
        return selectedTime != null;
      case 4:
        return selectedTotal != null && selectedTotal! > 0;
      default:
        return true;
    }
  }

  Widget buildUploadStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48.0),
          child: Row(
            children: [
              const Text(
                "Silahkan unggah file materi yang\ningin anda pelajari lebih lanjut!",
                style: TextStyle(fontSize: 14),
              ),
              const Spacer(),
              Image.asset(
                'assets/images/quizy_inputfile.png',
                width: 70,
                height: 70,
              ),
            ],
          ),
        ),
        const SizedBox(height: 50),
        Center(
          child: InkWell(
            onTap: pickFile,
            child: Container(
              width: 328,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Text(
                      selectedFileName ?? "Upload File (Opsional)",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(right: 24),
                    child: Icon(Icons.upload_outlined, color: Colors.grey),
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildCategoryStep() {
    return _buildDropdownStep(
      title: "Silahkan pilih level soal yang\nanda inginkan!",
      imagePath: 'assets/images/quizy_susah.png',
      items: categories,
      value: selectedCategory,
      onChanged: (value) => setState(() => selectedCategory = value),
    );
  }

  Widget buildTypeStep() {
    return _buildDropdownStep(
      title: "Silahkan pilih jenis soal yang\nanda inginkan!",
      imagePath: 'assets/images/quizy_jenissoal.png',
      items: types,
      value: selectedType,
      onChanged: (value) => setState(() => selectedType = value),
    );
  }

  Widget buildTimeStep() {
    return _buildDropdownStep(
      title:
          "Silahkan masukkan durasi\npengerjaan soal yang anda\ninginkan!",
      imagePath: 'assets/images/quizy_waktu.png',
      items: times,
      value: selectedTime,
      onChanged: (value) => setState(() => selectedTime = value),
    );
  }

  Widget buildTotalStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "Masukkan jumlah soal yang\nanda inginkan!",
                style: TextStyle(fontSize: 14),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 48.0),
                child: Image.asset('assets/images/quizy_totalsoal.png'),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Center(
            child: Container(
              width: 328,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: totalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Contoh: 10",
                  contentPadding: EdgeInsets.symmetric(horizontal: 24),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    selectedTotal = int.tryParse(value);
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownStep({
    required String title,
    required List<String> items,
    required String? value,
    required void Function(String?) onChanged,
    String? imagePath,
  }) {
    if (value != null && !items.contains(value)) {
      value = null;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              if (imagePath != null) ...[
                const SizedBox(width: 12),
                Image.asset(
                  imagePath,
                  width: 70,
                  height: 70,
                ),
              ],
            ],
          ),
          const SizedBox(height: 30),
          Center(
            child: Container(
              width: 328,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(24),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text("Pilih"),
                  ),
                  value: value,
                  onChanged: onChanged,
                  items: items
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(item),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget getStepWidget() {
    switch (currentStep) {
      case 0:
        return buildUploadStep();
      case 1:
        return buildCategoryStep();
      case 2:
        return buildTypeStep();
      case 3:
        return buildTimeStep();
      case 4:
        return buildTotalStep();
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    bool canProceed = isValidInput();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: currentStep == 0 ? null : previousStep,
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: currentStep == 0 ? Colors.transparent : Colors.black,
              ),
            ),
            const Text(
              "Quizy",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 35),
        child: Column(
          children: [
            getStepWidget(),
            const Spacer(),
            Center(
              child: SizedBox(
                width: 328,
                height: 50,
                child: ElevatedButton(
                  onPressed: canProceed ? nextStep : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        canProceed ? Colors.lightBlue : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    currentStep == 4 ? "Selesai" : "Lanjut",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
