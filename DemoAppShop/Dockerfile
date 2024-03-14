# Stage 1: Build the application
FROM maven:3.8.4-openjdk-17 AS build
WORKDIR /build
COPY pom.xml .

COPY src src
RUN mvn clean package -DskipTests

# Stage 3: Create the final image
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY --from=build /build/target/online-shop-0.0.1-SNAPSHOT.jar /app/
COPY --from=ghcr.io/ufoscout/docker-compose-wait:latest /wait /wait
RUN chmod a+x /wait
EXPOSE 8080
ENV WAIT_COMMAND="java -jar "online-shop-0.0.1-SNAPSHOT.jar""
ENTRYPOINT ["/wait"]