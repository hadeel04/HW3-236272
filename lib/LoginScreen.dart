import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hello_me/auth_repository.dart';





class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  @override
  Widget build(BuildContext context) {
    final firebaseUser = Provider.of<AuthRepository>(context);
    TextEditingController emailController = TextEditingController();
    TextEditingController passwordController = TextEditingController();
    TextEditingController confirmController = TextEditingController();
    bool _validate = true;
    final login_error_snackBar = SnackBar(
        content: Text('There  was  an  error  logging into  the  app'));
    final signup_error_snackBar = SnackBar(
        content: Text('There  was  an  error  signning into  the  app'));

    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            'Login',
            textAlign: TextAlign.center,
          ),
        ),
        body: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              //crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  '\nWelcome to Startup Names Generator,'
                      ' please log in below\n',
                  style: TextStyle(fontSize: 18.0),),

                // Email Field
                TextField(
                  controller: emailController,
                  obscureText: false,
                  //style: style,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(
                        20.0, 20.0, 20.0, 20.0),
                    hintText: "Email",
                  ),
                ),

                SizedBox(height: 20.0),

                // Password Field
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  //style: style,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(
                        20.0, 20.0, 20.0, 20.0),
                    hintText: "Password",
                  ),
                ),

                SizedBox(height: 25.0),

                firebaseUser.status == Status.Authenticating
                    ? Center(child: CircularProgressIndicator())
                    : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Material(
                          borderRadius: BorderRadius.circular(35.0),
                          color: Colors.deepPurple,
                          child: MaterialButton(
                            minWidth: MediaQuery
                                .of(context).size.width,
                            padding: const EdgeInsets.fromLTRB(
                                20.0, 20.0, 20.0, 20.0),
                            onPressed: () async {
                              bool res = await firebaseUser.signIn(
                                  emailController.text.trim(),
                                  passwordController.text.trim());
                              if (!res) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    login_error_snackBar);
                              } else {
                                Navigator.pop(context);
                              }
                            },
                            child: const Text('Log in',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 24.0, color: Colors.black),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child:Material(
                            borderRadius: BorderRadius.circular(30.0),
                            color: Colors.blue,
                            child: MaterialButton(
                              minWidth: MediaQuery
                                  .of(context)
                                  .size
                                  .width,
                              padding: const EdgeInsets.fromLTRB(
                                  20.0, 20.0, 20.0, 20.0),
                              onPressed: () async {
                                showModalBottomSheet<void>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AnimatedPadding(
                                          padding: MediaQuery
                                              .of(context)
                                              .viewInsets,
                                          duration: const Duration(milliseconds: 2),
                                          child:
                                          Container(
                                            height: 200,
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: <Widget>[
                                                const Text(
                                                    'Please confirm your password below:'),
                                                TextField(
                                                  controller: confirmController,
                                                  obscureText: true,
                                                  //style: style,
                                                  decoration: InputDecoration(
                                                    contentPadding: EdgeInsets.fromLTRB(
                                                        20.0, 20.0, 20.0, 20.0),
                                                    hintText: "password",
                                                    errorText: (!_validate) ? 'Passwords must  match' : null,
                                                  ),
                                                ),
                                                ElevatedButton(
                                                    child: const Text('confirm'),
                                                    onPressed: () {
                                                      if(confirmController.text == passwordController.text){
                                                        // the passwords match then sign up
                                                        firebaseUser.signUp(
                                                            emailController.text.trim(),
                                                            passwordController.text.trim());
                                                        Navigator.pop(context);
                                                        Navigator.pop(context);
                                                      }else{
                                                        setState(() {
                                                          _validate = false;
                                                          FocusScope.of(context).unfocus();
                                                        });
                                                      }
                                                    }
                                                )
                                              ],
                                            ),
                                          )
                                      );
                                    }
                                );
                              },
                              child: const Text('New user?  Click  to  sign  up',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 18.0, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                ),
              ],
            )
        )
    );
  }
}