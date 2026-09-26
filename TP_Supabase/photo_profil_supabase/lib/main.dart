import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';

final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (supabase.auth.currentSession == null) {
            return const LoginPage();
          }
          return const ProfilPage();
        },
      ),
    );
  }
}

// Page de connexion simple (reprise de la partie 3 mais avec Supabase)
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailField = TextEditingController();
  final passwordField = TextEditingController();
  String message = '';

  Future<void> seConnecter() async {
    try {
      await supabase.auth.signInWithPassword(
        email: emailField.text.trim(),
        password: passwordField.text.trim(),
      );
    } on AuthException catch (e) {
      setState(() => message = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(30),
        children: [
          TextField(
            controller: emailField,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: passwordField,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Mot de passe'),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: seConnecter,
            child: const Text('Connexion'),
          ),
          Text(message, style: const TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}

class ProfilPage extends StatefulWidget {
  const ProfilPage({Key? key}) : super(key: key);
  @override
  _ProfilPageState createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  File? _image;
  final picker = ImagePicker();
  final String userID = supabase.auth.currentUser!.id;

  Future getImage() async {
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  // Equivalent de putFile() de Firebase Storage
  Future uploadFile() async {
    await supabase.storage.from('photos').upload(
          '$userID.png',
          _image!,
          fileOptions: const FileOptions(upsert: true),
        );
    final url = supabase.storage.from('photos').getPublicUrl('$userID.png');
    // On stocke seulement l'url dans la table profils
    await supabase.from('profils').upsert({'id': userID, 'photo_url': url});
    print('Photo de profil mise à jour');
    refreshPage(context);
  }

  refreshPage(context) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const ProfilPage(),
        transitionDuration: const Duration(seconds: 0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo de profil Supabase'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => supabase.auth.signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              color: Colors.teal,
              child: Column(
                children: [
                  ImagePicture(userID: userID),
                  const SizedBox(height: 15),
                  ProfilTextSection(userID: userID),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _image == null
                ? const Text('No image selected.')
                : SizedBox(height: 150, child: Image.file(_image!)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _image == null ? null : uploadFile,
              child: const Text('Envoyer dans Supabase'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getImage,
        tooltip: 'Pick Image',
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}

class ImagePicture extends StatefulWidget {
  final String userID;
  const ImagePicture({Key? key, required this.userID}) : super(key: key);
  @override
  _ImagePictureState createState() => _ImagePictureState();
}

class _ImagePictureState extends State<ImagePicture> {
  String? userPhotoUrl;

  @override
  void initState() {
    super.initState();
    getProfilImage();
  }

  // On relit l'url dans la table profils (equivalent de getDownloadURL())
  getProfilImage() async {
    final data = await supabase
        .from('profils')
        .select('photo_url')
        .eq('id', widget.userID)
        .maybeSingle();
    if (data != null && data['photo_url'] != null) {
      setState(() {
        // le ?t= evite que l'ancienne photo reste en cache
        userPhotoUrl =
            '${data['photo_url']}?t=${DateTime.now().millisecondsSinceEpoch}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: 200,
      child: CircleAvatar(
        backgroundColor: Colors.grey,
        backgroundImage:
            userPhotoUrl == null ? null : NetworkImage(userPhotoUrl!),
        child: userPhotoUrl == null
            ? const Icon(Icons.person, size: 120, color: Colors.white)
            : null,
      ),
    );
  }
}

// Reprise du widget GetUserData : lit un champ du profil dans la table profils
class GetUserData extends StatelessWidget {
  final String userID;
  final String fieldName;
  final TextStyle fieldStyle;
  const GetUserData({
    Key? key,
    required this.userID,
    required this.fieldName,
    required this.fieldStyle,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: supabase
          .from('profils')
          .select(fieldName)
          .eq('id', userID)
          .maybeSingle(),
      builder: (BuildContext context,
          AsyncSnapshot<Map<String, dynamic>?> snapshot) {
        if (snapshot.hasError) {
          return Text(
            'Un problème est survenu',
            style: fieldStyle,
          );
        }
        if (snapshot.connectionState == ConnectionState.done) {
          Map<String, dynamic>? data = snapshot.data;
          return Text(
            data?[fieldName] ?? '',
            style: fieldStyle,
          );
        }
        return Text(
          'En cours de chargement',
          style: fieldStyle,
        );
      },
    );
  }
}

// Section texte du profil : pseudo, bio et localisation
class ProfilTextSection extends StatelessWidget {
  final String userID;
  const ProfilTextSection({Key? key, required this.userID}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GetUserData(
          userID: userID,
          fieldName: 'pseudo',
          fieldStyle: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        GetUserData(
          userID: userID,
          fieldName: 'bio',
          fieldStyle: const TextStyle(
            color: Colors.white,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_on,
              color: Colors.white,
            ),
            GetUserData(
              userID: userID,
              fieldName: 'location',
              fieldStyle: const TextStyle(
                color: Colors.white,
                fontSize: 17,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
