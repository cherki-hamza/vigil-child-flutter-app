// ignore_for_file: avoid_print, unused_element

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart'; // To pick files

class FilesServiceChild {

  
  String? childId;
  String? childName;
  int parentId = 1;
  String parentName = "Parent Name";
  List<Map<String, dynamic>> filesToUpload = [];
  bool isLoading = true;

  // Method to handle call logs
  Future<void> vigilFiles() async {

    print('start Fetching files...');

    // Get user data from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    childId = prefs.getString('childId');
    childName = prefs.getString('childName');

     try {
      // Using FilePicker to fetch all images and videos
      var result = await FilePicker.platform.pickFiles(
        type: FileType.media,
        allowMultiple: true,
      );

      if (result != null) {
        for (PlatformFile file in result.files) {
          if (file.path != null) {
            File fileObj = File(file.path!);
            String base64String = await _convertFileToBase64(fileObj);

            filesToUpload.add({
              'url': base64String, // Store Base64 in 'url' field
              'public_id': null, // Optional: If using cloud storage, add public ID here
              'file_type': file.extension, // MIME type can be guessed from extension
              'original_filename': file.name,
              'child_id': childId,
              'child_name': childName,
              'parent_id': parentId,
              'parent_name': parentName,
            });
          }
        }
       
          isLoading = false; // Update loading state
       
      } else {
        
          isLoading = false; // No files were picked
       
        print("No files selected");
      }
    } catch (e) {
      
      isLoading = false; // Update loading state on error
     
      print("Error fetching files: $e");
    }


  } 


  // Method to convert file to Base64 string
  Future<String> _convertFileToBase64(File file) async {
    try {
      List<int> fileBytes = await file.readAsBytes();
      String base64String = base64Encode(fileBytes);
      return base64String;
    } catch (e) {
      print("Error converting file to Base64: $e");
      return '';
    }
  }

  // Method to upload multiple files to server
  Future<void> _uploadFiles() async {
    
    if (filesToUpload.isEmpty) return;

    var url = Uri.parse('https://nodeapi-6omc.onrender.com/api/files/store_files'); // Replace with your server URL

    try {
      var response = await http.post(
        url,
        body: json.encode({'files': filesToUpload}), // Sending an array of files
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        List<dynamic> savedFiles = responseData['savedFiles'];
        List<dynamic> duplicateFiles = responseData['duplicateFiles'];

        print("Files uploaded successfully:");
        print("Saved Files: ${savedFiles.length}");
        print("Duplicate Files: ${duplicateFiles.length}");

        // You can use this data to show a summary to the user if needed
      } else {
        print("Failed to upload files: ${response.body}");
      }
    } catch (e) {
      print("Error uploading files: $e");
    }
  }
 

}
