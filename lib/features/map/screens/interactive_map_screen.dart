import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/bottom_nav_bar.dart';

class InteractiveMapScreen extends StatefulWidget {
  const InteractiveMapScreen({super.key});

  @override
  State<InteractiveMapScreen> createState() => _InteractiveMapScreenState();
}

class _InteractiveMapScreenState extends State<InteractiveMapScreen> {
  int _currentIndex = 1; // Map is index 1

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasCream,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 1,
        title: Text('Peta & Arah', style: AppTypography.headlineMd.copyWith(color: AppColors.espressoDark)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.espressoDark),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // Simulated Map Background
          Container(
            color: AppColors.surfaceContainerHigh,
            width: double.infinity,
            height: double.infinity,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 100, color: AppColors.outlineVariant),
                  SizedBox(height: AppConstants.spaceMd),
                  Text('Google Maps Placeholder', style: TextStyle(color: AppColors.outline)),
                ],
              ),
            ),
          ),
          
          // Search Bar
          Positioned(
            top: AppConstants.spaceMd,
            left: AppConstants.spaceMd,
            right: AppConstants.spaceMd,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppConstants.spaceMd),
                    child: Icon(Icons.search, color: AppColors.tanMedium),
                  ),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari tenda, toilet, posko kesehatan...',
                        hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.outline),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppConstants.spaceMd),
                    child: Icon(Icons.mic, color: AppColors.espressoDark),
                  ),
                ],
              ),
            ),
          ),
          
          // Floating Categories
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceMd),
              child: Row(
                children: [
                  _buildCategoryChip('Toilet', Icons.wc),
                  const SizedBox(width: AppConstants.spaceXs),
                  _buildCategoryChip('Posko Medis', Icons.local_hospital, isSelected: true),
                  const SizedBox(width: AppConstants.spaceXs),
                  _buildCategoryChip('Tenda Maktab', Icons.home),
                  const SizedBox(width: AppConstants.spaceXs),
                  _buildCategoryChip('Masjid', Icons.mosque),
                ],
              ),
            ),
          ),
          
          // Floating Action Buttons
          Positioned(
            bottom: AppConstants.spaceMd,
            right: AppConstants.spaceMd,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'my_location',
                  mini: true,
                  backgroundColor: AppColors.surfaceWhite,
                  foregroundColor: AppColors.espressoDark,
                  onPressed: () {},
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: AppConstants.spaceSm),
                FloatingActionButton(
                  heroTag: 'directions',
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.surfaceWhite,
                  onPressed: () {},
                  child: const Icon(Icons.directions),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: HajiCareBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            // Navigation handled later
          });
        },
      ),
    );
  }

  Widget _buildCategoryChip(String label, IconData icon, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceMd, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.espressoDark : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusPill),
        border: Border.all(color: isSelected ? AppColors.espressoDark : AppColors.goldLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isSelected ? AppColors.surfaceWhite : AppColors.tanMedium),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.captionBold.copyWith(
              color: isSelected ? AppColors.surfaceWhite : AppColors.espressoDark,
            ),
          ),
        ],
      ),
    );
  }
}
