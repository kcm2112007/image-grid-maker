import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// A single social/community link shown on the Home screen footer.
class SocialLink {
  final String label;
  final String url;
  final IconData icon;

  const SocialLink({
    required this.label,
    required this.url,
    required this.icon,
  });
}

const List<SocialLink> kSocialLinks = [
  SocialLink(
    label: 'WhatsApp Channel',
    url: 'https://whatsapp.com/channel/0029VbDU9dmEQIameOnw2R47',
    icon: FontAwesomeIcons.whatsapp,
  ),
  SocialLink(
    label: 'Instagram',
    url: 'https://www.instagram.com/goodx_official?stkn=MjViOTB0M3o5OHN6',
    icon: FontAwesomeIcons.instagram,
  ),
  SocialLink(
    label: 'Facebook',
    url: 'https://www.facebook.com/share/1Ew1TbBSwZ/',
    icon: FontAwesomeIcons.facebook,
  ),
];
