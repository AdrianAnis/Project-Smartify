import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Center(
            child: Text(
              'Quizy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        body: const FileUploadBody(),
      ),
    );
  }
}

class FileUploadBody extends StatefulWidget {
  const FileUploadBody({super.key});

  @override
  State<FileUploadBody> createState() => _FileUploadBodyState();
}

class _FileUploadBodyState extends State<FileUploadBody> {
  String? selectedFileName; 

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        selectedFileName = result.files.single.name;
      });
    } else {
      print("User canceled file picking.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 50.0),
      child: Column(
        children: [
          Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 48.0),
                child: Text(
                  "Silahkan unggah file materi yang\ningin anda pelajari lebih lanjut!",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: 48),
                child: Image.asset('assets/quizy_inputfile.png'),
              ),
            ],
          ),
          const SizedBox(height: 50),
          InkWell(
            onTap: pickFile,
            child: Container(
              width: 328,
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 52),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Row(
                    children: [
                      Text(
                        selectedFileName ?? "Upload File",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      const Padding(
                        padding: EdgeInsets.only(right: 24.0),
                        child: Icon(
                          Icons.upload_outlined,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 450,),
          Container(
            width: 328,
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 52),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(24),
              ),
          )
        ],
      ),
    );
  }
}
