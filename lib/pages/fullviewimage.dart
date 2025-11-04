// fullviewimage.dart - Updated for Base64 Images
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';

class FullScreenImagePage extends StatelessWidget {
  final String imageData;
  final bool isBase64;

  const FullScreenImagePage({
    Key? key,
    required this.imageData,
    this.isBase64 = true,
  }) : super(key: key);

  // Helper function to decode base64 string to Uint8List
  Uint8List? _decodeBase64(String base64String) {
    try {
      // Remove data:image/jpeg;base64, prefix if exists
      String cleanBase64 = base64String;
      if (base64String.contains(',')) {
        cleanBase64 = base64String.split(',').last;
      }

      return base64Decode(cleanBase64);
    } catch (e) {
      print('Error decoding base64: $e');
      return null;
    }
  }

  // Widget helper untuk menampilkan gambar
  Widget _buildImage() {
    if (isBase64) {
      final Uint8List? imageBytes = _decodeBase64(imageData);

      if (imageBytes != null) {
        return Image.memory(
          imageBytes,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey.shade800,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image_rounded,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Gambar tidak dapat dimuat',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        return Container(
          color: Colors.grey.shade800,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'Format gambar tidak valid',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } else {
      // Fallback untuk URL biasa
      return Image.network(
        imageData,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.shade800,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_rounded,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'Gambar tidak dapat dimuat',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: Text(
          'Gambar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 3.0,
          child: _buildImage(),
        ),
      ),
    );
  }
}

class FullScreenGalleryPage extends StatefulWidget {
  final List<String> imageDataList;
  final int initialIndex;
  final bool isBase64;

  const FullScreenGalleryPage({
    Key? key,
    required this.imageDataList,
    required this.initialIndex,
    this.isBase64 = true,
  }) : super(key: key);

  @override
  State<FullScreenGalleryPage> createState() => _FullScreenGalleryPageState();
}

class _FullScreenGalleryPageState extends State<FullScreenGalleryPage> {
  late PageController _pageController;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Helper function to decode base64 string to Uint8List
  Uint8List? _decodeBase64(String base64String) {
    try {
      // Remove data:image/jpeg;base64, prefix if exists
      String cleanBase64 = base64String;
      if (base64String.contains(',')) {
        cleanBase64 = base64String.split(',').last;
      }

      return base64Decode(cleanBase64);
    } catch (e) {
      print('Error decoding base64: $e');
      return null;
    }
  }

  // Widget helper untuk menampilkan gambar dalam gallery
  Widget _buildGalleryImage(String imageData) {
    if (widget.isBase64) {
      final Uint8List? imageBytes = _decodeBase64(imageData);

      if (imageBytes != null) {
        return Image.memory(
          imageBytes,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey.shade800,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image_rounded,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Gambar tidak dapat dimuat',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        return Container(
          color: Colors.grey.shade800,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'Format gambar tidak valid',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } else {
      // Fallback untuk URL biasa
      return Image.network(
        imageData,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.shade800,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_rounded,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'Gambar tidak dapat dimuat',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: Text(
          'Galeri ${currentIndex + 1}/${widget.imageDataList.length}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: Colors.white,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Info Gambar'),
                  content: Text(
                    'Gambar ${currentIndex + 1} dari ${widget.imageDataList.length}\n\n'
                    'Gunakan gesture pinch untuk zoom in/out\n'
                    'Swipe untuk navigasi antar gambar',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageDataList.length,
            onPageChanged: (index) => setState(() => currentIndex = index),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                panEnabled: true,
                boundaryMargin: EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 3.0,
                child: Center(
                  child: _buildGalleryImage(widget.imageDataList[index]),
                ),
              );
            },
          ),
          // Indicator dots
          if (widget.imageDataList.length > 1)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imageDataList.length,
                  (index) => Container(
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: currentIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
