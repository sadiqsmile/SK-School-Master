import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:school_app/features/school_admin/layout/admin_layout.dart';
import 'package:school_app/providers/school_admin_provider.dart';
import 'package:school_app/providers/current_school_provider.dart';

class TeachersScreen extends ConsumerWidget {
  const TeachersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teachersAsync =
        ref.watch(teachersProvider);

    return AdminLayout(
      title: 'Teachers',
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () =>
            context.go(
          '/add-teacher',
        ),
        icon: const Icon(
          Icons.person_add_alt_1,
        ),
        label: const Text(
          'Add Teacher',
        ),
      ),
      body: teachersAsync.when(
        loading: () =>
            const Center(
          child:
              CircularProgressIndicator(),
        ),
        error: (e, _) =>
            Center(
          child: Text(
            'Error: $e',
          ),
        ),
        data: (snapshot) {
          final teachers =
              snapshot.docs;

          if (teachers.isEmpty) {
            return const Center(
              child: Text(
                'No teachers added',
              ),
            );
          }

          return LayoutBuilder(
            builder:
                (context, box) {
              final mobile =
                  box.maxWidth <
                      760;

              return SingleChildScrollView(
                padding:
                    const EdgeInsets.all(
                  16,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    _heroHeader(
                      teachers
                          .length,
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    GridView.count(
                      crossAxisCount:
                          mobile
                              ? 2
                              : 4,
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      crossAxisSpacing:
                          14,
                      mainAxisSpacing:
                          14,
                      childAspectRatio:
                          mobile
                              ? 1.25
                              : 1.45,
                      children: [
                        _statCard(
                          'Total',
                          teachers
                              .length
                              .toString(),
                          Icons.groups_rounded,
                          const Color(
                            0xFF2563EB,
                          ),
                          const Color(
                            0xFF3B82F6,
                          ),
                        ),
                        _statCard(
                          'Assigned',
                          teachers
                              .where(
                                (
                                  e,
                                ) {
                                  final d = e
                                          .data()
                                      as Map<String,
                                          dynamic>;

                                  final a = d[
                                          'assignmentKeys'] ??
                                      [];

                                  return a
                                      .isNotEmpty;
                                },
                              )
                              .length
                              .toString(),
                          Icons.school_rounded,
                          const Color(
                            0xFF10B981,
                          ),
                          const Color(
                            0xFF059669,
                          ),
                        ),
                        _statCard(
                          'Unassigned',
                          teachers
                              .where(
                                (
                                  e,
                                ) {
                                  final d = e
                                          .data()
                                      as Map<String,
                                          dynamic>;

                                  final a = d[
                                          'assignmentKeys'] ??
                                      [];

                                  return a
                                      .isEmpty;
                                },
                              )
                              .length
                              .toString(),
                          Icons.pending_actions_rounded,
                          const Color(
                            0xFFEF4444,
                          ),
                          const Color(
                            0xFFDC2626,
                          ),
                        ),
                        _statCard(
                          'Active',
                          teachers
                              .length
                              .toString(),
                          Icons.verified_user_rounded,
                          const Color(
                            0xFF8B5CF6,
                          ),
                          const Color(
                            0xFF6366F1,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    ListView.builder(
                      itemCount:
                          teachers
                              .length,
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      itemBuilder:
                          (
                        context,
                        index,
                      ) {
                        final doc =
                            teachers[
                                index];

                        final data = doc
                                .data()
                            as Map<String,
                                dynamic>;

                        final teacherId =
                            doc.id;

                        final name =
                            (data['name'] ??
                                    '')
                                .toString();

                        final email =
                            (data['email'] ??
                                    '')
                                .toString();

                        final phone =
                            (data['phone'] ??
                                    '')
                                .toString();

                        final assignmentKeys =
                            (data['assignmentKeys'] ??
                                    [])
                                as List;

                        return _teacherCard(
                          context:
                              context,
                          ref: ref,
                          teacherId:
                              teacherId,
                          name:
                              name,
                          email:
                              email,
                          phone:
                              phone,
                          assignmentKeys:
                              assignmentKeys,
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _heroHeader(
    int total,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(
        20,
      ),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        gradient:
            const LinearGradient(
          colors: [
            Color(0xFF0EA5E9),
            Color(0xFF2563EB),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x220EA5E9,
            ),
            blurRadius: 24,
            offset: Offset(
              0,
              12,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          const Text(
            'Staff Management 👨‍🏫',
            style: TextStyle(
              color:
                  Colors.white70,
            ),
          ),
          const SizedBox(
            height: 6,
          ),
          const Text(
            'Teachers Dashboard',
            style: TextStyle(
              color:
                  Colors.white,
              fontSize: 26,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            '$total teachers registered in your school.',
            style:
                const TextStyle(
              color:
                  Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color start,
    Color end,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x12000000,
            ),
            blurRadius: 18,
            offset: Offset(
              0,
              8,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
                BoxDecoration(
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
              gradient:
                  LinearGradient(
                colors: [
                  start,
                  end,
                ],
              ),
            ),
            child: Icon(
              icon,
              color:
                  Colors.white,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style:
                const TextStyle(
              fontSize: 24,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            title,
            style:
                const TextStyle(
              color:
                  Color(
                0xFF6B7280,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _teacherCard({
    required BuildContext context,
    required WidgetRef ref,
    required String teacherId,
    required String name,
    required String email,
    required String phone,
    required List assignmentKeys,
  }) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      padding:
          const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x12000000,
            ),
            blurRadius: 18,
            offset: Offset(
              0,
              8,
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    const Color(
                  0xFFE0E7FF,
                ),
                child: Text(
                  name.isEmpty
                      ? '?'
                      : name[0]
                          .toUpperCase(),
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight
                            .bold,
                    color: Color(
                      0xFF4F46E5,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      name,
                      style:
                          const TextStyle(
                        fontSize:
                            16,
                        fontWeight:
                            FontWeight
                                .w700,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      email,
                      style:
                          const TextStyle(
                        color: Color(
                          0xFF6B7280,
                        ),
                        fontSize:
                            13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal:
                      10,
                  vertical:
                      6,
                ),
                decoration:
                    BoxDecoration(
                  color: assignmentKeys
                          .isEmpty
                      ? const Color(
                          0xFFFEF2F2)
                      : const Color(
                          0xFFECFDF5),
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
                child: Text(
                  assignmentKeys
                          .isEmpty
                      ? 'Free'
                      : 'Assigned',
                  style:
                      TextStyle(
                    fontSize:
                        12,
                    fontWeight:
                        FontWeight
                            .w700,
                    color: assignmentKeys
                            .isEmpty
                        ? const Color(
                            0xFFDC2626)
                        : const Color(
                            0xFF059669),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          Row(
            children: [
              const Icon(
                Icons.call_rounded,
                size: 16,
                color: Color(
                  0xFF64748B,
                ),
              ),
              const SizedBox(
                width: 6,
              ),
              Text(phone),
            ],
          ),

          const SizedBox(
            height: 10,
          ),

          Row(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              const Icon(
                Icons.school_rounded,
                size: 16,
                color: Color(
                  0xFF64748B,
                ),
              ),
              const SizedBox(
                width: 6,
              ),
              Expanded(
                child: Text(
                  assignmentKeys
                          .isEmpty
                      ? 'Not Assigned'
                      : assignmentKeys
                          .join(
                          ', ',
                        ),
                  style:
                      const TextStyle(
                    color: Color(
                      0xFF475569,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 16,
          ),

          Row(
            children: [
              Expanded(
                child:
                    OutlinedButton.icon(
                  onPressed: () {
                    context.push(
                      '/assign-class',
                      extra:
                          teacherId,
                    );
                  },
                  icon: const Icon(
                    Icons
                        .edit_note_rounded,
                  ),
                  label: const Text(
                    'Assign',
                  ),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child:
                    ElevatedButton.icon(
                  onPressed: () =>
                      _resetAssignments(
                    context,
                    ref,
                    teacherId,
                  ),
                  icon: const Icon(
                    Icons.restart_alt,
                  ),
                  label: const Text(
                    'Reset',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void>
      _resetAssignments(
    BuildContext context,
    WidgetRef ref,
    String teacherId,
  ) async {
    final ok =
        await showDialog<bool>(
      context: context,
      builder: (_) =>
          AlertDialog(
        title: const Text(
          'Reset Assignment',
        ),
        content: const Text(
          'Remove all assigned classes?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(
              context,
              false,
            ),
            child:
                const Text(
              'Cancel',
            ),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(
              context,
              true,
            ),
            child:
                const Text(
              'Reset',
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final school = await ref.read(
      currentSchoolProvider.future,
    );

    await FirebaseFirestore
        .instance
        .collection('schools')
        .doc(school.id)
        .collection('teachers')
        .doc(teacherId)
        .update({
      'assignmentKeys': [],
    });

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Assignments cleared',
          ),
        ),
      );
    }
  }
}