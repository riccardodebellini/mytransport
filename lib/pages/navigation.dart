import 'package:flutter/material.dart';
import 'package:mytransportation/pages/home/home.page.dart';
import 'package:mytransportation/system/responsive_navigation.dart';

import 'lines/lines.page.dart';


class Navigation extends StatelessWidget {
  const Navigation({super.key});

  @override
  Widget build(BuildContext context) {
    return MainNavigation(
      pageData: [
        MainNavigationDest(
          tabPadding: 0,
          appBarTitle: Text("Home"),
          text: "Home",
          icon: Icon(Icons.home_filled),
          destination: HomePage(key: homePageKey,),
          smallFab: true,
          fab: MainNavigationFAB(icon: Icon(Icons.gps_fixed_rounded), onPressed: () async {
            homePageKey.currentState?.centerOnUser();
          })
        ),
        MainNavigationDest(
          appBarTitle: Text("Linee"),
          text: "Linee",
          icon: Icon(Icons.route_rounded),
          destination: LinesPage(),
        ),
      ],
    );
  }
}
