# 构建可执行二进制文件
# 指定构建的基础镜像
FROM golang:alpine AS builder
# 修改源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
# 安装相关环境依赖
RUN apk update && apk add --no-cache git bash wget curl unzip 
# 运行工作目录
WORKDIR /go/src/v2ray.com/core
# 克隆源码运行安装
RUN git clone --progress https://github.com/v2fly/v2ray-core.git . && \
    bash ./release/user-package.sh nosource noconf codename=$(git describe --tags) buildname=docker-fly abpathtgz=/tmp/v2ray.tgz


FROM alpine:latest

ENV TZ=Asia/Tehran
# 修改源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
# 更新源
RUN apk upgrade
# 同步时间
RUN apk add -U tzdata \
&& ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
&& echo ${TZ} > /etc/timezone

COPY --from=builder /tmp/v2ray.tgz /tmp

RUN wget -q -O /tmp/v2ray-linux-64.zip https://github.com/v2fly/v2ray-core/releases/download/v4.45.0/v2ray-linux-64.zip && \
    unzip -d /usr/local/v2ray /tmp/v2ray-linux-64.zip v2ray  && \
    wget -q -O /usr/local/v2ray/geosite.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat && \
    wget -q -O /usr/local/v2ray/geoip.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat && \
    chmod a+x /usr/local/v2ray/entrypoint.sh && \
    apk del wget unzip  && \
    rm -rf /tmp/v2ray-linux-64.zip && \
    rm -rf /var/cache/apk/* && \
    rm -rf /tmp/*


ENV PATH /usr/bin/v2ray:$PATH

# 拷贝配置文件
COPY config.json /etc/v2ray/config.json

# 运行v2ray
CMD ["v2ray", "-config=/etc/v2ray/config.json"]
