import 'dart:async';

import 'package:flutter/material.dart';

import 'models.dart';
import 'operations_store.dart';

const _appName = 'GARON DENISE';
const _supportEmail = 'support@garondenise.com';

const _brandPrimary = Color(0xFF26F75E);
const _brandSecondary = Color(0xFF26F7C6);
const _brandTertiary = Color(0xFF26BFF7);
const _brandSurface = Color(0xFFF7F5EF);

class GaronDeniseApp extends StatefulWidget {
  const GaronDeniseApp({
    super.key,
    required this.store,
    required this.screenshotMode,
  });

  final OperationsStore store;
  final bool screenshotMode;

  @override
  State<GaronDeniseApp> createState() => _GaronDeniseAppState();
}

class _GaronDeniseAppState extends State<GaronDeniseApp> {
  late final OperationsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = OperationsController(
      store: widget.store,
      screenshotMode: widget.screenshotMode,
    );
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _brandPrimary,
      primary: _brandPrimary,
      secondary: _brandSecondary,
      tertiary: _brandTertiary,
      surface: _brandSurface,
    );

    return MaterialApp(
      title: _appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: _brandSurface,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: _brandSurface,
          foregroundColor: _brandPrimary,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: _brandPrimary.withAlpha(22)),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: _brandSecondary.withAlpha(38),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      home: OperationsHome(controller: _controller),
    );
  }
}

class OperationsHome extends StatefulWidget {
  const OperationsHome({super.key, required this.controller});

  final OperationsController controller;

  @override
  State<OperationsHome> createState() => _OperationsHomeState();
}

class _OperationsHomeState extends State<OperationsHome> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        if (!widget.controller.loaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final screens = [
          DashboardScreen(
            controller: widget.controller,
            onOpenType: _openType,
            onAddItem: () => _openForm(),
          ),
          WorkListScreen(
            controller: widget.controller,
            title: 'GARON DENISE',
            types: const [WorkType.lead],
            emptyLabel: 'No leads are waiting.',
            onAddItem: () => _openForm(initialType: WorkType.lead),
          ),
          WorkListScreen(
            controller: widget.controller,
            title: 'Procurement and supplies',
            types: const [WorkType.procurement, WorkType.supply],
            emptyLabel: 'No orders are waiting.',
            onAddItem: () => _openForm(initialType: WorkType.procurement),
          ),
          WorkListScreen(
            controller: widget.controller,
            title: 'Container tracking',
            types: const [WorkType.container],
            emptyLabel: 'No containers are being tracked.',
            onAddItem: () => _openForm(initialType: WorkType.container),
          ),
          SettingsScreen(controller: widget.controller),
        ];

        return Scaffold(
          body: SafeArea(child: screens[_selectedIndex]),
          floatingActionButton: _selectedIndex == 4
              ? null
              : FloatingActionButton(
                  key: const ValueKey('add-work-item'),
                  onPressed: () => _openForm(
                    initialType: switch (_selectedIndex) {
                      1 => WorkType.lead,
                      2 => WorkType.procurement,
                      3 => WorkType.container,
                      _ => null,
                    },
                  ),
                  child: const Icon(Icons.add),
                ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.trending_up_outlined),
                selectedIcon: Icon(Icons.trending_up),
                label: 'Leads',
              ),
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: 'Orders',
              ),
              NavigationDestination(
                icon: Icon(Icons.local_shipping_outlined),
                selectedIcon: Icon(Icons.local_shipping),
                label: 'Containers',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }

  void _openType(WorkType type) {
    setState(() {
      _selectedIndex = switch (type) {
        WorkType.lead => 1,
        WorkType.procurement || WorkType.supply => 2,
        WorkType.container => 3,
      };
    });
  }

  Future<void> _openForm({WorkType? initialType}) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => WorkItemFormScreen(
          controller: widget.controller,
          initialType: initialType,
        ),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.controller,
    required this.onOpenType,
    required this.onAddItem,
  });

  final OperationsController controller;
  final ValueChanged<WorkType> onOpenType;
  final VoidCallback onAddItem;

  @override
  Widget build(BuildContext context) {
    final items = controller.allItems;
    final activeItems = items.where((item) => !item.isClosed).length;
    final urgentItems = items.where((item) => item.priority == 'High').length;
    final containerItems = items
        .where((item) => item.type == WorkType.container && !item.isClosed)
        .length;
    final latestItems = [...items]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _appName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: _brandPrimary,
                ),
              ),
              Text(
                controller.preferences.siteName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _brandPrimary.withAlpha(170),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Add work item',
              onPressed: onAddItem,
              icon: const Icon(Icons.add_task),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          sliver: SliverList.list(
            children: [
              _DashboardHero(
                activeItems: activeItems,
                urgentItems: urgentItems,
                containerItems: containerItems,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _QuickActionChip(
                    icon: Icons.person_search,
                    label: 'Lead follow-up',
                    onPressed: () => onOpenType(WorkType.lead),
                  ),
                  _QuickActionChip(
                    icon: Icons.request_quote,
                    label: 'Procurement',
                    onPressed: () => onOpenType(WorkType.procurement),
                  ),
                  _QuickActionChip(
                    icon: Icons.inventory,
                    label: 'Supply desk',
                    onPressed: () => onOpenType(WorkType.supply),
                  ),
                  _QuickActionChip(
                    icon: Icons.route,
                    label: 'Containers',
                    onPressed: () => onOpenType(WorkType.container),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _SectionHeader(
                title: 'Today at a glance',
                actionLabel: 'Add',
                onAction: onAddItem,
              ),
              const SizedBox(height: 10),
              ...latestItems
                  .take(4)
                  .map(
                    (item) => WorkItemTile(
                      item: item,
                      onTap: () => _openDetail(context, item),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  void _openDetail(BuildContext context, WorkItem item) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) =>
            WorkItemDetailScreen(controller: controller, item: item),
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.activeItems,
    required this.urgentItems,
    required this.containerItems,
  });

  final int activeItems;
  final int urgentItems;
  final int containerItems;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _brandPrimary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Operations board',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lead work, purchase requests, supply orders, and containers stay in one local workspace.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withAlpha(220),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Active',
                  value: '$activeItems',
                  icon: Icons.bolt,
                ),
              ),
              Expanded(
                child: _HeroMetric(
                  label: 'High priority',
                  value: '$urgentItems',
                  icon: Icons.priority_high,
                ),
              ),
              Expanded(
                child: _HeroMetric(
                  label: 'Containers',
                  value: '$containerItems',
                  icon: Icons.local_shipping,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _brandSecondary, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white.withAlpha(210)),
        ),
      ],
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, color: _brandPrimary, size: 18),
      label: Text(label),
      onPressed: onPressed,
      backgroundColor: Colors.white,
      side: BorderSide(color: _brandPrimary.withAlpha(34)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

class WorkListScreen extends StatefulWidget {
  const WorkListScreen({
    super.key,
    required this.controller,
    required this.title,
    required this.types,
    required this.emptyLabel,
    required this.onAddItem,
  });

  final OperationsController controller;
  final String title;
  final List<WorkType> types;
  final String emptyLabel;
  final VoidCallback onAddItem;

  @override
  State<WorkListScreen> createState() => _WorkListScreenState();
}

class _WorkListScreenState extends State<WorkListScreen> {
  WorkType? _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.types.length == 1 ? widget.types.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = widget.controller.allItems
        .where((item) => widget.types.contains(item.type))
        .where((item) => _selectedType == null || item.type == _selectedType)
        .where(
          (item) => widget.controller.preferences.showClosed || !item.isClosed,
        )
        .toList(growable: false);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: Text(widget.title),
          actions: [
            IconButton(
              tooltip: 'Create item',
              onPressed: widget.onAddItem,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          sliver: SliverList.list(
            children: [
              if (widget.types.length > 1) ...[
                SegmentedButton<WorkType?>(
                  segments: const [
                    ButtonSegment(
                      value: null,
                      label: Text('All'),
                      icon: Icon(Icons.view_list),
                    ),
                    ButtonSegment(
                      value: WorkType.procurement,
                      label: Text('Procure'),
                      icon: Icon(Icons.request_quote),
                    ),
                    ButtonSegment(
                      value: WorkType.supply,
                      label: Text('Supply'),
                      icon: Icon(Icons.inventory),
                    ),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (selection) {
                    setState(() => _selectedType = selection.first);
                  },
                ),
                const SizedBox(height: 14),
              ],
              _SectionHeader(
                title: '${visibleItems.length} open records',
                actionLabel: 'New',
                onAction: widget.onAddItem,
              ),
              const SizedBox(height: 10),
              if (visibleItems.isEmpty)
                _EmptyState(
                  label: widget.emptyLabel,
                  onPressed: widget.onAddItem,
                )
              else
                ...visibleItems.map(
                  (item) => WorkItemTile(
                    item: item,
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (context) => WorkItemDetailScreen(
                          controller: widget.controller,
                          item: item,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class WorkItemTile extends StatelessWidget {
  const WorkItemTile({super.key, required this.item, required this.onTap});

  final WorkItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TypeBadge(type: item.type),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _PriorityPill(priority: item.priority),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${item.partner} - ${item.location}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: item.progress / 100,
                  minHeight: 7,
                  backgroundColor: _brandPrimary.withAlpha(18),
                  color: _progressColor(item.progress),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _InlineMeta(
                      icon: Icons.flag_outlined,
                      label: item.status,
                    ),
                  ),
                  Expanded(
                    child: _InlineMeta(
                      icon: Icons.event_outlined,
                      label: item.dueDate,
                    ),
                  ),
                  Expanded(
                    child: _InlineMeta(
                      icon: Icons.payments_outlined,
                      label: item.valueLabel,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _progressColor(int value) {
    if (value >= 75) {
      return _brandTertiary;
    }
    if (value >= 45) {
      return _brandSecondary;
    }
    return _brandPrimary;
  }
}

class WorkItemDetailScreen extends StatefulWidget {
  const WorkItemDetailScreen({
    super.key,
    required this.controller,
    required this.item,
  });

  final OperationsController controller;
  final WorkItem item;

  @override
  State<WorkItemDetailScreen> createState() => _WorkItemDetailScreenState();
}

class _WorkItemDetailScreenState extends State<WorkItemDetailScreen> {
  late WorkItem _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  @override
  Widget build(BuildContext context) {
    final statuses = statusesFor(_item.type);
    return Scaffold(
      appBar: AppBar(
        title: Text(_item.type.label),
        actions: [
          IconButton(
            tooltip: 'Delete',
            onPressed: _deleteItem,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            _item.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: _brandPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_item.partner} - ${_item.location}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 18),
          _DetailPanel(
            children: [
              _DetailRow(label: 'Owner', value: _item.owner),
              _DetailRow(label: 'Due', value: _item.dueDate),
              _DetailRow(label: 'Value', value: _item.valueLabel),
              _DetailRow(label: 'Priority', value: _item.priority),
            ],
          ),
          const SizedBox(height: 14),
          _DetailPanel(
            children: [
              Text(
                'Status',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: statuses
                    .map((status) {
                      final selected = status == _item.status;
                      return ChoiceChip(
                        label: Text(status),
                        selected: selected,
                        onSelected: (_) => _updateStatus(status),
                      );
                    })
                    .toList(growable: false),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _item.progress / 100,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 8),
              Text('${_item.progress}% complete'),
            ],
          ),
          const SizedBox(height: 14),
          _DetailPanel(
            children: [
              Text(
                'Notes',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(_item.notes),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(String status) async {
    final updated = _item.copyWith(
      status: status,
      progress: defaultProgressFor(status, _item.type),
      updatedAt: DateTime.now(),
    );
    setState(() => _item = updated);
    await widget.controller.updateItem(updated);
  }

  Future<void> _deleteItem() async {
    await widget.controller.deleteItem(_item.id);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class WorkItemFormScreen extends StatefulWidget {
  const WorkItemFormScreen({
    super.key,
    required this.controller,
    this.initialType,
  });

  final OperationsController controller;
  final WorkType? initialType;

  @override
  State<WorkItemFormScreen> createState() => _WorkItemFormScreenState();
}

class _WorkItemFormScreenState extends State<WorkItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _partnerController = TextEditingController();
  final _ownerController = TextEditingController(text: 'Operations');
  final _dueController = TextEditingController(text: 'This week');
  final _valueController = TextEditingController();
  final _locationController = TextEditingController(text: 'Main office');
  final _notesController = TextEditingController();

  late WorkType _type;
  late String _status;
  String _priority = 'Normal';
  double _progress = 20;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? WorkType.lead;
    _status = defaultStatusFor(_type);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _partnerController.dispose();
    _ownerController.dispose();
    _dueController.dispose();
    _valueController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statuses = statusesFor(_type);
    return Scaffold(
      appBar: AppBar(title: const Text('New operations record')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            DropdownButtonFormField<WorkType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Record type'),
              items: WorkType.values
                  .map(
                    (type) =>
                        DropdownMenuItem(value: type, child: Text(type.label)),
                  )
                  .toList(growable: false),
              onChanged: (type) {
                if (type == null) {
                  return;
                }
                setState(() {
                  _type = type;
                  _status = defaultStatusFor(type);
                  _progress = defaultProgressFor(_status, type).toDouble();
                });
              },
            ),
            const SizedBox(height: 12),
            _RequiredTextField(
              key: const ValueKey('title-field'),
              controller: _titleController,
              label: 'Title',
              icon: Icons.title,
            ),
            const SizedBox(height: 12),
            _RequiredTextField(
              controller: _partnerController,
              label: 'Partner or supplier',
              icon: Icons.business,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _RequiredTextField(
                    controller: _ownerController,
                    label: 'Owner',
                    icon: Icons.person_outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _priority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: const ['Normal', 'High']
                        .map(
                          (priority) => DropdownMenuItem(
                            value: priority,
                            child: Text(priority),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) =>
                        setState(() => _priority = value ?? 'Normal'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: statuses
                  .map(
                    (status) =>
                        DropdownMenuItem(value: status, child: Text(status)),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _status = value;
                  _progress = defaultProgressFor(value, _type).toDouble();
                });
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _RequiredTextField(
                    controller: _dueController,
                    label: 'Due date',
                    icon: Icons.event,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RequiredTextField(
                    controller: _valueController,
                    label: 'Value or quantity',
                    icon: Icons.numbers,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _RequiredTextField(
              controller: _locationController,
              label: 'Location',
              icon: Icons.place_outlined,
            ),
            const SizedBox(height: 16),
            Text(
              'Progress ${_progress.round()}%',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Slider(
              value: _progress,
              min: 0,
              max: 100,
              divisions: 20,
              label: '${_progress.round()}%',
              onChanged: (value) => setState(() => _progress = value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Notes',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const ValueKey('save-work-item'),
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save record'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final now = DateTime.now();
    final item = WorkItem(
      id: 'item-${now.microsecondsSinceEpoch}',
      type: _type,
      title: _titleController.text.trim(),
      partner: _partnerController.text.trim(),
      owner: _ownerController.text.trim(),
      status: _status,
      priority: _priority,
      dueDate: _dueController.text.trim(),
      valueLabel: _valueController.text.trim(),
      location: _locationController.text.trim(),
      progress: _progress.round(),
      notes: _notesController.text.trim().isEmpty
          ? 'No notes recorded yet.'
          : _notesController.text.trim(),
      updatedAt: now,
    );

    await widget.controller.addItem(item);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});

  final OperationsController controller;

  @override
  Widget build(BuildContext context) {
    final preferences = controller.preferences;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: _brandPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _DetailPanel(
          children: [
            TextFormField(
              initialValue: preferences.siteName,
              decoration: const InputDecoration(
                labelText: 'Workspace label',
                prefixIcon: Icon(Icons.warehouse_outlined),
              ),
              onFieldSubmitted: (value) {
                controller.updatePreferences(
                  preferences.copyWith(
                    siteName: value.trim().isEmpty
                        ? 'Main office'
                        : value.trim(),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show closed work'),
              subtitle: const Text(
                'Include won, fulfilled, received, and delivered records.',
              ),
              value: preferences.showClosed,
              onChanged: (value) {
                controller.updatePreferences(
                  preferences.copyWith(showClosed: value),
                );
              },
            ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: controller.resetLocalRecords,
              icon: const Icon(Icons.restore),
              label: const Text('Restore sample records'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _DetailPanel(
          children: [
            _SettingsInfo(
              icon: Icons.lock_outline,
              title: 'Local storage only',
              body:
                  'Records and preferences stay on this Android device. The app has no sign-in, cloud sync, analytics, ads, or external service connection.',
            ),
            const Divider(height: 24),
            _SettingsInfo(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy contact',
              body: 'GARON DENISE\n$_supportEmail',
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: _brandPrimary,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.add, size: 18),
          label: Text(actionLabel),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _brandPrimary.withAlpha(25)),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 36, color: _brandPrimary),
          const SizedBox(height: 8),
          Text(label),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.add),
            label: const Text('Create record'),
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final WorkType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _typeColor(type).withAlpha(28),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type.label,
        style: TextStyle(
          color: _typeColor(type),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Color _typeColor(WorkType type) {
    return switch (type) {
      WorkType.lead => _brandPrimary,
      WorkType.procurement => _brandSecondary,
      WorkType.supply => _brandTertiary,
      WorkType.container => const Color(0xFF476247),
    };
  }
}

class _PriorityPill extends StatelessWidget {
  const _PriorityPill({required this.priority});

  final String priority;

  @override
  Widget build(BuildContext context) {
    final high = priority == 'High';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: high
            ? const Color(0xFF8B2D2D).withAlpha(22)
            : _brandPrimary.withAlpha(16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        priority,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: high ? const Color(0xFF8B2D2D) : _brandPrimary,
        ),
      ),
    );
  }
}

class _InlineMeta extends StatelessWidget {
  const _InlineMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _brandPrimary.withAlpha(155)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _brandPrimary.withAlpha(22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _brandPrimary.withAlpha(170),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequiredTextField extends StatelessWidget {
  const _RequiredTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Required';
        }
        return null;
      },
    );
  }
}

class _SettingsInfo extends StatelessWidget {
  const _SettingsInfo({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _brandPrimary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(body),
            ],
          ),
        ),
      ],
    );
  }
}
