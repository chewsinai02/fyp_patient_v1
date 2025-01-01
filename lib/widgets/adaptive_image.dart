import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'adaptive_image_theme.dart';

class AdaptiveImage extends StatelessWidget {
  final String? imageUrl;
  final String? fallbackAsset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool circle;

  const AdaptiveImage({
    super.key,
    required this.imageUrl,
    this.fallbackAsset = 'assets/images/profile.png',
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.circle = false,
  });

  bool _isNetworkImage(String? url) {
    if (url == null) return false;
    return url.startsWith('http') ||
        url.startsWith('https') ||
        url.startsWith('https://firebasestorage.googleapis.com');
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildAssetImage(fallbackAsset!);
    }

    // Handle network images (including Firebase Storage)
    if (_isNetworkImage(imageUrl)) {
      // Check if it's a GIF
      final isGif = imageUrl!.toLowerCase().endsWith('.gif');
      Widget imageWidget;

      if (isGif) {
        imageWidget = Image.network(
          imageUrl!,
          width: width,
          height: height,
          fit: fit,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildLoadingWidget();
          },
          errorBuilder: (context, error, stackTrace) {
            print('Error loading GIF: $error');
            return _buildAssetImage(fallbackAsset!);
          },
        );
      } else {
        imageWidget = CachedNetworkImage(
          imageUrl: imageUrl!,
          width: width,
          height: height,
          fit: fit,
          placeholder: (context, url) => _buildLoadingWidget(),
          errorWidget: (context, url, error) {
            print('Error loading network image: $error');
            return _buildAssetImage(fallbackAsset!);
          },
        );
      }

      if (circle) {
        return ClipOval(child: imageWidget);
      } else if (borderRadius != null) {
        return ClipRRect(
          borderRadius: borderRadius!,
          child: imageWidget,
        );
      }
      return imageWidget;
    }

    // Handle local assets
    String assetPath = imageUrl!;
    if (!assetPath.startsWith('assets/')) {
      assetPath = 'assets/$assetPath';
    }
    return _buildAssetImage(assetPath);
  }

  Widget _buildLoadingWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildAssetImage(String assetPath) {
    Widget assetImage = Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        print('Error loading asset image: $error');
        print('Attempted path: $assetPath');
        // Return a fallback image from assets
        return Image.asset(
          'assets/images/profile.png',
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            // If even the fallback fails, show an icon
            return Container(
              width: width,
              height: height,
              color: Colors.grey[200],
              child: Icon(
                Icons.person,
                size: width != null ? width! * 0.5 : 40,
                color: Colors.grey[400],
              ),
            );
          },
        );
      },
    );

    if (circle) {
      return ClipOval(child: assetImage);
    } else if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: assetImage,
      );
    }

    return assetImage;
  }
}
