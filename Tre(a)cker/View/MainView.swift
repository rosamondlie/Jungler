//
//  MainView.swift
//  Tre(a)cker
//
//  Created by Rosamond Patricia Selamat Lie on 01/05/26.
//

import SwiftUI
import MapKit

struct MainView: View {
    @State private var mapPosition: MapCameraPosition = .region(MKCoordinateRegion(center: .init(latitude: -6.292363, longitude: 106.644227), latitudinalMeters: 1300, longitudinalMeters: 1300))
    
    @State private var locationManager = CLLocationManager()
    
    @State private var locations: [Location] = []
    
//    @State private var route: MKRoute?
    @State private var straightLineCoordinates: [CLLocationCoordinate2D] = []
    
    var body: some View {
        ZStack {
            Map(position: $mapPosition) {
                if !locations.isEmpty {
                    ForEach(locations) { location in
                         Annotation(location.name, coordinate: location.coordinate, anchor: .center){
                            Image(systemName: "flag")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundStyle(.white)
                                .frame(width: 20, height: 20)
                                .padding(7)
                                .background(.pink.gradient, in: .circle)
                                .contextMenu {
                                    Button("Get Direction"){
                                        getDirections(to: location)
                                    }
                                }
                        }
                    }
                }
                
                UserAnnotation()
                
//                if let route {
//                    MapPolyline(route)
//                        .stroke(Color.blue, lineWidth: 4)
//                }
                if !straightLineCoordinates.isEmpty {
                    MapPolyline(coordinates: straightLineCoordinates)
                        .stroke(.blue, lineWidth: 4)
                }
                
            }
            .mapControls{
                MapUserLocationButton()
                MapCompass()
                MapPitchToggle()
                MapScaleView()
            }
            .onAppear{
                locationManager.requestWhenInUseAuthorization()
                if let coordinate = locationManager.location?.coordinate {
                    mapPosition = .region(MKCoordinateRegion(center: coordinate, latitudinalMeters: 1300, longitudinalMeters: 1300))
                }
            }
            Button(action: createAnnotation) {
                    Label("Pin Location", systemImage: "plus")
                }
            .buttonStyle(.borderedProminent)
            .position(x: 100, y: 700)
            
        }
    }
    
    func createAnnotation(){
        if let coordinate = locationManager.location?.coordinate {
            print(coordinate)
            let newLocation = Location(name: "PIN" + String(locations.count), coordinate: coordinate)
            print(newLocation.name)
            locations.append(newLocation)
        }
    
    }
    
    func getUserLocation() async -> CLLocationCoordinate2D? {
        let updates = CLLocationUpdate.liveUpdates()
        
        do {
            let update = try await updates.first { $0.location?.coordinate != nil }
            
            return update?.location?.coordinate
        } catch {
            print("Cannot get user location")
            return nil
        }
    }
    
    //kalau sesuai tutor yt buat dapet belokannya dan jalan terdekat
//    func getDirections(to destination: CLLocationCoordinate2D) {
//        Task {
//            guard let userLocation = await getUserLocation() else { return }
//            
//            let request = MKDirections.Request()
//            request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation))
//            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
//            request.transportType = .walking
//            
//            do {
//                let directions = try await MKDirections(request: request).calculate()
//                route = directions.routes.first
//                }
//            catch {
//                print("Error getting directions: \(error)")
//            }
//            }
//        }
    
    // kalau mau get direction dari cur loc ke SATU titik terpilih
//    func getDirections(to destination: CLLocationCoordinate2D) {
//        Task {
//            for try await update in CLLocationUpdate.liveUpdates() {
//                guard let userCoordinate = update.location?.coordinate else { continue }
//
//                await MainActor.run {
//                    straightLineCoordinates = [
//                        userCoordinate,
//                        destination
//                    ]
//                }
//            }
//        }
//    }
    
    func getDirections(to destination: Location) {
        Task {
            for try await update in CLLocationUpdate.liveUpdates() {

                guard let userCoordinate = update.location?.coordinate else { continue }

                await MainActor.run {

                    let remainingPins = locations
                        .filter { $0.id != destination.id }
                        .sorted { $0.timestamp > $1.timestamp }

                    var routeCoordinates: [CLLocationCoordinate2D] = []

                    routeCoordinates.append(userCoordinate)

                    for pin in remainingPins {

                        if !isNear(userCoordinate, pin.coordinate) {
                            routeCoordinates.append(pin.coordinate)
                        }
                    }

                    routeCoordinates.append(destination.coordinate)

                    straightLineCoordinates = routeCoordinates
                }
            }
        }
    }
    
    func isNear(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Bool {
        let loc1 = CLLocation(latitude: a.latitude, longitude: a.longitude)
        let loc2 = CLLocation(latitude: b.latitude, longitude: b.longitude)

        return loc1.distance(from: loc2) < 15 // mau hilang garisnya jika sudah mendekati berapa meteer
    }
        
    
}

#Preview {
    MainView()
}

