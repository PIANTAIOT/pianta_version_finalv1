class Locationes {
  String? locationes;

  Locationes({
    String? location,
  }) : locationes = location;

//{"pk":2,"username":"","email":"example1@gmail.com","first_name":"First","last_name":"Last"}
  factory Locationes.fromJson(dynamic json) {
    print(json);
    List<dynamic> jsonData = json as List<dynamic>;
    if (jsonData.isNotEmpty) {
      Map<String, dynamic> firstItem = jsonData.first as Map<String, dynamic>;
      String location = firstItem['location'] as String;
      return Locationes(
        location: location,
      );
    } else {
      return Locationes(location: null);
    }
  }

  split(String s) {}
}

class LocationeDevice {
  String? location;

  LocationeDevice({
    this.location,
  });

  factory LocationeDevice.fromJson(dynamic json) {
    if (json is List && json.isNotEmpty) {
      Map<String, dynamic> firstItem = json[0] as Map<String, dynamic>;
      String location = firstItem['location'] as String;
      return LocationeDevice(
        location: location,
      );
    } else {
      return LocationeDevice(location: null);
    }
  }
}