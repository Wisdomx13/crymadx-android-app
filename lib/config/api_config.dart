/// CrymadX API Configuration - Production Backend

class ApiConfig {
  ApiConfig._();

  /// Development API base URL
  static const String devBaseUrl = 'https://backend.crymadx.io/api';

  /// Production API base URL
  static const String prodBaseUrl = 'https://backend.crymadx.io/api';

  /// Current environment (set to true for production)
  static const bool isProduction = true;

  /// Get current base URL
  static String get baseUrl => isProduction ? prodBaseUrl : devBaseUrl;

  /// Request timeout in milliseconds
  static const int timeout = 30000;

  /// Token storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';

  // ============================================
  // AUTHENTICATION ENDPOINTS
  // ============================================
  static const String auth = '/auth';
  static const String login = '$auth/login';
  static const String register = '$auth/register';
  static const String logout = '$auth/logout';
  static const String refreshToken = '$auth/refresh';
  static const String forgotPassword = '$auth/forgot-password';
  static const String resetPassword = '$auth/reset-password';
  static const String verifyEmail = '$auth/verify-email';
  static const String resendVerification = '$auth/resend-verification';
  static const String complete2FA = '$auth/complete-2fa';

  // ============================================
  // 2FA ENDPOINTS
  // ============================================
  static const String twoFA = '/2fa';
  static const String twoFASetup = '$twoFA/setup';
  static const String twoFAEnable = '$twoFA/enable';
  static const String twoFAVerify = '$twoFA/verify';
  static const String twoFAVerifyLogin = '$twoFA/verify-login';
  static const String twoFADisable = '$twoFA/disable';
  static const String twoFABackupCodes = '$twoFA/backup-codes';

  // ============================================
  // USER PROFILE ENDPOINTS
  // ============================================
  static const String user = '/user';
  static const String userProfile = '$user/profile';
  static const String userWallets = '$user/wallets';
  static const String userWalletsInitialize = '$user/wallets/initialize';
  static const String userWalletsStatus = '$user/wallets/status';
  static const String userAntiPhishing = '$user/anti-phishing';
  static const String userLoginHistory = '$user/login-history';

  // ============================================
  // KYC ENDPOINTS
  // ============================================
  static const String kyc = '/kyc';
  static const String kycStatus = '$kyc/status';
  static const String kycSubmit = '$kyc/submit';
  static const String kycRetry = '$kyc/retry';

  // ============================================
  // BALANCE/WALLET ENDPOINTS
  // ============================================
  static const String balance = '/balance';
  static const String balances = '$balance/balances';
  static const String balancesSummary = '$balance/balances/summary';
  static const String balanceTransfer = '$balance/transfer';
  static const String balanceTransfers = '$balance/transfers';

  // ============================================
  // MARKET DATA ENDPOINTS (Binance Proxy)
  // ============================================
  static const String binance = '/binance';
  static const String binanceTicker = '$binance/ticker/24hr';
  static const String binanceExchangeInfo = '$binance/exchangeInfo';
  static const String binanceDepth = '$binance/depth';
  static const String binanceTrades = '$binance/trades';

  // ============================================
  // SPOT TRADING ENDPOINTS
  // ============================================
  static const String spot = '/spot';
  static const String spotPairs = '$spot/pairs';
  static const String spotQuote = '$spot/quote';
  static const String spotOrder = '$spot/order';
  static const String spotOrders = '$spot/orders';

  // ============================================
  // SWAP/CONVERT ENDPOINTS
  // ============================================
  static const String swap = '/swap';
  static const String swapPairs = '$swap/pairs';
  static const String swapEstimate = '$swap/estimate';
  static const String swapCreate = '$swap/create';
  static const String swapStatus = '$swap/status';

  // ============================================
  // P2P ENDPOINTS
  // ============================================
  static const String p2p = '/p2p';
  static const String p2pOrders = '$p2p/orders';
  static const String p2pTrades = '$p2p/trades';

  // ============================================
  // SAVINGS/EARN ENDPOINTS
  // ============================================
  static const String savings = '/savings';
  static const String savingsProducts = '$savings/products';
  static const String savingsDeposit = '$savings/deposit';
  static const String savingsDeposits = '$savings/deposits';
  static const String savingsWithdraw = '$savings/withdraw';

  // ============================================
  // STAKING ENDPOINTS
  // ============================================
  static const String staking = '/staking';
  static const String stakingProducts = '$staking/products';
  static const String stakingStake = '$staking/stake';
  static const String stakingPositions = '$staking/positions';
  static const String stakingUnstake = '$staking/unstake';

  // ============================================
  // NFT ENDPOINTS
  // ============================================
  static const String nft = '/nft';
  static const String nftMarketplace = '$nft/marketplace';
  static const String nftOwned = '$nft/owned';
  static const String nftDetails = '$nft/details';
  static const String nftCollection = '$nft/collection';
  static const String nftFloor = '$nft/floor';
  static const String nftList = '$nft/list';
  static const String nftPlatformListings = '$nft/platform/listings';
  static const String nftPurchase = '$nft/purchase';

  // ============================================
  // REFERRAL ENDPOINTS
  // ============================================
  static const String referral = '/referral';
  static const String referralInfo = '$referral/info';
  static const String referralCode = '$referral/code';
  static const String referralStats = '$referral/stats';
  static const String referralApply = '$referral/apply';

  // ============================================
  // REWARDS ENDPOINTS
  // ============================================
  static const String rewards = '/rewards';
  static const String rewardsSummary = '$rewards/summary';
  static const String rewardsTasks = '$rewards/tasks';
  static const String rewardsTiers = '$rewards/tiers';
  static const String rewardsHistory = '$rewards/history';

  // ============================================
  // SUPPORT ENDPOINTS
  // ============================================
  static const String support = '/support';
  static const String supportTickets = '$support/tickets';
}
