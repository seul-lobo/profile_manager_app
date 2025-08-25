import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/validators.dart';
import '../../utils/permission_helper.dart';
import '../../utils/constants.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;
  File? _selectedDocument;
  String? _selectedDocumentName;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingProfile();
    });
    _initAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _loadExistingProfile() {
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    final profile = profileProvider.profile;

    if (profile != null) {
      _nameController.text = profile.name;
      _emailController.text = profile.email;
      _ageController.text = profile.age.toString();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    if (!await PermissionHelper.requestCameraPermission(context)) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showError('Failed to take photo: ${e.toString()}');
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (!await PermissionHelper.requestGalleryPermission(context)) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        final File imageFile = File(image.path);
        final ProfileProvider profileProvider =
            Provider.of<ProfileProvider>(context, listen: false);

        if (!profileProvider.isValidImageFile(imageFile, image.name)) {
          _showError(
              'Invalid image file. Please select a JPG or PNG file under 5MB.');
          return;
        }

        setState(() {
          _selectedImage = imageFile;
        });
      }
    } catch (e) {
      _showError('Failed to select image: ${e.toString()}');
    }
  }

  Future<void> _pickDocument() async {
    if (!await PermissionHelper.requestStoragePermission(context)) return;

    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: Constants.documentExtensions,
      );

      if (result != null && result.files.single.path != null && mounted) {
        final File documentFile = File(result.files.single.path!);
        final String fileName = result.files.single.name;
        final ProfileProvider profileProvider =
            Provider.of<ProfileProvider>(context, listen: false);

        if (!profileProvider.isValidDocumentFile(documentFile, fileName)) {
          _showError(
              'Invalid document file. Please select a PDF, JPG, or PNG file under 5MB.');
          return;
        }

        setState(() {
          _selectedDocument = documentFile;
          _selectedDocumentName = fileName;
        });
      }
    } catch (e) {
      _showError('Failed to select document: ${e.toString()}');
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? Colors.white
          : const Color(0xFF2D3748),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF718096),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Color(0xFF667EEA),
                  ),
                ),
                title: Text(
                  'Take Photo',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFF2D3748)
                        : Colors.white,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF764BA2).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: Color(0xFF764BA2),
                  ),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFF2D3748)
                        : Colors.white,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              if (_selectedImage != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                  title: Text(
                    'Remove Photo',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.light
                          ? const Color(0xFF2D3748)
                          : Colors.white,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);

    if (authProvider.currentUserId == null) {
      _showError('User not authenticated');
      return;
    }

    try {
      //save basic profile information
      final bool profileSaved = await profileProvider.saveProfile(
        userId: authProvider.currentUserId!,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        age: int.parse(_ageController.text),
      );

      if (!profileSaved) {
        if (profileProvider.error != null) {
          _showError(profileProvider.error!);
        }
        return;
      }

      //upload image if selected
      if (_selectedImage != null) {
        final bool imageUploaded = await profileProvider.uploadProfileImage(
          userId: authProvider.currentUserId!,
          imageFile: _selectedImage!,
        );

        if (!imageUploaded && profileProvider.error != null) {
          _showError(profileProvider.error!);
          return;
        }
      }

      //upload document if selected
      if (_selectedDocument != null && _selectedDocumentName != null) {
        final bool documentUploaded = await profileProvider.uploadDocument(
          userId: authProvider.currentUserId!,
          documentFile: _selectedDocument!,
          fileName: _selectedDocumentName!,
        );

        if (!documentUploaded && profileProvider.error != null) {
          _showError(profileProvider.error!);
          return;
        }
      }

      _showSuccess('Profile saved successfully!');

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showError('Failed to save profile: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer3<AuthProvider, ProfileProvider, ThemeProvider>(
        builder:
            (context, authProvider, profileProvider, themeProvider, child) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 160,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF2D3748),
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3,
                          color: Colors.black45,
                        ),
                      ],
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF667EEA),
                          Color(0xFF764BA2),
                          Color(0xFF2D3748),
                        ],
                        stops: [0.0, 0.6, 1.0],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -30,
                          top: -30,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                        ),
                        Positioned(
                          left: -20,
                          bottom: -20,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextButton(
                      onPressed: (profileProvider.isLoading ||
                              profileProvider.isUploading)
                          ? null
                          : _saveProfile,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (profileProvider.isLoading ||
                              profileProvider.isUploading)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          else
                            const Icon(Icons.save, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Save',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              //content
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          //profile image section
                          _buildProfileImageSection(profileProvider),
                          const SizedBox(height: 24),

                          //form fields
                          _buildFormFields(),
                          const SizedBox(height: 24),

                          //document upload section
                          _buildDocumentSection(profileProvider),
                          const SizedBox(height: 24),

                          //progress indicator
                          if (profileProvider.isUploading)
                            _buildUploadProgress(profileProvider),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileImageSection(ProfileProvider profileProvider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: Theme.of(context).brightness == Brightness.light
          ? Colors.white
          : const Color(0xFF2D3748),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'Profile Picture',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFF2D3748)
                        : Colors.white,
                  ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _showImagePicker,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _selectedImage != null
                      ? Image.file(
                          _selectedImage!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        )
                      : profileProvider.profile?.photoURL != null
                          ? Image.network(
                              profileProvider.profile!.photoURL!,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: 120,
                                  height: 120,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF7FAFC),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF667EEA),
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholderImage();
                              },
                            )
                          : _buildPlaceholderImage(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showImagePicker,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Change Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 120,
      height: 120,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(
          Icons.add_a_photo,
          size: 40,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: Theme.of(context).brightness == Brightness.light
          ? Colors.white
          : const Color(0xFF2D3748),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF667EEA),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Basic Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.light
                            ? const Color(0xFF2D3748)
                            : Colors.white,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.light
                    ? const Color(0xFF2D3748)
                    : Colors.white,
              ),
              decoration: InputDecoration(
                labelText: 'Full Name',
                labelStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.light
                      ? const Color(0xFF718096)
                      : Colors.white70,
                ),
                prefixIcon: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF667EEA),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF667EEA), width: 2),
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.light
                    ? const Color(0xFFF7FAFC)
                    : const Color(0xFF1A202C),
              ),
              validator: Validators.validateName,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.light
                    ? const Color(0xFF2D3748)
                    : Colors.white,
              ),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.light
                      ? const Color(0xFF718096)
                      : Colors.white70,
                ),
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  color: Color(0xFF667EEA),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF667EEA), width: 2),
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.light
                    ? const Color(0xFFF7FAFC)
                    : const Color(0xFF1A202C),
              ),
              validator: Validators.validateEmail,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.light
                    ? const Color(0xFF2D3748)
                    : Colors.white,
              ),
              decoration: InputDecoration(
                labelText: 'Age',
                labelStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.light
                      ? const Color(0xFF718096)
                      : Colors.white70,
                ),
                prefixIcon: const Icon(
                  Icons.cake_outlined,
                  color: Color(0xFF667EEA),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF667EEA), width: 2),
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.light
                    ? const Color(0xFFF7FAFC)
                    : const Color(0xFF1A202C),
              ),
              validator: Validators.validateAge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentSection(ProfileProvider profileProvider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: Theme.of(context).brightness == Brightness.light
          ? Colors.white
          : const Color(0xFF2D3748),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF764BA2).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.folder_outlined,
                    color: Color(0xFF764BA2),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Document',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.light
                            ? const Color(0xFF2D3748)
                            : Colors.white,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.light
                    ? const Color(0xFFF7FAFC)
                    : const Color(0xFF1A202C),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                ),
              ),
              child: _selectedDocument != null
                  ? ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF059669).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.description,
                          color: Color(0xFF059669),
                        ),
                      ),
                      title: Text(
                        _selectedDocumentName ?? 'Selected Document',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? const Color(0xFF2D3748)
                                  : Colors.white,
                        ),
                      ),
                      subtitle: const Text(
                        'Ready to upload',
                        style: TextStyle(color: Color(0xFF059669)),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFFDC2626)),
                        onPressed: () {
                          setState(() {
                            _selectedDocument = null;
                            _selectedDocumentName = null;
                          });
                        },
                      ),
                    )
                  : ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF764BA2).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.upload_file,
                          color: Color(0xFF764BA2),
                        ),
                      ),
                      title: Text(
                        'Upload Document',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? const Color(0xFF2D3748)
                                  : Colors.white,
                        ),
                      ),
                      subtitle: const Text('PDF, JPG, or PNG files supported'),
                      onTap: _pickDocument,
                    ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildUploadProgress(ProfileProvider profileProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Constants.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Constants.mediumPadding),
        child: Column(
          children: [
            Text(
              'Uploading...',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: profileProvider.uploadProgress,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 8),
            Text(
              '${(profileProvider.uploadProgress * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
