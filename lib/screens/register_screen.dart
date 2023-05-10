import 'package:drive_me/main.dart';
import 'package:drive_me/screens/login_screen.dart';
import 'package:drive_me/screens/main_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../widgets/progress_dialog.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  static const String idScreen = "register";
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
TextEditingController nameCtrl = TextEditingController();
TextEditingController emailCtrl = TextEditingController();
TextEditingController phoneCtrl = TextEditingController();
TextEditingController passCtrl = TextEditingController();

displayToastMessage(String message){
  Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 5,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0
  );
}


  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const SizedBox(height: 35,),
              const Image(
                image:AssetImage('images/logo.png') ,
                width: 400.0,
                height: 250.0,
                alignment: Alignment.center,
              ),

              const Text('Register as a rider',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24),
              ),
              Padding(
                padding:const EdgeInsets.all(20) ,
                child: Column(
                  children: [
                     TextField(
                      controller: nameCtrl,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                          labelText: 'Name',
                          labelStyle: TextStyle(fontSize: 14),
                          hintStyle: TextStyle(color: Colors.grey,fontSize: 10)
                      ),
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 1,),
                     TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(fontSize: 14),
                          hintStyle: TextStyle(color: Colors.grey,fontSize: 10)
                      ),
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 1,),
                     TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                          labelText: 'Phone',
                          labelStyle: TextStyle(fontSize: 14),
                          hintStyle: TextStyle(color: Colors.grey,fontSize: 10)
                      ),
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 1,),
                     TextField(
                       controller: passCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(fontSize: 14),
                          hintStyle: TextStyle(color: Colors.grey,fontSize: 10)
                      ),
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 30,),
                    InkWell(
                      onTap: (){
                        if(nameCtrl.text.isEmpty && emailCtrl.text.isEmpty && passCtrl.text.isEmpty && phoneCtrl.text.isEmpty){
                          displayToastMessage( 'Fields cannot be empty!');
                        }
                        else if(nameCtrl.text.length <3 || nameCtrl.text.isEmpty){
                          displayToastMessage( 'Name must be at least 3 characters.');
                        }
                        else if(!emailCtrl.text.contains('@')){
                          displayToastMessage( 'Email address is not valid');
                        }
                        else if(phoneCtrl.text.isEmpty){
                          displayToastMessage('Phone number is mandatory');
                        }
                        else if (passCtrl.text.length<6){
                          displayToastMessage('Password must be at least 6 characters.');
                        }
                        else{
                          registerNewUser(context);
                        }

                      },
                      child: Container(
                        height: 50,
                        width: 200,
                        child: Center(
                          child: Text('Register',style: TextStyle(fontSize: 18),),
                        ),
                        decoration: BoxDecoration(
                            color: Colors.yellow,
                            borderRadius: BorderRadius.circular(22)
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                  onPressed: (){
                    Navigator.pushNamedAndRemoveUntil(context, LoginScreen.idScreen, (route) => false);
                  },
                  child: Text('Already have an account?  Log in.')),


            ],
          ),
        ),
      ),
    );
  }

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
registerNewUser(BuildContext context)async{
  showDialog(
      context: context,
      barrierDismissible: false,

      builder: (BuildContext context){
        return ProgressDialog(message: 'Registering new user , Please wait ...');
      });
 var _firebaseUser = (await _firebaseAuth.
createUserWithEmailAndPassword(
    email: emailCtrl.text,
    password: passCtrl.text,
)
     .catchError((errorMsg){
       Navigator.pop(context);
   displayToastMessage("Error: " + errorMsg.toString());
 })
 )
     .user;

 if(_firebaseUser !=null){
   //save info to db
   usersRef.child(_firebaseUser.uid);
   Map userData =
   {
     "name": nameCtrl.text.trim(),
     "email":emailCtrl.text.trim(),
     "phone": phoneCtrl.text.trim(),
   };
   usersRef.child(_firebaseUser.uid) .set(userData);
   displayToastMessage(  'Your account has been successfully created.');
   Navigator.pushNamedAndRemoveUntil(context, MainScreen.idScreen, (route) => false);
 }
 else{
   Navigator.pop(context);
   //error occurred - display error msg
displayToastMessage(  'New user account has not been created');
 }
}



}
