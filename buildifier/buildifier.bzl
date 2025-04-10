BUILDIFIER_REPO_NAMES = [
    "darwin_amd64",
    "darwin_arm64",
    "linux_amd64",
    "linux_arm64",
    "windows_amd64",
]

BUILDIFIER_REPOS = {
    "v8.0.3": {
        "darwin_amd64": struct(
            path = "buildifier-darwin-amd64",
            sha256 = "b7a3152cde0b3971b1107f2274afe778c5c154dcdf6c9c669a231e3c004f047e",
        ),
        "darwin_arm64": struct(
            path = "buildifier-darwin-arm64",
            sha256 = "674c663f7b5cd03c002f8ca834a8c1c008ccb527a0a2a132d08a7a355883b22d",
        ),
        "linux_amd64": struct(
            path = "buildifier-linux-amd64",
            sha256 = "c969487c1af85e708576c8dfdd0bb4681eae58aad79e68ae48882c70871841b7",
        ),
        "linux_arm64": struct(
            path = "buildifier-linux-arm64",
            sha256 = "bdd9b92e2c65d46affeecaefb54e68d34c272d1f4a8c5b54929a3e92ab78820a",
        ),
        "windows_amd64": struct(
            path = "buildifier-windows-amd64.exe",
            sha256 = "0019dfc4b32d63c1392aa264aed2253c1e0c2fb09216f8e2cc269bbfb8bb49b5",
        ),
    },
}
