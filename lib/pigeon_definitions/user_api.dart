import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/pigeon_definitions/user_api.g.dart',
))

class UserDetails {
  UserDetails({
    this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
  });

  String? uid;
  String? email;
  String? displayName;
  String? photoUrl;
}

@HostApi()
abstract class UserHostApi {
  UserDetails getProfile();
  void setCurrentUser(UserDetails user);
  void clearCurrentUser();
}