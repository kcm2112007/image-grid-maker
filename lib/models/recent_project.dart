/// A saved reference to a past grid creation: the original photo (copied
/// into permanent app storage), and the ratio/grid choices used, so the
/// user can reopen and redo it later.
class RecentProject {
  final String id;
  final String imagePath;
  final String ratioId;
  final String layoutId;
  final int createdAtMillis;

  const RecentProject({
    required this.id,
    required this.imagePath,
    required this.ratioId,
    required this.layoutId,
    required this.createdAtMillis,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'imagePath': imagePath,
        'ratioId': ratioId,
        'layoutId': layoutId,
        'createdAtMillis': createdAtMillis,
      };

  factory RecentProject.fromJson(Map<String, dynamic> json) => RecentProject(
        id: json['id'] as String,
        imagePath: json['imagePath'] as String,
        ratioId: json['ratioId'] as String,
        layoutId: json['layoutId'] as String,
        createdAtMillis: json['createdAtMillis'] as int,
      );
}
