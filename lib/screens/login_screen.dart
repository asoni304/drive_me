import 'package:drive_me/screens/register_screen.dart';
import 'package:drive_me/widgets/progress_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../main.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  static const String idScreen = "login";
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailCtrl = TextEditingController();
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
                  height: 350.0,
                alignment: Alignment.center,
              ),

              const Text('Login as a rider',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24),
              ),
              Padding(
                padding:const EdgeInsets.all(20) ,
              child: Column(
                children: [
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
                  GestureDetector(
                    onTap: (){
                      if( emailCtrl.text.isEmpty && passCtrl.text.isEmpty ){
                        displayToastMessage( 'Fields cannot be empty!');
                      }
                      else if(!emailCtrl.text.contains('@')){
                        displayToastMessage( 'Email address is not valid');
                      }
                      else if (passCtrl.text.length<6){
                        displayToastMessage('Password must be at least 6 characters.');
                      }
                      else{
                        loginAndAuthenticateUser(context);
                      }


                    },
                    child: Container(
                      height: 50,
                      width: 200,
                      child: Center(
                        child: Text('Login',style: TextStyle(fontSize: 18),),
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
                      Navigator.pushNamedAndRemoveUntil(context, RegisterScreen.idScreen, (route) => false);
                  },
                  child: Text('Do not have an account?  Register here')),


            ],
          ),
        ),
      ),
    );
  }
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  loginAndAuthenticateUser(BuildContext context)async
  {
    showDialog(
        context: context,
        barrierDismissible: false,

        builder: (BuildContext context){
          return ProgressDialog(message: 'Authenticating ,Please wait...');
        });
    var _firebaseUser = (await _firebaseAuth.signInWithEmailAndPassword(
      email: emailCtrl.text,
      password: passCtrl.text,
    )
        .catchError((errorMsg){
          Navigator.pop(context);
      displayToastMessage("Error: " + errorMsg.toString());
    })
    ).user;

    if(_firebaseUser !=null){

      usersRef.child(_firebaseUser.uid).
    once().then( (event){
      if(event.snapshot.value !=null){
        Navigator.pushNamedAndRemoveUntil(context, MainScreen.idScreen, (route) => false);
        displayToastMessage('You are now logged in');
      }
      else{
        _firebaseAuth.signOut();
        displayToastMessage( 'User does not exist.Create new account.');
      }});
         }
    else{
      Navigator.pop(context);
      //error occurred - display error msg
      displayToastMessage(  'Error occurred,cannot be signed in.');
    }
  }

}
