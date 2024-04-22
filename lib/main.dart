import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:in_app_purchase/auth/login_screen.dart';
import 'package:in_app_purchase/auth/splash_screen.dart';
import 'package:in_app_purchase/services/inapp_purchase_service.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PaymentSuccessProvider(),
      child: const MaterialApp(
        title: 'Flutter Demo',
        home: SplashScreen(),
      ),
    );
  }
}

class InApp extends StatefulWidget {
  const InApp({super.key, required this.user});
  final User user;

  @override
  _InAppState createState() => _InAppState();
}

class _InAppState extends State<InApp> {
  late dynamic _purchaseUpdatedSubscription;
  late dynamic _purchaseErrorSubscription;
  late dynamic _connectionSubscription;
  late PaymentSuccessProvider paymentSuccessProvider;
  final List<String> _productLists = [
    'product_1',
  ];
  final List<String> _subscriptionLists = [
    'sub_2',
    'sub_3',
    'sub_1',
    'sub_4',
    'sub_5',
    'sub_7',
    'demo_12',
  ];

  List<IAPItem> _items = [];
  List<PurchasedItem> _purchases = [];

  Map<String, PurchasedItem> successData = {};

  @override
  void initState() {
    super.initState();
    _getPurchases();
    FirestoreService().getSubscriptionData(widget.user.uid, context);
    paymentSuccessProvider = context.read<PaymentSuccessProvider>();

    loadAllData();
    log('Init State Called');
  }

  @override
  void dispose() {
    if (_connectionSubscription != null) {
      _connectionSubscription.cancel();
      _connectionSubscription = null;
    }
    super.dispose();
  }

  loadAllData() {
    initPlatformState();
    _getProduct();
    fetchSub();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // prepare
    var result = await FlutterInappPurchase.instance.initialize();
    log('result: $result');
    if (!mounted) return;
    // refresh items for android
    try {
      String msg = await FlutterInappPurchase.instance.consumeAll();
      log('consumeAllItems: $msg');
    } catch (err) {
      log('consumeAllItems error: $err');
    }

    _connectionSubscription =
        FlutterInappPurchase.connectionUpdated.listen((connected) {
      log('connected: $connected');
    });

    // Listen subscription success
    listenSubscriptionSuccess();
    log('Success Fully buy subscription');

    // Listen Purchase error
    _purchaseErrorSubscription =
        FlutterInappPurchase.purchaseError.listen((purchaseError) {
      log('purchase-error: $purchaseError');
    });
  }

  void _requestPurchase(IAPItem item) {
    FlutterInappPurchase.instance.requestPurchase(item.productId!);
  }

  Future _getProduct() async {
    List<IAPItem> items =
        await FlutterInappPurchase.instance.getProducts(_productLists);
    for (var item in items) {
      // log('Get Product : ${item.toString()}');
      _items.add(item);
    }

    setState(() {
      _items = items;
      _purchases = [];
    });
  }

  Future _getPurchases() async {
    List<PurchasedItem>? items =
        await FlutterInappPurchase.instance.getAvailablePurchases();
    for (var item in items!) {
      // log('Purchase List : ${item.toString()}');
      _purchases.add(item);
    }

    setState(() {
      _items = [];
      _purchases = items;
    });
  }

  Future _getPurchaseHistory() async {
    List<PurchasedItem>? items =
        await FlutterInappPurchase.instance.getPurchaseHistory();
    for (var item in items!) {
      log(item.toString());
      _purchases.add(item);
    }

    setState(() {
      _items = [];
      _purchases = items;
    });
  }

  fetchSub() {
    FlutterInappPurchase.instance.getSubscriptions(_subscriptionLists);
    // log('Subscription Data : ${data.then((value) => log('Subscription product List : $value'))}');
  }

  listenSubscriptionSuccess() {
    _purchaseUpdatedSubscription =
        FlutterInappPurchase.purchaseUpdated.listen((productItem) async {
      FlutterInappPurchase.instance
          .acknowledgePurchaseAndroid('${productItem!.purchaseToken}');
      successData['purchaseSuccess'] = productItem;
      FirestoreService().postDataToFirestore(widget.user.uid, {
        'user_id': widget.user.uid,
        'product_id': productItem.productId,
        'purchase_token': productItem.purchaseToken,
        'date': productItem.transactionDate,
      });

      log('Purchase Success data : ${successData['purchaseSuccess']!.transactionDate}');
      // log('Subscription Purchased : $subscriptionPurchased');
    });
  }

  List<Widget> _renderInApps() {
    List<Widget> widgets = _items
        .map((item) => Container(
              margin: const EdgeInsets.symmetric(vertical: 10.0),
              child: Container(
                child: Column(
                  children: <Widget>[
                    Container(
                      margin: const EdgeInsets.only(bottom: 5.0),
                      child: Text(
                        item.toString(),
                        style: const TextStyle(
                          fontSize: 18.0,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    MaterialButton(
                      color: Colors.orange,
                      onPressed: () {
                        print("---------- Buy Item Button Pressed");
                        _requestPurchase(item);
                      },
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Container(
                              height: 48.0,
                              alignment: const Alignment(-1.0, 0.0),
                              child: const Text('Buy Item'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ))
        .toList();
    return widgets;
  }

  List<Widget> _renderPurchases() {
    if (_purchases.isEmpty) {
      // If there are no purchases, display a message
      return [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10.0),
          child: const Text(
            'No purchases found.',
            style: TextStyle(
              fontSize: 18.0,
              color: Colors.black,
            ),
          ),
        ),
      ];
    } else {
      // If there are purchases, render them as usual
      return _purchases
          .map((item) => Container(
                margin: const EdgeInsets.symmetric(vertical: 10.0),
                child: Container(
                  child: Column(
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.only(bottom: 5.0),
                        child: Text(
                          item.toString(),
                          maxLines: 2,
                          style: const TextStyle(
                            fontSize: 18.0,
                            color: Colors.black,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ))
          .toList();
    }
  }

  List subscriptionSuccessData = [];

  @override
  Widget build(BuildContext context) {
    // log('Success :${successData['purchaseSuccess']}');
    double screenWidth = MediaQuery.of(context).size.width - 20;
    double buttonWidth = (screenWidth / 3) - 20;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginPage(),
                    ));
              },
              icon: const Icon(Icons.logout))
        ],
        title: const Text('Flutter Inapp Plugin by dooboolab'),
      ),
      body: Container(
        padding: const EdgeInsets.all(10.0),
        child: ListView(
          children: <Widget>[
            Text(
              'Welcome, ${widget.user.email}',
              style: const TextStyle(fontSize: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  child: Text(
                    'Running on: ${Platform.operatingSystem} - ${Platform.operatingSystemVersion}\n',
                    style: const TextStyle(fontSize: 18.0),
                  ),
                ),
                Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Container(
                          width: buttonWidth,
                          height: 60.0,
                          margin: const EdgeInsets.all(7.0),
                          child: MaterialButton(
                            color: Colors.amber,
                            padding: const EdgeInsets.all(0.0),
                            onPressed: () async {
                              print(
                                  "---------- Connect Billing Button Pressed");
                              await FlutterInappPurchase.instance.initialize();
                            },
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              alignment: const Alignment(0.0, 0.0),
                              child: const Text(
                                'Connect Billing',
                                style: TextStyle(
                                  fontSize: 16.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: buttonWidth,
                          height: 60.0,
                          margin: const EdgeInsets.all(7.0),
                          child: MaterialButton(
                            color: Colors.amber,
                            padding: const EdgeInsets.all(0.0),
                            onPressed: () async {
                              print("---------- End Connection Button Pressed");
                              await FlutterInappPurchase.instance.finalize();
                              if (_purchaseUpdatedSubscription != null) {
                                _purchaseUpdatedSubscription.cancel();
                                _purchaseUpdatedSubscription = null;
                              }
                              if (_purchaseErrorSubscription != null) {
                                _purchaseErrorSubscription.cancel();
                                _purchaseErrorSubscription = null;
                              }
                              setState(() {
                                _items = [];
                                _purchases = [];
                              });
                            },
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              alignment: const Alignment(0.0, 0.0),
                              child: const Text(
                                'End Connection',
                                style: TextStyle(
                                  fontSize: 16.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Container(
                              width: buttonWidth,
                              height: 60.0,
                              margin: const EdgeInsets.all(7.0),
                              child: MaterialButton(
                                color: Colors.green,
                                padding: const EdgeInsets.all(0.0),
                                onPressed: () {
                                  print("---------- Get Items Button Pressed");
                                  _getProduct();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0),
                                  alignment: const Alignment(0.0, 0.0),
                                  child: const Text(
                                    'Get Items',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                    ),
                                  ),
                                ),
                              )),
                          Container(
                              width: buttonWidth,
                              height: 60.0,
                              margin: const EdgeInsets.all(7.0),
                              child: MaterialButton(
                                color: Colors.green,
                                padding: const EdgeInsets.all(0.0),
                                onPressed: () {
                                  print(
                                      "---------- Get Purchases Button Pressed");
                                  _getPurchases();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0),
                                  alignment: const Alignment(0.0, 0.0),
                                  child: const Text(
                                    'Get Purchases',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                    ),
                                  ),
                                ),
                              )),
                          Container(
                              width: buttonWidth,
                              height: 60.0,
                              margin: const EdgeInsets.all(7.0),
                              child: MaterialButton(
                                color: Colors.green,
                                padding: const EdgeInsets.all(0.0),
                                onPressed: () {
                                  print(
                                      "---------- Get Purchase History Button Pressed");
                                  _getPurchaseHistory();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0),
                                  alignment: const Alignment(0.0, 0.0),
                                  child: const Text(
                                    'Get Purchase History',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                    ),
                                  ),
                                ),
                              )),
                        ]),
                  ],
                ),
                Column(
                  children: _renderInApps(),
                ),
                Column(
                  children: _renderPurchases(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: () {
                  fetchSub();

                  FlutterInappPurchase.instance.requestSubscription(
                    'sub_7',
                  );
                },
                child: const Text('Plan 1')),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: () {
                  fetchSub();

                  FlutterInappPurchase.instance.requestSubscription(
                    'demo_12',
                  );
                },
                child: const Text('Plan 2')),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: () {
                  fetchSub();

                  FlutterInappPurchase.instance.requestSubscription(
                    'sub_1',
                  );
                },
                child: const Text('Plan 3')),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: () {
                  fetchSub();

                  FlutterInappPurchase.instance.requestSubscription(
                    'sub_2',
                  );
                },
                child: const Text('Plan 4')),
            const SizedBox(height: 20),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: () {
                  fetchSub();

                  FlutterInappPurchase.instance.requestSubscription(
                    'sub_3',
                  );
                },
                child: const Text('Plan 5')),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: () async {
                  await FlutterInappPurchase.instance.initialize();
                },
                child: const Text('Initialize Methods')),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
  //   final url = Uri.parse('http://$serverIp:8080/verifypurchase');
  //   const headers = {
  //     'Content-type': 'application/json',
  //     'Accept': 'application/json',
  //   };
  //   final response = await http.post(
  //     url,
  //     body: jsonEncode({
  //       'source': 'google_play/app_store',
  //       'productId': purchaseDetails.productID,
  //       'verificationData':
  //           successData['purchaseSuccess']!.purchaseToken,
  //       // 'userId': uid,
  //     }),
  //     headers: headers,
  //   );
  //   if (response.statusCode == 200) {
  //     print('Successfully verified purchase');
  //     return true;
  //   } else {
  //     print('failed request: ${response.statusCode} - ${response.body}');
  //     return false;
  //   }
  // }

  void _requestSubscription(String productId) async {
    PurchasedItem? purchasedItem =
        await FlutterInappPurchase.instance.requestSubscription(productId);
    if (purchasedItem != null) {
      // Store the purchase information
      await paymentSuccessProvider.markSubscriptionPurchased(
          widget.user.uid, purchasedItem.productId!);
    }
  }
}

class PaymentSuccessProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> markSubscriptionPurchased(
      String userId, String subscriptionId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('subscriptions')
          .doc(subscriptionId)
          .set({'purchased': true});
      notifyListeners();
    } catch (e) {
      print('Error marking subscription as purchased: $e');
    }
  }

  Future<bool> subscriptionPurchased(
      String userId, String subscriptionId) async {
    try {
      DocumentSnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('subscriptions')
          .doc(subscriptionId)
          .get();
      return snapshot.exists;
    } catch (e) {
      print('Error checking subscription purchase: $e');
      return false;
    }
  }
}
