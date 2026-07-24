import 'package:flutter/material.dart';

/// Widget for displaying an image carousel with page indicator.
///
/// Shows multiple images in a PageView with a counter indicator
/// in the top-right corner showing current position.
///
/// Example:
/// ```dart
/// ImageCarouselWidget(
///   images: imageDataList,
///   pageController: pageController,
///   currentIndex: currentImageIndex,
///   width: displayWidth,
///   height: displayHeight,
///   rotation: rotation,
///   cropTop: cropTop,
///   cropBottom: cropBottom,
///   alignment: alignment,
///   onPageChanged: (index) => setState(() => currentIndex = index),
///   imageBuilder: (imageData, width, height) => buildImage(imageData),
/// )
/// ```
class ImageCarouselWidget extends StatelessWidget {
  final List<dynamic> images;
  final PageController pageController;
  final int currentIndex;
  final double width;
  final double height;
  final double rotation;
  final double cropTop;
  final double cropBottom;
  final Alignment alignment;
  final ValueChanged<int> onPageChanged;
  final Widget Function(
    Map<String, dynamic> imageData,
    double width,
    double height,
  )
  imageBuilder;

  const ImageCarouselWidget({
    super.key,
    required this.images,
    required this.pageController,
    required this.currentIndex,
    required this.width,
    required this.height,
    required this.rotation,
    required this.cropTop,
    required this.cropBottom,
    required this.alignment,
    required this.onPageChanged,
    required this.imageBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRect(
          child: Align(
            alignment: alignment,
            heightFactor: 1.0 - cropTop - cropBottom,
            child: Transform.rotate(
              angle: rotation * 3.141592653589793 / 180,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: SizedBox(
                  width: width,
                  height: height,
                  child: PageView.builder(
                    controller: pageController,
                    itemCount: images.length,
                    onPageChanged: onPageChanged,
                    itemBuilder: (context, index) {
                      if (index >= images.length)
                        return const SizedBox.shrink();
                      final item = images[index];
                      if (item is! Map<String, dynamic>)
                        return const SizedBox.shrink();
                      final imageData = item;
                      return imageBuilder(imageData, width, height);
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        // Image indicator
        if (images.length > 1)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${currentIndex + 1}/${images.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
