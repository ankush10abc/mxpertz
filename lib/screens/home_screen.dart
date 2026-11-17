import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:my_first_app/controllers/auth_controller.dart';

const _dashboardTeal = Color(0xFF179EB1);
const _dashboardOrange = Color(0xFFF0A400);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Get.find<AuthController>().currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in to view your dashboard.')),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('dashboard')
                .doc('home')
                .snapshots(),
            builder: (context, dashboardSnapshot) {
              if (dashboardSnapshot.hasError) {
                return _DashboardMessage(
                  message:
                      'Could not load dashboard data: '
                      '${dashboardSnapshot.error}',
                );
              }
              if (!dashboardSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: _dashboardTeal),
                );
              }

              final dashboardDocument = dashboardSnapshot.data!;
              if (!dashboardDocument.exists ||
                  dashboardDocument.data() == null) {
                return const _DashboardMessage(
                  message:
                      'Dashboard data is not set. Add the dashboard/home '
                      'document in Firebase Firestore.',
                );
              }

              late final _HomeContent content;
              try {
                content = _HomeContent.fromMap(dashboardDocument.data()!);
              } on FormatException catch (error) {
                return _DashboardMessage(
                  message: 'Dashboard data is incomplete: ${error.message}',
                );
              }

              return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .snapshots(),
                builder: (context, profileSnapshot) {
                  if (profileSnapshot.hasError) {
                    return _DashboardMessage(
                      message:
                          'Could not load your profile: '
                          '${profileSnapshot.error}',
                    );
                  }
                  if (!profileSnapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: _dashboardTeal),
                    );
                  }

                  final profile = profileSnapshot.data!.data();
                  final displayName = _profileName(profile, user);
                  return _DashboardView(
                    content: content,
                    displayName: displayName,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  String _profileName(Map<String, dynamic>? profile, User user) {
    final displayName = profile?['displayName'];
    if (displayName is String && displayName.trim().isNotEmpty) {
      return displayName.trim();
    }
    final email = profile?['email'] ?? user.email;
    if (email is String && email.contains('@')) {
      return email.split('@').first;
    }
    final phoneNumber = profile?['phoneNumber'];
    if (phoneNumber is String && phoneNumber.isNotEmpty) {
      return phoneNumber;
    }
    return user.phoneNumber ?? '';
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView({required this.content, required this.displayName});

  final _HomeContent content;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    PopupMenuButton<String>(
                      tooltip: content.navigationItems.last.label,
                      onSelected: (value) {
                        if (value == 'logout') {
                          auth.logout();
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'logout', child: Text('Sign out')),
                      ],
                      child: const Icon(Icons.menu, size: 23),
                    ),
                    const Spacer(),
                    Text(
                      content.brandName,
                      style: const TextStyle(
                        color: _dashboardOrange,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Search',
                      onPressed: () => showSearch<void>(
                        context: context,
                        delegate: _ProductSearchDelegate(content.products),
                      ),
                      icon: const Icon(Icons.search, size: 22),
                    ),
                    IconButton(
                      tooltip: 'Scan',
                      onPressed: () {},
                      icon: const Icon(Icons.qr_code_scanner, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${content.greetingPrefix} $displayName',
                  style: const TextStyle(
                    color: Color(0xFF555555),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content.searchPrompt,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                _PromoBanner(banner: content.banner),
                const SizedBox(height: 16),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: content.tabs.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 20),
                    itemBuilder: (context, index) {
                      final tab = content.tabs[index];
                      final selected = tab == content.selectedTab;
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              tab,
                              style: TextStyle(
                                color: selected
                                    ? const Color(0xFF333333)
                                    : const Color(0xFF777777),
                                fontSize: 12,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 2,
                              width: selected ? 34 : 0,
                              color: _dashboardOrange,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    content.viewAllLabel,
                    style: const TextStyle(
                      color: _dashboardOrange,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: content.categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.78,
                  ),
                  itemBuilder: (context, index) {
                    final category = content.categories[index];
                    return Column(
                      children: [
                        Expanded(
                          child: _NetworkImage(
                            url: category.imageUrl,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          category.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: content.products.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.68,
                  ),
                  itemBuilder: (context, index) {
                    return _ProductCard(product: content.products[index]);
                  },
                ),
              ],
            ),
          ),
        ),
        _DashboardNavigation(items: content.navigationItems),
      ],
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({required this.banner});

  final _DashboardBanner banner;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 160,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _NetworkImage(url: banner.imageUrl, fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.28),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.12),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    banner.brand,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    banner.eyebrow,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    banner.discount,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          banner.subtitle,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          banner.headline,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 21,
                            height: 0.95,
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          color: Colors.black,
                          child: Text(
                            banner.actionLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final _DashboardProduct product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _NetworkImage(url: product.imageUrl, fit: BoxFit.contain),
              const Positioned(
                left: 4,
                top: 4,
                child: Icon(
                  Icons.favorite_border,
                  size: 17,
                  color: Color(0xFF777777),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          product.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Color(0xFF222222)),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Expanded(
              child: Text(
                product.price,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: _dashboardOrange,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                product.addLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.star, color: _dashboardOrange, size: 12),
            const SizedBox(width: 3),
            Text(
              product.rating,
              style: const TextStyle(fontSize: 9, color: Color(0xFF777777)),
            ),
            const SizedBox(width: 7),
            Text(
              product.reviewCount,
              style: const TextStyle(fontSize: 9, color: Color(0xFF777777)),
            ),
          ],
        ),
      ],
    );
  }
}

class _DashboardNavigation extends StatelessWidget {
  const _DashboardNavigation({required this.items});

  final List<_NavigationItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        children: [
          for (var index = 0; index < items.length; index++)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _navigationIcon(items[index].icon),
                    size: 19,
                    color: index == 0 ? _dashboardOrange : Colors.black26,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    items[index].label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: index == 0 ? _dashboardOrange : Colors.black26,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _navigationIcon(String icon) {
    return switch (icon) {
      'home' => Icons.home_filled,
      'category' => Icons.grid_view_outlined,
      'message' => Icons.chat_bubble_outline,
      'cart' => Icons.shopping_cart_outlined,
      'profile' => Icons.person_outline,
      _ => Icons.circle_outlined,
    };
  }
}

class _ProductSearchDelegate extends SearchDelegate<void> {
  _ProductSearchDelegate(this.products);

  final List<_DashboardProduct> products;

  List<_DashboardProduct> get _matchingProducts {
    final searchTerm = query.trim().toLowerCase();
    if (searchTerm.isEmpty) {
      return products;
    }
    return products
        .where((product) => product.name.toLowerCase().contains(searchTerm))
        .toList();
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(
      tooltip: 'Clear search',
      onPressed: () => query = '',
      icon: const Icon(Icons.clear),
    ),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    tooltip: 'Close search',
    onPressed: () => close(context, null),
    icon: const Icon(Icons.arrow_back),
  );

  @override
  Widget buildResults(BuildContext context) => _buildResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildResults();

  Widget _buildResults() {
    final matchingProducts = _matchingProducts;
    if (matchingProducts.isEmpty) {
      return const Center(child: Text('No matching products.'));
    }
    return ListView.builder(
      itemCount: matchingProducts.length,
      itemBuilder: (context, index) {
        final product = matchingProducts[index];
        return ListTile(
          title: Text(product.name),
          subtitle: Text(product.price),
          onTap: () => close(context, null),
        );
      },
    );
  }
}

class _NetworkImage extends StatelessWidget {
  const _NetworkImage({required this.url, required this.fit});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_outlined, color: Colors.black26),
            SizedBox(height: 4),
            Text(
              'Image unavailable',
              style: TextStyle(fontSize: 9, color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardMessage extends StatelessWidget {
  const _DashboardMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF555555)),
        ),
      ),
    );
  }
}

class _HomeContent {
  const _HomeContent({
    required this.brandName,
    required this.greetingPrefix,
    required this.searchPrompt,
    required this.banner,
    required this.tabs,
    required this.selectedTab,
    required this.viewAllLabel,
    required this.categories,
    required this.products,
    required this.navigationItems,
  });

  final String brandName;
  final String greetingPrefix;
  final String searchPrompt;
  final _DashboardBanner banner;
  final List<String> tabs;
  final String selectedTab;
  final String viewAllLabel;
  final List<_DashboardCategory> categories;
  final List<_DashboardProduct> products;
  final List<_NavigationItem> navigationItems;

  factory _HomeContent.fromMap(Map<String, dynamic> data) {
    final tabs = _stringList(data['tabs'], 'tabs');
    final selectedTab = _requiredString(data['selectedTab'], 'selectedTab');
    if (!tabs.contains(selectedTab)) {
      throw const FormatException('selectedTab must be included in tabs.');
    }
    final navigationItems = _records(
      data['navigationItems'],
      'navigationItems',
    ).map(_NavigationItem.fromMap).toList();
    if (navigationItems.isEmpty) {
      throw const FormatException('navigationItems must not be empty.');
    }

    return _HomeContent(
      brandName: _requiredString(data['brandName'], 'brandName'),
      greetingPrefix: _requiredString(data['greetingPrefix'], 'greetingPrefix'),
      searchPrompt: _requiredString(data['searchPrompt'], 'searchPrompt'),
      banner: _DashboardBanner.fromMap(_record(data['banner'], 'banner')),
      tabs: tabs,
      selectedTab: selectedTab,
      viewAllLabel: _requiredString(data['viewAllLabel'], 'viewAllLabel'),
      categories: _records(
        data['categories'],
        'categories',
      ).map(_DashboardCategory.fromMap).toList(),

      products: _records(
        data['products'],
        'products',
      ).map(_DashboardProduct.fromMap).toList(),
      navigationItems: navigationItems,
    );
  }
}

class _DashboardBanner {
  const _DashboardBanner({
    required this.imageUrl,
    required this.brand,
    required this.eyebrow,
    required this.discount,
    required this.subtitle,
    required this.headline,
    required this.actionLabel,
  });

  final String imageUrl;
  final String brand;
  final String eyebrow;
  final String discount;
  final String subtitle;
  final String headline;
  final String actionLabel;

  factory _DashboardBanner.fromMap(Map<String, dynamic> data) {
    return _DashboardBanner(
      imageUrl: _requiredString(data['imageUrl'], 'banner.imageUrl'),
      brand: _requiredString(data['brand'], 'banner.brand'),
      eyebrow: _requiredString(data['eyebrow'], 'banner.eyebrow'),
      discount: _requiredString(data['discount'], 'banner.discount'),
      subtitle: _requiredString(data['subtitle'], 'banner.subtitle'),
      headline: _requiredString(data['headline'], 'banner.headline'),
      actionLabel: _requiredString(data['actionLabel'], 'banner.actionLabel'),
    );
  }
}

class _DashboardCategory {
  const _DashboardCategory({required this.name, required this.imageUrl});

  final String name;
  final String imageUrl;

  factory _DashboardCategory.fromMap(Map<String, dynamic> data) {
    return _DashboardCategory(
      name: _requiredString(data['name'], 'category.name'),
      imageUrl: _requiredString(data['imageUrl'], 'category.imageUrl'),
    );
  }
}

class _DashboardProduct {
  const _DashboardProduct({
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.addLabel,
    required this.rating,
    required this.reviewCount,
  });

  final String name;
  final String imageUrl;
  final String price;
  final String addLabel;
  final String rating;
  final String reviewCount;

  factory _DashboardProduct.fromMap(Map<String, dynamic> data) {
    return _DashboardProduct(
      name: _requiredString(data['name'], 'product.name'),
      imageUrl: _requiredString(data['imageUrl'], 'product.imageUrl'),
      price: _requiredString(data['price'], 'product.price'),
      addLabel: _requiredString(data['addLabel'], 'product.addLabel'),
      rating: _requiredString(data['rating'], 'product.rating'),
      reviewCount: _requiredString(data['reviewCount'], 'product.reviewCount'),
    );
  }
}

class _NavigationItem {
  const _NavigationItem({required this.label, required this.icon});

  final String label;
  final String icon;

  factory _NavigationItem.fromMap(Map<String, dynamic> data) {
    return _NavigationItem(
      label: _requiredString(data['label'], 'navigationItem.label'),
      icon: _requiredString(data['icon'], 'navigationItem.icon'),
    );
  }
}

String _requiredString(Object? value, String field) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  throw FormatException('$field must be a non-empty string.');
}

List<String> _stringList(Object? value, String field) {
  if (value is! List) {
    throw FormatException('$field must be a list of strings.');
  }
  return value.map((item) => _requiredString(item, field)).toList();
}

List<Map<String, dynamic>> _records(Object? value, String field) {
  if (value is! List) {
    throw FormatException('$field must be a list of objects.');
  }
  return value
      .asMap()
      .entries
      .map((entry) => _record(entry.value, '$field[${entry.key}]'))
      .toList();
}

Map<String, dynamic> _record(Object? value, String field) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  throw FormatException('$field must be an object.');
}
