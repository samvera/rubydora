FROM amazoncorretto:8

ENV FEDORA_HOME /opt/fedora
ENV CATALINA_HOME /opt/fedora/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH

RUN curl -L http://sourceforge.net/projects/fedora-commons/files/fedora/3.8.1/fcrepo-installer-3.8.1.jar/download -o /opt/fcrepo-installer.jar

COPY docker/install.properties /opt/install.properties
RUN java -jar /opt/fcrepo-installer.jar /opt/install.properties

EXPOSE 8983
WORKDIR $FEDORA_HOME

CMD ["catalina.sh", "run"]
