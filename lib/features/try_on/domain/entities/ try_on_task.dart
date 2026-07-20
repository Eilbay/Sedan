import 'package:optombai/features/try_on/domain/entities/task_status.dart';

class TryOnTask {
  final String taskId;
  final TryOnTaskStatus status;
  final int? progress;
  final Uri? downloadUrl;
  final String? error;

  TryOnTask({
    required this.taskId,
    required this.status,
    this.progress,
    this.downloadUrl,
    this.error,
  });

  factory TryOnTask.fromJson(Map<String, dynamic> j) => TryOnTask(
        taskId: j['task_id'] as String,
        status: parseTaskStatus(j['status'] as String),
        progress: j['progress'] as int?,
        downloadUrl: (j['download_signed_url'] != null &&
                (j['download_signed_url'] as String).isNotEmpty)
            ? Uri.tryParse(j['download_signed_url'])
            : null,
        error: j['error'] as String?,
      );
}
