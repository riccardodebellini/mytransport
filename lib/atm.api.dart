import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

//Transport Stop
class Stop {
  final int stopId;
  final String stopName;
  final LatLng stopLocation;

  Stop({
    required this.stopId,
    required this.stopName,
    required this.stopLocation,
  });

  factory Stop.fromJson(Map<String, dynamic> info) {
    return Stop(
      stopId: int.tryParse(info['Code']) ?? 0,
      stopName: info['Description'] ?? "--",

      stopLocation: LatLng(
        double.tryParse(info['Location']['Y'].toString()) ?? 0.0,
        double.tryParse(info['Location']['X'].toString()) ?? 0.0,
      ),
    );
  }

  Future<List> getWaitingTime() async {
    final url =
        'https://giromilano.atm.it/proxy.tpportal/api/tpPortal/tpl/stops/$stopId/linesummary';
    final headers = await Atm().getHeaders();
    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = [];
        for (final line in data['Lines']) {
          final waitingTime = line['WaitMessage'].toString();

          final linePlaces =
              line['Line']["LineDescription"].split('${line['Code']} ')[1];

          final returnLine = Line(
            code: line["Line"]["LineCode"].toString(),
            dir: int.tryParse(line['Direction']) ?? 0,
            destination: linePlaces.split(' - ')[1],
            starting: linePlaces.split(' - ')[0],
          );
          if (waitingTime.contains("min")) {
            final time = waitingTime.split(" ")[0];
            if (time == '+30') {
              list.add(
                WaitingTime(
                  type: WaitingTimeType.int,
                  value: "+30",
                  line: returnLine,
                ),
              );
            } else {
              list.add(
                WaitingTime(
                  type: WaitingTimeType.int,
                  value: time,
                  line: returnLine,
                ),
              );
            }
          } else if (waitingTime.contains("arrivo")) {
            list.add(
              WaitingTime(type: WaitingTimeType.arriving, line: returnLine),
            );
          } else if (waitingTime.contains("ricalcolo")) {
            list.add(
              WaitingTime(type: WaitingTimeType.reloading, line: returnLine),
            );
          } else if (waitingTime.contains("coda")) {
            list.add(
              WaitingTime(type: WaitingTimeType.inQueue, line: returnLine),
            );
          } else if (waitingTime.contains("sospesa")) {
            list.add(
              WaitingTime(type: WaitingTimeType.suspended, line: returnLine),
            );
          } else {
            list.add(WaitingTime(type: WaitingTimeType.none, line: returnLine));
          }
        }
        return list;
      } else {
        return Future.error(
          "ERRORE\n\nCodice di errore: 'Stop.getWaitingTime - Code: ${response.statusCode.toString()}'\n\n----\n\nLa fermata probabilmente non esiste nel database Giromilano ATM e sparirà da questa mappa in futuro",
        );
      }
    } on Exception catch (e) {
      return Future.error(
        "ERRORE\nCodice di errore: 'Stop.getWaitingTime - Get: ${e.toString()}'",
      );
    }
  }

  Future<WaitingTime> getFilteredWaitingTime(Line choosenLine) async {
    final url =
        'https://giromilano.atm.it/proxy.tpportal/api/tpPortal/tpl/stops/$stopId/linesummary';
    final headers = await Atm().getHeaders();

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        for (final line in data['Lines']) {
          if (line['JourneyPatternId'] == choosenLine.id) {
            final waitingTime = line['WaitMessage'].toString();
            if (waitingTime.contains("min")) {
              final time = waitingTime.split(" ")[0];
              if (time == '+30') {
                return WaitingTime(
                  type: WaitingTimeType.int,
                  value: "+30",
                  line: choosenLine,
                );
              } else {
                return WaitingTime(
                  type: WaitingTimeType.int,
                  value: time,
                  line: choosenLine,
                );
              }
            } else if (waitingTime.contains("arrivo")) {
              return WaitingTime(
                type: WaitingTimeType.arriving,
                line: choosenLine,
              );
            } else if (waitingTime.contains("ricalcolo")) {
              return WaitingTime(
                type: WaitingTimeType.reloading,
                line: choosenLine,
              );
            } else if (waitingTime.contains("coda")) {
              return WaitingTime(
                type: WaitingTimeType.inQueue,
                line: choosenLine,
              );
            } else if (waitingTime.contains("sospesa")) {
              return WaitingTime(
                type: WaitingTimeType.suspended,
                line: choosenLine,
              );
            } else {
              return WaitingTime(type: WaitingTimeType.none, line: choosenLine);
            }
          }
        }
        return Future.error("Line not found");
      } else {
        return Future.error(
          "errore\nCodice di errore: 'Stop.getWaitingTime - Code: ${response.statusCode.toString()}'",
        );
      }
    } on Exception catch (e) {
      return Future.error(
        "errore\nCodice di errore: 'Stop.getWaitingTime - Get: ${e.toString()}'",
      );
    }
  }
}

//Waiting time
enum WaitingTimeType { int, arriving, reloading, inQueue, suspended, none }

class WaitingTime {
  final WaitingTimeType type;
  final dynamic value;
  final Line line;

  WaitingTime({required this.type, this.value, required this.line});

  @override
  String toString() {
    String message = "error";
    print(type.toString() + " - " + value.toString());

    switch (type) {
      case WaitingTimeType.int:
        message = "$value min";
      case WaitingTimeType.arriving:
        message = "In arrivo";
      case WaitingTimeType.reloading:
        message = "Ricalcolo";
      case WaitingTimeType.inQueue:
        message = "In coda";
      case WaitingTimeType.none:
        message = "--";
      case WaitingTimeType.suspended:
        message = "fermata sospesa";
    }
    return message;
  }
}

// Transport Line
class Line {
  final String code;
  final int dir;
  final String destination;
  final String starting;
  final TransportMode? type;

  Line({
    required this.code,
    required this.dir,
    required this.destination,
    required this.starting,
    this.type,
  });

  late String id = "$code|${dir.toString()}";

  Future<List<Stop>> getStops() async {
    final url =
        'https://giromilano.atm.it/proxy.tpportal/api/tpportal/tpl/journeyPatterns/$id/stops';
    final headers = await Atm().getHeaders();
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = data['Stops'] as List;
      final stops = items.map((item) => Stop.fromJson(item)).toList();
      return stops;
    } else {
      return [];
    }
  }

  factory Line.fromJson(Map<String, dynamic> info) {
    late String linePlaces;
    try {
      linePlaces =
          info['Line']["LineDescription"].split('${info['Code']}')[1];
    } catch (e) {
      linePlaces = info['Line']["LineDescription"];
    }

    final line = Line(
      code: info['Code'],
      dir: int.tryParse(info['Direction']) ?? 0,

      destination: linePlaces.split(' - ')[1],
      starting: linePlaces.split(' - ')[0],
    );
    print(line.destination);

    return line;
  }
}

enum TransportMode { bus, tram, metro, train, radioBus }

extension TransportModeExtension on TransportMode {
  parse(int transportMode) {
    switch (transportMode) {
      case 0:
        return TransportMode.metro;
      case 1:
        return TransportMode.tram;
      case 2:
        return TransportMode.train;
      case 3:
        return TransportMode.bus;
      case 99:
        return TransportMode.radioBus;
    }
  }
}


class Atm {
  Future<List<Stop>> getStops() async {
    final response = await http.get(
      Uri.parse(
        'https://raw.githubusercontent.com/riccardodebellini/mytransportation/refs/heads/master/web_assets/stops.json',
      ),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = data as List;
      final stops = items.map((item) => Stop.fromJson(item)).toList();
      return stops;
    } else {
      return [];
    }
  }

  Future<Map<String, String>> getHeaders() async {
    final response = await http.get(
      Uri.parse(
        'https://raw.githubusercontent.com/riccardodebellini/mytransportation/refs/heads/master/web_assets/cookies_atm.json',
      ),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final headers = Map<String, String>.from(data as Map<String, dynamic>);
      return headers;
    } else {
      return {};
    }
  }

  Future<List<Line>> getLines() async {
    final url =
        'https://giromilano.atm.it/proxy.tpportal/api/tpportal/tpl/journeyPatterns/';
    final headers = await Atm().getHeaders();

    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      print("200");
      final data = jsonDecode(response.body);
      final items = data['JourneyPatterns'] as List;
      final lines = List.generate(items.length, (i) {
        print(items[i]);
        try {
          final line = Line.fromJson(items[i]);
          return line;
        } catch (e) {
          print(e.toString());
          return Line(code: "0", dir: 0, destination: "", starting: "");
        }
      });

      return lines;
    } else {
      print('ERRORE: ${response.statusCode.toString()}\n${response.body.toString()}');
      return Future.error('ERRORE: ${response.statusCode.toString()}\n${response.body.toString()}');
    }
  }
}

void main() async {
  final line = Line.fromJson({
    "Id": "-1|0",
    "Code": "-1",
    "Direction": "0",
    "Line": {
      "OperatorCode": "",
      "LineCode": "-1",
      "LineDescription":
          "Linea M1 (Rossa) Sesto FS - Rho Fieramilano/Bisceglie",
      "Suburban": false,
      "TransportMode": 0,
      "OtherRoutesAvailable": false,
      "Links": [],
    },
    "Stops": null,
    "Geometry": null,
    "Links": [
      {"Rel": "self", "Href": "tpl/journeyPatterns/-1|0", "Title": null},
      {
        "Rel": "geom",
        "Href": "tpl/journeyPatterns/-1|0/geometry",
        "Title": null,
      },
      {"Rel": "stops", "Href": "tpl/journeyPatterns/-1|0/stops", "Title": null},
    ],
  });
  print(line.destination);
}
