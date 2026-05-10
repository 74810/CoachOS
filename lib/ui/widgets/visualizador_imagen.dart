import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class VisualizadorImagen extends StatelessWidget {
  final String imageUrl;

  const VisualizadorImagen({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.xmark, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CupertinoActivityIndicator(color: Colors.white));
            },
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.white),
          ),
        ),
      ),
    );
  }
}