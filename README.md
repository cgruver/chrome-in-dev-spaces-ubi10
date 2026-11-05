# chrome-in-dev-spaces-ubi10

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
EOF
```

```yaml
apiVersion: template.openshift.io/v1
kind: Template
metadata:
  name: devspaces-oauth-proxy-dependencies
  namespace: openshift-devspaces
  labels:
    app.kubernetes.io/part-of: che.eclipse.org
    app.kubernetes.io/component: workspaces-config
objects:
- apiVersion: v1
  kind: ServiceAccount
  metadata:
    name: oauth-proxy
    annotations:
      serviceaccounts.openshift.io/oauth-redirectreference.primary: '{"kind":"OAuthRedirectReference","apiVersion":"v1","reference":{"kind":"Route","name":"oauth-proxy"}}'
- apiVersion: v1
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
```

```yaml
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
---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: proxy
spec:
  to:
    kind: Service
    name: proxy
  tls:
    termination: Passthrough
---
apiVersion: v1
kind: Service
metadata:
  name: proxy
  annotations:
    service.beta.openshift.io/serving-cert-secret-name: proxy-tls
spec:
  ports:
  - name: proxy
    port: 443
    targetPort: 8443
  selector:
    app: proxy
```

```bash
COOKIE_SECRET=$(openssl rand -base64 32)

/usr/bin/oauth-proxy --http-address=:4180 --provider=openshift --https-address= --upstream=http://localhost:8444 --cookie-secret=${COOKIE_SECRET} --cookie-secure=true --pass-basic-auth=false --skip-provider-button=true --client-id=system:serviceaccount:${WORKSPACE_NAMESPACE}:wizard-oauth --client-secret-file=/var/run/oauth-client/token --openshift-ca=/etc/pki/tls/cert.pem --openshift-ca=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt --openshift-sar={"namespace":"${WORKSPACE_NAMESPACE}","resource":"pods","verb":"get"}


if [ ! -d ${HOME}/.config/google-chrome ]
then
  mkdir -p ${HOME}/.config/google-chrome
  touch ${HOME}/.config/google-chrome/'First Run'
fi
rm -f ${HOME}/.config/google-chrome/Singleton{Cookie,Lock,Socket}

if [ ! -d ${HOME}/.vnc ]
then
  mkdir ${HOME}/.vnc
  touch ${HOME}/.vnc/.de-was-selected
  (echo '#!/bin/sh';echo 'unset SESSION_MANAGER';echo 'unset DBUS_SESSION_BUS_ADDRESS';echo 'echo starting Xvnc') > ${HOME}/.vnc/xstartup
  chmod +x ${HOME}/.vnc/xstartup
fi
cat << EOF > ${HOME}/.vnc/kasmvnc.yaml
network:
  websocket_port: 8444
  interface: 127.0.0.1
  protocol: http
  ssl:
    require_ssl: false
  use_ipv4: true
  use_ipv6: false
user_session:
  session_type: exclusive
  concurrent_connections_prompt: false
logging:
  log_writer_name: all
  log_dest: logfile
  level: 30
desktop:
  resolution:
    width: 1280
    height: 1024
  allow_resize: true
  pixel_depth: 24
EOF
VNC_PASSWD=nopasswd
echo -e "${VNC_PASSWD}\n${VNC_PASSWD}\n" | vncpasswd -w -r -u user ${HOME}/.kasmpasswd
/usr/bin/vncserver :0 -disableBasicAuth

export $(dbus-launch)
/usr/bin/google-chrome --display=:0 --disable-gpu --disable-software-rasterizer --disable-dev-shm-usage --disable-plugins --disable-plugins-discovery --disable-notifications --disable-sync --mute-audio --dns-prefetch-disable --noremote --start-maximized > /tmp/chrome.out 2>&1 &
```


