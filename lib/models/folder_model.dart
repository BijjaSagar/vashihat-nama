class FolderModel {
  final int id;
  final int userId;
  final String folderName;

  FolderModel({required this.id, required this.userId, required this.folderName});

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    return FolderModel(
      id: json['id'],
      userId: json['user_id'],
      folderName: json['folder_name'],
    );
  }
}
