import 'dart:developer';
import 'package:chat_me/src/presentation/cubits/registercubit/register_cubit.dart';
import 'package:chat_me/src/presentation/screens/friends.dart';
import 'package:chat_me/src/presentation/screens/loginScreen.dart';
import 'package:chat_me/src/services/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RegisterCubit()..getAllusers(),
      child: BlocConsumer<RegisterCubit, RegisterState>(
        builder: (context, state) {
          var cubit = RegisterCubit.get(context);
          final List<List<Color>> bgColors = [
            [Colors.blue.shade700, Colors.purple.shade400],
            [Colors.pink.shade500, Colors.orange.shade300],
            [Colors.green.shade500, Colors.blue.shade300],
          ];

          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.blue.shade700,
              centerTitle: true,
              title: defulttext(data: "Chat App"),
            ),
            body: Container(
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: bgColors[0],
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Form(
                    key: cubit.formkey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 11),

                        defulttext(data: "Register", fSize: 26),
                        SizedBox(height: 22),
                        defulitTextFormField(
                          controller: cubit.emailcontroller,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "please inter ther Email";
                            }
                            return null;
                          },
                          title: "Email",
                          textInputAction: TextInputAction.next,
                        ),
                        SizedBox(height: 22),
                        defulitTextFormField(
                          isobscure: cubit.isscure,
                          controller: cubit.passcontroller,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "please inter ther password";
                            }
                            return null;
                          },
                          suffixIcon: IconButton(
                            onPressed: () {
                              cubit.PassowrdMethod();
                            },

                            icon: cubit.isscure
                                ? Icon(Icons.visibility, color: Colors.white)
                                : Icon(
                                    Icons.visibility_off,
                                    color: Colors.white,
                                  ),
                          ),
                          title: "Password",
                          textInputAction: TextInputAction.next,
                        ),
                        SizedBox(height: 22),
                        defulitTextFormField(
                          controller: cubit.namecontroller,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "please inter ther name";
                            }
                            return null;
                          },
                          title: "Name",
                          textInputAction: TextInputAction.next,
                        ),
                        SizedBox(height: 22),
                        defulitTextFormField(
                          controller: cubit.imagecontroller,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "please inter ther image";
                            }
                            return null;
                          },
                          title: "image",
                          textInputAction: TextInputAction.done,
                        ),
                        SizedBox(height: 22),
                        Center(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                            onPressed: () {
                              if (cubit.formkey.currentState!.validate()) {
                                cubit.createUser(
                                  Email: cubit.emailcontroller.text,
                                  name: cubit.namecontroller.text,
                                  password: cubit.passcontroller.text,
                                  image: cubit.imagecontroller.text,
                                );
                              }
                            },
                            child: state is createUserLoadingState
                                ? Center(child: CircularProgressIndicator())
                                : defulttext(data: "  Sign up  ", fSize: 18),
                          ),
                        ),
                        SizedBox(height: 33),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            defulttext(data: "I Have an Account"),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Loginscreen(),
                                  ),
                                );
                              
                              },
                              child: defulttext(
                                data: "login",
                                color: Colors.lightBlueAccent,
                                fSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        listener: (context, state) {
          if (state is createUsersuccessState) {
            navigat(context, widget: FriendsScreen());
          } else if (state is createUserFailureState) {
            log(state.error);
          }
        },
      ),
    );
  }
}
