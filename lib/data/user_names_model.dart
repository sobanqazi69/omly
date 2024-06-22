
class UserNamesModel {

  final String name,email,userId;
  final bool isBlocked;

  UserNamesModel(this.name, this.email,this.userId,this.isBlocked);

  factory UserNamesModel.fromJson(Map<String, dynamic> data ){
    return UserNamesModel(data['name'], data['email'],data['userId'],data.containsKey('isBlocked') && data['isBlocked']);
  }

}