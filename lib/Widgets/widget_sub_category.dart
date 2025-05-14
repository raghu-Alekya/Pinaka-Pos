import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../Constants/text.dart';
import '../Utilities/shimmer_effect.dart';

class SubCategoryGridWidget extends StatelessWidget {
  final bool isLoading;
  final List<Map<String, dynamic>> subCategories;
  final int? selectedSubCategoryIndex;
  final Function(int) onSubCategoryTapped;

  const SubCategoryGridWidget({
    super.key,
    required this.isLoading,
    required this.subCategories,
    required this.onSubCategoryTapped,
    this.selectedSubCategoryIndex,
  });

  Widget _buildImage(String imagePath) {
    if (imagePath.startsWith('assets/') && imagePath.endsWith('.svg')) {
      return SvgPicture.asset(
        imagePath,
        height: 40,
        width: 40,
        placeholderBuilder: (context) => const Icon(Icons.image, size: 40),
      );
    } else if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        height: 40,
        width: 40,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 40),
      );
    } else {
      return Image.network(
        imagePath,
        height: 40,
        width: 40,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 40),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: isLoading
          ? ShimmerEffect.rectangular(height: 200)
          : GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 20,
          crossAxisSpacing: 10,
          childAspectRatio: 40 / 40,
        ),
        itemCount: subCategories.length,
        itemBuilder: (context, index) {
          final subCategory = subCategories[index];
          final isSelected = selectedSubCategoryIndex == index;
          return GestureDetector(
            onTap: () => onSubCategoryTapped(index),
            child: Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder( // Build #1.0.27
                borderRadius: BorderRadius.circular(8),
                side: isSelected
                    ? const BorderSide(color: Colors.red, width: 2)
                    : const BorderSide(color: Colors.black12, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildImage(subCategory['image']),
                    const SizedBox(height: 8),
                    Text(
                      subCategory['name'],
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      subCategory['count'].toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}