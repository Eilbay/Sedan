import 'package:optombai/features/try_on/domain/entities/%20try_on_task.dart';

import 'package:optombai/features/try_on/domain/repositories/try_on_repository.dart';


class GetStatus {
  final TryOnRepository repo;
  GetStatus(this.repo);
  Future<TryOnTask> call(String taskId, String token) =>
      repo.getTaskStatus(taskId, token);
}
