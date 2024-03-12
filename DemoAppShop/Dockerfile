FROM maven:3.8.4-openjdk-17 AS build
WORKDIR /build
COPY pom.xml .

COPY src src
RUN mvn clean package -DskipTests

# Stage 2: Create the final image
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY --from=build /build/target/online-shop-0.0.1-SNAPSHOT.jar /app/
EXPOSE 8080
CMD ["java", "-jar", "online-shop-0.0.1-SNAPSHOT.jar"]