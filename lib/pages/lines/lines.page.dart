import 'package:flutter/material.dart';
import 'package:mytransportation/atm.api.dart';
import 'package:mytransportation/pages/lines/subpages/linerealtime.page.dart';

class LinesPage extends StatelessWidget {
  const LinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Atm().getLines(),
      builder: (context, lines) {
        if (lines.hasError) {
          return Text(lines.error.toString());
        }
        if (lines.hasData) {
          final linesList = lines.data!;

          return ListView.builder(
            itemCount: linesList.length,
            itemBuilder: (context, index) {
              final line = linesList[index];
              return ListTile(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => LineRealtime(line: line)),
                  );
                },
                title: Text(line.destination),
                leading: Text(line.code),
              );
            },
          );
        }

        return Center(child: CircularProgressIndicator());
      },
    );
  }
}
