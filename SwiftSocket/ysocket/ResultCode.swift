//
//  ResultCode.swift
//  SwiftSocket
//
//  Created by jieshao on 16/8/1.
//  Copyright © 2016年 swift. All rights reserved.
//

import Foundation
/**
 * Created by jieshao on 2015/3/25.
 * 区分不同网络异常，待完善
 */
public class ResultCode:NSData {
    static let  OK = 0;
    /**结构体解析异常*/
    static let PROTOCOL_DECODE_ERR = -1;
    
    
    
    //以下是Http相关返回码定义
    static let HTTP_OK = 200;
    
    static let HTTP_SOCKETTIMEOUT = -800;  //socket超时
    static let HTTP_CONTENT_LENGTH_PARSE_ERR = -801; //content-length解析异常
    static let HTTP_STATUS_LINE_PARSE_ERR = -802; //status line解析异常
    static let HTTP_STATUS_LINE_PARSE_ERR_EMPTY = -8021; //status line解析异常
    static let HTTP_BODY_READ_ERR = -803; //http body部分读取异常
    static let HTTP_DNS_RESOLVE_ERR = -804; //dns解析异常，正常来说不会出现
    static let HTTP_CONNECT_TIMEOUT = -805; 	// 连接超时
    static let HTTP_IO_ERR = -806; //IO异常
    static let HTTP_ENTITYNULL = -807; //回包包体为空
    static let HTTP_RESPONSENULL = -808;//没有得到Response
    static let HTTP_OTHER_ERR = -809; //其他异常
    static let HTTP_SOCKET_ERR = -810; //socket异常
    static let HTTP_SOCKET_ERR_NO_ROUTE = -8101; //socket异常
    static let HTTP_SOCKET_ERR_PORT_UNREACH = -8102; //socket异常
    static let HTTP_SOCKET_ERR_BIND = -8103; //socket异常
    static let HTTP_SOCKET_ERR_HTTP_HOST = -8104; //socket异常
    public static let HTTP_CONNECT_ERR = -811;//连接异常
    static let HTTP_ADDRESS_ERR = -812;//remoteAddr =null
    static let HTTP_SOCK_NAME_BAD_FD = -813 ; //一种特殊场景的异常，用上报来看占比
    static let HTTP_REQUESTNULL = -814;
    static let HTTP_SEND_ERR = -815;
    
    static let HTTP_EXCEED_POOL_CONNECTION_LIMIT = -900; //超出连接池连接数限制
    static let HTTP_CONNECTION_SEND_SOCKET_NULL = -901; // 发送数据时获取socket为null
    static let HTTP_CONNECTION_SEND_SOCKET_NOT_HEALTHY = -902; //发送数据进socket不正常
    static let HTTP_CONNECTION_RECV_SOCKET_NULL = -903; // 接收数据时发现socket为null
    
    static let NOT_SUPPORT_ERR = -99999; //不支持的err，用于反射未取到业务返回码时判断
    
}
