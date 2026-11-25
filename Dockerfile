FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY . .
RUN for i in 1 2 3 4 5 6; do mvn -B -q -s settings.xml package -DskipTests && break; echo "Maven failed, retry $i"; sleep 20; done; test -f target/ROOT.war

FROM tomcat:10.1-jre21
RUN rm -rf /usr/local/tomcat/webapps/*
COPY --from=build /app/target/ROOT.war /usr/local/tomcat/webapps/ROOT.war
COPY docker/start.sh /usr/local/bin/start.sh
RUN sed -i 's/\r$//' /usr/local/bin/start.sh && chmod +x /usr/local/bin/start.sh
ENV DB_PATH=/tmp/laundry-desk.db
ENV JAVA_OPTS="-Xmx300m"
EXPOSE 8080
CMD ["start.sh"]