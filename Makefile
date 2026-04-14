.PHONY: deploy-config-dev deploy-config-stg deploy-config-prod
.PHONY: fetch-config-dev fetch-config-stg fetch-config-prod
.PHONY: run-dev run-stg run-prod build-ios-dev build-ios-prod build-android-dev build-android-prod clean

run-dev:
	flutter run --flavor Runner-dev -t lib/main_dev.dart

run-stg:
	flutter run --flavor Runner-stg -t lib/main_stg.dart

run-prod:
	flutter run --flavor Runner-prod -t lib/main_prod.dart

build-ios-dev:
	flutter build ipa --flavor Runner-dev -t lib/main_dev.dart

build-ios-prod:
	flutter build ipa --flavor Runner-prod -t lib/main_prod.dart

build-android-dev:
	flutter build appbundle --flavor dev -t lib/main_dev.dart

build-android-prod:
	flutter build appbundle --flavor prod -t lib/main_prod.dart

clean:
	flutter clean && flutter pub get

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
