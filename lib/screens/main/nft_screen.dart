import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';

/// NFT Marketplace Screen with demo workflow
class NFTScreen extends StatefulWidget {
  const NFTScreen({super.key});

  @override
  State<NFTScreen> createState() => _NFTScreenState();
}

class _NFTScreenState extends State<NFTScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  // Demo NFT data
  final List<Map<String, dynamic>> _featuredNFTs = [
    {
      'id': '1',
      'name': 'CryptoApe #3421',
      'collection': 'CryptoApes',
      'price': 2.5,
      'currency': 'ETH',
      'image': 'ape',
      'creator': '0x1234...5678',
    },
    {
      'id': '2',
      'name': 'Digital Punk #8832',
      'collection': 'Digital Punks',
      'price': 1.8,
      'currency': 'ETH',
      'image': 'punk',
      'creator': '0xabcd...efgh',
    },
    {
      'id': '3',
      'name': 'Abstract Art #102',
      'collection': 'Abstract Series',
      'price': 0.5,
      'currency': 'ETH',
      'image': 'art',
      'creator': '0x9876...5432',
    },
    {
      'id': '4',
      'name': 'Space Explorer #55',
      'collection': 'Space Explorers',
      'price': 3.2,
      'currency': 'ETH',
      'image': 'space',
      'creator': '0xfedc...ba98',
    },
  ];

  final List<Map<String, dynamic>> _myNFTs = [
    {
      'id': '5',
      'name': 'My Ape #1122',
      'collection': 'CryptoApes',
      'price': 1.2,
      'currency': 'ETH',
      'image': 'myape',
      'creator': 'You',
    },
  ];

  final List<Map<String, dynamic>> _collections = [
    {'name': 'CryptoApes', 'items': 10000, 'floorPrice': 1.5, 'volume': '45.2K'},
    {'name': 'Digital Punks', 'items': 5000, 'floorPrice': 0.8, 'volume': '28.1K'},
    {'name': 'Abstract Series', 'items': 2500, 'floorPrice': 0.3, 'volume': '12.5K'},
    {'name': 'Space Explorers', 'items': 7500, 'floorPrice': 2.1, 'volume': '67.8K'},
  ];

  final List<Map<String, dynamic>> _activity = [
    {'type': 'Sale', 'nft': 'CryptoApe #1234', 'price': 2.1, 'from': '0x1234', 'to': '0x5678', 'time': '2m'},
    {'type': 'Listing', 'nft': 'Digital Punk #999', 'price': 1.5, 'from': '0xabcd', 'to': '-', 'time': '5m'},
    {'type': 'Transfer', 'nft': 'Abstract #55', 'price': 0, 'from': '0x9876', 'to': '0xfedc', 'time': '12m'},
    {'type': 'Mint', 'nft': 'Space Explorer #100', 'price': 0.1, 'from': '-', 'to': '0x1111', 'time': '1h'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedTab = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: Container(
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: _featuredNFTs.length,
        itemBuilder: (context, index) {
          final nft = _featuredNFTs[index];
          return _buildNFTCard(nft, isDark, textColor, cardColor, borderColor, () {
            _showBuyModal(context, nft, isDark);
          });
        },
      ),
    );
  }

  Widget _buildMyNFTs(bool isDark, Color textColor, Color cardColor, Color borderColor) {
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

    return Padding(
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
                return _buildNFTCard(nft, isDark, textColor, cardColor, borderColor, () {
                  _showSellModal(context, nft, isDark);
                }, isMine: true);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollections(bool isDark, Color textColor, Color cardColor, Color borderColor) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _collections.length,
      itemBuilder: (context, index) {
        final collection = _collections[index];
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
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withOpacity(0.6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.collections, color: Colors.black, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(collection['name'], style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('${collection['items']} items', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Floor: ${collection['floorPrice']} ETH', style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text('Vol: ${collection['volume']} ETH', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivity(bool isDark, Color textColor, Color cardColor, Color borderColor) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _activity.length,
      itemBuilder: (context, index) {
        final item = _activity[index];
        final typeColor = item['type'] == 'Sale' ? AppColors.tradingBuy
            : item['type'] == 'Listing' ? AppColors.primary
            : item['type'] == 'Transfer' ? Colors.blue
            : Colors.purple;

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
                child: Text(item['type'], style: TextStyle(color: typeColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['nft'], style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text('${item['from']} -> ${item['to']}', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (item['price'] > 0) Text('${item['price']} ETH', style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(item['time'], style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNFTCard(Map<String, dynamic> nft, bool isDark, Color textColor, Color cardColor, Color borderColor, VoidCallback onTap, {bool isMine = false}) {
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
            // NFT Image placeholder
            Container(
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.3),
                    Colors.purple.withOpacity(0.3),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Center(
                child: Icon(Icons.diamond, size: 48, color: AppColors.primary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nft['name'], style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(nft['collection'], style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${nft['price']} ${nft['currency']}', style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w700)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isMine ? AppColors.tradingSell.withOpacity(0.15) : AppColors.tradingBuy.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(isMine ? 'Sell' : 'Buy', style: TextStyle(color: isMine ? AppColors.tradingSell : AppColors.tradingBuy, fontSize: 10, fontWeight: FontWeight.w600)),
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

  void _showBuyModal(BuildContext context, Map<String, dynamic> nft, bool isDark) {
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
                      Text(isComplete ? 'Purchase Complete!' : 'Buy NFT', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, color: textColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Step indicator
                if (!isComplete) Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      _buildStepIndicator(0, currentStep, 'Select', isDark),
                      Expanded(child: Container(height: 2, color: currentStep > 0 ? AppColors.primary : Colors.grey[700])),
                      _buildStepIndicator(1, currentStep, 'Payment', isDark),
                      Expanded(child: Container(height: 2, color: currentStep > 1 ? AppColors.primary : Colors.grey[700])),
                      _buildStepIndicator(2, currentStep, 'Confirm', isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: isComplete
                        ? _buildSuccessContent(nft, textColor, cardColor, 'purchased')
                        : currentStep == 0
                            ? _buildSelectStep(nft, textColor, cardColor)
                            : currentStep == 1
                                ? _buildPaymentStep(nft, textColor, cardColor)
                                : _buildConfirmStep(nft, textColor, cardColor, isProcessing),
                  ),
                ),
                // Bottom buttons
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
                      : Row(
                          children: [
                            if (currentStep > 0)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => setModalState(() => currentStep--),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[400]!),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: Text('Back', style: TextStyle(color: textColor)),
                                ),
                              ),
                            if (currentStep > 0) const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isProcessing ? null : () {
                                  if (currentStep < 2) {
                                    setModalState(() => currentStep++);
                                  } else {
                                    setModalState(() => isProcessing = true);
                                    Future.delayed(const Duration(seconds: 2), () {
                                      setModalState(() {
                                        isProcessing = false;
                                        isComplete = true;
                                      });
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: isProcessing
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                                    : Text(currentStep < 2 ? 'Continue' : 'Confirm Purchase', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSellModal(BuildContext context, Map<String, dynamic> nft, bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final cardColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5);
    int currentStep = 0;
    bool isProcessing = false;
    bool isComplete = false;
    double listPrice = nft['price'] as double;

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
                      Text(isComplete ? 'NFT Listed!' : 'Sell NFT', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, color: textColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                if (!isComplete) Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      _buildStepIndicator(0, currentStep, 'Price', isDark),
                      Expanded(child: Container(height: 2, color: currentStep > 0 ? AppColors.primary : Colors.grey[700])),
                      _buildStepIndicator(1, currentStep, 'Review', isDark),
                      Expanded(child: Container(height: 2, color: currentStep > 1 ? AppColors.primary : Colors.grey[700])),
                      _buildStepIndicator(2, currentStep, 'List', isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: isComplete
                        ? _buildSuccessContent(nft, textColor, cardColor, 'listed')
                        : _buildSellStepContent(currentStep, nft, textColor, cardColor, listPrice, isProcessing),
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
                      : Row(
                          children: [
                            if (currentStep > 0)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => setModalState(() => currentStep--),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[400]!),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: Text('Back', style: TextStyle(color: textColor)),
                                ),
                              ),
                            if (currentStep > 0) const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isProcessing ? null : () {
                                  if (currentStep < 2) {
                                    setModalState(() => currentStep++);
                                  } else {
                                    setModalState(() => isProcessing = true);
                                    Future.delayed(const Duration(seconds: 2), () {
                                      setModalState(() {
                                        isProcessing = false;
                                        isComplete = true;
                                      });
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.tradingSell,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: isProcessing
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Text(currentStep < 2 ? 'Continue' : 'List for Sale', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
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
                      Text(isComplete ? 'NFT Minted!' : 'Mint NFT', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, color: textColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                if (!isComplete) Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      _buildStepIndicator(0, currentStep, 'Upload', isDark),
                      Expanded(child: Container(height: 2, color: currentStep > 0 ? AppColors.primary : Colors.grey[700])),
                      _buildStepIndicator(1, currentStep, 'Details', isDark),
                      Expanded(child: Container(height: 2, color: currentStep > 1 ? AppColors.primary : Colors.grey[700])),
                      _buildStepIndicator(2, currentStep, 'Mint', isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: isComplete
                        ? _buildMintSuccessContent(textColor, cardColor)
                        : _buildMintStepContent(currentStep, textColor, cardColor, isDark, isProcessing),
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
                      : Row(
                          children: [
                            if (currentStep > 0)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => setModalState(() => currentStep--),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[400]!),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: Text('Back', style: TextStyle(color: textColor)),
                                ),
                              ),
                            if (currentStep > 0) const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isProcessing ? null : () {
                                  if (currentStep < 2) {
                                    setModalState(() => currentStep++);
                                  } else {
                                    setModalState(() => isProcessing = true);
                                    Future.delayed(const Duration(seconds: 2), () {
                                      setModalState(() {
                                        isProcessing = false;
                                        isComplete = true;
                                      });
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: isProcessing
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Text(currentStep < 2 ? 'Continue' : 'Mint NFT', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepIndicator(int step, int currentStep, String label, bool isDark) {
    final isActive = step <= currentStep;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.grey[700],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isActive && step < currentStep
                ? const Icon(Icons.check, color: Colors.black, size: 16)
                : Text('${step + 1}', style: TextStyle(color: isActive ? Colors.black : Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: isActive ? (isDark ? Colors.white : Colors.black) : Colors.grey[600], fontSize: 10)),
      ],
    );
  }

  Widget _buildSelectStep(Map<String, dynamic> nft, Color textColor, Color cardColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary.withOpacity(0.3), Colors.purple.withOpacity(0.3)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Icon(Icons.diamond, size: 64, color: AppColors.primary)),
        ),
        const SizedBox(height: 16),
        Text(nft['name'], style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(nft['collection'], style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Price', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              Text('${nft['price']} ${nft['currency']}', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStep(Map<String, dynamic> nft, Color textColor, Color cardColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Payment Method', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        _buildPaymentOption('ETH Wallet', 'Balance: 5.23 ETH', true, cardColor, textColor),
        const SizedBox(height: 12),
        _buildPaymentOption('USDT Wallet', 'Balance: 2,450 USDT', false, cardColor, textColor),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('NFT Price', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                Text('${nft['price']} ETH', style: TextStyle(color: textColor, fontSize: 14)),
              ]),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Gas Fee (est.)', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                Text('0.005 ETH', style: TextStyle(color: textColor, fontSize: 14)),
              ]),
              const Divider(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Total', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
                Text('${nft['price'] + 0.005} ETH', style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w700)),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmStep(Map<String, dynamic> nft, Color textColor, Color cardColor, bool isProcessing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isProcessing) ...[
          const SizedBox(height: 40),
          Center(child: CircularProgressIndicator(color: AppColors.primary)),
          const SizedBox(height: 24),
          Center(child: Text('Processing transaction...', style: TextStyle(color: textColor, fontSize: 16))),
          const SizedBox(height: 8),
          Center(child: Text('Please wait while we confirm your purchase', style: TextStyle(color: Colors.grey[600], fontSize: 14))),
        ] else ...[
          Text('Confirm Purchase', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.3), Colors.purple.withOpacity(0.3)]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.diamond, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nft['name'], style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(nft['collection'], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
                Text('${nft['price']} ETH', style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w700)),
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
                Expanded(child: Text('This transaction cannot be reversed. Please review before confirming.', style: TextStyle(color: AppColors.warning, fontSize: 12))),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSuccessContent(Map<String, dynamic> nft, Color textColor, Color cardColor, String action) {
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
        Text('Successfully $action!', style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Your NFT has been $action', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.3), Colors.purple.withOpacity(0.3)]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.diamond, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nft['name'], style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(nft['collection'], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSellStepContent(int step, Map<String, dynamic> nft, Color textColor, Color cardColor, double price, bool isProcessing) {
    if (step == 0) {
      return Column(
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
                    style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: price.toString(),
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      border: InputBorder.none,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                Text('ETH', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Suggested prices based on similar NFTs', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildPriceSuggestion('1.0 ETH', cardColor, textColor),
              const SizedBox(width: 8),
              _buildPriceSuggestion('1.5 ETH', cardColor, textColor),
              const SizedBox(width: 8),
              _buildPriceSuggestion('2.0 ETH', cardColor, textColor),
            ],
          ),
        ],
      );
    } else if (step == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Review Listing', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Listing Price', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  Text('$price ETH', style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Platform Fee (2.5%)', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  Text('${(price * 0.025).toStringAsFixed(4)} ETH', style: TextStyle(color: textColor, fontSize: 14)),
                ]),
                const Divider(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('You Receive', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
                  Text('${(price * 0.975).toStringAsFixed(4)} ETH', style: TextStyle(color: AppColors.tradingBuy, fontSize: 16, fontWeight: FontWeight.w700)),
                ]),
              ],
            ),
          ),
        ],
      );
    } else {
      return isProcessing
          ? Column(
              children: [
                const SizedBox(height: 40),
                Center(child: CircularProgressIndicator(color: AppColors.tradingSell)),
                const SizedBox(height: 24),
                Center(child: Text('Creating listing...', style: TextStyle(color: textColor, fontSize: 16))),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Confirm Listing', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Your NFT will be listed on the marketplace', style: TextStyle(color: AppColors.warning, fontSize: 12))),
                    ],
                  ),
                ),
              ],
            );
    }
  }

  Widget _buildMintStepContent(int step, Color textColor, Color cardColor, bool isDark, bool isProcessing) {
    if (step == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Upload Artwork', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[400]!, style: BorderStyle.solid),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.grey[600]),
                  const SizedBox(height: 12),
                  Text('Click to upload', style: TextStyle(color: textColor, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('PNG, JPG, GIF up to 50MB', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      );
    } else if (step == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NFT Details', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          _buildTextField('Name', 'Enter NFT name', cardColor, textColor, isDark),
          const SizedBox(height: 12),
          _buildTextField('Description', 'Describe your NFT', cardColor, textColor, isDark, maxLines: 3),
          const SizedBox(height: 12),
          _buildTextField('Collection', 'Select or create collection', cardColor, textColor, isDark),
          const SizedBox(height: 12),
          _buildTextField('Royalties (%)', '2.5', cardColor, textColor, isDark),
        ],
      );
    } else {
      return isProcessing
          ? Column(
              children: [
                const SizedBox(height: 40),
                Center(child: CircularProgressIndicator(color: Colors.purple)),
                const SizedBox(height: 24),
                Center(child: Text('Minting your NFT...', style: TextStyle(color: textColor, fontSize: 16))),
                const SizedBox(height: 8),
                Center(child: Text('This may take a few moments', style: TextStyle(color: Colors.grey[600], fontSize: 14))),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ready to Mint', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Minting Fee', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                        Text('0.01 ETH', style: TextStyle(color: textColor, fontSize: 14)),
                      ]),
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Gas Fee (est.)', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                        Text('0.003 ETH', style: TextStyle(color: textColor, fontSize: 14)),
                      ]),
                      const Divider(height: 24),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Total', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
                        Text('0.013 ETH', style: TextStyle(color: Colors.purple, fontSize: 16, fontWeight: FontWeight.w700)),
                      ]),
                    ],
                  ),
                ),
              ],
            );
    }
  }

  Widget _buildMintSuccessContent(Color textColor, Color cardColor) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.purple, size: 40),
        ),
        const SizedBox(height: 24),
        Text('NFT Minted Successfully!', style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Your NFT is now on the blockchain', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.3), Colors.purple.withOpacity(0.3)]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.diamond, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('New NFT', style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600)),
                    Text('View in My NFTs', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(String title, String subtitle, bool selected, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? AppColors.primary : Colors.transparent, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet, color: selected ? AppColors.primary : Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600)),
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          if (selected) Icon(Icons.check_circle, color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildPriceSuggestion(String price, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(price, style: TextStyle(color: textColor, fontSize: 12)),
    );
  }

  Widget _buildTextField(String label, String hint, Color cardColor, Color textColor, bool isDark, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[400]!),
          ),
          child: TextField(
            style: TextStyle(color: textColor, fontSize: 14),
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[600]),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
