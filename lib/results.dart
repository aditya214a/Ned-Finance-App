import 'dart:math';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ResultsScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  ResultsScreen({required this.data});

  @override
  Widget build(BuildContext context) {
    double annualRevenue = data['annual_revenue'];
    double loan = data['loan']; // THIS IS SAME AS FUNDING AMOUNT
    double feePercent = data['fee_percent'];
    int revenueShareFrequency = data['revenue_share_frequency'];
    double revenueSharedPercent = data['revenue_percentage'] / 100;

    int repaymentDelay = data['repayment_delay'];

    double fees = feePercent * loan;
    double totalRevenueShare = loan + fees;
    int expectedTransfers = ((totalRevenueShare * revenueShareFrequency) /
            (annualRevenue * revenueSharedPercent))
        .ceil();
    // DATE Calculation
    DateTime currentDate = DateTime.now();
    DateTime expectedCompletionDate = revenueShareFrequency == 52
        ? currentDate
            .add(Duration(days: (expectedTransfers * 7) + repaymentDelay))
        : currentDate.add(Duration(
            days: (expectedTransfers * 30.42).toInt() + repaymentDelay));

    // Format date for display
    String formattedCompletionDate =
        DateFormat('MMMM d, yyyy').format(expectedCompletionDate);

    return Scaffold(
      appBar: AppBar(
        title: Text('Results'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            _buildResultRow('Annual Business Revenue',
                '\$${annualRevenue.toStringAsFixed(2)}'),
            _buildResultRow('Funding Amount', '\$${loan.toStringAsFixed(2)}'),
            _buildResultRow(
                'Fees', '(${feePercent * 100}%) \$${fees.toStringAsFixed(2)}'),
            Divider(),
            _buildResultRow('Total Revenue Share',
                '\$${totalRevenueShare.toStringAsFixed(2)}'),
            _buildResultRow('Expected Transfers', expectedTransfers.toString()),
            _buildResultRow('Expected Completion Date', formattedCompletionDate,
                isLink: true),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16)),
          isLink
              ? InkWell(
                  onTap: () {},
                  child: Text(value,
                      style: TextStyle(color: Colors.blue, fontSize: 16)),
                )
              : Text(value,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
