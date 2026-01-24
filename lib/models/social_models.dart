class SocialAccount {
  final int id;
  final String platform;
  final String username;
  final String status; // PENDING, VERIFIED, REJECTED

  SocialAccount({required this.id, required this.platform, required this.username, required this.status});

  factory SocialAccount.fromJson(Map<String, dynamic> json) {
    return SocialAccount(
      id: json['id'],
      platform: json['platform'],
      username: json['username'],
      status: json['status'],
    );
  }
}

class AdvertTask {
  final int taskId;
  final String platform;
  final String content;
  final String? imageUrl;
  final double reward;
  final String status;

  AdvertTask({
    required this.taskId,
    required this.platform,
    required this.content,
    this.imageUrl,
    required this.reward,
    required this.status,
  });
}