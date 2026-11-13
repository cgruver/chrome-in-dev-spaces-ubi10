# chrome-in-dev-spaces-ubi10

As a privileged user, apply the following to the target user's dev spaces namespace:

```bash
oc apply -f - <<'EOF'
apiVersion: v1
kind: ServiceAccount
metadata:
  name: oauth-proxy
  annotations:
    serviceaccounts.openshift.io/oauth-redirectreference.primary: '{"kind":"OAuthRedirectReference","apiVersion":"v1","reference":{"kind":"Route","name":"oauth-proxy"}}'
---
apiVersion: v1
kind: Secret
metadata:
  name: oauth-proxy
  labels:
    controller.devfile.io/mount-to-devworkspace: "true"
    controller.devfile.io/watch-secret: "true"
  annotations:
    kubernetes.io/service-account.name: oauth-proxy
    controller.devfile.io/mount-as: file
    controller.devfile.io/mount-path: /var/run/oauth-client
type: kubernetes.io/service-account-token
---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: oauth-proxy
spec:
  to:
    kind: Service
    name: oauth-proxy
    weight: 100
  port:
    targetPort: 4180
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
EOF
```

## Starting Chrome:

1. Open a terminal in VS Code
1. Run the command `dschrome`
