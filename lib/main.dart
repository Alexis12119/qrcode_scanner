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

class SalesItem {
  final String productId;
  final int itemCount;
  final double amount;
  final String studentName;
  final String studentId;
  final String courseAndSection;
  final String remarks;
  final String itemDesc;
  final String crNumber;
  final String issuanceNo;

  SalesItem({
    required this.productId,
    required this.itemCount,
    required this.amount,
    required this.studentName,
    required this.studentId,
    required this.courseAndSection,
    required this.remarks,
    required this.itemDesc,
    required this.crNumber,
    required this.issuanceNo,
  });
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

  // New variables for batch processing
  List<SalesItem> currentBatch = [];
  Map<String, String> lastTransaction = {};

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
        actions: [
          if (currentBatch.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: _showCurrentBatch,
            ),
        ],
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
    // Controllers with retained values from last transaction
    TextEditingController itemCountController = TextEditingController();
    TextEditingController studentNameController = TextEditingController(
      text: lastTransaction['studentName'] ?? '',
    );
    TextEditingController studentIdController = TextEditingController(
      text: lastTransaction['studentId'] ?? '',
    );
    TextEditingController courseAndSectionController = TextEditingController(
      text: lastTransaction['courseAndSection'] ?? '',
    );
    TextEditingController remarksController = TextEditingController();
    TextEditingController itemDescController = TextEditingController();
    TextEditingController crNumberController = TextEditingController(
      text: lastTransaction['crNumber'] ?? '',
    );
    TextEditingController issuanceNoController = TextEditingController(
      text: lastTransaction['issuanceNo'] ?? '',
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add to Current Transaction'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Product ID: $qrCode'),
                TextField(
                  controller: itemCountController,
                  decoration: const InputDecoration(
                    labelText: 'Item Count',
                    hintText: 'Enter item count',
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: studentNameController,
                  decoration: const InputDecoration(
                    labelText: 'Student Name',
                    hintText: 'Enter student name',
                  ),
                ),
                TextField(
                  controller: studentIdController,
                  decoration: const InputDecoration(
                    labelText: 'Student ID',
                    hintText: 'Enter student ID',
                  ),
                ),
                TextField(
                  controller: courseAndSectionController,
                  decoration: const InputDecoration(
                    labelText: 'Course and Section',
                    hintText: 'Enter course and section',
                  ),
                ),
                TextField(
                  controller: remarksController,
                  decoration: const InputDecoration(
                    labelText: 'Remarks',
                    hintText: 'Enter remarks',
                  ),
                ),
                TextField(
                  controller: itemDescController,
                  decoration: const InputDecoration(
                    labelText: 'Item Description',
                    hintText: 'Enter item description',
                  ),
                ),
                TextField(
                  controller: crNumberController,
                  decoration: const InputDecoration(
                    labelText: 'OR Number',
                    hintText: 'Enter OR number',
                  ),
                ),
                TextField(
                  controller: issuanceNoController,
                  decoration: const InputDecoration(
                    labelText: 'Issuance No',
                    hintText: 'Enter issuance number',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Add More Items'),
              onPressed: () {
                _addToCurrentBatch(
                  qrCode,
                  itemCountController,
                  studentNameController,
                  studentIdController,
                  courseAndSectionController,
                  remarksController,
                  itemDescController,
                  crNumberController,
                  issuanceNoController,
                );
                Navigator.of(context).pop();
                _toggleScanning(); // Resume scanning
              },
            ),
            TextButton(
              child: const Text('Complete Transaction'),
              onPressed: () {
                _addToCurrentBatch(
                  qrCode,
                  itemCountController,
                  studentNameController,
                  studentIdController,
                  courseAndSectionController,
                  remarksController,
                  itemDescController,
                  crNumberController,
                  issuanceNoController,
                );
                Navigator.of(context).pop();
                _processBatch();
              },
            ),
          ],
        );
      },
    );
  }

  void _addToCurrentBatch(
    String qrCode,
    TextEditingController itemCountController,
    TextEditingController studentNameController,
    TextEditingController studentIdController,
    TextEditingController courseAndSectionController,
    TextEditingController remarksController,
    TextEditingController itemDescController,
    TextEditingController crNumberController,
    TextEditingController issuanceNoController,
  ) {
    // Save current transaction info for next scan
    lastTransaction = {
      'studentName': studentNameController.text,
      'studentId': studentIdController.text,
      'courseAndSection': courseAndSectionController.text,
      'crNumber': crNumberController.text,
      'issuanceNo': issuanceNoController.text,
    };

    // Add item to current batch
    final itemCount = int.tryParse(itemCountController.text) ?? 0;
    if (itemCount > 0) {
      currentBatch.add(SalesItem(
        productId: qrCode,
        itemCount: itemCount,
        amount: 0, // Will be calculated when processing
        studentName: studentNameController.text,
        studentId: studentIdController.text,
        courseAndSection: courseAndSectionController.text,
        remarks: remarksController.text,
        itemDesc: itemDescController.text,
        crNumber: crNumberController.text,
        issuanceNo: issuanceNoController.text,
      ));
    }
  }

  void _showCurrentBatch() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Current Transaction'),
          content: SingleChildScrollView(
            child: Column(
              children: currentBatch
                  .map((item) => ListTile(
                        title: Text('Product: ${item.productId}'),
                        subtitle: Text('Quantity: ${item.itemCount}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              currentBatch.remove(item);
                            });
                            Navigator.pop(context);
                            if (currentBatch.isNotEmpty) {
                              _showCurrentBatch();
                            }
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Continue Shopping'),
              onPressed: () {
                Navigator.pop(context);
                _toggleScanning();
              },
            ),
            TextButton(
              child: const Text('Complete Transaction'),
              onPressed: () {
                Navigator.pop(context);
                _processBatch();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _processBatch() async {
    try {
      for (var item in currentBatch) {
        print("Product ID: ${item.productId}");
        print("Item Count: ${item.itemCount}");
        print("Amount: ${item.amount}");
        print("Student Name: ${item.studentName}");
        print("Student ID: ${item.studentId}");
        print("Course and Section: ${item.courseAndSection}");
        print("Remarks: ${item.remarks}");
        print("Item Description: ${item.itemDesc}");
        print("CR Number: ${item.crNumber}");
        print("Issuance No: ${item.issuanceNo}");

        final productId =
            item.productId.replaceAll(" ", "").replaceAll('"', "");
        // Fetch inventory
        print("Fetching inventory for product ID: $productId");
        final inventoryResponse = await Supabase.instance.client
            .from('inventory')
            .select('price, item_count')
            .eq('id', productId)
            .single();

        final price = inventoryResponse['price'];
        final inventoryItemCount = inventoryResponse['item_count'];

        if (item.itemCount > inventoryItemCount) {
          _showErrorSnackBar(
              'Not enough items in inventory for ${item.productId}. Available: $inventoryItemCount');
          return;
        }

        final amount = price * item.itemCount;

        await Supabase.instance.client.from('sales').insert({
          'product_id': productId,
          'item_count': item.itemCount,
          'amount': amount,
          'student_name': item.studentName,
          'student_id': item.studentId,
          'course_and_section': item.courseAndSection,
          'remarks': item.remarks,
          'item_desc': item.itemDesc,
          'cr_number': item.crNumber,
          'issuance_no': item.issuanceNo,
        });

        await Supabase.instance.client
            .from('inventory')
            .update({'item_count': inventoryItemCount - item.itemCount}).eq(
                'id', productId);
      }

      _showSuccessSnackBar('All items processed successfully!');
      setState(() {
        currentBatch.clear();
      });
    } catch (e) {
      _showErrorSnackBar('Error processing batch: $e');
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
