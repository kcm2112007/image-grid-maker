import 'package:flutter/material.dart';

/// A single social/community link shown on the Home screen footer.
class SocialLink {
  final String id;
  final String label;
  final String url;
  final IconData icon;

  const SocialLink({
    required this.id,
    required this.label,
    required this.url,
    required this.icon,
  });
}

const List<SocialLink> kSocialLinks = [
  SocialLink(
    id: 'whatsapp',
    label: 'WhatsApp Channel',
    url: 'https://whatsapp.com/channel/0029VbDU9dmEQIameOnw2R47',
    icon: Icons.chat_outlined,
  ),
  SocialLink(
    id: 'instagram',
    label: 'Instagram',
    url: 'https://www.instagram.com/goodx_official?stkn=MjViOTB0M3o5OHN6',
    icon: Icons.camera_alt_outlined,
  ),
  SocialLink(
    id: 'facebook',
    label: 'Facebook',
    url: 'https://www.facebook.com/share/1Ew1TbBSwZ/',
    icon: Icons.public,
  ),
];
