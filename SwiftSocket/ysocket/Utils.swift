//
//  Utils.swift
//  SwiftSocket
//
//  Created by jieshao on 16/8/5.
//  Copyright © 2016年 swift. All rights reserved.
//

import Foundation



extension String
{
    func trim() -> String
    {
        return self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }
}