import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  runApp(const MyApp());
}

// Raccourci utilisé dans toute l'application
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Carnet de contacts',
      theme: ThemeData(colorSchemeSeed: Colors.green),
      home: StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = supabase.auth.currentSession;
          print(session != null ? 'Connecté' : 'Déconnecté');
          if (session == null) {
            return const LoginPage();
          }
          return const ContactsPage();
        },
      ),
    );
  }
}

// ---------------- Authentification ----------------

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailField = TextEditingController();
  final passwordField = TextEditingController();
  String message = '';

  Future<void> inscrire() async {
    try {
      await supabase.auth.signUp(
        email: emailField.text.trim(),
        password: passwordField.text.trim(),
      );
    } on AuthException catch (e) {
      setState(() => message = e.message);
    }
  }

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
        title: const Text('Connexion Supabase'),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: const EdgeInsets.all(30),
        children: [
          const Icon(Icons.contacts, size: 80, color: Colors.green),
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
            onPressed: seConnecter,
            child: const Text('Connexion'),
          ),
          OutlinedButton(
            onPressed: inscrire,
            child: const Text('Inscription'),
          ),
          const SizedBox(height: 20),
          Text(message, style: const TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}

// ---------------- Contacts (CRUD + temps réel) ----------------

class ContactsPage extends StatefulWidget {
  const ContactsPage({Key? key}) : super(key: key);
  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  // Niveau 4 : flux temps réel de la table contacts
  final contactsStream =
      supabase.from('contacts').stream(primaryKey: ['id']).order('nom');
  List<Map<String, dynamic>> groupes = [];

  @override
  void initState() {
    super.initState();
    chargerGroupes();
  }

  Future<void> chargerGroupes() async {
    final data = await supabase.from('groupes').select().order('nom');
    setState(() => groupes = data);
  }

  String nomDuGroupe(dynamic id) {
    for (final g in groupes) {
      if (g['id'] == id) return g['nom'];
    }
    return 'Sans groupe';
  }

  // CREATE
  Future<void> ajouterContact(
      String nom, String telephone, int age, int? groupeId) async {
    await supabase.from('contacts').insert({
      'nom': nom,
      'telephone': telephone,
      'age': age,
      'groupe_id': groupeId,
      'proprietaire': supabase.auth.currentUser!.id,
    });
  }

  // UPDATE
  Future<void> modifierAge(String id, int nouvelAge) async {
    await supabase.from('contacts').update({'age': nouvelAge}).eq('id', id);
  }

  // DELETE
  Future<void> supprimerContact(String id) async {
    await supabase.from('contacts').delete().eq('id', id);
  }

  // Niveau 5 : appel de l'Edge Function
  Future<void> afficherStatistique() async {
    final reponse = await supabase.functions.invoke('contacts-majeurs');
    print(reponse.data);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistique (Edge Function)'),
        content: Text(
            'Contacts majeurs : ${reponse.data['majeurs']} / ${reponse.data['total']}'),
      ),
    );
  }

  void formulaireContact({Map<String, dynamic>? contact}) {
    final nomField = TextEditingController(text: contact?['nom']);
    final telField = TextEditingController(text: contact?['telephone']);
    final ageField =
        TextEditingController(text: contact?['age']?.toString() ?? '');
    int? groupeChoisi = contact?['groupe_id'];
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(contact == null ? 'Nouveau contact' : 'Modifier l\'âge'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (contact == null) ...[
                TextField(
                    controller: nomField,
                    decoration: const InputDecoration(labelText: 'Nom')),
                TextField(
                    controller: telField,
                    decoration: const InputDecoration(labelText: 'Téléphone')),
              ],
              TextField(
                  controller: ageField,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Âge')),
              if (contact == null)
                DropdownButton<int?>(
                  value: groupeChoisi,
                  hint: const Text('Groupe'),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Sans groupe')),
                    ...groupes.map((g) =>
                        DropdownMenuItem(value: g['id'] as int, child: Text(g['nom']))),
                  ],
                  onChanged: (v) => setDialogState(() => groupeChoisi = v),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final age = int.tryParse(ageField.text.trim()) ?? 0;
                if (contact == null) {
                  ajouterContact(nomField.text.trim(), telField.text.trim(),
                      age, groupeChoisi);
                } else {
                  modifierAge(contact['id'], age);
                }
                Navigator.pop(context);
              },
              child: const Text('Valider'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes contacts'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            tooltip: 'Groupes',
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const GroupesPage()));
              chargerGroupes();
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Statistique',
            onPressed: afficherStatistique,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => supabase.auth.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text('Connecté : ${supabase.auth.currentUser?.email}'),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: contactsStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final contacts = snapshot.data!;
                if (contacts.isEmpty) {
                  return const Center(child: Text('Aucun contact'));
                }
                return ListView.builder(
                  itemCount: contacts.length,
                  itemBuilder: (context, i) => ListTile(
                    leading: CircleAvatar(child: Text(contacts[i]['nom'][0])),
                    title: Text(contacts[i]['nom']),
                    subtitle: Text(
                        '${contacts[i]['telephone']} - ${contacts[i]['age']} ans - ${nomDuGroupe(contacts[i]['groupe_id'])}'),
                    onTap: () => formulaireContact(contact: contacts[i]),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => supprimerContact(contacts[i]['id']),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => formulaireContact(),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

// ---------------- Groupes (niveau 2 : jointure) ----------------

class GroupesPage extends StatefulWidget {
  const GroupesPage({Key? key}) : super(key: key);
  @override
  State<GroupesPage> createState() => _GroupesPageState();
}

class _GroupesPageState extends State<GroupesPage> {
  final nomField = TextEditingController();
  List<Map<String, dynamic>> groupes = [];

  @override
  void initState() {
    super.initState();
    chargerGroupes();
  }

  // Jointure : chaque groupe avec ses contacts
  Future<void> chargerGroupes() async {
    final data =
        await supabase.from('groupes').select('id, nom, contacts(nom, age)');
    setState(() => groupes = data);
  }

  Future<void> ajouterGroupe() async {
    await supabase.from('groupes').insert({
      'nom': nomField.text.trim(),
      'proprietaire': supabase.auth.currentUser!.id,
    });
    nomField.clear();
    chargerGroupes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groupes'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.grey.withOpacity(0.1),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nomField,
                    decoration:
                        const InputDecoration(hintText: 'Nom du groupe'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: ajouterGroupe,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: groupes.map((g) {
                final membres = g['contacts'] as List;
                return ExpansionTile(
                  initiallyExpanded: true,
                  leading: const Icon(Icons.group),
                  title: Text(g['nom'],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${membres.length} contact(s)'),
                  children: membres
                      .map((c) => ListTile(
                            dense: true,
                            title: Text(c['nom']),
                            trailing: Text('${c['age']} ans'),
                          ))
                      .toList(),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
