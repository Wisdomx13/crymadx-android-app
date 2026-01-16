import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// CryptoIcon - Shows real cryptocurrency logos from multiple reliable CDNs
class CryptoIcon extends StatelessWidget {
  final String symbol;
  final double size;
  final bool showBorder;
  final Color? backgroundColor;

  const CryptoIcon({
    super.key,
    required this.symbol,
    this.size = 40,
    this.showBorder = false,
    this.backgroundColor,
  });

  /// Get crypto color for the symbol
  Color get cryptoColor => getCryptoColor(symbol);

  @override
  Widget build(BuildContext context) {
    final lowerSymbol = symbol.toLowerCase();

    // Get all possible image URLs to try
    final imageUrls = _getAllImageUrls(lowerSymbol);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? cryptoColor.withOpacity(0.15),
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: AppColors.glassBorder, width: 1)
            : null,
      ),
      child: ClipOval(
        child: _CryptoImageWithFallback(
          imageUrls: imageUrls,
          size: size,
          symbol: symbol,
          cryptoColor: cryptoColor,
        ),
      ),
    );
  }

  /// Get multiple image URLs to try in order of reliability
  static List<String> _getAllImageUrls(String lowerSymbol) {
    final urls = <String>[];

    // 1. jsDelivr CDN (cryptocurrency-icons) - Most reliable, proper CORS
    urls.add('https://cdn.jsdelivr.net/gh/atomiclabs/cryptocurrency-icons@1a63530be6e374711a8554f31b17e4cb92c25fa5/128/color/$lowerSymbol.png');

    // 2. CoinGecko images (using coin ID mapping)
    final coinGeckoId = _coinGeckoIds[lowerSymbol.toUpperCase()];
    if (coinGeckoId != null) {
      urls.add('https://assets.coingecko.com/coins/images/$coinGeckoId/small/${lowerSymbol}.png');
    }

    // 3. Crypto Icons API
    urls.add('https://cryptoicons.org/api/icon/$lowerSymbol/128');

    // 4. Alternative jsdelivr path
    urls.add('https://cdn.jsdelivr.net/gh/spothq/cryptocurrency-icons@master/128/color/$lowerSymbol.png');

    // 5. CryptoCompare (backup)
    urls.add('https://www.cryptocompare.com/media/37746251/$lowerSymbol.png');

    return urls;
  }

  /// CoinGecko coin IDs for some popular coins
  static const Map<String, String> _coinGeckoIds = {
    'BTC': '1/large/bitcoin',
    'ETH': '279/large/ethereum',
    'USDT': '325/large/Tether',
    'BNB': '825/large/bnb-icon2_2x',
    'SOL': '4128/large/solana',
    'XRP': '44/large/xrp-symbol-white-128',
    'USDC': '6319/large/usdc',
    'ADA': '975/large/cardano',
    'DOGE': '5/large/dogecoin',
    'AVAX': '12559/large/Avalanche_Circle_RedWhite_Trans',
    'DOT': '12171/large/polkadot',
    'TRX': '1094/large/tron-logo',
    'MATIC': '4713/large/polygon',
    'LINK': '877/large/chainlink-new-logo',
    'SHIB': '11939/large/shiba',
    'LTC': '2/large/litecoin',
    'ATOM': '1481/large/cosmos_hub',
    'UNI': '12504/large/uniswap',
    'XLM': '100/large/Stellar_symbol_black_RGB',
  };
}

/// Widget that tries multiple image URLs with fallback
class _CryptoImageWithFallback extends StatefulWidget {
  final List<String> imageUrls;
  final double size;
  final String symbol;
  final Color cryptoColor;

  const _CryptoImageWithFallback({
    required this.imageUrls,
    required this.size,
    required this.symbol,
    required this.cryptoColor,
  });

  @override
  State<_CryptoImageWithFallback> createState() => _CryptoImageWithFallbackState();
}

class _CryptoImageWithFallbackState extends State<_CryptoImageWithFallback> {
  int _currentUrlIndex = 0;
  bool _allFailed = false;

  @override
  Widget build(BuildContext context) {
    if (_allFailed || widget.imageUrls.isEmpty) {
      return _buildTextFallback();
    }

    return Image.network(
      widget.imageUrls[_currentUrlIndex],
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Try next URL
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _currentUrlIndex < widget.imageUrls.length - 1) {
            setState(() {
              _currentUrlIndex++;
            });
          } else if (mounted) {
            setState(() {
              _allFailed = true;
            });
          }
        });
        return _buildTextFallback();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildLoadingIndicator();
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.cryptoColor.withOpacity(0.2),
            widget.cryptoColor.withOpacity(0.1),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SizedBox(
          width: widget.size * 0.4,
          height: widget.size * 0.4,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(widget.cryptoColor),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFallback() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.cryptoColor.withOpacity(0.3),
            widget.cryptoColor.withOpacity(0.1),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          widget.symbol.length > 2
              ? widget.symbol.substring(0, 2).toUpperCase()
              : widget.symbol.toUpperCase(),
          style: TextStyle(
            fontSize: widget.size * 0.35,
            fontWeight: FontWeight.w700,
            color: widget.cryptoColor,
          ),
        ),
      ),
    );
  }
}

/// Get crypto brand color
Color getCryptoColor(String symbol) {
  final colors = {
    'BTC': const Color(0xFFF7931A),
    'ETH': const Color(0xFF627EEA),
    'USDT': const Color(0xFF26A17B),
    'BNB': const Color(0xFFF3BA2F),
    'SOL': const Color(0xFF00FFA3),
    'XRP': const Color(0xFF23292F),
    'USDC': const Color(0xFF2775CA),
    'ADA': const Color(0xFF0033AD),
    'DOGE': const Color(0xFFC2A633),
    'DOT': const Color(0xFFE6007A),
    'MATIC': const Color(0xFF8247E5),
    'LTC': const Color(0xFFBFBBBB),
    'AVAX': const Color(0xFFE84142),
    'LINK': const Color(0xFF2A5ADA),
    'ATOM': const Color(0xFF2E3148),
    'UNI': const Color(0xFFFF007A),
    'XLM': const Color(0xFF14B6E7),
    'TRX': const Color(0xFFFF0013),
    'NEAR': const Color(0xFF000000),
    'APT': const Color(0xFF4CEAAE),
    'ARB': const Color(0xFF213147),
    'OP': const Color(0xFFFF0420),
    'SHIB': const Color(0xFFFFA409),
    'PEPE': const Color(0xFF4E9F3D),
    'FTM': const Color(0xFF1969FF),
    'INJ': const Color(0xFF00F2FE),
    'SUI': const Color(0xFF6FBCF0),
    'SEI': const Color(0xFF9B1C1C),
    'TON': const Color(0xFF0098EA),
    'AAVE': const Color(0xFFB6509E),
    'MKR': const Color(0xFF1AAB9B),
    'CRV': const Color(0xFF003366),
    'SUSHI': const Color(0xFFFA52A0),
    'COMP': const Color(0xFF00D395),
    'YFI': const Color(0xFF006AE3),
    'SNX': const Color(0xFF00D1FF),
    'BAT': const Color(0xFFFF5000),
    'ZRX': const Color(0xFF000000),
    'ENJ': const Color(0xFF624DBF),
    'MANA': const Color(0xFFFF2D55),
    'SAND': const Color(0xFF04ADEF),
    'AXS': const Color(0xFF0055D5),
    'GALA': const Color(0xFF000000),
    'APE': const Color(0xFF0052FF),
    'GMT': const Color(0xFFE8D96E),
    'CAKE': const Color(0xFFD1884F),
    'XMR': const Color(0xFFFF6600),
    'ZEC': const Color(0xFFF4B728),
    'DASH': const Color(0xFF008CE7),
    'ETC': const Color(0xFF328332),
    'XTZ': const Color(0xFFA6E000),
    'EOS': const Color(0xFF000000),
    'IOTA': const Color(0xFF131F37),
    'NEO': const Color(0xFF00E599),
    'WAVES': const Color(0xFF0055FF),
    'ALGO': const Color(0xFF000000),
    'THETA': const Color(0xFF2AB8E6),
    'FIL': const Color(0xFF0090FF),
    'HBAR': const Color(0xFF000000),
    'VET': const Color(0xFF15BDFF),
    'EGLD': const Color(0xFF000000),
    'FLOW': const Color(0xFF00EF8B),
    'QNT': const Color(0xFF000000),
    'KSM': const Color(0xFF000000),
    'KLAY': const Color(0xFFFF4800),
    'ROSE': const Color(0xFF0092F6),
    'CHZ': const Color(0xFFCD0124),
    'HOT': const Color(0xFF8834FF),
    'ONE': const Color(0xFF00BFFF),
    'ZIL': const Color(0xFF49C1BF),
    'CELO': const Color(0xFFFCFF52),
    'ANKR': const Color(0xFF2E6DF5),
    'SKL': const Color(0xFF000000),
    'STORJ': const Color(0xFF2683FF),
    'LRC': const Color(0xFF1C60FF),
    'BAND': const Color(0xFF516AFF),
    'REN': const Color(0xFF001B3A),
    'NKN': const Color(0xFF23336F),
    'OCEAN': const Color(0xFF000000),
    'FET': const Color(0xFF1D2951),
    'CTSI': const Color(0xFF1A1B1D),
    'CELR': const Color(0xFF000000),
    'RSR': const Color(0xFF000000),
    'REEF': const Color(0xFFA30D91),
    'DENT': const Color(0xFF666666),
    'SXP': const Color(0xFFF25A3C),
    'BTT': const Color(0xFF000000),
    'DGB': const Color(0xFF006AD2),
    'RVN': const Color(0xFF384182),
    'SC': const Color(0xFF20EE82),
    'ICX': const Color(0xFF1FC5C9),
    'ONT': const Color(0xFF32A4BE),
    'OMG': const Color(0xFF101010),
    'RUNE': const Color(0xFF33FF99),
    'KAVA': const Color(0xFFFF433E),
    'CRO': const Color(0xFF103F68),
    'LUNA': const Color(0xFF172852),
    'LUNC': const Color(0xFFF9D85E),
    'WIF': const Color(0xFFBB5B2E),
    'BONK': const Color(0xFFF6A739),
    'FLOKI': const Color(0xFFF6A739),
    'PEPE': const Color(0xFF4E9F3D),
    'WLD': const Color(0xFF000000),
    'BLUR': const Color(0xFFFF6B00),
    'RNDR': const Color(0xFFDA3A34),
    'ARB': const Color(0xFF12AAFF),
    'OP': const Color(0xFFFF0420),
    'STX': const Color(0xFF5546FF),
    'IMX': const Color(0xFF17B5CB),
    'INJ': const Color(0xFF0082FA),
    'SUI': const Color(0xFF6FBCF0),
    'SEI': const Color(0xFF9B1C1C),
    'TIA': const Color(0xFF7B2BF9),
    'PYTH': const Color(0xFF7142CF),
    'JTO': const Color(0xFF000000),
    'TON': const Color(0xFF0098EA),
    'NOT': const Color(0xFF000000),
  };

  return colors[symbol.toUpperCase()] ?? AppColors.primary;
}

/// Crypto icon with name and price
class CryptoIconWithLabel extends StatelessWidget {
  final String symbol;
  final String name;
  final double? price;
  final double? change24h;
  final double iconSize;
  final VoidCallback? onTap;

  const CryptoIconWithLabel({
    super.key,
    required this.symbol,
    required this.name,
    this.price,
    this.change24h,
    this.iconSize = 40,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = (change24h ?? 0) >= 0;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          CryptoIcon(symbol: symbol, size: iconSize),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  symbol.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (price != null) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatPrice(price!),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'monospace',
                  ),
                ),
                if (change24h != null)
                  Text(
                    '${isPositive ? '+' : ''}${change24h!.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isPositive ? AppColors.tradingBuy : AppColors.tradingSell,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000) return '\$${price.toStringAsFixed(2)}';
    if (price >= 1) return '\$${price.toStringAsFixed(4)}';
    return '\$${price.toStringAsFixed(6)}';
  }
}

/// Small crypto badge
class CryptoBadge extends StatelessWidget {
  final String symbol;
  final double size;

  const CryptoBadge({
    super.key,
    required this.symbol,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return CryptoIcon(symbol: symbol, size: size);
  }
}
