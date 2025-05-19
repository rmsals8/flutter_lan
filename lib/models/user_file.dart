class UserFile {
  final int id;
  final String fileName;
  final String fileType;
  final DateTime createdAt;
  final DateTime expireAt;
  final int fileSize;

  UserFile({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.createdAt,
    required this.expireAt,
    required this.fileSize,
  });

  factory UserFile.fromJson(Map<String, dynamic> json) {
    return UserFile(
      id: json['id'],
      fileName: json['fileName'],
      fileType: json['fileType'],
      createdAt: DateTime.parse(json['createdAt']),
      expireAt: DateTime.parse(json['expireAt']),
      fileSize: json['fileSize'] ?? 0,
    );
  }
}