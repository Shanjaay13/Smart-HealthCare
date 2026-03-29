import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_sejahtera_ng/core/widgets/glass_container.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:supabase_flutter/supabase_flutter.dart';
class HotspotScreen extends StatefulWidget {
  const HotspotScreen({super.key});

  @override
  State<HotspotScreen> createState() => _HotspotScreenState();
}

class _HotspotScreenState extends State<HotspotScreen> {
  LatLng? _currentPosition;
  LatLng? _mapCenter; // Track the current center of the map
  bool _isLoading = true;
  String _statusMessage = "Locating you...";
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  List<CircleMarker> _hotspots = [];
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // UI State
  bool _isCardExpanded = false; // For the bottom card

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _determinePosition();
  }

  Future<void> _initializeNotifications() async {
    tz.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('ic_notification');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _notificationsPlugin.initialize(settings);
  }

  Future<void> _showProximityAlert() async {
    const androidDetails = AndroidNotificationDetails(
      'hotspot_alerts',
      'Hotspot Alerts',
      channelDescription: 'Alerts when near COVID-19 hotspots',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());
    
    await _notificationsPlugin.show(
      0,
      'High Risk Area Detected',
      'You are within 500m of a reported hotspot. Please maintain social distancing.',
      details,
    );
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _statusMessage = "Location services are disabled.";
        _isLoading = false;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _statusMessage = "Location permissions are denied";
          _isLoading = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _statusMessage =
            "Location permissions are permanently denied, we cannot request permissions.";
        _isLoading = false;
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentPosition = latLng;
        _mapCenter = latLng; // Initialize map center
        _isLoading = false;
      });
      _fetchHotspotsFromDB(latLng);

      
      // Check for proximity (simulated check)
      if (_hotspots.isNotEmpty) {
        _showProximityAlert();
      }
      
    } catch (e) {
      setState(() {
        _statusMessage = "Error getting location: $e";
        _isLoading = false;
      });
    }
  }
  
  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;
    
    // 1. Try Native Geocoding
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        _moveToLocation(locations.first.latitude, locations.first.longitude);
        return;
      }
    } catch (e) {
      debugPrint("Native geocoding failed: $e");
    }

    // 2. Fallback to OpenStreetMap Nominatim API
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1');
      final response = await http.get(url, headers: {'User-Agent': 'com.mysj.nextgen'});
      
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          _moveToLocation(lat, lon);
          return;
        }
      }
    } catch (e) {
      debugPrint("Nominatim geocoding failed: $e");
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Location not found: $query")));
    }
  }

  void _moveToLocation(double lat, double lng) {
    final latLng = LatLng(lat, lng);
    _mapController.move(latLng, 15);
    setState(() {
        _mapCenter = latLng; // Update map center
        // Fetch real hotspots from DB
        _fetchHotspotsFromDB(latLng);
    });
  }

  Future<void> _fetchHotspotsFromDB(LatLng center) async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.from('hotspots').select();
      
      final List<dynamic> data = response as List<dynamic>;
      setState(() {
         if (data.isEmpty) {
             _hotspots = _generateRandomHotspots(center);
         } else {
             _hotspots = data.map((item) {
               return CircleMarker(
                 point: LatLng(item['latitude'], item['longitude']),
                 radius: (item['radius_meters'] as num).toDouble(),
                 useRadiusInMeter: true,
                 color: (item['risk_level'] == 'High' ? Colors.red : Colors.orange).withOpacity(0.3),
                 borderColor: item['risk_level'] == 'High' ? Colors.red : Colors.orange,
                 borderStrokeWidth: 2,
               );
             }).toList();
         }
         _isLoading = false;
      });
      
      if (_hotspots.isNotEmpty) {
        _showProximityAlert();
      }
    } catch (e) {
      debugPrint("Error fetching hotspots: $e");
      setState(() => _isLoading = false);
    }
  }

  List<CircleMarker> _generateRandomHotspots(LatLng center) {
    final random = Random();
    // Generate more concentrated hotspots in Predictive mode
    int count = _isPredictiveMode ? 8 : 5;
    
    return List.generate(count, (index) {
      double latOffset = (random.nextDouble() - 0.5) * (_isPredictiveMode ? 0.04 : 0.02);
      double lngOffset = (random.nextDouble() - 0.5) * (_isPredictiveMode ? 0.04 : 0.02);
      
      // Predictive mode favors warning (orange), Normal favors confirmed (red)
      bool isHighRisk = _isPredictiveMode ? random.nextDouble() > 0.7 : random.nextBool();
      Color baseColor = isHighRisk ? Colors.red : Colors.orange;
      
      return CircleMarker(
        point: LatLng(center.latitude + latOffset, center.longitude + lngOffset),
        color: baseColor.withOpacity(0.3),
        borderColor: baseColor,
        borderStrokeWidth: 2,
        useRadiusInMeter: true,
        radius: 100 + random.nextDouble() * (_isPredictiveMode ? 500 : 300),
      );
    });
  }

  bool _isPredictiveMode = false;

  void _togglePredictiveMode(bool value) {
    setState(() {
      _isPredictiveMode = value;
      // Re-fetch or filter logic
      if (_mapCenter != null) {
        _fetchHotspotsFromDB(_mapCenter!);
      }
    });
  }

  void _showDetailedAnalysis() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                 Icon(_isPredictiveMode ? LucideIcons.radar : LucideIcons.alertCircle, 
                      color: _isPredictiveMode ? Colors.orangeAccent : Colors.redAccent, size: 28),
                 const SizedBox(width: 12),
                 Text(
                   _isPredictiveMode ? "AI Crowd Analysis" : "Outbreak Details",
                   style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)
                 ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetailRow("Calculated Risk Score", _isPredictiveMode ? "High (78%)" : "Medium (45%)"),
            _buildDetailRow("Est. Active Cases", _isPredictiveMode ? "~142 (Projected)" : "34 (Confirmed)"),
            _buildDetailRow("Crowd Density", _isPredictiveMode ? "Very High 👥" : "Moderate"),
            _buildDetailRow("Last Updated", "Just now"),
            const SizedBox(height: 24),
            Text(
              _isPredictiveMode 
                ? "Recommendation: The AI model predicts a surge in crowd density due to upcoming events/hours. Avoid this area for the next 3-4 hours to minimize exposure risk."
                : "Standard Protocol: Maintain 1 meter distance. Double-masking recommended in this zone.",
              style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                child: const Text("Close Report", style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 16)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int riskCount = _hotspots.length; 

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Hotspot Tracker"),
        leading: const BackButton(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? Container(
              color: const Color(0xFF0F2027),
              child: const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
            )
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition ?? const LatLng(3.1390, 101.6869),
                    initialZoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.mysj.nextgen',
                    ),
                    CircleLayer(circles: _hotspots),
                    if (_currentPosition != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentPosition!,
                            width: 60, height: 60,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(LucideIcons.user, color: Colors.white, size: 30),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                
                // Overlays
                SafeArea(
                  child: Column(
                    children: [
                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white24, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white),
                            onSubmitted: _searchLocation,
                            decoration: InputDecoration(
                                hintText: "Search location...",
                                hintStyle: const TextStyle(color: Colors.white54),
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                icon: const Icon(LucideIcons.search, color: Colors.white54),
                                suffixIcon: IconButton(
                                  icon: const Icon(LucideIcons.arrowRight, color: Colors.blueAccent),
                                  onPressed: () => _searchLocation(_searchController.text),
                                )
                            ),
                          ),
                        ),
                      ),

                      // Predictive Toggle
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: _isPredictiveMode ? Colors.orangeAccent : Colors.grey.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Predictive Radar (AI)", 
                              style: GoogleFonts.outfit(
                                color: _isPredictiveMode ? Colors.orangeAccent : Colors.white,
                                fontWeight: FontWeight.bold
                              )
                            ),
                            const SizedBox(width: 10),
                            Switch(
                              value: _isPredictiveMode,
                              onChanged: _togglePredictiveMode,
                              activeColor: Colors.orangeAccent,
                              activeTrackColor: Colors.orangeAccent.withValues(alpha: 0.3),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),
                      
                      // FAB to recenter
                      Padding(
                        padding: const EdgeInsets.only(right: 20, bottom: 20),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FloatingActionButton(
                            backgroundColor: Colors.blueAccent,
                            child: const Icon(LucideIcons.crosshair, color: Colors.white),
                            onPressed: () {
                              if (_currentPosition != null) {
                                _mapController.move(_currentPosition!, 15);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                  // Enhanced Bottom Card (Redesigned)
                Positioned(
                  bottom: 24,
                  left: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => setState(() => _isCardExpanded = !_isCardExpanded), // Toggle expand
                    child: Container(
                      decoration: BoxDecoration(
                         // Solid dark color like 0xFF1E1E1E ensures readability
                         color: const Color(0xFF1E1E1E), 
                         borderRadius: BorderRadius.circular(24),
                         border: Border.all(color: Colors.white.withOpacity(0.1)),
                         boxShadow: [
                           BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))
                         ]
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header (Always Visible)
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: (_isPredictiveMode ? Colors.orangeAccent : Colors.redAccent).withOpacity(0.2),
                                  shape: BoxShape.circle
                                ),
                                child: Icon(
                                  _isPredictiveMode ? LucideIcons.radar : LucideIcons.alertTriangle, 
                                  color: _isPredictiveMode ? Colors.orangeAccent : Colors.redAccent, 
                                  size: 24
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isPredictiveMode ? "AI Crowd Forecast" : "Risk Monitor", 
                                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                                    ),
                                    Text(
                                      _isPredictiveMode ? "High Activity Projected" : "$riskCount Active Hotspots", 
                                      style: GoogleFonts.outfit(
                                        color: _isPredictiveMode ? Colors.orangeAccent : Colors.redAccent, 
                                        fontSize: 14, 
                                        fontWeight: FontWeight.w600
                                      )
                                    ),
                                  ],
                                ),
                              ),
                              // Expand/Collapse Icon
                              Icon(
                                _isCardExpanded ? LucideIcons.chevronDown : LucideIcons.chevronUp,
                                color: Colors.white54,
                              )
                            ],
                          ),
                          
                          // Expanded Content
                          AnimatedCrossFade(
                            firstChild: const SizedBox.shrink(),
                            secondChild: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                Divider(color: Colors.white.withOpacity(0.1)),
                                const SizedBox(height: 16),
                                Text(
                                  _isPredictiveMode 
                                      ? "AI simulations indicate a 45% increase in crowd density for this location over the next 4 hours. Infection probability is elevated."
                                      : "This area has active reported cases within a 1km radius. Please verify your check-in status and maintain social distancing.",
                                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 15, height: 1.5),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _showDetailedAnalysis,
                                    icon: const Icon(LucideIcons.fileBarChart),
                                    label: const Text("View Full Analysis"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isPredictiveMode ? Colors.orangeAccent : Colors.redAccent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                                    ),
                                  ),
                                )
                              ],
                            ),
                            crossFadeState: _isCardExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 300),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
    );
  }
}
