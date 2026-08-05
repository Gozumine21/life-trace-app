#!/bin/bash
# Firebase Emulator 起動スクリプト
# 使い方: ./start-emulator.sh
# 起動するたびに bulltop21@gmail.com / LifeTrace2024 アカウントを自動作成します

cd "/Volumes/SSD 1TB/life-trace-app"
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

# 残っているエミュレータプロセスをクリーンアップ
lsof -ti :9099,8080,9199 2>/dev/null | xargs kill -9 2>/dev/null
sleep 1

# エミュレータをバックグラウンドで起動
echo "🔥 Firebase Emulator 起動中..."
firebase emulators:start --project demo-lifetrace > /tmp/emulator.log 2>&1 &
EMULATOR_PID=$!

# Auth emulator が準備できるまで待機
echo "⏳ Auth emulator 準備待ち..."
until curl -s http://localhost:9099 > /dev/null 2>&1; do
  sleep 2
done
echo "✅ Emulator 準備完了"

# アカウントが存在するか確認し、なければ作成
RESULT=$(curl -s -X POST \
  'http://localhost:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake' \
  -H 'Content-Type: application/json' \
  -d '{"email":"bulltop21@gmail.com","password":"LifeTrace2024","returnSecureToken":false}' 2>/dev/null)

if echo "$RESULT" | grep -q '"email"'; then
  echo "👤 アカウント確認済み: bulltop21@gmail.com"
else
  echo "📝 アカウントを作成中..."
  curl -s -X POST \
    'http://localhost:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake' \
    -H 'Content-Type: application/json' \
    -d '{"email":"bulltop21@gmail.com","password":"LifeTrace2024","returnSecureToken":false}' > /dev/null
  echo "✅ アカウント作成完了: bulltop21@gmail.com / LifeTrace2024"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ログイン情報"
echo "  メール: bulltop21@gmail.com"
echo "  パスワード: LifeTrace2024"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Ctrl+C で停止"
echo ""

# エミュレータが終了するまで待機
wait $EMULATOR_PID
