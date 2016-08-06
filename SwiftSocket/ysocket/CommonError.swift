//
//  CommonError.swift
//  SwiftSocket
//
//  Created by jieshao on 16/8/3.
//  Copyright © 2016年 swift. All rights reserved.
//  自定义一些异常
//

import Foundation

enum CommonError:ErrorType {
    case HttpError(errCode:Int,errMsg:String)
    
}