import Flutter
import MapKit
import UIKit

public class NativeAddressAutocompletePlugin: NSObject, FlutterPlugin, MKLocalSearchCompleterDelegate {
  private var completer: MKLocalSearchCompleter?
  private var pendingResult: FlutterResult?
  private var pendingLimit: Int = 5
  private var recentCompletions: [String: MKLocalSearchCompletion] = [:]

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "native_address_autocomplete", binaryMessenger: registrar.messenger())
    let instance = NativeAddressAutocompletePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isAvailable":
      result(true)
    case "suggestAddresses":
      suggestAddresses(call.arguments, result: result)
    case "resolveAddress":
      resolveAddress(call.arguments, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func suggestAddresses(_ arguments: Any?, result: @escaping FlutterResult) {
    guard
      let args = arguments as? [String: Any],
      let query = args["query"] as? String
    else {
      result(FlutterError(code: "invalid_arguments", message: "Missing query.", details: nil))
      return
    }

    let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedQuery.isEmpty else {
      result([])
      return
    }

    pendingResult?(FlutterError(code: "cancelled", message: "A newer autocomplete request was started.", details: nil))

    let limit = args["limit"] as? Int ?? 5
    pendingLimit = max(1, min(limit, 20))
    pendingResult = result

    let searchCompleter = MKLocalSearchCompleter()
    searchCompleter.delegate = self
    searchCompleter.resultTypes = resultTypes(from: args["resultTypes"] as? [String])

    if
      let latitude = args["latitude"] as? Double,
      let longitude = args["longitude"] as? Double
    {
      let radiusMeters = args["radiusMeters"] as? Double ?? 50_000
      let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
      searchCompleter.region = MKCoordinateRegion(
        center: center,
        latitudinalMeters: radiusMeters * 2,
        longitudinalMeters: radiusMeters * 2
      )
    }

    completer = searchCompleter
    searchCompleter.queryFragment = trimmedQuery
  }

  private func resolveAddress(_ arguments: Any?, result: @escaping FlutterResult) {
    guard let args = arguments as? [String: Any] else {
      result(FlutterError(code: "invalid_arguments", message: "Missing suggestion.", details: nil))
      return
    }

    let request: MKLocalSearch.Request
    if
      let id = args["id"] as? String,
      let completion = recentCompletions[id]
    {
      request = MKLocalSearch.Request(completion: completion)
    } else {
      request = MKLocalSearch.Request()
      request.naturalLanguageQuery =
        args["fullText"] as? String ??
        args["primaryText"] as? String
    }

    if
      let latitude = args["latitude"] as? Double,
      let longitude = args["longitude"] as? Double
    {
      let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
      request.region = MKCoordinateRegion(
        center: center,
        latitudinalMeters: 10_000,
        longitudinalMeters: 10_000
      )
    }

    MKLocalSearch(request: request).start { response, error in
      if let error = error {
        result(FlutterError(code: "resolve_failed", message: error.localizedDescription, details: nil))
        return
      }

      guard let mapItem = response?.mapItems.first else {
        result(nil)
        return
      }

      result(self.mapItemToMap(mapItem))
    }
  }

  public func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
    guard completer === self.completer else {
      return
    }

    var nextCompletions: [String: MKLocalSearchCompletion] = [:]
    let suggestions = completer.results.prefix(pendingLimit).enumerated().map { index, completion in
      let id = suggestionId(completion, index: index)
      nextCompletions[id] = completion
      let fullText = [completion.title, completion.subtitle]
        .filter { !$0.isEmpty }
        .joined(separator: ", ")

      return [
        "id": id,
        "primaryText": completion.title,
        "secondaryText": completion.subtitle.isEmpty ? nil : completion.subtitle,
        "fullText": fullText
      ] as [String: Any?]
    }

    recentCompletions = nextCompletions
    pendingResult?(Array(suggestions))
    pendingResult = nil
    self.completer = nil
  }

  public func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
    guard completer === self.completer else {
      return
    }

    pendingResult?(FlutterError(code: "autocomplete_failed", message: error.localizedDescription, details: nil))
    pendingResult = nil
    self.completer = nil
  }

  private func resultTypes(from values: [String]?) -> MKLocalSearchCompleter.ResultType {
    let requested = Set(values ?? ["address", "pointOfInterest"])
    var resultTypes = MKLocalSearchCompleter.ResultType()

    if requested.contains("address") {
      resultTypes.insert(.address)
    }

    if requested.contains("pointOfInterest") {
      resultTypes.insert(.pointOfInterest)
    }

    if resultTypes.isEmpty {
      resultTypes.insert(.address)
    }

    return resultTypes
  }

  private func suggestionId(_ completion: MKLocalSearchCompletion, index: Int) -> String {
    return "\(completion.title)|\(completion.subtitle)|\(index)"
  }

  private func mapItemToMap(_ mapItem: MKMapItem) -> [String: Any?] {
    let placemark = mapItem.placemark
    let street = [placemark.subThoroughfare, placemark.thoroughfare]
      .compactMap { $0 }
      .joined(separator: " ")
    let primaryText = mapItem.name ?? street
    let fullText = placemark.title ?? [
      street.isEmpty ? nil : street,
      placemark.locality,
      placemark.administrativeArea,
      placemark.postalCode,
      placemark.country
    ].compactMap { $0 }.joined(separator: ", ")
    let secondaryText = [
      placemark.locality,
      placemark.administrativeArea,
      placemark.postalCode,
      placemark.country
    ].compactMap { $0 }.joined(separator: ", ")

    return [
      "primaryText": primaryText.isEmpty ? nil : primaryText,
      "secondaryText": secondaryText.isEmpty ? nil : secondaryText,
      "fullText": fullText,
      "streetNumber": placemark.subThoroughfare,
      "street": placemark.thoroughfare,
      "city": placemark.locality,
      "state": placemark.administrativeArea,
      "postalCode": placemark.postalCode,
      "country": placemark.country,
      "countryCode": placemark.isoCountryCode,
      "latitude": placemark.coordinate.latitude,
      "longitude": placemark.coordinate.longitude
    ]
  }
}
