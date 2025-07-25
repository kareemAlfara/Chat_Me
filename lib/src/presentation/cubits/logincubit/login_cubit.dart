import 'package:bloc/bloc.dart';

import 'package:chat_me/src/data/models/usersmodel.dart';
import 'package:chat_me/src/services/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(LoginInitial());
  static LoginCubit get(context) => BlocProvider.of(context);
  var formkey = GlobalKey<FormState>();
  var emailcontroller = TextEditingController();
  var passcontroller = TextEditingController();
  bool isscure = true;
  void PassowrdMethod() {
    isscure = !isscure;
    emit(PassowrdMethodState());
  }

  Future<void> getUser({
    required String Email,
    required String password,
  }) async {
    emit(getUserloadingState());
    await Supabase.instance.client.auth
        .signInWithPassword(password: password, email: Email)
        .then((value) {
          uid = Supabase.instance.client.auth.currentUser!.id;
          print(uid);
          print("success");
          emit(getUserSuccessState());
        })
        .catchError((e) {
          print(e.toString());
          emit(getUserFailureState(error: e.toString()));
        });
  }

  List<Usersmodel> userslist = [];

  Future<void> getAllUser() async {
    try {
      emit(getAllUsersLoadingState());
      await Supabase.instance.client.from('users').stream(primaryKey: ['id'])
      // .eq('sender_id', uid!) // Use your primary key    (filter by sender in subscribeToMessages)
      .listen((List<Map<String, dynamic>> userslist) {
        this.userslist.clear(); // Optional: clear existing data
        for (var row in userslist) {
          this.userslist.add(
            Usersmodel.fromJson(row),
          ); // Ensure fromJson is implemented
        }
        print("all users success");

        emit(getAllUsersSuccessState());
      });
    } on Exception catch (error) {
      // TODO
      print("error is  $error");
      emit(getAllUsersFailureState(error: error.toString()));
    }
  }

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');

    await Supabase.instance.client.auth.signOut();
  }
}
