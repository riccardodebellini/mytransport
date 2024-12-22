import 'package:flutter/material.dart';
import 'package:mytransportation/pages/account/account.page.dart';
import 'package:mytransportation/pages/home/home.page.dart';
import 'package:mytransportation/system/responsive_navigation.dart';

class Navigation extends StatelessWidget {
  const Navigation({super.key});

  @override
  Widget build(BuildContext context) {
    return MainNavigation(
      pageData: [
        MainNavigationDest(
          appBarTitle: Text("Home"),
          text: "Home",
          icon: Icon(Icons.home_filled),
          destination: HomePage(),
        ),
        MainNavigationDest(
          appBarTitle: Text("Account"),
          text: "Account",
          icon: Icon(Icons.settings_rounded),
          destination: AccountPage(),
        ),
      ],
    );
  }
}
