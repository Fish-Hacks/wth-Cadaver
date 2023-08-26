//
//  CommunicationService.swift
//  Cadaver
//
//  Created by Jia Chen Yee on 26/8/23.
//

import Foundation

struct Point: Codable {
    var x: Int
    var y: Int
}

struct CoordinateRecord: Codable {
    var top_left: Point
    var bottom_right: Point
}

struct CVRecord: Codable {
    var probability: Float16
    var coordinates: CoordinateRecord
}

struct CVResponse {
    var sceneDescription: String
    var contextCoordinate: CGRect?
}

class CommunicationService {
    
    let apiHost: String = "http://192.56.128.60:5000/cv"
    
    init() {}
    
    func sendImageForProcessing(imageData: Data) -> CVResponse{
        let requestID = UUID().uuidString
        let endpoint = URL(string: "\(apiHost)?uuid=\(requestID)")!
        var responseData: [String: [CVRecord]] = [:]
        var request = URLRequest(url: endpoint)
        
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.httpBody = imageData

        let session = URLSession.shared
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                print(error)
            }
            else if let data = data {
                let responseString = String(data: data, encoding: .utf8)!
                responseData = try! JSONDecoder().decode([String: [CVRecord]].self, from: Data(responseString.utf8))
            }
        }
        
        return processCVResponse(cvResponse: responseData)
    }
    
    func processCVResponse(cvResponse: [String: [CVRecord]]) -> CVResponse {
        
        let sizeThresold = 150000
        var itemsInView: [String: Int8] = [:]
        var contextCoodinates: CGRect? = nil
        
        for (objectName, objectHits) in cvResponse {
            itemsInView[objectName] = 0
            for objectHit in objectHits {
                let width = objectHit.coordinates.bottom_right.x - objectHit.coordinates.top_left.x
                let length = objectHit.coordinates.top_left.y - objectHit.coordinates.bottom_right.y
                
                if objectName == "laptop" || objectName == "tv" || objectName == "whiteboard" {
                    contextCoodinates = CGRect(x: objectHit.coordinates.top_left.x, y: objectHit.coordinates.top_left.y, width: width, height: length)
                }
                
                let area = width * length
                if area < sizeThresold {
                    continue
                }
                itemsInView[objectName]! += 1
            }
        }
        
        var sceneDescription: String = ""
        
        for (objectName, objectHitCount) in itemsInView {
            sceneDescription += "\(objectHitCount) \(objectName) "
        }
        
        sceneDescription = contextCoodinates != nil ? "\(sceneDescription)tap for insights": sceneDescription
        
        return CVResponse(sceneDescription: sceneDescription, contextCoordinate: contextCoodinates)
    }
}
