class NomineeModel {
  final int id;
  final int userId;
  final String name;
  final String email;
  final String phone;
  final String relation;

  NomineeModel({required this.id, required this.userId, required this.name, required this.email, required this.phone, required this.relation});

  factory NomineeModel.fromJson(Map<String, dynamic> json) {
    return NomineeModel(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      email: json['email'],
      phone: json['mobile'],
      relation: json['relation'],
    );
  }
}
