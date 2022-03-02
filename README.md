# 概要
SSH接続用サーバ兼、OpenSearch Dashboardsアクセス用プロキシーサーバをデプロイするためのコンテナイメージ

<BR>

# 構成
- OS
  - Amazon Linux2
- ユーザー
  - ec2-user
- 起動プロセス
  - sshd
  - nginx 

<BR>

# Nginx設定ファイル
- default.confにOpenSearchドメインのエンドポイントと、Cognitoのログイン用ドメイン（パラメーター：DomainPrefix）を設定する必要があります
- 以下のコマンドで置換
```
$ sudo sed -i 's/$domain-endpoint/[ドメインエンドポイント]/' /etc/nginx/conf.d/default.conf
$ sudo sed -i 's/$cognito_host/[Cognitoのログイン用ドメイン].auth.[リージョン].amazoncognito.com/' /etc/nginx/conf.d/default.conf

例）
$ sudo sed -i 's/$domain-endpoint/vpc-hrjoboffer-dev-xeurlaoavsjteppcqcoyrbqsmm.ap-northeast-1.es.amazonaws.com/' /etc/nginx/conf.d/default.conf
$ sudo sed -i 's/$cognito_host/hrjoboffer-dev-login.auth.ap-northeast-1.amazoncognito.com/' /etc/nginx/conf.d/default.conf
```

<BR>

# SSH公開鍵認証用キーペア
- 起動したサーバにSSH接続するためのキーペアを作成する必要があります
- 以下のコマンドで作成
```
Linuxの場合
$ ssh-keygen -t rsa -b 4096
```
- Puttyで作成しても問題ありませんが、公開鍵のファイル名は必ず「id_rsa.pub」で保存してください。
- id_rsa.pubを差し替える

<BR>

# 注意事項

## ECSサービスのセキュリティグループについて
- ECSサービス作成時、設定するセキュリティグループにOpenSearch用セキュリティグループを必ず含めてください

<BR>

## 自己署名証明書について
- OpenSearch DashboardsにアクセスするにはHTTPS経由である必要があるため、自己署名証明書を利用しています
- そのため、ブラウザでアクセスした際に警告メッセージが表示されます
- 自己署名証明書はECSタスク起動時に生成されます（CN=localhost）

<BR>

# 参考記事
- [Amazon Cognito 認証を使用して、NGINX プロキシで VPC の外部から OpenSearch Dashboards にアクセスするにはどうすればよいですか?](https://aws.amazon.com/jp/premiumsupport/knowledge-center/opensearch-outside-vpc-nginx/)

<BR>