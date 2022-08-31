#!/bin/bash
kyloservicepod=$(kubectl get pods -o yaml | sed -En 's/name: tba-kylo-services-(.*)-(.*)/tba-kylo-services-\1-\2/p')
echo "kylo service pod is $kyloservicepod"
kubectl exec -it $kyloservicepod -- tail -1000f /var/log/kylo-services/kylo-services.log