import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Flutter Inapp Plugin by dooboolab'),
          ),
          body: const InApp()),
    );
  }
}

class InApp extends StatefulWidget {
  const InApp({super.key});

  @override
  _InAppState createState() => _InAppState();
}

class _InAppState extends State<InApp> {
  late dynamic _purchaseUpdatedSubscription;
  late dynamic _purchaseErrorSubscription;
  late dynamic _connectionSubscription;
  final List<String> _productLists = [
    'product_1',
  ];
  final List<String> _subscriptionLists = [
    'sub_2',
    'sub_3',
    'sub_1',
    'sub_4',
    'sub_5',
  ];

  List<IAPItem> _items = [];
  List<PurchasedItem> _purchases = [];

  @override
  void initState() {
    super.initState();
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
    _getPurchases();
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
      log('Get Product : ${item.toString()}');
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
      log('Purchase List : ${item.toString()}');
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
    final data =
        FlutterInappPurchase.instance.getSubscriptions(_subscriptionLists);
    log('Subscription Data : ${data.then((value) => log('Value : $value'))}');
  }

  listenSubscriptionSuccess() {
    _purchaseUpdatedSubscription =
        FlutterInappPurchase.purchaseUpdated.listen((productItem) {
      FlutterInappPurchase.instance
          .acknowledgePurchaseAndroid('${productItem!.purchaseToken}');
      log('Testing');
      log('purchase-updated: $productItem');
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
    List<Widget> widgets = _purchases
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
    return widgets;
  }

  List subscriptionSuccessData = [];

  @override
  Widget build(BuildContext context) {
    log('Subscription Data :$subscriptionSuccessData');
    double screenWidth = MediaQuery.of(context).size.width - 20;
    double buttonWidth = (screenWidth / 3) - 20;

    return Container(
      padding: const EdgeInsets.all(10.0),
      child: ListView(
        children: <Widget>[
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
                            print("---------- Connect Billing Button Pressed");
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
                FlutterInappPurchase.instance.requestSubscription(
                  'sub_2',
                );
              },
              child: const Text('Plan 1')),
          const SizedBox(height: 20),
          ElevatedButton(
              onPressed: () {
                FlutterInappPurchase.instance.requestSubscription(
                  'sub_3',
                );
              },
              child: const Text('Plan 2')),
          const SizedBox(height: 20),
          ElevatedButton(
              onPressed: () async {
                await FlutterInappPurchase.instance.initialize();
              },
              child: const Text('Initialize Methods'))
        ],
      ),
    );
  }
}
