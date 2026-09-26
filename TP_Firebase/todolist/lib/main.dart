import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

void main() => runApp(const InitializeApp());

class InitializeApp extends StatelessWidget {
  const InitializeApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const ErrorFirebase();
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return MyApp();
        }
        return const Loading();
      },
    );
  }
}

class ErrorFirebase extends StatelessWidget {
  const ErrorFirebase({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Container(
          color: Colors.white,
          child: const Center(
            child: Text('Erreur de chargement des données'),
          ),
        ),
      ),
    );
  }
}

class Loading extends StatelessWidget {
  const Loading({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Container(
          color: Colors.white,
          child: const Center(
            child: Text('Chargement'),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);
  final databaseReference = FirebaseFirestore.instance;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Firebase Todolist'),
          backgroundColor: Colors.amber,
        ),
        body: Column(
          children: [
            FormSection(),
            Expanded(
              child: ListSection(),
            ),
          ],
        ),
      ),
    );
  }

  void addDataToFirebase() {
    try {
      databaseReference.collection("items").add({
        "text": "Lire un livre pendant 30 minutes",
      }).then((value) {
        print(value.id);
      });
    } catch (e) {
      print(e.toString());
    }
  }
}

class FormSection extends StatelessWidget {
  FormSection({Key? key}) : super(key: key);
  final databaseReference = FirebaseFirestore.instance;
  final myController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.grey.withOpacity(0.1),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: myController,
              decoration: const InputDecoration(
                hintText: 'Entrez une nouvelle tâche',
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 0, 0),
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(5),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.add,
                color: Colors.white,
              ),
              onPressed: () {
                addItem();
              },
            ),
          ),
        ],
      ),
    );
  }

  void addItem() {
    try {
      var now = new DateTime.now();
      var hourAndMinutes = new DateFormat('HH:mm');
      databaseReference.collection("items").add({
        "text": myController.text,
        "time": hourAndMinutes.format(now),
        "done": false,
      }).then((value) {
        print(value.id);
        myController.clear();
      });
    } catch (e) {
      print(e.toString());
    }
  }
}

class ListSection extends StatelessWidget {
  ListSection({Key? key}) : super(key: key);
  final databaseReference = FirebaseFirestore.instance;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: databaseReference.collection('items').snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) return const Text('Loading...');
        return ListView(
          children: snapshot.data!.docs.map((document) {
            return CheckboxListTile(
              title: Text(
                document['text'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(document['time']),
              value: document['done'],
              activeColor: Colors.amber,
              secondary: IconButton(
                icon: Icon(
                  Icons.delete,
                  color: Colors.red.withOpacity(0.6),
                ),
                onPressed: () {
                  deleteItem(document.id);
                },
              ),
              onChanged: (bool? value) {
                print(value);
                updateItem(document.id, value!);
              },
            );
          }).toList(),
        );
      },
    );
  }

  void deleteItem(String itemID) {
    databaseReference.collection("items").doc(itemID).delete();
  }

  void updateItem(String itemID, bool itemDone) {
    databaseReference
        .collection("items")
        .doc(itemID)
        .update({"done": itemDone});
  }
}
