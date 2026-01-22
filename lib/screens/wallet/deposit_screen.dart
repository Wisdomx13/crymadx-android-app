import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/spacing.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/app_button.dart';
import '../../widgets/crypto_icon.dart';
import '../../services/wallet_service.dart';

/// Network icon data with logo URL and fallback color
class NetworkIconData {
  final String? logoUrl;
  final Color color;
  final IconData fallbackIcon;

  const NetworkIconData({
    this.logoUrl,
    required this.color,
    this.fallbackIcon = Icons.hub,
  });
}

/// Get network icon data for a specific network
NetworkIconData getNetworkIconData(String network) {
  final networkLower = network.toLowerCase();

  // Network logo URLs and colors
  switch (networkLower) {
    // Bitcoin networks
    case 'bitcoin':
      return NetworkIconData(
        logoUrl: 'https://cryptologos.cc/logos/bitcoin-btc-logo.png',
        color: const Color(0xFFF7931A),
      );
    case 'lightning':
      return NetworkIconData(
        logoUrl: 'https://cryptologos.cc/logos/lightning-network-logo.png',
        color: const Color(0xFFF7931A),
        fallbackIcon: Icons.bolt,
      );

    // Ethereum & EVM networks
    case 'erc20':
    case 'ethereum':
      return NetworkIconData(
        logoUrl: 'https://cryptologos.cc/logos/ethereum-eth-logo.png',
        color: const Color(0xFF627EEA),
      );
    case 'bep20':
    case 'bep2':
    case 'bnb':
    case 'binance':
      return NetworkIconData(
        logoUrl: 'https://cryptologos.cc/logos/bnb-bnb-logo.png',
        color: const Color(0xFFF0B90B),
      );
    case 'trc20':
    case 'tron':
      return NetworkIconData(
        logoUrl: 'https://cryptologos.cc/logos/tron-trx-logo.png',
        color: const Color(0xFFFF0013),
      );
    case 'polygon':
    case 'matic':
      return NetworkIconData(
        logoUrl: 'https://cryptologos.cc/logos/polygon-matic-logo.png',
        color: const Color(0xFF8247E5),
      );
    case 'arbitrum':
      return NetworkIconData(
        logoUrl: 'https://cryptologos.cc/logos/arbitrum-arb-logo.png',
        color: const Color(0xFF28A0F0),
      );
    case 'optimism':
      return NetworkIconData(
        logoUrl: 'https://cryptologos.cc/logos/optimism-ethereum-op-logo.png',
        color: const Color(0xFFFF0420),
      );
    case 'base':
      return NetworkIconData(
        logoUrl: 'https://raw.githubusercontent.com/base-org/brand-kit/main/logo/symbol/Base_Symbol_Blue.png',
        color: const Color(0xFF0052FF),
      );
    case 'avalanche':
    case 'avalanche c-chain':
      return NetworkIconData(
        logoUrl: 'https://cryptologos.cc/logos/avalanche-avax-logo.png',
        color: const Color(0xFFE84142),
      );

    // Other networks
    case 'solana':
      return NetworkIconData(
        logoUrl: 'https://cryptologos.cc/logos/solana-sol-logo.png',
        color: const Color(0xFF00FFA3),
      );
    case 'ton':
      return NetworkIconData(
        logoUrl: 'https://cryptologos.cc/logos/toncoin-ton-logo.png',
        color: const Color(0xFF0098EA),
      );
    case 'cardano':
      return NetworkIconData(
        logoUrl: 'https://cryptologos.cc/logos/cardano-ada-logo.png',
        color: const Color(0xFF0033AD),
      );
    case 'xrp ledger':
    case 'xrp':
      return NetworkIconData(
        logoUrl: 'https://cryptologos.cc/logos/xrp-xrp-logo.png',
        color: const Color(0xFF23292F),
      );
    case 'stellar':
      return NetworkIconData(
        logoUrl: 'https://cryptologos.cc/logos/stellar-xlm-logo.png',
        color: const Color(0xFF000000),
      );
    case 'cosmos':
      return NetworkIconData(
        logoUrl: 'https://cryptologos.cc/logos/cosmos-atom-logo.png',
        color: const Color(0xFF2E3148),
      );
    case 'polkadot':
      return NetworkIconData(
        logoUrl: 'https://cryptologos.cc/logos/polkadot-new-dot-logo.png',
        color: const Color(0xFFE6007A),
      );
    case 'near':
      return NetworkIconData(
        logoUrl: 'https://cryptologos.cc/logos/near-protocol-near-logo.png',
        color: const Color(0xFF000000),
      );
    case 'fantom':
      return NetworkIconData(
        logoUrl: 'https://cryptologos.cc/logos/fantom-ftm-logo.png',
        color: const Color(0xFF1969FF),
      );
    case 'zksync era':
    case 'zksync':
      return NetworkIconData(
        logoUrl: 'https://raw.githubusercontent.com/matter-labs/web3-icons/main/icons/default/zksync.svg',
        color: const Color(0xFF8C8DFC),
      );
    case 'litecoin':
      return NetworkIconData(
        logoUrl: 'https://cryptologos.cc/logos/litecoin-ltc-logo.png',
        color: const Color(0xFFBFBBBB),
      );
    case 'bitcoin cash':
      return NetworkIconData(
        logoUrl: 'https://cryptologos.cc/logos/bitcoin-cash-bch-logo.png',
        color: const Color(0xFF8DC351),
      );
    case 'dogecoin':
      return NetworkIconData(
        logoUrl: 'https://cryptologos.cc/logos/dogecoin-doge-logo.png',
        color: const Color(0xFFC2A633),
      );

    // Default
    default:
      return NetworkIconData(
        color: AppColors.primary,
      );
  }
}

/// Widget to display network icon with logo or fallback
class NetworkIcon extends StatelessWidget {
  final String network;
  final double size;

  const NetworkIcon({
    super.key,
    required this.network,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final data = getNetworkIconData(network);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: data.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.2),
          child: data.logoUrl != null
              ? CachedNetworkImage(
                  imageUrl: data.logoUrl!,
                  width: size * 0.6,
                  height: size * 0.6,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => _buildFallback(data),
                  errorWidget: (context, url, error) => _buildFallback(data),
                )
              : _buildFallback(data),
        ),
      ),
    );
  }

  Widget _buildFallback(NetworkIconData data) {
    return Icon(
      data.fallbackIcon,
      color: data.color,
      size: size * 0.5,
    );
  }
}

// Comprehensive crypto asset data with networks
class CryptoAsset {
  final String symbol;
  final String name;
  final List<String> networks;

  const CryptoAsset({
    required this.symbol,
    required this.name,
    required this.networks,
  });
}

// 500+ crypto assets list
const List<CryptoAsset> allCryptoAssets = [
  // Top 50 by market cap
  CryptoAsset(symbol: 'BTC', name: 'Bitcoin', networks: ['Bitcoin', 'BEP20', 'Lightning']),
  CryptoAsset(symbol: 'ETH', name: 'Ethereum', networks: ['ERC20', 'BEP20', 'Arbitrum', 'Optimism', 'Base']),
  CryptoAsset(symbol: 'USDT', name: 'Tether', networks: ['ERC20', 'TRC20', 'BEP20', 'Solana', 'Polygon', 'Arbitrum', 'Optimism', 'Avalanche']),
  CryptoAsset(symbol: 'BNB', name: 'BNB', networks: ['BEP20', 'BEP2']),
  CryptoAsset(symbol: 'SOL', name: 'Solana', networks: ['Solana']),
  CryptoAsset(symbol: 'XRP', name: 'XRP', networks: ['XRP Ledger']),
  CryptoAsset(symbol: 'USDC', name: 'USD Coin', networks: ['ERC20', 'BEP20', 'Solana', 'Polygon', 'Arbitrum', 'Optimism', 'Base', 'Avalanche']),
  CryptoAsset(symbol: 'ADA', name: 'Cardano', networks: ['Cardano']),
  CryptoAsset(symbol: 'AVAX', name: 'Avalanche', networks: ['Avalanche C-Chain', 'BEP20']),
  CryptoAsset(symbol: 'DOGE', name: 'Dogecoin', networks: ['Dogecoin', 'BEP20']),
  CryptoAsset(symbol: 'TRX', name: 'Tron', networks: ['TRC20']),
  CryptoAsset(symbol: 'DOT', name: 'Polkadot', networks: ['Polkadot']),
  CryptoAsset(symbol: 'LINK', name: 'Chainlink', networks: ['ERC20', 'BEP20']),
  CryptoAsset(symbol: 'MATIC', name: 'Polygon', networks: ['Polygon', 'ERC20', 'BEP20']),
  CryptoAsset(symbol: 'SHIB', name: 'Shiba Inu', networks: ['ERC20', 'BEP20']),
  CryptoAsset(symbol: 'DAI', name: 'Dai', networks: ['ERC20', 'Polygon', 'Optimism', 'Arbitrum']),
  CryptoAsset(symbol: 'LTC', name: 'Litecoin', networks: ['Litecoin', 'BEP20']),
  CryptoAsset(symbol: 'BCH', name: 'Bitcoin Cash', networks: ['Bitcoin Cash']),
  CryptoAsset(symbol: 'ATOM', name: 'Cosmos', networks: ['Cosmos']),
  CryptoAsset(symbol: 'UNI', name: 'Uniswap', networks: ['ERC20', 'BEP20']),
  CryptoAsset(symbol: 'XLM', name: 'Stellar', networks: ['Stellar']),
  CryptoAsset(symbol: 'ETC', name: 'Ethereum Classic', networks: ['ETC']),
  CryptoAsset(symbol: 'XMR', name: 'Monero', networks: ['Monero']),
  CryptoAsset(symbol: 'OKB', name: 'OKB', networks: ['ERC20', 'OKX Chain']),
  CryptoAsset(symbol: 'FIL', name: 'Filecoin', networks: ['Filecoin', 'BEP20']),
  CryptoAsset(symbol: 'HBAR', name: 'Hedera', networks: ['Hedera']),
  CryptoAsset(symbol: 'APT', name: 'Aptos', networks: ['Aptos']),
  CryptoAsset(symbol: 'ARB', name: 'Arbitrum', networks: ['Arbitrum']),
  CryptoAsset(symbol: 'CRO', name: 'Cronos', networks: ['Cronos', 'ERC20']),
  CryptoAsset(symbol: 'VET', name: 'VeChain', networks: ['VeChain']),
  CryptoAsset(symbol: 'NEAR', name: 'NEAR Protocol', networks: ['NEAR']),
  CryptoAsset(symbol: 'MKR', name: 'Maker', networks: ['ERC20']),
  CryptoAsset(symbol: 'GRT', name: 'The Graph', networks: ['ERC20', 'Arbitrum']),
  CryptoAsset(symbol: 'AAVE', name: 'Aave', networks: ['ERC20', 'Polygon']),
  CryptoAsset(symbol: 'ALGO', name: 'Algorand', networks: ['Algorand']),
  CryptoAsset(symbol: 'QNT', name: 'Quant', networks: ['ERC20']),
  CryptoAsset(symbol: 'EOS', name: 'EOS', networks: ['EOS']),
  CryptoAsset(symbol: 'STX', name: 'Stacks', networks: ['Stacks']),
  CryptoAsset(symbol: 'SAND', name: 'The Sandbox', networks: ['ERC20', 'Polygon']),
  CryptoAsset(symbol: 'MANA', name: 'Decentraland', networks: ['ERC20', 'Polygon']),
  CryptoAsset(symbol: 'THETA', name: 'Theta Network', networks: ['Theta']),
  CryptoAsset(symbol: 'AXS', name: 'Axie Infinity', networks: ['ERC20', 'Ronin']),
  CryptoAsset(symbol: 'EGLD', name: 'MultiversX', networks: ['MultiversX']),
  CryptoAsset(symbol: 'XTZ', name: 'Tezos', networks: ['Tezos']),
  CryptoAsset(symbol: 'IMX', name: 'Immutable', networks: ['ERC20']),
  CryptoAsset(symbol: 'FLOW', name: 'Flow', networks: ['Flow']),
  CryptoAsset(symbol: 'NEO', name: 'Neo', networks: ['Neo N3', 'Neo Legacy']),
  CryptoAsset(symbol: 'KAVA', name: 'Kava', networks: ['Kava']),
  CryptoAsset(symbol: 'CAKE', name: 'PancakeSwap', networks: ['BEP20']),
  CryptoAsset(symbol: 'RUNE', name: 'THORChain', networks: ['THORChain', 'BEP20']),
  // 51-100
  CryptoAsset(symbol: 'ZEC', name: 'Zcash', networks: ['Zcash']),
  CryptoAsset(symbol: 'DASH', name: 'Dash', networks: ['Dash']),
  CryptoAsset(symbol: 'COMP', name: 'Compound', networks: ['ERC20']),
  CryptoAsset(symbol: 'SNX', name: 'Synthetix', networks: ['ERC20', 'Optimism']),
  CryptoAsset(symbol: 'CHZ', name: 'Chiliz', networks: ['ERC20', 'Chiliz Chain']),
  CryptoAsset(symbol: 'ENJ', name: 'Enjin Coin', networks: ['ERC20']),
  CryptoAsset(symbol: 'BAT', name: 'Basic Attention Token', networks: ['ERC20']),
  CryptoAsset(symbol: '1INCH', name: '1inch', networks: ['ERC20', 'BEP20']),
  CryptoAsset(symbol: 'CRV', name: 'Curve DAO', networks: ['ERC20']),
  CryptoAsset(symbol: 'SUSHI', name: 'SushiSwap', networks: ['ERC20', 'Polygon']),
  CryptoAsset(symbol: 'YFI', name: 'yearn.finance', networks: ['ERC20']),
  CryptoAsset(symbol: 'LRC', name: 'Loopring', networks: ['ERC20']),
  CryptoAsset(symbol: 'ZRX', name: '0x', networks: ['ERC20']),
  CryptoAsset(symbol: 'KSM', name: 'Kusama', networks: ['Kusama']),
  CryptoAsset(symbol: 'WAVES', name: 'Waves', networks: ['Waves']),
  CryptoAsset(symbol: 'OMG', name: 'OMG Network', networks: ['ERC20']),
  CryptoAsset(symbol: 'IOTA', name: 'IOTA', networks: ['IOTA']),
  CryptoAsset(symbol: 'ZIL', name: 'Zilliqa', networks: ['Zilliqa']),
  CryptoAsset(symbol: 'ICX', name: 'ICON', networks: ['ICON']),
  CryptoAsset(symbol: 'ONT', name: 'Ontology', networks: ['Ontology']),
  CryptoAsset(symbol: 'DGB', name: 'DigiByte', networks: ['DigiByte']),
  CryptoAsset(symbol: 'SC', name: 'Siacoin', networks: ['Sia']),
  CryptoAsset(symbol: 'RVN', name: 'Ravencoin', networks: ['Ravencoin']),
  CryptoAsset(symbol: 'BTT', name: 'BitTorrent', networks: ['TRC20', 'BEP20']),
  CryptoAsset(symbol: 'CELO', name: 'Celo', networks: ['Celo']),
  CryptoAsset(symbol: 'HOT', name: 'Holo', networks: ['ERC20']),
  CryptoAsset(symbol: 'ONE', name: 'Harmony', networks: ['Harmony']),
  CryptoAsset(symbol: 'ANKR', name: 'Ankr', networks: ['ERC20', 'BEP20']),
  CryptoAsset(symbol: 'RSR', name: 'Reserve Rights', networks: ['ERC20']),
  CryptoAsset(symbol: 'STORJ', name: 'Storj', networks: ['ERC20']),
  CryptoAsset(symbol: 'SKL', name: 'SKALE', networks: ['ERC20']),
  CryptoAsset(symbol: 'BAND', name: 'Band Protocol', networks: ['ERC20', 'BEP20']),
  CryptoAsset(symbol: 'REN', name: 'Ren', networks: ['ERC20']),
  CryptoAsset(symbol: 'OCEAN', name: 'Ocean Protocol', networks: ['ERC20', 'Polygon']),
  CryptoAsset(symbol: 'NKN', name: 'NKN', networks: ['ERC20']),
  CryptoAsset(symbol: 'FET', name: 'Fetch.ai', networks: ['ERC20', 'BEP20']),
  CryptoAsset(symbol: 'CTSI', name: 'Cartesi', networks: ['ERC20']),
  CryptoAsset(symbol: 'CELR', name: 'Celer Network', networks: ['ERC20', 'BEP20']),
  CryptoAsset(symbol: 'REEF', name: 'Reef', networks: ['ERC20', 'BEP20']),
  CryptoAsset(symbol: 'DENT', name: 'Dent', networks: ['ERC20']),
  CryptoAsset(symbol: 'SXP', name: 'Solar', networks: ['ERC20', 'BEP20']),
  CryptoAsset(symbol: 'LUNA', name: 'Terra', networks: ['Terra']),
  CryptoAsset(symbol: 'LUNC', name: 'Terra Classic', networks: ['Terra Classic']),
  CryptoAsset(symbol: 'FTM', name: 'Fantom', networks: ['Fantom', 'ERC20', 'BEP20']),
  CryptoAsset(symbol: 'KLAY', name: 'Klaytn', networks: ['Klaytn']),
  CryptoAsset(symbol: 'ROSE', name: 'Oasis Network', networks: ['Oasis']),
  CryptoAsset(symbol: 'INJ', name: 'Injective', networks: ['Injective', 'ERC20']),
  CryptoAsset(symbol: 'OP', name: 'Optimism', networks: ['Optimism']),
  CryptoAsset(symbol: 'SUI', name: 'Sui', networks: ['Sui']),
  CryptoAsset(symbol: 'SEI', name: 'Sei', networks: ['Sei']),
  // 101-200
  CryptoAsset(symbol: 'PEPE', name: 'Pepe', networks: ['ERC20']),
  CryptoAsset(symbol: 'WLD', name: 'Worldcoin', networks: ['Optimism']),
  CryptoAsset(symbol: 'BLUR', name: 'Blur', networks: ['ERC20']),
  CryptoAsset(symbol: 'BONK', name: 'Bonk', networks: ['Solana']),
  CryptoAsset(symbol: 'FLOKI', name: 'Floki', networks: ['ERC20', 'BEP20']),
  CryptoAsset(symbol: 'RNDR', name: 'Render', networks: ['ERC20', 'Solana']),
  CryptoAsset(symbol: 'FXS', name: 'Frax Share', networks: ['ERC20']),
  CryptoAsset(symbol: 'RPL', name: 'Rocket Pool', networks: ['ERC20']),
  CryptoAsset(symbol: 'GMX', name: 'GMX', networks: ['Arbitrum', 'Avalanche']),
  CryptoAsset(symbol: 'LDO', name: 'Lido DAO', networks: ['ERC20']),
  CryptoAsset(symbol: 'CFX', name: 'Conflux', networks: ['Conflux']),
  CryptoAsset(symbol: 'MASK', name: 'Mask Network', networks: ['ERC20']),
  CryptoAsset(symbol: 'AGIX', name: 'SingularityNET', networks: ['ERC20']),
  CryptoAsset(symbol: 'GALA', name: 'Gala', networks: ['ERC20']),
  CryptoAsset(symbol: 'APE', name: 'ApeCoin', networks: ['ERC20']),
  CryptoAsset(symbol: 'DYDX', name: 'dYdX', networks: ['ERC20']),
  CryptoAsset(symbol: 'ENS', name: 'Ethereum Name Service', networks: ['ERC20']),
  CryptoAsset(symbol: 'CVX', name: 'Convex Finance', networks: ['ERC20']),
  CryptoAsset(symbol: 'JASMY', name: 'JasmyCoin', networks: ['ERC20']),
  CryptoAsset(symbol: 'GMT', name: 'STEPN', networks: ['Solana', 'BEP20']),
  CryptoAsset(symbol: 'GAL', name: 'Galxe', networks: ['ERC20', 'BEP20']),
  CryptoAsset(symbol: 'MAGIC', name: 'Magic', networks: ['Arbitrum']),
  CryptoAsset(symbol: 'JOE', name: 'Trader Joe', networks: ['Avalanche']),
  CryptoAsset(symbol: 'SSV', name: 'ssv.network', networks: ['ERC20']),
  CryptoAsset(symbol: 'LQTY', name: 'Liquity', networks: ['ERC20']),
  CryptoAsset(symbol: 'T', name: 'Threshold', networks: ['ERC20']),
  CryptoAsset(symbol: 'HFT', name: 'Hashflow', networks: ['ERC20']),
  CryptoAsset(symbol: 'LEVER', name: 'LeverFi', networks: ['ERC20']),
  CryptoAsset(symbol: 'HOOK', name: 'Hooked Protocol', networks: ['BEP20']),
  CryptoAsset(symbol: 'ID', name: 'SPACE ID', networks: ['BEP20']),
  CryptoAsset(symbol: 'EDU', name: 'Open Campus', networks: ['BEP20']),
  CryptoAsset(symbol: 'ORDI', name: 'ORDI', networks: ['BRC20']),
  CryptoAsset(symbol: 'TIA', name: 'Celestia', networks: ['Celestia']),
  CryptoAsset(symbol: 'MEME', name: 'Memecoin', networks: ['ERC20']),
  CryptoAsset(symbol: 'PYTH', name: 'Pyth Network', networks: ['Solana']),
  CryptoAsset(symbol: 'JTO', name: 'Jito', networks: ['Solana']),
  CryptoAsset(symbol: 'ALT', name: 'AltLayer', networks: ['ERC20']),
  CryptoAsset(symbol: 'PIXEL', name: 'Pixels', networks: ['ERC20']),
  CryptoAsset(symbol: 'STRK', name: 'Starknet', networks: ['Starknet']),
  CryptoAsset(symbol: 'DYM', name: 'Dymension', networks: ['Dymension']),
  CryptoAsset(symbol: 'PORTAL', name: 'Portal', networks: ['Solana']),
  CryptoAsset(symbol: 'AEVO', name: 'Aevo', networks: ['ERC20']),
  CryptoAsset(symbol: 'W', name: 'Wormhole', networks: ['Solana', 'ERC20']),
  CryptoAsset(symbol: 'ENA', name: 'Ethena', networks: ['ERC20']),
  CryptoAsset(symbol: 'ETHFI', name: 'Ether.fi', networks: ['ERC20']),
  CryptoAsset(symbol: 'BOME', name: 'Book of Meme', networks: ['Solana']),
  CryptoAsset(symbol: 'WIF', name: 'dogwifhat', networks: ['Solana']),
  CryptoAsset(symbol: 'TON', name: 'Toncoin', networks: ['TON']),
  CryptoAsset(symbol: 'NOT', name: 'Notcoin', networks: ['TON']),
  CryptoAsset(symbol: 'IO', name: 'io.net', networks: ['Solana']),
  // 201-300
  CryptoAsset(symbol: 'ZK', name: 'zkSync', networks: ['zkSync Era']),
  CryptoAsset(symbol: 'LISTA', name: 'Lista DAO', networks: ['BEP20']),
  CryptoAsset(symbol: 'ZRO', name: 'LayerZero', networks: ['ERC20']),
  CryptoAsset(symbol: 'BANANA', name: 'Banana Gun', networks: ['ERC20']),
  CryptoAsset(symbol: 'RENDER', name: 'Render Token', networks: ['ERC20']),
  CryptoAsset(symbol: 'FTT', name: 'FTX Token', networks: ['ERC20']),
  CryptoAsset(symbol: 'HNT', name: 'Helium', networks: ['Solana']),
  CryptoAsset(symbol: 'MINA', name: 'Mina Protocol', networks: ['Mina']),
  CryptoAsset(symbol: 'ICP', name: 'Internet Computer', networks: ['ICP']),
  CryptoAsset(symbol: 'KAS', name: 'Kaspa', networks: ['Kaspa']),
  CryptoAsset(symbol: 'TAO', name: 'Bittensor', networks: ['Bittensor']),
  CryptoAsset(symbol: 'BEAM', name: 'Beam', networks: ['Avalanche']),
  CryptoAsset(symbol: 'CORE', name: 'Core', networks: ['Core']),
  CryptoAsset(symbol: 'OSMO', name: 'Osmosis', networks: ['Osmosis']),
  CryptoAsset(symbol: 'WOO', name: 'WOO Network', networks: ['ERC20', 'BEP20']),
  CryptoAsset(symbol: 'PENDLE', name: 'Pendle', networks: ['ERC20', 'Arbitrum']),
  CryptoAsset(symbol: 'MANTA', name: 'Manta Network', networks: ['Manta']),
  CryptoAsset(symbol: 'ONDO', name: 'Ondo Finance', networks: ['ERC20']),
  CryptoAsset(symbol: 'JUP', name: 'Jupiter', networks: ['Solana']),
  CryptoAsset(symbol: 'ASTR', name: 'Astar', networks: ['Astar']),
  CryptoAsset(symbol: 'MOVR', name: 'Moonriver', networks: ['Moonriver']),
  CryptoAsset(symbol: 'GLMR', name: 'Moonbeam', networks: ['Moonbeam']),
  CryptoAsset(symbol: 'CANTO', name: 'Canto', networks: ['Canto']),
  CryptoAsset(symbol: 'ACH', name: 'Alchemy Pay', networks: ['ERC20']),
  CryptoAsset(symbol: 'AR', name: 'Arweave', networks: ['Arweave']),
  CryptoAsset(symbol: 'AUDIO', name: 'Audius', networks: ['ERC20', 'Solana']),
  CryptoAsset(symbol: 'BNT', name: 'Bancor', networks: ['ERC20']),
  CryptoAsset(symbol: 'BLZ', name: 'Bluzelle', networks: ['ERC20']),
  CryptoAsset(symbol: 'BICO', name: 'Biconomy', networks: ['ERC20']),
  CryptoAsset(symbol: 'CLV', name: 'Clover Finance', networks: ['ERC20']),
  CryptoAsset(symbol: 'CTXC', name: 'Cortex', networks: ['ERC20']),
  CryptoAsset(symbol: 'DATA', name: 'Streamr', networks: ['ERC20']),
  CryptoAsset(symbol: 'DCR', name: 'Decred', networks: ['Decred']),
  CryptoAsset(symbol: 'DOCK', name: 'Dock', networks: ['ERC20']),
  CryptoAsset(symbol: 'DODO', name: 'DODO', networks: ['ERC20', 'BEP20']),
  CryptoAsset(symbol: 'ERG', name: 'Ergo', networks: ['Ergo']),
  CryptoAsset(symbol: 'EURS', name: 'STASIS EURO', networks: ['ERC20']),
  CryptoAsset(symbol: 'FLM', name: 'Flamingo', networks: ['Neo']),
  CryptoAsset(symbol: 'FORTH', name: 'Ampleforth', networks: ['ERC20']),
  CryptoAsset(symbol: 'FUN', name: 'FUNToken', networks: ['ERC20']),
  CryptoAsset(symbol: 'GAS', name: 'Gas', networks: ['Neo']),
  CryptoAsset(symbol: 'GNO', name: 'Gnosis', networks: ['ERC20']),
  CryptoAsset(symbol: 'HIVE', name: 'Hive', networks: ['Hive']),
  CryptoAsset(symbol: 'ILV', name: 'Illuvium', networks: ['ERC20']),
  CryptoAsset(symbol: 'IOTX', name: 'IoTeX', networks: ['IoTeX', 'ERC20']),
  CryptoAsset(symbol: 'JST', name: 'JUST', networks: ['TRC20']),
  CryptoAsset(symbol: 'KDA', name: 'Kadena', networks: ['Kadena']),
  CryptoAsset(symbol: 'KEEP', name: 'Keep Network', networks: ['ERC20']),
  CryptoAsset(symbol: 'KMD', name: 'Komodo', networks: ['Komodo']),
  CryptoAsset(symbol: 'KNC', name: 'Kyber Network', networks: ['ERC20']),
  // 301-400
  CryptoAsset(symbol: 'LPT', name: 'Livepeer', networks: ['ERC20']),
  CryptoAsset(symbol: 'LSK', name: 'Lisk', networks: ['Lisk']),
  CryptoAsset(symbol: 'MDT', name: 'Measurable Data', networks: ['ERC20']),
  CryptoAsset(symbol: 'MFT', name: 'Hifi Finance', networks: ['ERC20']),
  CryptoAsset(symbol: 'MIR', name: 'Mirror Protocol', networks: ['ERC20', 'Terra']),
  CryptoAsset(symbol: 'MLN', name: 'Enzyme', networks: ['ERC20']),
  CryptoAsset(symbol: 'MTL', name: 'Metal', networks: ['ERC20']),
  CryptoAsset(symbol: 'NANO', name: 'Nano', networks: ['Nano']),
  CryptoAsset(symbol: 'NMR', name: 'Numeraire', networks: ['ERC20']),
  CryptoAsset(symbol: 'NU', name: 'NuCypher', networks: ['ERC20']),
  CryptoAsset(symbol: 'OGN', name: 'Origin Protocol', networks: ['ERC20']),
  CryptoAsset(symbol: 'OXT', name: 'Orchid', networks: ['ERC20']),
  CryptoAsset(symbol: 'PAXG', name: 'PAX Gold', networks: ['ERC20']),
  CryptoAsset(symbol: 'PERP', name: 'Perpetual Protocol', networks: ['ERC20', 'Optimism']),
  CryptoAsset(symbol: 'PHA', name: 'Phala Network', networks: ['ERC20']),
  CryptoAsset(symbol: 'PLA', name: 'PlayDapp', networks: ['ERC20']),
  CryptoAsset(symbol: 'POLS', name: 'Polkastarter', networks: ['ERC20']),
  CryptoAsset(symbol: 'POND', name: 'Marlin', networks: ['ERC20']),
  CryptoAsset(symbol: 'POWR', name: 'Powerledger', networks: ['ERC20']),
  CryptoAsset(symbol: 'QKC', name: 'QuarkChain', networks: ['ERC20']),
  CryptoAsset(symbol: 'RAD', name: 'Radicle', networks: ['ERC20']),
  CryptoAsset(symbol: 'RARE', name: 'SuperRare', networks: ['ERC20']),
  CryptoAsset(symbol: 'RARI', name: 'Rarible', networks: ['ERC20']),
  CryptoAsset(symbol: 'RAY', name: 'Raydium', networks: ['Solana']),
  CryptoAsset(symbol: 'RLC', name: 'iExec RLC', networks: ['ERC20']),
  CryptoAsset(symbol: 'RNDR', name: 'Render Token', networks: ['ERC20']),
  CryptoAsset(symbol: 'ROSE', name: 'Oasis', networks: ['Oasis']),
  CryptoAsset(symbol: 'RSR', name: 'Reserve Rights', networks: ['ERC20']),
  CryptoAsset(symbol: 'SAND', name: 'Sandbox', networks: ['ERC20']),
  CryptoAsset(symbol: 'SCRT', name: 'Secret', networks: ['Secret']),
  CryptoAsset(symbol: 'SFP', name: 'SafePal', networks: ['BEP20']),
  CryptoAsset(symbol: 'SKL', name: 'SKALE', networks: ['ERC20']),
  CryptoAsset(symbol: 'SLP', name: 'Smooth Love Potion', networks: ['ERC20', 'Ronin']),
  CryptoAsset(symbol: 'SNT', name: 'Status', networks: ['ERC20']),
  CryptoAsset(symbol: 'SOL', name: 'Solana', networks: ['Solana']),
  CryptoAsset(symbol: 'SRM', name: 'Serum', networks: ['Solana']),
  CryptoAsset(symbol: 'STEEM', name: 'Steem', networks: ['Steem']),
  CryptoAsset(symbol: 'STMX', name: 'StormX', networks: ['ERC20']),
  CryptoAsset(symbol: 'STRAX', name: 'Stratis', networks: ['Stratis']),
  CryptoAsset(symbol: 'SUPER', name: 'SuperVerse', networks: ['ERC20']),
  CryptoAsset(symbol: 'SURE', name: 'inSure DeFi', networks: ['ERC20']),
  CryptoAsset(symbol: 'SYS', name: 'Syscoin', networks: ['Syscoin']),
  CryptoAsset(symbol: 'TKO', name: 'Tokocrypto', networks: ['BEP20']),
  CryptoAsset(symbol: 'TLM', name: 'Alien Worlds', networks: ['BEP20', 'WAX']),
  CryptoAsset(symbol: 'TOMO', name: 'TomoChain', networks: ['TomoChain']),
  CryptoAsset(symbol: 'TRB', name: 'Tellor', networks: ['ERC20']),
  CryptoAsset(symbol: 'TRIBE', name: 'Tribe', networks: ['ERC20']),
  CryptoAsset(symbol: 'TROY', name: 'TROY', networks: ['BEP20']),
  CryptoAsset(symbol: 'TRU', name: 'TrueFi', networks: ['ERC20']),
  CryptoAsset(symbol: 'TVK', name: 'Virtua', networks: ['ERC20']),
  // 401-500
  CryptoAsset(symbol: 'TWT', name: 'Trust Wallet Token', networks: ['BEP20']),
  CryptoAsset(symbol: 'UMA', name: 'UMA', networks: ['ERC20']),
  CryptoAsset(symbol: 'UNFI', name: 'Unifi Protocol DAO', networks: ['ERC20', 'BEP20']),
  CryptoAsset(symbol: 'UTK', name: 'Utrust', networks: ['ERC20']),
  CryptoAsset(symbol: 'VGX', name: 'Voyager Token', networks: ['ERC20']),
  CryptoAsset(symbol: 'VIDT', name: 'VIDT DAO', networks: ['ERC20']),
  CryptoAsset(symbol: 'VITE', name: 'Vite', networks: ['Vite']),
  CryptoAsset(symbol: 'VTHO', name: 'VeThor', networks: ['VeChain']),
  CryptoAsset(symbol: 'WAN', name: 'Wanchain', networks: ['Wanchain']),
  CryptoAsset(symbol: 'WAXP', name: 'WAX', networks: ['WAX']),
  CryptoAsset(symbol: 'WIN', name: 'WINkLink', networks: ['TRC20']),
  CryptoAsset(symbol: 'WING', name: 'Wing Finance', networks: ['BEP20']),
  CryptoAsset(symbol: 'WRX', name: 'WazirX', networks: ['ERC20', 'BEP20']),
  CryptoAsset(symbol: 'XEC', name: 'eCash', networks: ['eCash']),
  CryptoAsset(symbol: 'XEM', name: 'NEM', networks: ['NEM']),
  CryptoAsset(symbol: 'XNO', name: 'Nano', networks: ['Nano']),
  CryptoAsset(symbol: 'XVG', name: 'Verge', networks: ['Verge']),
  CryptoAsset(symbol: 'XVS', name: 'Venus', networks: ['BEP20']),
  CryptoAsset(symbol: 'YGG', name: 'Yield Guild Games', networks: ['ERC20']),
  CryptoAsset(symbol: 'ZEN', name: 'Horizen', networks: ['Horizen']),
  CryptoAsset(symbol: 'AERGO', name: 'Aergo', networks: ['ERC20']),
  CryptoAsset(symbol: 'AGLD', name: 'Adventure Gold', networks: ['ERC20']),
  CryptoAsset(symbol: 'ALCX', name: 'Alchemix', networks: ['ERC20']),
  CryptoAsset(symbol: 'ALICE', name: 'My Neighbor Alice', networks: ['ERC20']),
  CryptoAsset(symbol: 'ALPHA', name: 'Alpha Venture DAO', networks: ['ERC20', 'BEP20']),
  CryptoAsset(symbol: 'AMP', name: 'Amp', networks: ['ERC20']),
  CryptoAsset(symbol: 'ANC', name: 'Anchor Protocol', networks: ['Terra']),
  CryptoAsset(symbol: 'ARDR', name: 'Ardor', networks: ['Ardor']),
  CryptoAsset(symbol: 'ARPA', name: 'ARPA', networks: ['ERC20']),
  CryptoAsset(symbol: 'ASTR', name: 'Astar', networks: ['Astar', 'ERC20']),
  CryptoAsset(symbol: 'ATA', name: 'Automata', networks: ['ERC20']),
  CryptoAsset(symbol: 'AVA', name: 'Travala.com', networks: ['BEP20']),
  CryptoAsset(symbol: 'BADGER', name: 'Badger DAO', networks: ['ERC20']),
  CryptoAsset(symbol: 'BAKE', name: 'BakeryToken', networks: ['BEP20']),
  CryptoAsset(symbol: 'BAL', name: 'Balancer', networks: ['ERC20']),
  CryptoAsset(symbol: 'BETA', name: 'Beta Finance', networks: ['ERC20']),
  CryptoAsset(symbol: 'BIFI', name: 'Beefy Finance', networks: ['BEP20']),
  CryptoAsset(symbol: 'BIT', name: 'BitDAO', networks: ['ERC20']),
  CryptoAsset(symbol: 'BNX', name: 'BinaryX', networks: ['BEP20']),
  CryptoAsset(symbol: 'BOND', name: 'BarnBridge', networks: ['ERC20']),
  CryptoAsset(symbol: 'BOSON', name: 'Boson Protocol', networks: ['ERC20']),
  CryptoAsset(symbol: 'BRD', name: 'Bread', networks: ['ERC20']),
  CryptoAsset(symbol: 'BTG', name: 'Bitcoin Gold', networks: ['Bitcoin Gold']),
  CryptoAsset(symbol: 'BTS', name: 'BitShares', networks: ['BitShares']),
  CryptoAsset(symbol: 'BURGER', name: 'BurgerSwap', networks: ['BEP20']),
  CryptoAsset(symbol: 'BUSD', name: 'Binance USD', networks: ['BEP20', 'ERC20']),
  CryptoAsset(symbol: 'C98', name: 'Coin98', networks: ['ERC20', 'BEP20']),
  CryptoAsset(symbol: 'CFG', name: 'Centrifuge', networks: ['ERC20']),
  CryptoAsset(symbol: 'CHESS', name: 'Tranchess', networks: ['BEP20']),
  CryptoAsset(symbol: 'CKB', name: 'Nervos Network', networks: ['Nervos']),
  // 501-550 - Additional popular tokens
  CryptoAsset(symbol: 'COCOS', name: 'COCOS BCX', networks: ['ERC20']),
  CryptoAsset(symbol: 'COTI', name: 'COTI', networks: ['ERC20']),
  CryptoAsset(symbol: 'CREAM', name: 'Cream Finance', networks: ['ERC20']),
  CryptoAsset(symbol: 'CVC', name: 'Civic', networks: ['ERC20']),
  CryptoAsset(symbol: 'DAO', name: 'DAO Maker', networks: ['ERC20']),
  CryptoAsset(symbol: 'DEGO', name: 'Dego Finance', networks: ['ERC20']),
  CryptoAsset(symbol: 'DF', name: 'dForce', networks: ['ERC20']),
  CryptoAsset(symbol: 'DIA', name: 'DIA', networks: ['ERC20']),
  CryptoAsset(symbol: 'DPI', name: 'DeFi Pulse Index', networks: ['ERC20']),
  CryptoAsset(symbol: 'DUSK', name: 'Dusk Network', networks: ['ERC20']),
  CryptoAsset(symbol: 'EASY', name: 'EasyFi', networks: ['Polygon']),
  CryptoAsset(symbol: 'EFI', name: 'Efinity', networks: ['ERC20']),
  CryptoAsset(symbol: 'ELF', name: 'aelf', networks: ['ERC20']),
  CryptoAsset(symbol: 'ELON', name: 'Dogelon Mars', networks: ['ERC20']),
  CryptoAsset(symbol: 'EPX', name: 'Ellipsis', networks: ['BEP20']),
  CryptoAsset(symbol: 'ERN', name: 'Ethernity', networks: ['ERC20']),
  CryptoAsset(symbol: 'FARM', name: 'Harvest Finance', networks: ['ERC20']),
  CryptoAsset(symbol: 'FIDA', name: 'Bonfida', networks: ['Solana']),
  CryptoAsset(symbol: 'FIRO', name: 'Firo', networks: ['Firo']),
  CryptoAsset(symbol: 'FLUX', name: 'Flux', networks: ['Flux']),
  CryptoAsset(symbol: 'FNSA', name: 'Finschia', networks: ['Finschia']),
  CryptoAsset(symbol: 'FOR', name: 'ForTube', networks: ['ERC20']),
  CryptoAsset(symbol: 'FRAX', name: 'Frax', networks: ['ERC20']),
  CryptoAsset(symbol: 'FTN', name: 'Fasttoken', networks: ['ERC20']),
  CryptoAsset(symbol: 'GFI', name: 'Goldfinch', networks: ['ERC20']),
  CryptoAsset(symbol: 'GHST', name: 'Aavegotchi', networks: ['Polygon']),
  CryptoAsset(symbol: 'GLM', name: 'Golem', networks: ['ERC20']),
  CryptoAsset(symbol: 'GODS', name: 'Gods Unchained', networks: ['ERC20']),
  CryptoAsset(symbol: 'GRIN', name: 'Grin', networks: ['Grin']),
  CryptoAsset(symbol: 'GTC', name: 'Gitcoin', networks: ['ERC20']),
  CryptoAsset(symbol: 'HARD', name: 'Kava Lend', networks: ['Kava']),
  CryptoAsset(symbol: 'HIGH', name: 'Highstreet', networks: ['ERC20', 'BEP20']),
  CryptoAsset(symbol: 'IDEX', name: 'IDEX', networks: ['ERC20']),
  CryptoAsset(symbol: 'IOST', name: 'IOST', networks: ['IOST']),
  CryptoAsset(symbol: 'IRIS', name: 'IRISnet', networks: ['IRIS']),
  CryptoAsset(symbol: 'JASMY', name: 'JasmyCoin', networks: ['ERC20']),
  CryptoAsset(symbol: 'JONES', name: 'Jones DAO', networks: ['Arbitrum']),
  CryptoAsset(symbol: 'KEY', name: 'SelfKey', networks: ['ERC20']),
  CryptoAsset(symbol: 'KILT', name: 'KILT Protocol', networks: ['KILT']),
  CryptoAsset(symbol: 'KP3R', name: 'Keep3rV1', networks: ['ERC20']),
  CryptoAsset(symbol: 'LAMB', name: 'Lambda', networks: ['ERC20']),
  CryptoAsset(symbol: 'LAT', name: 'PlatON', networks: ['PlatON']),
  CryptoAsset(symbol: 'LAZIO', name: 'Lazio Fan Token', networks: ['BEP20']),
  CryptoAsset(symbol: 'LCX', name: 'LCX', networks: ['ERC20']),
  CryptoAsset(symbol: 'LINA', name: 'Linear', networks: ['BEP20']),
  CryptoAsset(symbol: 'LIT', name: 'Litentry', networks: ['ERC20']),
  CryptoAsset(symbol: 'LOKA', name: 'League of Kingdoms', networks: ['ERC20']),
  CryptoAsset(symbol: 'LOOM', name: 'Loom Network', networks: ['ERC20']),
  CryptoAsset(symbol: 'LTO', name: 'LTO Network', networks: ['ERC20']),
  CryptoAsset(symbol: 'LUNA2', name: 'Terra 2.0', networks: ['Terra 2.0']),
];

class DepositScreen extends StatefulWidget {
  final String? initialSymbol;
  final String? initialName;

  const DepositScreen({
    super.key,
    this.initialSymbol,
    this.initialName,
  });

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  CryptoAsset? _selectedAsset;
  String? _selectedNetwork;
  bool _isLoading = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Real deposit address from API
  String _depositAddress = '';
  String? _depositMemo;
  String? _depositError;

  @override
  void initState() {
    super.initState();
    // Set initial asset if provided
    if (widget.initialSymbol != null) {
      _selectedAsset = allCryptoAssets.firstWhere(
        (asset) => asset.symbol.toUpperCase() == widget.initialSymbol!.toUpperCase(),
        orElse: () => allCryptoAssets.first,
      );
      if (_selectedAsset!.networks.isNotEmpty) {
        _selectedNetwork = _selectedAsset!.networks.first;
        _fetchDepositAddress();
      }
    }
  }

  Future<void> _fetchDepositAddress() async {
    if (_selectedAsset == null || _selectedNetwork == null) return;

    setState(() {
      _isLoading = true;
      _depositError = null;
      _depositAddress = '';
      _depositMemo = null;
    });

    try {
      final address = await walletService.getDepositAddress(
        _selectedAsset!.symbol,
        network: _selectedNetwork,
      );

      if (mounted) {
        setState(() {
          _depositAddress = address.address;
          _depositMemo = address.memo;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _depositError = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  List<CryptoAsset> get _filteredAssets {
    if (_searchQuery.isEmpty) return allCryptoAssets;
    final query = _searchQuery.toLowerCase();
    return allCryptoAssets.where((asset) =>
      asset.symbol.toLowerCase().contains(query) ||
      asset.name.toLowerCase().contains(query)
    ).toList();
  }


  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _selectAsset(CryptoAsset asset) {
    setState(() {
      _selectedAsset = asset;
      _selectedNetwork = null;
    });
  }

  void _selectNetwork(String network) {
    setState(() {
      _selectedNetwork = network;
    });
    _fetchDepositAddress();
  }

  void _copyAddress() {
    if (_depositAddress.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _depositAddress));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Address copied to clipboard'),
        backgroundColor: AppColors.tradingBuy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copyMemo() {
    if (_depositMemo == null || _depositMemo!.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _depositMemo!));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Memo/Tag copied to clipboard'),
        backgroundColor: AppColors.tradingBuy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearSelection() {
    setState(() {
      _selectedAsset = null;
      _selectedNetwork = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundPrimary : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () {
            if (_selectedNetwork != null) {
              setState(() => _selectedNetwork = null);
            } else if (_selectedAsset != null) {
              setState(() => _selectedAsset = null);
            } else {
              context.pop();
            }
          },
        ),
        title: Text(
          _selectedAsset != null
              ? 'Deposit ${_selectedAsset!.symbol}'
              : 'Deposit',
          style: AppTypography.headlineSmall.copyWith(
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_selectedAsset != null)
            IconButton(
              icon: Icon(Icons.close, color: textColor),
              onPressed: _clearSelection,
            ),
        ],
      ),
      body: SafeArea(
        child: _selectedAsset == null
            ? _buildAssetSelection()
            : _selectedNetwork == null
                ? _buildNetworkSelection()
                : _buildDepositAddress(),
      ),
    );
  }

  Widget _buildAssetSelection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final mutedColor = isDark ? AppColors.textMuted : const Color(0xFF555555);
    final cardBg = isDark ? AppColors.backgroundCard : const Color(0xFFF8F8F8);
    final borderColor = isDark ? AppColors.glassBorder : Colors.black.withOpacity(0.1);

    return Column(
      children: [
        // Search Box
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Search ${allCryptoAssets.length}+ coins...',
                hintStyle: TextStyle(color: mutedColor),
                prefixIcon: Icon(Icons.search, color: mutedColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: mutedColor),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),

        // Results count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Text(
                '${_filteredAssets.length} assets available',
                style: AppTypography.caption.copyWith(color: mutedColor),
              ),
              const Spacer(),
              Icon(Icons.info_outline, size: 14, color: mutedColor),
              const SizedBox(width: 4),
              Text(
                'Live prices from Binance',
                style: AppTypography.caption.copyWith(color: mutedColor, fontSize: 10),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Asset List
        Expanded(
          child: _filteredAssets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 48, color: mutedColor),
                      const SizedBox(height: 16),
                      Text(
                        'No assets found for "$_searchQuery"',
                        style: AppTypography.bodyMedium.copyWith(color: mutedColor),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: _filteredAssets.length,
                  itemBuilder: (context, index) {
                    final asset = _filteredAssets[index];
                    return _buildAssetItem(asset);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAssetItem(CryptoAsset asset) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final mutedColor = isDark ? AppColors.textMuted : const Color(0xFF555555);
    final cardBg = isDark ? AppColors.backgroundCard : Colors.white;
    final borderColor = isDark ? AppColors.glassBorder : Colors.black.withOpacity(0.1);

    return GestureDetector(
      onTap: () => _selectAsset(asset),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            CryptoIcon(symbol: asset.symbol, size: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.symbol,
                    style: AppTypography.titleMedium.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    asset.name,
                    style: AppTypography.bodySmall.copyWith(
                      color: mutedColor,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${asset.networks.length} networks',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: mutedColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkSelection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final mutedColor = isDark ? AppColors.textMuted : const Color(0xFF555555);
    final borderColor = isDark ? AppColors.glassBorder : Colors.black.withOpacity(0.1);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected Asset Card
          GlassCard(
            child: Row(
              children: [
                CryptoIcon(symbol: _selectedAsset!.symbol, size: 48),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedAsset!.symbol,
                        style: AppTypography.titleLarge.copyWith(
                          color: textColor,
                        ),
                      ),
                      Text(
                        _selectedAsset!.name,
                        style: AppTypography.bodySmall.copyWith(
                          color: mutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.check_circle, color: AppColors.tradingBuy),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Network Selection
          Text(
            'Select Network',
            style: AppTypography.titleMedium.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose the network matching your withdrawal',
            style: AppTypography.bodySmall.copyWith(color: mutedColor),
          ),
          const SizedBox(height: AppSpacing.md),

          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: _selectedAsset!.networks.asMap().entries.map((entry) {
                final index = entry.key;
                final network = entry.value;
                return GestureDetector(
                  onTap: () => _selectNetwork(network),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      border: index < _selectedAsset!.networks.length - 1
                          ? Border(bottom: BorderSide(color: borderColor))
                          : null,
                    ),
                    child: Row(
                      children: [
                        NetworkIcon(network: network, size: 40),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                network,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Est. arrival: ~${_getEstimatedTime(network)}',
                                style: AppTypography.caption.copyWith(
                                  color: mutedColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Fee: ${_getNetworkFee(network)}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.tradingBuy,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right, color: mutedColor, size: 20),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Warning
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ensure the network matches your source. Wrong network = lost funds.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getEstimatedTime(String network) {
    switch (network) {
      case 'Lightning':
        return 'Instant';
      case 'Solana':
      case 'TON':
        return '1 min';
      case 'TRC20':
      case 'BEP20':
        return '2-3 min';
      case 'Polygon':
      case 'Arbitrum':
      case 'Optimism':
      case 'Base':
        return '5 min';
      case 'ERC20':
        return '10-15 min';
      case 'Bitcoin':
        return '30-60 min';
      default:
        return '5-10 min';
    }
  }

  String _getNetworkFee(String network) {
    switch (network) {
      case 'Lightning':
        return 'Free';
      case 'Solana':
      case 'TON':
        return '~\$0.01';
      case 'TRC20':
        return '~\$1';
      case 'BEP20':
        return '~\$0.10';
      case 'Polygon':
        return '~\$0.02';
      case 'Arbitrum':
      case 'Optimism':
        return '~\$0.20';
      case 'ERC20':
        return '~\$5-15';
      case 'Bitcoin':
        return '~\$2-10';
      default:
        return '~\$0.50';
    }
  }

  Widget _buildDepositAddress() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final mutedColor = isDark ? AppColors.textMuted : const Color(0xFF555555);
    final bgColor = isDark ? AppColors.backgroundPrimary : const Color(0xFFF8F8F8);
    final borderColor = isDark ? AppColors.glassBorder : Colors.black.withOpacity(0.1);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error state if API failed
    if (_depositError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.tradingSell),
              const SizedBox(height: 16),
              Text(
                'Failed to get deposit address',
                style: AppTypography.titleMedium.copyWith(color: textColor),
              ),
              const SizedBox(height: 8),
              Text(
                _depositError!,
                style: AppTypography.bodySmall.copyWith(color: mutedColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchDepositAddress,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show empty state if no address returned
    if (_depositAddress.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_balance_wallet_outlined, size: 64, color: mutedColor),
              const SizedBox(height: 16),
              Text(
                'No deposit address available',
                style: AppTypography.titleMedium.copyWith(color: textColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Please contact support if this issue persists',
                style: AppTypography.bodySmall.copyWith(color: mutedColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchDepositAddress,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          // Asset and Network Info
          GlassCard(
            child: Row(
              children: [
                CryptoIcon(symbol: _selectedAsset!.symbol, size: 48),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_selectedAsset!.symbol} on $_selectedNetwork',
                        style: AppTypography.titleMedium.copyWith(
                          color: textColor,
                        ),
                      ),
                      Text(
                        _selectedAsset!.name,
                        style: AppTypography.bodySmall.copyWith(
                          color: mutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // QR Code - Encodes the actual deposit address
          GlassCard(
            variant: GlassVariant.prominent,
            child: Column(
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: QrImageView(
                    data: _depositAddress,
                    version: QrVersions.auto,
                    size: 180,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.black,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Warning
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: AppColors.warning, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Only send ${_selectedAsset!.symbol} via $_selectedNetwork',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Address
                Text(
                  'Deposit Address',
                  style: AppTypography.caption.copyWith(color: mutedColor),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _depositAddress,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _copyAddress,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.copy, color: AppColors.primary, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                // Memo/Tag (if required for this coin)
                if (_depositMemo != null && _depositMemo!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.tradingSell.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.tradingSell.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: AppColors.tradingSell, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'MEMO/TAG REQUIRED - Include it or funds will be lost!',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.tradingSell,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Memo/Tag',
                    style: AppTypography.caption.copyWith(color: mutedColor),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _depositMemo!,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _copyMemo,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.copy, color: AppColors.primary, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),

                // Copy Button
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'Copy Address',
                    icon: Icons.copy,
                    onPressed: _copyAddress,
                  ),
                ),
                if (_depositMemo != null && _depositMemo!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: 'Copy Memo/Tag',
                      icon: Icons.copy,
                      variant: AppButtonVariant.outline,
                      onPressed: _copyMemo,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Info
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deposit Information',
                  style: AppTypography.titleSmall.copyWith(
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Network', _selectedNetwork!),
                _buildInfoRow('Est. Arrival', _getEstimatedTime(_selectedNetwork!)),
                _buildInfoRow('Min. Deposit', '0.0001 ${_selectedAsset!.symbol}'),
                _buildInfoRow('Confirmations', '3'),
              ],
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final mutedColor = isDark ? AppColors.textMuted : const Color(0xFF555555);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(color: mutedColor),
          ),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
