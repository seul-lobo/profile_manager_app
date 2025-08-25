import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../utils/validators.dart';
import '../../utils/permission_helper.dart';
import '../../utils/constants.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;
  File? _selectedDocument;
  String? _selectedDocumentName;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
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
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
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
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            if (_selectedImage != null)
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Remove Photo'),
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
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
        actions: [
          Consumer<ProfileProvider>(
            builder: (context, profileProvider, child) {
              return TextButton(
                onPressed:
                    (profileProvider.isLoading || profileProvider.isUploading)
                        ? null
                        : _saveProfile,
                child: const Text('Save'),
              );
            },
          ),
        ],
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final isLargeScreen =
                  constraints.maxWidth > Constants.mobileBreakpoint;
              final horizontalPadding = isLargeScreen
                  ? constraints.maxWidth * 0.25
                  : Constants.mediumPadding;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: Constants.largePadding,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      //profile image section
                      _buildProfileImageSection(profileProvider),

                      const SizedBox(height: Constants.largePadding),

                      //form fields
                      _buildFormFields(),

                      const SizedBox(height: Constants.largePadding),

                      //document upload section
                      _buildDocumentSection(profileProvider),

                      const SizedBox(height: Constants.largePadding),

                      //progress indicator
                      if (profileProvider.isUploading)
                        _buildUploadProgress(profileProvider),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProfileImageSection(ProfileProvider profileProvider) {
    return Column(
      children: [
        GestureDetector(
          onTap: _showImagePicker,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
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
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                                child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderImage();
                          },
                        )
                      : _buildPlaceholderImage(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _showImagePicker,
          icon: const Icon(Icons.camera_alt),
          label: const Text('Change Photo'),
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 120,
      height: 120,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.add_a_photo,
        size: 40,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        // Name field
        TextFormField(
          controller: _nameController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Full Name',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Constants.borderRadius),
            ),
          ),
          validator: Validators.validateName,
        ),

        const SizedBox(height: Constants.mediumPadding),

        // Email field
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Constants.borderRadius),
            ),
          ),
          validator: Validators.validateEmail,
        ),

        const SizedBox(height: Constants.mediumPadding),

        // Age field
        TextFormField(
          controller: _ageController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: 'Age',
            prefixIcon: const Icon(Icons.cake_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Constants.borderRadius),
            ),
          ),
          validator: Validators.validateAge,
        ),
      ],
    );
  }

  Widget _buildDocumentSection(ProfileProvider profileProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Constants.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Constants.mediumPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Document',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            if (_selectedDocument != null)
              ListTile(
                leading: const Icon(Icons.description, color: Colors.green),
                title: Text(_selectedDocumentName ?? 'Selected Document'),
                subtitle: const Text('Ready to upload'),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _selectedDocument = null;
                      _selectedDocumentName = null;
                    });
                  },
                ),
              )
            else if (profileProvider.profile?.docURL != null)
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Current Document'),
                subtitle: const Text('Tap to replace'),
                trailing: const Icon(Icons.open_in_new),
                onTap: _pickDocument,
              )
            else
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('Upload Document'),
                subtitle: const Text('PDF, JPG, or PNG files supported'),
                onTap: _pickDocument,
              ),
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
