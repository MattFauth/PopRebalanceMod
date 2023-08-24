import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:archive/archive.dart';


void main() {
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pop Rebalance Mod',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Pop Rebalance Mod'),
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
  bool _isFileLoaded = false;
  bool _isLoading = false; // to track if uploading is in progress
  List<String> _uploadedFileNames = []; // to store names of uploaded files
  List<Uint8List> _uploadedFilesData = []; // to store data of uploaded files
  bool _isCountingPopulation = false;  // New state to track if counting is in progress
  int _totalPopulation = 0;  // New state to store the total population
  double _scalingFactor = 1.0;
  List<String> _filePaths = []; // to store paths of uploaded files


  void _showSnackBar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}


  Future<void> _pickFiles() async {
  _isLoading = true;
  // Show a loading indicator
  setState(() {});

  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['txt'],
    allowMultiple: true,
    withData: true,  // This flag is important
  );

  if (result != null) {
    // Now, result.files should contain the bytes
    List<Uint8List> byteData = result.files.map((file) => file.bytes!).toList();
    await _uploadFiles(byteData, result);
  } else {
    // User canceled the picker
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No files selected')),
    );
  }
  _isLoading = false;
  // Hide the loading indicator
  setState(() {});
}


    Future<void> _uploadFiles(List<Uint8List> byteData, FilePickerResult result) async {
    // Show a snackbar for uploading files
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Uploading files...')),
    );
    // Create a multipart request for the POST api call
    var request = http.MultipartRequest('POST', Uri.parse('http://127.0.0.1:8000/upload/'));
    if (result != null) {
      for (var file in result.files) {
        var fileData = file.bytes!;
        var fileName = file.name;
        var multipartFile = http.MultipartFile.fromBytes(
          'files',
          fileData,
          filename: fileName,
        );
        _uploadedFilesData.add(fileData);
        _uploadedFileNames.add(fileName);
        request.files.add(multipartFile);
      }
    }
    // Send the request
    var response = await request.send();
    // Check if the upload is successful
    if (response.statusCode == 200) {
      // Show a snackbar for successful upload
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Files uploaded successfully')),
      );
      _isFileLoaded = true;  // Update _isFileLoaded to true
      setState(() {});
    } else {
      // Handle the error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading files')),
      );
    }
  }


Future<void> _countPopulation() async {
  print('Sending request to count population...');
  _isCountingPopulation = true;
  setState(() {});
  var request = http.MultipartRequest('POST', Uri.parse('http://127.0.0.1:8000/count/'));
  for (int i = 0; i < _uploadedFilesData.length; i++) {
    var fileData = _uploadedFilesData[i];
    var fileName = _uploadedFileNames[i];
    var multipartFile = http.MultipartFile.fromBytes(
      'files',
      fileData,
      filename: fileName,
    );
    request.files.add(multipartFile);
  }
  print('Request sent. Awaiting response...');
  var response = await request.send();
  response.stream.transform(utf8.decoder).listen((value) {
    print('Received response: $value');
    var data = jsonDecode(value);
    print('Decoded JSON: $data');
    if (data['total_population'] != null) {
      _totalPopulation = data['total_population'];
    }
    _isCountingPopulation = false;
    setState(() {});
  });
}


Future<void> _scalePopulation() async {
  _isLoading = true;  // Set loading state to true
  setState(() {});
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('http://127.0.0.1:8000/scale/'),
  );
  request.fields['scaling_factor'] = _scalingFactor.toString();  // Add scaling factor
  for (int i = 0; i < _uploadedFilesData.length; i++) {
    var multipartFile = http.MultipartFile.fromBytes(
      'files',
      _uploadedFilesData[i],
      filename: _uploadedFileNames[i],
    );
    request.files.add(multipartFile);
  }
  var response = await request.send();
  response.stream.transform(utf8.decoder).listen((value) {
    var data = jsonDecode(value);
    var archive = Archive();
    data.forEach((filename, fileContent) {
      var fileBytes = utf8.encode(fileContent);
      var archiveFile = ArchiveFile(filename, fileBytes.length, fileBytes);
      archive.addFile(archiveFile);
    });
    var zipEncoder = ZipEncoder();
    var zipData = zipEncoder.encode(archive);
    // Create and click on a download link to allow the user to download the zip
    var blob = html.Blob([zipData]);
    var url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..target = 'blank'
      ..download = 'scaled_population.zip'
      ..click();
    html.Url.revokeObjectUrl(url);
    _showSnackBar("Population scaled successfully");
    _isLoading = false;  // Set loading state back to false
    setState(() {});
  }, onError: (e) {
    _showSnackBar("An error occurred: $e");
    _isLoading = false;  // Set loading state back to false
    setState(() {});
  });
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
              onPressed: _isLoading ? null : _pickFiles,
              child: Text('Upload Files'),
            ),
            ElevatedButton(
              onPressed: _isLoading || !_isFileLoaded ? null : _countPopulation,
              child: Text('Count Population'),
            ),
            ElevatedButton(
              onPressed: _isLoading || !_isFileLoaded ? null : _scalePopulation,
              child: Text('Scale Population'),
            ),
            Text("Scaling Function: y = x * scaling_factor"),
            TextField(
              decoration: InputDecoration(labelText: "Enter scaling factor"),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _scalingFactor = double.tryParse(value) ?? 1.0;
              },
            ),
            // Loading indicator for file upload
            if (_isLoading)
              CircularProgressIndicator(),
            // Loading indicator for population counting
            if (_isCountingPopulation)
              CircularProgressIndicator(),
            // Display total population
            if (_totalPopulation > 0)
              Text("Total Population: $_totalPopulation"),
            // List of uploaded files
            Expanded(
              child: ListView.builder(
                itemCount: _uploadedFileNames.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_uploadedFileNames[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // You can add more logic here if necessary
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}