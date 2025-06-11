import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:graphview/GraphView.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:mytestapp/flutter_gen/gen_l10n/app_localizations.dart';

// Add your ImgBB API key here - you'll need to register at https://api.imgbb.com/
const String IMGBB_API_KEY = 'ae07899cbeb3f0f95743db787f6b613e';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(FamilyTreeApp());
}

class FamilyTreeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final local = Localizations.of(context, AppLocalizations);
    return MaterialApp(
      title: local.familyTree,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FamilyTreeScreen(),
    );
  }
}

class FamilyMember {
  final String id;
  final String name;
  final String relation;
  final String imageUrl;
  final String? parentId;
  final DateTime dateAdded;

  FamilyMember({
    required this.id,
    required this.name,
    required this.relation,
    required this.imageUrl,
    this.parentId,
    DateTime? dateAdded,
  }) : dateAdded = dateAdded ?? DateTime.now();

  factory FamilyMember.fromMap(Map<String, dynamic> data) {
    return FamilyMember(
      id: data['id'],
      name: data['name'],
      relation: data['relation'],
      imageUrl: data['imageUrl'],
      parentId: data['parentId'],
      dateAdded: data['dateAdded'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['dateAdded'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'relation': relation,
      'imageUrl': imageUrl,
      'parentId': parentId,
      'dateAdded': dateAdded.millisecondsSinceEpoch,
    };
  }
}

class FamilyTreeScreen extends StatefulWidget {
  @override
  _FamilyTreeScreenState createState() => _FamilyTreeScreenState();
}

class _FamilyTreeScreenState extends State<FamilyTreeScreen> {
  List<FamilyMember> members = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = 'current_user'; // This would be from auth in a real app
  bool _isLoading = true;
  String? _selectedParentId;
  bool _showListView = false;

  // Graph configuration
  Graph graph = Graph()..isTree = true;
  BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();

  @override
  void initState() {
    super.initState();
    _setupGraphBuilder();
    _loadFamilyMembers();
  }

  void _setupGraphBuilder() {
    builder
      ..siblingSeparation = (100)
      ..levelSeparation = (150)
      ..subtreeSeparation = (150)
      ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM);
  }

  Future<void> _loadFamilyMembers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('family-members')
          .get();

      final loadedMembers = snapshot.docs
          .map((doc) => FamilyMember.fromMap(doc.data()))
          .toList();

      setState(() {
        members = loadedMembers;
        _buildFamilyTreeGraph();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load family members: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _buildFamilyTreeGraph() {
    graph = Graph()..isTree = true;
    
    if (members.isEmpty) return;

    // Create nodes for each family member
    Map<String, Node> nodeMap = {};
    for (FamilyMember member in members) {
      Node node = Node.Id(member.id);
      nodeMap[member.id] = node;
      graph.addNode(node);
    }

    // Create edges based on parent-child relationships
    for (FamilyMember member in members) {
      if (member.parentId != null && nodeMap.containsKey(member.parentId)) {
        graph.addEdge(nodeMap[member.parentId]!, nodeMap[member.id]!);
      }
    }
  }

Future<void> _addFamilyMember() async {
  final local = Localizations.of(context, AppLocalizations);
  final pickedImage = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    imageQuality: 80,
  );

  if (pickedImage == null) return;

  final imageFile = File(pickedImage.path);
  String name = '';
  String relation = '';
  String? parentId = _selectedParentId;

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(local.addFamilyMember),
      content: StatefulBuilder(
        builder: (context, setStateDialog) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  backgroundImage: FileImage(imageFile),
                  radius: 50,
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(labelText: local.name),
                  onChanged: (value) => name = value,
                ),
                SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(labelText: local.relation),
                  onChanged: (value) => relation = value,
                ),
                SizedBox(height: 16),
                if (members.isNotEmpty) ...[
                  Text(local.selectParentOptional),
                  DropdownButton<String>(
                    hint: Text(local.selectParent),
                    value: parentId,
                    isExpanded: true,
                    onChanged: (value) {
                      setStateDialog(() {
                        parentId = value;
                      });
                    },
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text(local.noParent),
                      ),
                      ...members.map((member) {
                        return DropdownMenuItem<String>(
                          value: member.id, // Make sure `id` is a field in your member model
                          child: Text(member.name),
                        );
                      }).toList(),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(local.cancel),
        ),
        ElevatedButton(
          onPressed: () async {
            if (name.isNotEmpty && relation.isNotEmpty) {
              Navigator.of(context).pop();
              await _saveNewMember(name, relation, imageFile, parentId);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(local.pleaseFillInAllFields)),
              );
            }
          },
          child: Text(local.add),
        ),
      ],
    ),
  );
}


  // Upload image to ImgBB API and return the URL
  Future<String> _uploadImageToImgBB(File imageFile) async {
    try {
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Create the request body
      final Map<String, String> body = {
        'key': IMGBB_API_KEY,
        'image': base64Image,
        'name': 'family_tree_image_${DateTime.now().millisecondsSinceEpoch}',
      };

      // Send POST request
      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload'),
        body: body,
      );

      print('ImgBB Response Status: ${response.statusCode}');
      print('ImgBB Response Body: ${response.body}');

      // Parse response
      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode != 200 || !jsonResponse['success']) {
        final errorMessage = jsonResponse['error']?['message'] ?? 'Unknown error';
        throw Exception('Failed to upload image: $errorMessage');
      }

      // Return the direct URL of the uploaded image
      return jsonResponse['data']['url'];
    } catch (e) {
      print('Error during ImgBB upload: $e');
      throw Exception('Failed to upload image to ImgBB: $e');
    }
  }

  Future<void> _saveNewMember(String name, String relation, File imageFile, String? parentId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Request permissions before attempting to access files
      if (Platform.isAndroid) {
        await [Permission.storage, Permission.photos].request();
      } else if (Platform.isIOS) {
        await [Permission.photos].request();
      }

      // Safety check for userId
      if (userId.isEmpty) {
        throw Exception("User ID is not set.");
      }

      // Check if image file exists and is readable
      final fileExists = await imageFile.exists();
      if (!fileExists) {
        throw Exception("Image file does not exist at path: ${imageFile.path}");
      }

      // Generate a unique ID for the new family member
      final memberId = Uuid().v4();
      final local = Localizations.of(context, AppLocalizations);

      print('Uploading image to ImgBB...');
      final imageUrl = await _uploadImageToImgBB(imageFile);
      print("Image uploaded successfully to ImgBB, URL: $imageUrl");

      // Create FamilyMember instance
      final newMember = FamilyMember(
        id: memberId,
        name: name,
        relation: relation,
        imageUrl: imageUrl,
        parentId: parentId,
      );

      // Save member data to Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('family-members')
          .doc(memberId)
          .set(newMember.toMap());

      // Add the new member to local state and rebuild graph
      setState(() {
        members.add(newMember);
        _buildFamilyTreeGraph();
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(local.familyMemberAdded)),
      );
    } catch (e, st) {
      final local = Localizations.of(context, AppLocalizations);
      // Show error message and print stacktrace
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${local.failedToAddFamilyMember} $e')),
      );
      print('Error adding family member: $e');
      print('Stack trace: $st');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteMember(FamilyMember member) async {
    // Check if member has children
    final hasChildren = members.any((m) => m.parentId == member.id);
    
    if (hasChildren) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot delete member with children. Delete children first.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Family Member'),
        content: Text('Are you sure you want to delete ${member.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('family-members')
            .doc(member.id)
            .delete();

        setState(() {
          members.removeWhere((m) => m.id == member.id);
          _buildFamilyTreeGraph();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${member.name} deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete member: $e')),
        );
      }
    }
  }

  Widget _buildMemberNode(String memberId) {
    final member = members.firstWhere((m) => m.id == memberId);
    
    return GestureDetector(
      onLongPress: () => _deleteMember(member),
      child: Container(
        width: 120,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(member.imageUrl),
              backgroundColor: Colors.grey[300],
            ),
            SizedBox(height: 8),
            Text(
              member.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              member.relation,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreeView() {
    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.family_restroom, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No family members yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the + button to add your first family member',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return InteractiveViewer(
      constrained: false,
      boundaryMargin: EdgeInsets.all(100),
      minScale: 0.01,
      maxScale: 5.6,
      child: GraphView(
        graph: graph,
        algorithm: BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder)),
        paint: Paint()
          ..color = Colors.green
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
        builder: (Node node) {
          return _buildMemberNode(node.key!.value as String);
        },
      ),
    );
  }

  Widget _buildListView() {
    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.family_restroom, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No family members yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the + button to add your first family member',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final parent = member.parentId != null 
            ? members.firstWhere((m) => m.id == member.parentId, orElse: () => null as FamilyMember)
            : null;

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(member.imageUrl),
              backgroundColor: Colors.grey[300],
            ),
            title: Text(member.name, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.relation),
                if (parent != null)
                  Text('Child of: ${parent.name}', 
                       style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteMember(member),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context);
     if (local == null) {
    return const Center(child: CircularProgressIndicator());
  }
    return Scaffold(
      appBar: AppBar(
        title: Text(local.familyTree),
        actions: [
          IconButton(
            icon: Icon(_showListView ? Icons.account_tree : Icons.list),
            onPressed: () {
              setState(() {
                _showListView = !_showListView;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addFamilyMember,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadFamilyMembers,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : members.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.family_restroom, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        local.noFamilyMembersYet,
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                )
              : FamilyTreeView(members: members),
    );
  }
}

class FamilyTreeView extends StatefulWidget {
  final List<FamilyMember> members;
  
  const FamilyTreeView({super.key, required this.members});

  @override
  _FamilyTreeViewState createState() => _FamilyTreeViewState();
}

class _FamilyTreeViewState extends State<FamilyTreeView> {
  late Graph graph;
  late Algorithm algorithm;
  final TransformationController _transformationController = TransformationController();
  
  @override
  void initState() {
    super.initState();
    graph = Graph()..isTree = true;
    
    var builder = BuchheimWalkerConfiguration()
      ..siblingSeparation = (100)
      ..levelSeparation = (150)
      ..subtreeSeparation = (150)
      ..orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;
      
    algorithm = BuchheimWalkerAlgorithm(
      builder, 
      TreeEdgeRenderer(builder)
    );
    
    _buildGraph();
  }
  
  void _buildGraph() {
    // First, find root nodes (members without parents or with non-existent parent IDs)
    final rootMembers = widget.members.where((member) {
      if (member.parentId == null || member.parentId!.isEmpty) return true;
      return !widget.members.any((m) => m.id == member.parentId);
    }).toList();
    
    // If no root members, use first member as root
    if (rootMembers.isEmpty && widget.members.isNotEmpty) {
      rootMembers.add(widget.members.first);
    }
    
    // Add root nodes to graph
    for (final rootMember in rootMembers) {
      final rootNode = Node.Id(rootMember.id);
      graph.addNode(rootNode);
      
      // Add children recursively
      _addChildrenToGraph(rootMember);
    }
  }
  
  void _addChildrenToGraph(FamilyMember parent) {
    final parentNode = Node.Id(parent.id);
    
    // Find all children of this parent
    final children = widget.members.where((member) => 
      member.parentId != null && member.parentId == parent.id
    ).toList();
    
    // Add children and edges to graph
    for (final child in children) {
      final childNode = Node.Id(child.id);
      graph.addNode(childNode);
      graph.addEdge(parentNode, childNode);
      
      // Recursively add this child's children
      _addChildrenToGraph(child);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _transformationController,
      boundaryMargin: EdgeInsets.all(double.infinity),
      minScale: 0.1,
      maxScale: 2.5,
      child: GraphView(
        graph: graph,
        algorithm: algorithm,
        paint: Paint()
          ..color = Colors.teal
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
        builder: (Node node) {
          // Find the family member that corresponds to this node
          final id = node.key!.value as String;
          final member = widget.members.firstWhere((m) => m.id == id);
          
          return _buildFamilyMemberNode(member);
        },
      ),
    );
  }
  
  Widget _buildFamilyMemberNode(FamilyMember member) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      width: 150,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(member.imageUrl),
            radius: 40,
            onBackgroundImageError: (exception, stackTrace) {
              print('Error loading image: $exception');
            },
          ),
          SizedBox(height: 8),
          Text(
            member.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          Text(
            member.relation,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}