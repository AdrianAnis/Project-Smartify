import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart'; 
import 'quiz_template.dart';

String _getApiKey() {
  final key = dotenv.env['GEMINI_API_KEY'];
  if (key == null || key.isEmpty) {
    // Tidak langsung lempar exception agar UX lebih halus
    return ''; 
  }
  return key;
}

String _getModel() {
  return dotenv.env['MODEL_NAME'] ?? 'gemini-2.5-flash';
}

String _buildPrompt({
  required String category,
  required String type,
  required String time,
  required int total,
  String? fileText,
}) {
  final source = (fileText != null && fileText.trim().isNotEmpty)
      ? '\nSumber:\n$fileText'
      : '';

  // Instruksi ketat agar output AI berbentuk JSON murni
  return '''
Buat $total soal berbahasa Indonesia berdasarkan kriteria berikut:
Level: $category
Jenis soal: $type
Durasi: $time
$source

PENTING: BALAS HANYA DENGAN JSON VALID TANPA TEKS PENDAHULUAN/PENUTUP.
Gunakan format JSON yang TEPAT seperti ini:
{
  "quiz_title": "Quiz ${category} ${type}",
  "questions": [
    {
      "id": 1,
      "type": "multiple_choice" | "essay",
      "question": "Teks soal",
      "choices": ["opsi A","opsi B","opsi C","opsi D"], // gunakan [] jika type "essay"
      "answer_index": 0, // 0-3 untuk multiple_choice, null untuk essay
      "explanation": "penjelasan singkat"
    }
  ]
}
''';
}

/// Fungsi utama untuk menghasilkan soal dari Gemini AI.
/// Mengembalikan Map dengan isi:
/// { "raw": rawTextString, "questions": List<Question>?, "diagnostic": String }
Future<Map<String, dynamic>> generateQuizRaw({
  required String category,
  required String type,
  required String time,
  required int total,
  String? fileText,
}) async {
  final apiKey = _getApiKey();
  if (apiKey.isEmpty) {
    throw Exception('API Key tidak tersedia. Pastikan GEMINI_API_KEY ada di .env');
  }

  final modelName = _getModel();
  final prompt = _buildPrompt(
    category: category,
    type: type,
    time: time,
    total: total,
    fileText: fileText,
  );

  // Inisialisasi model Gemini
  final model = GenerativeModel(model: modelName, apiKey: apiKey);

  String rawText = '';
  try {
    // Panggil API Gemini
    final response = await model.generateContent(
      [Content.text(prompt)],
      generationConfig: GenerationConfig(
        temperature: 0.2,
      ),
    );

    rawText = response.text ?? '';
    if (rawText.isEmpty) {
      throw Exception('Respons dari Gemini kosong.');
    }
  } catch (e) {
    throw Exception('Permintaan Gemini API Gagal: ${e.toString()}');
  }

  // 🔧 Tahap pembersihan & parsing JSON
  try {
    print('--- RAW RESPONSE DARI GEMINI ---');
    print(rawText);

    // Bersihkan karakter tambahan seperti markdown atau teks non-JSON
    rawText = rawText
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .replaceAll('\n', ' ')
        .trim();

    // Hapus teks sebelum tanda { pertama
    final firstBrace = rawText.indexOf('{');
    if (firstBrace > 0) {
      rawText = rawText.substring(firstBrace);
    }

    // Potong sampai penutup JSON terakhir
    final lastBrace = rawText.lastIndexOf('}');
    if (lastBrace != -1 && lastBrace < rawText.length - 1) {
      rawText = rawText.substring(0, lastBrace + 1);
    }

    print('--- TEKS SETELAH DIBERSIHKAN ---');
    print(rawText);

    // Parse JSON
    final parsed = jsonDecode(rawText);
    final questionsAny = parsed['questions'];

    if (questionsAny == null || questionsAny is! List) {
      return {
        "raw": rawText,
        "questions": null,
        "diagnostic": "JSON tidak memiliki field 'questions' yang merupakan List."
      };
    }

    final List<Question> questions = (questionsAny).map<Question>((q) {
      final id = q['id'] is int
          ? q['id']
          : int.tryParse(q['id']?.toString() ?? '') ?? 0;
      final text = q['question']?.toString() ?? '';
      final choicesAny = q['choices'] ?? [];
      final List<String> choices =
          List<String>.from((choicesAny as List).map((e) => e.toString()));
      final answerIdx = q['answer_index'];
      final type = q['type']?.toString().toLowerCase();

      // hanya pakai answer index jika multiple choice
      final finalAnswerIdx =
          (type == 'multiple_choice' && answerIdx is int) ? answerIdx : null;

      return Question(
        id: id,
        question: text,
        choices: choices,
        answerIndex: finalAnswerIdx,
      );
    }).toList();

    return {
      "raw": rawText,
      "questions": questions,
      "diagnostic": "SUCCESS",
    };
  } catch (e) {
    // Kalau parsing gagal, tetap kirim raw-nya untuk debugging
    return {
      "raw": rawText,
      "questions": null,
      "diagnostic": "Parsing JSON gagal: ${e.toString()}",
    };
  }
}
