import 'package:equatable/equatable.dart';

class ImageAboutModel extends Equatable {
  final int id;
  final String user;
  final String file;

  const ImageAboutModel({
    this.id = 0,
    this.user = '',
    required this.file,
  });

  factory ImageAboutModel.fromJson(Map<String, dynamic> json) {
    return ImageAboutModel(
      id: json["id"] ?? 0,
      user: json["user"] ?? '',
      file: json["file"] ?? "",
    );
  }

  ImageAboutModel copyWith({
    int? id,
    String? user,
    String? file,
  }) {
    return ImageAboutModel(
      id: id ?? this.id,
      user: user ?? this.user,
      file: file ?? this.file,
    );
  }

  Map<String, dynamic> toJson() =>
      {"id": id, "user": user, "file": file};

  @override
  List<Object?> get props => [id, user, file];
}

class DocumentImageModel extends Equatable {
  final int id;
  final String user;
  final String file;

  const DocumentImageModel({
    this.id = 0,
    this.user = '',
    required this.file,
  });

  factory DocumentImageModel.fromJson(Map<String, dynamic> json) {
    return DocumentImageModel(
      id: json["id"] ?? 0,
      user: json["user"] ?? '',
      file: json["file"] ?? "",
    );
  }

  DocumentImageModel copyWith({
    int? id,
    String? user,
    String? file,
  }) {
    return DocumentImageModel(
      id: id ?? this.id,
      user: user ?? this.user,
      file: file ?? this.file,
    );
  }

  Map<String, dynamic> toJson() =>
      {"id": id, "user": user, "file": file};

  @override
  List<Object?> get props => [id, user, file];
}
