BUILDIFIER_REPO_NAMES = [
    "darwin_amd64",
    "darwin_arm64",
    "linux_amd64",
    "linux_arm64",
    "windows_amd64",
]

BUILDIFIER_REPOS = {
    "v6.4.0": {
        "darwin_amd64": struct(
            path = "buildifier-darwin-amd64",
            sha256 = "eeb47b2de27f60efe549348b183fac24eae80f1479e8b06cac0799c486df5bed",
        ),
        "darwin_arm64": struct(
            path = "buildifier-darwin-arm64",
            sha256 = "fa07ba0d20165917ca4cc7609f9b19a8a4392898148b7babdf6bb2a7dd963f05",
        ),
        "linux_amd64": struct(
            path = "buildifier-linux-amd64",
            sha256 = "be63db12899f48600bad94051123b1fd7b5251e7661b9168582ce52396132e92",
        ),
        "linux_arm64": struct(
            path = "buildifier-linux-arm64",
            sha256 = "18540fc10f86190f87485eb86963e603e41fa022f88a2d1b0cf52ff252b5e1dd",
        ),
        "windows_amd64": struct(
            path = "buildifier-windows-amd64.exe",
            sha256 = "da8372f35e34b65fb6d997844d041013bb841e55f58b54d596d35e49680fe13c",
        ),
    },
}
