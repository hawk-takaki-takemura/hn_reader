.PHONY: deploy-config-dev deploy-config-stg deploy-config-prod
.PHONY: fetch-config-dev fetch-config-stg fetch-config-prod
.PHONY: run-dev run-stg run-prod build-ios-dev build-ios-prod build-android-dev build-android-prod clean

# .env を使う場合のみ dart-define-from-file を付与します。
# （Claude キーはクライアントで保持しません）

run-dev:
	@if [ -f .env ]; then \
		flutter run \
			--flavor Runner-dev \
			-t lib/main_dev.dart \
			--dart-define-from-file=.env; \
	else \
		flutter run \
			--flavor Runner-dev \
			-t lib/main_dev.dart; \
	fi

run-stg:
	@if [ -f .env ]; then \
		flutter run \
			--flavor Runner-stg \
			-t lib/main_stg.dart \
			--dart-define-from-file=.env; \
	else \
		flutter run \
			--flavor Runner-stg \
			-t lib/main_stg.dart; \
	fi

run-prod:
	@if [ -f .env ]; then \
		flutter run \
			--flavor Runner-prod \
			-t lib/main_prod.dart \
			--dart-define-from-file=.env; \
	else \
		flutter run \
			--flavor Runner-prod \
			-t lib/main_prod.dart; \
	fi

build-ios-dev:
	flutter build ipa \
		--flavor Runner-dev \
		-t lib/main_dev.dart \
		--dart-define-from-file=.env

build-ios-prod:
	flutter build ipa \
		--flavor Runner-prod \
		-t lib/main_prod.dart \
		--dart-define-from-file=.env

build-android-dev:
	flutter build appbundle \
		--flavor dev \
		-t lib/main_dev.dart \
		--dart-define-from-file=.env

build-android-prod:
	flutter build appbundle \
		--flavor prod \
		-t lib/main_prod.dart \
		--dart-define-from-file=.env

clean:
	flutter clean && flutter pub get

# Remote Config デプロイ（Firebase CLI 15 では remoteconfig:update が無いため deploy を使用）
deploy-config-dev:
	firebase deploy --only remoteconfig --project yomi-dev -c firebase.rc.dev.json

deploy-config-stg:
	firebase deploy --only remoteconfig --project yomi-stg -c firebase.rc.stg.json

deploy-config-prod:
	firebase deploy --only remoteconfig --project yomi-prod -c firebase.rc.prod.json

# 現在の設定を取得（確認用）
fetch-config-dev:
	firebase remoteconfig:get --project yomi-dev -o firebase/remote_config/dev_current.json

fetch-config-stg:
	firebase remoteconfig:get --project yomi-stg -o firebase/remote_config/stg_current.json

fetch-config-prod:
	firebase remoteconfig:get --project yomi-prod -o firebase/remote_config/prod_current.json
