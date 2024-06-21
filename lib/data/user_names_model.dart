
class UserNamesModel {

  final String name,email,userId;

  UserNamesModel(this.name, this.email,this.userId);

  factory UserNamesModel.fromJson(Map<String, dynamic> data ){
    return UserNamesModel(data['name'], data['email'],data['userId']);
  }

}