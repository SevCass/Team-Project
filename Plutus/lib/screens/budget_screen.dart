import 'package:Plutus/models/category.dart';
import 'package:Plutus/models/transaction.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:provider/provider.dart';

import './new_budget_screens/income_screen.dart';
import '../models/budget.dart';
import '../models/month_changer.dart';
import '../widgets/budget_list_tile.dart';
import '../providers/auth.dart';

class BudgetScreen extends StatefulWidget {
  static const routeName = '/budget';

  @override
  _BudgetScreenState createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  void _enterBudget(BuildContext context, Budget budget) {
    Navigator.of(context)
        .pushNamed('/income', arguments: budget)
        .then((newBudget) {
      if (newBudget == null) return;
      Provider.of<BudgetDataProvider>(context, listen: false)
          .addBudget(newBudget, context); //TODO check if needed
    });
  }

  double _getRemainingAmountPerDay(
      MonthChanger monthData, double remainingAmount) {
    var daysInMonth = monthData.selectedMonth == 12
        ? DateTime(monthData.selectedYear + 1, monthData.selectedMonth + 1, 0)
        : DateTime(monthData.selectedYear, monthData.selectedMonth + 1, 0);

    int daysLeft;
    double remainingAmountPerDay;
    if (monthData.selectedMonth == DateTime.now().month &&
        monthData.selectedYear == DateTime.now().year) {
      //current month (currently spending)
      daysLeft = daysInMonth.day - DateTime.now().day + 1;
      remainingAmountPerDay = remainingAmount / daysLeft;
    } else if (monthData.selectedYear > DateTime.now().year ||
        (monthData.selectedMonth > DateTime.now().month &&
            monthData.selectedYear == DateTime.now().year)) {
      // in future (full month left)
      daysLeft = daysInMonth.day;
      remainingAmountPerDay = remainingAmount / daysLeft;
    } else {
      // in past (can't spend)
      daysLeft = 0;
      remainingAmountPerDay = 0;
    }
    if (remainingAmountPerDay < 0) remainingAmountPerDay = 0;

    return remainingAmountPerDay;
  }

  @override
  Widget build(BuildContext context) {
    final budgetDataProvider = Provider.of<BudgetDataProvider>(context);
    var monthData = Provider.of<MonthChanger>(context);
    var monthlyTransactions = Provider.of<Transactions>(context);
    var transactionDataProvider =
        Provider.of<Transactions>(context, listen: false);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: Container(
            width: 250,
            child: monthData.buildMonthChanger(context),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: budgetDataProvider.getmonthlyBudget(context,
                DateTime(monthData.selectedYear, monthData.selectedMonth)),
            builder: (context, budgetSnapshot) {
              if (!budgetSnapshot.hasData || budgetSnapshot.data.docs.isEmpty) {
                return Container(
                  margin: EdgeInsets.only(top: 25),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 250),
                      child: Column(
                        children: [
                          Text(
                            'No budget has been added this month.',
                            style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(context).primaryColor),
                            textAlign: TextAlign.center,
                          ),
                          RaisedButton(
                            child: Text('Add Budget'),
                            color: Theme.of(context).primaryColor,
                            textColor: Theme.of(context).canvasColor,
                            onPressed: () =>
                                _enterBudget(context, new Budget.empty()),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              } else {
                var budget = budgetDataProvider
                    .initializeBudget(budgetSnapshot.data.docs.first);

                // Get the transactions for the budget
                var budgetTransactions = FirebaseFirestore.instance
                    .collection('users')
                    .doc(Provider.of<Auth>(context, listen: false).getUserId())
                    .collection('Transactions')
                    .where(
                      'date',
                      isGreaterThanOrEqualTo: DateTime(
                        budget.getDate().year,
                        budget.getDate().month,
                        1,
                      ),
                      isLessThan: DateTime(
                        budget.getDate().year,
                        budget.getDate().month + 1,
                        1,
                      ),
                    );
                // Get the categories selected by the user for this budget
                var budgetCategories = BudgetDataProvider()
                    .getBudgetCategories(context, budget.getID());

                // Gets unbudgeted categories where transactions were made
                var budgetCat = FirebaseFirestore.instance
                    .collection('users')
                    .doc(Provider.of<Auth>(context, listen: false).getUserId())
                    .collection('Budgets')
                    .doc(budget.getID())
                    .collection('categories');

                List<String> categoryIds = [];

                budgetCat.get().then((catSnapshot) {
                  if (catSnapshot.docs.isNotEmpty)
                    catSnapshot.docs.forEach((doc) {
                      categoryIds.add(doc.id);
                    });
                });
                categoryIds.forEach((element) {
                  print(element);
                });
                budgetTransactions.get().then((transSnapshot) {
                  transSnapshot.docs.forEach((doc) async {
                    if (transSnapshot.docs.isNotEmpty) {
                      if (!categoryIds.contains(doc.data()['categoryID'])) {
                        // initialize category with relevant data from transaction
                        var category = Category();
                        category.setID(doc.data()['categoryID']);
                        category.setTitle(doc.data()['categoryTitle']);
                        category.setCodepoint(doc.data()['categoryCodepoint']);
                        category.setAmount(0.00); // 0 because unbudgeted

                        await Provider.of<CategoryDataProvider>(context,
                                listen: false)
                            .uploadCategory(budget.getID(), category, context);

                        categoryIds.add(doc.data()['categoryID']);
                      }
                    }
                  });
                });

                return Container(
                  margin: EdgeInsets.only(top: 25),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: budgetTransactions.snapshots(),
                    builder: (context, transactionSnapshots) {
                      if (!transactionSnapshots.hasData) {
                        return new Container(width: 0.0, height: 0.0);
                      }

                      var transactionExpenses = transactionDataProvider
                          .getTransactionExpenses(transactionSnapshots.data);
                      budget.calculateRemainingAmount(transactionExpenses);
                      return Card(
                        color: Colors.grey[900],
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        )),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20)),
                              child: ListTile(
                                onTap: () => _enterBudget(context, budget),
                                tileColor: Colors.grey[850],
                                title: Column(
                                  children: [
                                    Text(
                                      'Total Budget',
                                      style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              Theme.of(context).primaryColor),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Remaining',
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                  fontSize: 18),
                                            ),
                                            AutoSizeText(
                                              '\$${budget.getAmount() < transactionExpenses ? 0.00.toStringAsFixed(2) : budget.getRemainingAmount().toStringAsFixed(2)}',
                                              maxLines: 1,
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                  fontSize: 18),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Available per day',
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                  fontSize: 18),
                                            ),
                                            AutoSizeText(
                                              '\$${_getRemainingAmountPerDay(monthData, budget.getRemainingAmount()).toStringAsFixed(2)}',
                                              maxLines: 1,
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                  fontSize: 18),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: 20,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        new LinearPercentIndicator(
                                          alignment: MainAxisAlignment.center,
                                          width: 310.0,
                                          lineHeight: 14.0,
                                          percent: transactionExpenses >
                                                  budget.getAmount()
                                              ? 1
                                              : transactionExpenses /
                                                  budget.getAmount(),
                                          backgroundColor: Colors.black,
                                          progressColor: Colors.amber,
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: 20,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        AutoSizeText(
                                          '\$${transactionExpenses.toStringAsFixed(2)} of \$${budget.getAmount().toStringAsFixed(2)}',
                                          maxLines: 1,
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .primaryColor,
                                              fontSize: 18),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Divider(height: 10),
                            Expanded(
                              child: StreamBuilder<QuerySnapshot>(
                                  stream: budgetCategories,
                                  builder: (context, categorySnapshot) {
                                    if (categorySnapshot.hasData &&
                                        categorySnapshot.data.docs.isNotEmpty) {
                                      return ListView.builder(
                                          itemCount:
                                              categorySnapshot.data.docs.length,
                                          itemBuilder: (context, index) {
                                            return BudgetListTile(
                                              Provider.of<CategoryDataProvider>(
                                                      context,
                                                      listen: false)
                                                  .initializeCategory(
                                                      categorySnapshot
                                                          .data.docs[index]),
                                              budgetTransactions,
                                              ValueKey({
                                                'monthData.selectedMonth': index
                                              }), // gives a unique key to each category; necessary to stop open listtiles from one month make another month's open
                                            );
                                          });
                                    } else {
                                      if (!categorySnapshot.hasData) {
                                        return Container();
                                      } else {
                                        return Container(
                                          margin: EdgeInsets.all(16),
                                          child: Text(
                                              'There are no categories selected for this budget.',
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                  fontSize: 18)),
                                        );
                                      }
                                    }
                                  }),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
