import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageCompressor {
  // 选择图片并压缩到2K以下，然后转换为Base64
  static Future<String?> pickAndCompressImage() async {
    try {
      // 使用image_picker选择图片
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return null;

      // 获取原始图片文件
      File imageFile = File(image.path);

      // 压缩图片
      File? compressedFile = await compressImage(imageFile);

      if (compressedFile == null) return null;

      // 将压缩后的图片转为Base64
      String base64Image = await convertToBase64(compressedFile);

      return base64Image;
    } catch (e) {
      if (kDebugMode) {
        print('选择图片并压缩出错: $e');
      }
      return null;
    }
  }

  static Future<String?> compressAndConvertImage(File imageFile) async {
    try {
      // 压缩图片
      File? compressedFile = await compressImage(imageFile);

      if (compressedFile == null) return null;

      // 将压缩后的图片转为Base64
      String base64Image = await convertToBase64(compressedFile);

      return base64Image;
    } catch (e) {
      if (kDebugMode) {
        print('压缩并转化图片出错: $e');
      }
      return null;
    }
  }

  static Future<File?> compressImage(File file) async {
    try {
      // 设置目标分辨率（2K约为2048x1080）
      const int maxWidth = 2048;
      const int maxHeight = 1080;
      const int quality = 85; // 压缩质量（0-100）

      // 获取临时目录来存储压缩后的文件
      final String targetPath =
          '${file.parent.path}/compressed_${file.path.split('/').last}';

      // 使用flutter_image_compress进行压缩
      final XFile? compressedXFile =
          await FlutterImageCompress.compressAndGetFile(
            file.absolute.path,
            targetPath,
            quality: quality,
            minWidth: maxWidth,
            minHeight: maxHeight,
          );

      if (compressedXFile == null) return null;

      return File(compressedXFile.path);
    } catch (e) {
      if (kDebugMode) {
        print('压缩图片失败: $e');
      }
      return null;
    }
  }

  // 将文件转为Base64字符串
  static Future<String> convertToBase64(File file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }
}
