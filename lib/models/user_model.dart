class UserModel {
  String userId;
  String email;
  String name;
  String role;
  String username;
  String image;

  UserModel({
    required this.userId,
    required this.image,
    required this.email,
    required this.name,
    required this.role,
    required this.username,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      userId: data['userId'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? '',
       image: data['image'] ?? '',
      username: data['username'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'name': name,
      'role': role,
      'username': username,
      'image': image
    };
  }
}


class UserData {
  static final UserData _instance = UserData._internal();
  UserModel? currentUser;

  factory UserData() {
    return _instance;
  }

  UserData._internal();
}

final userData = UserData();
