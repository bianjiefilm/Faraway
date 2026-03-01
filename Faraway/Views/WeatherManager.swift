import Foundation
import CoreLocation
import WeatherKit
import Combine

@MainActor
class WeatherManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = WeatherManager()

    @Published var weatherMessage: String?
    @Published var isLocationAuthorized: Bool = false

    private let locationManager = CLLocationManager()
    private let weatherService = WeatherService.shared
    
    // We only fetch weather occasionally to preserve battery and API limits
    private var lastFetchDate: Date?

    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer // Coarse location is enough for weather

        // Check initial authorization state
        updateAuthorizationStatus(locationManager.authorizationStatus)
    }

    /// Called when the user toggles the switch in Settings
    func requestPermissionAndFetch() {
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if locationManager.authorizationStatus == .authorized || locationManager.authorizationStatus == .authorizedAlways {
            requestLocation()
        }
    }

    /// Stops tracking and clears message when user disables the feature
    func disableWeather() {
        locationManager.stopUpdatingLocation()
        weatherMessage = nil
    }

    private func requestLocation() {
        locationManager.requestLocation()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        updateAuthorizationStatus(manager.authorizationStatus)
    }

    private func updateAuthorizationStatus(_ status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorized:
            isLocationAuthorized = true
            // Immediately request location if authorized to kick off fetch
            if UserDefaults.standard.bool(forKey: "isWeatherEnabled") {
                requestLocation()
            }
        case .denied, .restricted:
            isLocationAuthorized = false
            DispatchQueue.main.async {
                self.weatherMessage = nil
            }
        case .notDetermined:
            isLocationAuthorized = false
        @unknown default:
            isLocationAuthorized = false
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }

        // Throttle fetches: Only fetch if we haven't fetched in the last 2 hours
        if let last = lastFetchDate, Date().timeIntervalSince(last) < 7200 {
            return
        }

        fetchWeatherForLocation(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("WeatherManager: Location fetch failed: \(error.localizedDescription)")
    }

    // MARK: - Weather Fetching

    private func fetchWeatherForLocation(_ location: CLLocation) {
        Task {
            do {
                let weather = try await weatherService.weather(for: location)
                self.lastFetchDate = Date()
                
                let message = processWeatherMessage(current: weather.currentWeather, dailyForecast: weather.dailyForecast)
                
                DispatchQueue.main.async {
                    self.weatherMessage = message
                }
                
            } catch {
                print("WeatherManager: Failed to fetch weather: \(error.localizedDescription)")
            }
        }
    }

    /// Processes the raw Weather data and generates contextual copy
    private func processWeatherMessage(current: CurrentWeather, dailyForecast: Forecast<DayWeather>) -> String? {
        // 1. Check for rain today
        let rainyConditions: [WeatherCondition] = [
            .drizzle, .freezingDrizzle, .rain, .heavyRain, .freezingRain,
            .sleet, .hail, .thunderstorms, .tropicalStorm, .hurricane
        ]
        
        if rainyConditions.contains(current.condition) {
            return "下雨的日子，适合慢一点"
        }
        
        // 2. Check for clear sky (occasionally returning)
        let clearConditions: [WeatherCondition] = [.clear, .mostlyClear, .sunShowers]
        
        if clearConditions.contains(current.condition) {
            // Give it a 30% chance to show up so it doesn't get repetitive
            if Int.random(in: 1...100) <= 30 {
                return "今天可以去晒着阳光充充电 ☀️"
            }
            return nil
        }
        
        // 3. Check for 3 consecutive cloudy days
        let cloudyConditions: [WeatherCondition] = [
            .cloudy, .mostlyCloudy, .foggy, .haze, .smoky, .breezy, .windy
        ]
        
        let todayAndNextTwoDays = dailyForecast.prefix(3)
        if todayAndNextTwoDays.count == 3 {
            let areAllCloudy = todayAndNextTwoDays.allSatisfy { dayWeather in
                cloudyConditions.contains(dayWeather.condition)
            }
            if areAllCloudy {
                return "🌻阳光会回来的"
            }
        }

        return nil
    }
}
