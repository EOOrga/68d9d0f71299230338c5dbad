import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

abstract class OperationsStore {
  Future<List<WorkItem>> loadItems();

  Future<AppPreferences> loadPreferences();

  Future<void> saveItems(List<WorkItem> items);

  Future<void> savePreferences(AppPreferences preferences);
}

class SharedPreferencesOperationsStore implements OperationsStore {
  static const _itemsKey = 'garon_denise_items_v1';
  static const _preferencesKey = 'garon_denise_preferences_v1';

  @override
  Future<List<WorkItem>> loadItems() async {
    final preferences = await SharedPreferences.getInstance();
    final rawItems = preferences.getString(_itemsKey);
    if (rawItems == null || rawItems.isEmpty) {
      return sampleItems();
    }

    final decoded = jsonDecode(rawItems);
    if (decoded is! List) {
      return sampleItems();
    }

    return decoded
        .whereType<Map>()
        .map((json) => WorkItem.fromJson(Map<String, Object?>.from(json)))
        .toList(growable: false);
  }

  @override
  Future<AppPreferences> loadPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    final rawPreferences = preferences.getString(_preferencesKey);
    if (rawPreferences == null || rawPreferences.isEmpty) {
      return defaultPreferences;
    }

    final decoded = jsonDecode(rawPreferences);
    if (decoded is! Map) {
      return defaultPreferences;
    }
    return AppPreferences.fromJson(Map<String, Object?>.from(decoded));
  }

  @override
  Future<void> saveItems(List<WorkItem> items) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _itemsKey,
      jsonEncode(items.map((item) => item.toJson()).toList(growable: false)),
    );
  }

  @override
  Future<void> savePreferences(AppPreferences preferences) async {
    final localPreferences = await SharedPreferences.getInstance();
    await localPreferences.setString(
      _preferencesKey,
      jsonEncode(preferences.toJson()),
    );
  }
}

class MemoryOperationsStore implements OperationsStore {
  MemoryOperationsStore({
    List<WorkItem>? items,
    AppPreferences preferences = defaultPreferences,
  }) : _items = List<WorkItem>.from(items ?? const []),
       _preferences = preferences;

  factory MemoryOperationsStore.seeded() {
    return MemoryOperationsStore(items: sampleItems());
  }

  List<WorkItem> _items;
  AppPreferences _preferences;

  @override
  Future<List<WorkItem>> loadItems() async => List<WorkItem>.from(_items);

  @override
  Future<AppPreferences> loadPreferences() async => _preferences;

  @override
  Future<void> saveItems(List<WorkItem> items) async {
    _items = List<WorkItem>.from(items);
  }

  @override
  Future<void> savePreferences(AppPreferences preferences) async {
    _preferences = preferences;
  }
}

class OperationsController extends ChangeNotifier {
  OperationsController({required this.store, required this.screenshotMode});

  final OperationsStore store;
  final bool screenshotMode;

  bool _loaded = false;
  List<WorkItem> _items = const [];
  AppPreferences _preferences = defaultPreferences;

  bool get loaded => _loaded;

  List<WorkItem> get allItems => List<WorkItem>.unmodifiable(_items);

  AppPreferences get preferences => _preferences;

  List<WorkItem> visibleItemsFor(WorkType type) {
    return _items
        .where((item) => item.type == type)
        .where((item) => _preferences.showClosed || !item.isClosed)
        .toList(growable: false);
  }

  List<WorkItem> visibleOrderItems() {
    return _items
        .where(
          (item) =>
              item.type == WorkType.procurement || item.type == WorkType.supply,
        )
        .where((item) => _preferences.showClosed || !item.isClosed)
        .toList(growable: false);
  }

  Future<void> load() async {
    final loadedItems = screenshotMode
        ? sampleItems()
        : await store.loadItems();
    final loadedPreferences = screenshotMode
        ? defaultPreferences
        : await store.loadPreferences();
    _items = loadedItems;
    _preferences = loadedPreferences;
    _loaded = true;
    notifyListeners();
  }

  Future<void> addItem(WorkItem item) async {
    _items = [item, ..._items];
    await _saveItems();
  }

  Future<void> updateItem(WorkItem item) async {
    _items = [
      for (final current in _items)
        if (current.id == item.id) item else current,
    ];
    await _saveItems();
  }

  Future<void> deleteItem(String id) async {
    _items = _items.where((item) => item.id != id).toList(growable: false);
    await _saveItems();
  }

  Future<void> updatePreferences(AppPreferences preferences) async {
    _preferences = preferences;
    if (!screenshotMode) {
      await store.savePreferences(preferences);
    }
    notifyListeners();
  }

  Future<void> resetLocalRecords() async {
    _items = sampleItems();
    await _saveItems();
  }

  Future<void> _saveItems() async {
    if (!screenshotMode) {
      await store.saveItems(_items);
    }
    notifyListeners();
  }
}

List<WorkItem> sampleItems() {
  final now = DateTime(2026, 5, 10, 9);
  return [
    WorkItem(
      id: 'lead-atlas',
      type: WorkType.lead,
      title: 'Atlas Wholesale expansion',
      partner: 'Atlas Wholesale',
      owner: 'Denise',
      status: 'Proposal',
      priority: 'High',
      dueDate: 'May 14',
      valueLabel: '\$48K pipeline',
      location: 'Casablanca',
      progress: 75,
      notes: 'Prepare revised commercial terms and confirm delivery windows.',
      updatedAt: now.subtract(const Duration(hours: 1)),
    ),
    WorkItem(
      id: 'procurement-coldchain',
      type: WorkType.procurement,
      title: 'Cold-chain pallet wrap',
      partner: 'Northline Packaging',
      owner: 'Garon',
      status: 'Approved',
      priority: 'High',
      dueDate: 'May 12',
      valueLabel: '340 rolls',
      location: 'Warehouse A',
      progress: 60,
      notes: 'Approved by operations. Waiting on supplier confirmation.',
      updatedAt: now.subtract(const Duration(hours: 2)),
    ),
    WorkItem(
      id: 'supply-parts',
      type: WorkType.supply,
      title: 'Forklift service kit',
      partner: 'Internal supply desk',
      owner: 'Mina',
      status: 'Queued',
      priority: 'Normal',
      dueDate: 'May 15',
      valueLabel: '8 kits',
      location: 'Dock 3',
      progress: 66,
      notes: 'Bundle filters, belts, and inspection tags for maintenance.',
      updatedAt: now.subtract(const Duration(hours: 4)),
    ),
    WorkItem(
      id: 'container-7714',
      type: WorkType.container,
      title: 'Container GDN-7714',
      partner: 'BlueLine Freight',
      owner: 'Youssef',
      status: 'In transit',
      priority: 'High',
      dueDate: 'ETA May 18',
      valueLabel: '24 pallets',
      location: 'Tangier to Marseille',
      progress: 52,
      notes: 'Documents cleared. Monitor port berth assignment daily.',
      updatedAt: now.subtract(const Duration(hours: 3)),
    ),
    WorkItem(
      id: 'lead-orion',
      type: WorkType.lead,
      title: 'Orion Retail replenishment',
      partner: 'Orion Retail',
      owner: 'Denise',
      status: 'Qualified',
      priority: 'Normal',
      dueDate: 'May 20',
      valueLabel: '\$21K pipeline',
      location: 'Rabat',
      progress: 50,
      notes: 'Needs recurring monthly ordering plan and delivery calendar.',
      updatedAt: now.subtract(const Duration(days: 1)),
    ),
    WorkItem(
      id: 'container-6632',
      type: WorkType.container,
      title: 'Container GDN-6632',
      partner: 'Atlantic Forwarding',
      owner: 'Garon',
      status: 'Customs',
      priority: 'Normal',
      dueDate: 'Release May 11',
      valueLabel: '18 pallets',
      location: 'Casablanca port',
      progress: 78,
      notes: 'Customs broker has invoice packet and packing list.',
      updatedAt: now.subtract(const Duration(hours: 5)),
    ),
  ];
}
