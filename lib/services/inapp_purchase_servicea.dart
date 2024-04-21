import 'package:flutter_inapp_purchase/modules.dart';

class InAppPurchaseMethods {
  late dynamic _purchaseUpdatedSubscription;
  late dynamic _purchaseErrorSubscription;
  late dynamic _connectionSubscription;
  final List<String> _subscriptionLists = [
    'sub_2',
    'sub_3',
    'sub_1',
    'sub_4',
    'sub_5',
    'sub_7',
    'demo_12',
  ];

  final List<IAPItem> _items = [];
  final List<PurchasedItem> _purchases = [];

  Map<String, PurchasedItem> successData = {};
}
