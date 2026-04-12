import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:extended_image/extended_image.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';

class CropScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const CropScreen({super.key, required this.imageBytes});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  final GlobalKey<ExtendedImageEditorState> editorKey = GlobalKey();
bool _isCropping = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Adjust Image"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
    
onPressed: () async {
  final state = editorKey.currentState;

  if (state == null) return;

  final raw = state.rawImageData;
  final rect = state.getCropRect();

  if (raw == null || rect == null) return;

  /// 🌐 WEB → return FAST (no processing)
  if (kIsWeb) {
    Navigator.pop(context, raw); // ⚡ instant
    return;
  }

  /// 📱 MOBILE → full processing
  setState(() => _isCropping = true);

  await Future.delayed(const Duration(milliseconds: 50));

  final original = img.decodeImage(raw);
  if (original == null) return;

  final cropped = img.copyCrop(
    original,
    x: rect.left.toInt(),
    y: rect.top.toInt(),
    width: rect.width.toInt(),
    height: rect.height.toInt(),
  );

  final croppedBytes = Uint8List.fromList(
    img.encodeJpg(cropped, quality: 75),
  );

  Navigator.pop(context, croppedBytes);
}



          )
        ],
      ),


body: Stack(
  children: [
    ExtendedImage.memory(
      widget.imageBytes,
      fit: BoxFit.contain,
      mode: ExtendedImageMode.editor,
      extendedImageEditorKey: editorKey,
      initEditorConfigHandler: (state) {
        return EditorConfig(
          maxScale: 5.0,
          cropRectPadding: const EdgeInsets.all(20),
          hitTestSize: 20,
          cropAspectRatio: 1,
        );
      },
    ),

    if (_isCropping)
      Container(
        color: Colors.black54,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
  ],
),
     




    );
  }
}