import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_app/providers/current_school_provider.dart';



class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override

  ConsumerState<GroupsScreen> createState() =>
      _GroupsScreenState();
}
String? schoolId;
class _GroupsScreenState
    extends ConsumerState<GroupsScreen> {




  @override
  Widget build(BuildContext context) {



final schoolAsync =
    ref.watch(
      currentSchoolProvider,
    );

final school =
    schoolAsync.value;
if (school != null) {
  schoolId = school.id;
}

    final isMobile =
        MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('School Structure'),
      ),




      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: () {
                _showAddGroupDialog(context);
              },
              child: const Icon(Icons.add),
            )
          : null,





      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1200,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            
            child: Column(
  crossAxisAlignment:
      CrossAxisAlignment.start,
  children: [

                Row(

  mainAxisAlignment:
      MainAxisAlignment.spaceBetween,

  children: [

    const Text(
      'Groups',
      style: TextStyle(
        fontSize: 22,
        fontWeight:
            FontWeight.bold,
      ),
    ),

    ElevatedButton.icon(

      onPressed: () {
        _showAddGroupDialog(
          context,
        );
      },

      icon:
          const Icon(Icons.add),

      label:
          const Text(
        'Add Group',
      ),
    ),
  ],
),

const SizedBox(height: 16),
                
                Expanded(
  child: StreamBuilder<QuerySnapshot>(

stream: schoolAsync.when(

  data: (school) {

    return FirebaseFirestore.instance
        .collection('schools')
        .doc(school.id)
        .collection('groups')
        .orderBy('order')
        .snapshots();
  },

  loading: () => const Stream.empty(),

  error: (_, __) => const Stream.empty(),
),




       
    builder: (context, snapshot) {

      if (!snapshot.hasData) {
        return const Center(
          child:
              CircularProgressIndicator(),
        );
      }

      final docs =
          snapshot.data!.docs;

      if (docs.isEmpty) {
        return const Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [

            Icon(
              Icons.account_tree_outlined,
              size: 80,
              color: Colors.grey,
            ),

            SizedBox(height: 16),

            Text(
              'No Groups Created Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        );
      }

      return ListView.builder(
        itemCount: docs.length,
        itemBuilder: (context, index) {

          final data =
              docs[index].data()
                  as Map<String, dynamic>;

        return Container(

  margin:
      const EdgeInsets.only(
    bottom: 12,
  ),

  decoration: BoxDecoration(

    color: Colors.white,

    borderRadius:
        BorderRadius.circular(16),

    boxShadow: [

      BoxShadow(

        color:
            Colors.black
                .withOpacity(0.04),

        blurRadius: 10,

        offset:
            const Offset(0, 3),
      ),
    ],
  ),

  child: ListTile(
              leading: 
              
           Container(

  width: 48,

  height: 48,

  decoration:
      BoxDecoration(

    color: Theme.of(context)
        .colorScheme
        .primary
        .withOpacity(0.1),

    borderRadius:
        BorderRadius.circular(
      12,
    ),
  ),

  child: Center(

    child: Text(

      '${index + 1}',

      style: TextStyle(

        color:
            Theme.of(context)
                .colorScheme
                .primary,

        fontWeight:
            FontWeight.bold,
      ),
    ),
  ),
),


             
             title: Text(
  data['name'] ?? '',
),

subtitle: const Text(
  'Group',
),
trailing: 








PopupMenuButton<String>(

  onSelected: (value) async {

    final docId =
        docs[index].id;

    if (value == 'delete') {

      final confirm =
          await showDialog<bool>(

        context: context,

        builder: (_) =>
            AlertDialog(

          title: const Text(
            'Delete Group',
          ),

          content: Text(
            'Delete ${data['name']}?',
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
                  const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child:
                  const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirm == true) {

        await FirebaseFirestore
            .instance
            .collection('schools')
            .doc(schoolId)
            .collection('groups')
            .doc(docId)
            .delete();
      }
    }

    if (value == 'edit') {

      final controller =
          TextEditingController(
        text:
            data['name'],
      );

      final result =
          await showDialog<String>(

        context: context,

        builder: (_) =>
            AlertDialog(

          title: const Text(
            'Edit Group',
          ),

          content: TextField(
            controller:
                controller,
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              child:
                  const Text(
                'Cancel',
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  controller.text
                      .trim(),
                );
              },
              child:
                  const Text(
                'Save',
              ),
            ),
          ],
        ),
      );

      if (result != null &&
          result.isNotEmpty) {

        await FirebaseFirestore
            .instance
            .collection('schools')
            .doc(schoolId)
            .collection('groups')
            .doc(docId)
            .update({

          'name': result,

          'searchName':
              result
                  .toLowerCase(),
        });
      }
    }
  },

 itemBuilder: (_) => [

  const PopupMenuItem(
    value: 'edit',
    child: Text('Edit'),
  ),

  const PopupMenuItem(
    value: 'move_up',
    child: Text('Move Up'),
  ),

  const PopupMenuItem(
    value: 'move_down',
    child: Text('Move Down'),
  ),

  const PopupMenuItem(
    value: 'delete',
    child: Text('Delete'),
  ),
],
),



              onTap: () {
                // Navigate to group details or edit screen
              },
            ),
          );
        },
      );
    },
  ),
),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


Future<void> _showAddGroupDialog(
  BuildContext context,
) async


 {
  final controller =
      TextEditingController();

  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: const Text(
          'Add Group',
        ),

        content: TextField(
          controller: controller,
          decoration:
              const InputDecoration(
            labelText: 'Group Name',
          ),
        ),

        actions: [

          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },




            child: const Text('Cancel'),
          ),

        ElevatedButton(
  onPressed: () async {

    if (controller.text
        .trim()
        .isEmpty) {
      return;
    }

    

    if (schoolId == null) {
  return;
}

final existing =
    await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('groups')
     .where(
  'searchName',
  isEqualTo:
      controller.text
          .trim()
          .toLowerCase(),
)
        .limit(1)
        .get();

if (existing.docs.isNotEmpty) {

  ScaffoldMessenger.of(context)
      .showSnackBar(

    const SnackBar(

      content: Text(
        'Group already exists',
      ),
    ),
  );

  return;
}


await FirebaseFirestore.instance
    .collection('schools')
    .doc(schoolId)
    .collection('groups')
    .add({

  'name':
    controller.text.trim(),

'searchName':
    controller.text
        .trim()
        .toLowerCase(),

  'order':
      DateTime.now()
          .millisecondsSinceEpoch,

  'isActive': true,

  'createdAt':
      FieldValue.serverTimestamp(),
});

Navigator.pop(context);
  },



            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}