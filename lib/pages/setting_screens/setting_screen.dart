
import 'package:flutter/material.dart';

import '../../models/response/user_response.dart';
import '../../services/user_service.dart';
import '../../widgets/notification.dart';
import '../../widgets/profile_drawer.dart';
import 'edit_user.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late MyData _dataSource;


  List<UserData> users = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    try {
      debugPrint(" Loading users...");

      final result = await UserApiService.getUsers();

      debugPrint(" Users loaded: ${result.length}");

      setState(() {
        users = result;
        _dataSource = MyData(
          context: context,
          users: users,
          onRefresh: loadUsers,
        );
        loading = false;
      });
    } catch (e, stack) {
      debugPrint(" LOAD USERS ERROR: $e");
      debugPrint(" STACK: $stack");

      setState(() => loading = false);
    }
  }


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  String roleText(UserData user) {
    return user.role.name ?? user.role.id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const ProfileDrawer(),
      resizeToAvoidBottomInset: true,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        automaticallyImplyLeading: false,
        title: Text("User Management"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context){
               return  NotificationScreen();
              }));
            },
            icon: const Icon(Icons.notifications_none, color: Colors.black),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                _scaffoldKey.currentState?.openEndDrawer();
              },
              child: const CircleAvatar(
                backgroundImage: AssetImage("assets/images/profile.png"),
              ),
            ),
          ),
        ],
      ),


      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [

              SizedBox(
                width: 418,
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    _dataSource.filter(value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: loading
                    ? Center(child: CircularProgressIndicator())
                    : LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: PaginatedDataTable(
                            headingRowColor: WidgetStateProperty.all(Colors.green),
                            columns: const [
                              DataColumn(
                                label: Text("Name",
                                    style: TextStyle(color: Colors.white)),
                              ),
                              DataColumn(
                                label: Text("Role",
                                    style: TextStyle(color: Colors.white)),
                              ),
                              DataColumn(
                                label: Text("Status",
                                    style: TextStyle(color: Colors.white)),
                              ),

                            ],
                            source: _dataSource,
                            rowsPerPage: 7,
                            columnSpacing: 60,
                            horizontalMargin: 24,
                            showFirstLastButtons: true,
                            showCheckboxColumn: false,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class MyData extends DataTableSource {
  final BuildContext context;
  final VoidCallback onRefresh;
  final List<UserData> _original;
  List<UserData> _filtered;

  MyData({required this.context,required this.onRefresh, required List<UserData> users})
      : _original = users,
        _filtered = List.from(users);


  void filter(String query) {
    query = query.trim().toLowerCase();

    if (query.isEmpty) {
      _filtered = List.from(_original);
    } else {
      _filtered = _original.where((u) {
        final roleName = (u.role.name ?? u.role.id).toLowerCase();
        final statusText =
        (u.isActive || u.isVerified) ? "active" : "inactive";

        return u.name.toLowerCase().contains(query) ||
            roleName.contains(query) ||
            statusText.contains(query);
      }).toList();
    }

    notifyListeners();
  }



  bool isUserActive(UserData user) {
    return user.isActive || user.isVerified;
  }
  
  


  @override
  DataRow getRow(int index) {
    if (index >= _filtered.length) return const DataRow(cells: []);

    final user = _filtered[index];
    final active = isUserActive(user);

    final statusText = active ? "Active" : "Inactive";
    final statusColor = active ? Colors.green : Colors.red;


    Future<void> openEdit() async {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditUser(user: user),
        ),
      );

      if (result == true) {
        onRefresh();
      }
    }
    
    

    return DataRow(cells: [
      DataCell(
        GestureDetector(
          onTap: openEdit,
          child: Text(user.name),
        ),
      ),
      DataCell(
        GestureDetector(
          onTap: openEdit,
          child: Text(user.role.name ?? user.role.id),
        ),
      ),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(statusText),
        ),
      ),
    ]);
  }


  @override
  int get rowCount => _filtered.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}



