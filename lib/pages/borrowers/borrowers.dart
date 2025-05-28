import 'package:flutter/material.dart';
import 'package:gobeller/pages/borrowers/property_detail_page.dart';
import 'package:provider/provider.dart';
import 'package:gobeller/controller/property_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'SubscriptionHistoryPage.dart';

class PropertyListPage extends StatefulWidget {
  const PropertyListPage({super.key});

  @override
  State<PropertyListPage> createState() => _PropertyListPageState();
}

class _PropertyListPageState extends State<PropertyListPage> {
  String? selectedCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<PropertyController>(context, listen: false);
      controller.fetchProperties();
      controller.fetchPropertyCategories();
    });
  }

  // Helper method to get the preferred image URL from property attachments
  String _getPropertyImageUrl(Map<String, dynamic> property) {
    final attachments = property['property_attachments'] as List<dynamic>?;

    if (attachments == null || attachments.isEmpty) {
      return 'https://via.placeholder.com/80x80.png?text=No+Image';
    }

    // First, try to find the preferred item
    final preferredAttachment = attachments.firstWhere(
          (attachment) => attachment['is_preferred_item'] == true,
      orElse: () => null,
    );

    String imageUrl;
    if (preferredAttachment != null) {
      imageUrl = preferredAttachment['attachment_open_url'] ?? 'https://via.placeholder.com/80x80.png?text=No+Image';
    } else {
      // If no preferred item, use the first attachment
      imageUrl = attachments.first['attachment_open_url'] ?? 'https://via.placeholder.com/80x80.png?text=No+Image';
    }

    // Add a timestamp to prevent caching issues
    if (imageUrl.startsWith('http')) {
      imageUrl = '$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}';
    }

    return imageUrl;
  }

  // Custom image widget with fallback options
  Widget _buildPropertyImage(String imageUrl, String propertyName) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: 70,
          height: 70,
          fit: BoxFit.cover,
          httpHeaders: const {
            'User-Agent': 'Flutter App',
            'Accept': 'image/png, image/jpeg, image/jpg, image/gif, image/webp, image/*',
          },
          placeholder: (context, url) => Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) {
            print('Failed to load image: $url');
            print('Error: $error');
            return Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.image_not_supported, color: Colors.grey),
            );
          },
        ),
      ),
    );
  }

  String _formatQuantity(dynamic quantity) {
    if (quantity == null) return '0';

    // Convert to double first, then check if it's a whole number
    double quantityDouble = double.tryParse(quantity.toString()) ?? 0.0;

    if (quantityDouble == quantityDouble.toInt()) {
      // It's a whole number, return as integer
      return quantityDouble.toInt().toString();
    } else {
      // It has decimal places, return as is
      return quantityDouble.toString();
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Properties'),
        actions: [
          Consumer<PropertyController>(
            builder: (context, controller, child) {
              if (controller.isCategoriesLoading) {
                return const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                );
              }

              if (controller.categories.isEmpty) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    dropdownColor: Colors.white,
                    icon: const Icon(Icons.filter_list, color: Colors.white),
                    value: selectedCategoryId,
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Row(
                          children: const [
                            Icon(Icons.category, color: Colors.black),
                            SizedBox(width: 8),
                            Text('All', style: TextStyle(color: Colors.black)),
                          ],
                        ),
                      ),
                      ...controller.categories.map((category) {
                        return DropdownMenuItem<String?>(
                          value: category['id'] as String?,
                          child: Text(
                            category['label'] ?? 'Unknown',
                            style: const TextStyle(color: Colors.black),
                          ),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedCategoryId = value;
                      });
                      controller.filterPropertiesByCategory(value);
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<PropertyController>(
        builder: (context, controller, child) {
          if (controller.isLoading && controller.properties.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.properties.isEmpty) {
            return const Center(child: Text('No properties available.'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: controller.properties.length,
                  itemBuilder: (context, index) {
                    final property = controller.properties[index];
                    final imageUrl = _getPropertyImageUrl(property);
                    final propertyName = property['name'] ?? 'Unnamed Property';
                    final propertyId = property['id']; // <-- Get the property ID here

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildPropertyImage(imageUrl, propertyName),
                                  const SizedBox(width: 16),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          propertyName,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          "Price: ₦${property['price']} | Payment Duration: ${property['payment_duration'] ?? '12'} months",
                                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            _infoRow("Payment Plan", "${property!['payment_cycle']}"),

                            _infoRow(
                                "Available Stock",
                                "${_formatQuantity(property!['quantity'])}${property!['uom'] ?? ''}"
                            ),

                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SubscriptionHistoryPage(propertyId: propertyId),
                                        ),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text("My Order"),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PropertyDetailPage(propertyId: propertyId),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text("View Details"),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (controller.hasNextPage)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: ElevatedButton(
                    onPressed: () {
                      controller.loadNextPage();
                    },
                    child: controller.isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text('Load More'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }
}
