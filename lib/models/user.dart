import 'package:firebase_database/firebase_database.dart';

class Users{
   String? id;
   String? email;
  String? name;
  String? phone;

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