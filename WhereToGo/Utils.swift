//
//  Utils.swift
//  Virtual Tourist
//
//  Created by Konstantin Bondarchuk on 18.09.17.
//  Copyright © 2017 Konstantin Bondarchuk. All rights reserved.
//

import Foundation

struct _Debug {
    static var bkLogExceptions: Set = ["KGAPI", "Movie", "MovieShowing", "Place"]
    static var lastName = ""
}


public func BKLog(_ item: Any? = nil, prefix: Character = " ", function: String = #function, file: String? = #file )
{
    // Get File name
    var fileName:String = ""
    if file != nil {
        fileName = URL(fileURLWithPath: file!).deletingPathExtension().lastPathComponent
    }

    guard !_Debug.bkLogExceptions.contains(fileName) else {
        return
    }
    
    if _Debug.lastName != fileName {
        print("")
        _Debug.lastName = fileName
    }
    
    
    let prefixString: String
    if prefix != " " {
        prefixString = "[\(prefix)]"
    }else{
        prefixString = "   "
    }
    
    
    if let item = item {
        print(prefixString, " [", fileName, "] [.", function, "] ", item, separator: "")
    }else{
        print(prefixString, " [", fileName, "] [.", function, "] ", separator: "")
    }
    
}



extension String {
    func firstCharacterUpperCase() -> String {
        if let firstCharacter = characters.first {
            return replacingCharacters(in: startIndex..<index(after: startIndex), with: String(firstCharacter).uppercased())
        }
        return ""
    }
}

