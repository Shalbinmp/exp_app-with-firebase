import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class View_Report extends StatefulWidget {
  final String book_sel_doc;
  final String Bookname;
  final CurrentUserId;
  final companyId;
  const View_Report({super.key, required this.book_sel_doc, required this.Bookname,required this.CurrentUserId,required this.companyId});

  @override
  State<View_Report> createState() => _View_ReportState();
}
class _View_ReportState extends State<View_Report> {
  final CollectionReference userDetails = FirebaseFirestore.instance.collection('Users');
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var size;
  var height;
  var width;
  String? selectedCompanyId;

  DateTime? selectedMonth;

  @override
  void initState() {
    super.initState();
    selectedMonth = DateTime(DateTime.now().year, DateTime.now().month); // Set current month as default
    get_doc_pref().then((value) {
      print(selectedCompanyId);
    });

  }


  // Add method to pick a month
  Future<void> _selectMonth(BuildContext context) async {
    DateTime now = DateTime.now();
    DateTime initialDate = selectedMonth ?? DateTime(now.year, now.month);

    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 5, 1), // Adjust as needed
      lastDate: DateTime(now.year + 5, 12),
      selectableDayPredicate: (DateTime date) {
        // Ensure only the first day of each month is selectable
        return date.day == 1;
      },
    );

    if (selectedDate != null) {
      setState(() {
        selectedMonth = DateTime(selectedDate.year, selectedDate.month);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;

    return Scaffold(
      backgroundColor: Colors.blueGrey[200],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(onPressed: () { Navigator.pop(context); }, icon: Icon(Icons.arrow_back_ios)),
        title: Text(widget.Bookname,style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            width: width,
            color: Colors.green,
            child: ElevatedButton(
              onPressed: () => _selectMonth(context),
              child: Text(selectedMonth == null ? 'Select Month' : 'Month: ${selectedMonth!.toLocal().toString().substring(0, 7)}'),
            ),
          ),
          Expanded(
            child: StreamBuilder(
                stream: userDetails
                    .doc(this.widget.CurrentUserId)
                    .collection('company_details')
                    .doc(this.widget.companyId)
                    .collection('Books')
                    .doc(this.widget.book_sel_doc)
                    .collection('cash_transactions').snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("No data available", style: TextStyle(color: Colors.grey, fontSize: 16)));
                  }

                  List<FlSpot> lineSpots = [];
                  List<BarChartGroupData> barGroups = [];
                  Set<double> uniqueYValues = {};
                  double minY = double.infinity;
                  double maxY = double.negativeInfinity;
                  int totalInPositive = 0;
                  int totalInNegative = 0;
                  Map<int, double> dailyAmounts = {};

                  if (selectedMonth == null) {
                    return Center(child: Text("Please select a month", style: TextStyle(color: Colors.grey, fontSize: 16)));
                  }

                  DateTime startDate = DateTime(selectedMonth!.year, selectedMonth!.month, 1);
                  DateTime endDate = DateTime(selectedMonth!.year, selectedMonth!.month + 1, 0);

                  for (var doc in snapshot.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    DateTime date = DateTime.parse(data['date']);
                    if (date.isAfter(startDate.subtract(Duration(days: 1))) && date.isBefore(endDate.add(Duration(days: 1)))) {
                      double amount = double.tryParse(data['amount'].toString()) ?? 0.0;
                      dailyAmounts.update(date.day, (value) => value + amount, ifAbsent: () => amount);
                    }
                    int? amount = int.tryParse(data['amount'].toString());
                    if (amount != null) {
                      if (data['condition'] == 'Credit') {
                        totalInPositive += amount;
                      } else {
                        totalInNegative += amount;
                      }
                    }
                  }

                  dailyAmounts.forEach((day, amount) {
                    lineSpots.add(FlSpot(day.toDouble(), amount));
                    barGroups.add(BarChartGroupData(
                      x: day,
                      barRods: [
                        BarChartRodData(
                          toY: amount,
                          color: amount >= 0 ? Colors.greenAccent : Colors.redAccent,
                        ),
                      ],
                    ));
                    uniqueYValues.add(amount);
                    if (amount < minY) minY = amount;
                    if (amount > maxY) maxY = amount;
                  });

                  if (lineSpots.isEmpty && barGroups.isEmpty) {
                    return Center(child: Text("No data available for the selected month", style: TextStyle(color: Colors.grey, fontSize: 16)));
                  }

                  double midY = (0 + maxY) / 2;
                  lineSpots.add(FlSpot(1, 0));

                  return DefaultTabController(
                      length: 3,
                      child: Column(
                        children: [
                          Container(
                            color: Colors.green,
                            child: TabBar(
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.blueGrey[100],
                              indicatorColor: Colors.white,
                              tabs: [
                                Tab(icon: Icon(Icons.stacked_line_chart_rounded)),
                                Tab(icon: Icon(Icons.bar_chart)),
                                Tab(icon: Icon(Icons.pie_chart)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: TabBarView(children: [
                              Container(color: Colors.blueGrey[100], child: Line_chart(lineSpots, minY, midY, maxY, uniqueYValues)),
                              Container(color: Colors.blueGrey[100], child: Bar_chart(barGroups, minY, maxY)),
                              Container(color: Colors.blueGrey[100], child: Pie_chart(totalInPositive.toDouble(), totalInNegative.toDouble())),
                            ]),
                          ),
                        ],
                      ));
                }),
          ),
        ],
      ),
    );
  }

  String formatYAxisLabel(double value) {
    if (value >= 1000 && value < 1000000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    } else if (value >= 1000000 && value < 1000000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    }
    return value.toStringAsFixed(1);
  }

  bool isValidDouble(double value) => value.isFinite;

  Widget Line_chart(
      List<FlSpot> spots,
      double minY,
      double midY,
      double maxY,
      Set<double> uniqueYValues,
      ) {
    if (spots.isEmpty || !isValidDouble(minY) || !isValidDouble(midY) || !isValidDouble(maxY)) {
      return Center(
        child: Text(
          'No data available',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }

    // Adjust minY and maxY if only one data point exists
    double adjustedMinY = spots.length == 1 ? 0 : minY;
    double adjustedMaxY = spots.length == 1 ? spots.first.y : maxY;

    // Create the x-axis labels based on selected duration
    Map<double, String> xAxisLabels = {};
    DateTime now = DateTime.now();
    DateTime startDate = DateTime(now.year, now.month, 1); // Default to this month

    for (int i = 1; i <= DateTime(now.year, now.month + 1, 0).day; i++) {
      xAxisLabels[i.toDouble()] = i.toString();
    }

    // Define the interval for the y-axis
    double yAxisInterval = 500;

    return SingleChildScrollView(
      child: Container(
        margin: EdgeInsets.only(top: 45, bottom: 15, right: 10, left: 10),
        decoration: BoxDecoration(
          color: Colors.blueGrey[50],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: AspectRatio(
            aspectRatio: .80,
            child: LineChart(
              LineChartData(
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        // Custom interval labels
                        if (value % yAxisInterval == 0) {
                          return Text(
                            formatYAxisLabel(value),
                            style: TextStyle(color: Colors.blueGrey),
                          );
                        } else {
                          return SizedBox.shrink();
                        }
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        xAxisLabels[value] ?? value.toString(),
                        style: TextStyle(color: Colors.blueGrey),
                      ),
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                minX: 1,
                maxX: 30,
                minY: 0,
                maxY: adjustedMaxY,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    // tooltipBgColor: Colors.blueAccent,
                    getTooltipItems: (List<LineBarSpot> lineBarSpots) {
                      return lineBarSpots.map((LineBarSpot lineBarSpot) {
                        return LineTooltipItem(
                          'day: ${lineBarSpot.x.toStringAsFixed(2)}\n'
                              'amt: ${lineBarSpot.y.toStringAsFixed(2)}',
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                  // touchCallback: (LineTouchResponse touchResponse) {
                  //   // Optional: Handle touch events here
                  // },
                  handleBuiltInTouches: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }



  Widget Bar_chart(
      List<BarChartGroupData> barGroups,
      double minY,
      double maxY,
      ) {
    // Define the interval for the y-axis
    double yAxisInterval = 500;

    return Container(
      margin: EdgeInsets.only(top: 45, bottom: 15, right: 10, left: 10),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AspectRatio(
          aspectRatio: .80,
          child: BarChart(
            BarChartData(
              titlesData: FlTitlesData(
                show: true,
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      // Custom interval labels
                      if (value % yAxisInterval == 0) {
                        return Text(
                          formatYAxisLabel(value),
                          style: TextStyle(color: Colors.blueGrey),
                        );
                      } else {
                        return SizedBox.shrink();
                      }
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text(
                      value.toString(),
                      style: TextStyle(color: Colors.blueGrey),
                    ),
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              minY: 0,
              maxY: maxY,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: false),
              barGroups: barGroups,
            ),
          ),
        ),
      ),
    );
  }


  Widget Pie_chart(double totalInPositive, double totalInNegative) {
    return Container(
      margin: EdgeInsets.only(top: 45,bottom: 15,right: 10,left: 10),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AspectRatio(
          aspectRatio: 1.0,
          child: PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  value: totalInPositive,
                  color: Colors.greenAccent,
                  title: '${totalInPositive.toStringAsFixed(2)}',
                  titleStyle: TextStyle(color: Colors.white),
                ),
                PieChartSectionData(
                  value: totalInNegative,
                  color: Colors.redAccent,
                  title: '${totalInNegative.toStringAsFixed(2)}',
                  titleStyle: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> get_doc_pref() async {
    var pref = await SharedPreferences.getInstance();
    var doc_id = pref.getString('docid_company');
    setState(() {
      selectedCompanyId = doc_id!;
    });
    return selectedCompanyId!.isEmpty ? true : false;
  }
}
