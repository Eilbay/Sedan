enum TryOnTaskStatus { queued, processing, completed, failed }

TryOnTaskStatus parseTaskStatus(String s) {
  switch (s.toLowerCase()) {
    case 'queued':
      return TryOnTaskStatus.queued;
    case 'processing':
      return TryOnTaskStatus.processing;
    case 'completed':
      return TryOnTaskStatus.completed;
    default:
      return TryOnTaskStatus.failed;
  }
}
