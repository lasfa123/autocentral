// lib/features/vehicles/vehicle_form_page.dart
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:image/image.dart' as img;
import '../../core/models/vehicle.dart';
import '../../core/services/vehicle_service.dart';
import '../../widgets/modern_calendar_picker.dart';

class VehicleFormPage extends StatefulWidget {
  final CarModel? vehicle;

  const VehicleFormPage({super.key, this.vehicle});

  @override
  State<VehicleFormPage> createState() => _VehicleFormPageState();
}

class _VehicleFormPageState extends State<VehicleFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _licenseController = TextEditingController();
  final _registrationController = TextEditingController();
  final _yearController = TextEditingController();
  final _mileageController = TextEditingController();

  DateTime? _purchaseDate;
  DateTime? _insuranceExpiry;
  DateTime? _inspectionExpiry;
  Uint8List? _selectedImageData;
  String? _selectedImageName;
  String? _existingPhotoBase64; // Changé de photoUrl à photoBase64

  bool _isLoading = false;
  bool _isEditing = false;
  bool _isCompressing = false;

  // Limite pour Firestore : 1MB
  static const int maxImageSize = 800 * 1024; // 800KB pour avoir de la marge

  final List<String> _popularBrands = [
    'Peugeot', 'Renault', 'Citroën', 'Toyota', 'Volkswagen',
    'BMW', 'Mercedes-Benz', 'Audi', 'Ford', 'Nissan', 'Hyundai'
  ];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.vehicle != null;
    if (_isEditing) {
      _populateFormWithVehicleData();
    } else {
      _purchaseDate = DateTime.now();
      _insuranceExpiry = DateTime.now().add(const Duration(days: 365));
      _inspectionExpiry = DateTime.now().add(const Duration(days: 365));
    }
  }

  void _populateFormWithVehicleData() {
    final vehicle = widget.vehicle!;
    _brandController.text = vehicle.brand;
    _modelController.text = vehicle.model;
    _licenseController.text = vehicle.licensePlate;
    _registrationController.text = vehicle.registrationNumber;
    _yearController.text = vehicle.year.toString();
    _mileageController.text = vehicle.mileage.toString();
    _purchaseDate = vehicle.purchaseDate;
    _insuranceExpiry = vehicle.insuranceExpiry;
    _inspectionExpiry = vehicle.inspectionExpiry;
    _existingPhotoBase64 = vehicle.photoUrl; // Supposant que c'est déjà en Base64
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _licenseController.dispose();
    _registrationController.dispose();
    _yearController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Modifier le véhicule' : 'Ajouter un véhicule',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildPhotoSection(),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: 'Informations générales',
                    icon: Icons.info_outline,
                    children: [
                      _buildBrandField(),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _modelController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Modèle',
                          hintText: 'Ex: Clio, Golf, 308...',
                          prefixIcon: Icon(Icons.directions_car),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez saisir le modèle';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _yearController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Année',
                                hintText: '2020',
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Requis';
                                }
                                final year = int.tryParse(value);
                                if (year == null || year < 1900 || year > DateTime.now().year + 1) {
                                  return 'Année invalide';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _mileageController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Kilométrage',
                                hintText: '50000',
                                suffixText: 'km',
                                prefixIcon: Icon(Icons.speed),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Requis';
                                }
                                final mileage = int.tryParse(value);
                                if (mileage == null || mileage < 0) {
                                  return 'Invalide';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: 'Immatriculation',
                    icon: Icons.confirmation_number,
                    children: [
                      TextFormField(
                        controller: _licenseController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Plaque d\'immatriculation',
                          hintText: 'AA-123-BB',
                          prefixIcon: Icon(Icons.credit_card),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez saisir la plaque d\'immatriculation';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _registrationController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Numéro de carte grise',
                          hintText: 'RG-12345',
                          prefixIcon: Icon(Icons.badge),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez saisir le numéro de carte grise';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: 'Dates importantes',
                    icon: Icons.event,
                    children: [
                      _buildModernDateField(
                        label: 'Date d\'achat',
                        date: _purchaseDate,
                        onDateSelected: (date) => setState(() => _purchaseDate = date),
                        icon: Icons.shopping_cart,
                        firstDate: DateTime(1990),
                        lastDate: DateTime.now(),
                      ),
                      const SizedBox(height: 16),
                      _buildModernDateField(
                        label: 'Échéance assurance',
                        date: _insuranceExpiry,
                        onDateSelected: (date) => setState(() => _insuranceExpiry = date),
                        icon: Icons.security,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                        isImportant: true,
                      ),
                      const SizedBox(height: 16),
                      _buildModernDateField(
                        label: 'Échéance contrôle technique',
                        date: _inspectionExpiry,
                        onDateSelected: (date) => setState(() => _inspectionExpiry = date),
                        icon: Icons.build_circle,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                        isImportant: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.camera_alt_outlined, color: Colors.grey[600]),
              const SizedBox(width: 8),
              const Text(
                'Photo du véhicule',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              if (_isCompressing) ...[
                const SizedBox(width: 12),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  'Compression...',
                  style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _isCompressing ? null : _selectImage,
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _selectedImageData != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(_selectedImageData!, fit: BoxFit.cover),
              )
                  : _existingPhotoBase64 != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  base64Decode(_existingPhotoBase64!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                ),
              )
                  : _buildPlaceholder(),
            ),
          ),
          if (_selectedImageData != null || _existingPhotoBase64 != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: _isCompressing ? null : _selectImage,
                    icon: const Icon(Icons.edit),
                    label: const Text('Modifier'),
                  ),
                  TextButton.icon(
                    onPressed: _isCompressing ? null : _removeImage,
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo, size: 48, color: Colors.grey[400]),
        const SizedBox(height: 12),
        Text(
          'Ajouter une photo',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          'JPG ou PNG (max 800KB après compression)',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildBrandField() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return _popularBrands.where(
              (brand) => brand.toLowerCase().contains(textEditingValue.text.toLowerCase()),
        );
      },
      onSelected: (String selection) {
        _brandController.text = selection;
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        _brandController.text = controller.text;
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Marque',
            hintText: 'Ex: Renault, Toyota, BMW...',
            prefixIcon: Icon(Icons.business),
            suffixIcon: Icon(Icons.arrow_drop_down),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Veuillez saisir la marque';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildModernDateField({
    required String label,
    required DateTime? date,
    required Function(DateTime) onDateSelected,
    required IconData icon,
    DateTime? firstDate,
    DateTime? lastDate,
    bool isImportant = false,
  }) {
    final isExpiringSoon = date != null &&
        date.difference(DateTime.now()).inDays <= 30 &&
        isImportant;
    final isExpired = date != null && date.isBefore(DateTime.now()) && isImportant;

    return InkWell(
      onTap: () async {
        final selectedDate = await showModernCalendarPicker(
          context: context,
          initialDate: date,
          firstDate: firstDate,
          lastDate: lastDate,
          title: label,
        );
        if (selectedDate != null) onDateSelected(selectedDate);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isExpired
              ? LinearGradient(colors: [Colors.red[50]!, Colors.red[100]!])
              : isExpiringSoon
              ? LinearGradient(colors: [Colors.orange[50]!, Colors.orange[100]!])
              : null,
          color: isExpired || isExpiringSoon ? null : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExpired
                ? Colors.red[300]!
                : isExpiringSoon
                ? Colors.orange[300]!
                : Colors.grey[300]!,
            width: isExpired || isExpiringSoon ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isExpired
                    ? Colors.red[600]
                    : isExpiringSoon
                    ? Colors.orange[600]
                    : Colors.blue[600],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    date != null ? _formatDate(date) : 'Sélectionner une date',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: date != null ? Colors.black87 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.calendar_today,
              size: 20,
              color: isExpired
                  ? Colors.red[600]
                  : isExpiringSoon
                  ? Colors.orange[600]
                  : Colors.blue[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading || _isCompressing ? null : _saveVehicle,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
                  : Text(
                _isEditing ? 'Modifier le véhicule' : 'Ajouter le véhicule',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading || _isCompressing ? null : _deleteVehicle,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Supprimer le véhicule',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _selectImage() async {
    try {
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'Images',
        extensions: ['jpg', 'jpeg', 'png'],
      );

      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) return;

      setState(() => _isCompressing = true);

      final imageData = await file.readAsBytes();
      print('Taille originale: ${_formatSize(imageData.length)}');

      // Compresser l'image
      final compressedData = await _compressImage(imageData);

      if (compressedData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la compression de l\'image'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      print('Taille compressée: ${_formatSize(compressedData.length)}');

      if (compressedData.length > maxImageSize) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Image trop volumineuse (${_formatSize(compressedData.length)}). '
                    'Maximum: ${_formatSize(maxImageSize)}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _selectedImageData = compressedData;
        _selectedImageName = file.name;
        _isCompressing = false;
      });
    } catch (e) {
      setState(() => _isCompressing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Uint8List?> _compressImage(Uint8List data) async {
    try {
      // Décoder l'image
      img.Image? image = img.decodeImage(data);
      if (image == null) return null;

      // Redimensionner si trop grande
      if (image.width > 1200 || image.height > 1200) {
        image = img.copyResize(
          image,
          width: image.width > image.height ? 1200 : null,
          height: image.height > image.width ? 1200 : null,
        );
      }

      // Compresser en JPEG avec qualité progressive
      int quality = 85;
      Uint8List? compressed;

      while (quality >= 50) {
        compressed = Uint8List.fromList(img.encodeJpg(image, quality: quality));

        if (compressed.length <= maxImageSize) {
          break;
        }

        quality -= 10;
      }

      return compressed;
    } catch (e) {
      print('Erreur compression: $e');
      return null;
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImageData = null;
      _selectedImageName = null;
      _existingPhotoBase64 = null;
    });
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    if (_purchaseDate == null || _insuranceExpiry == null || _inspectionExpiry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir toutes les dates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Convertir l'image en Base64 si présente
      String? photoBase64;
      if (_selectedImageData != null) {
        photoBase64 = base64Encode(_selectedImageData!);
      } else if (_existingPhotoBase64 != null) {
        photoBase64 = _existingPhotoBase64;
      }

      final vehicle = CarModel(
        id: _isEditing ? widget.vehicle!.id : '',
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        licensePlate: _licenseController.text.trim().toUpperCase(),
        registrationNumber: _registrationController.text.trim().toUpperCase(),
        year: int.parse(_yearController.text),
        mileage: int.parse(_mileageController.text),
        purchaseDate: _purchaseDate!,
        insuranceExpiry: _insuranceExpiry!,
        inspectionExpiry: _inspectionExpiry!,
        photoUrl: photoBase64, // Stocker le Base64 dans photoUrl
      );

      final result = _isEditing
          ? await VehicleService.updateVehicle(vehicle.id, vehicle)
          : await VehicleService.addVehicle(vehicle);

      if (mounted) {
        if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing ? 'Véhicule modifié avec succès' : 'Véhicule ajouté avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errorMessage ?? 'Erreur inconnue'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteVehicle() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le véhicule'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer ce véhicule ? '
              'Cette action supprimera également tous les documents associés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true && _isEditing) {
      setState(() => _isLoading = true);

      final result = await VehicleService.deleteVehicle(widget.vehicle!.id);

      if (mounted) {
        if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Véhicule supprimé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errorMessage ?? 'Erreur lors de la suppression'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}