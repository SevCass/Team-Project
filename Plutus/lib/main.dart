import 'package:Plutus/screens/new_budget_screens/income_screen.dart';
import 'package:Plutus/models/month_changer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import './screens/tab_screen.dart';
import './screens/intro_screen.dart';
import './screens/dashboard_screen.dart';
import './screens/budget_screen.dart';
import './screens/transaction_screen.dart';
import './screens/goal_screen.dart';
import './screens/new_budget_screens/first_budget_screen.dart';
import './screens/auth_screen.dart';
import './models/transaction.dart';
import './models/budget.dart';
import './providers/auth.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => Transactions()),
        ChangeNotifierProvider(create: (context) => Budgets()),
        ChangeNotifierProvider(create: (context) => Budget()),
        ChangeNotifierProvider(
          create: (_) => Auth(),
        ),
        ChangeNotifierProvider(create: (context) => MonthChanger()),
        ChangeNotifierProxyProvider<MonthChanger, Transactions>(
          update: (buildContext, monthChanger, previousTransactions) =>
              Transactions(
                  monthChanger,
                  previousTransactions == null
                      ? []
                      : previousTransactions.transactions),
          create: null,
        ),
        ChangeNotifierProxyProvider<MonthChanger, Budgets>(
          update: (buildContext, monthChanger, previousBudgets) => Budgets(
              monthChanger,
              previousBudgets == null ? [] : previousBudgets.budgets),
          create: null,
        ),
      ],
      child: Builder(
        builder: (context) => MaterialApp(
          title: 'Plutus',
          theme: ThemeData(
            primarySwatch: Colors.amber,
            primaryColor: Colors.amber,
            primaryColorLight: Colors.amberAccent,
            accentColor: Colors.white,
            canvasColor: Colors.black,
            textTheme: GoogleFonts.latoTextTheme(
              TextTheme(
                bodyText1: TextStyle(
                  color: Colors.amber,
                ),
              ),
            ),
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => OnBoardingPage(),
            DashboardScreen.routeName: (context) => DashboardScreen(),
            BudgetScreen.routeName: (context) => BudgetScreen(),
            TransactionScreen.routeName: (context) => TransactionScreen(),
            GoalScreen.routeName: (context) => GoalScreen(),
            IncomeScreen.routeName: (context) => IncomeScreen(),
            FirstBudgetScreen.routeName: (context) => FirstBudgetScreen(),
            AuthScreen.routeName: (context) => AuthScreen(),
            TabScreen.routeName: (context) => TabScreen(),
          },
        ),
      ),
    );
  }
}
