import 'package:flutter/material.dart';
import '../models/property.dart';
import '../theme/app_colors.dart';
import 'image_carousel.dart';
import 'country_flag.dart';

class FeedPropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback? onTap;

  const FeedPropertyCard({super.key, required this.property, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Get all property images
    final images = <String>[];
    if (property.imageUrl.isNotEmpty) {
      images.add(property.imageUrl);
    }
    for (final img in property.propertyImages) {
      if (img.imageUrl.isNotEmpty && !images.contains(img.imageUrl)) {
        images.add(img.imageUrl);
      }
    }
    // Add placeholder if no images
    if (images.isEmpty) {
      images.add(
        'https://via.placeholder.com/800x600/CCCCCC/FFFFFF?text=No+Image',
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel
            ImageCarousel(
              images: images,
              height: 280,
              fit: BoxFit.cover,
              onTap: onTap,
            ),

            // Property Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Property Name & Location
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              property.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                // Country Flag
                                CountryFlag(
                                  countryCode: CountryFlag.extractCountryCodeFromLocation(
                                    property.location,
                                  ),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    property.location,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (property.hasActiveAuction)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.gavel,
                                size: 14,
                                color: AppColors.error,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Live Auction',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Key Stats Row
                  Row(
                    children: [
                      _buildStatIcon(Icons.bed, '${property.bedrooms} Bed'),
                      const SizedBox(width: 16),
                      _buildStatIcon(
                        Icons.bathtub,
                        '${property.bathrooms} Bath',
                      ),
                      const SizedBox(width: 16),
                      _buildStatIcon(
                        Icons.square_foot,
                        '${property.squareFeet} sqft',
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Description
                  Text(
                    property.description,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 16),

                  // Footer with action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'View Full Details',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          // Share functionality
                        },
                        icon: const Icon(Icons.share_outlined),
                        style: IconButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          // Favorite functionality
                        },
                        icon: const Icon(Icons.favorite_border),
                        style: IconButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatIcon(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
