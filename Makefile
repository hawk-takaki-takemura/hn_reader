.PHONY: deploy-config-dev deploy-config-stg deploy-config-prod
.PHONY: fetch-config-dev fetch-config-stg fetch-config-prod
.PHONY: run-dev run-stg run-prod

# アプリ起動（環境は dart-define で渡す。main 側の受け取りは未実装でも可）
run-dev:
	flutter run --dart-define=FLAVOR=dev

run-stg:
	flutter run --dart-define=FLAVOR=stg

run-prod:
	flutter run --dart-define=FLAVOR=prod

# Remote Config デプロイ
deploy-config-dev:
	firebase remoteconfig:update \
	  --project hn-reader-dev \
	  firebase/remote_config/dev.json

deploy-config-stg:
	firebase remoteconfig:update \
	  --project hn-reader-stg \
	  firebase/remote_config/stg.json

deploy-config-prod:
	firebase remoteconfig:update \
	  --project hn-reader-prod \
	  firebase/remote_config/prod.json

# 現在の設定を取得（確認用）
fetch-config-dev:
	firebase remoteconfig:get \
	  --project hn-reader-dev \
	  --output firebase/remote_config/dev_current.json

fetch-config-stg:
	firebase remoteconfig:get \
	  --project hn-reader-stg \
	  --output firebase/remote_config/stg_current.json

fetch-config-prod:
	firebase remoteconfig:get \
	  --project hn-reader-prod \
	  --output firebase/remote_config/prod_current.json
