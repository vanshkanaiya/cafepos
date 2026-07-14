import 'package:flutter/material.dart';
import 'package:cafepos/services/login_db_service.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  List<MenuItem> _allItems = const [];
  final List<String> _sections = const [
    'All',
    'Momos',
    'Pizza',
    'Maggie',
    'Fries',
    'Coffee',
    'Beverages',
  ];
  String _selectedSection = 'All';
  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMenuData();
  }

  Future<void> _loadMenuData() async {
    try {
      final items = await LoginDbService.instance.getAllMenuItems();

      if (!mounted) {
        return;
      }

      setState(() {
        _allItems = items;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  List<MenuItem> get _filteredItems {
    return _allItems.where((item) {
      final matchesSection = _selectedSection == 'All' ||
          item.section == _selectedSection;
      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.section.toLowerCase().contains(query);

      return matchesSection && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFFFF7F0);
    const primaryText = Color(0xFF2D1B12);
    const secondaryText = Color(0xFF8B776B);
    const accent = Color(0xFFFF6A00);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadMenuData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.search,
                              color: secondaryText,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Search items...',
                                hintStyle: const TextStyle(
                                  color: secondaryText,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(
                                  Icons.manage_search_rounded,
                                  color: secondaryText,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _sections.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final section = _sections[index];
                            final isSelected = section == _selectedSection;

                            return ChoiceChip(
                              label: Text(section),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  _selectedSection = section;
                                });
                              },
                              backgroundColor: Colors.white,
                              selectedColor: const Color(0xFF5B3317),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : primaryText,
                                fontWeight: FontWeight.w600,
                              ),
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: accent,
                    ),
                  ),
                )
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Failed to load menu\n$_error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: primaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
              else if (_filteredItems.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No items found',
                      style: TextStyle(
                        color: primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = _filteredItems[index];
                        return _MenuItemCard(item: item);
                      },
                      childCount: _filteredItems.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.73,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({required this.item});

  final MenuItem item;

  @override
  Widget build(BuildContext context) {
    const primaryText = Color(0xFF2D1B12);
    const secondaryText = Color(0xFF8B776B);
    const accent = Color(0xFFFF6A00);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _sectionGradient(item.section),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      _sectionIcon(item.section),
                      size: 58,
                      color: Colors.white,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xCCFFFFFF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.section,
                        style: const TextStyle(
                          color: primaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '₹${item.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: primaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Freshly prepared',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: secondaryText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _sectionIcon(String section) {
    switch (section) {
      case 'Momos':
        return Icons.ramen_dining;
      case 'Pizza':
        return Icons.local_pizza_outlined;
      case 'Maggie':
        return Icons.lunch_dining_outlined;
      case 'Fries':
        return Icons.fastfood_outlined;
      case 'Coffee':
        return Icons.local_cafe_outlined;
      case 'Beverages':
        return Icons.local_drink_outlined;
      default:
        return Icons.restaurant_menu_outlined;
    }
  }

  List<Color> _sectionGradient(String section) {
    switch (section) {
      case 'Momos':
        return const [Color(0xFFFFA652), Color(0xFFFF6A00)];
      case 'Pizza':
        return const [Color(0xFFF97352), Color(0xFFD9480F)];
      case 'Maggie':
        return const [Color(0xFFFFC857), Color(0xFFF77F00)];
      case 'Fries':
        return const [Color(0xFFFFD166), Color(0xFFFF9F1C)];
      case 'Coffee':
        return const [Color(0xFF9C6644), Color(0xFF6F4518)];
      case 'Beverages':
        return const [Color(0xFF59C3C3), Color(0xFF2A9D8F)];
      default:
        return const [Color(0xFFB08968), Color(0xFF7F5539)];
    }
  }
}
