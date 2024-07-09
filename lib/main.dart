import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  await Hive.initFlutter();
  await Hive.openBox('milkConsumption');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Milk Consumption Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, int> _consumptionData = {};
  Map<int, double> _monthlyPriceData = {}; // Store price per month
  Map<int, double> _monthlyTotalPrice = {}; // Store total price per month

  @override
  void initState() {
    super.initState();
    final box = Hive.box('milkConsumption');
    _consumptionData = Map<DateTime, int>.from(box.get('data', defaultValue: {}));
    _monthlyPriceData = Map<int, double>.from(box.get('price', defaultValue: {}));
    _monthlyTotalPrice = Map<int, double>.from(box.get('monthlyTotal', defaultValue: {}));
    _calculateMonthlyTotals(); // Calculate monthly totals at startup
  }

  void _calculateMonthlyTotals() {
    // Reset monthly totals
    _monthlyTotalPrice.clear();
    _consumptionData.forEach((date, consumption) {
      double price = _monthlyPriceData[date.month] ?? 0.0;
      _monthlyTotalPrice[date.month] = (_monthlyTotalPrice[date.month] ?? 0.0) + (consumption * price);
    });
    final box = Hive.box('milkConsumption');
    box.put('monthlyTotal', _monthlyTotalPrice); // Save monthly totals
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Milk Consumption Tracker'),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            body: Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _selectedDay,
                  calendarFormat: _calendarFormat,
                  availableCalendarFormats: const { // Disable calendar format toggle
                    CalendarFormat.month: 'Month',
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                    });
                  },
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      if (_consumptionData[day] != null) {
                        return Container(
                          margin: const EdgeInsets.all(6.0),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            '${_consumptionData[day]} KG',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: _showInputDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Add/Edit Milk Consumption',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _buildConsumptionInfo(),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
    );
  }

  Widget _buildConsumptionInfo() {
    int? consumption = _consumptionData[_selectedDay];
    double price = _monthlyPriceData[_selectedDay.month] ?? 0.0; // Default price is 0.0
    double monthlyTotalPrice = _monthlyTotalPrice[_selectedDay.month] ?? 0.0; // Monthly total price

    return Center(
      child: Container(
        padding: EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.blue, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4.0,
              spreadRadius: 2.0,
              offset: Offset(2.0, 2.0),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Milk Consumption on ${_selectedDay.toLocal().toString().split(' ')[0]}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              consumption != null ? '$consumption KG' : 'No data available',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Price per KG: \Rs ${price.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Total Price for the Month: \Rs ${monthlyTotalPrice.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _showInputDialog() {
    final TextEditingController _consumptionController = TextEditingController();
    final TextEditingController _priceController = TextEditingController();

    _priceController.text = (_monthlyPriceData[_selectedDay.month] ?? 0.0).toString();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Milk Consumption and Price'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _consumptionController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(hintText: 'Enter milk in KG'),
              ),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(hintText: 'Enter price per KG'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final consumption = int.tryParse(_consumptionController.text);
                final price = double.tryParse(_priceController.text);
                if (consumption != null && price != null) {
                  setState(() {
                    _consumptionData[_selectedDay] = consumption;
                    _monthlyPriceData[_selectedDay.month] = price;
                    _calculateMonthlyTotals(); // Recalculate monthly totals

                    final box = Hive.box('milkConsumption');
                    box.put('data', _consumptionData);
                    box.put('price', _monthlyPriceData);
                    box.put('monthlyTotal', _monthlyTotalPrice);
                  });
                  Navigator.of(context).pop();
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
