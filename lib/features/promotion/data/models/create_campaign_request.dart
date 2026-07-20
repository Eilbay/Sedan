class CreateCampaignRequest {
  final String postId;
  final int? packageId;
  final int days;
  final String idempotencyKey;

  const CreateCampaignRequest({
    required this.postId,
    this.packageId,
    required this.days,
    required this.idempotencyKey,
  });

  Map<String, dynamic> toJson() => {
        'post_id': postId,
        'package_id': packageId,
        'days': days,
        'idempotency_key': idempotencyKey,
      };
}
