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
    return MaterialApp(
      title: 'Family Tree',
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
  
  FamilyMember({
    required this.id,
    required this.name,
    required this.relation,
    required this.imageUrl,
    this.parentId,
  });
  
  factory FamilyMember.fromMap(Map<String, dynamic> data) {
    return FamilyMember(
      id: data['id'],
      name: data['name'],
      relation: data['relation'],
      imageUrl: data['imageUrl'],
      parentId: data['parentId'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'relation': relation,
      'imageUrl': imageUrl,
      'parentId': parentId,
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
  
  @override
  void initState() {
    super.initState();
    _loadFamilyMembers();
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

  Future<void> _addFamilyMember() async {
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
        title: Text("Add Family Member"),
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
                    decoration: InputDecoration(labelText: "Name"),
                    onChanged: (value) => name = value,
                  ),
                  SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(labelText: "Relation"),
                    onChanged: (value) => relation = value,
                  ),
                  SizedBox(height: 16),
                  if (members.isNotEmpty) ...[
                    Text("Select Parent (Optional)"),
                    DropdownButton<String>(
                      hint: Text("Select Parent"),
                      value: parentId,
                      isExpanded: true,
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text("No Parent"),
                        ),
                        ...members.map((member) {
                          return DropdownMenuItem<String>(
                            value: member.id,
                            child: Text(member.name),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setStateDialog(() {
                          parentId = value;
                        });
                      },
                    ),
                  ],
                ],
              ),
            );
          }
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              if (name.isNotEmpty && relation.isNotEmpty) {
                Navigator.of(context).pop();
                await _saveNewMember(name, relation, imageFile, parentId);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Please fill in all fields")),
                );
              }
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }
  
  // Upload image to ImgBB API and return the URL
  Future<String> _uploadImageToImgBB(File imageFile) async {
    try {
      // Create a multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imgbb.com/1/upload?key=$IMGBB_API_KEY'),
      );
      
      // Get file length
      final fileLength = await imageFile.length();
      
      // Create multipart file
      final multipartFile = await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        filename: 'family_tree_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      
      // Add file to request
      request.files.add(multipartFile);
      
      // Send request
      final streamedResponse = await request.send();
      
      // Get response
      final response = await http.Response.fromStream(streamedResponse);
      
      // Parse response
      final jsonResponse = jsonDecode(response.body);
      
      if (response.statusCode != 200) {
        throw Exception('Failed to upload image: ${jsonResponse['error']['message'] ?? 'Unknown error'}');
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
      Map<Permission, PermissionStatus> statuses;
      
      if (Platform.isAndroid) {
        statuses = await [
          Permission.storage,
          Permission.photos,
        ].request();
      } else if (Platform.isIOS) {
        statuses = await [
          Permission.photos,
        ].request();
      } else {
        statuses = {Permission.storage: PermissionStatus.granted};
      }
      
      // Check if any permission was denied
      bool allGranted = true;
      statuses.forEach((permission, status) {
        if (!status.isGranted) {
          allGranted = false;
          print("Permission denied: $permission");
        }
      });

      // Safety check for userId
      if (userId.isEmpty) {
        throw Exception("User ID is not set.");
      }

      // Check if image file exists and is readable
      try {
        final fileExists = await imageFile.exists();
        if (!fileExists) {
          throw Exception("Image file does not exist at path: ${imageFile.path}");
        }
        
        // Try to read some bytes to verify file access
        await imageFile.openRead(0, 100).first;
      } catch (e) {
        throw Exception("Cannot access image file: $e");
      }

      // Generate a unique ID for the new family member
      final memberId = Uuid().v4();

      // Debug prints
      print('userId: $userId');
      print('memberId: $memberId');
      print("File exists: ${await imageFile.exists()}");
      print("Path: ${imageFile.path}");
      print("File size: ${await imageFile.length()} bytes");

      // Upload image to ImgBB instead of Imgur
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

      // Add the new member to local state
      setState(() {
        members.add(newMember);
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Family member added successfully')),
      );
    } catch (e, st) {
      // Show error message and print stacktrace
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add family member: $e')),
      );
      print('Error adding family member: $e');
      print('Stack trace: $st');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
                        "No family members yet. Tap + to add.",
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