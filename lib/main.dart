import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';

import 'package:ned_flutter_app/results.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Financing Options',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FinancingScreen(),
    );
  }
}

class FinancingScreen extends StatefulWidget {
  @override
  _FinancingScreenState createState() => _FinancingScreenState();
}

class _FinancingScreenState extends State<FinancingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _revenueController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  int _loanAmount = 50000;
  double revenue = 250000;
  double _loanMax = 83333; // Default max value
  double _revenueVal = 1; // Default max value

  String repaymentDelay = '30 days';
  String fundUsage = 'Marketing';
  bool isMonthly = true;
  List<Map<String, dynamic>> fundEntries = [];
  Map<String, dynamic>? _configData;

  @override
  void initState() {
    super.initState();
    fetchConfig();
    _revenueController.addListener(_updateMaxLoanAmount);
  }

  /// Function to dynamically update the loan amount slider max
  void _updateMaxLoanAmount() {
    setState(() {
      double revenueValue = double.tryParse(_revenueController.text) ?? 0;
      _loanMax = (revenueValue / 3).clamp(50000, double.infinity);
      _revenueVal = revenueValue;
      _loanAmount = (_loanMax / 2).toInt();
    });
  }

  @override
  void dispose() {
    _revenueController.removeListener(_updateMaxLoanAmount);
    _revenueController.dispose();
    super.dispose();
  }

  // Fetch config once and store it to avoid rebuilding
  Future<void> fetchConfig() async {
    try {
      final response = await http.get(Uri.parse(
          'https://gist.githubusercontent.com/motgi/8fc373cbfccee534c820875ba20ae7b5/raw/7143758ff2caa773e651dc3576de57cc829339c0/config.json'));

      if (response.statusCode == 200) {
        List<dynamic> rawData = json.decode(response.body);
        // Parsing data for easy access
        Map<String, dynamic> parsedData = {
          for (var item in rawData) item['name']: item
        };
        setState(() {
          _configData = parsedData;
        });

        // log("${_configData?["revenue_amount"]['label']}");
      } else {
        throw Exception('Failed to load configuration');
      }
    } catch (error) {
      log('Error fetching config: $error');
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // TODO MAKE IT DYNAMIC
      Map<String, dynamic> resultData = {
        'annual_revenue': _revenueVal,
        'loan': _loanAmount,
        'fee_percent':
            double.parse(_configData?['desired_fee_percentage']['value']),
        'revenue_share_frequency': isMonthly ? 12 : 52,
        'revenue_percentage':
            (100 * (0.156 / 6.2055 / _revenueVal) * (_loanAmount * 10)),
        'repayment_delay': int.parse(repaymentDelay.split(' ')[0]),
      };

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsScreen(data: resultData),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Financing Options')),
      body: _configData == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),
                    Text('${_configData?['revenue_amount']['label']} *'),
                    TextFormField(
                      controller: _revenueController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          prefixText: '\$',
                          hintText:
                              "${_configData?['revenue_amount']['placeholder'].substring(1)}"),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                    SizedBox(height: 20),
                    Text('${_configData?['funding_amount']['label']} '),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _loanAmount.toDouble(),
                            min: 1,
                            max: (_loanMax / 1000.0).toInt() * 1000,
                            divisions: (_loanMax / 1000).toInt(),
                            label: _loanAmount.toString(),
                            onChanged: (double newValue) {
                              setState(() {
                                _loanAmount = newValue.toInt();
                              });
                            },
                          ),
                        ),
                        Text('\$$_loanAmount')
                      ],
                    ),
                    Text(
                        'Revenue share percentage: ${_revenueVal != 0 ? '${(100 * (0.156 / 6.2055 / _revenueVal) * (_loanAmount * 10)).toStringAsFixed(2)}%' : ''}'),
                    SizedBox(height: 20),
                    Text('Revenue Shared Frequency'),
                    Row(
                      children: [
                        Radio(
                          value: true,
                          groupValue: isMonthly,
                          onChanged: (value) =>
                              setState(() => isMonthly = value as bool),
                        ),
                        Text('Monthly'),
                        Radio(
                          value: false,
                          groupValue: isMonthly,
                          onChanged: (value) =>
                              setState(() => isMonthly = value as bool),
                        ),
                        Text('Weekly'),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text('${_configData?['desired_repayment_delay']['label']}'),
                    DropdownButtonFormField<String>(
                      value: repaymentDelay,
                      onChanged: (value) =>
                          setState(() => repaymentDelay = value!),
                      items: _configData?['desired_repayment_delay']['value']
                          .toString()
                          .split('*') //['30 days', '60 days', '90 days']
                          .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                    ),
                    SizedBox(height: 10),
                    Text('${_configData?['use_of_funds']['label']}'),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: fundUsage,
                            onChanged: (value) =>
                                setState(() => fundUsage = value!),
                            items: _configData?['use_of_funds']['value']
                                .toString()
                                .split('*')
                                .map((e) =>
                                    DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _descriptionController,
                            decoration:
                                InputDecoration(hintText: 'Description'),
                            // validator: (value) =>
                            //     value!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(hintText: 'Amount'),
                            // validator: (value) =>
                            //     value!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              fundEntries.add({
                                'category': fundUsage,
                                'description': _descriptionController.text,
                                'amount': _amountController.text
                              });
                              _descriptionController.clear();
                              _amountController.clear();
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Column(
                      children: fundEntries.map((entry) {
                        return Row(
                          children: [
                            Expanded(child: Text(entry['category'])),
                            Expanded(child: Text(entry['description'])),
                            Expanded(child: Text(entry['amount'])),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                setState(() {
                                  fundEntries.remove(entry);
                                });
                              },
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitForm,
                      child: Text('Submit'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
