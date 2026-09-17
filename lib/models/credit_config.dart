/// Configuration for Twinora Credit Engine & StoreKit / Google Play Billing
class CreditConfig {
  // ── Subscription Product IDs ────────────────────────────────────────────────
  static const String subStarter = 'twinora_starter_27';
  static const String subPlus = 'twinora_plus_47.00';
  static const String subPlusAlt = 'twinora_plus_47';
  static const String subPro = 'twinora_pro_97';
  static const String subBusiness = 'twinora_business_197';

  // ── Consumable Top-Up Product IDs ───────────────────────────────────────────
  static const String topUp250 = 'twinora_credits_250';
  static const String topUp500 = 'twinora_credits_500';
  static const String topUp1000 = 'twinora_credits_1000';
  static const String topUp2000 = 'twinora_credits_2000';
  static const String topUp4000 = 'twinora_credits_4000';

  /// All registered store product IDs
  static const Set<String> allProductIds = {
    subStarter,
    subPlus,
    subPlusAlt,
    subPro,
    subBusiness,
    topUp250,
    topUp500,
    topUp1000,
    topUp2000,
    topUp4000,
  };

  /// Subscription Credits Mapping
  static const Map<String, int> subscriptionCreditsMap = {
    subStarter: 600,
    subPlus: 1200,
    subPlusAlt: 1200,
    subPro: 3000,
    subBusiness: 6000,
  };

  /// Top-Up Credits Mapping
  static const Map<String, int> topUpCreditsMap = {
    topUp250: 250,
    topUp500: 500,
    topUp1000: 1000,
    topUp2000: 2000,
    topUp4000: 4000,
  };

  // ── Feature Credit Pricing Matrix (Customer-Facing) ─────────────────────────
  static const int geminiImageCredits = 2;
  static const int heygenDirectTalkPerSec = 4;
  static const int syncProPerSec = 9;
  static const int standardLipSyncPerSec = 5;

  /// Kling 3.0 Matrix: credits per (durationSeconds, resolution)
  static int getKlingCredits(int durationSec, String resolution) {
    final is4k = resolution.toUpperCase() == '4K';
    if (durationSec <= 5) return is4k ? 30 : 10;
    if (durationSec <= 10) return is4k ? 60 : 20;
    return is4k ? 90 : 30; // 15s or higher
  }

  /// Natural Talk (Movement + Lip Sync)
  static int getNaturalTalkCredits({
    required String movementModel,
    required int durationSec,
    String lipSyncEngine = 'everypixel',
    String resolution = '1080p',
    bool promoActive = true,
  }) {
    final lipSyncRate = lipSyncEngine == 'synclabs' ? syncProPerSec : standardLipSyncPerSec;
    final syncCredits = durationSec * lipSyncRate;
    if (movementModel.toLowerCase().contains('seedance')) {
      final seedanceCredits = promoActive ? 133 : 169;
      return seedanceCredits + syncCredits;
    } else {
      // Kling movement
      final klingCredits = getKlingCredits(durationSec, resolution);
      return klingCredits + syncCredits;
    }
  }

  // ── Backend Provider Cost Logging (USD) ─────────────────────────────────────
  static double estimateGeminiCostUsd(String model, String resolution) {
    if (resolution == '4K') return 0.24;
    if (model.contains('Flash')) return 0.067;
    return 0.134; // Gemini 3 Pro
  }

  static double estimateHeyGenCostUsd(int durationSec) {
    return (durationSec / 60.0) * 3.00; // Avatar IV @ $3/min ($0.25 for 5s)
  }

  static double estimateSyncCostUsd(int durationSec) {
    return durationSec * 0.08325; // Creator tier
  }
}
