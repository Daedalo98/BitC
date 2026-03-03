import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Turin BTC Explorer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Center on Turin, Piedmont, Italy
  final LatLng _turinCenter = const LatLng(45.0703, 7.6869);

  // Simulated user location in Piazza San Carlo
  final LatLng _userLocation = const LatLng(45.0678, 7.6826);

  List<Marker> _markers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMerchants();
  }

  Future<void> _fetchMerchants() async {
    try {
      // Query btcmap.org for merchants near Turin
      final response = await http.get(Uri.parse(
          'https://api.btcmap.org/v2/elements?bounding-box=44.9,7.5,45.2,7.9'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          // 1. Create the merchant markers with the custom image
          _markers = data.map<Marker>((merchant) {
            return Marker(
              point: LatLng(merchant['lat'], merchant['lon']),
              width: 50, // Size of the interactive area
              height: 50,
              // Use Image.asset instead of Icon
              child: GestureDetector(
                onTap: () {
                  // This is where we'll add the popup/details logic later
                  print(
                      "Tapped a merchant at: ${merchant['lat']}, ${merchant['lon']}");
                },
                child: Image.asset(
                  'assets/bitcoin_logo.png', // MUST match your file name exactly
                  fit: BoxFit.contain,
                ),
              ),
            );
          }).toList();

          // 2. Add the custom user marker
          _markers.add(Marker(
            point: _userLocation,
            width: 50,
            height: 50,
            child: const Icon(Icons.person_pin_circle,
                color: Colors.blue, size: 45),
          ));

          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load merchants');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Turin BTC Explorer')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(
                initialCenter: _turinCenter,
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.btc_explorer',
                ),
                MarkerLayer(markers: _markers),
              ],
            ),
    );
  }
}
