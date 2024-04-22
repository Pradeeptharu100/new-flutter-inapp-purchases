import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/demo_home_screen.dart';

class FirestoreService {
  static const String usersCollection = 'users';
  List subscriptionData = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> postDataToFirestore(
      String userId, Map<String, dynamic> subscriptionData) async {
    try {
      DocumentReference userDocRef =
          _firestore.collection(usersCollection).doc(userId);

      CollectionReference subscriptionsCollectionRef =
          userDocRef.collection('subscriptions');
      await subscriptionsCollectionRef.add(subscriptionData).whenComplete(
          () => log('Successfully added in data base : $subscriptionData'));
    } catch (e) {
      // Handle any errors here
      log('Error posting data to Firestore: $e');
    }
  }

  getSubscriptionData(String userId, BuildContext context) async {
    try {
      // Reference to the user's document in the 'users' collection
      DocumentReference userDocRef =
          _firestore.collection(usersCollection).doc(userId);

      // Reference to the 'subscriptions' subcollection within the user's document
      CollectionReference subscriptionsCollectionRef =
          userDocRef.collection('subscriptions');

      // Query the 'subscriptions' subcollection to get all documents
      QuerySnapshot querySnapshot = await subscriptionsCollectionRef.get();

      // Extract subscription data from each document and store in a list
      List subscriptionList = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
      subscriptionData = subscriptionList;
      log('Subscription  Getter data : $subscriptionData');

      if (subscriptionData.isNotEmpty) {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DemoHomeScreen(),
            ));
      }
      return subscriptionData;
    } catch (e) {
      // Handle any errors here
      log('Error getting subscription data from Firestore: $e');
      return []; // Return an empty list in case of error
    }
  }
}
