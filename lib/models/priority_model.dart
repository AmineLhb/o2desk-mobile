class PriorityModel {
  final int id;
  final String name;
  final String? colorHex;

  PriorityModel({required this.id, required this.name, this.colorHex});

  factory PriorityModel.fromJson(Map<String, dynamic> json) {
    String? color;
    if (json['color'] != null) {
      color = json['color']['text_hex'];
    }
    return PriorityModel(
      id: json['id'] ?? 0,
      name: json['nom_priorite'] ?? json['name'] ?? json['nom'] ?? '',
      colorHex: color,
    );
  }
}