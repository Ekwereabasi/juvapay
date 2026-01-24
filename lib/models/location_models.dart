
class StateModel {
  final int id;
  final String name;

  StateModel({required this.id, required this.name});

  factory StateModel.fromJson(Map<String, dynamic> json) {
    return StateModel(id: json['id'] as int, name: json['name'] as String);
  }
}

class LgaModel {
  final int id;
  final int stateId;
  final String name;

  LgaModel({required this.id, required this.stateId, required this.name});

  factory LgaModel.fromJson(Map<String, dynamic> json) {
    return LgaModel(
      id: json['id'] as int,
      stateId: json['state_id'] as int,
      name: json['name'] as String,
    );
  }
}


