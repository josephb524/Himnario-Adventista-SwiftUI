//
//  DataAPI.swift
//  Himnario Adventista
//
//  Created by Jose Pimentel on 4/30/21.
//  Copyright © 2021 Jose Pimentel. All rights reserved.
//

import Foundation

struct DataAPI: Decodable {
    
    //let data: [String]
    let data: [Data1]
}

struct Data1: Decodable {

    let duration: Int
    let title: String
    let id: String
    
}
