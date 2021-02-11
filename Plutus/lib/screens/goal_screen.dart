import 'package:Plutus/widgets/debts_tab.dart';
import 'package:Plutus/widgets/goals_tab.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth.dart';
import '../models/goals.dart';
import '../widgets/goals_list_tile.dart';

class GoalScreen extends StatelessWidget {
  static const routeName = '/goal';
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    Goal goal; // will change to reflect DB
    var goalDataProvider =
        Provider.of<GoalDataProvider>(context, listen: false);
    var authDataProvider = Provider.of<Auth>(context);
    var dbRef = FirebaseFirestore.instance
        .collection('users')
        .doc(authDataProvider.getUserId())
        .collection('Goals');
    return StreamBuilder<QuerySnapshot>(
        stream: dbRef.snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) return Text('Error: ${snapshot.error}');
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return Text('Loading...');
            default:
              /*switch (snapshot.data.docs.isEmpty) {
                case true:
                  return Text('You have no goals yet...');
                default:*/
              return Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    DefaultTabController(
                      length: 2, // length of tabs
                      //initialIndex: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Container(
                            child: TabBar(
                              indicatorColor: Theme.of(context).primaryColor,
                              labelColor: Theme.of(context).primaryColor,
                              unselectedLabelColor:
                                  Theme.of(context).primaryColor,
                              labelStyle: Theme.of(context).textTheme.headline1,
                              tabs: [
                                Tab(text: 'Goals'),
                                Tab(text: 'Debt'),
                              ],
                            ),
                          ),
                          Container(
                            height: screenHeight * 0.73, //height of TabBarView
                            child: TabBarView(
                              children: <Widget>[
                                Card(
                                  color: Colors.grey[900],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  child: Expanded(
                                    child: ListView.builder(
                                      //shrinkWrap: true,
                                      itemCount: snapshot.data.docs.length,
                                      itemBuilder: (context, index) {
                                        snapshot.data.docs.map(
                                          (doc) {
                                            // initialize the goal with the document data
                                            goal = goalDataProvider
                                                .initializeGoal(doc);
                                          },
                                        );
                                        return GoalsListTile(goal);
                                      },
                                    ),
                                  ),
                                ),
                                //TODO build Debt list tile
                                Column(
                                  children: <Widget>[
                                    Expanded(
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: snapshot.data.docs.length,
                                        itemBuilder: (context, index) {
                                          snapshot.data.docs.map(
                                            (doc) {
                                              // initialize the goal with the document data
                                              goal = goalDataProvider
                                                  .initializeGoal(doc);
                                            },
                                          );
                                          return GoalsListTile(goal);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            /*ListView(
                padding: EdgeInsets.all(12.0),
                children: snapshot.data.docs.map((doc) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5.0, vertical: 8.0),
                    child: Container(
                      child: ListTile(
                        onLongPress: () {
                          capture info from this document into the goal object provided above
                            and offer them to either update or delete possibly
                        },
                      ),
                    ),
                  );
                }).toList(),
              );*/
          }
        }
        //}
        );
  }
}
