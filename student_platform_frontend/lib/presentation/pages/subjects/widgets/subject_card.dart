import 'package:flutter/material.dart';
import '../../../../data/models/subject.dart';

class SubjectCard extends StatelessWidget {
  final Subject subject;
  final bool isAdmin;
  final VoidCallback onTap;
  final Function(String) onMenuSelected;

  const SubjectCard({
    super.key,
    required this.subject,
    required this.isAdmin,
    required this.onTap,
    required this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = subject.isDisabled;
    return Card(
      elevation: 0,
      color: isDisabled ? Colors.grey.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDisabled ? Colors.grey.shade300 : Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        hoverColor: const Color(0xFF1E3A8A).withOpacity(0.05),
        onTap: isDisabled && !isAdmin ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDisabled ? Colors.grey.shade300 : const Color(0xFF1E3A8A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.menu_book, color: isDisabled ? Colors.grey.shade500 : const Color(0xFF1E3A8A), size: 28),
                  ),
                  if (isAdmin)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      onSelected: onMenuSelected,
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'groups', child: Row(children: [Icon(Icons.group, size: 18, color: Colors.indigo), SizedBox(width: 8), Text('Guruhlarga biriktirish')])),
                        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18, color: Colors.blue), SizedBox(width: 8), Text('Tahrirlash')])),
                        PopupMenuItem(value: 'toggle', child: Row(children: [Icon(isDisabled ? Icons.visibility : Icons.visibility_off, size: 18, color: Colors.orange), SizedBox(width: 8), Text(isDisabled ? 'Faollashtirish' : 'Faolsizlashtirish')])),
                        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('O\'chirish', style: TextStyle(color: Colors.red))])),
                      ]
                    ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      subject.name,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDisabled ? Colors.grey.shade600 : Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isDisabled)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(4)),
                      child: const Text('Faolsiz', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                ],
              ),
              const SizedBox(height: 8),
              Text(
                subject.description.isEmpty ? 'Ta\'rif yo\'q' : subject.description,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
