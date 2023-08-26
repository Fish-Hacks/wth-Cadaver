//
//  CommunicationService.swift
//  Cadaver
//
//  Created by Jia Chen Yee on 26/8/23.
//

import Foundation

struct CVPayload: Codable {
    var image: String
    var uuid: String
}

struct CVRecord: Codable {
    var probability: Float16
    var coordinates: [Int8]
}


class CommunicationService {
    
    var endpoint = URL(string: "192.56.128.60:5000")!
    
    init() {
    }
    
    func sendImageForProcessing(imageData: Data) -> [String: [CVRecord]]{
        var responseData: [String: [CVRecord]] = [:]
        let imageBase64 = imageData.base64EncodedString()
        var request = URLRequest(url: endpoint)
        let cvPayload = CVPayload(image: imageBase64, uuid: UUID().uuidString)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try! JSONEncoder().encode(cvPayload)

        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print(error)
            }
            else if let data = data {
                let responseString = String(data: data, encoding: .utf8)!
                let responseData = try! JSONDecoder().decode([String: [CVRecord]].self, from: Data(responseString.utf8))
            }
        }

        return responseData
    }
}
