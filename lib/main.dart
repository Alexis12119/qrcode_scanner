import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qrcode_scanner/sales_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Sales Table
//INSERT INTO "public"."sales" ("item_count", "amount", "last_modified", "student_name", "remarks", "item_desc", "or_number", "id", "product_id", "course_and_section", "student_id", "issuance_no", "item_type") VALUES ('2', '440', '2024-11-21 09:05:56.675702+00', 'Eirra', 'Good', 'Washday Male 3XL', '123456789', '37', 'PTWFYB001-007', 'BSIT401A', '274626', '4', ''), ('1', '380', '2024-11-21 09:06:10.263963+00', 'Eirra ', 'n/a', 'IT Blouse M', '123456789', '44', 'UITB001-003', 'BSIT401A', '274626', '5', ''), ('2', '600', '2024-11-22 01:34:05.43907+00', 'Angelou', 'NA', 'NA', '', '51', 'UBF001-001', 'BSIT401', '02000', '6', ''), ('2', '600', '2024-11-22 01:38:57.601223+00', 'Angie', 'na', 'na', '001', '52', 'UBF001-001', 'BSIT', '02000', '7', ''), ('3', '900', '2024-11-22 01:39:37.415963+00', 'Lou', 'na', 'na', '001', '53', 'UBF001-001', 'bsit', '0284', '8', ''), ('1', '220', '2024-11-22 07:24:54.233929+00', 'dsad', '', 'wa', '202', '54', 'PTWFYB001-001', 'bsit', '02391', '9', ''), ('2', '440', '2024-11-23 13:50:02.008528+00', 'Marian', 'Good', 'Test ', '404', '57', 'PTWFYB001-001', 'BSIT-4G ', '9', '10', '');
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

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (isScanning && scanData.code != null) {
        _pauseScanning();
        final isSalesTab = _tabController?.index == 0;
        if (isSalesTab) {
          _showSalesConfirmationDialog(scanData.code!);
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

    // Item type dropdown value
    String? selectedItemType = lastTransaction['itemType'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
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
                    DropdownButtonFormField<String>(
                      value: selectedItemType,
                      decoration: const InputDecoration(
                        labelText: 'Item Type',
                        hintText: 'Select item type',
                      ),
                      items: ['Proware', 'Uniform']
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedItemType = value;
                        });
                      },
                    ),
                    TextField(
                      controller: studentNameController,
                      decoration: const InputDecoration(
                        labelText: 'Issued To',
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
                      selectedItemType,
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
                      selectedItemType,
                    );
                    Navigator.of(context).pop();
                    _processBatch();
                  },
                ),
              ],
            );
          },
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
    String? itemType,
  ) {
    // Save current transaction info for next scan
    lastTransaction = {
      'studentName': studentNameController.text,
      'studentId': studentIdController.text,
      'courseAndSection': courseAndSectionController.text,
      'itemType': itemType.toString(),
    };

    // Add item to current batch
    final itemCount = int.tryParse(itemCountController.text) ?? 0;

    if (itemCount > 0) {
      currentBatch.add(SalesItem(
        productId: qrCode,
        itemCount: itemCount,
        studentName: studentNameController.text,
        studentId: studentIdController.text,
        courseAndSection: courseAndSectionController.text,
        remarks: remarksController.text,
        itemDesc: itemDescController.text,
        itemType: itemType ?? '',
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
    // Prompt for OR Number before processing
    final orNumberController = TextEditingController();

    // Show OR Number input dialog
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter OR Number'),
          content: TextField(
            controller: orNumberController,
            decoration: const InputDecoration(
              labelText: 'OR Number',
              hintText: 'Enter Official Receipt Number',
            ),
            keyboardType: TextInputType.number,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    // Check if OR number was provided
    if (orNumberController.text.isEmpty) {
      _showErrorSnackBar('OR Number is required');
      return;
    }

    final orNumber = orNumberController.text;

    try {
      // Get the next issuance number
      final issuanceResponse = await Supabase.instance.client
          .from('sales')
          .select('issuance_no')
          .order('issuance_no', ascending: false)
          .limit(1)
          .single();

      final nextIssuanceNo = (issuanceResponse['issuance_no'] as int) + 1;

      for (var item in currentBatch) {
        final productId =
            item.productId.replaceAll(" ", "").replaceAll('"', "");

        // Fetch inventory
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
          'item_type': item.itemType,
          'or_number': orNumber,
          'issuance_no': nextIssuanceNo,
        });

        await Supabase.instance.client
            .from('inventory')
            .update({'item_count': inventoryItemCount - item.itemCount}).eq(
                'id', productId);
      }

      _showSuccessSnackBar(
          'All items processed successfully with OR Number: $orNumber');
      setState(() {
        currentBatch.clear();
      });
    } catch (e) {
      _showErrorSnackBar('Error processing batch: $e');
    }
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
