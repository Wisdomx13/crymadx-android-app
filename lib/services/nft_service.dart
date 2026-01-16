import 'api_service.dart';
import '../config/api_config.dart';

/// NFT model - matches backend /api/nft endpoints
class NFT {
  final String id;
  final String tokenId;
  final String name;
  final String description;
  final String imageUrl;
  final String? animationUrl;
  final String collectionId;
  final String collectionName;
  final String contractAddress;
  final String network; // ethereum, polygon, etc.
  final String? ownerAddress;
  final double? price;
  final String? priceCurrency;
  final bool isListed;
  final Map<String, dynamic>? attributes;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;
  final DateTime? listedAt;

  NFT({
    required this.id,
    required this.tokenId,
    required this.name,
    required this.description,
    required this.imageUrl,
    this.animationUrl,
    required this.collectionId,
    required this.collectionName,
    required this.contractAddress,
    required this.network,
    this.ownerAddress,
    this.price,
    this.priceCurrency,
    required this.isListed,
    this.attributes,
    this.metadata,
    this.createdAt,
    this.listedAt,
  });

  factory NFT.fromJson(Map<String, dynamic> json) {
    return NFT(
      id: json['id'] ?? json['nftId'] ?? '',
      tokenId: json['tokenId'] ?? json['token_id'] ?? '',
      name: json['name'] ?? json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? json['image'] ?? json['image_url'] ?? '',
      animationUrl: json['animationUrl'] ?? json['animation_url'],
      collectionId: json['collectionId'] ?? json['collection']?['id'] ?? '',
      collectionName: json['collectionName'] ?? json['collection']?['name'] ?? '',
      contractAddress: json['contractAddress'] ?? json['contract'] ?? '',
      network: json['network'] ?? json['chain'] ?? 'ethereum',
      ownerAddress: json['ownerAddress'] ?? json['owner'],
      price: json['price'] != null ? (json['price']).toDouble() : null,
      priceCurrency: json['priceCurrency'] ?? json['currency'] ?? 'ETH',
      isListed: json['isListed'] ?? json['listed'] ?? false,
      attributes: json['attributes'] != null
          ? Map<String, dynamic>.from(json['attributes'])
          : null,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      listedAt: json['listedAt'] != null
          ? DateTime.parse(json['listedAt'])
          : null,
    );
  }
}

/// NFT Collection model
class NFTCollection {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String? bannerUrl;
  final String contractAddress;
  final String network;
  final String? creatorAddress;
  final int totalItems;
  final int listedItems;
  final double? floorPrice;
  final String? floorPriceCurrency;
  final double? totalVolume;
  final bool isVerified;
  final DateTime? createdAt;

  NFTCollection({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    this.bannerUrl,
    required this.contractAddress,
    required this.network,
    this.creatorAddress,
    required this.totalItems,
    required this.listedItems,
    this.floorPrice,
    this.floorPriceCurrency,
    this.totalVolume,
    required this.isVerified,
    this.createdAt,
  });

  factory NFTCollection.fromJson(Map<String, dynamic> json) {
    return NFTCollection(
      id: json['id'] ?? json['collectionId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? json['image'] ?? json['logo'] ?? '',
      bannerUrl: json['bannerUrl'] ?? json['banner'],
      contractAddress: json['contractAddress'] ?? json['contract'] ?? '',
      network: json['network'] ?? json['chain'] ?? 'ethereum',
      creatorAddress: json['creatorAddress'] ?? json['creator'],
      totalItems: json['totalItems'] ?? json['itemCount'] ?? 0,
      listedItems: json['listedItems'] ?? json['listedCount'] ?? 0,
      floorPrice: json['floorPrice'] != null ? (json['floorPrice']).toDouble() : null,
      floorPriceCurrency: json['floorPriceCurrency'] ?? json['currency'] ?? 'ETH',
      totalVolume: json['totalVolume'] != null ? (json['totalVolume']).toDouble() : null,
      isVerified: json['isVerified'] ?? json['verified'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }
}

/// NFT Listing model (for marketplace)
class NFTListing {
  final String id;
  final String nftId;
  final NFT nft;
  final double price;
  final String currency;
  final String sellerAddress;
  final String status; // active, sold, cancelled
  final DateTime listedAt;
  final DateTime? expiresAt;
  final DateTime? soldAt;

  NFTListing({
    required this.id,
    required this.nftId,
    required this.nft,
    required this.price,
    required this.currency,
    required this.sellerAddress,
    required this.status,
    required this.listedAt,
    this.expiresAt,
    this.soldAt,
  });

  factory NFTListing.fromJson(Map<String, dynamic> json) {
    return NFTListing(
      id: json['id'] ?? json['listingId'] ?? '',
      nftId: json['nftId'] ?? json['nft']?['id'] ?? '',
      nft: NFT.fromJson(json['nft'] ?? json),
      price: (json['price'] ?? 0).toDouble(),
      currency: json['currency'] ?? json['priceCurrency'] ?? 'ETH',
      sellerAddress: json['sellerAddress'] ?? json['seller'] ?? '',
      status: json['status'] ?? 'active',
      listedAt: json['listedAt'] != null
          ? DateTime.parse(json['listedAt'])
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : null,
      soldAt: json['soldAt'] != null
          ? DateTime.parse(json['soldAt'])
          : null,
    );
  }
}

/// NFT Purchase model
class NFTPurchase {
  final String id;
  final String listingId;
  final String nftId;
  final double price;
  final String currency;
  final double? fee;
  final String status; // pending, completed, failed
  final String? txHash;
  final DateTime createdAt;
  final DateTime? completedAt;

  NFTPurchase({
    required this.id,
    required this.listingId,
    required this.nftId,
    required this.price,
    required this.currency,
    this.fee,
    required this.status,
    this.txHash,
    required this.createdAt,
    this.completedAt,
  });

  factory NFTPurchase.fromJson(Map<String, dynamic> json) {
    return NFTPurchase(
      id: json['id'] ?? json['purchaseId'] ?? '',
      listingId: json['listingId'] ?? '',
      nftId: json['nftId'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'ETH',
      fee: json['fee'] != null ? (json['fee']).toDouble() : null,
      status: json['status'] ?? 'pending',
      txHash: json['txHash'] ?? json['transactionHash'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }
}

/// NFT Service - Handles all NFT marketplace API calls
class NFTService {
  final ApiService _api = api;

  // ============================================
  // MARKETPLACE
  // ============================================

  /// Get marketplace listings
  Future<List<NFTListing>> getMarketplaceListings({
    String? collectionId,
    String? network,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    String? sortOrder,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.get(
      ApiConfig.nftMarketplace,
      queryParameters: {
        if (collectionId != null) 'collectionId': collectionId,
        if (network != null) 'network': network,
        if (minPrice != null) 'minPrice': minPrice,
        if (maxPrice != null) 'maxPrice': maxPrice,
        if (sortBy != null) 'sortBy': sortBy,
        if (sortOrder != null) 'sortOrder': sortOrder,
        'page': page,
        'limit': limit,
      },
    );
    final List<dynamic> data = response['listings'] ?? response['items'] ?? [];
    return data.map((json) => NFTListing.fromJson(json)).toList();
  }

  /// Get platform listings
  Future<List<NFTListing>> getPlatformListings({int page = 1, int limit = 20}) async {
    final response = await _api.get(
      ApiConfig.nftPlatformListings,
      queryParameters: {'page': page, 'limit': limit},
    );
    final List<dynamic> data = response['listings'] ?? response['items'] ?? [];
    return data.map((json) => NFTListing.fromJson(json)).toList();
  }

  // ============================================
  // MY NFTS
  // ============================================

  /// Get owned NFTs
  Future<List<NFT>> getOwnedNFTs({
    String? collectionId,
    String? network,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.get(
      ApiConfig.nftOwned,
      queryParameters: {
        if (collectionId != null) 'collectionId': collectionId,
        if (network != null) 'network': network,
        'page': page,
        'limit': limit,
      },
    );
    final List<dynamic> data = response['nfts'] ?? response['items'] ?? [];
    return data.map((json) => NFT.fromJson(json)).toList();
  }

  // ============================================
  // NFT DETAILS
  // ============================================

  /// Get NFT details
  Future<NFT> getNFTDetails(String nftId) async {
    final response = await _api.get('${ApiConfig.nftDetails}/$nftId');
    final nftData = response['nft'] ?? response;
    return NFT.fromJson(nftData);
  }

  /// Get NFT details by contract and token ID
  Future<NFT> getNFTByContract(String contractAddress, String tokenId) async {
    final response = await _api.get(
      ApiConfig.nftDetails,
      queryParameters: {
        'contract': contractAddress,
        'tokenId': tokenId,
      },
    );
    final nftData = response['nft'] ?? response;
    return NFT.fromJson(nftData);
  }

  // ============================================
  // COLLECTIONS
  // ============================================

  /// Get collections
  Future<List<NFTCollection>> getCollections({
    String? network,
    bool? verified,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.get(
      ApiConfig.nftCollection,
      queryParameters: {
        if (network != null) 'network': network,
        if (verified != null) 'verified': verified,
        'page': page,
        'limit': limit,
      },
    );
    final List<dynamic> data = response['collections'] ?? response['items'] ?? [];
    return data.map((json) => NFTCollection.fromJson(json)).toList();
  }

  /// Get collection details
  Future<NFTCollection> getCollectionDetails(String collectionId) async {
    final response = await _api.get('${ApiConfig.nftCollection}/$collectionId');
    final collectionData = response['collection'] ?? response;
    return NFTCollection.fromJson(collectionData);
  }

  /// Get collection floor price
  Future<Map<String, dynamic>> getCollectionFloor(String collectionId) async {
    final response = await _api.get('${ApiConfig.nftFloor}/$collectionId');
    return {
      'floorPrice': (response['floorPrice'] ?? response['floor'] ?? 0).toDouble(),
      'currency': response['currency'] ?? 'ETH',
      'change24h': response['change24h'] != null
          ? (response['change24h']).toDouble()
          : null,
    };
  }

  // ============================================
  // LISTING & PURCHASE
  // ============================================

  /// List NFT for sale
  Future<NFTListing> listNFT({
    required String nftId,
    required double price,
    required String currency,
    int? durationDays,
  }) async {
    final response = await _api.post(
      ApiConfig.nftList,
      data: {
        'nftId': nftId,
        'price': price,
        'currency': currency,
        if (durationDays != null) 'durationDays': durationDays,
      },
    );
    final listingData = response['listing'] ?? response;
    return NFTListing.fromJson(listingData);
  }

  /// Cancel listing
  Future<void> cancelListing(String listingId) async {
    await _api.delete('${ApiConfig.nftList}/$listingId');
  }

  /// Update listing price
  Future<NFTListing> updateListingPrice(String listingId, double newPrice) async {
    final response = await _api.put(
      '${ApiConfig.nftList}/$listingId',
      data: {'price': newPrice},
    );
    final listingData = response['listing'] ?? response;
    return NFTListing.fromJson(listingData);
  }

  /// Purchase NFT
  Future<NFTPurchase> purchaseNFT(String listingId) async {
    final response = await _api.post(
      ApiConfig.nftPurchase,
      data: {'listingId': listingId},
    );
    final purchaseData = response['purchase'] ?? response;
    return NFTPurchase.fromJson(purchaseData);
  }

  /// Get purchase status
  Future<NFTPurchase> getPurchaseStatus(String purchaseId) async {
    final response = await _api.get('${ApiConfig.nftPurchase}/$purchaseId');
    final purchaseData = response['purchase'] ?? response;
    return NFTPurchase.fromJson(purchaseData);
  }

  // ============================================
  // ACTIVITY
  // ============================================

  /// Get NFT activity history
  Future<List<Map<String, dynamic>>> getNFTActivity(String nftId, {int limit = 20}) async {
    final response = await _api.get(
      '${ApiConfig.nft}/activity/$nftId',
      queryParameters: {'limit': limit},
    );
    final List<dynamic> data = response['activity'] ?? response['history'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  /// Get user's NFT activity
  Future<List<Map<String, dynamic>>> getMyActivity({int page = 1, int limit = 20}) async {
    final response = await _api.get(
      '${ApiConfig.nft}/my-activity',
      queryParameters: {'page': page, 'limit': limit},
    );
    final List<dynamic> data = response['activity'] ?? response['items'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }
}

/// Global NFT service instance
final nftService = NFTService();
