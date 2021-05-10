// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';

import 'package:google_mobile_ads/src/ad_instance_manager.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GoogleMobileAds', () {
    final List<MethodCall> log = <MethodCall>[];
    final MessageCodec<dynamic> codec = AdMessageCodec();

    setUp(() async {
      log.clear();
      instanceManager =
          AdInstanceManager('plugins.flutter.io/google_mobile_ads');
      instanceManager.channel
          .setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'MobileAds#updateRequestConfiguration':
          case 'MobileAds#setSameAppKeyEnabled':
          case 'loadBannerAd':
          case 'loadNativeAd':
          case 'showAdWithoutView':
          case 'disposeAd':
          case 'loadRewardedAd':
          case 'loadInterstitialAd':
          case 'loadAdManagerBannerAd':
            return Future<void>.value();
          default:
            assert(false);
            return null;
        }
      });
    });

    test('updateRequestConfiguration', () async {
      final RequestConfiguration requestConfiguration = RequestConfiguration(
        maxAdContentRating: MaxAdContentRating.ma,
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.yes,
        testDeviceIds: <String>['test-device-id'],
      );
      await instanceManager.updateRequestConfiguration(requestConfiguration);
      expect(log, <Matcher>[
        isMethodCall('MobileAds#updateRequestConfiguration',
            arguments: <String, dynamic>{
              'maxAdContentRating': MaxAdContentRating.ma,
              'tagForChildDirectedTreatment': TagForChildDirectedTreatment.yes,
              'tagForUnderAgeOfConsent': TagForUnderAgeOfConsent.yes,
              'testDeviceIds': <String>['test-device-id'],
            })
      ]);
    });


    test('setSameAppKeyEnabled', () async {
      await instanceManager.setSameAppKeyEnabled(true);

      expect(log, <Matcher>[
        isMethodCall('MobileAds#setSameAppKeyEnabled',
            arguments: <String, dynamic>{
              'isEnabled': true,
            })
      ]);

      await instanceManager.setSameAppKeyEnabled(false);

      expect(log, <Matcher>[
        isMethodCall('MobileAds#setSameAppKeyEnabled',
            arguments: <String, dynamic>{
              'isEnabled': true,
            }),
        isMethodCall('MobileAds#setSameAppKeyEnabled',
            arguments: <String, dynamic>{
              'isEnabled': false,
            })
      ]);
    });

    test('load banner', () async {
      final BannerAd banner = BannerAd(
        adUnitId: BannerAd.testAdUnitId,
        size: AdSize.banner,
        listener: BannerAdListener(),
        request: AdRequest(),
      );

      await banner.load();
      expect(log, <Matcher>[
        isMethodCall('loadBannerAd', arguments: <String, dynamic>{
          'adId': 0,
          'adUnitId': BannerAd.testAdUnitId,
          'request': banner.request,
          'size': AdSize.banner,
        })
      ]);

      expect(instanceManager.adFor(0), isNotNull);
    });

    test('dispose banner', () async {
      final BannerAd banner = BannerAd(
        adUnitId: BannerAd.testAdUnitId,
        size: AdSize.banner,
        listener: BannerAdListener(),
        request: AdRequest(),
      );

      await banner.load();
      log.clear();
      await banner.dispose();
      expect(log, <Matcher>[
        isMethodCall('disposeAd', arguments: <String, dynamic>{
          'adId': 0,
        })
      ]);

      expect(instanceManager.adFor(0), isNull);
      expect(instanceManager.adIdFor(banner), isNull);
    });

    test('calling dispose without awaiting load', () {
      final BannerAd banner = BannerAd(
        adUnitId: BannerAd.testAdUnitId,
        size: AdSize.banner,
        listener: BannerAdListener(),
        request: AdRequest(),
      );

      banner.load();
      banner.dispose();
      expect(instanceManager.adFor(0), isNull);
      expect(instanceManager.adIdFor(banner), isNull);
    });

    test('load native', () async {
      final Map<String, Object> options = <String, Object>{'a': 1, 'b': 2};

      final NativeAd native = NativeAd(
        adUnitId: NativeAd.testAdUnitId,
        factoryId: '0',
        customOptions: options,
        listener: NativeAdListener(),
        request: AdRequest(),
      );

      await native.load();
      expect(log, <Matcher>[
        isMethodCall('loadNativeAd', arguments: <String, dynamic>{
          'adId': 0,
          'adUnitId': NativeAd.testAdUnitId,
          'request': native.request,
          'adManagerRequest': null,
          'factoryId': '0',
          'customOptions': options,
        })
      ]);

      expect(instanceManager.adFor(0), isNotNull);
    });

    test('load native with $AdManagerAdRequest', () async {
      final Map<String, Object> options = <String, Object>{'a': 1, 'b': 2};

      final NativeAd native = NativeAd.fromAdManagerRequest(
        adUnitId: 'test-id',
        factoryId: '0',
        customOptions: options,
        listener: NativeAdListener(),
        adManagerRequest: AdManagerAdRequest(),
      );

      await native.load();
      expect(log, <Matcher>[
        isMethodCall('loadNativeAd', arguments: <String, dynamic>{
          'adId': 0,
          'adUnitId': 'test-id',
          'request': null,
          'adManagerRequest': native.adManagerRequest,
          'factoryId': '0',
          'customOptions': options,
        })
      ]);

      expect(instanceManager.adFor(0), isNotNull);
    });

    testWidgets('build ad widget', (WidgetTester tester) async {
      final NativeAd native = NativeAd(
        adUnitId: NativeAd.testAdUnitId,
        factoryId: '0',
        listener: NativeAdListener(),
        request: AdRequest(),
      );

      await native.load();

      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            AdWidget widget = AdWidget(ad: native);
            Widget buildWidget = widget.createElement().build();
            expect(buildWidget, isA<PlatformViewLink>());
            return widget;
          },
        ),
      );

      await native.dispose();
    });

    testWidgets('build ad widget', (WidgetTester tester) async {
      final NativeAd native = NativeAd(
        adUnitId: NativeAd.testAdUnitId,
        factoryId: '0',
        listener: NativeAdListener(),
        request: AdRequest(),
      );

      await native.load();

      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            AdWidget widget = AdWidget(ad: native);
            Widget buildWidget = widget.createElement().build();
            expect(buildWidget, isA<PlatformViewLink>());
            return widget;
          },
        ),
      );

      await native.dispose();
    });

    testWidgets('warns when ad has not been loaded',
        (WidgetTester tester) async {
      final NativeAd ad = NativeAd(
        adUnitId: NativeAd.testAdUnitId,
        factoryId: '0',
        listener: NativeAdListener(),
        request: AdRequest(),
      );

      try {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                children: <Widget>[
                  AdWidget(ad: ad),
                ],
              ),
            ),
          ),
        );
      } finally {
        dynamic exception = tester.takeException();
        expect(exception, isA<FlutterError>());
        expect(
            (exception as FlutterError).toStringDeep(),
            'FlutterError\n'
            '   AdWidget requires Ad.load to be called before AdWidget is\n'
            '   inserted into the tree\n'
            '   Parameter ad is not loaded. Call Ad.load before AdWidget is\n'
            '   inserted into the tree.\n');
      }
    });

    testWidgets('warns when ad object is reused', (WidgetTester tester) async {
      final NativeAd ad = NativeAd(
        adUnitId: NativeAd.testAdUnitId,
        factoryId: '0',
        listener: NativeAdListener(),
        request: AdRequest(),
      );

      await ad.load();

      try {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                children: <Widget>[
                  AdWidget(ad: ad),
                  AdWidget(ad: ad),
                ],
              ),
            ),
          ),
        );
      } finally {
        dynamic exception = tester.takeException();
        expect(exception, isA<FlutterError>());
        expect(
            (exception as FlutterError).toStringDeep(),
            'FlutterError\n'
            '   This AdWidget is already in the Widget tree\n'
            '   If you placed this AdWidget in a list, make sure you create a new\n'
            '   instance in the builder function with a unique ad object.\n'
            '   Make sure you are not using the same ad object in more than one\n'
            '   AdWidget.\n'
            '');
      }
    });

    testWidgets('warns when the widget is reused', (WidgetTester tester) async {
      final NativeAd ad = NativeAd(
        adUnitId: NativeAd.testAdUnitId,
        factoryId: '0',
        listener: NativeAdListener(),
        request: AdRequest(),
      );

      await ad.load();

      final AdWidget widget = AdWidget(ad: ad);
      try {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                children: <Widget>[
                  widget,
                  widget,
                ],
              ),
            ),
          ),
        );
      } finally {
        dynamic exception = tester.takeException();
        expect(exception, isA<FlutterError>());
        expect(
            (exception as FlutterError).toStringDeep(),
            'FlutterError\n'
            '   This AdWidget is already in the Widget tree\n'
            '   If you placed this AdWidget in a list, make sure you create a new\n'
            '   instance in the builder function with a unique ad object.\n'
            '   Make sure you are not using the same ad object in more than one\n'
            '   AdWidget.\n'
            '');
      }
    });

    testWidgets(
        'ad objects can be reused if the widget holding the object is disposed',
        (WidgetTester tester) async {
      final NativeAd ad = NativeAd(
        adUnitId: NativeAd.testAdUnitId,
        factoryId: '0',
        listener: NativeAdListener(),
        request: AdRequest(),
      );
      await ad.load();
      final AdWidget widget = AdWidget(ad: ad);
      try {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              width: 100,
              height: 100,
              child: widget,
            ),
          ),
        );

        await tester.pumpWidget(Container());

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              width: 100,
              height: 100,
              child: widget,
            ),
          ),
        );
      } finally {
        expect(tester.takeException(), isNull);
      }
    });

    test('load rewarded', () async {
      final RewardedAd rewarded = RewardedAd(
          adUnitId: RewardedAd.testAdUnitId,
          listener: RewardedAdListener(),
          request: AdRequest(),
          serverSideVerificationOptions: ServerSideVerificationOptions(
            userId: 'test-user-id',
            customData: 'test-custom-data',
          ));

      await rewarded.load();

      expect(log, <Matcher>[
        isMethodCall('loadRewardedAd', arguments: <String, dynamic>{
          'adId': 0,
          'adUnitId': RewardedAd.testAdUnitId,
          'request': rewarded.request,
          'adManagerRequest': null,
          'serverSideVerificationOptions':
              rewarded.serverSideVerificationOptions,
        }),
      ]);

      expect(instanceManager.adFor(0), isNotNull);
    });

    test('load rewarded with $AdManagerAdRequest', () async {
      final RewardedAd rewarded = RewardedAd.fromAdManagerRequest(
        adUnitId: RewardedAd.testAdUnitId,
        listener: RewardedAdListener(),
        adManagerRequest: AdManagerAdRequest(),
        serverSideVerificationOptions: ServerSideVerificationOptions(
          userId: 'test-user-id',
          customData: 'test-custom-data',
        ),
      );

      await rewarded.load();

      expect(log, <Matcher>[
        isMethodCall('loadRewardedAd', arguments: <String, dynamic>{
          'adId': 0,
          'adUnitId': RewardedAd.testAdUnitId,
          'request': null,
          'adManagerRequest': rewarded.adManagerRequest,
          'serverSideVerificationOptions':
              rewarded.serverSideVerificationOptions,
        }),
      ]);

      expect(instanceManager.adFor(0), isNotNull);
    });

    test('load interstitial', () async {
      final InterstitialAd interstitial = InterstitialAd(
        adUnitId: InterstitialAd.testAdUnitId,
        listener: InterstitialAdListener(),
        request: AdRequest(),
      );

      await interstitial.load();
      expect(log, <Matcher>[
        isMethodCall('loadInterstitialAd', arguments: <String, dynamic>{
          'adId': 0,
          'adUnitId': InterstitialAd.testAdUnitId,
          'request': interstitial.request,
        })
      ]);

      expect(instanceManager.adFor(0), isNotNull);
    });

    test('load ad manager banner', () async {
      final AdManagerBannerAd banner = AdManagerBannerAd(
        adUnitId: 'testId',
        sizes: <AdSize>[AdSize.largeBanner],
        listener: AdManagerBannerAdListener(),
        request: AdManagerAdRequest(),
      );

      await banner.load();
      expect(log, <Matcher>[
        isMethodCall('loadAdManagerBannerAd', arguments: <String, dynamic>{
          'adId': 0,
          'adUnitId': 'testId',
          'sizes': <AdSize>[AdSize.largeBanner],
          'request': AdManagerAdRequest(),
        })
      ]);

      expect(instanceManager.adFor(0), banner);
      expect(instanceManager.adIdFor(banner), 0);
    });

    test('onAdLoaded', () async {
      final Completer<Ad> adEventCompleter = Completer<Ad>();

      final BannerAd banner = BannerAd(
        adUnitId: BannerAd.testAdUnitId,
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) => adEventCompleter.complete(ad),
        ),
        request: AdRequest(),
      );

      await banner.load();

      final MethodCall methodCall = MethodCall('onAdEvent', <dynamic, dynamic>{
        'adId': 0,
        'eventName': 'onAdLoaded',
      });

      final ByteData data =
          instanceManager.channel.codec.encodeMethodCall(methodCall);

      await instanceManager.channel.binaryMessenger.handlePlatformMessage(
        'plugins.flutter.io/google_mobile_ads',
        data,
        (ByteData? data) {},
      );

      expect(adEventCompleter.future, completion(banner));
    });

    test('onAdFailedToLoad', () async {
      final Completer<List<dynamic>> resultsCompleter =
          Completer<List<dynamic>>();

      final BannerAd banner = BannerAd(
        adUnitId: BannerAd.testAdUnitId,
        size: AdSize.banner,
        listener: BannerAdListener(
            onAdFailedToLoad: (Ad ad, LoadAdError error) =>
                resultsCompleter.complete(<dynamic>[ad, error])),
        request: AdRequest(),
      );

      await banner.load();
      ResponseInfo responseInfo = ResponseInfo(
          responseId: 'id', mediationAdapterClassName: 'className');

      final MethodCall methodCall = MethodCall('onAdEvent', <dynamic, dynamic>{
        'adId': 0,
        'eventName': 'onAdFailedToLoad',
        'loadAdError': LoadAdError(1, 'domain', 'message', responseInfo),
      });

      final ByteData data =
          instanceManager.channel.codec.encodeMethodCall(methodCall);

      await instanceManager.channel.binaryMessenger.handlePlatformMessage(
        'plugins.flutter.io/google_mobile_ads',
        data,
        (ByteData? data) {},
      );

      final List<dynamic> results = await resultsCompleter.future;
      expect(results[0], banner);
      expect(results[1].code, 1);
      expect(results[1].domain, 'domain');
      expect(results[1].message, 'message');
      expect(results[1].responseInfo.responseId, responseInfo.responseId);
      expect(results[1].responseInfo.mediationAdapterClassName,
          responseInfo.mediationAdapterClassName);
    });

    test('onNativeAdClicked', () async {
      final Completer<Ad> adEventCompleter = Completer<Ad>();

      final NativeAd native = NativeAd(
        adUnitId: NativeAd.testAdUnitId,
        factoryId: 'testId',
        listener: NativeAdListener(
            onNativeAdClicked: (Ad ad) => adEventCompleter.complete(ad)),
        request: AdRequest(),
      );

      await native.load();

      final MethodCall methodCall = MethodCall('onAdEvent',
          <dynamic, dynamic>{'adId': 0, 'eventName': 'onNativeAdClicked'});

      final ByteData data =
          instanceManager.channel.codec.encodeMethodCall(methodCall);

      await instanceManager.channel.binaryMessenger.handlePlatformMessage(
        'plugins.flutter.io/google_mobile_ads',
        data,
        (ByteData? data) {},
      );

      expect(adEventCompleter.future, completion(native));
    });

    test('onNativeAdImpression', () async {
      final Completer<Ad> adEventCompleter = Completer<Ad>();

      final NativeAd native = NativeAd(
        adUnitId: NativeAd.testAdUnitId,
        factoryId: 'testId',
        listener: NativeAdListener(
            onAdImpression: (Ad ad) => adEventCompleter.complete(ad)),
        request: AdRequest(),
      );

      await native.load();

      final MethodCall methodCall = MethodCall('onAdEvent',
          <dynamic, dynamic>{'adId': 0, 'eventName': 'onAdImpression'});

      final ByteData data =
          instanceManager.channel.codec.encodeMethodCall(methodCall);

      await instanceManager.channel.binaryMessenger.handlePlatformMessage(
        'plugins.flutter.io/google_mobile_ads',
        data,
        (ByteData? data) {},
      );

      expect(adEventCompleter.future, completion(native));
    });

    test('onAdOpened', () async {
      final Completer<Ad> adEventCompleter = Completer<Ad>();

      final BannerAd banner = BannerAd(
        adUnitId: BannerAd.testAdUnitId,
        size: AdSize.banner,
        listener: BannerAdListener(
            onAdOpened: (Ad ad) => adEventCompleter.complete(ad)),
        request: AdRequest(),
      );

      await banner.load();

      final MethodCall methodCall = MethodCall('onAdEvent',
          <dynamic, dynamic>{'adId': 0, 'eventName': 'onAdOpened'});

      final ByteData data =
          instanceManager.channel.codec.encodeMethodCall(methodCall);

      await instanceManager.channel.binaryMessenger.handlePlatformMessage(
        'plugins.flutter.io/google_mobile_ads',
        data,
        (ByteData? data) {},
      );

      expect(adEventCompleter.future, completion(banner));
    });

    test('onAdClosed', () async {
      final Completer<Ad> adEventCompleter = Completer<Ad>();

      final BannerAd banner = BannerAd(
        adUnitId: BannerAd.testAdUnitId,
        size: AdSize.banner,
        listener: BannerAdListener(
            onAdClosed: (Ad ad) => adEventCompleter.complete(ad)),
        request: AdRequest(),
      );

      await banner.load();

      final MethodCall methodCall = MethodCall('onAdEvent',
          <dynamic, dynamic>{'adId': 0, 'eventName': 'onAdClosed'});

      final ByteData data =
          instanceManager.channel.codec.encodeMethodCall(methodCall);

      await instanceManager.channel.binaryMessenger.handlePlatformMessage(
        'plugins.flutter.io/google_mobile_ads',
        data,
        (ByteData? data) {},
      );

      expect(adEventCompleter.future, completion(banner));
    });

    test('onRewardedAdUserEarnedReward', () async {
      final Completer<List<dynamic>> resultCompleter =
          Completer<List<dynamic>>();

      final RewardedAd rewardedAd = RewardedAd(
        adUnitId: BannerAd.testAdUnitId,
        listener: RewardedAdListener(
          onRewardedAdUserEarnedReward: (RewardedAd ad, RewardItem item) =>
              resultCompleter.complete(<Object>[ad, item]),
        ),
        request: AdRequest(),
      );

      await rewardedAd.load();

      final MethodCall methodCall = MethodCall('onAdEvent', <dynamic, dynamic>{
        'adId': 0,
        'eventName': 'onRewardedAdUserEarnedReward',
        'rewardItem': RewardItem(1, 'one'),
      });

      final ByteData data =
          instanceManager.channel.codec.encodeMethodCall(methodCall);

      await instanceManager.channel.binaryMessenger.handlePlatformMessage(
        'plugins.flutter.io/google_mobile_ads',
        data,
        (ByteData? data) {},
      );

      final List<dynamic> result = await resultCompleter.future;
      expect(result[0], rewardedAd);
      expect(result[1].amount, 1);
      expect(result[1].type, 'one');
    });

    test('show $AdWithoutView', () {
      final InterstitialAd ad = InterstitialAd(
        adUnitId: 'testId',
        request: AdRequest(),
        listener: InterstitialAdListener(),
      );

      ad.load();
      log.clear();
      ad.show();
      expect(log, <Matcher>[
        isMethodCall('showAdWithoutView', arguments: <dynamic, dynamic>{
          'adId': 0,
        })
      ]);
    });

    test('show $AdWithoutView throws $AssertionError', () {
      final InterstitialAd ad = InterstitialAd(
        adUnitId: 'testId',
        request: AdRequest(),
        listener: InterstitialAdListener(),
      );

      expect(() => instanceManager.showAdWithoutView(ad), throwsAssertionError);
    });

    test('encode/decode AdSize', () async {
      final ByteData byteData = codec.encodeMessage(AdSize.banner)!;
      expect(codec.decodeMessage(byteData), AdSize.banner);
    });

    test('encode/decode AdRequest', () async {
      final AdRequest adRequest = AdRequest(
          keywords: <String>['1', '2', '3'],
          contentUrl: 'contentUrl',
          nonPersonalizedAds: false);

      final ByteData byteData = codec.encodeMessage(adRequest)!;
      expect(codec.decodeMessage(byteData), adRequest);
    });

    test('encode/decode $LoadAdError', () async {
      final ResponseInfo responseInfo = ResponseInfo(
        responseId: 'id',
        mediationAdapterClassName: 'class',
      );
      final ByteData byteData = codec.encodeMessage(
        LoadAdError(1, 'domain', 'message', responseInfo),
      )!;
      final LoadAdError error = codec.decodeMessage(byteData);
      expect(error.code, 1);
      expect(error.domain, 'domain');
      expect(error.message, 'message');
      expect(error.responseInfo?.responseId, responseInfo.responseId);
      expect(error.responseInfo?.mediationAdapterClassName,
          responseInfo.mediationAdapterClassName);
    });

    test('encode/decode $RewardItem', () async {
      final ByteData byteData = codec.encodeMessage(RewardItem(1, 'type'))!;

      final RewardItem result = codec.decodeMessage(byteData);
      expect(result.amount, 1);
      expect(result.type, 'type');
    });

    test('encode/decode $AdManagerAdRequest', () async {
      final ByteData byteData = codec.encodeMessage(AdManagerAdRequest(
        keywords: <String>['who'],
        contentUrl: 'dat',
        customTargeting: <String, String>{'boy': 'who'},
        customTargetingLists: <String, List<String>>{
          'him': <String>['is']
        },
        nonPersonalizedAds: true,
      ))!;

      expect(
        codec.decodeMessage(byteData),
        AdManagerAdRequest(
          keywords: <String>['who'],
          contentUrl: 'dat',
          customTargeting: <String, String>{'boy': 'who'},
          customTargetingLists: <String, List<String>>{
            'him': <String>['is'],
          },
          nonPersonalizedAds: true,
        ),
      );
    });

    test('isLoaded', () async {
      final Completer<Ad> adEventCompleter = Completer<Ad>();

      final BannerAd banner = BannerAd(
        adUnitId: BannerAd.testAdUnitId,
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) => adEventCompleter.complete(ad),
        ),
        request: AdRequest(),
      );

      await banner.load();

      expect(banner.isLoaded(), completion(false));

      final MethodCall methodCall = MethodCall('onAdEvent', <dynamic, dynamic>{
        'adId': 0,
        'eventName': 'onAdLoaded',
      });

      final ByteData data =
          instanceManager.channel.codec.encodeMethodCall(methodCall);

      await instanceManager.channel.binaryMessenger.handlePlatformMessage(
        'plugins.flutter.io/google_mobile_ads',
        data,
        (ByteData? data) {},
      );

      expect(banner.isLoaded(), completion(true));

      await banner.dispose();
      expect(banner.isLoaded(), completion(false));
    });
  });
}
