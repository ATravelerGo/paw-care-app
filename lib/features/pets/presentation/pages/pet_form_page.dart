import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/route_paths.dart';
import '../../../../core/error/app_exception.dart';
import '../../application/pet_controller.dart';
import '../../application/pet_providers.dart';
import '../../domain/models/pet.dart';

class PetFormPage extends ConsumerStatefulWidget {
  const PetFormPage({this.petId, super.key});

  final String? petId;

  @override
  ConsumerState<PetFormPage> createState() => _PetFormPageState();
}

class _PetFormPageState extends ConsumerState<PetFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  String _species = 'dog';
  String? _gender;
  bool _didPopulate = false;

  bool get _isEditing => widget.petId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      Future.microtask(() => ref.read(petControllerProvider).load());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(petControllerProvider);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final pet = _isEditing ? controller.petById(widget.petId!) : null;
        if (_isEditing &&
            pet == null &&
            controller.status == PetListStatus.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (_isEditing && pet == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('编辑宠物')),
            body: const Center(child: Text('未找到这只宠物。')),
          );
        }
        _populateFrom(pet);
        return Scaffold(
          appBar: AppBar(title: Text(_isEditing ? '编辑宠物' : '创建宠物档案')),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    _isEditing ? '更新宠物的基本信息' : '先填写基本信息，之后可随时修改。',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    key: const Key('pet_name_field'),
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: '宠物名字',
                      hintText: '例如：团子',
                    ),
                    validator: _requiredValidator('请填写宠物名字'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: const Key('pet_species_field'),
                    initialValue: _species,
                    decoration: const InputDecoration(labelText: '种类'),
                    items: const [
                      DropdownMenuItem(value: 'dog', child: Text('狗狗')),
                      DropdownMenuItem(value: 'cat', child: Text('猫咪')),
                    ],
                    onChanged: controller.isSaving
                        ? null
                        : (value) => setState(() => _species = value!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('pet_breed_field'),
                    controller: _breedController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: '品种（可选）',
                      hintText: '例如：金毛、英短',
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    key: const Key('pet_gender_field'),
                    initialValue: _gender,
                    decoration: const InputDecoration(labelText: '性别（可选）'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('暂不填写')),
                      DropdownMenuItem(value: 'male', child: Text('男孩')),
                      DropdownMenuItem(value: 'female', child: Text('女孩')),
                    ],
                    onChanged: controller.isSaving
                        ? null
                        : (value) => setState(() => _gender = value),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    key: const Key('save_pet_button'),
                    onPressed: controller.isSaving
                        ? null
                        : () => _submit(controller),
                    child: controller.isSaving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isEditing ? '保存修改' : '创建宠物档案'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _populateFrom(Pet? pet) {
    if (_didPopulate || pet == null) return;
    _didPopulate = true;
    _nameController.text = pet.name;
    _breedController.text = pet.breed ?? '';
    _species = pet.species.trim().toLowerCase() == 'cat' ? 'cat' : 'dog';
    _gender = pet.gender;
  }

  Future<void> _submit(PetController controller) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final draft = PetDraft(
      name: _nameController.text,
      species: _species,
      breed: _breedController.text,
      gender: _gender,
    );
    try {
      final pet = _isEditing
          ? await controller.updatePet(widget.petId!, draft)
          : await controller.createPet(draft);
      if (mounted) context.go(AppRoutePaths.petDetails(pet.id));
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_messageFor(error))));
    }
  }
}

String? Function(String?) _requiredValidator(String message) {
  return (value) => value == null || value.trim().isEmpty ? message : null;
}

String _messageFor(Object error) {
  return error is AppException ? error.message : '保存失败，请稍后重试。';
}
