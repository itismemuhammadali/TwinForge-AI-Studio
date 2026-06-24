import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class TrendingTemplate {
  final String trendName;
  final List<String> searchTerms;
  final String visualContext;
  final String contentType;
  final String priority; // HIGH, MEDIUM, LOW
  final String popularityLevel; // HIGH, MEDIUM

  TrendingTemplate({
    required this.trendName,
    required this.searchTerms,
    required this.visualContext,
    required this.contentType,
    required this.priority,
    required this.popularityLevel,
  });

  factory TrendingTemplate.fromJson(Map<String, dynamic> json) {
    return TrendingTemplate(
      trendName: json['trendName'] ?? '',
      searchTerms: List<String>.from(json['searchTerms'] ?? []),
      visualContext: json['visualContext'] ?? '',
      contentType: json['contentType'] ?? '',
      priority: json['priority'] ?? 'MEDIUM',
      popularityLevel: json['popularityLevel'] ?? 'MEDIUM',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trendName': trendName,
      'searchTerms': searchTerms,
      'visualContext': visualContext,
      'contentType': contentType,
      'priority': priority,
      'popularityLevel': popularityLevel,
    };
  }
}

class TrendingService {
  static String apiKey = '';
  static final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  static List<TrendingTemplate>? _cachedTrends;
  static DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(hours: 24);

  static void debugLog(String message) {
    debugPrint('[TrendingService] $message');
  }

  /// Initialize TrendingService with API key from Firebase Remote Config
  static Future<void> initialize() async {
    debugLog('🔍 Initializing Trending Service...');
    try {
      await _remoteConfig.setDefaults({
        'gemini_api_key': '',
      });

      await _remoteConfig.fetchAndActivate().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugLog('⚠️ Remote Config fetch timed out');
          return false;
        },
      );

      apiKey = _remoteConfig.getString('gemini_api_key');

      if (apiKey.isEmpty) {
        throw Exception('Gemini API key not configured');
      }

      debugLog('✅ Trending Service initialized successfully');
    } catch (e) {
      debugLog('❌ Error initializing Trending Service: $e');
      rethrow;
    }
  }

  /// Fetch trending templates from Gemini with caching
  static Future<List<TrendingTemplate>> getTrendingTemplates() async {
    // Check cache first
    if (_cachedTrends != null && _cacheTime != null) {
      final now = DateTime.now();
      if (now.difference(_cacheTime!).inSeconds < _cacheDuration.inSeconds) {
        debugLog('✅ Returning cached trends (${_cachedTrends!.length} trends)');
        return _cachedTrends!;
      }
    }

    debugLog('📡 Fetching fresh trends from Gemini API...');
    try {
      final trends = await _fetchTrendsFromGemini();
      
      // Cache the results
      _cachedTrends = trends;
      _cacheTime = DateTime.now();
      
      debugLog('✅ Fetched ${trends.length} trends successfully');
      return trends;
    } catch (e) {
      debugLog('❌ Error fetching trends: $e');
      
      // Return cached trends if available, even if expired
      if (_cachedTrends != null) {
        debugLog('⚠️ Returning stale cached trends');
        return _cachedTrends!;
      }
      
      // Return empty list as fallback
      return [];
    }
  }

  /// Fetch trends from Gemini API
  static Future<List<TrendingTemplate>> _fetchTrendsFromGemini() async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
    );

    final prompt = '''TODAY IS JUNE 2026. List the ACTUAL BIGGEST VIRAL TOPICS RIGHT NOW that people are searching and creating content for. CRITICAL: All search terms MUST include "people" or "person" so images show ACTUAL PEOPLE/CHARACTERS, not just objects or landscapes.

**MUST INCLUDE (High Priority - Major Events Happening):**
- Women's Cricket World Cup (search: "women cricket players", "female cricket athlete", "women cricket person")
- Football World Cup (search: "football players", "soccer people", "athletes playing football")
- Olympic Games preparations (search: "olympic athletes", "sports person", "people competing")
- AI Latest Breakthroughs (search: "person using AI", "people with technology", "AI user")
- Stock Market & Crypto trends (search: "person trading stocks", "crypto investor", "people with money")

**Also Include (Medium Priority):**
- Business & Startups (search: "business person", "entrepreneur people", "person working")
- Tech gadgets (search: "person with gadgets", "people using technology", "tech user")
- Travel & vacation trends (search: "people traveling", "tourists", "vacation person")
- Entertainment & movies (search: "movie actors", "people performing", "actor character")
- Health & fitness (search: "person exercising", "fitness people", "workout person")

Return ONLY valid JSON, NO markdown, NO extra text. ALL searchTerms MUST include "people" or "person":
[
  {"trendName":"Women's Cricket World Cup","searchTerms":["women cricket players","female cricket athlete","women cricket person"],"visualContext":"Female athletes playing cricket","contentType":"sports","priority":"HIGH","popularityLevel":"HIGH"},
  {"trendName":"Football World Cup","searchTerms":["football players","soccer people","athletes playing football"],"visualContext":"Soccer players and fans","contentType":"sports","priority":"HIGH","popularityLevel":"HIGH"},
  {"trendName":"AI Breakthroughs","searchTerms":["person using AI","people with technology","AI user"],"visualContext":"Futuristic AI technology with people","contentType":"tech","priority":"HIGH","popularityLevel":"HIGH"}
]''';

    final requestBody = {
      'contents': [
        {
          'parts': [
            {
              'text': prompt,
            }
          ]
        }
      ]
    };

    debugLog('📤 Sending request to Gemini API...');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    ).timeout(
      const Duration(seconds: 60),
      onTimeout: () => throw Exception('Gemini API timeout'),
    );

    debugLog('📥 Received response: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['candidates'] != null && data['candidates'].isNotEmpty) {
        final candidate = data['candidates'][0];
        if (candidate['content'] != null && candidate['content']['parts'] != null) {
          for (final part in candidate['content']['parts']) {
            if (part['text'] != null) {
              var responseText = part['text'].toString().trim();
              
              // Remove markdown code blocks if present
              if (responseText.startsWith('```json')) {
                responseText = responseText.replaceFirst('```json', '').trim();
              }
              if (responseText.startsWith('```')) {
                responseText = responseText.replaceFirst('```', '').trim();
              }
              if (responseText.endsWith('```')) {
                responseText = responseText.replaceAll(RegExp(r'```\s*$'), '').trim();
              }
              
              // Parse JSON from response
              try {
                final List<dynamic> trendsJson = jsonDecode(responseText);
                
                final trends = trendsJson
                    .map((item) => TrendingTemplate.fromJson(item as Map<String, dynamic>))
                    .toList();

                debugLog('✅ Parsed ${trends.length} trends from Gemini');
                return trends;
              } catch (parseError) {
                debugLog('❌ Error parsing JSON: $parseError');
                debugLog('Response text (first 500 chars): ${responseText.substring(0, responseText.length > 500 ? 500 : responseText.length)}');
                throw Exception('Failed to parse trend data');
              }
            }
          }
        }
      }

      throw Exception('No text response from Gemini API');
    } else {
      final errorBody = response.body;
      debugLog('❌ API Error: ${response.statusCode}');
      debugLog('❌ Error details: $errorBody');
      throw Exception('Gemini API returned status ${response.statusCode}');
    }
  }

  /// Sort trends by priority for display (HIGH → MEDIUM → LOW → repeat)
  static List<TrendingTemplate> sortByPriority(List<TrendingTemplate> trends) {
    final high = trends.where((t) => t.priority == 'HIGH').toList();
    final medium = trends.where((t) => t.priority == 'MEDIUM').toList();
    final low = trends.where((t) => t.priority == 'LOW').toList();

    // Interleave the priorities: HIGH, MEDIUM, LOW, repeat
    final sorted = <TrendingTemplate>[];
    
    final maxLength = [high.length, medium.length, low.length].reduce((a, b) => a > b ? a : b);
    
    for (int i = 0; i < maxLength; i++) {
      if (i < high.length) sorted.add(high[i]);
      if (i < medium.length) sorted.add(medium[i]);
      if (i < low.length) sorted.add(low[i]);
    }

    return sorted;
  }
}
