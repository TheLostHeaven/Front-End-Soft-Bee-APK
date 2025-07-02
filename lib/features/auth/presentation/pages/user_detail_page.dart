import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sotfbee/features/auth/data/models/user_model.dart';

class UserDetailPage extends StatelessWidget {
  final UserProfile user;

  const UserDetailPage({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles del Usuario'),
        backgroundColor: Colors.amber,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundImage: user.profilePicture != 'default_profile.jpg'
                    ? NetworkImage(
                        'https://softbee-back-end-1.onrender.com/api/uploads/${user.profilePicture}',
                      )
                    : AssetImage('images/userSoftbee.png') as ImageProvider,
              ),
            ),
            SizedBox(height: 24),
            _buildDetailRow('Nombre:', user.name),
            _buildDetailRow('Username:', user.username),
            _buildDetailRow('Email:', user.email),
            _buildDetailRow('Teléfono:', user.phone),
            _buildDetailRow('ID:', user.id.toString()),
            _buildDetailRow('Rol:', user.role),
            _buildDetailRow('Verificado:', user.isVerified ? 'Sí' : 'No'),
            _buildDetailRow('Activo:', user.isActive ? 'Sí' : 'No'),
            _buildDetailRow(
              'Fecha de Creación:',
              user.createdAt.toLocal().toString().split('.')[0],
            ),
            _buildDetailRow(
              'Última Actualización:',
              user.updatedAt.toLocal().toString().split('.')[0],
            ),

            if (user.apiaries.isNotEmpty) ...[
              SizedBox(height: 24),
              Text(
                'Apiarios:',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              ...user.apiaries
                  .map(
                    (apiary) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        '- ${apiary.name} (ID: ${apiary.id})',
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                    ),
                  )
                  .toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(value, style: GoogleFonts.poppins(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
