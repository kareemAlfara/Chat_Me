import 'package:bloc/bloc.dart';
import 'package:chat_me/src/data/models/usersmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

part 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit() : super(RegisterInitial());
  static RegisterCubit get(context) => BlocProvider.of(context);
  var formkey = GlobalKey<FormState>();
  var emailcontroller = TextEditingController();
  var passcontroller = TextEditingController();
  var namecontroller = TextEditingController();
  var imagecontroller = TextEditingController();
  bool isscure = true;
  void PassowrdMethod() {
    isscure = !isscure;
    emit(PassowrdMethodState());
  }

  createUser({
    required String Email,
    required String name,
    required String password,
    required String image,
  }) async {
    try {
      emit(createUserLoadingState());
          // final cleanEmail = Email.trim(); // تنظيف البريد

      final response = await Supabase.instance.client.auth.signUp(
        password: password,
        email: Email,
      );
      
      if (response.user != null) {
        await Supabase.instance.client.from("users").insert({
          'user_uid': response.user!.id, // Supabase auth ID
          'email': Email,
          'name': name,
          'image': image,
          "password": password,
        });
      }
        print("success");
      print("success");
      emit(createUsersuccessState());
    } on Exception catch (e) {
      // TODO
      print(e.toString());
      emit(createUserFailureState(error: e.toString()));
    }
  }
  List<Usersmodel>userslist=[];
  getAllusers()async{
   try {
  await Supabase.instance.client.from("users").stream(primaryKey: ['id'])
  .order('created_at').listen((List<Map<String, dynamic>> userslist) {
           this.userslist.clear(); // Optional: clear existing data
           for (var row in userslist) {
             this.userslist.add(
               Usersmodel.fromJson(row),
             ); // Ensure fromJson is implemented
           }
           print("object");
           print("object");
           print("object");
           emit(getAllUsersSuccessState());
         });
} on Exception catch (e) {
  emit(getAllUsersFailureState(error: e.toString()));
}
  }
}
