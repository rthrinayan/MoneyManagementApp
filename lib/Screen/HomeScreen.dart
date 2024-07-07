import 'package:flutter/material.dart';
import 'package:money_management/Payload/Authentication.dart';
import 'package:money_management/Providers/SmsService.dart';
import 'package:money_management/Screen/SMS.dart';
import 'package:money_management/Widget/AddTransaction.dart';
import 'package:money_management/Widget/Drawer.dart';
import 'package:provider/provider.dart';
import '../Providers/CreditData.dart';
import '../Providers/DebitData.dart';
import 'CreditScreen.dart';
import 'DebitScreen.dart';

class Home extends StatefulWidget {

    const Home({Key? key}) : super(key: key);
    static const routeName ='/homeScreen';
  @override
  State<Home> createState() => _HomeState();
}

enum DisplayMode {
    homeScreen,
    debitScreen
}

class _HomeState extends State<Home> {

  late CreditData creditData;
  late DebitData debitData;
  late SmsService smsService;

  @override
  void initState() {
    creditData = Provider.of<CreditData>(context,listen: false);
    creditData.fetchCreditDataFromDatabase();
    debitData = Provider.of<DebitData>(context,listen: false);
    debitData.fetchDebitDataFromDatabase();
    super.initState();
    print("i'm Recalled");
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print("Home Screen initating SMS services");
    initializeSmsService();
  }

  Future<void> initializeSmsService() async {
    smsService = Provider.of<SmsService>(context, listen: true);
    await smsService.initialize();
    await smsService.fetchSms(); // Assuming this method fetches SMS messages
  }


  DisplayMode currentMode = DisplayMode.homeScreen;

  updateSelectIndex(int updateTheMode){
    setState(() {
      currentMode = updateTheMode == 0? DisplayMode.homeScreen : DisplayMode.debitScreen;
    });
  }

  @override
  Widget build(BuildContext context) {
    // if (smsService == null) {
    //   return const Center(
    //     child: CircularProgressIndicator(), // Show loading indicator while initializing
    //   );
    // }
    return ScaffoldMessenger(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          title: const Text("Manage your money"),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () { Provider.of<Authentication>(context,listen: false).logOut();},
            ),
          ],
        ),
        drawer: const DrawerWidget(),
        // body : const SMSWidget(),
        body: currentMode == DisplayMode.homeScreen ? CreditScreen(): Debit(),
        bottomNavigationBar: BottomNavigationBar(
          onTap: updateSelectIndex,
          currentIndex: currentMode.index,
          selectedItemColor: Colors.blueAccent,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Debit',
            ),
            BottomNavigationBarItem(
              label: 'Credit',
              icon: Icon(Icons.credit_card),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          child: const Text('+',style: TextStyle(
              fontSize: 25
          ),),
          onPressed: () {
            showModalBottomSheet(
                context: context,
                builder: (bctx) {
                  return AddTransaction(displayMode: currentMode);
                }
            );
          },
        ),
      ),
    );
  }
}


