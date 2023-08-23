import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;


void main() {
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  Future<void> _pickFiles() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['txt'],
    allowMultiple: true,
  );

  if (result != null) {
    List<File> files = result.paths.map((path) => File(path!)).toList();
    _uploadFiles(files);  // Chama o método para fazer o upload
  } else {
    // O usuário cancelou a seleção de arquivos
  }
}

Future<void> _uploadFiles(List<File> files) async {
  var url = 'http://localhost:8000/upload/';
  var request = http.MultipartRequest('POST', Uri.parse(url));

  for (var file in files) {
    request.files.add(http.MultipartFile(
      'files', // o nome do campo no seu servidor
      file.readAsBytes().asStream(),
      file.lengthSync(),
      filename: file.path.split("/").last,
    ));
  }

  var response = await request.send();

  if (response.statusCode == 200) {
    print("Upload successful");
  } else {
    print("Upload failed");
  }
}


  Future<void> _countPopulation() async {
  var url = 'http://localhost:8000/count/';
  var response = await http.post(
    Uri.parse(url),
  );

  if (response.statusCode == 200) {
    // TODO: Manipular a resposta do servidor aqui (ex.: exibir a população total)
  } else {
    // TODO: Manipular erros aqui
  }
}

  Future<void> _scalePopulation() async {
  var url = 'http://localhost:8000/scale/';
  var response = await http.post(
    Uri.parse(url),
  );

  if (response.statusCode == 200) {
    // TODO: Manipular a resposta do servidor aqui (ex.: confirmar o ajuste da população)
  } else {
    // TODO: Manipular erros aqui
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _pickFiles,
              child: Text('Upload Files'),
            ),
            ElevatedButton(
              onPressed: _countPopulation,
              child: Text('Count Population'),
            ),
            ElevatedButton(
              onPressed: _scalePopulation,
              child: Text('Scale Population'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Você pode adicionar mais lógica aqui se necessário
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
