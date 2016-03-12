# A little dockerfile to compile SwiftMongoDB on Ubuntu to run tests.
# Built (from root directory) with `docker build -t danappelxx/swiftmongodb -f Tests/Dockerfile .`

FROM swiftdocker/swift:latest

### Mongo server

# Add apt repository
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
RUN echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/3.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.0.list

# Fetch repository
RUN apt-get update

# Install mongodb
RUN apt-get install -y mongodb-org
RUN mkdir -p /data/db


### Mongo C Driver

# Install build dependencies
RUN apt-get install -y pkg-config libssl-dev libsasl2-dev

# Downloads release tarball
RUN wget https://github.com/mongodb/mongo-c-driver/releases/download/1.3.0/mongo-c-driver-1.3.0.tar.gz
RUN tar xzf mongo-c-driver-1.3.0.tar.gz

WORKDIR /mongo-c-driver-1.3.0/

# Compile Mongo-C
RUN ./configure
RUN make && make install
RUN ldconfig

### Swift Package Manager
WORKDIR /

# Download source, build
RUN git clone https://github.com/apple/swift-package-manager
RUN swift-package-manager/Utilities/bootstrap

### Swift MongoDB
WORKDIR /SwiftMongoDB/

# Copy files
ADD ./Package.swift /SwiftMongoDB/
ADD ./Sources /SwiftMongoDB/Sources
ADD ./Tests /SwiftMongoDB/Tests
ADD ./Packages /SwiftMongoDB/Packages

# Build it (extra flags because SPM breaks more and more)
RUN swift build -Xcc -I/usr/local/include/libbson-1.0/ -Xcc -fmodule-map-file=Packages/CBSON-1.1.1/module.modulemap -Xcc -fmodule-map-file=Packages/CMongoC-0.1.0/module.modulemap

### To run tests, start this container with /bin/bash and run `mongod --fork --logpath /dev/null` and `swift test`.
