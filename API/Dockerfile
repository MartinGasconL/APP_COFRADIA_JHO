FROM maven:3.9.6-eclipse-temurin-17 AS builder
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -q
COPY src ./src
RUN mvn package -DskipTests -q

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
# FFmpeg: necesario para convertir MP4/vídeo a MP3 y leer la duración de las pistas.
RUN apk add --no-cache ffmpeg
COPY --from=builder /app/target/*.jar app.jar
ENV COFRADIA_MEDIA_DIR=/data/media
VOLUME ["/data/media"]
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
