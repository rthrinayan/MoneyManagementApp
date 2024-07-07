import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:money_management/Payload/Debit.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telephony/telephony.dart';

import '../Payload/Credit.dart';
import '../Payload/Place.dart';
import 'CreditData.dart';
import 'DebitData.dart';

class SmsService with ChangeNotifier{

  CreditData? creditData;
  DebitData? debitData;
  int? prevReadTime = 0;
  late String format;
  late Gemini gemini;
  List<Credit> credits = [];
  List<Debit> debits = [];
  List<SmsMessage> temp = [];

  SmsService({required this.creditData, required this.debitData}){
    const geminiAIToken = "AIzaSyCauRZs_olUpP-s7fYJ3-L86ox_PFT-XlI";
    Gemini.init(apiKey: geminiAIToken);
    gemini = Gemini.instance;
    format = '''Response for sms in following format in Json format, if the sms is related to transaction
                  strictly respond in the below form only
                  Example SMS: Money Transfer:Rs 50.00 from HDFC Bank A/c **3271 on 19-01-24 to MOHAMMED MUSHTAQ UPI: 401953928215 Not you? Call 18002586161
                  Example Output Response JSon:
                  {
                    "transaction_type": "debit",
                    "amount": "50.00",
                    "from": "HDFC Bank A/c **3271",
                    "to": "MOHAMMED MUSHTAQ UPI: 401953928215",
                    "date": "19-01-24",
                    "note": "Money Transfer",
                    "contact_number": "18002586161"
                   }''';
    initialize();
  }


  Future<void> initialize() async {
    credits =[]; debits = [];
    await getReadTime();
  }

  Future<void> updateReadTime(int dateTime) async{
    print("Updating ReadTime $dateTime");
    try{
      final prefs = await SharedPreferences.getInstance();
      prefs.setInt("prevReadTime",dateTime);
    }on Exception{
      print("Failed to save");
    }
  }

  Future<void> getReadTime() async {
    final prefs = await SharedPreferences.getInstance();
    if(prefs.containsKey("prevReadTime")){
      prevReadTime = prefs.getInt("prevReadTime");
    }
  }

  Future<void> smsAnalysis(List<SmsMessage> messages) async{

    for (var sms in messages) {
       await geminiResponse(sms);
    }

    print("${debits.length}  ${credits.length} haha") ;

    if(debits.isEmpty && credits.isEmpty) return;
    await creditData!.addListOfCredits(credits);
    await debitData!.addListOfDebits(debits);
    notifyListeners();
  }

  List<SmsMessage> get fetchedSms{
    return temp;
  }


  Future<void> fetchSms() async{
    int dateTime = DateTime.now().millisecondsSinceEpoch;
    Telephony telephony = Telephony.instance;
    List<SmsMessage> messages = await telephony.getInboxSms(
        filter:  SmsFilter.where(SmsColumn.DATE)
            .greaterThanOrEqualTo(prevReadTime.toString())
    );
    temp = messages;
    await updateReadTime(dateTime);
    await smsAnalysis(messages);

  }

  Future<void> geminiResponse(SmsMessage message) async {
    var prompt = '''If this sms is related to transaction debit/ credit respond yes otherwise no, here is the "
                    sms: ${message.body}''';
    var value = await gemini.text(prompt);
    String? response = value?.content?.parts?.last.text;
    if(response!.toUpperCase().contains("NO")){
      print("Irrelevant");
      return;
    }
    prompt = '''$format + "Here is the sms on which you have to respond like above format
                    sms : ${message.body}''';

    Map<String, dynamic> data = {};
    await gemini.text(prompt).then(
          (value) {
        if (value?.content?.parts?.isNotEmpty == true) {
          data = jsonDecode(value!.content!.parts!.last.text!.trim());
        } else {
          throw const FormatException('No JSON content found.');
        }
      },
    ).catchError((error) {
      throw error;
    });

    if(data['transaction_type'].toUpperCase().contains("DEBIT")){
        credits.add(Credit(
          productName: data['to'],
          cost: double.parse(data['amount']),
          quantity: 1,
          transactionId: creditData!.data.length,
          createdDate: DateTime.now(),
          place: const Place(longitude: 0, latitude: 0, address: ''),
        ));
        print("Credit");
    }
    else if(data['transaction_type'].toUpperCase().contains("CREDIT")){
      debits.add(Debit(
        createdDate: DateTime.now(),
        amount: double.parse(data['amount']),
        transactionId: debitData!.data.length,
      ));
      print("Debit");
    }
  }
}

