import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/colors.dart';
import '../../services/nft_service.dart';
import '../../services/cache_service.dart';

/// NFT Marketplace Screen - Full API integration
class NFTScreen extends StatefulWidget {
  const NFTScreen({super.key});

  @override
  State<NFTScreen> createState() => _NFTScreenState();
}

class _NFTScreenState extends State<NFTScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  List<NFTListing> _listings = [];
  List<NFT> _myNFTs = [];
  List<NFTCollection> _collections = [];
  List<Map<String, dynamic>> _activity = [];

  bool _isLoadingListings = true;
  bool _isLoadingMyNFTs = true;
  bool _isLoadingCollections = true;
  bool _isLoadingActivity = true;

  String? _listingsError;
  String? _myNFTsError;
  String? _collectionsError;
  String? _activityError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedTab = _tabController.index);
      _loadDataForTab(_selectedTab);
    });
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    _loadListings();
    _loadMyNFTs();
    _loadCollections();
    _loadActivity();
  }

  void _loadDataForTab(int tab) {
    switch (tab) {
      case 0:
        if (_listings.isEmpty) _loadListings();
        break;
      case 1:
        if (_myNFTs.isEmpty) _loadMyNFTs();
        break;
      case 2:
        if (_collections.isEmpty) _loadCollections();
        break;
      case 3:
        if (_activity.isEmpty) _loadActivity();
        break;
    }
  }

  Future<void> _loadListings() async {
    setState(() {
      _isLoadingListings = true;
      _listingsError = null;
    });

    try {
      // Try cache first if offline
      if (!cacheService.isOnline) {
        final cached = cacheService.getCachedNFTListings();
        if (cached.isNotEmpty) {
          setState(() {
            _listings = cached.map((json) => NFTListing.fromJson(json)).toList();
            _isLoadingListings = false;
          });
          return;
        }
      }

      final listings = await nftService.getMarketplaceListings();

      // Cache results
      await cacheService.cacheNFTListings(
        listings.map((l) => {
          'id': l.id,
          'nftId': l.nftId,
          'price': l.price,
          'currency': l.currency,
          'status': l.status,
          'sellerAddress': l.sellerAddress,
          'nft': {
            'id': l.nft.id,
            'name': l.nft.name,
            'imageUrl': l.nft.imageUrl,
            'collectionName': l.nft.collectionName,
            'price': l.nft.price,
            'priceCurrency': l.nft.priceCurrency,
          },
        }).toList(),
      );

      setState(() {
        _listings = listings;
        _isLoadingListings = false;
      });
    } catch (e) {
      final cached = cacheService.getCachedNFTListings();
      setState(() {
        if (cached.isNotEmpty) {
          _listings = cached.map((json) => NFTListing.fromJson(json)).toList();
          _listingsError = 'Using cached data';
        } else {
          _listingsError = e.toString();
        }
        _isLoadingListings = false;
      });
    }
  }

  Future<void> _loadMyNFTs() async {
    setState(() {
      _isLoadingMyNFTs = true;
      _myNFTsError = null;
    });

    try {
      if (!cacheService.isOnline) {
        final cached = cacheService.getCachedOwnedNFTs();
        if (cached.isNotEmpty) {
          setState(() {
            _myNFTs = cached.map((json) => NFT.fromJson(json)).toList();
            _isLoadingMyNFTs = false;
          });
          return;
        }
      }

      final nfts = await nftService.getOwnedNFTs();

      await cacheService.cacheOwnedNFTs(
        nfts.map((n) => {
          'id': n.id,
          'name': n.name,
          'imageUrl': n.imageUrl,
          'collectionName': n.collectionName,
          'price': n.price,
          'priceCurrency': n.priceCurrency,
          'isListed': n.isListed,
        }).toList(),
      );

      setState(() {
        _myNFTs = nfts;
        _isLoadingMyNFTs = false;
      });
    } catch (e) {
      final cached = cacheService.getCachedOwnedNFTs();
      setState(() {
        if (cached.isNotEmpty) {
          _myNFTs = cached.map((json) => NFT.fromJson(json)).toList();
          _myNFTsError = 'Using cached data';
        } else {
          _myNFTsError = e.toString();
        }
        _isLoadingMyNFTs = false;
      });
    }
  }

  Future<void> _loadCollections() async {
    setState(() {
      _isLoadingCollections = true;
      _collectionsError = null;
    });

    try {
      if (!cacheService.isOnline) {
        final cached = cacheService.getCachedNFTCollections();
        if (cached.isNotEmpty) {
          setState(() {
            _collections = cached.map((json) => NFTCollection.fromJson(json)).toList();
            _isLoadingCollections = false;
          });
          return;
        }
      }

      final collections = await nftService.getCollections();

      await cacheService.cacheNFTCollections(
        collections.map((c) => {
          'id': c.id,
          'name': c.name,
          'imageUrl': c.imageUrl,
          'totalItems': c.totalItems,
          'floorPrice': c.floorPrice,
          'floorPriceCurrency': c.floorPriceCurrency,
          'totalVolume': c.totalVolume,
          'isVerified': c.isVerified,
        }).toList(),
      );

      setState(() {
        _collections = collections;
        _isLoadingCollections = false;
      });
    } catch (e) {
      final cached = cacheService.getCachedNFTCollections();
      setState(() {
        if (cached.isNotEmpty) {
          _collections = cached.map((json) => NFTCollection.fromJson(json)).toList();
          _collectionsError = 'Using cached data';
        } else {
          _collectionsError = e.toString();
        }
        _isLoadingCollections = false;
      });
    }
  }

  Future<void> _loadActivity() async {
    setState(() {
      _isLoadingActivity = true;
      _activityError = null;
    });

    try {
      final activity = await nftService.getMyActivity();
      setState(() {
        _activity = activity;
        _isLoadingActivity = false;
      });
    } catch (e) {
      setState(() {
        _activityError = e.toString();
        _isLoadingActivity = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : AppColors.lightBackgroundPrimary;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final cardColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5);
    final borderColor = isDark ? const Color(0xFF1A1A1A) : Colors.grey[300]!;
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth > 500 ? 460.0 : screenWidth;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('NFT Marketplace', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: textColor)),
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 20, color: textColor),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: textColor),
            onPressed: () => _showSearchDialog(),
          ),
        ],
      ),
      body: Center(
        child: SizedBox(
          width: contentWidth,
          child: Column(
            children: [
              // Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: textColor,
                  unselectedLabelColor: isDark ? Colors.grey[600] : Colors.grey[500],
                  indicator: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  tabs: const [
                    Tab(text: 'Marketplace'),
                    Tab(text: 'My NFTs'),
                    Tab(text: 'Collections'),
                    Tab(text: 'Activity'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMarketplace(isDark, textColor, cardColor, borderColor),
                    _buildMyNFTs(isDark, textColor, cardColor, borderColor),
                    _buildCollections(isDark, textColor, cardColor, borderColor),
                    _buildActivity(isDark, textColor, cardColor, borderColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarketplace(bool isDark, Color textColor, Color cardColor, Color borderColor) {
    if (_isLoadingListings) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_listingsError != null && _listings.isEmpty) {
      return _buildErrorWidget(_listingsError!, _loadListings);
    }

    if (_listings.isEmpty) {
      return _buildEmptyWidget(
        icon: Icons.store_outlined,
        title: 'No NFTs listed',
        subtitle: 'Check back later for new listings',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadListings,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: _listings.length,
          itemBuilder: (context, index) {
            final listing = _listings[index];
            return _buildNFTCard(
              listing.nft,
              listing.price,
              listing.currency,
              isDark,
              textColor,
              cardColor,
              borderColor,
              () => _showBuyModal(context, listing, isDark),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMyNFTs(bool isDark, Color textColor, Color cardColor, Color borderColor) {
    if (_isLoadingMyNFTs) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myNFTsError != null && _myNFTs.isEmpty) {
      return _buildErrorWidget(_myNFTsError!, _loadMyNFTs);
    }

    if (_myNFTs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.collections_outlined, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text('No NFTs yet', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Start collecting or minting NFTs', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showMintModal(context, isDark),
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text('Mint NFT', style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyNFTs,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showMintModal(context, isDark),
                  icon: const Icon(Icons.add, color: Colors.black, size: 18),
                  label: const Text('Mint NFT', style: TextStyle(color: Colors.black, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: _myNFTs.length,
                itemBuilder: (context, index) {
                  final nft = _myNFTs[index];
                  return _buildNFTCard(
                    nft,
                    nft.price ?? 0,
                    nft.priceCurrency ?? 'ETH',
                    isDark,
                    textColor,
                    cardColor,
                    borderColor,
                    () => _showSellModal(context, nft, isDark),
                    isMine: true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollections(bool isDark, Color textColor, Color cardColor, Color borderColor) {
    if (_isLoadingCollections) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_collectionsError != null && _collections.isEmpty) {
      return _buildErrorWidget(_collectionsError!, _loadCollections);
    }

    if (_collections.isEmpty) {
      return _buildEmptyWidget(
        icon: Icons.collections_bookmark_outlined,
        title: 'No collections',
        subtitle: 'Collections will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCollections,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _collections.length,
        itemBuilder: (context, index) {
          final collection = _collections[index];
          return _buildCollectionCard(collection, isDark, textColor, cardColor, borderColor);
        },
      ),
    );
  }

  Widget _buildActivity(bool isDark, Color textColor, Color cardColor, Color borderColor) {
    if (_isLoadingActivity) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activityError != null && _activity.isEmpty) {
      return _buildErrorWidget(_activityError!, _loadActivity);
    }

    if (_activity.isEmpty) {
      return _buildEmptyWidget(
        icon: Icons.history,
        title: 'No activity',
        subtitle: 'Your NFT activity will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadActivity,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _activity.length,
        itemBuilder: (context, index) {
          final item = _activity[index];
          return _buildActivityCard(item, isDark, textColor, cardColor, borderColor);
        },
      ),
    );
  }

  Widget _buildErrorWidget(String error, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(error, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(color: Colors.grey[400], fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildNFTCard(
    NFT nft,
    double price,
    String currency,
    bool isDark,
    Color textColor,
    Color cardColor,
    Color borderColor,
    VoidCallback onTap, {
    bool isMine = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // NFT Image
            Container(
              height: 140,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: nft.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: nft.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) => Container(
                          color: AppColors.primary.withOpacity(0.1),
                          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                        ),
                        errorWidget: (context, url, error) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.primary.withOpacity(0.3), Colors.purple.withOpacity(0.3)],
                            ),
                          ),
                          child: Center(child: Icon(Icons.diamond, size: 48, color: AppColors.primary)),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.primary.withOpacity(0.3), Colors.purple.withOpacity(0.3)],
                          ),
                        ),
                        child: Center(child: Icon(Icons.diamond, size: 48, color: AppColors.primary)),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nft.name,
                    style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nft.collectionName,
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$price $currency',
                        style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isMine
                              ? AppColors.tradingSell.withOpacity(0.15)
                              : AppColors.tradingBuy.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isMine ? 'Sell' : 'Buy',
                          style: TextStyle(
                            color: isMine ? AppColors.tradingSell : AppColors.tradingBuy,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Widget _buildCollectionCard(NFTCollection collection, bool isDark, Color textColor, Color cardColor, Color borderColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: collection.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: collection.imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primary.withOpacity(0.6)],
                          ),
                        ),
                        child: const Icon(Icons.collections, color: Colors.black, size: 28),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primary.withOpacity(0.6)],
                        ),
                      ),
                      child: const Icon(Icons.collections, color: Colors.black, size: 28),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      collection.name,
                      style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    if (collection.isVerified) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.verified, color: AppColors.primary, size: 16),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text('${collection.totalItems} items', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Floor: ${collection.floorPrice ?? 0} ${collection.floorPriceCurrency ?? 'ETH'}',
                style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              if (collection.totalVolume != null)
                Text(
                  'Vol: ${_formatVolume(collection.totalVolume!)} ${collection.floorPriceCurrency ?? 'ETH'}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> item, bool isDark, Color textColor, Color cardColor, Color borderColor) {
    final type = item['type'] as String? ?? 'Unknown';
    final nftName = item['nftName'] ?? item['nft']?['name'] ?? 'Unknown NFT';
    final price = item['price']?.toString() ?? '0';
    final from = _truncateAddress(item['from'] ?? '-');
    final to = _truncateAddress(item['to'] ?? '-');
    final time = item['time'] ?? item['timestamp'] ?? '-';

    Color typeColor;
    switch (type.toLowerCase()) {
      case 'sale':
        typeColor = AppColors.tradingBuy;
        break;
      case 'listing':
        typeColor = AppColors.primary;
        break;
      case 'transfer':
        typeColor = Colors.blue;
        break;
      case 'mint':
        typeColor = Colors.purple;
        break;
      default:
        typeColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              type,
              style: TextStyle(color: typeColor, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nftName,
                  style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text('$from -> $to', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (double.tryParse(price) != null && double.parse(price) > 0)
                Text('$price ETH', style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
              Text(time, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  String _truncateAddress(String address) {
    if (address.length > 10) {
      return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
    }
    return address;
  }

  String _formatVolume(double volume) {
    if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}K';
    }
    return volume.toStringAsFixed(2);
  }

  void _showSearchDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121212) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                autofocus: true,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'Search NFTs or collections...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.grey[200],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: Text(
                    'Start typing to search...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBuyModal(BuildContext context, NFTListing listing, bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final cardColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5);
    int currentStep = 0;
    bool isProcessing = false;
    bool isComplete = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121212) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        isComplete ? 'Purchase Complete!' : 'Buy NFT',
                        style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, color: textColor),
                        onPressed: () {
                          Navigator.pop(context);
                          if (isComplete) _loadMyNFTs();
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: isComplete
                        ? _buildSuccessContent(listing.nft.name, listing.nft.collectionName, textColor, cardColor)
                        : _buildBuyConfirmContent(listing, textColor, cardColor, isProcessing),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: isComplete
                      ? SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _loadMyNFTs();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Done', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                          ),
                        )
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isProcessing
                                ? null
                                : () async {
                                    setModalState(() => isProcessing = true);
                                    try {
                                      await nftService.purchaseNFT(listing.id);
                                      setModalState(() {
                                        isProcessing = false;
                                        isComplete = true;
                                      });
                                    } catch (e) {
                                      setModalState(() => isProcessing = false);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: isProcessing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                                  )
                                : const Text('Confirm Purchase', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBuyConfirmContent(NFTListing listing, Color textColor, Color cardColor, bool isProcessing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: listing.nft.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: listing.nft.imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.primary.withOpacity(0.3), Colors.purple.withOpacity(0.3)],
                              ),
                            ),
                            child: Icon(Icons.diamond, color: AppColors.primary),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary.withOpacity(0.3), Colors.purple.withOpacity(0.3)],
                            ),
                          ),
                          child: Icon(Icons.diamond, color: AppColors.primary),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(listing.nft.name, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(listing.nft.collectionName, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
              Text(
                '${listing.price} ${listing.currency}',
                style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This transaction cannot be reversed. Please review before confirming.',
                  style: TextStyle(color: AppColors.warning, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessContent(String name, String collection, Color textColor, Color cardColor) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.tradingBuy.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check, color: AppColors.tradingBuy, size: 40),
        ),
        const SizedBox(height: 24),
        Text('Successfully purchased!', style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('$name from $collection', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
      ],
    );
  }

  void _showSellModal(BuildContext context, NFT nft, bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final cardColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5);
    final priceController = TextEditingController(text: nft.price?.toString() ?? '');
    bool isProcessing = false;
    bool isComplete = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121212) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        isComplete ? 'NFT Listed!' : 'Sell NFT',
                        style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, color: textColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: isComplete
                        ? _buildSuccessContent(nft.name, nft.collectionName, textColor, cardColor)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Set Your Price', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: priceController,
                                        style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.w600),
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          hintText: '0.00',
                                          hintStyle: TextStyle(color: Colors.grey[600]),
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                    Text('ETH', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: isComplete
                      ? SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Done', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                          ),
                        )
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isProcessing
                                ? null
                                : () async {
                                    final price = double.tryParse(priceController.text);
                                    if (price == null || price <= 0) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please enter a valid price')),
                                      );
                                      return;
                                    }

                                    setModalState(() => isProcessing = true);
                                    try {
                                      await nftService.listNFT(nftId: nft.id, price: price, currency: 'ETH');
                                      setModalState(() {
                                        isProcessing = false;
                                        isComplete = true;
                                      });
                                    } catch (e) {
                                      setModalState(() => isProcessing = false);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.tradingSell,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: isProcessing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('List for Sale', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showMintModal(BuildContext context, bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF000000);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('Mint NFT', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.construction, size: 64, color: Colors.grey[600]),
                    const SizedBox(height: 16),
                    Text('Coming Soon', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('NFT minting will be available soon', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
