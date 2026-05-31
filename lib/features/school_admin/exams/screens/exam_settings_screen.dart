import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_app/features/school_admin/layout/admin_layout.dart';
import '../widgets/add_exam_name_dialog.dart';
import 'package:school_app/providers/current_school_provider.dart';
import '../providers/exam_names_provider.dart';
import '../services/exam_name_service.dart';


class ExamSettingsScreen
    extends ConsumerStatefulWidget {
  
  
const ExamSettingsScreen({super.key});

@override
ConsumerState<ExamSettingsScreen>
    createState() =>
        _ExamSettingsScreenState();
}

class _ExamSettingsScreenState
    extends ConsumerState<ExamSettingsScreen> {

  

final _service =
    ExamNameService();



  @override
  Widget build(BuildContext context) {
    
    final schoolAsync =
    ref.watch(
      currentSchoolProvider,
    );
    
    return AdminLayout(
      title: 'Exam Settings',
      
      
      
      body: ListView(
  padding: const EdgeInsets.all(16),
  children: [

    Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [

        const Text(
          'Exam Names',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        ElevatedButton.icon(
       onPressed: () async {

  final result =
      await showDialog<String>(
    context: context,
    builder: (_) =>
        const AddExamNameDialog(),
  );





if (result != null &&
    result.isNotEmpty) {

  final school = schoolAsync.value;

  if (school == null) {
    return;
  }

  try {

    await _service.addExamName(
      schoolId: school.id,
      name: result,
    );

  } catch (e) {

    if (mounted) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
        ),
      );
    }
  }
}
},
          icon: const Icon(Icons.add),
          label: const Text(
            'Add Exam Name',
          ),
        ),
      ],
    ),

    const SizedBox(height: 20),



schoolAsync.when(

  data: (school) {

    final examNamesAsync =
        ref.watch(
          examNamesProvider(
            school.id,
          ),
        );

    return examNamesAsync.when(

      data: (docs) {

        if (docs.isEmpty) {

          return const Card(
            child: ListTile(



              leading: CircleAvatar(
                child: Icon(
                  Icons.description,
                ),
              ),




              title: Text(
                'No Exam Names Added Yet',
              ),
              subtitle: Text(
                'Click Add Exam Name to get started',
              ),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {

            final data = doc.data();

            final name =
                data['name'] ?? '';

            return Card(
              child: ListTile(




            leading: CircleAvatar(
  backgroundColor:
      Colors.deepPurple.shade50,
  child: Text(
    '${docs.indexOf(doc) + 1}',
    style: const TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.deepPurple,
    ),
  ),
),




                title: Text(
  name,
  style: const TextStyle(
    fontWeight: FontWeight.w600,
  ),
),

             trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [




    IconButton(
  icon: const Icon(
    Icons.edit,
    color: Colors.blue,
  ),
  onPressed: () async {

    final updated =
        await showDialog<String>(
      context: context,
      builder: (_) => AddExamNameDialog(
        initialValue: name,
      ),
    );

    if (updated == null ||
        updated.isEmpty ||
        updated == name) {
      return;
    }

    await _service.updateExamName(
      schoolId: school.id,
      docId: doc.id,
      name: updated,
    );

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Exam name updated',
          ),
        ),
      );
    }
  },
),





IconButton(
  icon: const Icon(
    Icons.delete,
    color: Colors.red,
  ),
  onPressed: () async {

    final confirm =
        await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Delete Exam Name',
        ),
        content: Text(
          'Delete "$name" ?',
        ),
        actions: [

          TextButton(
            onPressed: () {
              Navigator.pop(
                context,
                false,
              );
            },
            child: const Text(
              'Cancel',
            ),
          ),

          ElevatedButton(
            onPressed: () {
              Navigator.pop(
                context,
                true,
              );
            },
            child: const Text(
              'Delete',
            ),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    await _service.deleteExamName(
      schoolId: school.id,
      docId: doc.id,
    );
  },
),


  ],
),



              ),
            );
          }).toList(),
        );
      },

      loading: () =>
          const Center(
        child:
            CircularProgressIndicator(),
      ),

      error: (e, _) =>
          Text(
        e.toString(),
      ),
    );
  },

  loading: () =>
      const Center(
    child:
        CircularProgressIndicator(),
  ),

  error: (e, _) =>
      Text(
    e.toString(),
  ),
),
  
  ],
),
   
    );
  }
}