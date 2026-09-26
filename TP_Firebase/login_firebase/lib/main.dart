import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';

FirebaseAuth auth = FirebaseAuth.instance;
FirebaseFirestore firestore = FirebaseFirestore.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  auth.authStateChanges().listen((User? user) {
    if (user == null) {
      print('Utilisateur non connecté');
      runApp(const LoginTabBar());
    } else {
      print('Utilisateur connecté: ' + user.email!);
      runApp(const HomePage());
    }
  });
}

class LoginTabBar extends StatelessWidget {
  const LoginTabBar({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Page de connexion'),
            backgroundColor: Colors.amber,
            bottom: const TabBar(
              labelColor: Colors.black,
              indicatorColor: Colors.black,
              tabs: [
                Tab(text: 'Connexion'),
                Tab(text: 'Inscription'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              LoginSection(),
              SignUpSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginSection extends StatelessWidget {
  LoginSection({Key? key}) : super(key: key);
  final emailField = TextEditingController();
  final passwordField = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(30),
      children: [
        const Icon(Icons.lock_outline, size: 80, color: Colors.amber),
        const SizedBox(height: 20),
        TextField(
          controller: emailField,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email),
          ),
        ),
        TextField(
          controller: passwordField,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Mot de passe',
            prefixIcon: Icon(Icons.lock),
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
          child: const Text(
            "Connexion",
            style: TextStyle(color: Colors.black),
          ),
          onPressed: () {
            loginToFirebase();
          },
        ),
      ],
    );
  }

  void loginToFirebase() {
    print(emailField.text.trim());
    print(passwordField.text.trim());
    try {
      auth
          .signInWithEmailAndPassword(
              email: emailField.text.trim(),
              password: passwordField.text.trim())
          .then((value) {
        print(value.toString());
      });
    } catch (e) {
      print(e.toString());
    }
  }
}

class SignUpSection extends StatelessWidget {
  SignUpSection({Key? key}) : super(key: key);
  final emailField = TextEditingController();
  final passwordField = TextEditingController();
  final pseudoField = TextEditingController();
  final birthdateField = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(30),
      children: [
        TextField(
          controller: pseudoField,
          decoration: const InputDecoration(
            labelText: 'Pseudo',
            prefixIcon: Icon(Icons.person),
          ),
        ),
        TextField(
          controller: birthdateField,
          decoration: const InputDecoration(
            labelText: 'Date de naissance',
            prefixIcon: Icon(Icons.cake),
          ),
        ),
        TextField(
          controller: emailField,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email),
          ),
        ),
        TextField(
          controller: passwordField,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Mot de passe',
            prefixIcon: Icon(Icons.lock),
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
          child: const Text(
            "Inscription",
            style: TextStyle(color: Colors.black),
          ),
          onPressed: () {
            signUpToFirebase();
          },
        ),
      ],
    );
  }

  void signUpToFirebase() {
    print(emailField.text.trim());
    print(passwordField.text.trim());
    try {
      auth
          .createUserWithEmailAndPassword(
        email: emailField.text.trim(),
        password: passwordField.text.trim(),
      )
          .then((value) {
        print(value.user!.uid);
        addUser(
          value.user!.uid,
          pseudoField.text.trim(),
          birthdateField.text.trim(),
        );
      });
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> addUser(String userID, String pseudo, String birthdate) {
    return firestore
        .collection('Users')
        .doc(userID)
        .set({
          'pseudo': pseudo,
          'birthdate': birthdate,
        })
        .then((value) => print("Utilisateur ajouté"))
        .catchError(
          (error) => print("Erreur: $error"),
        );
  }
}
