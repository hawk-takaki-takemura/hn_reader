import google_mobile_ads
import UIKit

class ListTileNativeAdFactory: FLTNativeAdFactory {
  func createNativeAd(
    _ nativeAd: GADNativeAd,
    customOptions: [AnyHashable: Any]? = nil
  ) -> GADNativeAdView? {
    guard let nativeAdView = Bundle.main.loadNibNamed(
      "ListTileNativeAdView",
      owner: nil,
      options: nil
    )?.first as? GADNativeAdView else {
      return nil
    }

    (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline
    (nativeAdView.bodyView as? UILabel)?.text = nativeAd.body
    (nativeAdView.callToActionView as? UIButton)?
      .setTitle(nativeAd.callToAction, for: .normal)
    nativeAdView.callToActionView?.isUserInteractionEnabled = false

    if let mediaView = nativeAdView.mediaView {
      mediaView.mediaContent = nativeAd.mediaContent
    }

    nativeAdView.nativeAd = nativeAd
    return nativeAdView
  }
}
