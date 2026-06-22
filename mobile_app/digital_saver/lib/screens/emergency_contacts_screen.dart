import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:digital_saver/services/storage_service.dart';
import 'package:digital_saver/models/health_data.dart';
import 'package:digital_saver/i18n/app_localizations.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final storage = Provider.of<StorageService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.emergencyContacts),
      ),
      body: storage.emergencyContacts.isEmpty
          ? _buildEmptyState(context, l10n)
          : ListView.builder(
              itemCount: storage.emergencyContacts.length,
              itemBuilder: (context, index) {
                final contact = storage.emergencyContacts[index];
                return _buildContactCard(context, contact, index, l10n, storage);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddContactDialog(context, l10n, storage),
        icon: const Icon(Icons.add),
        label: Text(l10n.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.contacts,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No emergency contacts added',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add a contact',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context,
    EmergencyContact contact,
    int index,
    AppLocalizations l10n,
    StorageService storage,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: contact.isPrimary ? Colors.red : Colors.grey,
          child: Icon(
            contact.isPrimary ? Icons.star : Icons.person,
            color: Colors.white,
          ),
        ),
        title: Text(
          contact.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contact.phone),
            Text(
              contact.relationship,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit),
                  const SizedBox(width: 8),
                  Text(l10n.edit),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _showEditContactDialog(context, contact, index, l10n, storage);
            } else if (value == 'delete') {
              _showDeleteConfirmation(context, index, l10n, storage);
            }
          },
        ),
      ),
    );
  }

  void _showAddContactDialog(
    BuildContext context,
    AppLocalizations l10n,
    StorageService storage,
  ) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationshipController = TextEditingController();
    bool isPrimary = storage.emergencyContacts.isEmpty;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.add),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.name,
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: l10n.phone,
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: relationshipController,
                decoration: InputDecoration(
                  labelText: l10n.relationship,
                  prefixIcon: const Icon(Icons.family_restroom),
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: isPrimary,
                onChanged: (value) => isPrimary = value ?? false,
                title: Text(l10n.primaryContact),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                storage.addEmergencyContact(EmergencyContact(
                  name: nameController.text,
                  phone: phoneController.text,
                  relationship: relationshipController.text,
                  isPrimary: isPrimary,
                ));
                Navigator.pop(context);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showEditContactDialog(
    BuildContext context,
    EmergencyContact contact,
    int index,
    AppLocalizations l10n,
    StorageService storage,
  ) {
    final nameController = TextEditingController(text: contact.name);
    final phoneController = TextEditingController(text: contact.phone);
    final relationshipController = TextEditingController(text: contact.relationship);
    bool isPrimary = contact.isPrimary;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.edit),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.name,
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: l10n.phone,
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: relationshipController,
                decoration: InputDecoration(
                  labelText: l10n.relationship,
                  prefixIcon: const Icon(Icons.family_restroom),
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: isPrimary,
                onChanged: (value) => isPrimary = value ?? false,
                title: Text(l10n.primaryContact),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                storage.updateEmergencyContact(
                  index,
                  EmergencyContact(
                    name: nameController.text,
                    phone: phoneController.text,
                    relationship: relationshipController.text,
                    isPrimary: isPrimary,
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    int index,
    AppLocalizations l10n,
    StorageService storage,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: const Text('Are you sure you want to delete this contact?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              storage.removeEmergencyContact(index);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}
