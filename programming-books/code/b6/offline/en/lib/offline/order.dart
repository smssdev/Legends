enum SyncState { queued, synced, failed }

// One order as this phone knows it, with how far it got in reaching the server.
class Order {
  const Order({
    required this.id,
    required this.title,
    this.note = '',
    this.status = 'new',
    this.sync = SyncState.queued,
    this.version = 0,
    this.error,
  });

  final String id;
  final String title;
  // Who owns which field: the person writes the note; the café writes the status.
  final String note;
  final String status;
  final SyncState sync;
  final int version;
  final String? error;

  Order copyWith({
    String? note,
    String? status,
    SyncState? sync,
    int? version,
    String? error,
  }) => Order(
    id: id,
    title: title,
    note: note ?? this.note,
    status: status ?? this.status,
    sync: sync ?? this.sync,
    version: version ?? this.version,
    error: error ?? this.error,
  );
}
