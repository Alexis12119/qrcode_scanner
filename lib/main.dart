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
    TextEditingController studentIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Sale'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('QR code: $qrCode'),
              const SizedBox(height: 10),
              TextField(
                controller: itemCountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Enter item count',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: studentIdController,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: 'Enter student ID',
                ),
              ),
            ],
          ),
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
                final itemCount = int.tryParse(itemCountController.text);
                final studentId = studentIdController.text.trim();

                if (itemCount == null || itemCount <= 0) {
                  _showErrorSnackBar('Please enter a valid item count.');
                } else if (studentId.isEmpty) {
                  _showErrorSnackBar('Please enter a valid student ID.');
                } else {
                  Navigator.of(context).pop();
                  _addToSalesDatabase(qrCode, itemCount, studentId);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _addToSalesDatabase(
      String qrCode, int itemCount, String studentId) async {
    final productId = int.parse(qrCode);
    print('Product ID: $productId');
    print("Student ID: $studentId");

    try {
      // Fetch the price and item_count from the inventory table
      final inventoryResponse = await Supabase.instance.client
          .from('inventory')
          .select('price, item_count')
          .eq('id', productId)
          .single();

      final price = inventoryResponse['price'];
      final inventoryItemCount = inventoryResponse['item_count'];

      if (price == null || inventoryItemCount == null) {
        _showErrorSnackBar('Product not found for ID: $productId');
        return;
      }

      if (itemCount > inventoryItemCount) {
        _showErrorSnackBar(
            'Not enough items in inventory. Available: $inventoryItemCount');
        return;
      }

      final amount = price * itemCount;

      // Insert sale into sales table
      final insertResponse =
          await Supabase.instance.client.from('sales').insert({
        'product_id': productId,
        'item_count': itemCount,
        'amount': amount,
        'student_id': studentId,
      });

      // Subtract the item count from inventory
      await Supabase.instance.client.from('inventory').update(
          {'item_count': inventoryItemCount - itemCount}).eq('id', productId);

      print('Insert response: $insertResponse');
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
