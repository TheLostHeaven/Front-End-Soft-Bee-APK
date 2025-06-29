import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sotfbee/features/auth/data/datasources/user_service.dart';
import 'package:sotfbee/features/auth/data/models/user_model.dart';

class UserManagementPage extends StatefulWidget {
  final UserProfile? user;

  const UserManagementPage({Key? key, this.user}) : super(key: key);

  @override
  _UserManagementPageState createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  List<UserProfile> _users = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  UserProfile? get currentUser => widget.user;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await UserService.getAllUsers();
      if (!mounted) return;

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar usuarios: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<UserProfile> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    final query = _searchQuery.toLowerCase();
    return _users.where((user) {
      return user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.phone.toLowerCase().contains(query) ||
          user.username.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión de Usuarios', style: GoogleFonts.poppins()),
        backgroundColor: Colors.amber,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Recargar usuarios',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (currentUser != null) _buildCurrentUserCard(),
            _buildSearchBar(),
            Expanded(child: _buildUserList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateUserDialog,
        backgroundColor: Colors.amber,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Crear nuevo usuario',
      ),
    );
  }

  Widget _buildCurrentUserCard() {
    final user = currentUser!;
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: _getProfileImage(user.profilePictureUrl),
            ),
            const SizedBox(height: 16),
            ..._buildUserDetails(user),
          ],
        ),
      ),
    );
  }

  ImageProvider _getProfileImage(String url) {
    if (url.isEmpty || url == 'images/userSoftbee.png') {
      return const AssetImage('images/userSoftbee.png');
    }
    return NetworkImage(url);
  }

  List<Widget> _buildUserDetails(UserProfile user) {
    return [
      _buildDetailRow('Nombre:', user.name),
      _buildDetailRow('Email:', user.email),
      _buildDetailRow('Teléfono:', user.phone),
      _buildDetailRow('Usuario:', user.username),
      _buildDetailRow('ID:', user.id.toString()),
      if (user.apiaries.isNotEmpty)
        _buildDetailRow(
          'Apiarios:',
          user.apiaries.map((a) => a.name).join(', '),
        ),
    ];
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: GoogleFonts.poppins(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'Buscar usuarios...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildUserList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    if (_filteredUsers.isEmpty) {
      return _buildEmptyWidget();
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: _getProfileImage(user.profilePictureUrl),
            ),
            title: Text(
              user.name,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email),
                Text(user.phone),
                if (user.apiaries.isNotEmpty)
                  Text('${user.apiaries.length} apiarios'),
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) => _handlePopupSelection(value, user),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: const [
                      Icon(Icons.edit, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: const [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Eliminar'),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () => _showUserDetails(user),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error al cargar usuarios',
            style: GoogleFonts.poppins(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Error desconocido',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadUsers,
            child: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No se encontraron usuarios',
            style: GoogleFonts.poppins(fontSize: 18),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'No hay resultados para "$_searchQuery"',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: const Text('Limpiar búsqueda'),
            ),
          ],
        ],
      ),
    );
  }

  void _handlePopupSelection(String value, UserProfile user) {
    switch (value) {
      case 'edit':
        _showEditUserDialog(user);
        break;
      case 'delete':
        _showDeleteConfirmation(user);
        break;
    }
  }

  void _showUserDetails(UserProfile user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Detalles de usuario'),
            backgroundColor: Colors.amber,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildUserDetails(user),
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateUserDialog() {
    showDialog(
      context: context,
      builder: (context) => _UserFormDialog(
        title: 'Crear Usuario',
        onSubmit: (data) async {
          final result = await UserService.createUser(
            nombre: data['nombre'] ?? '',
            username: data['username'] ?? '',
            email: data['email'] ?? '',
            phone: data['phone'] ?? '',
            password: data['password'] ?? '',
          );

          if (result['success'] == true) {
            _loadUsers();
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Usuario creado exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Error al crear usuario'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _showEditUserDialog(UserProfile user) {
    showDialog(
      context: context,
      builder: (context) => _UserFormDialog(
        title: 'Editar Usuario',
        initialData: {
          'nombre': user.name,
          'email': user.email,
          'phone': user.phone,
        },
        onSubmit: (data) async {
          final result = await UserService.updateUser(
            userId: user.id,
            nombre: data['nombre'] ?? '',
            email: data['email'] ?? '',
            phone: data['phone'] ?? '',
          );

          if (result['success'] == true) {
            _loadUsers();
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Usuario actualizado exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result['message'] ?? 'Error al actualizar usuario',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _showDeleteConfirmation(UserProfile user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de eliminar a ${user.name}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteUser(user.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(int userId) async {
    try {
      final result = await UserService.deleteUser(userId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['success'] == true
                ? 'Usuario eliminado exitosamente'
                : result['message'] ?? 'Error al eliminar usuario',
          ),
          backgroundColor: result['success'] == true
              ? Colors.green
              : Colors.red,
        ),
      );

      if (result['success'] == true) {
        _loadUsers();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar usuario: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _UserFormDialog extends StatefulWidget {
  final String title;
  final Map<String, String>? initialData;
  final Function(Map<String, String>) onSubmit;

  const _UserFormDialog({
    required this.title,
    this.initialData,
    required this.onSubmit,
  });

  @override
  __UserFormDialogState createState() => __UserFormDialogState();
}

class __UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _nameController.text = widget.initialData!['nombre'] ?? '';
      _emailController.text = widget.initialData!['email'] ?? '';
      _phoneController.text = widget.initialData!['phone'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialData != null;

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre completo'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Este campo es requerido'
                    : null,
              ),
              if (!isEditing) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de usuario',
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Este campo es requerido'
                      : null,
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Este campo es requerido';
                  if (!value.contains('@')) return 'Ingresa un email válido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone,
                validator: (value) => value == null || value.isEmpty
                    ? 'Este campo es requerido'
                    : null,
              ),
              if (!isEditing) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Este campo es requerido';
                    if (value.length < 8) return 'Mínimo 8 caracteres';
                    return null;
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitForm,
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(isEditing ? 'Actualizar' : 'Crear'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final formData = {
          'nombre': _nameController.text.trim(),
          if (!(widget.initialData?.containsKey('username') ?? false))
            'username': _usernameController.text.trim().toLowerCase(),
          'email': _emailController.text.trim().toLowerCase(),
          'phone': _phoneController.text.trim(),
          if (_passwordController.text.isNotEmpty)
            'password': _passwordController.text.trim(),
        };

        await widget.onSubmit(formData);
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
}
