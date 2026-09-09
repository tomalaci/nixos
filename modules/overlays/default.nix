_: prev: {
  # Upstream stable fixes (because some deps are broken in the latest version)
  # Make sure to recheck later if these are needed anymore.
  # Pin the Linux 6.2.2 release to avoid crashes in later versions.
  megasync = prev.megasync.overrideAttrs (old: {
    version = "6.2.2.0";
    # Keep nixpkgs' SDK-only fetch; fetching all submodules fails on design assets.
    src = old.src.override {
      hash = "sha256-daRisgc/psFJd9E25egMxJVFnuS/0MG20BbZPnRscHQ=";
    };
    # This SDK version uses ICU collation but omits i18n from its non-vcpkg link.
    postPatch =
      old.postPatch
      + ''
        substituteInPlace src/MEGASync/mega/cmake/modules/sdklib_libraries.cmake \
          --replace-fail "find_package(ICU COMPONENTS uc data REQUIRED)" \
            "find_package(ICU COMPONENTS i18n uc data REQUIRED)" \
          --replace-fail "target_link_libraries(SDKlib PRIVATE ICU::uc ICU::data)" \
            "target_link_libraries(SDKlib PRIVATE ICU::i18n ICU::uc ICU::data)"
      '';
  });
}
