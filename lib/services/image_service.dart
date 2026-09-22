import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// Result of a single-image pick attempt. `error` is null on success.
/// `error` is set to a message OR the special value 'PERMISSION_DENIED'
/// which the UI uses to show a "Open Settings" action.
class ImagePickResult {
  final File? image;
  final String? error;
  const ImagePickResult({this.image, this.error});
}

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<ImagePickResult> pickSingleImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (picked == null) {
        // User backed out of the picker — not an error.
        return const ImagePickResult();
      }

      final file = File(picked.path);
      if (!await file.exists() || await file.length() == 0) {
        return const ImagePickResult(error: 'That file could not be read. Try a different photo.');
      }

      return ImagePickResult(image: file);
    } on PlatformException catch (e) {
      if (e.code == 'photo_access_denied' || e.code == 'permission_denied') {
        return const ImagePickResult(error: 'PERMISSION_DENIED');
      }
      return ImagePickResult(error: 'Could not open photo picker: ${e.message}');
    } catch (_) {
      return const ImagePickResult(error: 'Something went wrong while picking the image.');
    }
  }

  /// Decodes an image file into its real, full-resolution pixel data.
  /// This is the single source of truth used for both on-screen
  /// positioning and final tile slicing, so what the user sees is
  /// exactly what gets exported.
  static Future<ui.Image> decodeImageFile(File file) async {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}
