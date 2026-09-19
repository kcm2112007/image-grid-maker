import 'dart:io';
import 'package:flutter/material.dart';

/// One selected photo, with a real remove button.
/// If the file turns out to be corrupted/unreadable, shows a broken-image
/// icon and reports it back so the parent can drop it from the list.
class SelectedImageTile extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;
  final VoidCallback onLoadError;

  const SelectedImageTile({
    super.key,
    required this.file,
    required this.onRemove,
    required this.onLoadError,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              WidgetsBinding.instance.addPostFrameCallback((_) => onLoadError());
              return Container(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Icon(Icons.broken_image_outlined,
                    color: Theme.of(context).colorScheme.onErrorContainer),
              );
            },
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
