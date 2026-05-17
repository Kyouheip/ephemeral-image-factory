# 画像生成サーバー構築IaC

AI画像生成は強力なGPUを必要としますが、個人開発やライトユースにおいて24時間稼働のサーバーやローカルのGPUは高価で用意が難しいため、未使用時の維持費をほぼゼロにするAI画像生成サーバーをAWSクラウド上に構築したTerraform構成です。

モデルやLoRAはEBSではなくS3に保存し、EC2起動時のユーザーデータで自動転送される仕組みになっています。使用するときだけEC2を立ち上げ、使い終わったら `terraform destroy` で全リソースを破棄することでコストを最小化しています。

GPUインスタンスはAWS全体でも需要が高く、スポットインスタンスでは起動失敗が頻発するため、オンデマンドインスタンスを採用しています。

UIは **Stable Diffusion WebUI Forge** を使用しています。

---

## アーキテクチャ
アーキテクチャ図作成予定


| リソース | 詳細 |
|---|---|
| EC2 | g4dn.xlarge|
| AMI | AWS Deep Learning OSS Nvidia Driver AMI（Ubuntu 22.04） |
| ストレージ | ルートボリューム gp3 120GB ＋ モデルはS3 |
| ネットワーク | VPC / パブリックサブネット / 自分のIPのみ許可 |
| SSHキー | Terraform apply時に毎回生成、`sd-forge-key.pem`として保存 |
| IAM | EC2インスタンスロール経由でS3にアクセス |

---

## 料金の目安

| 状態 | 費用 |
|---|---|
| EC2起動中（g4dn.xlarge オンデマンド） | 約79円 / 時間 |
| EC2停止中（S3保存のみ） | 約3.5円 / GB / 月 |

使わないときは必ず `terraform destroy` でEC2を削除してください。S3のモデルはそのまま残ります。

---

## 事前準備

### 必要なもの

- Terraform >= 1.0.0
- AWS CLI（`aws configure` 設定済み）
- S3バケット（Terraform管理外のため、先に作成しておく）

```bash
aws s3 mb s3://作成したバケット名 --region us-west-2
```

### S3へのモデルアップロード

EC2起動時にユーザーデータが自動でS3から転送します。事前に以下のパスへアップロードしてください。

```bash
# モデル
aws s3 cp モデルファイル名.safetensors s3://作成したバケット名/models/

# LoRA
aws s3 cp LoRAファイル名.safetensors s3://作成したバケット名/loras/
```
💡 補足：おすすめのモデルについて
イラスト系・実写系でそれぞれ以下のモデルなどが人気でおすすめです。好みに合わせて CivitAI 等からダウンロードして S3 に配置してください。

2D・イラスト系: Pony 2D (Ponyベースの優秀な二次元モデル)

リアル・実写系: cyber_realistic_xl (リアルな質感に強みを持つXLモデル)

---

## セットアップ手順

### 1. リポジトリをクローン

```bash
git clone https://github.com/Kyouheip/ephemeral-image-factory.git
cd ephemeral-image-factory
```

### 2. terraform.tfvarsを作成

個人のIPアドレスとバケット名が含まれるため `.gitignore` に設定済みです。

```hcl
# terraform.tfvars
my_ip          = "自分のグローバルIP/32"    # 例: "203.0.113.5/32"
s3_bucket_name = "作成したバケット名"
```

### 3. 初期化と起動

```bash
terraform init
terraform apply
```

完了後、以下のようにURLとSSHコマンドが出力されます。

```
webui_url   = "http://<PUBLIC_IP>:7860"
ssh_command = "ssh -i sd-forge-key.pem ubuntu@<PUBLIC_IP>"
```

**SSHキーについて**: `sd-forge-key.pem` は apply のたびに新規生成されます。`.gitignore` に設定済みです。

### 4. 起動確認

EC2が立ち上がってからWebUIが使えるようになるまで、ユーザーデータの処理を含めて**5〜10分ほどかかります**。

起動が遅い場合はSSHでサーバーに入ってログを確認してください。

```bash
ssh -i sd-forge-key.pem ubuntu@<PUBLIC_IP> "tail -f /var/log/user-data.log"
```

### 5. WebUIにアクセス

ブラウザで以下のURLを開きます。

```
http://<PUBLIC_IP>:7860
```

### 6. 使い終わったら必ず破棄

```bash
terraform destroy
```

S3バケットはTerraform管理外のため、destroyしても**削除されません。**