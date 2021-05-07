//
//  ViewController.swift
//  buscadorMapas
//
//  Created by Jorge Luis Baltazar Perez on 04/05/21.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController,  UISearchBarDelegate, MKMapViewDelegate {
    
    var latitud: CLLocationDegrees?
    var longitud: CLLocationDegrees?
    var altitud: CLLocationDegrees?
    var distanciaKM: String?
    var place: String?
    
    @IBAction func distanciaBttn(_ sender: UIBarButtonItem) {
        let alerta = UIAlertController(title: "Distancia", message: "La distancia entre \(place ?? "") y tu ubicaciób es de: \(distanciaKM ?? "0") km", preferredStyle: .alert)
        
        let accionAceptar = UIAlertAction(title: "Aceptar", style: .default, handler: nil)
        
        alerta.addAction(accionAceptar)
        
        present(alerta, animated: true, completion: nil)
    }
    @IBAction func ubicacionBttn(_ sender: UIBarButtonItem) {
        
        let alerta = UIAlertController(title: "Ubicación", message: "Las coordenadas son: \(latitud ?? 0) \(longitud ?? 0) \(altitud ?? 0)", preferredStyle: .alert)
        
        let accionAceptar = UIAlertAction(title: "Aceptar", style: .default, handler: nil)
        
        alerta.addAction(accionAceptar)
        
        present(alerta, animated: true, completion: nil)
        
        let localizacion = CLLocationCoordinate2D(latitude: latitud!, longitude: longitud!)
        
        let spanMapa = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        
        let region  = MKCoordinateRegion(center: localizacion, span: spanMapa)
        
        mapaMK.setRegion(region, animated: true)
        mapaMK.showsUserLocation = true
        
    }
    @IBOutlet weak var mapaMK: MKMapView!
    @IBOutlet weak var buscadorSB: UISearchBar!
    
    var manager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buscadorSB.delegate = self
        mapaMK.delegate = self
        manager.delegate = self
        
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
        
        //mejor localizacion posible
        manager.desiredAccuracy = kCLLocationAccuracyBest
        
        //monitorea en todo momento la ubicación
        manager.startUpdatingLocation()
    }
    
    //Trazar la ruta
    
    func trazarRuta(coordenadasDestino: CLLocationCoordinate2D){
        guard let coordOrigen = manager.location?.coordinate else {
            return
        }
        let origen = CLLocation(latitude: coordOrigen.latitude, longitude: coordOrigen.longitude)
        let destino = CLLocation(latitude: coordenadasDestino.latitude, longitude: coordenadasDestino.longitude)
        
        print("DISTANCIA: \(origen.distance(from: destino))")
        
        distanciaKM = String(format: "%.2f", (origen.distance(from: destino))/1000)
    
        
        //crear un lugar de origen y destino
        let origenPlceMark = MKPlacemark(coordinate: coordOrigen)
        let destinoPlaceMark = MKPlacemark(coordinate: coordenadasDestino)
        
        //crear objeto en mapkit item
        let origenItem = MKMapItem(placemark: origenPlceMark)
        let destinoItem = MKMapItem(placemark: destinoPlaceMark)
        
        //solicitud de ruta
        let solicitudDestino = MKDirections.Request()
        solicitudDestino.source = origenItem
        solicitudDestino.destination = destinoItem
        
        //definir como se va a viajar
        solicitudDestino.transportType = .automobile
        solicitudDestino.requestsAlternateRoutes = true
        
        let direcciones = MKDirections(request: solicitudDestino)
        direcciones.calculate { (respuesta, error) in
            //variable segura para destapar la respuesta
            guard let respuestaSegura = respuesta else{
                if let error = error{
                    print("Error al calcular la ruta: \(error.localizedDescription)")
                }
                return
            }
            //si todo salio bien
            //print(respuestaSegura.routes.count)
            let ruta = respuestaSegura.routes[0]
            //Agregar al mapa una superposición (linea que aprece de la ruta)
            self.mapaMK.addOverlay(ruta.polyline)
            self.mapaMK.setVisibleMapRect(ruta.polyline.boundingMapRect, animated: true)
        }
    }
    
    //metodo de ayuda para poder poner la superposicion al mapa
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderizado = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderizado.strokeColor = .purple
        return renderizado
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("ubicación encontrada!")
        
        //metodo para ocultar el teclado
        buscadorSB.resignFirstResponder()
        
        let geocoder = CLGeocoder()
        
        //lugar buscado
        place = buscadorSB.text
        
        if let direccion = buscadorSB.text{
            geocoder.geocodeAddressString(direccion) { (lugares: [CLPlacemark]?, error: Error?) in
                
                //crear el destino
                guard let destinoRuta = lugares?.first?.location else{
                    return
                }
                
                if error == nil{
                    let lugar = lugares?.first
                    let anotacion = MKPointAnnotation()
                    anotacion.coordinate = (lugar?.location?.coordinate)!
                    anotacion.title = direccion
                    
                    let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    let region = MKCoordinateRegion(center: anotacion.coordinate, span: span)
                    
                    self.mapaMK.setRegion(region, animated: true)
                    self.mapaMK.addAnnotation(anotacion)
                    self.mapaMK.selectAnnotation(anotacion, animated: true)
                    
                    //mandar llamar trazar ruta
                    self.trazarRuta(coordenadasDestino: destinoRuta.coordinate)
                    
                }else{
                    print("error: \(error?.localizedDescription)")
                }
            }
        }
    }

}

extension ViewController: CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        print("Número de ubicaciones: \(locations.count)")
        
        guard let ubicacion = locations.first else{
            return
        }
        
        latitud = ubicacion.coordinate.latitude
        longitud = ubicacion.coordinate.longitude
        altitud = ubicacion.altitude
        
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error: \(error.localizedDescription)")
    }
    
}

