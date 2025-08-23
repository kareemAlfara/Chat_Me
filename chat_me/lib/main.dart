import 'package:chat_me/src/presentation/cubits/logincubit/login_cubit.dart';
import 'package:chat_me/src/presentation/cubits/meesagescubit/messages_cubit.dart';
import 'package:chat_me/src/presentation/cubits/registercubit/register_cubit.dart';
import 'package:chat_me/src/presentation/screens/wellcome_chatApp.dart';
import 'package:chat_me/src/presentation/screens/friends.dart';
import 'package:chat_me/src/presentation/screens/loginScreen.dart';
import 'package:chat_me/src/presentation/screens/onboading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: "https://hmyngrmjiqpwqcwegjbi.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhteW5ncm1qaXFwd3Fjd2VnamJpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA5Nzk3OTcsImV4cCI6MjA2NjU1NTc5N30.EntAUdipEreHOsYEpL69h0CNFZhLRW_-VJqb0Gs0DqU",
 authOptions: const FlutterAuthClientOptions( 
    autoRefreshToken: true,
    
  ),
  );

  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('user_id');

  runApp(
   MyApp(isLoggedIn: userId != null),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.isLoggedIn});
  final bool isLoggedIn;
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
       BlocProvider(
          create: (context) {
            final cubit = LoginCubit();
            // Always call getAllUser when app starts
            cubit.getAllUser();
            return cubit;
          }
        ),
         BlocProvider(
          create: (context) {
            final cubit = RegisterCubit();
            // Always call getAllUser when app starts
            cubit.getAllusers();
            return cubit;
          }
        ),
        // BlocProvider(create: (context) => MessagesCubit()),
  
      ],
      child: MaterialApp(
        theme: ThemeData.dark(),
        debugShowCheckedModeBanner: false,
        home:
            isLoggedIn
                ? WelcomeScreen()
                : OnboardingScreen(),
      ),
    );
  }
}
