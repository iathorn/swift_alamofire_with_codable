//
//  ViewController.swift
//  AlamofireDecoderPrac
//
//  Created by 최동호 on 2018. 3. 7..
//  Copyright © 2018년 최동호. All rights reserved.
//

import UIKit
import Alamofire
import CoreLocation

struct Sky: Codable {
    let code: String
    let name: String
}


struct Temperature: Codable {
    let tc: String
    let tmax: String
    let tmin: String
}


struct Minutely: Codable {
    let minutely: [MinutelyArray]
}


struct MinutelyArray: Codable {
    let sky: Sky
    let temperature: Temperature
    
}

struct WeatherSummary: Codable {
    let weather: Minutely
}

//  ForecastSummary

//struct FcstSky: Codable {
//    var codeValue: String
//
//    init?(codeValue: String) {
//        var hour = 4
//        while hour <= 64 {
//            defer {
//                hour += 3
//            }
//             self.init(codeValue: "code\(hour)hour")
//             self.codeValue = codeValue
//        }
//
//    }
//}

    
//    var code4hour: String
//    var code7hour: String
//    var code10hour: String
//
//    enum CodingKeys: String, CodingKey {
//
//        case code4hour
//        case code7hour
//        case code10hour
//    }
//
//    init (from decoder :Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        code4hour = try container.decode(String.self, forKey: .code4hour)
//        code7hour = try container.decode(String.self, forKey: .code7hour)
//        code10hour = try container.decode(String.self, forKey: .code10hour)
//    }
//}

struct Fcst3Hour: Codable {
    let sky: [String: String]
    let temperature: [String: String]
}

struct Forecast3DaysArray: Codable {
    let fcst3hour: Fcst3Hour
}

struct Forecast3Days: Codable {
    let forecast3days: [Forecast3DaysArray]
}


struct ForecastSummary: Codable {
    let weather: Forecast3Days
}


class ViewController: UIViewController {

    
    lazy var manager: CLLocationManager = {
        let m = CLLocationManager()
        m.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        m.delegate = self
        return m
    }()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let status = CLLocationManager.authorizationStatus()
        
        
        
        switch status {
        case .authorizedWhenInUse:
            updateLocation()
        case .notDetermined:
            self.manager.requestWhenInUseAuthorization()
        default:
            let alert = UIAlertController(title: "권한 요청", message: "위치 권한이 필요합니다", preferredStyle: UIAlertControllerStyle.alert)
            
            alert.addAction(UIAlertAction(title: "확인", style: UIAlertActionStyle.default, handler: { (action) in
                guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                    return
                }
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
                }
            }))
            self.present(alert, animated: true, completion: nil)
            
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    func fetchForecast(with coordinate: CLLocationCoordinate2D) {
        let urlStr = "https://api2.sktelecom.com/weather/forecast/3days?version=1&lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&appKey=appKey"
        
        guard let url = URL(string: urlStr) else {
            return
        }
        
        Alamofire.request(url).responseData { (response) in
            if response.result.isSuccess {
                if let data = response.value {
                    let decoder = JSONDecoder()
                    
                    do {
                        let jsonResult = try decoder.decode(ForecastSummary.self, from: data)

                        let result = jsonResult.weather.forecast3days
                        let skyResult = result[0].fcst3hour.sky
                        let tempResult = result[0].fcst3hour.temperature
                        
                        var hour = 4
                        while hour <= 64 {
                            defer {
                                hour += 3
                            }
                            
                            guard let name = skyResult["name\(hour)hour"], name.count > 0 else {
                                return
                            }
//                            print(name)
                            
                            guard let code = skyResult["code\(hour)hour"], code.count > 0 else {
                                return
                            }
//                            print(code)
                            
                            guard let temp = tempResult["temp\(hour)hour"], temp.count > 0 else {
                                return
                            }
//                            print(temp)
                            
                            
                        }

                    } catch {
                        print(error)
                    }
                }
            } else {
                fatalError()
            }
        }
        
    }
    
    
    func fetchSummary(with coordinate: CLLocationCoordinate2D) {
        let urlStr = "https://api2.sktelecom.com/weather/current/minutely?lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&appKey=appKey"
        
        guard let url = URL(string: urlStr) else {
            return
        }
        
        Alamofire.request(url).responseData { (response) in
            if response.result.isSuccess {
                if let data = response.value {
                    let decoder = JSONDecoder()
                    do {
                    let jsonResult = try decoder.decode(WeatherSummary.self, from: data)
                    let result = jsonResult.weather.minutely
                        let skyCode = result[0].sky.code
                        let skyName = result[0].sky.name
                        let currentTemp = result[0].temperature.tc
                        let maxTemp = result[0].temperature.tmax
                        let minTemp = result[0].temperature.tmin
                        print(skyCode)
                        print(skyName)
                        print(currentTemp)
                        print(maxTemp)
                        print(minTemp)
//                    dump(jsonResult)
                    } catch {
                        print(error)
                    }
                }
            } else {
                fatalError()
            }
        }
    }
   


}


extension ViewController: CLLocationManagerDelegate {
    func updateLocation() {
        self.manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let current = locations.last {
            self.fetchSummary(with: current.coordinate)
            self.fetchForecast(with: current.coordinate)
            let geoCoder = CLGeocoder()
            
            geoCoder.reverseGeocodeLocation(current, completionHandler: { (list, error) in
                if let error = error {
                    fatalError()
                }
                if let first = list?.first {
                    if let gu = first.locality, let dong = first.subLocality {
                        print("\(gu) \(dong)")
                    } else {
                        print("name: \(first.name)")
                    }
                }
            })
        }
        self.manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse:
            updateLocation()
        default:
            let alert = UIAlertController(title: "권한 요청", message: "위치 권한이 필요합니다", preferredStyle: UIAlertControllerStyle.alert)
            
            alert.addAction(UIAlertAction(title: "확인", style: UIAlertActionStyle.default, handler: { (action) in
                guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                    return
                }
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
                }
            }))
            self.present(alert, animated: true, completion: nil)
            
        }
    }
}
