enum Role {
  civilian,
  imposter;

  bool get isImposter => this == Role.imposter;
}
