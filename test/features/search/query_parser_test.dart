// Unit tests for QueryParser — parses natural-language search queries
// into structured SearchQueryModel objects.

import 'package:flutter_test/flutter_test.dart';
import 'package:find_my_stuff_ai/features/search/data/query_parser.dart';
import 'package:find_my_stuff_ai/features/search/domain/search_query_model.dart';

void main() {
  group('QueryParser.parse', () {
    test('extracts single keyword from simple object query', () {
      final q = QueryParser.parse('charger');
      expect(q.keywords, contains('charger'));
      expect(q.rawQuery, equals('charger'));
    });

    test('extracts color attribute', () {
      final q = QueryParser.parse('black charger');
      expect(q.targetColor, equals('black'));
      expect(q.keywords, contains('charger'));
    });

    test('extracts target item from "where is my X" pattern', () {
      final q = QueryParser.parse('where is my college ID');
      expect(q.targetItem, isNotNull);
      // Should contain "id" or "college"
      expect(
        q.targetItem!.toLowerCase().contains('id') ||
            q.keywords.any((k) => k.contains('id') || k.contains('college')),
        isTrue,
      );
    });

    test('extracts location hint from "near" clause', () {
      final q = QueryParser.parse('keys near the study table');
      expect(q.keywords, contains('keys'));
      // Location should mention "study table" or be non-null
      expect(q.targetLocation != null || q.keywords.any((k) => k.contains('study')), isTrue);
    });

    test('extracts time filter for "today"', () {
      final q = QueryParser.parse('photos from today');
      expect(q.timeFilter, equals(TimeFilter.today));
    });

    test('extracts time filter for "yesterday"', () {
      final q = QueryParser.parse('keys yesterday');
      expect(q.timeFilter, equals(TimeFilter.yesterday));
    });

    test('extracts time filter for "this week"', () {
      final q = QueryParser.parse('backpack this week');
      expect(q.timeFilter, equals(TimeFilter.thisWeek));
    });

    test('defaults to TimeFilter.any for unspecified time', () {
      final q = QueryParser.parse('wallet');
      expect(q.timeFilter, equals(TimeFilter.any));
    });

    test('handles multi-word natural query', () {
      final q = QueryParser.parse('find my black USB-C charger');
      expect(q.keywords, isNotEmpty);
      // Should capture at least "charger" and "black" as color
      expect(q.targetColor, equals('black'));
    });

    test('empty query returns empty model', () {
      final q = QueryParser.parse('');
      expect(q.keywords, isEmpty);
      expect(q.targetItem, isNull);
      expect(q.rawQuery, equals(''));
    });

    test('case insensitive parsing', () {
      final q = QueryParser.parse('BLACK Wallet ON My Desk');
      expect(q.targetColor, equals('black'));
      expect(q.keywords.map((k) => k.toLowerCase()), contains('wallet'));
    });

    test('parses Hindi/Hinglish query "Mera black charger kahan hai"', () {
      final q = QueryParser.parse('Mera black charger kahan hai');
      expect(q.targetColor, equals('black'));
      expect(q.targetItem, equals('Charger'));
      // Hindi stop words (mera, kahan, hai) should be stripped
      expect(q.keywords, contains('charger'));
      expect(q.keywords, isNot(contains('mera')));
      expect(q.keywords, isNot(contains('kahan')));
    });

    test('parses Hindi synonyms "Meri chaabi kal"', () {
      final q = QueryParser.parse('Meri chaabi kal');
      expect(q.targetItem, equals('Keys'));
      expect(q.timeFilter, equals(TimeFilter.yesterday));
    });

    test('parses Hindi color and item "Kaala chashma aaj"', () {
      final q = QueryParser.parse('Kaala chashma aaj');
      expect(q.targetColor, equals('black'));
      expect(q.targetItem, equals('Glasses'));
      expect(q.timeFilter, equals(TimeFilter.today));
    });
  });
}
