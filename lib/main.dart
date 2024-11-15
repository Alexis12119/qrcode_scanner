import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://eyzscfnyniowwatjehuh.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV5enNjZm55bmlvd3dhdGplaHVoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjU4MTE4NDksImV4cCI6MjA0MTM4Nzg0OX0.7vjJL_PtOkq2rEDqAXB4yyJeYL0cgFBaDa3wefs_pPQ',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Scanner App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const QRScannerScreen(),
    );
  }
}

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  QRScannerScreenState createState() => QRScannerScreenState();
}

class QRScannerScreenState extends State<QRScannerScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isScanning = false;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Scanner App'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sales'),
            Tab(text: 'Maintenance'),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: TabBarView(
          controller: _tabController,
          physics: const BouncingScrollPhysics(), // For smoother swipe effect
          children: [
            buildSalesTab(),
            buildMaintenanceTab(),
          ],
        ),
      ),
    );
  }

  Widget buildSalesTab() {
    return Column(
      children: <Widget>[
        Expanded(
          flex: 5,
          child: Stack(
            alignment: Alignment.center,
            children: [
              QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 2),
                ),
                width: 200,
                height: 200,
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: _toggleScanning,
          child:
              Text(isScanning ? 'Stop Sales Scanning' : 'Start Sales Scanning'),
        ),
      ],
    );
  }

  Widget buildMaintenanceTab() {
    return Column(
      children: <Widget>[
        Expanded(
          flex: 5,
          child: Stack(
            alignment: Alignment.center,
            children: [
              QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 2),
                ),
                width: 200,
                height: 200,
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: _toggleScanning,
          child: Text(isScanning
              ? 'Stop Maintenance Scanning'
              : 'Start Maintenance Scanning'),
        ),
      ],
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (isScanning && scanData.code != null) {
        _pauseScanning();
        final isSalesTab = _tabController?.index == 0;
        if (isSalesTab) {
          _showSalesConfirmationDialog(scanData.code!);
        } else {
          _showMaintenanceConfirmationDialog(scanData.code!);
        }
      }
    });
  }

  void _toggleScanning() {
    setState(() {
      isScanning = !isScanning;
    });
    if (isScanning) {
      controller?.resumeCamera();
    } else {
      controller?.pauseCamera();
    }
  }

  void _pauseScanning() {
    setState(() {
      isScanning = false;
    });
    controller?.pauseCamera();
  }

  void _showSalesConfirmationDialog(String qrCode) {
    TextEditingController itemCountController = TextEditingController();
    TextEditingController studentNameController = TextEditingController();
    TextEditingController remarksController = TextEditingController();
    TextEditingController itemDescController = TextEditingController();
    TextEditingController crNumberController = TextEditingController();
    TextEditingController issuanceNoController = TextEditingController();
    TextEditingController courseAndSectionController = TextEditingController();
    TextEditingController studentIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Sales Record'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('QR code: $qrCode'),
                const SizedBox(height: 10),
                // Product ID (from qrCode)
                TextField(
                  controller: itemCountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Enter item count',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: studentNameController,
                  decoration: const InputDecoration(
                    labelText: 'Issued to',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: studentIdController,
                  decoration: const InputDecoration(
                    labelText: 'Student ID',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: courseAndSectionController,
                  decoration: const InputDecoration(
                    labelText: 'Course and Section',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: remarksController,
                  decoration: const InputDecoration(
                    labelText: 'Remarks',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: itemDescController,
                  decoration: const InputDecoration(
                    labelText: 'Item Description',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: crNumberController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'OR Number',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: issuanceNoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Issuance No',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                final itemCount = int.tryParse(itemCountController.text);
                final studentName = studentNameController.text.trim();
                final remarks = remarksController.text.trim();
                final itemDesc = itemDescController.text.trim();
                final crNumber = crNumberController.text.trim();
                final issuanceNo = issuanceNoController.text.trim();
                final courseAndSection = courseAndSectionController.text.trim();
                final studentId = studentIdController.text.trim();

                if (itemCount == null || itemCount <= 0) {
                  _showErrorSnackBar('Please enter a valid item count.');
                } else {
                  Navigator.of(context).pop();
                  _addToSalesDatabase(
                    qrCode,
                    itemCount,
                    studentName,
                    studentId,
                    courseAndSection,
                    remarks,
                    itemDesc,
                    crNumber,
                    issuanceNo,
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _addToSalesDatabase(
      String qrCode,
      int itemCount,
      String studentName,
      String studentId,
      String courseAndSection,
      String remarks,
      String itemDesc,
      String crNumber,
      String issuanceNo) async {
    try {
      qrCode = qrCode.replaceAll('"', '');

      final inventoryResponse = await Supabase.instance.client
          .from('inventory')
          .select('price, item_count')
          .eq('id', qrCode)
          .single();

      final price = inventoryResponse['price'];
      final inventoryItemCount = inventoryResponse['item_count'];

      print(inventoryResponse);
      if (price == null || inventoryItemCount == null) {
        _showErrorSnackBar('Product not found for ID: $qrCode');
        return;
      }

      if (itemCount > inventoryItemCount) {
        _showErrorSnackBar(
            'Not enough items in inventory. Available: $inventoryItemCount');
        return;
      }

      final amount = price * itemCount;

      // Insert sale into sales table with additional fields
      await Supabase.instance.client.from('sales').insert({
        'product_id': qrCode,
        'item_count': itemCount,
        'amount': amount,
        'student_name': studentName,
        'student_id': studentId,
        'course_and_section': courseAndSection,
        'remarks': remarks,
        'item_desc': itemDesc,
        'cr_number': crNumber,
        'issuance_no': issuanceNo,
      });

      // Update inventory
      await Supabase.instance.client.from('inventory').update(
          {'item_count': inventoryItemCount - itemCount}).eq('id', qrCode);

      _showSuccessSnackBar('Sale added successfully!');
    } catch (e, stackTrace) {
      print('Error details: $e');
      print('Stack trace: $stackTrace');
      _showErrorSnackBar('An error occurred: $e');
    }
  }

  Future<void> _showMaintenanceRecords(String qrCode) async {
    final equipmentId = int.parse(qrCode);
    print('Equipment ID: $equipmentId');

    try {
      // Fetch maintenance records for the given equipment
      final maintenanceResponse = await Supabase.instance.client
          .from('maintenance')
          .select('date_maintained, equipment_name')
          .eq('equipment_id', equipmentId)
          .order('date_maintained', ascending: false);

      print('Maintenance records: $maintenanceResponse');

      if (maintenanceResponse.isEmpty) {
        _showErrorSnackBar(
            'No maintenance records found for equipment ID: $equipmentId');
        return;
      }

      // Fetch days_interval from the equipments table
      final equipmentResponse = await Supabase.instance.client
          .from('equipments')
          .select('days_interval, name')
          .eq('id', equipmentId)
          .single();

      print('Equipment response: $equipmentResponse');

      final equipmentName = equipmentResponse['name'];
      final daysInterval = equipmentResponse['days_interval'];

      final lastMaintenanceDate =
          DateTime.parse(maintenanceResponse.first['date_maintained']);
      final nextMaintenanceDate =
          lastMaintenanceDate.add(Duration(days: daysInterval));

      // Show the maintenance records in a dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Maintenance Records for $equipmentName'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('Previous Maintenance Date: $lastMaintenanceDate'),
                Text('Next Maintenance Date: $nextMaintenanceDate'),
                const Divider(),
                ...maintenanceResponse.map<Widget>((record) {
                  return ListTile(
                    title:
                        Text('Date Maintained: ${record['date_maintained']}'),
                    subtitle: Text('Equipment: ${record['equipment_name']}'),
                  );
                }).toList(),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } catch (e, stackTrace) {
      print('Error: $e');
      print('Stack trace: $stackTrace');
      _showErrorSnackBar('An error occurred: $e');
    }
  }

  // Maintenance confirmation dialog
  void _showMaintenanceConfirmationDialog(String qrCode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Maintenance'),
          content: Text(
              'Do you want to retrieve maintenance records for equipment ID: $qrCode?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop();
                _showMaintenanceRecords(qrCode);
              },
            ),
          ],
        );
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    print('Error: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
