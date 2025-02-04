import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:mytransportation/atm.api.dart';
import 'package:mytransportation/system/column_builder.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../home/home.page.dart';

class LineRealtime extends StatefulWidget {
  final Line line;

  const LineRealtime({super.key, required this.line});

  @override
  State<LineRealtime> createState() => _LineRealtimeState();
}

class _LineRealtimeState extends State<LineRealtime> {
  late Line line = widget.line;
  late Future<List<Stop>> getStops;

  final GlobalKey<RefreshIndicatorState> isReloading =
      GlobalKey<RefreshIndicatorState>();

  late Future<List<Stop>> future = line.getStops();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${line.code} - ${line.destination}'),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.of(context).pop();
                final dir = (line.dir == 0 ? 1 : 0);
                line = Line(
                  code: line.code,
                  dir: dir,
                  destination: line.starting,
                  starting: line.destination,
                );
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => LineRealtime(line: line),
                  ),
                );
              },
              icon: Icon(Icons.swap_calls_rounded),
            ),
          ],
          bottom: const TabBar(
            tabs: [Tab(child: Text("Stops")), Tab(child: Text('Map'))],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async {},
          key: isReloading,
          child: TabBarView(
            children: [
              FutureBuilder(
                future: line.getStops(),
                builder: (context, stops) {
                  if (stops.hasError) {
                    return Text(stops.error.toString());
                  } else if (stops.hasData) {
                    return SingleChildScrollView(
                      child: ColumnBuilder(
                        itemCount: stops.data!.length,
                        itemBuilder: (context, index) {
                          final stop = stops.data![index];
                          return ListTile(
                            title: Text(stop.stopName.toString()),
                            subtitle: Text(stop.stopId.toString()),
                            trailing: FutureBuilder(
                              future: stop.getFilteredWaitingTime(line),
                              builder: (context, waitingTime) {
                                if (index++ == stops.data!.length) {
                                  return Text("Capolinea");
                                }

                                if (waitingTime.hasError) {
                                  return IconButton(
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            waitingTime.error.toString(),
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    icon: Icon(
                                      Icons.bus_alert_rounded,
                                      color:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                  );
                                } else if (waitingTime.hasData) {
                                  if (waitingTime.data!.type ==
                                      WaitingTimeType.arriving) {
                                    return CircleAvatar(
                                      backgroundColor: Colors.deepOrange,
                                      foregroundColor: Colors.white,
                                      child: Icon(Icons.directions_bus_rounded),
                                    );
                                  }
                                  return Text(waitingTime.data!.toString());
                                } else {
                                  return Skeletonizer(
                                    textBoneBorderRadius: TextBoneBorderRadius(
                                      BorderRadius.all(Radius.circular(4)),
                                    ),
                                    enabled: true,
                                    child: Text('0 min'),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
                    );
                  } else {
                    return Skeletonizer(
                      textBoneBorderRadius: TextBoneBorderRadius(
                        BorderRadius.all(Radius.circular(4)),
                      ),
                      enabled: true,
                      child: ListView.builder(
                        itemCount: 7,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text('Via Frassini Via Pini'),
                            subtitle: const Text('00000'),
                            trailing: const Text("0 min"),
                          );
                        },
                      ),
                    );
                  }
                },
              ),
              FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(45.464219, 9.189606),
                  initialZoom: 16,
                  //  minZoom: 13,
                  maxZoom: 20,
                ),
                children: [
                  TileLayer(
                    fallbackUrl:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png',
                  ),
                  FutureBuilder(
                    future: line.getStops(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final stops = snapshot.data!;
                        print(stops);
                        return MarkerLayer(
                          markers: List.generate(stops.length, (index) {
                            final stop = stops[index];
                            final location = stop.stopLocation;

                            return Marker(
                              point: LatLng(location.latitude, location.longitude),
                              child: FutureBuilder(
                                future: stop.getFilteredWaitingTime(line),
                                builder: (context, waitingTime) {
                                  if (index++ == snapshot.data!.length) {
                                    return Text("Capolinea");
                                  }

                                  if (waitingTime.hasError) {
                                    return IconButton(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              waitingTime.error.toString(),
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      icon: Icon(
                                        Icons.bus_alert_rounded,
                                      ),
                                    );
                                  } else if (waitingTime.hasData) {
                                    if (waitingTime.data!.type ==
                                        WaitingTimeType.arriving) {
                                      return CircleAvatar(
                                          foregroundColor: Colors.white,
                                          backgroundColor: Colors.deepOrange,
                                          child: Icon(Icons.directions_bus_rounded));
                                    }
                                    return Icon(Icons.location_pin);
                                  } else {
                                    return Skeletonizer(
                                      textBoneBorderRadius: TextBoneBorderRadius(
                                        BorderRadius.all(Radius.circular(4)),
                                      ),
                                      enabled: true,
                                      child: Text('0 min'),
                                    );
                                  }
                                },
                              ),
                            );
                          }),
                        );
                      } else if (snapshot.hasError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(snapshot.error.toString())),
                        );
                      }
                      return Center(child: CircularProgressIndicator());
                    },
                  ),
                  FutureBuilder(
                    future: determinePosition(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return MarkerLayer(
                          markers: [
                            Marker(
                              point: snapshot.data!,
                              child: Icon(
                                Icons.gps_fixed_rounded,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        );
                      }
                      if (snapshot.hasError) {}
                      return MarkerLayer(markers: []);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
