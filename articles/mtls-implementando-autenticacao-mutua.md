---
title: "GoでmTLSによるクライアント・サーバー間の相互認証を実装する"
emoji: "🔐"
type: "tech"
topics: ["go", "security", "tls", "mtls"]
published: true
---

mTLS (Mutual TLS) authenticates both client and server. Each one presents a digital certificate signed by a trusted certificate authority. By controlling certificate issuance, you ensure that only authorized clients access your service. It also makes it easy to identify the client without needing an API Key or Token. I also recommend using an [HMAC (Hash-based Message Authentication Code)](https://crg.eti.br/en/post/hmac-assinatura-de-mensagens-segura-em-go/) header as an additional layer of security and message integrity.

## Creating Certificates

In this example, I'll create the certificates in a simple way for local testing. When deploying to production, be careful with the parameters you use. It's important to include Subject Alternative Names (SANs), since relying on the CN (Common Name) alone is no longer recommended.

First, create the CA (Certificate Authority) key pair:

```bash
openssl genrsa -out ca.key 4096

openssl req -x509 -new -nodes \
    -key ca.key -sha256 -days 3650 \
    -out ca.pem \
    -subj "/C=BR/ST=Estado/L=Cidade/O=MinhaEmpresa/OU=TI/CN=MinhaCA"
```

This gives you the `ca.key` and `ca.pem` files, which are the CA's private and public keys.

Create a text file `server_cert_ext.cnf` with the server certificate settings:

```ini
[ req ]
default_bits       = 2048
prompt             = no
default_md         = sha256
distinguished_name = dn
req_extensions     = req_ext

[ dn ]
C  = BR
ST = Estado
L  = Cidade
O  = MinhaEmpresa
OU = TI
CN = localhost

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = localhost
IP.1  = 127.0.0.1
```

Now, create the server key pair:

```bash
openssl genrsa -out server.key 2048

openssl req -new \
    -key server.key \
    -out server.csr \
    -config server_cert_ext.cnf
```

Sign the server certificate with the CA, including the extensions:

```bash
openssl x509 -req \
    -in server.csr \
    -CA ca.pem \
    -CAkey ca.key \
    -CAcreateserial \
    -out server.pem \
    -days 365 \
    -sha256 \
    -extfile server_cert_ext.cnf \
    -extensions req_ext
```

The server certificate is now ready. Next, create the client key pair. First, create the `client_cert_ext.cnf` configuration file:

```ini
[ req ]
default_bits       = 2048
prompt             = no
default_md         = sha256
distinguished_name = dn
req_extensions     = req_ext

[ dn ]
C  = BR
ST = Estado
L  = Cidade
O  = MinhaEmpresa
OU = CODIGODOCLIENTE
CN = Cliente

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = Cliente
```

Note that in the `OU` field, I put a client code to identify who is accessing the service. Now, create the client key pair:

```bash
openssl genrsa -out client.key 2048

openssl req -new -key client.key \
    -out client.csr \
    -config client_cert_ext.cnf
```

Sign the client certificate with the CA, including the extensions:

```bash
openssl x509 -req \
    -in client.csr \
    -CA ca.pem \
    -CAkey ca.key \
    -CAcreateserial \
    -out client.pem \
    -days 365 \
    -sha256 \
    -extfile client_cert_ext.cnf \
    -extensions req_ext
```

You now have all the certificates you need:

- *ca.pem*: CA certificate.
- *ca.key*: CA private key.
- *server.pem*: Server certificate with SANs.
- *server.key*: Server private key.
- *client.pem*: Client certificate with SANs.
- *client.key*: Client private key.

## Server

Create a simple server in Go that uses the certificates you created:

```go
cert, err := tls.LoadX509KeyPair("server.pem", "server.key")
if err != nil {
    log.Fatalf("Erro ao carregar certificado do servidor: %v", err)
}

caCert, err := os.ReadFile("ca.pem")
if err != nil {
    log.Fatalf("Erro ao ler CA cert: %v", err)
}
caCertPool := x509.NewCertPool()
if ok := caCertPool.AppendCertsFromPEM(caCert); !ok {
    log.Fatalf("Erro ao adicionar CA cert ao pool")
}

tlsConfig := &tls.Config{
    Certificates: []tls.Certificate{cert},
    ClientCAs:    caCertPool,
    ClientAuth:   tls.RequireAndVerifyClientCert,
}

server := &http.Server{
    Addr:      ":8080",
    TLSConfig: tlsConfig,
}

http.HandleFunc("/", helloHandler)

log.Fatal(server.ListenAndServeTLS("", ""))
```
[full server source code](server/main.go)

The process is similar to creating a regular server. Load the server's certificate and private key. Also load the CA certificate and add it to `ClientCAs`. Set `ClientAuth` to `tls.RequireAndVerifyClientCert`, requiring the client to present a valid certificate. There are other configuration options you can adjust as needed.

The `helloHandler` handler checks whether the client is authorized:

```go
func helloHandler(w http.ResponseWriter, r *http.Request) {
    if len(r.TLS.PeerCertificates) > 0 {
        client := r.TLS.PeerCertificates[0]
        ret := fmt.Sprintf(
            "Common Name: %s\nOrganization Unit: %s\nSerial Number: %s\n",
            client.Subject.CommonName,
            client.Subject.OrganizationalUnit[0],
            client.SerialNumber.Text(16))
        fmt.Fprintf(w, ret)
        log.Printf("Client CN: %s, OU: %s, Serial: %s\n",
            client.Subject.CommonName,
            client.Subject.OrganizationalUnit[0],
            client.SerialNumber.Text(16))
        return
    }

    w.WriteHeader(http.StatusUnauthorized)
    fmt.Fprintf(w, `{ "error": "client certificate required" }`)
}
```

The handler checks whether the client has a certificate. If it does, it formats and returns the certificate information. Otherwise, it responds with an authorization error.

## Client

Create a simple client in Go that uses the certificate you created:

```go
cert, err := tls.LoadX509KeyPair("client.pem", "client.key")
if err != nil {
    log.Fatalf("Erro ao carregar certificado do cliente: %v", err)
}

caCert, err := os.ReadFile("ca.pem")
if err != nil {
    log.Fatalf("Erro ao ler CA cert: %v", err)
}
caCertPool := x509.NewCertPool()
if ok := caCertPool.AppendCertsFromPEM(caCert); !ok {
    log.Fatalf("Erro ao adicionar CA cert ao pool")
}

tlsConfig := &tls.Config{
    Certificates:       []tls.Certificate{cert},
    RootCAs:            caCertPool,
    InsecureSkipVerify: false,
}

transport := &http.Transport{
    TLSClientConfig: tlsConfig,
}

client := &http.Client{
    Transport: transport,
}

resp, err := client.Get("https://localhost:8080/")
if err != nil {
    log.Fatalf("Erro na requisição: %v", err)
}
defer resp.Body.Close()

body, err := io.ReadAll(resp.Body)
if err != nil {
    log.Fatalf("Erro ao ler resposta: %v", err)
}

fmt.Printf("Resposta do servidor: %s\n", body)
```
[full client source code](client/main.go)

As with the server, load the client's certificate and private key. Also load the CA certificate and configure the HTTP transport with `TLSClientConfig`.

## Key Points

- **Security**: mTLS provides secure authentication. Include SANs in your certificates for added security.
- **Expiration**: Manage certificate renewal so clients don't lose access due to expired certificates.
- **Complexity**: mTLS is more complex than other forms of authentication. Make integration easier by building SDKs for your clients.
- **Certificate Management**: Keep public and private key files safe. Plan carefully how these files are stored and distributed.

## Conclusion

mTLS is the most secure form of authentication. Once you solve the initial challenges of managing keys and certificates, you'll have a robust and secure system. The client and server code is simple and can be easily integrated into your project, making its use transparent. However, with each new client, you'll need to guide them through certificates and information security.

Video with the explanation (in Portuguese):

@[youtube](Cixe3hXyp5I)
