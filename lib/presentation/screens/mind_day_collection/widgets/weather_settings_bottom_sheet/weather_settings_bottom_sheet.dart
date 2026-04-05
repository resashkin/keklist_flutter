import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:keklist/domain/services/weather/weather_api_service.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';

final class WeatherSettingsBottomSheet extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final void Function(double lat, double lon) onSave;
  final WeatherApiService weatherApiService;

  const WeatherSettingsBottomSheet({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    required this.onSave,
    required this.weatherApiService,
  });

  @override
  State<WeatherSettingsBottomSheet> createState() => _WeatherSettingsBottomSheetState();
}

final class _WeatherSettingsBottomSheetState extends State<WeatherSettingsBottomSheet> {
  late final TextEditingController _latController;
  late final TextEditingController _lonController;
  bool _isDetecting = false;
  String? _locationError;
  String? _locationName;

  @override
  void initState() {
    super.initState();
    _latController = TextEditingController(
      text: widget.initialLatitude?.toString() ?? '',
    );
    _lonController = TextEditingController(
      text: widget.initialLongitude?.toString() ?? '',
    );
    _latController.addListener(_clearLocationName);
    _lonController.addListener(_clearLocationName);
  }

  @override
  void dispose() {
    _latController.removeListener(_clearLocationName);
    _lonController.removeListener(_clearLocationName);
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  void _clearLocationName() {
    if (_locationName != null) setState(() => _locationName = null);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.weatherSettings,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            OutlinedButton.icon(
              onPressed: _isDetecting ? null : _detectLocation,
              icon: _isDetecting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, size: 18),
              label: Text(
                _isDetecting
                    ? context.l10n.weatherDetectingLocation
                    : context.l10n.weatherUseMyLocation,
              ),
            ),
            if (_locationError != null) ...[
              const SizedBox(height: 8.0),
              Text(
                _locationError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (_locationName != null) ...[
              const SizedBox(height: 8.0),
              Text(
                _locationName!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 12.0),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    context.l10n.weatherOrEnterManually,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 12.0),
            TextField(
              controller: _latController,
              keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
              decoration: InputDecoration(
                labelText: context.l10n.weatherLatitude,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12.0),
            TextField(
              controller: _lonController,
              keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
              decoration: InputDecoration(
                labelText: context.l10n.weatherLongitude,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _onSave,
              child: Text(context.l10n.weatherSaveLocation),
            ),
            SafeArea(child: const SizedBox(height: 8.0)),
          ],
        ),
      ),
    );
  }

  Future<void> _detectLocation() async {
    setState(() {
      _isDetecting = true;
      _locationError = null;
      _locationName = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = context.l10n.weatherLocationServicesDisabled;
          _isDetecting = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = context.l10n.weatherLocationPermissionDenied;
            _isDetecting = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = context.l10n.weatherLocationPermissionPermanentlyDenied;
          _isDetecting = false;
        });
        await Geolocator.openAppSettings();
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 15),
        ),
      );

      if (!mounted) return;
      _latController.text = position.latitude.toStringAsFixed(4);
      _lonController.text = position.longitude.toStringAsFixed(4);

      final String? name = await widget.weatherApiService.fetchLocationName(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted) return;
      setState(() {
        _locationName = name;
        _isDetecting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationError = context.l10n.weatherLocationError;
        _isDetecting = false;
      });
    }
  }

  void _onSave() {
    final double? lat = double.tryParse(_latController.text.trim());
    final double? lon = double.tryParse(_lonController.text.trim());
    if (lat == null || lon == null) return;
    widget.onSave(lat, lon);
    Navigator.of(context).pop();
  }
}
