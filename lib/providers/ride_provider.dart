import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../models/ride_model.dart';
import '../services/ride_service.dart';
import 'auth_provider.dart';


// Ride Search Provider
final rideSearchProvider = StateNotifierProvider<RideSearchNotifier, AsyncValue<List<RideModel>>>((ref) {
  return RideSearchNotifier();
});

class RideSearchNotifier extends StateNotifier<AsyncValue<List<RideModel>>> {
  RideSearchNotifier() : super(const AsyncValue.data([]));

  Future<void> search({
    required String from,
    required String to,
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
    required DateTime date,
    String? userId,
    int? maxResults,
  }) async {
    state = const AsyncValue.loading();
    try {
      final rides = await RideService.searchRides(
        from: from,
        to: to,
        fromLat: fromLat,
        fromLng: fromLng,
        toLat: toLat,
        toLng: toLng,
        date: date,
        maxResults: maxResults,
      );
      
      if (rides.isEmpty && userId != null) {
        await RideService.recordRideSearch(
          userId: userId,
          from: from,
          to: to,
          fromLat: fromLat,
          fromLng: fromLng,
          toLat: toLat,
          toLng: toLng,
        );
      }
      
      state = AsyncValue.data(rides);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void clear() {
    state = const AsyncValue.data([]);
  }
}

// My Published Rides Provider
final myPublishedRidesProvider = FutureProvider<List<RideModel>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  return currentUser.maybeWhen(
    data: (user) async {
      if (user != null) {
        return await RideService.getMyPublishedRides(driverId: user.id);
      }
      return [];
    },
    orElse: () => [],
  );
});

// Publish Ride Provider
final publishRideProvider = StateNotifierProvider<PublishRideNotifier, AsyncValue<void>>((ref) {
  return PublishRideNotifier();
});

class PublishRideNotifier extends StateNotifier<AsyncValue<void>> {
  PublishRideNotifier() : super(const AsyncValue.data(null));

  Future<void> publish(RideModel ride) async {
    state = const AsyncValue.loading();
    try {
      await RideService.publishRide(
        driverId: ride.driverId,
        driverName: ride.driverName,
        fromLocation: ride.fromLocation,
        toLocation: ride.toLocation,
        fromLat: ride.fromLat,
        fromLng: ride.fromLng,
        toLat: ride.toLat,
        toLng: ride.toLng,
        departureDatetime: ride.departureDatetime,
        totalSeats: ride.totalSeats,
        pricePerSeat: ride.pricePerSeat,
        vehicleInfo: ride.vehicleInfo,
        vehicleType: ride.vehicleType,
        description: ride.description,
        routePoints: ride.routePointsJson?.map((p) => LatLng(p['lat'] as double, p['lng'] as double)).toList(),
        distanceKm: ride.distanceKm,
        durationMins: ride.durationMins,
        ruleNoSmoking: ride.ruleNoSmoking,
        ruleNoMusic: ride.ruleNoMusic,
        ruleNoHeavyLuggage: ride.ruleNoHeavyLuggage,
        ruleNoPets: ride.ruleNoPets,
        ruleNegotiation: ride.ruleNegotiation,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Ride Details Provider
final rideDetailsProvider = FutureProvider.family<RideModel?, String>((ref, rideId) async {
  return await RideService.getRideById(rideId: rideId);
});

// Nearby Rides Provider
final nearbyRidesProvider = FutureProvider<List<RideModel>>((ref) async {
  // TODO: Get current location from location provider
  // For now, return empty list
  return [];
});
