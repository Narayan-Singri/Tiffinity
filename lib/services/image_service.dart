import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ImageService {
  // 32 MB limit in bytes
  static const int MAX_FILE_SIZE = 32 * 1024 * 1024;

  static Future<String?> uploadToImgBB(File imageFile) async {
    try {
      // Check file size
      final fileSize = await imageFile.length();
      if (fileSize > MAX_FILE_SIZE) {
        print(
          '❌ Image too large: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB. Max: 32MB',
        );
        return 'SIZE_EXCEEDED';
      }

      final apiKey = dotenv.env['IMGBB_API_KEY'];
      if (apiKey == null) {
        print('❌ ImgBB API key not found in .env file');
        return null;
      }

      print('📤 Uploading image to ImgBB...');
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey'),
      );
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.toBytes();
        var jsonResponse = jsonDecode(String.fromCharCodes(responseData));
        final imageUrl = jsonResponse['data']['url'];
        print('✅ Image uploaded successfully: $imageUrl');
        return imageUrl;
      } else {
        print('❌ ImgBB upload failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Image upload error: $e');
      return null;
    }
  }
}
