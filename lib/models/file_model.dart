class FileModel {
  final int id;
  final int folderId;
  final String fileName;
  final String fileType;
  final String filePath;

  FileModel({required this.id, required this.folderId, required this.fileName, required this.fileType, required this.filePath});

  factory FileModel.fromJson(Map<String, dynamic> json) {
    return FileModel(
      id: json['id'],
      folderId: json['folder_id'],
      fileName: json['file_name'],
      fileType: json['file_type'],
      filePath: json['file_path'],
    );
  }
}
