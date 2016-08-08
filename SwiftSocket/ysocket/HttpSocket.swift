//
//  HttpSocket.swift
//  SwiftSocket
//
//  Created by jieshao on 16/8/1.
//  Copyright © 2016年 swift. All rights reserved.
//

import Foundation

@_silgen_name("ytcpsocket_connect") func c_yhttpsocket_connect(host:UnsafePointer<Int8>,port:Int32,timeout:Int32) -> Int32
@_silgen_name("ytcpsocket_close") func c_yhttpsocket_close(fd:Int32) -> Int32
@_silgen_name("ytcpsocket_send") func c_yhttpsocket_send(fd:Int32,buff:UnsafePointer<UInt8>,len:Int32) -> Int32
@_silgen_name("ytcpsocket_pull") func c_yhttpsocket_pull(fd:Int32,buff:UnsafePointer<UInt8>,len:Int32,timeout:Int32) -> Int32
@_silgen_name("ytcpsocket_listen") func c_yhttpsocket_listen(addr:UnsafePointer<Int8>,port:Int32)->Int32
@_silgen_name("ytcpsocket_accept") func c_yhttpsocket_accept(onsocketfd:Int32,ip:UnsafePointer<Int8>,port:UnsafePointer<Int32>) -> Int32

public class HttpClient:YSocket{
    /*
     * connect to server
     * return success or fail with message & result
     */
    public func connect(timeout t:Int) throws{
        
        let time1 = NSDate().timeIntervalSince1970
        print("time1=\( time1)")
        
        let rs:Int32=c_yhttpsocket_connect(self.addr, port: Int32(self.port), timeout: Int32(t))
        let time2 = NSDate().timeIntervalSince1970
        print("time2=\( time2)")
        print("cost=\(time2-time1)")

        if rs>0{
            self.fd=rs
        }else{
            switch rs{
            case -1:
                throw CommonError.HttpError(errCode: ResultCode.HTTP_CONNECT_ERR, errMsg: "qeury server fail")
                
            case -2:
                throw CommonError.HttpError(errCode: ResultCode.HTTP_CONNECT_ERR, errMsg: "connection closed")
                
            case -3:
                throw CommonError.HttpError(errCode: ResultCode.HTTP_CONNECT_TIMEOUT, errMsg: "connect timeout")
                
            default:
                throw CommonError.HttpError(errCode: ResultCode.HTTP_CONNECT_ERR, errMsg: "unknow err.")

            }
        }
    }
    /*
     * close socket
     * return success or fail with message
     */
    public func close()->(Bool,String){
        if let fd:Int32=self.fd{
            c_yhttpsocket_close(fd)
            self.fd=nil
            return (true,"close success")
        }else{
            return (false,"socket not open")
        }
    }
    /*
     * send data
     * return success or fail with message
     */
    public func send(data d:[UInt8]) throws{
        if let fd:Int32=self.fd{
            let sendsize:Int32=c_yhttpsocket_send(fd, buff: d, len: Int32(d.count))
            if Int(sendsize)==d.count{
                return
            }else{
                throw CommonError.HttpError(errCode: ResultCode.HTTP_SEND_ERR, errMsg: "send error")
                
            }
        }else{
            throw CommonError.HttpError(errCode: ResultCode.HTTP_CONNECTION_SEND_SOCKET_NOT_HEALTHY, errMsg: "socket not open")
            
        }
    }
    /*
     * send string
     * return success or fail with message
     */
    public func send(str s:String) throws{
        if let fd:Int32=self.fd{
            let sendsize:Int32=c_yhttpsocket_send(fd, buff: s, len: Int32(strlen(s)))
            if sendsize==Int32(strlen(s)){
                return
            }else{
                throw CommonError.HttpError(errCode: ResultCode.HTTP_SEND_ERR, errMsg: "send error")
            }
        }else{
            throw CommonError.HttpError(errCode: ResultCode.HTTP_CONNECTION_SEND_SOCKET_NOT_HEALTHY, errMsg: "socket not open")

        }
    }
    /*
     *
     * send nsdata
     */
    public func send(data d:NSData) throws{
        if let fd:Int32=self.fd{
            var buff:[UInt8] = [UInt8](count:d.length,repeatedValue:0x0) //初始化buff为发送数据的大小，默认填充0
            d.getBytes(&buff, length: d.length)
            let sendsize:Int32=c_yhttpsocket_send(fd, buff: buff, len: Int32(d.length))
            if sendsize==Int32(d.length){
                return
            }else{
                throw CommonError.HttpError(errCode: ResultCode.HTTP_SEND_ERR, errMsg: "send error")
            }
        }else{
            throw CommonError.HttpError(errCode: ResultCode.HTTP_CONNECTION_SEND_SOCKET_NOT_HEALTHY, errMsg: "socket not open")
        }
    }
    /*
     * read data with http content-length
     * return body data
     */
    public func read(timeout:Int = -1)->[UInt8]?{
        if let fd:Int32 = self.fd{
            let parser:HttpParser = HttpParser()
            do{
                try parser.read(fd: fd,timeout: timeout)   //TODO 这里要把时间传进去做接收超时处理
                return parser.responseBody
            }catch CommonError.HttpError(let errCode, let errMsg){
                print("errCode=\(errCode) errMsg=\(errMsg)")
            }catch{
                print(error)
            }
        }
        return nil
    }
    

}



