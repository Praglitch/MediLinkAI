/// Lifecycle status of a volunteer transfer request.
enum TransferRequestStatus {
  pending,
  approved,
  dispatched,
  inTransit,
  received,
  completed,
}

/// A tracked request for a volunteer to carry out a resource transfer.
class TransferRequest {
  final String id;
  final String resourceType; // 'OXYGEN', 'BED'
  final TransferRequestStatus status;
  final String fromName;
  final String toName;
  final int quantity;
  final String? assignedVolunteerName;

  const TransferRequest({
    required this.id,
    required this.resourceType,
    required this.status,
    required this.fromName,
    required this.toName,
    required this.quantity,
    this.assignedVolunteerName,
  });

  String get statusLabel {
    switch (status) {
      case TransferRequestStatus.pending:
        return 'PENDING';
      case TransferRequestStatus.approved:
        return 'APPROVED';
      case TransferRequestStatus.dispatched:
        return 'DISPATCHED';
      case TransferRequestStatus.inTransit:
        return 'IN TRANSIT';
      case TransferRequestStatus.received:
        return 'RECEIVED';
      case TransferRequestStatus.completed:
        return 'COMPLETED';
    }
  }
}
