# chrome-in-dev-spaces-ubi10

```bash
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
  interface: 0.0.0.0
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

```yaml
kind: List
apiVersion: v1
items:
# Create a proxy service account and ensure it will use the route "proxy"
- apiVersion: v1
  kind: ServiceAccount
  metadata:
    name: proxy
    annotations:
      serviceaccounts.openshift.io/oauth-redirectreference.primary: '{"kind":"OAuthRedirectReference","apiVersion":"v1","reference":{"kind":"Route","name":"proxy"}}'
# Create a secure connection to the proxy via a route
- apiVersion: route.openshift.io/v1
  kind: Route
  metadata:
    name: proxy
  spec:
    to:
      kind: Service
      name: proxy
    tls:
      termination: Reencrypt
- apiVersion: v1
  kind: Service
  metadata:
    name: proxy
    annotations:
      service.alpha.openshift.io/serving-cert-secret-name: proxy-tls
  spec:
    ports:
    - name: proxy
      port: 443
      targetPort: 8443
    selector:
      app: proxy
# Launch a proxy as a sidecar
- apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: proxy
  spec:
    replicas: 1
    selector:
      matchLabels:
        app: proxy
    template:
      metadata:
        labels:
          app: proxy
      spec:
        serviceAccountName: proxy
        containers:
        - name: oauth-proxy
          image: image-registry.openshift-image-registry.svc:5000/openshift/oauth-proxy:v4.4
          imagePullPolicy: IfNotPresent
          ports:
          - containerPort: 8443
            name: public
          args:
          - --https-address=:8443
          - --provider=openshift
          - --openshift-service-account=proxy
          - --upstream=http://localhost:8080
          - --tls-cert=/etc/tls/private/tls.crt
          - --tls-key=/etc/tls/private/tls.key
          - --cookie-secret=SECRET
          volumeMounts:
          - mountPath: /etc/tls/private
            name: proxy-tls

        - name: app
          image: openshift/hello-openshift:latest
        volumes:
        - name: proxy-tls
          secret:
            secretName: proxy-tls
```