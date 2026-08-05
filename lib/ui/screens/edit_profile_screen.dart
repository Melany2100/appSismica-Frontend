import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String? userId;
  final String? token;
  final Map<String, dynamic>? userData;

  const EditProfileScreen({super.key, this.userId, this.token, this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cedulaController = TextEditingController();

  String? _originalNombre;
  String? _originalTelefono;
  String? _originalEmail;
  String? _originalCedula;
  String? _originalFoto;
  File? _selectedImage;
  bool _loading = false;
  bool _hasChanges = false;
  bool _imageRemoved =
      false; // Nueva variable para track si se eliminó la imagen
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    if (widget.userData != null) {
      _originalNombre = widget.userData!['nombre']?.toString() ?? '';
      _originalTelefono = widget.userData!['telefono']?.toString() ?? '';
      _originalEmail = widget.userData!['email']?.toString() ?? '';
      _originalCedula = widget.userData!['cedula']?.toString() ?? '';
      _originalFoto = widget.userData!['foto_perfil_url']?.toString() ?? '';

      _nombreController.text = _originalNombre ?? '';
      _telefonoController.text = _originalTelefono ?? '';
      _emailController.text = _originalEmail ?? '';
      _cedulaController.text = _originalCedula ?? '';

      // Listeners para detectar cambios
      _nombreController.addListener(_checkForChanges);
      _telefonoController.addListener(_checkForChanges);
      _emailController.addListener(_checkForChanges);
      _cedulaController.addListener(_checkForChanges);
    }
  }

  void _checkForChanges() {
    final hasNameChange =
        _nombreController.text.trim() != (_originalNombre ?? '');
    final hasPhoneChange =
        _telefonoController.text.trim() != (_originalTelefono ?? '');
    final hasEmailChange =
        _emailController.text.trim() != (_originalEmail ?? '');
    final hasCedulaChange =
        _cedulaController.text.trim() != (_originalCedula ?? '');
    final hasImageChange = _selectedImage != null || _imageRemoved;

    setState(() {
      _hasChanges =
          hasNameChange ||
          hasPhoneChange ||
          hasEmailChange ||
          hasCedulaChange ||
          hasImageChange;
    });
  }

  Future<void> _selectImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Seleccionar imagen',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImageOption(
                      icon: Icons.photo_camera,
                      label: 'Cámara',
                      onTap: () {
                        Navigator.of(context).pop();
                        _pickImage(ImageSource.camera);
                      },
                    ),
                    _buildImageOption(
                      icon: Icons.photo_library,
                      label: 'Galería',
                      onTap: () {
                        Navigator.of(context).pop();
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                    if (_selectedImage != null ||
                        (_originalFoto != null &&
                            _originalFoto!.isNotEmpty &&
                            !_imageRemoved))
                      _buildImageOption(
                        icon: Icons.delete,
                        label: 'Eliminar',
                        color: Colors.red,
                        onTap: () {
                          Navigator.of(context).pop();
                          _removeImage();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: (color ?? AppColors.primary).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: color ?? AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color ?? AppColors.text,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _imageRemoved =
              false; // Reset removed flag cuando se selecciona nueva imagen
        });
        _checkForChanges();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imagen seleccionada correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar imagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _imageRemoved = true;
    });
    _checkForChanges();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Imagen eliminada'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  String? _validateNombre(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es obligatorio';
    }
    if (value.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    if (value.trim().length > 100) {
      return 'El nombre no debe exceder 100 caracteres';
    }
    return null;
  }

  String? _validateTelefono(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Campo opcional
    }

    final phone = value.trim();

    // Validar que solo contenga dígitos
    if (!RegExp(r'^\d+$').hasMatch(phone)) {
      return 'El teléfono solo debe contener números';
    }

    // Validar que tenga exactamente 10 dígitos
    if (phone.length != 10) {
      return 'El teléfono debe tener exactamente 10 dígitos';
    }

    // Validar que empiece con 0 (formato ecuatoriano)
    if (!phone.startsWith('0')) {
      return 'El teléfono debe empezar con 0';
    }

    // Validar formatos válidos ecuatorianos:
    // Móviles: 09XXXXXXXX (Claro, Movistar, CNT)
    // Fijos: 0[2-7]XXXXXXX (según provincia)
    if (phone.startsWith('09')) {
      // Teléfono móvil - validar que el tercer dígito sea válido
      final thirdDigit = phone[2];
      if (![
        '0',
        '1',
        '2',
        '3',
        '4',
        '5',
        '6',
        '7',
        '8',
        '9',
      ].contains(thirdDigit)) {
        return 'Formato de móvil inválido';
      }
    } else {
      // Teléfono fijo - validar código de área
      final areaCode = phone[1];
      if (!['2', '3', '4', '5', '6', '7'].contains(areaCode)) {
        return 'Código de área inválido. Use 02-07 para fijos o 09 para móviles';
      }
    }

    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El email es obligatorio';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Formato de email inválido';
    }
    return null;
  }

  String? _validateCedula(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Campo opcional
    }
    final cedulaRegex = RegExp(r'^\d{10}$');
    if (!cedulaRegex.hasMatch(value.trim())) {
      return 'La cédula debe tener 10 dígitos';
    }
    return null;
  }

  // MÉTODO _saveProfile() ACTUALIZADO en EditProfileScreen
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || !_hasChanges) return;

    setState(() => _loading = true);

    try {
      String? userId = widget.userId;
      String? token = widget.token;

      if (userId == null || token == null) {
        throw Exception('Datos de sesión no válidos');
      }

      debugPrint('=== ACTUALIZANDO PERFIL ===');
      debugPrint('Usuario ID: $userId');
      debugPrint('Tiene nueva imagen: ${_selectedImage != null}');
      debugPrint('Imagen eliminada: $_imageRemoved');
      debugPrint('Cambios detectados: $_hasChanges');

      // Usar el UserService con los nuevos parámetros
      final response = await UserService.updateUser(
        token: token,
        userId: userId,
        nombre: _nombreController.text.trim() != _originalNombre
            ? _nombreController.text.trim()
            : null,
        telefono: _telefonoController.text.trim() != _originalTelefono
            ? _telefonoController.text.trim()
            : null,
        email: _emailController.text.trim() != _originalEmail
            ? _emailController.text.trim()
            : null,
        cedula: _cedulaController.text.trim() != _originalCedula
            ? _cedulaController.text.trim()
            : null,
        imageFile: _selectedImage, // Solo enviar si hay nueva imagen
        removeImage: _imageRemoved, // NUEVO: Flag para eliminar imagen
      );

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Resetear flags de cambios
        setState(() {
          _hasChanges = false;
          _selectedImage = null;
          _imageRemoved = false;

          // Actualizar valores originales con los nuevos datos
          if (response.data != null) {
            _originalNombre = response.data!.nombre;
            _originalTelefono = response.data!.telefono;
            _originalEmail = response.data!.email;
            _originalCedula = response.data!.cedula;
            _originalFoto = response.data!.fotoPerfilUrl;
          }
        });

        // Regresar con los datos actualizados
        Navigator.of(
          context,
        ).pop({'success': true, 'userData': response.data?.toCompatibleMap()});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.error ?? 'Error al actualizar perfil'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      debugPrint("Error al actualizar perfil: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  // Widget para mostrar la imagen de perfil con indicadores visuales
  Widget _buildProfileImage() {
    Widget imageWidget;

    if (_selectedImage != null) {
      // Mostrar nueva imagen seleccionada
      imageWidget = ClipOval(
        child: Image.file(
          _selectedImage!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      );
    } else if (_imageRemoved) {
      // Imagen eliminada, mostrar placeholder
      imageWidget = _buildPlaceholderImage();
    } else if (_originalFoto != null && _originalFoto!.isNotEmpty) {
      // Mostrar imagen original del servidor
      imageWidget = ClipOval(
        child: Image.network(
          _originalFoto!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gray300,
              ),
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            // Si hay error cargando la imagen de red, mostrar placeholder
            return _buildPlaceholderImage();
          },
        ),
      );
    } else {
      // No hay imagen original, mostrar placeholder
      imageWidget = _buildPlaceholderImage();
    }

    return Stack(
      children: [
        imageWidget,
        // Botón flotante para cambiar imagen
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: IconButton(
              onPressed: _selectImage,
              icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              iconSize: 20,
            ),
          ),
        ),
        // Indicador de cambio
        if (_selectedImage != null || _imageRemoved)
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _imageRemoved ? Colors.red : Colors.green,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                _imageRemoved ? Icons.delete : Icons.check,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
      ],
    );
  }

  // Widget para mostrar placeholder cuando no hay imagen
  Widget _buildPlaceholderImage() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withOpacity(0.1),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
      ),
      child: const Icon(Icons.person, size: 60, color: AppColors.primary),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _cedulaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Imagen de perfil mejorada
              _buildProfileImage(),

              const SizedBox(height: 32),

              // Campo Nombre
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  hintText: 'Ingrese su nombre completo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                maxLength: 100,
                validator: _validateNombre,
                style: const TextStyle(color: AppColors.text),
              ),

              const SizedBox(height: 16),

              // Campo Teléfono
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono (opcional)',
                  hintText: '0987654321 o 0234567890',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                  helperText: 'Móvil: 09XXXXXXXX, Fijo: 0[2-7]XXXXXXX',
                  helperMaxLines: 2,
                ),
                keyboardType: TextInputType.phone,
                maxLength: 10,
                validator: _validateTelefono,
                style: const TextStyle(color: AppColors.text),
              ),

              const SizedBox(height: 16),

              // Botón Guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_hasChanges && !_loading) ? _saveProfile : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasChanges
                        ? AppColors.primary
                        : AppColors.gray300,
                    foregroundColor: _hasChanges
                        ? Colors.white
                        : AppColors.gray500,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: _hasChanges ? 2 : 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Guardar Cambios',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Información adicional
              if (!_hasChanges)
                const Text(
                  'Modifica algún campo para habilitar el botón Guardar',
                  style: TextStyle(color: AppColors.gray500, fontSize: 12),
                  textAlign: TextAlign.center,
                ),

              if (_hasChanges)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Hay cambios pendientes por guardar',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
