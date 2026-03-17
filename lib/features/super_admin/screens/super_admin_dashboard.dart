import 'package:flutter/material.dart';

class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      /// TOP BAR
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: const [
            SizedBox(width: 10),
            CircleAvatar(
              radius: 16,
              child: Icon(Icons.person, size: 18),
            ),
            SizedBox(width: 10),
            Text(
              "Super Admin",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// STATS
            Row(
              children: const [
                Expanded(
                  child: _StatCard(
                    title: "Total Schools",
                    value: "12",
                    colors: [Color(0xff4facfe), Color(0xff00f2fe)],
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: "Total Students",
                    value: "2450",
                    colors: [Color(0xff43e97b), Color(0xff38f9d7)],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// ADD SCHOOL BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff6366F1),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add_business),
                label: const Text(
                  "Add School",
                  style: TextStyle(fontSize: 16),
                ),
                onPressed: () {},
              ),
            ),

            const SizedBox(height: 20),

            /// SEARCH BAR
            TextField(
              decoration: InputDecoration(
                hintText: "Search school...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// SCHOOL LIST
            Expanded(
              child: ListView.builder(
                itemCount: 10,
                itemBuilder: (context, index) {
                  return const _SchoolTile();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final List<Color> colors;

  const _StatCard({
    required this.title,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white70),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SchoolTile extends StatelessWidget {
  const _SchoolTile();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: const Text(
          "ABC INTERNATIONAL SCHOOL",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: const Text("Tap for options"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          showModalBottomSheet(
            context: context,
            builder: (context) {
              return const _SchoolOptions();
            },
          );
        },
      ),
    );
  }
}

class _SchoolOptions extends StatelessWidget {
  const _SchoolOptions();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [

          ListTile(
            leading: Icon(Icons.archive),
            title: Text("Archive School"),
          ),

          ListTile(
            leading: Icon(Icons.color_lens),
            title: Text("Change Theme"),
          ),

          ListTile(
            leading: Icon(Icons.admin_panel_settings),
            title: Text("School Admin ID"),
          ),

          ListTile(
            leading: Icon(Icons.tag),
            title: Text("School ID"),
          ),

          ListTile(
            leading: Icon(Icons.delete),
            title: Text("Remove School"),
          ),
        ],
      ),
    );
  }
}