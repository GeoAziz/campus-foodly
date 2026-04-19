enum PaymentStatus {
  idle,
  pending,
  processing,
  succeeded,
  failed,
}

PaymentStatus paymentStatusFromString(String value) {
  return switch (value) {
    'pending' => PaymentStatus.pending,
    'processing' => PaymentStatus.processing,
    'succeeded' => PaymentStatus.succeeded,
    'failed' => PaymentStatus.failed,
    _ => PaymentStatus.idle,
  };
}

String paymentStatusToString(PaymentStatus status) {
  return switch (status) {
    PaymentStatus.idle => 'idle',
    PaymentStatus.pending => 'pending',
    PaymentStatus.processing => 'processing',
    PaymentStatus.succeeded => 'succeeded',
    PaymentStatus.failed => 'failed',
  };
}
