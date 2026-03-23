import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/art_post.dart';
import '../../services/art_post_service.dart';
import '../../services/auth_service.dart';
import '../../services/subscription_service.dart';
import 'subscription_plans_screen.dart';

class UploadArtScreen extends StatefulWidget {
  const UploadArtScreen({super.key});

  @override
  State<UploadArtScreen> createState() => _UploadArtScreenState();
}

class _UploadArtScreenState extends State<UploadArtScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _tagsController = TextEditingController();
  final _mediumController = TextEditingController();
  final _styleController = TextEditingController();
  final ArtPostService _artPostService = ArtPostService();
  final AuthService _authService = AuthService();
  final _currentUser = FirebaseAuth.instance.currentUser;
  final _imagePicker = ImagePicker();

  File? _selectedImage;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _errorMessage = '';

  final List<String> _mediumOptions = [
    'Oil',
    'Acrylic',
    'Watercolor',
    'Digital',
    'Photography',
    'Sculpture',
    'Mixed Media',
    'Charcoal',
    'Pencil',
  ];

  final List<String> _styleOptions = [
    'Abstract',
    'Realistic',
    'Impressionism',
    'Surrealism',
    'Contemporary',
    'Pop Art',
    'Minimalism',
    'Expressionism',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _tagsController.dispose();
    _mediumController.dispose();
    _styleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Compress for faster upload
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _errorMessage = '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: $e';
      });
    }
  }

  Future<String> _uploadImageToFirebase(File imageFile) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = '${_currentUser!.uid}_$timestamp.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('art_uploads')
          .child(_currentUser!.uid)
          .child(filename);

      final uploadTask = ref.putFile(imageFile);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        setState(() {
          _uploadProgress = progress;
        });
      });

      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image to Firebase: $e');
    }
  }

  Future<void> _uploadArt() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in title and description';
      });
      return;
    }

    if (_mediumController.text.isEmpty || _styleController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please select medium and style';
      });
      return;
    }

    if (_selectedImage == null) {
      setState(() {
        _errorMessage = 'Please select an image to upload';
      });
      return;
    }

    // Check subscription upload limit
    final subscriptionService = SubscriptionService();
    final canUpload = await subscriptionService.canUploadArt(_currentUser!.uid);

    if (!canUpload) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Upload Limit Reached'),
            content: const Text(
              'You\'ve reached your monthly upload limit. Upgrade to a higher tier for more uploads!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubscriptionPlansScreen(),
                    ),
                  );
                },
                child: const Text('Upgrade Now'),
              ),
            ],
          ),
        );
      }
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _errorMessage = '';
    });

    try {
      // Upload image to Firebase Storage
      final imageUrl = await _uploadImageToFirebase(_selectedImage!);

      final userProfile = await _authService.getUserProfile(_currentUser!.uid);

      final newPost = ArtPost(
        postId: '',
        artistUid: _currentUser!.uid,
        artistName: userProfile?.displayName ?? 'Unknown Artist',
        artistProfileImage: userProfile?.profileImageUrl ?? '',
        title: _titleController.text,
        description: _descriptionController.text,
        imageUrl: imageUrl,
        tags: _tagsController.text.isNotEmpty
            ? _tagsController.text.split(',').map((t) => t.trim()).toList()
            : [],
        medium: _mediumController.text,
        style: _styleController.text,
        askingPrice: double.tryParse(_priceController.text) ?? 0.0,
        viewCount: 0,
        likeCount: 0,
        critiqueCount: 0,
        likedBy: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        imageUrls: [imageUrl],
      );

      await _artPostService.createPost(newPost);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Art uploaded successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to upload art: $e';
      });
    }

    setState(() {
      _isUploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Upload Your Art'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Art Title *',
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),

            // Description
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Description *',
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),

            // Medium Dropdown
            DropdownButtonFormField<String>(
              initialValue: _mediumController.text.isEmpty
                  ? null
                  : _mediumController.text,
              items: _mediumOptions.map((medium) {
                return DropdownMenuItem(
                  value: medium,
                  child: Text(medium),
                );
              }).toList(),
              onChanged: (value) {
                _mediumController.text = value ?? '';
              },
              decoration: InputDecoration(
                labelText: 'Medium *',
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Style Dropdown
            DropdownButtonFormField<String>(
              initialValue:
                  _styleController.text.isEmpty ? null : _styleController.text,
              items: _styleOptions.map((style) {
                return DropdownMenuItem(
                  value: style,
                  child: Text(style),
                );
              }).toList(),
              onChanged: (value) {
                _styleController.text = value ?? '';
              },
              decoration: InputDecoration(
                labelText: 'Style *',
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Price
            TextField(
              controller: _priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Asking Price (\$)',
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),

            // Tags
            TextField(
              controller: _tagsController,
              decoration: InputDecoration(
                labelText: 'Tags (comma separated)',
                hintText: 'landscape, oil, contemporary',
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),

            // Image Preview & Picker
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.deepPurple.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: _selectedImage != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImage = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.8),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        if (_isUploading)
                          Container(
                            color: Colors.black.withValues(alpha: 0.5),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: _uploadProgress,
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.deepPurple.shade300,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 64,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No image selected',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 12),

            // Pick Image Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _pickImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple.withValues(alpha: 0.7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.photo_library),
                label: const Text('Pick Image from Gallery'),
              ),
            ),
            const SizedBox(height: 24),
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (_errorMessage.isNotEmpty) const SizedBox(height: 16),

            // Upload Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadArt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Upload Art',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
