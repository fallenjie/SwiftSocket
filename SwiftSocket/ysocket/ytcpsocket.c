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
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <dirent.h>
#include <netdb.h>
#include <unistd.h>
#include <fcntl.h>
#include <signal.h>
#include <sys/select.h>
void ytcpsocket_set_block(int socket,int on) {
    int flags;
    flags = fcntl(socket,F_GETFL,0);
    if (on==0) {
        fcntl(socket, F_SETFL, flags | O_NONBLOCK);
    }else{
        flags &= ~ O_NONBLOCK;
        fcntl(socket, F_SETFL, flags);
    }
}
/**
 @param host 服务器的地址
 @param port 服务器的端口
 @param timeout 连接超时*/
int ytcpsocket_connect(const char *host,int port,int timeout){
    struct sockaddr_in sa;  //socket address地址结构
    struct hostent *hp;  // 解析出来的host信息？
    int sockfd = -1;     // socket fd定义
    hp = gethostbyname(host);  //通过地址/域名获取对应的host信息（这一步是不是就可能被系统发出sig给终结掉？）
    if(hp==NULL){               //如果无法获取到对应的host信息，那就直接连接失败
        return -1;
    }
    // 将解析出来的host信息中的ip地址填充到sockaddr中
    bcopy((char *)hp->h_addr, (char *)&sa.sin_addr, hp->h_length);
    sa.sin_family = hp->h_addrtype;
    sa.sin_port = htons(port);
    sockfd = socket(hp->h_addrtype, SOCK_STREAM, 0);
    
    ytcpsocket_set_block(sockfd,0); // 设置tcpnodelay,能更快的发出小包
    
    connect(sockfd, (struct sockaddr *)&sa, sizeof(sa));
    fd_set          fdwrite;
    struct timeval  tvSelect;
    FD_ZERO(&fdwrite);
    FD_SET(sockfd, &fdwrite);
    tvSelect.tv_sec = timeout;
    tvSelect.tv_usec = 0;
    int retval = select(sockfd + 1,NULL, &fdwrite, NULL, &tvSelect);
    if (retval<0) {
        close(sockfd);
        return -2;
    }else if(retval==0){//timeout
        close(sockfd);
        return -3;
    }else{
        int error=0;
        int errlen=sizeof(error);
        getsockopt(sockfd, SOL_SOCKET, SO_ERROR, &error, (socklen_t *)&errlen);
        if(error!=0){
            close(sockfd);
            return -4;//connect fail
        }
        ytcpsocket_set_block(sockfd, 1);
        int set = 1;
        setsockopt(sockfd, SOL_SOCKET, SO_NOSIGPIPE, (void *)&set, sizeof(int));
        return sockfd;
    }
}
int ytcpsocket_close(int socketfd){
    return close(socketfd);
}
int ytcpsocket_pull(int socketfd,char *data,int len,int timeout_sec){
    if (timeout_sec>0) {  //处理读取超时
        fd_set fdset;
        struct timeval timeout;
        timeout.tv_usec = 0;
        timeout.tv_sec = timeout_sec;
        FD_ZERO(&fdset);
        FD_SET(socketfd, &fdset);
        int ret = select(socketfd+1, &fdset, NULL, NULL, &timeout);
        if (ret<=0) {
            return ret; // select-call failed or timeout occurred (before anything was sent)
        }
    }
    int readlen=(int)read(socketfd,data,len);
    return readlen;
}
//int ytcpsocket_read(int socketfd,char )
int ytcpsocket_send(int socketfd,const char *data,int len){
    int byteswrite=0;
    while (len-byteswrite>0) {
        int writelen=(int)write(socketfd, data+byteswrite, len-byteswrite);
        if (writelen<0) {
            return -1;
        }
        byteswrite+=writelen;
    }
    return byteswrite;
}
//return socket fd
int ytcpsocket_listen(const char *addr,int port){
    //create socket
    int socketfd=socket(AF_INET, SOCK_STREAM, 0);
    int reuseon   = 1;
    setsockopt( socketfd, SOL_SOCKET, SO_REUSEADDR, &reuseon, sizeof(reuseon) );
    //bind
    struct sockaddr_in serv_addr;
    memset( &serv_addr, '\0', sizeof(serv_addr));
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_addr.s_addr = inet_addr(addr);
    serv_addr.sin_port = htons(port);
    int r=bind(socketfd, (struct sockaddr *) &serv_addr, sizeof(serv_addr));
    if(r==0){
        if (listen(socketfd, 128)==0) {
            return socketfd;
        }else{
            return -2;//listen error
        }
    }else{
        return -1;//bind error
    }
}
//return client socket fd
int ytcpsocket_accept(int onsocketfd,char *remoteip,int* remoteport){
    socklen_t clilen;
    struct sockaddr_in  cli_addr;
    clilen = sizeof(cli_addr);
    int newsockfd = accept(onsocketfd, (struct sockaddr *) &cli_addr, &clilen);
    char *clientip=inet_ntoa(cli_addr.sin_addr);
    memcpy(remoteip, clientip, strlen(clientip));
    *remoteport=cli_addr.sin_port;
    if(newsockfd>0){
        return newsockfd;
    }else{
        return -1;
    }
}
