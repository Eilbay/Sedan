/// - [none]: current version is up to date.
/// - [soft]: a newer version exists but the current one still works —
///   dismissible prompt.
/// - [hard]: current version is below the server's minimum supported
///   version — blocking prompt, app must be updated to continue.
enum UpdateType { none, soft, hard }
