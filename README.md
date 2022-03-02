# 概要
SSH接続用サーバ兼、OpenSearch Dashboardsアクセス用プロキシーサーバをデプロイするためのコンテナイメージ

<BR>

# 環境
- OS
  - Amazon Linux2
- ユーザー
  - ec2-user
- 起動プロセス
  - sshd
  - nginx 

<BR>

# Nginx設定ファイル
- default.confにOpenSearchドメインのエンドポイントと、Cognitoのログイン用ドメイン（パラメーター：DomainPrefix）を設定する
- 以下のコマンドで置換する
```
$ sudo sed -i 's/$domain-endpoint/[ドメインエンドポイント]/' /etc/nginx/conf.d/default.conf
$ sudo sed -i 's/$cognito_host/[Cognitoのログイン用ドメイン].auth.[リージョン].amazoncognito.com/' /etc/nginx/conf.d/default.conf

例）
$ sudo sed -i 's/$domain-endpoint/vpc-hrjoboffer-dev-xeurlaoavsjteppcqcoyrbqsmm.ap-northeast-1.es.amazonaws.com/' /etc/nginx/conf.d/default.conf
$ sudo sed -i 's/$cognito_host/hrjoboffer-dev-login.auth.ap-northeast-1.amazoncognito.com/' /etc/nginx/conf.d/default.conf
```

<BR>

# 注意事項

## ECSサービスのセキュリティグループについて
- ECSサービス作成時、設定するセキュリティグループにOpenSearch用セキュリティグループを必ず含めてください。

<BR>

## 自己署名証明書について
- OpenSearch DashboardsにアクセスするにはHTTPS経由である必要があるため、自己署名証明書を利用しています。
- そのため、ブラウザでアクセスした際に警告メッセージが表示されます。
- 自己署名証明書はECSタスク起動時に生成されます。

<BR>

# 参考記事
- [Amazon Cognito 認証を使用して、NGINX プロキシで VPC の外部から OpenSearch Dashboards にアクセスするにはどうすればよいですか?](https://aws.amazon.com/jp/premiumsupport/knowledge-center/opensearch-outside-vpc-nginx/)

<BR>