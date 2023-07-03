class GrapchisTemplate {
  int id;
  final String titlegraphics;
  final String namegraphics;
  final String aliasgraphics;
  final String location;
  bool is_circular;
  final String ports;
  GrapchisTemplate({
    required this.id,
    required this.titlegraphics,
    required this.namegraphics,
    required this.aliasgraphics,
    required this.location,
    required this.is_circular,
    required this.ports,
  });

  factory GrapchisTemplate.fromJson(Map<String, dynamic> json) {
    return GrapchisTemplate(
      id: json['id'],
      titlegraphics: json['titlegraphics'],
      namegraphics: json['namegraphics'],
      aliasgraphics: json['aliasgraphics'],
      location: json['location'],
      is_circular: json['is_circular'],
      ports: json['ports'],
    );
  }
}

List<GrapchisTemplate> graphics = [];