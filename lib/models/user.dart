import 'package:firebase_database/firebase_database.dart';

class Users{
  late String id;
  late String email;
  late String name;
  late String phone;

  Users({required this.phone,required this.id,required this.name,required this.email});

  Users.fromSnapshot(DataSnapshot dataSnapshot) {
    id = dataSnapshot.key!;
    var data = dataSnapshot.value as Map?;

    if(data != null){
      email = data!["email"];
      name = data?["name"];
      phone = data?["phone"];
    }



  }
}