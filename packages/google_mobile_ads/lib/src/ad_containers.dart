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

// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'ad_instance_manager.dart';
import 'ad_listeners.dart';

/// Error information about why an ad load operation failed.
class AdError {
  /// Default constructor for [LoadAdError].
  AdError(this.code, this.domain, this.message);

  /// Unique code to identify the error.
  ///
  /// See links below for possible error codes:
  /// Android:
  ///   https://developers.google.com/android/reference/com/google/android/gms/ads/AdRequest#constant-summary
  /// Ios:
  ///   https://developers.google.com/admob/ios/api/reference/Enums/GADErrorCode
  final int code;

  /// The domain from which the error came.
  final String domain;

  /// A message detailing the error.
  ///
  /// For example "Account not approved yet". See
  /// https://support.google.com/admob/answer/9905175 for explanations of
  /// common errors.
  final String message;

  @override
  String toString() {
    return '$runtimeType(code: $code, domain: $domain, message: $message)';
  }
}

/// Contains information about the loaded ad or ad request.
///
/// For debugging and logging purposes.
class ResponseInfo {
  /// Default constructor for [ResponseInfo].
  const ResponseInfo({this.responseId, this.mediationAdapterClassName});

  /// An identifier for the loaded ad.
  final String? responseId;

  /// The mediation adapter class name of the ad network that loaded the ad.
  final String? mediationAdapterClassName;

  @override
  String toString() {
    return '$runtimeType(responseId: $responseId, '
        'mediationAdapterClassName: $mediationAdapterClassName)';
  }
}

/// Represents errors that occur when loading an ad.
class LoadAdError extends AdError {
  /// Default constructor for [LoadAdError].
  LoadAdError(int code, String domain, String message, this.responseInfo)
      : super(code, domain, message);

  /// The [ResponseInfo] for the error.
  final ResponseInfo? responseInfo;

  @override
  String toString() {
    return '$runtimeType(code: $code, domain: $domain, message: $message'
        ', responseInfo: $responseInfo)';
  }
}

/// Targeting info per the AdMob API.
///
/// This class's properties mirror the native AdRequest API. See for example:
/// [AdRequest.Builder for Android](https://developers.google.com/android/reference/com/google/android/gms/ads/AdRequest.Builder).
class AdRequest {
  /// Default constructor for [AdRequest].
  const AdRequest({
    this.keywords,
    this.contentUrl,
    this.nonPersonalizedAds,
  });

  /// Words or phrases describing the current user activity.
  final List<String>? keywords;

  /// URL string for a webpage whose content matches the app’s primary content.
  ///
  /// This webpage content is used for targeting and brand safety purposes.
  final String? contentUrl;

  /// Non-personalized ads are ads that are not based on a user’s past behavior.
  ///
  /// For more information:
  /// https://support.google.com/admob/answer/7676680?hl=en
  final bool? nonPersonalizedAds;

  @override
  bool operator ==(Object other) {
    return other is AdRequest &&
        listEquals<String>(keywords, other.keywords) &&
        contentUrl == other.contentUrl &&
        nonPersonalizedAds == other.nonPersonalizedAds;
  }
}

/// Targeting info per the Ad Manager API.
class AdManagerAdRequest {
  /// Default constructor for [AdManagerAdRequest].
  const AdManagerAdRequest({
    this.keywords,
    this.contentUrl,
    this.customTargeting,
    this.customTargetingLists,
    this.nonPersonalizedAds,
  });

  /// Words or phrases describing the current user activity.
  final List<String>? keywords;

  /// URL string for a webpage whose content matches the app’s primary content.
  ///
  /// This webpage content is used for targeting and brand safety purposes.
  final String? contentUrl;

  /// Key-value pairs used for custom targeting.
  final Map<String, String>? customTargeting;

  /// Key-value pairs used for custom targeting.
  final Map<String, List<String>>? customTargetingLists;

  /// Non-personalized ads are ads that are not based on a user’s past behavior.
  ///
  /// For more information:
  /// https://support.google.com/admanager/answer/9005435?hl=en
  final bool? nonPersonalizedAds;

  @override
  bool operator ==(Object other) {
    return other is AdManagerAdRequest &&
        listEquals<String>(keywords, other.keywords) &&
        contentUrl == other.contentUrl &&
        mapEquals<String, String>(customTargeting, other.customTargeting) &&
        customTargetingLists.toString() ==
            other.customTargetingLists.toString() &&
        nonPersonalizedAds == other.nonPersonalizedAds;
  }
}

/// [AdSize] represents the size of a banner ad.
///
/// There are six sizes available, which are the same for both iOS and Android.
/// See the guides for banners on [Android](https://developers.google.com/admob/android/banner#banner_sizes)
/// and [iOS](https://developers.google.com/admob/ios/banner#banner_sizes) for
/// additional details.
class AdSize {
  /// Default constructor for [AdSize].
  const AdSize({
    required this.width,
    required this.height,
  });

  /// The vertical span of an ad.
  final int height;

  /// The horizontal span of an ad.
  final int width;

  /// The standard banner (320x50) size.
  static const AdSize banner = AdSize(width: 320, height: 50);

  /// The large banner (320x100) size.
  static const AdSize largeBanner = AdSize(width: 320, height: 100);

  /// The medium rectangle (300x250) size.
  static const AdSize mediumRectangle = AdSize(width: 300, height: 250);

  /// The full banner (468x60) size.
  static const AdSize fullBanner = AdSize(width: 468, height: 60);

  /// The leaderboard (728x90) size.
  static const AdSize leaderboard = AdSize(width: 728, height: 90);

  /// Ad units that render screen-width banner ads on any screen size across different devices in either [Orientation].
  static AdSize getSmartBanner(Orientation orientation) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return smartBanner;
    } else if (defaultTargetPlatform == TargetPlatform.iOS &&
        orientation == Orientation.portrait) {
      return smartBannerPortrait;
    } else if (defaultTargetPlatform == TargetPlatform.iOS &&
        orientation == Orientation.landscape) {
      return smartBannerLandscape;
    }

    throw AssertionError('Only supported on Android and iOS.');
  }

  /// Ad units that render screen-width banner ads on any screen size across different devices in either orientation on Android.
  // Android expects a width and height of -1 represents a smart banner.
  static AdSize get smartBanner {
    assert(defaultTargetPlatform == TargetPlatform.android);
    return AdSize(width: -1, height: -1);
  }

  /// Ad units that render screen-width banner ads on any screen size across different devices in portrait on iOS.
  // iOS expects a width of -1 and a height of -2 represents a portrait smart banner.
  static AdSize get smartBannerPortrait {
    assert(defaultTargetPlatform == TargetPlatform.iOS);
    return AdSize(width: -1, height: -2);
  }

  /// Ad units that render screen-width banner ads on any screen size across different devices in landscape on iOS.
  // iOS expects a width of -1 and a height of -2 represents a landscape smart banner.
  static AdSize get smartBannerLandscape {
    assert(defaultTargetPlatform == TargetPlatform.iOS);
    return AdSize(width: -1, height: -3);
  }

  @override
  bool operator ==(Object other) {
    return other is AdSize && width == other.width && height == other.height;
  }
}


/// The base class for all ads.
///
/// A valid [adUnitId] is required.
abstract class Ad {
  /// Default constructor, used by subclasses.
  const Ad({required this.adUnitId});

  /// Identifies the source of [Ad]s for your application.
  ///
  /// For testing use a [sample ad unit](https://developers.google.com/admob/ios/test-ads#sample_ad_units).
  final String adUnitId;

  /// Free the plugin resources associated with this ad.
  Future<void> dispose() {
    return instanceManager.disposeAd(this);
  }

  /// Whether this [Ad.load] has been called for this [Ad] and [AdListener.onAdLoaded] callback has been called.
  Future<bool> isLoaded() async {
    return instanceManager.adIdFor(this) != null &&
        instanceManager.onAdLoadedCalled(this);
  }
}

/// Base class for mobile [Ad] that has an in-line view.
///
/// A valid [adUnitId] and [size] are required.
abstract class AdWithView extends Ad {
  /// Default constructor, used by subclasses.
  const AdWithView({required String adUnitId, required this.listener})
      : super(adUnitId: adUnitId);

  /// The [AdWithViewListener] for the ad.
  final AdWithViewListener listener;

  /// Start loading this ad.
  ///
  /// Loading callbacks are sent to this [Ad]'s [listener].
  Future<void> load();

}

/// An [Ad] that is overlaid on top of the UI.
abstract class AdWithoutView extends Ad {
  /// Default constructor used by subclasses.
  AdWithoutView(
      {required String adUnitId})
      : super(adUnitId: adUnitId);
}

/// Displays an [Ad] as a Flutter widget.
///
/// This widget takes ads inheriting from [AdWithView]
/// (e.g. [BannerAd] and [NativeAd]) and allows them to be added to the Flutter
/// widget tree.
///
/// Must call `load()` first before showing the widget. Otherwise, a
/// [PlatformException] will be thrown.
class AdWidget extends StatefulWidget {
  /// Default constructor for [AdWidget].
  ///
  /// [ad] must be loaded before this is added to the widget tree.
  const AdWidget({Key? key, required this.ad}) : super(key: key);

  /// Ad to be displayed as a widget.
  final AdWithView ad;

  @override
  _AdWidgetState createState() => _AdWidgetState();
}

class _AdWidgetState extends State<AdWidget> {
  bool _adIdAlreadyMounted = false;
  bool _adLoadNotCalled = false;

  @override
  void initState() {
    super.initState();
    final int? adId = instanceManager.adIdFor(widget.ad);
    if (adId != null) {
      if (instanceManager.isWidgetAdIdMounted(adId)) {
        _adIdAlreadyMounted = true;
      }
      instanceManager.mountWidgetAdId(adId);
    } else {
      _adLoadNotCalled = true;
    }
  }

  @override
  void dispose() {
    super.dispose();
    final int? adId = instanceManager.adIdFor(widget.ad);
    if (adId != null) {
      instanceManager.unmountWidgetAdId(adId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_adIdAlreadyMounted) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('This AdWidget is already in the Widget tree'),
        ErrorHint(
            'If you placed this AdWidget in a list, make sure you create a new instance '
            'in the builder function with a unique ad object.'),
        ErrorHint(
            'Make sure you are not using the same ad object in more than one AdWidget.'),
      ]);
    }
    if (_adLoadNotCalled) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary(
            'AdWidget requires Ad.load to be called before AdWidget is inserted into the tree'),
        ErrorHint(
            'Parameter ad is not loaded. Call Ad.load before AdWidget is inserted into the tree.'),
      ]);
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return PlatformViewLink(
        viewType: '${instanceManager.channel.name}/ad_widget',
        surfaceFactory:
            (BuildContext context, PlatformViewController controller) {
          return AndroidViewSurface(
            controller: controller as AndroidViewController,
            gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          );
        },
        onCreatePlatformView: (PlatformViewCreationParams params) {
          return PlatformViewsService.initSurfaceAndroidView(
            id: params.id,
            viewType: '${instanceManager.channel.name}/ad_widget',
            layoutDirection: TextDirection.ltr,
            creationParams: instanceManager.adIdFor(widget.ad),
            creationParamsCodec: StandardMessageCodec(),
          )
            ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
            ..create();
        },
      );
    }

    return UiKitView(
      viewType: '${instanceManager.channel.name}/ad_widget',
      creationParams: instanceManager.adIdFor(widget.ad),
      creationParamsCodec: StandardMessageCodec(),
    );
  }
}

/// A banner ad.
///
/// This ad can either be overlaid on top of all flutter widgets as a static
/// view or displayed as a typical Flutter widget. To display as a widget,
/// instantiate an [AdWidget] with this as a parameter.
class BannerAd extends AdWithView {
  /// Creates a [BannerAd].
  ///
  /// A valid [adUnitId], nonnull [listener], and nonnull request is required.
  BannerAd({
    required this.size,
    required String adUnitId,
    required this.listener,
    required this.request,
  }) : super(adUnitId: adUnitId, listener: listener);

  /// Targeting information used to fetch an [Ad].
  final AdRequest request;

  /// Represents the size of a banner ad.
  ///
  /// There are six sizes available, which are the same for both iOS and Android.
  /// See the guides for banners on Android](https://developers.google.com/admob/android/banner#banner_sizes)
  /// and [iOS](https://developers.google.com/admob/ios/banner#banner_sizes) for additional details.
  final AdSize size;

  /// A listener for receiving events in the ad lifecycle.
  @override
  final BannerAdListener listener;

  /// {@template google_mobile_ads.testAdUnitId}
  /// A platform-specific AdMob test ad unit ID.
  ///
  /// This ad unit has been specially configured to always return test ads, and
  /// developers are encouraged to use it while building and testing their apps.
  /// {@endtemplate}
  /// {@macro google_mobile_ads.testAdUnitId}
  static final String testAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-3940256099942544/2934735716';

  @override
  Future<void> load() async {
    await instanceManager.loadBannerAd(this);
  }
}

/// A banner ad displayed with Google Ad Manager.
///
/// This ad can either be overlaid on top of all flutter widgets by passing this
/// to an [AdWidget] after calling [load].
class AdManagerBannerAd extends AdWithView {
  /// Default constructor for [AdManagerBannerAd].
  ///
  /// [sizes], [adUnitId], [listener], and [request] are all required values.
  AdManagerBannerAd({
    required this.sizes,
    required String adUnitId,
    required this.listener,
    required this.request,
  })  : assert(sizes.isNotEmpty),
        super(adUnitId: adUnitId, listener: listener);

  /// Targeting information used to fetch an [Ad].
  final AdManagerAdRequest request;

  /// A listener for receiving events in the ad lifecycle.
  @override
  final AdManagerBannerAdListener listener;

  /// Ad sizes supported by this [AdManagerBannerAd].
  ///
  /// In most cases, only one ad size will be specified. Multiple ad sizes can
  /// be specified if your application can appropriately handle multiple ad
  /// sizes. If multiple ad sizes are specified, the [AdManagerBannerAd] will
  /// assume the size of the first ad size until an ad is loaded.
  final List<AdSize> sizes;

  @override
  Future<void> load() async {
    await instanceManager.loadAdManagerBannerAd(this);
  }
}

/// A NativeAd.
///
/// Native ads are ad assets that are presented to users via UI components that
/// are native to the platform. (e.g. A
/// [View](https://developer.android.com/reference/android/view/View) on Android
/// or a
/// [UIView](https://developer.apple.com/documentation/uikit/uiview?language=objc)
/// on iOS). Using Flutter widgets to create native ads is NOT supported by
/// this.
///
/// Using platform specific UI components, these ads can be formatted to match
/// the visual design of the user experience in which they live. In coding
/// terms, this means that when a native ad loads, your app receives a NativeAd
/// object that contains its assets, and the app (rather than the Google Mobile
/// Ads SDK) is then responsible for displaying them.
///
/// See the README for more details on using Native Ads.
///
/// To display this ad, instantiate an [AdWidget] with this as a parameter after
/// calling [load].
class NativeAd extends AdWithView {
  /// Creates a [NativeAd].
  ///
  /// A valid [adUnitId], nonnull [listener], nonnull [request], and nonnull
  /// [factoryId] is required.
  NativeAd({
    required String adUnitId,
    required this.factoryId,
    required this.listener,
    required this.request,
    this.customOptions,
  })  : adManagerRequest = null,
        assert(request != null),
        super(adUnitId: adUnitId, listener: listener);

  /// Creates a [NativeAd] with Ad Manager.
  ///
  /// A valid [adUnitId], nonnull [listener], nonnull [adManagerRequest], and
  /// nonnull [factoryId] is required.
  NativeAd.fromAdManagerRequest({
    required String adUnitId,
    required this.factoryId,
    required this.listener,
    required this.adManagerRequest,
    this.customOptions,
  })  : request = null,
        assert(adManagerRequest != null),
        super(adUnitId: adUnitId, listener: listener);

  /// An identifier for the factory that creates the Platform view.
  final String factoryId;

  /// A listener for receiving events in the ad lifecycle.
  @override
  final NativeAdListener listener;

  /// Optional options used to create the [NativeAd].
  ///
  /// These options are passed to the platform's `NativeAdFactory`.
  Map<String, Object>? customOptions;

  /// Targeting information used to fetch an [Ad].
  final AdRequest? request;

  /// Targeting information used to fetch an [Ad] with Ad Manager.
  final AdManagerAdRequest? adManagerRequest;

  /// {@template google_mobile_ads.testAdUnitId}
  /// A platform-specific AdMob test ad unit ID.
  ///
  /// This ad unit has been specially configured to always return test ads, and
  /// developers are encouraged to use it while building and testing their apps.
  /// {@endtemplate}
  /// {@macro google_mobile_ads.testAdUnitId}
  static final String testAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/2247696110'
      : 'ca-app-pub-3940256099942544/3986624511';

  @override
  Future<void> load() async {
    await instanceManager.loadNativeAd(this);
  }
}

/// A full-screen interstitial ad for the Google Mobile Ads Plugin.
class InterstitialAd extends AdWithoutView {
  /// Creates an [InterstitialAd].
  ///
  /// A valid [adUnitId] from the AdMob dashboard, a nonnull [listener], and a
  /// nonnull [request] is required.
  InterstitialAd._({
    required String adUnitId,
    required this.request,
    required this.adLoadCallback,
  }) : super(adUnitId: adUnitId);

  /// Targeting information used to fetch an [Ad].
  final AdRequest request;

  /// Callback to be invoked when the ad finishes loading.
  final InterstitialAdLoadCallback adLoadCallback;

  /// Callbacks to be invoked when ads show and dismiss full screen content.
  FullScreenContentCallback<InterstitialAd>? fullScreenContentCallback;

  /// {@macro google_mobile_ads.testAdUnitId}
  static final String testAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';

  /// Loads an [InterstitialAd] with the given [adUnitId] and [request].
  static Future<void> load({
    required String adUnitId,
    required AdRequest request,
    required InterstitialAdLoadCallback adLoadCallback}) async {
    InterstitialAd ad = InterstitialAd._(
        adUnitId: adUnitId,
        adLoadCallback: adLoadCallback,
        request: request);

    await instanceManager.loadInterstitialAd(ad);
  }

  /// Display this on top of the application.
  ///
  /// Set [this.fullScreenContentCallback] before calling this method to be
  /// notified of events that occur when showing the ad.
  Future<void> show() {
    return instanceManager.showAdWithoutView(this);
  }
}

/// A full-screen interstitial ad for use with Ad Manager.
class AdManagerInterstitialAd extends AdWithoutView {
  /// Creates an [AdManagerInterstitialAd].
  ///
  /// A valid [adUnitId] from the Ad Manager dashboard, a nonnull [listener],
  /// and nonnull [request] is required.
  AdManagerInterstitialAd._({
    required String adUnitId,
    required this.request,
    required this.adLoadCallback,
  }) : super(adUnitId: adUnitId);

  /// Targeting information used to fetch an [Ad].
  final AdManagerAdRequest request;

  /// Callback to be invoked when the ad finishes loading.
  final AdManagerInterstitialAdLoadCallback adLoadCallback;

  /// Callbacks to be invoked when ads show and dismiss full screen content.
  FullScreenContentCallback<AdManagerInterstitialAd>? fullScreenContentCallback;

  AppEventListener? appEventListener;

  /// Loads an [AdManagerInterstitialAd] with the given [adUnitId] and [request].
  static Future<void> load({
    required String adUnitId,
    required AdManagerAdRequest request,
    required AdManagerInterstitialAdLoadCallback adLoadCallback,
    AppEventListener? appEventListener
    }) async {
    AdManagerInterstitialAd ad = AdManagerInterstitialAd._(
        adUnitId: adUnitId,
        adLoadCallback: adLoadCallback,
        request: request);

    await instanceManager.loadAdManagerInterstitialAd(ad);
  }

  /// Displays this on top of the application.
  ///
  /// Set [this.fullScreenContentCallback] before calling this method to be
  /// notified of events that occur when showing the ad.
  Future<void> show() {
    return instanceManager.showAdWithoutView(this);
  }
}

/// An [Ad] where a user has the option of interacting with in exchange for in-app rewards.
///
/// Because the video assets are so large, it's a good idea to start loading an
/// ad well in advance of when it's likely to be needed.
class RewardedAd extends AdWithoutView {
  /// Creates a [RewardedAd] with an [AdRequest].
  ///
  /// A valid [adUnitId], nonnull [listener], and nonnull request is required.
  RewardedAd._({
    required String adUnitId,
    required this.rewardedAdLoadCallback,
    required this.request,
    this.serverSideVerificationOptions,
  })  : adManagerRequest = null,
        super(adUnitId: adUnitId);

  /// Creates a [RewardedAd] with a [AdManagerAdRequest].
  ///
  /// A valid [adUnitId], nonnull [listener], and nonnull request is required.
  RewardedAd._fromAdManagerRequest({
    required String adUnitId,
    required this.rewardedAdLoadCallback,
    required this.adManagerRequest,
    this.serverSideVerificationOptions,
  })  : request = null,
        super(adUnitId: adUnitId);

  /// Targeting information used to fetch an [Ad].
  final AdRequest? request;

  /// Targeting information used to fetch an [Ad] using Ad Manager.
  final AdManagerAdRequest? adManagerRequest;

  /// Callbacks for events that occur when attempting to load an ad.
  final RewardedAdLoadCallback rewardedAdLoadCallback;

  /// {@template google_mobile_ads.testAdUnitId}
  /// A platform-specific AdMob test ad unit ID.
  ///
  /// This ad unit has been specially configured to always return test ads, and
  /// developers are encouraged to use it while building and testing their apps.
  /// {@endtemplate}
  /// {@macro google_mobile_ads.testAdUnitId}
  static final String testAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/5224354917'
      : 'ca-app-pub-3940256099942544/1712485313';

  /// Optional [ServerSideVerificationOptions].
  ServerSideVerificationOptions? serverSideVerificationOptions;

  /// Callbacks to be invoked when ads show and dismiss full screen content.
  FullScreenContentCallback<RewardedAd>? fullScreenContentCallback;

  /// Callback for when the user earns a reward.
  OnUserEarnedRewardCallback? onUserEarnedRewardCallback;

  /// Loads a [RewardedAd] using an [AdRequest].
  static Future<void> load({
    required String adUnitId,
    required AdRequest request,
    required RewardedAdLoadCallback rewardedAdLoadCallback,
    ServerSideVerificationOptions? serverSideVerificationOptions}) async {

    RewardedAd rewardedAd = RewardedAd._(
      adUnitId: adUnitId,
      request: request,
      rewardedAdLoadCallback: rewardedAdLoadCallback,
      serverSideVerificationOptions: serverSideVerificationOptions
    );

    await instanceManager.loadRewardedAd(rewardedAd);
  }

  /// Loads a [RewardedAd] using an [AdManagerAdRequest].
  static Future<void> loadWithAdManagerAdRequest({
    required String adUnitId,
    required AdManagerAdRequest adManagerRequest,
    required RewardedAdLoadCallback rewardedAdLoadCallback,
    ServerSideVerificationOptions? serverSideVerificationOptions}) async {

    RewardedAd rewardedAd = RewardedAd._fromAdManagerRequest(
        adUnitId: adUnitId,
        adManagerRequest: adManagerRequest,
        rewardedAdLoadCallback: rewardedAdLoadCallback,
        serverSideVerificationOptions: serverSideVerificationOptions
    );

    await instanceManager.loadRewardedAd(rewardedAd);
  }

  /// Display this on top of the application.
  ///
  /// Set [this.fullScreenContentCallback] before calling this method to be
  /// notified of events that occur when showing the ad.
  /// [onUserEarnedReward] will be invoked when the user earns a reward.
  Future<void> show({required OnUserEarnedRewardCallback onUserEarnedReward}) {
    onUserEarnedRewardCallback = onUserEarnedReward;
    return instanceManager.showAdWithoutView(this);
  }
}

/// Credit information about a reward received from a [RewardedAd].
class RewardItem {
  /// Default constructor for [RewardItem].
  ///
  /// This is mostly used to return [RewardItem]s for a [RewardedAd] and
  /// shouldn't be needed to be used directly.
  RewardItem(this.amount, this.type);

  /// Credit amount rewarded from a [RewardedAd].
  final num amount;

  /// Type of credit rewarded.
  final String type;
}

/// Options for RewardedAd server-side verification callbacks.
///
/// See https://developers.google.com/admob/ios/rewarded-video-ssv and
/// https://developers.google.com/admob/android/rewarded-video-ssv for more
/// information.
class ServerSideVerificationOptions {
  /// The user id to be used in server-to-server reward callbacks.
  final String? userId;

  /// The custom data to be used in server-to-server reward callbacks
  final String? customData;

  /// Create [ServerSideVerificationOptions] with the userId or customData.
  ServerSideVerificationOptions({this.userId, this.customData});

  @override
  bool operator ==(other) {
    return other is ServerSideVerificationOptions &&
        userId == other.userId &&
        customData == other.customData;
  }
}
