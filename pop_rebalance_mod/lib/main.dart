import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


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
  List<String> _uploadedFiles = []; // to store names of uploaded files
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
  );

  if (result != null) {
    if (result.files.first.bytes != null) {
      List<Uint8List> byteData = result.files.map((file) => file.bytes!).toList();
      await _uploadFiles(byteData);
    } else {
      // Handle the case for non-web platforms
      List<File> files = result.paths.map((path) => File(path!)).toList();
      await _uploadFiles(files);
    }
  } else {
    // User canceled the picker
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No files selected')),
    );
  }
  }

  _isLoading = false;
  // Hide the loading indicator
  setState(() {});
}


  Future<void> _uploadFiles(List<File> files) async {
    // Show a snackbar for uploading files
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Uploading files...')),
    );

    // Simulated delay for the upload process
    await Future.delayed(Duration(seconds: 2));

    // Add file names to _uploadedFiles list
    for (var file in files) {
      _uploadedFiles.add(file.path.split("/").last);
    }

    // Show a snackbar for successful upload
    ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Files uploaded successfully')),
    );
    _isFileLoaded = true;  // Atualizar _isFileLoaded para true aqui
    setState(() {});
  }


  Future<void> _countPopulation() async {
  _isCountingPopulation = true;  // Set counting state to true
  setState(() {});
  // Create a multipart request for the POST api call
  var request = http.MultipartRequest('POST', Uri.parse('http://your_backend_url/count/'));
  // Attach the files to the request
  for (var file in _uploadedFiles) {
    request.files.add(await http.MultipartFile.fromPath('files', file));
  }
  // Send the request
  var response = await request.send();
  // Listen for the response
  response.stream.transform(utf8.decoder).listen((value) {
    // Parse the JSON response
    var data = jsonDecode(value);
    // Update the total population from the server response
    if (data['total_population'] != null) {
      _totalPopulation = data['total_population'];
    }
    _isCountingPopulation = false;  // Set counting state back to false
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
  // Assume _filePaths contains the list of file paths to upload
  for (var path in _filePaths) {
    request.files.add(await http.MultipartFile.fromPath('files', path));
  }
  // Send the request
  var response = await request.send();
  // Listen for the response
  response.stream.transform(utf8.decoder).listen((value) {
    // Parse the JSON response
    var data = jsonDecode(value);
    // Check if the scaling was successful
    if (data['message'] == 'Population scaled') {
      // Update some state variables or show a success message
      _showSnackBar("Population scaled successfully");
    } else {
      // Show an error message
      _showSnackBar("Failed to scale population");
    }
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
                itemCount: _uploadedFiles.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_uploadedFiles[index]),
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