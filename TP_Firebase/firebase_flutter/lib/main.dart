import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Firebase',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  _HomePageState createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Firebase'),
        backgroundColor: Colors.amber,
      ),
      body: Center(
        child: FirebaseMessage(),
      ),
    );
  }
}

class FirebaseMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    CollectionReference users =
        FirebaseFirestore.instance.collection('message');
    return FutureBuilder<DocumentSnapshot>(
      future: users.doc('success').get(),
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text("Quelque chose s'est mal passé");
        }
        if (snapshot.hasData && !snapshot.data!.exists) {
          return Text("Le document n'existe pas");
        }
        if (snapshot.connectionState == ConnectionState.done) {
          Map<String, dynamic> data =
              snapshot.data!.data() as Map<String, dynamic>;
          return MessageDesign(
            titleMessage: data["title"],
            subtitleMessage: data["sub_title"],
            textMessage: data["text"],
          );
        }
        return Text("Chargement en cours");
      },
    );
  }
}

class MessageDesign extends StatelessWidget {
  final String titleMessage;
  final String subtitleMessage;
  final String textMessage;
  const MessageDesign(
      {Key? key,
      required this.titleMessage,
      required this.textMessage,
      required this.subtitleMessage})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(30),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 200,
            width: 200,
            child: Image.network(
                'https://www.gstatic.com/mobilesdk/240501_mobilesdk/firebase_28dp.png',
                fit: BoxFit.contain),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.done, size: 50, color: Colors.green),
              SizedBox(width: 10),
              Text(
                titleMessage,
                style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
              )
            ],
          ),
          SizedBox(height: 20),
          Text(
            subtitleMessage,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 20),
          Text(
            textMessage,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w300),
          ),
          SizedBox(height: 100),
        ],
      ),
    );
  }
}
