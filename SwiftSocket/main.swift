/*
Copyright (c) <2014>, skysent
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
1. Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.
3. All advertising materials mentioning features or use of this software
must display the following acknowledgement:
This product includes software developed by skysent.
4. Neither the name of the skysent nor the
names of its contributors may be used to endorse or promote products
derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY skysent ''AS IS'' AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL skysent BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
import Foundation
import Darwin.C
func testtcpclient(){
    //创建socket
    let client:TCPClient = TCPClient(addr: "www.baidu.com", port: 80)
    //连接
    var (success,errmsg)=client.connect(timeout: 1)
    if success{
        //发送数据
        var (success,errmsg)=client.send(str:"GET / HTTP/1.0\n\n" )
        if success{
            //读取数据
            let data=client.read(1024*40)
//            if let d=data{
//                if let str=String(bytes: d, encoding: NSUTF8StringEncoding){
//                    print("111data="+str)
//                }
//            }
            let d = String(bytes:data!,encoding:NSUTF8StringEncoding)
            print("111data="+d!)
            
        }else{
            print("111"+errmsg)
        }


    }else{
        print(errmsg)
    }
}
//testtcpclient()

func testHttpclient(){
    //创建socket
    let httpClient:HttpClient = HttpClient(addr: "m.baidu.com", port: 80)
    //连接
    do{
        try httpClient.connect(timeout: 1)
        //发送数据
        try httpClient.send(str:"GET / HTTP/1.0\n\n" )
            //读取数据
            let data=httpClient.read(30)
            let d = String(bytes:data!,encoding:NSUTF8StringEncoding)
            print("111data="+d!)
    }catch{
        print(error)
    }
    
    
    
   
}
testHttpclient()


func echoService(client c:TCPClient){
    print("newclient from:\(c.addr)[\(c.port)]")
    let d=c.read(1024*10)
    c.send(data: d!)
    c.close()
}
func testtcpserver(){
    let server:TCPServer = TCPServer(addr: "127.0.0.1", port: 8080)
    var (success,msg)=server.listen()
    if success{
        while true{
            if let client=server.accept(){
                echoService(client: client)
            }else{
                print("accept error")
            }
        }
    }else{
        print(msg)
    }
}
//testclient()
func testudpserver(){
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () -> Void in
        let server:UDPServer=UDPServer(addr:"127.0.0.1",port:8080)
        let run:Bool=true
        while run{
            var (data,remoteip,remoteport)=server.recv(1024)
            print("recive")
            if let d=data{
                if let str=String(bytes: d, encoding: NSUTF8StringEncoding){
                    print(str)
                }
            }
            print(remoteip)
            server.close()
            break
        }
    })
}
func testudpclient(){
    let client:UDPClient=UDPClient(addr: "localhost", port: 8080)
    print("send hello world")
    client.send(str: "hello world")
    client.close()
}
//testudpBroadcastclient()
func testudpBroadcastserver(){
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () -> Void in
        //turn the server to broadcast mode with the address 255.255.255.255 or empty string
        let server:UDPServer=UDPServer(addr:"",port:8080)
        let run:Bool=true
        print("server.started")
        while run{
            let (data,remoteip,remoteport)=server.recv(1024)
            print("recive\(remoteip);\(remoteport)")
            if let d=data{
                if let str=String(bytes: d, encoding: NSUTF8StringEncoding){
                    print(str)
                }
            }
            print(remoteip)
        }
        print("server.close")
        server.close()
    })
}
func testudpBroadcastclient(){
    //wait a few second till server will ready
    sleep(2)
    print("Broadcastclient.send...")
    let clientB:UDPClient = UDPClient(addr: "255.255.255.255", port: 8080)
    clientB.enableBroadcast()
    clientB.send(str: "test hello from broadcast")
    clientB.close()
}

func test(){
    
    let statusLine = "HTTP/1.0 200 OK "
    let  statusLinePattern:String = "\\A(\\S+) +(\\d+) +(.*)"

    do{
        let re = try NSRegularExpression(pattern: statusLinePattern, options: NSRegularExpressionOptions.CaseInsensitive)
        
        let matches = re.matchesInString(statusLine, options: NSMatchingOptions(rawValue: 0), range: NSRange(location: 0, length: statusLine.utf16.count))
        
        print("number of matches: \(matches.count)")
        if matches.count > 0 {
            print("range size="+String(matches[0].numberOfRanges))
            //                        matches[0].numberOfRanges
            let httpVersion = (statusLine as NSString).substringWithRange(matches[0].rangeAtIndex(1))
            print("httpVersion="+httpVersion)
            print("rang0="+(statusLine as NSString).substringWithRange(matches[0].rangeAtIndex(0)))
            print("rang1="+(statusLine as NSString).substringWithRange(matches[0].rangeAtIndex(1)))
            print("rang2="+(statusLine as NSString).substringWithRange(matches[0].rangeAtIndex(2)))
            print("rang3="+(statusLine as NSString).substringWithRange(matches[0].rangeAtIndex(3)))
        }
        //
        //                    for match in matches as [NSTextCheckingResult] {
        //                        // range at index 0: full match
        //                        // range at index 1: first capture group
        //                        let substring = (statusLine as NSString).substringWithRange(match.rangeAtIndex(1))
        //                        print(substring)
        //                    }
        
        let str:String = "a \n"
        let utf8Array = Array(str.utf8);
        let utf16Array = Array(str.utf16);
        let utf8Length = utf8Array.count
        let utf16Length = utf16Array.count
        for i in 0...utf8Length-1{
            print("utf8=",utf8Array[i])
        }
        for i in 0...utf16Length-1{
            print("utf16=",utf16Array[i])
        }
        
//        print("utf16="+utf16Array)
    }catch{
        print(error)
    }

}
//test()
//testudpserver()
//testudpclient()

//testudpBroadcastserver()
//testudpBroadcastclient()

var stdinput=NSFileHandle.fileHandleWithStandardInput()
stdinput.readDataToEndOfFile()

