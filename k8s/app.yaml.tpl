apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: shop
  labels:
    app: web
    team: ${TEAM}
    commit: "${GIT_SHA}"
spec:
  replicas: ${REPLICAS}
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
        team: ${TEAM}
        commit: "${GIT_SHA}"
    spec:
      nodeSelector:
        karpenter.sh/capacity-type: ${CAPACITY}
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: kubernetes.io/hostname
          whenUnsatisfiable: ScheduleAnyway
          labelSelector:
            matchLabels:
              app: web
      terminationGracePeriodSeconds: 30
      containers:
        - name: web
          image: ghcr.io/stefanprodan/podinfo:6.7.1
          ports:
            - containerPort: 9898
          resources:
            requests:
              cpu: ${CPU_REQ}
              memory: ${MEM_REQ}
            limits:
              memory: ${MEM_REQ}
          readinessProbe:
            httpGet:
              path: /readyz
              port: 9898
            periodSeconds: 2
---
apiVersion: v1
kind: Service
metadata:
  name: web
  namespace: shop
spec:
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 9898
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: web-pdb
  namespace: shop
spec:
  maxUnavailable: 1
  selector:
    matchLabels:
      app: web
