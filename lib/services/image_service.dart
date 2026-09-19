import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// Result of a pick attempt. `error` is null on full success.
/// `error` is set to a message OR the special value 'PERMISSION_DENIED'
/// which the UI uses to show a "Open Settings" action.
class ImagePickResult {
  final List<File> images;
  final String? error;
  const ImagePickResult({this.images = const [], this.error});
}

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<ImagePickResult> pickImages({required int remainingSlots}) async {
    if (remainingSlots <= 0) {
      return const ImagePickResult(error: 'You have reached the maximum number of images.');
    }
    try {
      final List<XFile> picked = await _picker.pickMultiImage(imageQuality: 90);

      if (picked.isEmpty) {
        // User backed out of the picker — not an error.
        return const ImagePickResult();
      }

      final limited = picked.take(remainingSlots).toList();
      final files = <File>[];
      for (final x in limited) {
        final f = File(x.path);
        if (await f.exists() && await f.length() > 0) {
          files.add(f);
        }
      }

      final skipped = picked.length - limited.length;
      String? warning;
      if (skipped > 0) {
        warning = 'Only added $remainingSlots image(s) — limit reached.';
      }
      if (files.isEmpty && warning == null) {
        warning = 'Selected file(s) could not be read. Try a different photo.';
      }

      return ImagePickResult(images: files, error: warning);
    } on PlatformException catch (e) {
      if (e.code == 'photo_access_denied' || e.code == 'permission_denied') {
        return const ImagePickResult(error: 'PERMISSION_DENIED');
      }
      return ImagePickResult(error: 'Could not open photo picker: ${e.message}');
    } catch (_) {
      return const ImagePickResult(error: 'Something went wrong while picking images.');
    }
  }
}
