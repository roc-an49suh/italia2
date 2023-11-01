default: all

REGISTRY=nexus.daf.teamdigitale.it
KYLO_SERVICES_PATH=../kylo0.9.1
#CLEAN=--no-cache
CLEAN=

.PHONY: activemq
activemq:
	docker build $(CLEAN) -t tba-activemq -f docker/activemq/Dockerfile docker/activemq
	docker tag tba-activemq $(REGISTRY)/tba-activemq.5.15.1:1.1.0
	docker push $(REGISTRY)/tba-activemq.5.15.1:1.1.0

.PHONY: mysql
mysql:
	mkdir -p docker/mysql/dist
	cp -R ${KYLO_SERVICES_PATH}/install/install-tar/target/kylo/setup/sql/mysql/kylo/* docker/mysql/dist
	docker build $(CLEAN) -t tba-mysql -f docker/mysql/Dockerfile docker/mysql
	docker tag tba-mysql $(REGISTRY)/tba-mysql.10.3:1.1.0
	docker push $(REGISTRY)/tba-mysql.10.3:1.1.0
	rm -dr docker/mysql/dist

.PHONY: kylo-services
kylo-services:
		mkdir -p docker/kylo-services/dist/kylo-services
		if [ ! -f ${KYLO_SERVICES_PATH}/install/install-tar/target/kylo/kylo-services/lib/postgresql-42.1.4.jar ] ;then curl -o ${KYLO_SERVICES_PATH}/install/install-tar/target/kylo/kylo-services/lib/postgresql-42.1.4.jar http://central.maven.org/maven2/org/postgresql/postgresql/42.1.4/postgresql-42.1.4.jar  ;fi
		# Apply patch for ghost jobs - start
		cp kylo/patch/kylo-operational-metadata-integration-service-0.9.1.4-SNAPSHOT.jar ${KYLO_SERVICES_PATH}/install/install-tar/target/kylo/kylo-services/lib/kylo-operational-metadata-integration-service-0.9.1.3.jar
		# Apply patch for ghost jobs - end
		cp -R ${KYLO_SERVICES_PATH}/install/install-tar/target/kylo/kylo-services/lib docker/kylo-services/dist/kylo-services
		cp -R ${KYLO_SERVICES_PATH}/install/install-tar/target/kylo/kylo-services/plugin docker/kylo-services/dist/kylo-services
		cp -R ${KYLO_SERVICES_PATH}/install/install-tar/target/kylo/bin docker/kylo-services/dist
		cp -R ${KYLO_SERVICES_PATH}/install/install-tar/target/kylo/lib docker/kylo-services/dist
		docker build $(CLEAN) -t tba-kylo-services -f docker/kylo-services/Dockerfile docker/kylo-services
		docker tag tba-kylo-services $(REGISTRY)/tba-kylo-services-fix.9.1:3.0.1
		rm -dr docker/kylo-services/dist

.PHONY: kylo-ui
kylo-ui:
		mkdir -p docker/kylo-ui/dist/kylo-ui
		cp -R ${KYLO_SERVICES_PATH}/install/install-tar/target/kylo/kylo-ui/lib docker/kylo-ui/dist/kylo-ui
		cp -R ${KYLO_SERVICES_PATH}/install/install-tar/target/kylo/kylo-ui/plugin docker/kylo-ui/dist/kylo-ui
		cp -R ${KYLO_SERVICES_PATH}/install/install-tar/target/kylo/bin docker/kylo-ui/dist
		cp -R ${KYLO_SERVICES_PATH}/install/install-tar/target/kylo/lib docker/kylo-ui/dist
		docker build $(CLEAN) -t tba-kylo-ui -f docker/kylo-ui/Dockerfile docker/kylo-ui
		docker tag tba-kylo-ui $(REGISTRY)/tba-kylo-ui.9.1:3.0.1
		rm -dr docker/kylo-ui/dist

.PHONY: nifi
nifi:
		mkdir -p docker/nifi/dist/daf
		cp -R ${KYLO_SERVICES_PATH}/install/install-tar/target/kylo/setup/nifi/* docker/nifi/dist
		# Apply patch for kylo and nifi async provenance - start
		cp nifi/patch/kylo-nifi-core-v1.2-nar-0.9.1.4-SNAPSHOT.nar docker/nifi/dist/kylo-nifi-core-v1.2-nar-0.9.1.3.nar
		# Apply patch for kylo and nifi async provenance - end
		# Apply patch for stucked queue before kylo init feed processor - start
		cp nifi/patch/kylo-nifi-core-service-v1.2-nar-0.9.1.4-SNAPSHOT.nar docker/nifi/dist/kylo-nifi-core-service-v1.2-nar-0.9.1.3.nar
		# Apply patch for stucked queue before kylo init feed processor - end
		# Apply KYLO-2894 fix
		cp nifi/patch/kylo-nifi-provenance-repo-v1.2-nar-0.9.1.4-SNAPSHOT.nar docker/nifi/dist/kylo-nifi-provenance-repo-v1.2-nar-0.9.1.3.nar
		cp -R ./nifi/extensions/processors/target/*.nar docker/nifi/dist/daf
		docker build $(CLEAN) -t tba-nifi -f docker/nifi/Dockerfile docker/nifi
		docker tag tba-nifi $(REGISTRY)/tba-nifi-fix.1.7.0:9.3.1
		rm -dr docker/nifi/dist

.PHONY: build-kylo
build-kylo:
	rm -rf ${KYLO_SERVICES_PATH} && \
	mkdir -p ${KYLO_SERVICES_PATH} && \
	git clone https://github.com/Teradata/kylo.git ${KYLO_SERVICES_PATH} | true  && \
	cd ${KYLO_SERVICES_PATH} && \
	git checkout tags/v0.9.1.3 -b v0.9.1.3 && \
	git apply ../daf-kylo/kylo/patch/hive_patch.patch && \
	mvn clean install -DskipTests=true -U && \
	mkdir -p install/install-tar/target/kylo && \
	tar -C install/install-tar/target/kylo -xvf install/install-tar/target/kylo-*-dependencies.tar.gz

.PHONY: daf-kylo
daf-kylo:
	git checkout master && \
	git pull && \
	cd nifi/extensions && \
	mvn clean install

clean:
	rm -rf ${KYLO_SERVICES_PATH}