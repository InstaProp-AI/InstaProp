import 'package:flutter/material.dart';
import '../services/ai_broker_service.dart';
import 'progressive_network_image.dart';

class PropertySuggestionCard extends StatelessWidget {
  final PropertySuggestion property;
  final VoidCallback onViewDetails;
  final VoidCallback onGoToAuction;

  const PropertySuggestionCard({
    super.key,
    required this.property,
    required this.onViewDetails,
    required this.onGoToAuction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property Image
          if (property.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: ProgressiveNetworkImage(
                imageUrl: property.imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: Container(
                  height: 150,
                  color: Colors.grey[300],
                  child: const Icon(Icons.home, size: 48),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        property.location,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildFeature(Icons.bed, '${property.bedrooms}'),
                    const SizedBox(width: 12),
                    _buildFeature(Icons.bathtub, '${property.bathrooms}'),
                    const SizedBox(width: 12),
                    _buildFeature(Icons.square_foot, '${property.squareFeet}'),
                  ],
                ),
                const SizedBox(height: 12),
                _buildAuctionStatus(property),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onViewDetails,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.blue),
                        ),
                        child: const Text('View Details'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onGoToAuction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: const Text(
                          'Go to Auction',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildAuctionStatus(PropertySuggestion property) {
    if (property.auctionId == null) {
      // No auction available
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'No auction available right now',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    } else {
      // Auction available - check if it's active or starting soon
      final now = DateTime.now();
      final isActive = property.auctionStatus == 'Active';

      String statusText;
      bool isGreen;
      IconData statusIcon;

      if (isActive) {
        statusText = 'Auction Live Now!';
        isGreen = true;
        statusIcon = Icons.gavel;

        if (property.currentPrice > 0) {
          statusText +=
              '\nCurrent bid: \$${property.currentPrice.toStringAsFixed(0)}';
        }
      } else if (property.auctionStartTime != null) {
        final daysUntilStart = property.auctionStartTime!
            .difference(now)
            .inDays;
        final hoursUntilStart = property.auctionStartTime!
            .difference(now)
            .inHours;

        if (daysUntilStart > 0) {
          statusText =
              'Auction starts in $daysUntilStart day${daysUntilStart == 1 ? '' : 's'}';
        } else if (hoursUntilStart > 0) {
          statusText =
              'Auction starts in $hoursUntilStart hour${hoursUntilStart == 1 ? '' : 's'}';
        } else {
          statusText = 'Auction starting soon';
        }
        isGreen = false;
        statusIcon = Icons.schedule;
      } else {
        statusText = 'Auction Scheduled';
        isGreen = false;
        statusIcon = Icons.event;
      }

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isGreen ? Colors.green[50] : Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isGreen ? Colors.green[300]! : Colors.blue[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              statusIcon,
              color: isGreen ? Colors.green[700] : Colors.blue[700],
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isGreen ? Colors.green[900] : Colors.blue[900],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
