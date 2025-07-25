import 'dart:developer';
import 'package:chat_me/src/presentation/cubits/logincubit/login_cubit.dart';
import 'package:chat_me/src/presentation/screens/friends.dart';
import 'package:chat_me/src/presentation/screens/register.dart';
import 'package:chat_me/src/services/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class Loginscreen extends StatelessWidget {
  const Loginscreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginCubit, LoginState>(
      listener: (context, state) async {
        if (state is getUserSuccessState) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => FriendsScreen()),
          );
          // navigat(context, widget: FriendsScreen());
          await saveUserIdToPrefs();
          print("uid $uid");
          print("uid $uid");
          print("uid $uid");
        } else if (state is getUserFailureState) {
          log(state.error);
        }
      },
      builder: (context, state) {
        var cubit = LoginCubit.get(context);
        return Scaffold(
          backgroundColor: Primarycolor,
          appBar: AppBar(
            backgroundColor: Primarycolor,
            centerTitle: true,
            title: defulttext(data: "Chat App"),
          ),
          body: Form(
            key: cubit.formkey,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 33),

                  defulttext(data: "Login", fSize: 26),
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

                      icon:
                          cubit.isscure
                              ? Icon(Icons.visibility, color: Colors.white)
                              : Icon(Icons.visibility_off, color: Colors.white),
                    ),
                    title: "Password",
                    textInputAction: TextInputAction.done,
                  ),
                  SizedBox(height: 33),

                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      onPressed: () {
                        if (cubit.formkey.currentState!.validate()) {
                          cubit.getUser(
                            Email: cubit.emailcontroller.text,
                            password: cubit.passcontroller.text,
                          );
                        }
                      },
                      child:
                          state is getUserloadingState
                              ? Center(child: CircularProgressIndicator())
                              : defulttext(data: "  Login  ", fSize: 18),
                    ),
                  ),
                  SizedBox(height: 33),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      defulttext(data: "Donot Have Any Accounts "),
                      TextButton(
                        onPressed: () {
                          navigat(context, widget: RegisterScreen());
                        },
                        child: defulttext(
                          data: "Sign up",
                          color: Colors.blue,
                          fSize: 17,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
