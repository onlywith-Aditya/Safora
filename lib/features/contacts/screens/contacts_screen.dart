import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_input.dart';
import '../../../routes/app_routes.dart';
import '../../auth/services/auth_service.dart';

class ContactsScreen extends StatefulWidget {
  final bool isStandalone;
  const ContactsScreen({super.key, this.isStandalone = false});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  late List<Map<String, String>> _contacts;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  void _loadContacts() {
    final user = AuthService().currentUser;
    final rawList = user?['contacts'] ?? user?['emergencyContacts'];
    if (rawList != null && rawList is List && rawList.isNotEmpty) {
      _contacts = rawList.map((c) {
        final map = c is Map ? c : {};
        return {
          'name': (map['name'] ?? map['fullName'] ?? 'Contact').toString(),
          'phone': (map['phone'] ?? map['phoneNumber'] ?? '').toString(),
          'relation': (map['relation'] ?? map['relationship'] ?? 'Family').toString(),
        };
      }).toList();
    } else {
      _contacts = [
        {'name': 'Rajesh Sharma', 'phone': '+91 98765 43210', 'relation': 'Father'},
        {'name': 'Anita Verma', 'phone': '+91 91234 56744', 'relation': 'Sister'},
        {'name': 'Dr. Mehta', 'phone': '+91 90000 11122', 'relation': 'Family Doctor'},
      ];
    }
  }

  void _showAddEditContactDialog({int? index}) {
    final isEdit = index != null;
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: isEdit ? _contacts[index]['name'] : '');
    final phoneCtrl = TextEditingController(text: isEdit ? _contacts[index]['phone'] : '');
    final relationCtrl = TextEditingController(text: isEdit ? _contacts[index]['relation'] : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Edit Contact' : 'Add Emergency Contact',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                CustomInputField(
                  label: 'Name',
                  hintText: 'e.g. Rajesh Sharma',
                  controller: nameCtrl,
                  isRequired: true,
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter contact name'
                      : null,
                ),
                const SizedBox(height: 12),
                CustomInputField(
                  label: 'Phone Number',
                  hintText: 'e.g. +91 98765 43210',
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  isRequired: true,
                  prefixIcon: Icons.phone_outlined,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter phone number';
                    }
                    if (v.trim().length < 8) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                CustomInputField(
                  label: 'Relation',
                  hintText: 'e.g. Father, Sister, Friend',
                  controller: relationCtrl,
                  isRequired: true,
                  prefixIcon: Icons.people_outline_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter relation'
                      : null,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }

                      final name = nameCtrl.text.trim();
                      final phone = phoneCtrl.text.trim();
                      final relation = relationCtrl.text.trim();

                      if (name.isEmpty || phone.isEmpty || relation.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('All fields are required'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                        return;
                      }

                      setState(() {
                        if (isEdit) {
                          _contacts[index] = {
                            'name': name,
                            'phone': phone,
                            'relation': relation,
                          };
                        } else {
                          _contacts.add({
                            'name': name,
                            'phone': phone,
                            'relation': relation,
                          });
                        }
                      });

                      // Persist directly to Cloud Firestore
                      AuthService().updateContacts(_contacts);

                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      isEdit ? 'Save Changes' : 'Add Contact',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteContact(int index) {
    setState(() {
      _contacts.removeAt(index);
    });
    // Persist removal to Cloud Firestore
    AuthService().updateContacts(_contacts);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contact removed'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: AppColors.headerPink,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () {
              if (widget.isStandalone) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, AppRoutes.home);
              }
            },
          ),
          title: const Text(
            'Emergency Contacts',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          centerTitle: false,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          children: [
            // List of Contact Cards
            ...List.generate(_contacts.length, (index) {
              final contact = _contacts[index];
              final initial = contact['name']!.isNotEmpty ? contact['name']![0].toUpperCase() : 'C';

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 12,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Pink Initial Circle
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFB8D2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Contact Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contact['name']!,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${contact['relation']} • ${contact['phone']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Edit Pencil Icon
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Color(0xFFFF72AC), size: 20),
                      onPressed: () => _showAddEditContactDialog(index: index),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),

                    // Delete Trash Icon
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.dangerRed, size: 20),
                      onPressed: () => _deleteContact(index),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 8),

            // + Add New Contact Button (Dashed outlined style)
            InkWell(
              onTap: () => _showAddEditContactDialog(),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFF85B7),
                    width: 1.5,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Add New Contact',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0), width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: 1, // Contacts Tab Active
        onTap: (idx) {
          if (idx == 0) {
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          } else if (idx == 3) {
            Navigator.pushReplacementNamed(context, AppRoutes.profile);
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline_rounded),
            activeIcon: Icon(Icons.people_rounded),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications_rounded),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
