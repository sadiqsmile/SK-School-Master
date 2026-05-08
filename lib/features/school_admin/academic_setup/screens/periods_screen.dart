import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/group_timing_service.dart';

class PeriodsScreen extends StatefulWidget {

  final String schoolId;

  const PeriodsScreen({
    super.key,
    required this.schoolId,
  });

  @override
  State<PeriodsScreen> createState() =>
      _PeriodsScreenState();
}

class _PeriodsScreenState
    extends State<PeriodsScreen> {

  final GroupTimingService _service =
      GroupTimingService();

  final List<String> groups = [

    "Nursery",
    "Primary",
    "Middle School",
    "High School",
    "College",
  ];

  // Time helpers

  String _to24Hour(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  String _addMinutes(String time24, int minutes) {
    final parts = time24.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final total = h * 60 + m + minutes;
    final nh = (total ~/ 60) % 24;
    final nm = total % 60;
    return '${nh.toString().padLeft(2, '0')}:${nm.toString().padLeft(2, '0')}';
  }

  String _to12Hour(String time24) {
    final parts = time24.split(':');
    if (parts.length < 2) return time24;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final period = h < 12 ? 'AM' : 'PM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${h12.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(0xffF8FAFC),

      appBar: AppBar(

        title: const Text(
          "Periods & Timings",
        ),

        backgroundColor: Colors.white,

        elevation: 0,
      ),

      body: StreamBuilder<QuerySnapshot>(

        stream: _service.getTimings(
          widget.schoolId,
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

          return ListView.builder(

            padding:
                const EdgeInsets.all(16),

            itemCount: groups.length,

            itemBuilder:
                (context, index) {

              final group =
                  groups[index];

              final existing = docs
                  .where((e) {

                final data =
                    e.data()
                        as Map<String, dynamic>;

                return data['group'] ==
                    group;

              }).toList();

              final data =
                  existing.isNotEmpty
                      ? existing.first.data()
                          as Map<String,
                              dynamic>
                      : null;

              return Container(

                margin:
                    const EdgeInsets.only(
                  bottom: 16,
                ),

                padding:
                    const EdgeInsets.all(
                  20,
                ),

                decoration: BoxDecoration(

                  color: Colors.white,

                  borderRadius:
                      BorderRadius.circular(
                    24,
                  ),

                  border: Border.all(
                    color:
                        Colors.grey.shade100,
                  ),

                  boxShadow: [

                    BoxShadow(
                      color: Colors.black
                          .withOpacity(0.02),

                      blurRadius: 10,

                      offset:
                          const Offset(
                        0,
                        4,
                      ),
                    ),
                  ],
                ),

                child: Column(

                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [

                    Row(
                      children: [

                        Container(

                          height: 52,
                          width: 52,

                          decoration:
                              BoxDecoration(

                            color:
                                const Color(
                              0xffEEF2FF,
                            ),

                            borderRadius:
                                BorderRadius
                                    .circular(
                              16,
                            ),
                          ),

                          child: const Icon(

                            Icons.schedule_rounded,

                            color: Color(
                              0xff5B5FEF,
                            ),
                          ),
                        ),

                        const SizedBox(
                          width: 14,
                        ),

                        Expanded(
                          child: Column(

                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [

                              Text(

                                group,

                                style:
                                    const TextStyle(

                                  fontSize: 17,

                                  fontWeight:
                                      FontWeight
                                          .w600,

                                  color: Color(
                                    0xff111827,
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: 4,
                              ),

                              Text(

                                data == null
                                    ? "No timing configured"
                                    : "${data['totalPeriods']} Periods • ${data['periodDuration']} mins",

                                style:
                                    TextStyle(

                                  fontSize: 13,

                                  color: Colors
                                      .grey
                                      .shade600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        ElevatedButton(

                          style:
                              ElevatedButton
                                  .styleFrom(

                            backgroundColor:
                                const Color(
                              0xff5B5FEF,
                            ),

                            shape:
                                RoundedRectangleBorder(

                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                            ),
                          ),

                          onPressed: () {

                            _showTimingSheet(
                              group,
                              data,
                            );
                          },

                          child: Text(

                            data == null
                                ? "Setup"
                                : "Edit",

                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (data != null) ...[

                      const SizedBox(
                        height: 22,
                      ),

                      _previewPeriods(data),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _previewPeriods(
    Map<String, dynamic> data,
  ) {

    final total =
        data['totalPeriods'];

    final lunchAfter =
        data['lunchAfterPeriod'];

    final breakAfter =
        data['shortBreakAfter'];

    List<Widget> widgets = [];

    for (int i = 1; i <= total; i++) {

      widgets.add(
        _periodChip("P$i"),
      );

      if (i == breakAfter) {

        widgets.add(
          _periodChip(
            "BREAK",
            color:
                const Color(0xffFEF3C7),
            textColor:
                const Color(0xff92400E),
          ),
        );
      }

      if (i == lunchAfter) {

        widgets.add(
          _periodChip(
            "LUNCH",
            color:
                const Color(0xffFEE2E2),
            textColor:
                const Color(0xff991B1B),
          ),
        );
      }
    }

    return Wrap(

      spacing: 10,
      runSpacing: 10,

      children: widgets,
    );
  }

  Widget _periodChip(

    String text, {

    Color color =
        const Color(0xffEEF2FF),

    Color textColor =
        const Color(0xff5B5FEF),
  }) {

    return Container(

      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),

      decoration: BoxDecoration(

        color: color,

        borderRadius:
            BorderRadius.circular(12),
      ),

      child: Text(

        text,

        style: TextStyle(

          fontWeight: FontWeight.w600,

          color: textColor,
        ),
      ),
    );
  }

  void _showTimingSheet(

    String group,
    Map<String, dynamic>? editData,

  ) {

    final startTimeController =
        TextEditingController(
      text:
          editData?['schoolStartTime'] ??
              '08:30 AM',
    );

    final durationController =
        TextEditingController(
      text:
          (editData?['periodDuration'] ??
                  45)
              .toString(),
    );

    final totalPeriodsController =
        TextEditingController(
      text:
          (editData?['totalPeriods'] ??
                  8)
              .toString(),
    );

    final lunchAfterController =
        TextEditingController(
      text:
          (editData?['lunchAfterPeriod'] ??
                  4)
              .toString(),
    );

    final lunchDurationController =
        TextEditingController(
      text:
          (editData?['lunchDuration'] ??
                  40)
              .toString(),
    );

    final shortBreakAfterController =
        TextEditingController(
      text:
          (editData?['shortBreakAfter'] ??
                  2)
              .toString(),
    );

    final shortBreakDurationController =
        TextEditingController(
      text:
          (editData?[
                      'shortBreakDuration'] ??
                  15)
              .toString(),
    );

    // suppress unused variable warnings for removed helpers
    // ignore: unused_local_variable
    final bool isEdit = editData != null;

    showModalBottomSheet(

      context: context,

      isScrollControlled: true,

      backgroundColor: Colors.transparent,

      builder: (_) {

        return Container(

          padding: EdgeInsets.only(

            left: 24,
            right: 24,
            top: 24,

            bottom:
                MediaQuery.of(context)
                        .viewInsets
                        .bottom +
                    24,
          ),

          decoration: const BoxDecoration(

            color: Colors.white,

            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(30),
            ),
          ),

          child: SingleChildScrollView(

            child: Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              mainAxisSize:
                  MainAxisSize.min,

              children: [

                Center(

                  child: Container(

                    height: 5,
                    width: 60,

                    decoration: BoxDecoration(

                      color:
                          Colors.grey.shade300,

                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Text(

                  "$group Timings",

                  style: const TextStyle(

                    fontSize: 22,

                    fontWeight:
                        FontWeight.w700,

                    color:
                        Color(0xff111827),
                  ),
                ),

                const SizedBox(height: 6),

                Text(

                  "Configure timetable structure and automatic periods",

                  style: TextStyle(

                    fontSize: 13,

                    color:
                        Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 28),

                _inputField(

                  controller:
                      startTimeController,

                  label:
                      "School Start Time",

                  hint:
                      "08:30 AM",
                ),

                const SizedBox(height: 18),

                Row(
                  children: [

                    Expanded(
                      child: _inputField(

                        controller:
                            durationController,

                        label:
                            "Period Duration",

                        hint: "45",
                      ),
                    ),

                    const SizedBox(
                      width: 14,
                    ),

                    Expanded(
                      child: _inputField(

                        controller:
                            totalPeriodsController,

                        label:
                            "Total Periods",

                        hint: "8",
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Row(
                  children: [

                    Expanded(
                      child: _inputField(

                        controller:
                            shortBreakAfterController,

                        label:
                            "Break After",

                        hint: "2",
                      ),
                    ),

                    const SizedBox(
                      width: 14,
                    ),

                    Expanded(
                      child: _inputField(

                        controller:
                            shortBreakDurationController,

                        label:
                            "Break Duration",

                        hint: "15",
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Row(
                  children: [

                    Expanded(
                      child: _inputField(

                        controller:
                            lunchAfterController,

                        label:
                            "Lunch After",

                        hint: "4",
                      ),
                    ),

                    const SizedBox(
                      width: 14,
                    ),

                    Expanded(
                      child: _inputField(

                        controller:
                            lunchDurationController,

                        label:
                            "Lunch Duration",

                        hint: "40",
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 34),

                SizedBox(

                  width: double.infinity,
                  height: 54,

                  child: ElevatedButton(

                    style:
                        ElevatedButton
                            .styleFrom(

                      backgroundColor:
                          const Color(
                        0xff5B5FEF,
                      ),

                      shape:
                          RoundedRectangleBorder(

                        borderRadius:
                            BorderRadius
                                .circular(
                          16,
                        ),
                      ),
                    ),

                    onPressed: () async {

                      await _service
                          .saveTiming(

                        schoolId:
                            widget.schoolId,

                        group: group,

                        schoolStartTime:
                            startTimeController
                                .text
                                .trim(),

                        periodDuration:
                            int.parse(
                          durationController
                              .text,
                        ),

                        totalPeriods:
                            int.parse(
                          totalPeriodsController
                              .text,
                        ),

                        lunchAfterPeriod:
                            int.parse(
                          lunchAfterController
                              .text,
                        ),

                        lunchDuration:
                            int.parse(
                          lunchDurationController
                              .text,
                        ),

                        shortBreakAfter:
                            int.parse(
                          shortBreakAfterController
                              .text,
                        ),

                        shortBreakDuration:
                            int.parse(
                          shortBreakDurationController
                              .text,
                        ),
                      );

                      if (!mounted) return;

                      Navigator.pop(context);
                    },

                    child: const Text(

                      "Save Timings",

                      style: TextStyle(

                        fontSize: 15,

                        fontWeight:
                            FontWeight.w600,

                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionLabel({

    required IconData icon,

    required Color bgColor,

    required Color iconColor,

    required String label,
  }) {

    return Row(

      children: [

        Container(

          width: 32,
          height: 32,

          decoration: BoxDecoration(

            color: bgColor,

            borderRadius:
                BorderRadius.circular(10),
          ),

          child: Icon(
            icon,
            size: 16,
            color: iconColor,
          ),
        ),

        const SizedBox(width: 10),

        Text(

          label,

          style: const TextStyle(

            fontSize: 15,

            fontWeight: FontWeight.w600,

            color: Color(0xff374151),
          ),
        ),
      ],
    );
  }

  Widget _inputField({

    required TextEditingController controller,

    required String label,
    required String hint,

  }) {

    return TextField(

      controller: controller,

      keyboardType:
          TextInputType.number,

      decoration: InputDecoration(

        labelText: label,

        hintText: hint,

        filled: true,

        fillColor:
            const Color(0xffF8FAFC),

        border: OutlineInputBorder(

          borderRadius:
              BorderRadius.circular(16),

          borderSide: BorderSide.none,
        ),

        enabledBorder:
            OutlineInputBorder(

          borderRadius:
              BorderRadius.circular(16),

          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),

        focusedBorder:
            const OutlineInputBorder(

          borderRadius:
              BorderRadius.all(
            Radius.circular(16),
          ),

          borderSide: BorderSide(
            color: Color(0xff5B5FEF),
          ),
        ),
      ),
    );
  }
}
