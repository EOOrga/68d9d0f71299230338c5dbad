enum WorkType { lead, procurement, supply, container }

extension WorkTypeLabels on WorkType {
  String get label {
    switch (this) {
      case WorkType.lead:
        return 'Lead';
      case WorkType.procurement:
        return 'Procurement';
      case WorkType.supply:
        return 'Supply order';
      case WorkType.container:
        return 'Container';
    }
  }

  String get pluralLabel {
    switch (this) {
      case WorkType.lead:
        return 'Leads';
      case WorkType.procurement:
        return 'Procurement';
      case WorkType.supply:
        return 'Supply orders';
      case WorkType.container:
        return 'Containers';
    }
  }
}

class WorkItem {
  const WorkItem({
    required this.id,
    required this.type,
    required this.title,
    required this.partner,
    required this.owner,
    required this.status,
    required this.priority,
    required this.dueDate,
    required this.valueLabel,
    required this.location,
    required this.progress,
    required this.notes,
    required this.updatedAt,
  });

  final String id;
  final WorkType type;
  final String title;
  final String partner;
  final String owner;
  final String status;
  final String priority;
  final String dueDate;
  final String valueLabel;
  final String location;
  final int progress;
  final String notes;
  final DateTime updatedAt;

  bool get isClosed =>
      status == 'Won' ||
      status == 'Received' ||
      status == 'Fulfilled' ||
      status == 'Delivered';

  WorkItem copyWith({
    String? id,
    WorkType? type,
    String? title,
    String? partner,
    String? owner,
    String? status,
    String? priority,
    String? dueDate,
    String? valueLabel,
    String? location,
    int? progress,
    String? notes,
    DateTime? updatedAt,
  }) {
    return WorkItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      partner: partner ?? this.partner,
      owner: owner ?? this.owner,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      valueLabel: valueLabel ?? this.valueLabel,
      location: location ?? this.location,
      progress: progress ?? this.progress,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'partner': partner,
      'owner': owner,
      'status': status,
      'priority': priority,
      'dueDate': dueDate,
      'valueLabel': valueLabel,
      'location': location,
      'progress': progress,
      'notes': notes,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory WorkItem.fromJson(Map<String, Object?> json) {
    final typeName = json['type'] as String? ?? WorkType.lead.name;
    final type = WorkType.values.firstWhere(
      (value) => value.name == typeName,
      orElse: () => WorkType.lead,
    );

    return WorkItem(
      id:
          json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      title: json['title'] as String? ?? '',
      partner: json['partner'] as String? ?? '',
      owner: json['owner'] as String? ?? '',
      status: json['status'] as String? ?? defaultStatusFor(type),
      priority: json['priority'] as String? ?? 'Normal',
      dueDate: json['dueDate'] as String? ?? 'This week',
      valueLabel: json['valueLabel'] as String? ?? '',
      location: json['location'] as String? ?? '',
      progress: json['progress'] as int? ?? 0,
      notes: json['notes'] as String? ?? '',
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class AppPreferences {
  const AppPreferences({required this.siteName, required this.showClosed});

  final String siteName;
  final bool showClosed;

  AppPreferences copyWith({String? siteName, bool? showClosed}) {
    return AppPreferences(
      siteName: siteName ?? this.siteName,
      showClosed: showClosed ?? this.showClosed,
    );
  }

  Map<String, Object?> toJson() {
    return {'siteName': siteName, 'showClosed': showClosed};
  }

  factory AppPreferences.fromJson(Map<String, Object?> json) {
    return AppPreferences(
      siteName: json['siteName'] as String? ?? 'Main office',
      showClosed: json['showClosed'] as bool? ?? true,
    );
  }
}

const defaultPreferences = AppPreferences(
  siteName: 'Main office',
  showClosed: true,
);

String defaultStatusFor(WorkType type) {
  switch (type) {
    case WorkType.lead:
      return 'New';
    case WorkType.procurement:
      return 'Draft';
    case WorkType.supply:
      return 'Requested';
    case WorkType.container:
      return 'At origin';
  }
}

List<String> statusesFor(WorkType type) {
  switch (type) {
    case WorkType.lead:
      return const ['New', 'Qualified', 'Proposal', 'Won'];
    case WorkType.procurement:
      return const ['Draft', 'Submitted', 'Approved', 'Ordered', 'Received'];
    case WorkType.supply:
      return const ['Requested', 'Queued', 'Fulfilled'];
    case WorkType.container:
      return const ['At origin', 'In transit', 'Customs', 'Delivered'];
  }
}

int defaultProgressFor(String status, WorkType type) {
  final statuses = statusesFor(type);
  final index = statuses.indexOf(status);
  if (index < 0 || statuses.length == 1) {
    return 0;
  }
  return ((index + 1) / statuses.length * 100).round();
}
