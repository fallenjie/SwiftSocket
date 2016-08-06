//
//  HttpParser.swift
//  SwiftSocket
//
//  Created by jieshao on 16/8/3.
//  Copyright © 2016年 swift. All rights reserved.
//  解析普通的http头部数据
//

import Foundation

public class HttpParser{
    
    
    
    let  tag:String = "HttpRecvPacket"
    let  MAX_GC_LINE = 10
    let  FIELD_CONTENT_LENGTH:String = "Content-Length"
    let  FILED_CONTENT_LENGTH_1:String = "Content-length"
    let  FILED_CONTENT_LENGTH_2:String = "content-length"
    let  STATUSLINE_PATTERN:String = "\\A(\\S+) +(\\d+) +(.*)"
    let  HEADLINE_PATTERN:String = "(.*) *: *(.*)";
    
    let cr = UInt8(ascii: "\r")
    let lf = UInt8(ascii: "\n")
    
    
    var  httpVersion:String = ""
    var  statusCode:Int = 0
    var  reasonPhrase:String = ""
    var  headFields = Dictionary<String, String>()
    var  contentLength:Int32 = 0
    var  responseBody:[UInt8] = []
    var  functionName:String = ""
    
    
    public func read(fd fd:Int32) throws{
        do{
            try readHttpStatusLine(fd: fd)
            try readHttpHeader(fd: fd)
            try readHttpBody(fd: fd)
        }catch CommonError.HttpError(let errCode, let errMsg){
            print("errCode=\(errCode) errMsg=\(errMsg)")
            throw CommonError.HttpError(errCode: errCode, errMsg: errMsg)
        }
        
    }
    
    public func getStatusCode()->Int {
        return statusCode;
    }
    
    
    private func readHttpStatusLine(fd fd:Int32) throws->Int{
        var ret = 0
        var count = 0
        
        repeat {
            if let statusLine = readline(fd: fd){
                print("HTTPRECV||statusLine:\(statusLine)")
                if (statusLine.isEmpty) {
                    throw CommonError.HttpError(errCode: ResultCode.HTTP_STATUS_LINE_PARSE_ERR_EMPTY, errMsg: "The server failed to respond with a valid HTTP response,statusLine Empty")
                }
                if  (statusLine.characters.count > 0) {
                    ret += statusLine.utf8.count; // TODO 这里的获取字节长度可能有问题，需要再测试
                }
                // 如果是正常的http头
                if startsWithHTTP(str: statusLine) {
                    //  解析出httpVersion/statusCode/reasonPhrase
                    do{
                        let re = try NSRegularExpression(pattern: STATUSLINE_PATTERN, options: NSRegularExpressionOptions.CaseInsensitive)
                        
                        let matches = re.matchesInString(statusLine, options: NSMatchingOptions(rawValue: 0), range: NSRange(location: 0, length: statusLine.utf16.count))
                        
                        //                        print("number of matches: \(matches.count)")
                        if matches.count > 0 {
                            //                            print("range size="+String(matches[0].numberOfRanges))
                            if matches[0].numberOfRanges > 3{
                                httpVersion = (statusLine as NSString).substringWithRange(matches[0].rangeAtIndex(1))
                                statusCode = Int((statusLine as NSString).substringWithRange(matches[0].rangeAtIndex(2)))!
                                reasonPhrase = (statusLine as NSString).substringWithRange(matches[0].rangeAtIndex(3))
                            }
                            break
                            
                        }
                        
                    }catch{
                        print(error)
                    }
                    
                }else if statusLine == ""{
                    throw CommonError.HttpError(errCode: ResultCode.HTTP_STATUS_LINE_PARSE_ERR, errMsg: "The server  failed to respond with a valid HTTP response, statusLine null")
                }else if count > MAX_GC_LINE{
                    throw CommonError.HttpError(errCode: ResultCode.HTTP_STATUS_LINE_PARSE_ERR, errMsg: "The server  failed to respond with a valid HTTP response, count > \(MAX_GC_LINE),statusLine:\(statusLine)")
                }
                
            }else{
                throw CommonError.HttpError(errCode: ResultCode.HTTP_STATUS_LINE_PARSE_ERR, errMsg: "The server  failed to respond with a valid HTTP response, statusLine null")
            }
            
            count += 1
            
        }while true
        
        return 0;
    }
    
    
    private func readHttpHeader(fd fd:Int32) throws ->Int{
        var ret = 0
        headFields.removeAll()
        while true {
            
            if let headLine = readline(fd: fd){
//                print("headline isEmpty?\(headLine.isEmpty) count=\(headLine.characters.count)")
                if headLine.trim().isEmpty {
                    break
                }
                ret += headLine.utf8.count
//                print("headline:"+headLine)
                //以下照样是分组匹配出header里面的key/value
                do{
                    let re = try NSRegularExpression(pattern: HEADLINE_PATTERN, options: NSRegularExpressionOptions.CaseInsensitive)
                    
                    let matches = re.matchesInString(headLine, options: NSMatchingOptions(rawValue: 0), range: NSRange(location: 0, length: headLine.utf16.count))
                    
                    //                    print("number of matches: \(matches.count)")
                    if matches.count > 0 {
                        //                        print("range size="+String(matches[0].numberOfRanges))
                        if matches[0].numberOfRanges > 2{
                            let key = (headLine as NSString).substringWithRange(matches[0].rangeAtIndex(1))
                            let value = (headLine as NSString).substringWithRange(matches[0].rangeAtIndex(2))
                            headFields.updateValue(value, forKey: key)
                            print("HTTPRECV||headFields,key=\(key),value=\(value)")
                        }
                    }
                    
                }catch{
                    print(error)
                }
                
            }
            
        }
        if  headFields[FIELD_CONTENT_LENGTH] != nil {
            contentLength = Int32(headFields[FIELD_CONTENT_LENGTH]!)!
        }else if headFields[FILED_CONTENT_LENGTH_1] != nil{
            contentLength = Int32(headFields[FILED_CONTENT_LENGTH_1]!)!
        }else if headFields[FILED_CONTENT_LENGTH_2] != nil{
            contentLength = Int32(headFields[FILED_CONTENT_LENGTH_2]!)!
        }else{
            var  code = 0
            if statusCode == ResultCode.HTTP_OK {
                code = ResultCode.HTTP_CONTENT_LENGTH_PARSE_ERR
            }else{
                code = statusCode
            }
            
            
            throw CommonError.HttpError(errCode: code, errMsg: "The server  failed to respond with a correct Content-Length")
        }
        
        return ret
    }
    
    
    private func readHttpBody(fd fd:Int32) throws -> Int{
        if let tempFd:Int32 = fd{
            if contentLength > INT32_MAX {
                throw CommonError.HttpError(errCode: ResultCode.HTTP_CONTENT_LENGTH_PARSE_ERR, errMsg: "Content too large to be buffered")
            }
            if contentLength == -1 {
                throw CommonError.HttpError(errCode: ResultCode.HTTP_CONTENT_LENGTH_PARSE_ERR, errMsg: "Content length unknow")
            }
            
//            responseBody = [UInt8](count:Int(contentLength),repeatedValue:0x0)
            var bodyCount:Int32 = 0
            var buffer:[UInt8] = [UInt8](count:1024,repeatedValue:0x0)
            while bodyCount < contentLength { // 内容还没读取完成，就要不断的读
                let size = c_ytcpsocket_pull(tempFd, buff: &buffer, len: Int32(buffer.count), timeout: 0)
                bodyCount += size
//                print("size=\(size)")
                responseBody += Array(buffer[0..<Int(size)])
                
            }
            
//            print("body length=\(bodyCount) \r\n result=\(String(bytes:responseBody,encoding:NSUTF8StringEncoding))")
            
        }
        return Int(contentLength)
    }
    
    
    
    // 判断是否是http协议头，处理掉可能存在的空白符号
    private func  startsWithHTTP(str s:String)->Bool {
        if !s.isEmpty {
            var at = 0
            let characters = Array(s.utf16)
            while isWhitespace(codePoint: characters[at]) {
                at += 1
            }
            //            print("at=\(at) count=\(characters.count)")
            if characters.count > (at+4) {
                let range = s.startIndex.advancedBy(at)..<s.startIndex.advancedBy(at+4)
                //                print("range=\(s.substringWithRange(range))")
                return ("HTTP" == s.substringWithRange(range))
            }
            
        }
        return false
    }
    
    
    
    private func isWhitespace(codePoint codePoint:UInt16)->Bool{
        //
        //        NSCharacterSet.whitespaceCharacterSet()
        // Any ASCII whitespace character?
        if ((codePoint >= 0x1c && codePoint <= 0x20) || (codePoint >= 0x09 && codePoint <= 0x0d)) {
            return true;
        }
        if (codePoint < 0x1000) {
            return false;
        }
        // OGHAM SPACE MARK or MONGOLIAN VOWEL SEPARATOR?
        if (codePoint == 0x1680 || codePoint == 0x180e) {
            return true;
        }
        if (codePoint < 0x2000) {
            return false;
        }
        // Exclude General Punctuation's non-breaking spaces (which includes FIGURE SPACE).
        if (codePoint == 0x2007 || codePoint == 0x202f) {
            return false;
        }
        if (codePoint <= 0xffff) {
            // Other whitespace from General Punctuation...
            return codePoint <= 0x200a || codePoint == 0x2028 || codePoint == 0x2029 || codePoint == 0x205f ||
                codePoint == 0x3000; // ...or CJK Symbols and Punctuation?
        }
        //non-BMP code points not check, fix me
        return false;
        
    }
    
    
    /**读取一行内容*/
    private func readline(fd fd:Int32)->String?{
        if let rawdata:[UInt8] = readRawLine(fd: fd){
            let len = rawdata.count;
            var offset = 0;
            
            if (len > 0) {
                
                if (rawdata[len - 1] == lf) {
                    offset += 1;
                    if (len > 1) {
                        if (rawdata[len - 2] == cr) {
                            offset += 1;
                        }
                    }
                }
            }
//            print("offset=\(offset)")
            let data:[UInt8] = Array(rawdata[0..<Int(len-offset)])
            return String(bytes: data, encoding: NSUTF8StringEncoding)
        }
        return nil
    }
    
    /**读取一行内容*/
    private func readRawLine(fd fd:Int32)->[UInt8]?{
        
        if let tempfd:Int32 = fd{
            var ch:[UInt8] = [UInt8](count:1,repeatedValue:0x0) //
            var buffer:[UInt8] = []
            var count = 0;
            while (c_ytcpsocket_pull(tempfd, buff: &ch, len: Int32(1), timeout: 0) > 0) {
                buffer.append(ch[0])
                
                if ch[0] == lf {
                    break
                }
                count += 1
            }
            if count == 0 {
                return nil
            }
            
            let result = buffer[0...Int(count)]
            //             print("count=\(count) raw=\(String(bytes:result,encoding:NSUTF8StringEncoding)!)kkkk")
            return Array(result)
            
        }
        
        return nil
    }
    
    
    
}
