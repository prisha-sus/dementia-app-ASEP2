import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

void main() => runApp(FamilyTreeApp());

class FamilyTreeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Family Tree',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: FamilyTreeScreen(),
    );
  }
}

class FamilyMember {
  final String id;
  final String name;
  final String relation;
  final File image;

  FamilyMember({
    required this.id,
    required this.name,
    required this.relation,
    required this.image,
  });
}

class FamilyTreeScreen extends StatefulWidget {
  @override
  _FamilyTreeScreenState createState() => _FamilyTreeScreenState();
}

class _FamilyTreeScreenState extends State<FamilyTreeScreen> {
  List<FamilyMember> members = [];

  Future<void> _addFamilyMember() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage == null) return;

    final imageFile = File(pickedImage.path);
    final appDir = await getApplicationDocumentsDirectory();
    final savedImage = await imageFile.copy('${appDir.path}/${Uuid().v4()}.png');

    String name = '';
    String relation = '';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Family Member"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: "Name"),
              onChanged: (value) => name = value,
            ),
            TextField(
              decoration: InputDecoration(labelText: "Relation"),
              onChanged: (value) => relation = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (name.isNotEmpty && relation.isNotEmpty) {
                setState(() {
                  members.add(FamilyMember(
                    id: Uuid().v4(),
                    name: name,
                    relation: relation,
                    image: savedImage,
                  ));
                });
              }
              Navigator.of(context).pop();
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(FamilyMember member) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: FileImage(member.image),
          radius: 30,
        ),
        title: Text(member.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        subtitle: Text(member.relation),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Family Tree'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addFamilyMember,
          ),
        ],
      ),
      body: members.isEmpty
          ? Center(child: Text("No family members yet. Tap + to add.", style: TextStyle(fontSize: 16)))
          : ListView.builder(
              itemCount: members.length,
              itemBuilder: (ctx, i) => _buildMemberCard(members[i]),
            ),
    );
  }
}