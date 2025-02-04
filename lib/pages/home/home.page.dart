import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mytransportation/system/column_builder.dart';
import 'package:mytransportation/atm.api.dart';

GlobalKey<HomePageState> homePageKey = GlobalKey();



class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  centerOnUser() async {
    final pos = await determinePosition();
    mapController.move(pos, 17);

  }

  MapController mapController =   MapController();

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,

      options: MapOptions(

        initialCenter: LatLng(45.464219, 9.189606),
        initialZoom: 16,
        //  minZoom: 13,
        maxZoom: 20,
      ),
      children: [
        TileLayer(
          fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png',
        ),
        FutureBuilder(
          future: Atm().getStops(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final stops = snapshot.data!;
              return MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  builder: (context, markers) {
                    return CircleAvatar(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      child: Text(markers.length.toString()),
                    );
                  },
                  centerMarkerOnClick: true,
                  maxClusterRadius: 50,
                  markers: List.generate(stops.length, (index) {
                    final stop = stops[index];
                    return Marker(
                      point: stop.stopLocation,
                      child: GestureDetector(
                        onTap: () {
                          showDialog<void>(
                            context: context,
                            // user must tap button!
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text(
                                  'Fermata ${stop.stopName} (${stop.stopId.toString()})',
                                ),
                                content: FutureBuilder(
                                  future: stop.getWaitingTime(),
                                  builder: (context, times) {
                                    if (times.hasData) {
                                      return ColumnBuilder(
                                        mainAxisSize: MainAxisSize.min,
                                        itemCount: times.data!.length,
                                        itemBuilder: (context, index) {
                                          return ListTile(
                                            title: Text(
                                              "${times.data![index].line.code} - ${times.data![index].line.destination}",
                                            ),
                                            trailing:
                                                Text(times.data![index].toString()),
                                          );
                                        },
                                      );
                                    } else if (times.hasError) {
                                      return Text(times.error.toString());
                                    } else {
                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [CircularProgressIndicator()],
                                      );
                                    }
                                  },
                                ),
                              );
                            },
                          );
                        },
                        child: CircleAvatar(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          child: Icon(Icons.directions_bus_rounded),
                        ),
                      ),
                    );
                  }),
                ),
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
                    child: Icon(Icons.gps_fixed_rounded, color: Colors.blue),
                  ),
                ],
              );
            }
            if (snapshot.hasError) {
            }
            return MarkerLayer(markers: []);
          },
        ),
      ],
    );
  }
}


Future<LatLng> determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // When we reach here, permissions are granted and we can
  // continue accessing the position of the device.

  final position = await Geolocator.getCurrentPosition();
  final positionLatLng = LatLng(position.latitude, position.longitude);
  return positionLatLng;

}

