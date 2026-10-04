import 'package:flutter_test/flutter_test.dart';
import 'package:ai_video_image_generation_app/models/credit_config.dart';

void main() {
  group('IAP Product Resolution & Credit Mapping Tests', () {
    // Helper function mirroring the resolution logic in IapService._grantPurchaseCredits
    ({int credits, String? plan, bool isSub}) resolveProduct(String rawProductId) {
      final productId = rawProductId.split(':').first.trim().toLowerCase();
      int creditsToAdd = 0;
      String? subscriptionPlan;
      bool isSubscription = false;

      if (CreditConfig.subscriptionCreditsMap.containsKey(productId)) {
        creditsToAdd = CreditConfig.subscriptionCreditsMap[productId]!;
        subscriptionPlan = productId.replaceAll('twinora_', '');
        isSubscription = true;
      } else if (productId == CreditConfig.subPlusAlt || productId == 'twinora_plus_47') {
        creditsToAdd = 1200;
        subscriptionPlan = 'plus';
        isSubscription = true;
      } else if (CreditConfig.topUpCreditsMap.containsKey(productId)) {
        creditsToAdd = CreditConfig.topUpCreditsMap[productId]!;
        subscriptionPlan = null;
        isSubscription = false;
      } else {
        if (productId.contains('starter')) {
          creditsToAdd = 600;
          subscriptionPlan = 'starter';
          isSubscription = true;
        } else if (productId.contains('plus')) {
          creditsToAdd = 1200;
          subscriptionPlan = 'plus';
          isSubscription = true;
        } else if (productId.contains('pro')) {
          creditsToAdd = 3000;
          subscriptionPlan = 'pro';
          isSubscription = true;
        } else if (productId.contains('business')) {
          creditsToAdd = 6000;
          subscriptionPlan = 'business';
          isSubscription = true;
        } else if (productId.contains('4000')) {
          creditsToAdd = 4000;
        } else if (productId.contains('2000')) {
          creditsToAdd = 2000;
        } else if (productId.contains('1000')) {
          creditsToAdd = 1000;
        } else if (productId.contains('500')) {
          creditsToAdd = 500;
        } else if (productId.contains('250')) {
          creditsToAdd = 250;
        }
      }

      return (credits: creditsToAdd, plan: subscriptionPlan, isSub: isSubscription);
    }

    test('Resolves exact subscription product IDs correctly', () {
      final starter = resolveProduct('twinora_starter_27');
      expect(starter.credits, equals(600));
      expect(starter.isSub, isTrue);

      final plus = resolveProduct('twinora_plus_47.00');
      expect(plus.credits, equals(1200));
      expect(plus.isSub, isTrue);

      final pro = resolveProduct('twinora_pro_97');
      expect(pro.credits, equals(3000));
      expect(pro.isSub, isTrue);

      final business = resolveProduct('twinora_business_197');
      expect(business.credits, equals(6000));
      expect(business.isSub, isTrue);
    });

    test('Resolves Google Play base plan and offer variations correctly', () {
      final businessGPlay = resolveProduct('twinora_business_197:monthly-base-plan');
      expect(businessGPlay.credits, equals(6000));
      expect(businessGPlay.isSub, isTrue);

      final plusGPlay = resolveProduct('twinora_plus_47:p1m');
      expect(plusGPlay.credits, equals(1200));
      expect(plusGPlay.isSub, isTrue);

      final starterGPlay = resolveProduct('twinora_starter_27:default-plan');
      expect(starterGPlay.credits, equals(600));
      expect(starterGPlay.isSub, isTrue);
    });

    test('Resolves top-up credit packs correctly', () {
      expect(resolveProduct('twinora_credits_250').credits, equals(250));
      expect(resolveProduct('twinora_credits_500').credits, equals(500));
      expect(resolveProduct('twinora_credits_1000').credits, equals(1000));
      expect(resolveProduct('twinora_credits_2000').credits, equals(2000));
      expect(resolveProduct('twinora_credits_4000').credits, equals(4000));
    });

    test('Handles fuzzy fallback when store ID has unexpected prefix or suffix', () {
      final fuzzyBusiness = resolveProduct('com.twinora.app.business');
      expect(fuzzyBusiness.credits, equals(6000));

      final fuzzyPlus = resolveProduct('subscription_plus_tier');
      expect(fuzzyPlus.credits, equals(1200));

      final fuzzyStarter = resolveProduct('starter_promo_27');
      expect(fuzzyStarter.credits, equals(600));
    });
  });
}
