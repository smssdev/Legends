$ mkdir -p ~/keys
$ keytool -genkeypair -v -keystore ~/keys/upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storepass:env STORE_PASSWORD -keypass:env STORE_PASSWORD -dname 'CN=Bit Cafe, O=Bit Cafe, C=EG'
Generating 2,048 bit RSA key pair and self-signed certificate (SHA384withRSA) with a validity of 10,000 days
	for: CN=Bit Cafe, O=Bit Cafe, C=EG
[Storing ~/keys/upload-keystore.jks]

Warning:
The JKS keystore uses a proprietary format. It is recommended to migrate to PKCS12 which is an industry standard format using "keytool -importkeystore -srckeystore ~/keys/upload-keystore.jks -destkeystore ~/keys/upload-keystore.jks -deststoretype pkcs12".
