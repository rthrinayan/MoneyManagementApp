
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:money_management/Providers/SmsService.dart';
import 'package:telephony/telephony.dart';

class SMSWidget extends StatefulWidget {
  const SMSWidget({Key? key}) : super(key: key);

  @override
  State<SMSWidget> createState() => SMSWidgetState();
}

class SMSWidgetState extends State<SMSWidget> {
  late SmsService smsService;
  final telephony = Telephony.instance;


  @override
  void initState() {
    super.initState();
    initializeSmsService();
  }

  Future<void> initializeSmsService() async {
    smsService = SmsService(creditData: null, debitData: null);
    await smsService.fetchSms(); // Assuming this method fetches SMS messages
    setState(() {}); // Update the UI after initialization
  }


  @override
  Widget build(BuildContext context) {
    print("SMS.dart Re-called");
    if (smsService == null) {
      return const Center(
        child: CircularProgressIndicator(), // Show loading indicator while initializing
      );
    }

    const geminiAIToken = "AIzaSyCauRZs_olUpP-s7fYJ3-L86ox_PFT-XlI";
    Gemini.init(apiKey: geminiAIToken);
    final gemini = Gemini.instance;
    var format = '''Response for sms in following format in Json format, if the sms is related to transaction
                  1st line is credit / debit if not of those two types respond invalid
                  2nd line amount credited/debited
                  3rd line From if credited and To if debited
                  Example SMS: Money Transfer:Rs 50.00 from HDFC Bank A/c **3271 on 19-01-24 to MOHAMMED MUSHTAQ UPI: 401953928215 Not you? Call 18002586161
                  Example Output: {
                    "transaction_type": "debit",
                    "amount": "Rs 50.00",
                    "from": "HDFC Bank A/c **3271",
                    "to": "MOHAMMED MUSHTAQ UPI: 401953928215",
                    "date": "19-01-24",
                    "note": "Money Transfer",
                    "contact_number": "18002586161"
                    }
                    If not a transaction then simply keep 
                    {
                      "transaction_type" : invalid
                    }''';

    List<SmsMessage> messages = smsService.fetchedSms;
    print("SMS.dart Re-called & messageLength is ${messages.length}");
    return Scaffold(
      body: ListView.builder(
        itemCount: messages.length,
        itemBuilder: (BuildContext context, int index) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                minVerticalPadding: 8,
                minLeadingWidth: 4,
                title: Text(messages[index].body ?? 'empty'),
                subtitle: Text(messages[index].date.toString()),
              ),
              const Divider()
            ],
          );
        },
      ),
    );
  }
}
