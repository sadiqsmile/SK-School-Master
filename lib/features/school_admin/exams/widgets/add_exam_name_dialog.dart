import 'package:flutter/material.dart';

class AddExamNameDialog extends StatefulWidget {

  final String? initialValue;

  const AddExamNameDialog({
    super.key,
    this.initialValue,
  });

  @override
  State<AddExamNameDialog> createState() =>
      _AddExamNameDialogState();
}

class _AddExamNameDialogState
    extends State<AddExamNameDialog> {

@override
void initState() {
  super.initState();

  controller.text =
      widget.initialValue ?? '';
}


  final controller =
      TextEditingController();

  @override
  Widget build(BuildContext context) {

    return AlertDialog(



   title: Text(
  widget.initialValue == null
      ? 'Add Exam Name'
      : 'Edit Exam Name',
),



      content: TextField(
        controller: controller,

        textCapitalization:
            TextCapitalization.characters,

        decoration:
            const InputDecoration(
          labelText: 'Exam Name',
          hintText:
              'UNIT TEST 1',
        ),
      ),

      actions: [

        TextButton(
          onPressed: () {
            Navigator.pop(
              context,
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
              controller.text
                  .trim()
                  .toUpperCase(),
            );
          },
          child: const Text(
            'Save',
          ),
        ),
      ],
    );
  }
}