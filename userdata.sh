#!/bin/bash
# 構築ログをリアルタイムで保存
exec > >(tee /var/log/user-data.log) 2>&1

echo "===== Starting Stable Diffusion WebUI Forge Setup ====="

# 依存パッケージのインストール
apt-get update -y
apt-get install -y git libgl1-mesa-glx libglib2.0-0 inotify-tools python3.10-venv

# 権限トラブルを防ぐためubuntuユーザーのコンテキストで実行
sudo -u ubuntu -i bash << 'EOF'
cd /home/ubuntu

# 1. WebUI Forgeのクローン
if [ ! -d "stable-diffusion-webui-forge" ]; then
    echo "Cloning Forge Repository..."
    git clone https://github.com/lllyasviel/stable-diffusion-webui-forge.git
fi

cd stable-diffusion-webui-forge

# venvを先に作成してsetuptoolsを確保
python3 -m venv venv
./venv/bin/pip install --upgrade pip "setuptools==69.5.1" wheel

# CLIP of setup.py uses pkg_resources, so it fails in pip's isolated build environment.
# Pre-install with --no-build-isolation referencing setuptools in venv.
./venv/bin/pip install --no-build-isolation --no-deps \
    "https://github.com/openai/CLIP/archive/d50d76daa670286dd6cacf3bcd80b5e4823fc8e1.zip"

# requirements_versions.txt がscikit-image==0.21.0を固定しているが、
# numpy 2.x環境ではバイナリ非互換のためWebUIが起動しない。
# webui.shがrequirementsをインストールする前にpinを上書きしておく。
sed -i 's/scikit-image==0.21.0/scikit-image>=0.24.0/' requirements_versions.txt || true

# 2. S3バケットから事前に用意したモデル群を高速同期（EBSへキャッシュ）
echo "Syncing assets from S3 bucket: ${s3_bucket}..."
mkdir -p ./models/ControlNet
aws s3 sync s3://${s3_bucket}/models/ ./models/
aws s3 sync s3://${s3_bucket}/loras/ ./models/Lora/
aws s3 sync s3://${s3_bucket}/embeddings/ ./embeddings/

# =====================================================================
# 【追加】Checkpoint欄（最上部ドロップダウン）への誤混入を永久に防ぐクリーンアップ
# =====================================================================
rm -rf ./models/Stable-diffusion/ControlNet
# =====================================================================

# 3. 画像が生成された瞬間にバックグラウンドでS3へ自動コピーするデーモンを起動
mkdir -p outputs
cat << 'INNER_EOF' > sync_outputs.sh
#!/bin/bash
# outputsフォルダを常時監視し、書き込み完了を検知してS3へ転送
inotifywait -m -r -e close_write --format '%w%f' ./outputs | while read file
do
    if [ -f "$file" ]; then
        echo "New image detected. Uploading $file to S3..."
        aws s3 cp "$file" s3://${s3_bucket}/outputs/$(basename "$file")
    fi
done
INNER_EOF

chmod +x sync_outputs.sh
./sync_outputs.sh &

# 4. WebUI Forgeの起動（外部疎通許可、xformers有効化）
echo "Launching WebUI Forge process..."
./webui.sh --listen --port 7860 --enable-insecure-extension-access --xformers > webui_run.log 2>&1 &

EOF

echo "===== Setup Script Finished ====="