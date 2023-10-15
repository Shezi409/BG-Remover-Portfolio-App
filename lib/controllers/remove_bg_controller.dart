import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:core';
import 'package:path/path.dart' as path;

class BackgroundRemoverController extends GetxController {
  Uint8List? imageFile;
  String? imagePath;
  ScreenshotController controller = ScreenshotController();
  var isLoading = false.obs;

  Future<Uint8List> removeBg(String? imagePath) async {
    isLoading = true.obs;
    update();
    var request = http.MultipartRequest(
        "POST", Uri.parse("https://api.remove.bg/v1.0/removebg"));
    request.files
        .add(await http.MultipartFile.fromPath("image_file", imagePath!));
    request.headers.addAll({"X-API-Key": "XH5axMWfLx5SSxSFLqEvJcMA"});
    final response = await request.send();
    if (response.statusCode == 200) {
      http.Response imgRes = await http.Response.fromStream(response);
      isLoading = false.obs;
      update();
      return imgRes.bodyBytes;
    } else {
      throw Exception("Error");
    }
  }

  void pickImage(ImageSource source) async {
    try {
      final pickedImage = await ImagePicker().pickImage(source: source);
      if (pickedImage != null) {
        imagePath = pickedImage.path;
        print('This is img Path ${imagePath}');
        imageFile = await pickedImage.readAsBytes();
        print('This is img file ${imageFile}');
        update();
      }
    } catch (e) {
      imageFile = null;
      update();
    }
  }

  void cleanUp() {
    imageFile = null;
    update();
  }

  void saveImage() async {
    bool isGranted = await Permission.storage.isGranted;
    if (!isGranted) {
      isGranted = await Permission.storage.request().isGranted;
    }
    if (isGranted) {
      String directory = (await getExternalStorageDirectory())!.path;
      String fileName = "${DateTime.now().microsecondsSinceEpoch}.png";
      controller.captureAndSave(directory, fileName: fileName);
    }
  }

  downloadImage() async {
    var perm = await Permission.storage.request();
    var folderName = 'BGRemover';
    var fileName = '${DateTime.now().millisecondsSinceEpoch}.png';

    if (perm.isGranted) {
      final directory = Directory('storage/emulated/0/');

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      await controller.captureAndSave(directory.path,
          delay: Duration(milliseconds: 100),
          fileName: fileName,
          pixelRatio: 1.0);
    }
  }

  gallerySaver() async {
    final tempDir = await getTemporaryDirectory();
    final path = '${tempDir.path}/myfile.jpg';
    await Dio().download(imagePath!, path);
    await GallerySaver.saveImage(path, albumName: 'BG Remover');
  }
}
