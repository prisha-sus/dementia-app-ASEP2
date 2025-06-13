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
// Remove this import if you don't have localization set up
// import 'package:mytestapp/flutter_gen/gen_l10n/app_localizations.dart';

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
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      relation: data['relation'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
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

  @override
  void initState() {
    super.initState();
    _loadFamilyMembers();
  }

  Future<void> _loadFamilyMembers() async {
    print('Starting to load family members...');
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('family-members')
          .get();

      print('Firestore query completed. Found ${snapshot.docs.length} documents');

      final loadedMembers = snapshot.docs
          .map((doc) {
            print('Processing document: ${doc.id}');
            return FamilyMember.fromMap(doc.data());
          })
          .toList();

      print('Successfully loaded ${loadedMembers.length} family members');

      setState(() {
        members = loadedMembers;
      });
    } catch (e, stackTrace) {
      print('Error loading family members: $e');
      print('Stack trace: $stackTrace');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load family members: $e')),
      );
    } finally {
      print('Setting loading to false');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addFamilyMember() async {
    try {
      final pickedImage = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedImage == null) {
        print('No image selected');
        return;
      }

      final imageFile = File(pickedImage.path);
      String name = '';
      String relation = '';
      String? parentId = _selectedParentId;

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Add Family Member'),
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
                      decoration: InputDecoration(labelText: 'Name'),
                      onChanged: (value) => name = value,
                    ),
                    SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(labelText: 'Relation'),
                      onChanged: (value) => relation = value,
                    ),
                    SizedBox(height: 16),
                    if (members.isNotEmpty) ...[
                      Text('Select Parent (Optional)'),
                      DropdownButton<String>(
                        hint: Text('Select Parent'),
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
                            child: Text('No Parent'),
                          ),
                          ...members.map((member) {
                            return DropdownMenuItem<String>(
                              value: member.id,
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
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (name.isNotEmpty && relation.isNotEmpty) {
                  Navigator.of(context).pop();
                  await _saveNewMember(name, relation, imageFile, parentId);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill in all fields')),
                  );
                }
              },
              child: Text('Add'),
            ),
          ],
        ),
      );
    } catch (e, stackTrace) {
      print('Error in _addFamilyMember: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding family member: $e')),
      );
    }
  }

  // Upload image to ImgBB API and return the URL
  Future<String> _uploadImageToImgBB(File imageFile) async {
    try {
      print('Starting image upload to ImgBB...');
      
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
      final imageUrl = jsonResponse['data']['url'];
      print('Image uploaded successfully. URL: $imageUrl');
      return imageUrl;
    } catch (e) {
      print('Error during ImgBB upload: $e');
      throw Exception('Failed to upload image to ImgBB: $e');
    }
  }

  Future<void> _saveNewMember(String name, String relation, File imageFile, String? parentId) async {
    print('Starting to save new member: $name');
    
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

      // Check if image file exists and is readable
      final fileExists = await imageFile.exists();
      if (!fileExists) {
        throw Exception("Image file does not exist at path: ${imageFile.path}");
      }

      // Generate a unique ID for the new family member
      final memberId = Uuid().v4();

      print('Uploading image to ImgBB...');
      final imageUrl = await _uploadImageToImgBB(imageFile);

      // Create FamilyMember instance
      final newMember = FamilyMember(
        id: memberId,
        name: name,
        relation: relation,
        imageUrl: imageUrl,
        parentId: parentId,
      );

      print('Saving member data to Firestore...');
      // Save member data to Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('family-members')
          .doc(memberId)
          .set(newMember.toMap());

      print('Member saved successfully to Firestore');

      // Add the new member to local state
      setState(() {
        members.add(newMember);
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Family member added successfully')),
      );
    } catch (e, stackTrace) {
      print('Error adding family member: $e');
      print('Stack trace: $stackTrace');
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add family member: $e')),
      );
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
            ? members.cast<FamilyMember?>().firstWhere(
                (m) => m?.id == member.parentId, 
                orElse: () => null
              )
            : null;

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(member.imageUrl),
              backgroundColor: Colors.grey[300],
              onBackgroundImageError: (exception, stackTrace) {
                print('Error loading image: $exception');
              },
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
    print('Building FamilyTreeScreen. Loading: $_isLoading, Members count: ${members.length}');
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Family Tree'),
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
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading family members...'),
                ],
              ),
            )
          : _showListView
              ? _buildListView()
              : members.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.family_restroom, size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No family members yet',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap the + button to add your first family member',
                            style: TextStyle(color: Colors.grey),
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
    print('Initializing FamilyTreeView with ${widget.members.length} members');
    _setupGraph();
  }
  
  void _setupGraph() {
    try {
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
      print('Graph setup completed successfully');
    } catch (e, stackTrace) {
      print('Error setting up graph: $e');
      print('Stack trace: $stackTrace');
    }
  }
  
  void _buildGraph() {
    if (widget.members.isEmpty) {
      print('No members to build graph');
      return;
    }

    try {
      // First, find root nodes (members without parents or with non-existent parent IDs)
      final rootMembers = widget.members.where((member) {
        if (member.parentId == null || member.parentId!.isEmpty) return true;
        return !widget.members.any((m) => m.id == member.parentId);
      }).toList();
      
      print('Found ${rootMembers.length} root members');
      
      // If no root members, use first member as root
      if (rootMembers.isEmpty && widget.members.isNotEmpty) {
        rootMembers.add(widget.members.first);
        print('No root members found, using first member as root');
      }
      
      // Add root nodes to graph
      for (final rootMember in rootMembers) {
        final rootNode = Node.Id(rootMember.id);
        graph.addNode(rootNode);
        print('Added root node: ${rootMember.name}');
        
        // Add children recursively
        _addChildrenToGraph(rootMember);
      }
      
      print('Graph building completed. Total nodes: ${graph.nodeCount()}');
    } catch (e, stackTrace) {
      print('Error building graph: $e');
      print('Stack trace: $stackTrace');
    }
  }
  
  void _addChildrenToGraph(FamilyMember parent) {
    try {
      final parentNode = Node.Id(parent.id);
      
      // Find all children of this parent
      final children = widget.members.where((member) => 
        member.parentId != null && member.parentId == parent.id
      ).toList();
      
      print('Adding ${children.length} children for ${parent.name}');
      
      // Add children and edges to graph
      for (final child in children) {
        final childNode = Node.Id(child.id);
        graph.addNode(childNode);
        graph.addEdge(parentNode, childNode);
        print('Added child node and edge: ${child.name}');
        
        // Recursively add this child's children
        _addChildrenToGraph(child);
      }
    } catch (e, stackTrace) {
      print('Error adding children to graph: $e');
      print('Stack trace: $stackTrace');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    print('Building FamilyTreeView widget');
    
    if (widget.members.isEmpty) {
      return Center(
        child: Text('No family members to display'),
      );
    }

    try {
      return InteractiveViewer(
        transformationController: _transformationController,
        boundaryMargin: EdgeInsets.all(100),
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
            try {
              // Find the family member that corresponds to this node
              final id = node.key!.value as String;
              final member = widget.members.firstWhere((m) => m.id == id);
              
              return _buildFamilyMemberNode(member);
            } catch (e) {
              print('Error building node: $e');
              return Container(
                width: 150,
                height: 100,
                color: Colors.red,
                child: Center(child: Text('Error')),
              );
            }
          },
        ),
      );
    } catch (e, stackTrace) {
      print('Error building FamilyTreeView: $e');
      print('Stack trace: $stackTrace');
      
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 60, color: Colors.red),
            SizedBox(height: 16),
            Text('Error displaying family tree'),
            SizedBox(height: 8),
            Text('$e', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }
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
            backgroundColor: Colors.grey[300],
            onBackgroundImageError: (exception, stackTrace) {
              print('Error loading image for ${member.name}: $exception');
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