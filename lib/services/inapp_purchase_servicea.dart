import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
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

class FirestoreService {
  static const String usersCollection = 'users';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> postDataToFirestore(
      String userId, Map<String, dynamic> subscriptionData) async {
    try {
      // Reference to the user's document in the 'users' collection
      DocumentReference userDocRef =
          _firestore.collection(usersCollection).doc(userId);

      // Reference to the 'subscriptions' subcollection within the user's document
      CollectionReference subscriptionsCollectionRef =
          userDocRef.collection('subscriptions');

      // Add subscription data to the 'subscriptions' subcollection
      await subscriptionsCollectionRef
          .add(subscriptionData)
          .whenComplete(() => log('Successfully added in data base'));
    } catch (e) {
      // Handle any errors here
      log('Error posting data to Firestore: $e');
    }
  }
}
