import '../domain/search_query_model.dart';

class QueryParser {
  static const Map<String, List<String>> _colorSynonyms = {
    'black': ['black', 'kaala', 'kala', 'kaale', 'kali'],
    'white': ['white', 'safed', 'chitta'],
    'blue': ['blue', 'neela', 'nila', 'neeli'],
    'red': ['red', 'laal', 'lal'],
    'green': ['green', 'hara', 'hari'],
    'yellow': ['yellow', 'peela', 'pila', 'peeli'],
    'silver': ['silver', 'chandi'],
    'brown': ['brown', 'bhoora', 'bhura'],
    'grey': ['grey', 'gray', 'slaty'],
    'orange': ['orange', 'narangi'],
    'purple': ['purple', 'baingani'],
    'pink': ['pink', 'gulabi'],
  };

  static const Map<String, List<String>> _itemSynonyms = {
    'Keys': ['keys', 'key', 'keychain', 'car key', 'house key', 'chaabi', 'chabi', 'chabhi', 'kunji'],
    'Charger': ['charger', 'cable', 'cord', 'adapter', 'wire', 'usb', 'usb-c', 'lightning', 'plug', 'chazar'],
    'College ID': ['college id', 'id card', 'id', 'student id', 'campus card', 'badge', 'pass', 'pehchaan patra'],
    'Wallet': ['wallet', 'purse', 'cardholder', 'billfold', 'batua'],
    'Headphones': ['headphones', 'earphones', 'earbuds', 'airpods', 'buds', 'headset', 'earphone', 'headphone'],
    'Glasses': ['glasses', 'spectacles', 'sunglasses', 'shades', 'chashma', 'chasma', 'ainak', 'specs'],
    'Backpack': ['backpack', 'bag', 'tote', 'rucksack', 'knapsack', 'basta', 'college bag', 'school bag'],
    'Watch': ['watch', 'smartwatch', 'wristwatch', 'iwatch', 'ghadi', 'ghari'],
    'Water Bottle': ['water bottle', 'bottle', 'flask', 'mug', 'cup', 'tumbler', 'paani ki bottle', 'pani ki bottle'],
    'Laptop': ['laptop', 'macbook', 'notebook', 'computer'],
  };

  static const Map<String, List<String>> _locationKeywords = {
    'Bedroom': ['bedroom', 'bed', 'nightstand', 'wardrobe', 'closet', 'kamra', 'kamre', 'almari', 'almirah', 'bistar'],
    'Study Desk': ['study desk', 'desk', 'study table', 'study', 'workstation', 'mez', 'padhai ki table', 'table'],
    'Living Room': ['living room', 'couch', 'sofa', 'tv unit', 'coffee table', 'hall'],
    'College Backpack': ['backpack', 'college backpack', 'bag', 'basta', 'college bag'],
    'Office Desk': ['office', 'office desk', 'office table', 'cubicle', 'work desk'],
    'Kitchen Counter': ['kitchen', 'kitchen counter', 'fridge', 'dining table', 'rasoi', 'kitchen table'],
    'Car Glovebox': ['car', 'glovebox', 'dashboard', 'seat', 'gaadi', 'gaddi'],
    'Entryway Shelf': ['entryway', 'shelf', 'rack', 'shoe rack', 'door', 'darwaza'],
  };

  /// Parses natural language query (English, Hindi, Hinglish) into structured search parameters
  static SearchQueryModel parse(String query) {
    final lower = query.toLowerCase().trim();
    if (lower.isEmpty) {
      return const SearchQueryModel(rawQuery: '');
    }

    String? detectedItem;
    String? detectedColor;
    String? detectedLocation;
    TimeFilter timeFilter = TimeFilter.any;

    // 1. Detect Time Filters (English & Hindi)
    if (lower.contains('today') || lower.contains('aaj')) {
      timeFilter = TimeFilter.today;
    } else if (lower.contains('yesterday') || lower.contains('kal') || lower.contains('beeta kal')) {
      timeFilter = TimeFilter.yesterday;
    } else if (lower.contains('this week') || lower.contains('past week') || lower.contains('last week') ||
               lower.contains('is hafte') || lower.contains('pichle hafte') || lower.contains('recent')) {
      timeFilter = TimeFilter.thisWeek;
    } else if (lower.contains('this month') || lower.contains('past month') || lower.contains('is mahine')) {
      timeFilter = TimeFilter.thisMonth;
    }

    // 2. Detect Color (English & Hindi)
    for (final entry in _colorSynonyms.entries) {
      for (final syn in entry.value) {
        final reg = RegExp(r'\b' + RegExp.escape(syn) + r'\b');
        if (reg.hasMatch(lower)) {
          detectedColor = entry.key;
          break;
        }
      }
      if (detectedColor != null) break;
    }

    // 3. Detect Item Category (English & Hindi)
    for (final entry in _itemSynonyms.entries) {
      for (final syn in entry.value) {
        final reg = RegExp(r'\b' + RegExp.escape(syn) + r'\b');
        if (reg.hasMatch(lower)) {
          detectedItem = entry.key;
          break;
        }
      }
      if (detectedItem != null) break;
    }

    // 4. Detect Location / Room (English & Hindi)
    for (final entry in _locationKeywords.entries) {
      for (final kw in entry.value) {
        final reg = RegExp(r'\b' + RegExp.escape(kw) + r'\b');
        if (reg.hasMatch(lower)) {
          detectedLocation = entry.key;
          break;
        }
      }
      if (detectedLocation != null) break;
    }

    // 5. Extract cleaned keywords (strip English & Hindi stop words and question phrasing)
    var cleaned = lower
        .replaceAll(RegExp(r'\b(where is my|where is|where did i keep|where did i leave|find my|find the|find|show me|show my|show|when did i last see|when was|look for|did i leave|photo of|photo with|my|the|a|an|in|on|at|near|beside|under|by|from|yesterday|today|last)\b'), ' ')
        .replaceAll(RegExp(r'\b(mera|meri|mere|kahan hai|kahan rakha|kahan rakhi|kahan tha|kahan thi|kahan|kidhar hai|kidhar rakha|kidhar|dhundo|dhundho|batao|dikhao|tha|thi|hai|hain|rakha|rakhi|par|pe|me|mein|se|ka|ki|ke|aaj|kal)\b'), ' ')
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .trim();

    final keywords = cleaned
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1)
        .toSet()
        .toList();

    return SearchQueryModel(
      rawQuery: query,
      targetItem: detectedItem,
      targetColor: detectedColor,
      targetLocation: detectedLocation,
      timeFilter: timeFilter,
      keywords: keywords,
    );
  }
}
