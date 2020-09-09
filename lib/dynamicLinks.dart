import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

class DynamicLinkService {
  static Future<String> createAppLink(String title) async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://rendezvous.page.link',
      link: Uri.parse('https://rendezvous.page.link'),
      androidParameters: AndroidParameters(
          packageName: 'com.Rendezous.Rendezvous', minimumVersion: 9),
      iosParameters: IosParameters(
        bundleId: 'com.Rendezvous.Rendezvous',
        minimumVersion: '10', // ios version needs to be updated
        appStoreId: '1435066055', // fake store id need real when when created.
      ),
      dynamicLinkParametersOptions: DynamicLinkParametersOptions(
        shortDynamicLinkPathLength: ShortDynamicLinkPathLength.unguessable,
      ),
      socialMetaTagParameters: SocialMetaTagParameters(
        title: 'Connect to a rendezvous group',
        description:
            'Rendezvous allows users to connect with each other and find convenient place to meet up in between one another',
      ),
    );

    final Uri dynamicUrl = await parameters.buildUrl();

    return dynamicUrl.toString();
  }

  Future handleDynamicLinks() async {
    // startup from dynamic link logic
    // get initial dynamic link if app is started using link
    final PendingDynamicLinkData data =
        await FirebaseDynamicLinks.instance.getInitialLink();

    _handleDeepLink(data);

    // Into foreground from dynamic link logic
    FirebaseDynamicLinks.instance.onLink(
        onSuccess: (PendingDynamicLinkData dynamicLinkData) async {
      _handleDeepLink(dynamicLinkData);
    }, onError: (OnLinkErrorException e) async {
      print('Dynamic link failed: ${e.message}');
    });
  }

  void _handleDeepLink(PendingDynamicLinkData data) {
    final Uri deepLink = data?.link;
    if (deepLink != null) {
      print('_handleDeepLink | deep: $deepLink');
    }
  }
}
