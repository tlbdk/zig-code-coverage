# zig-code-coverage
Example repo that show how to generate code coverage in Zip


# Ubuntu setup

kcov was only added in Ubuntu 25.04 so if you are running Ubuntu 24.04, then you need to add that as a source:

/etc/apt/sources.list.d/plucky.sources (For x86_64):
``` text
Types: deb
URIs: http://archive.ubuntu.com/ubuntu/
Suites: plucky plucky-updates plucky-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
 
Types: deb
URIs: http://security.ubuntu.com/ubuntu/
Suites: plucky-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
```

/etc/apt/sources.list.d/plucky.sources (For arm64):
```
Types: deb
URIs: http://ports.ubuntu.com/ubuntu-ports/
Suites: plucky plucky-updates plucky-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
 
Types: deb
URIs: http://ports.ubuntu.com/ubuntu-ports/
Suites: plucky-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
```

Set low priority for all packages in plucky expect for kcov:

``` text
/etc/apt/preferences.d/plucky-pin:
Package: *
Pin: release n=plucky
Pin-Priority: -10
 
Package: kcov
Pin: release n=plucky
Pin-Priority: 500
```

Install kcov and tooling needed for installing zig:

``` bash
apt-get install -qq --no-install-recommends -y curl xz-utils ca-certificates kcov minisign git
```


# Installing zig and testing 

Install zig:
``` bash
# For x86-64
curl -sSL --fail -o zig.tar.xz "https://ziglang.org/download/0.15.1/zig-x86_64-linux-0.15.1.tar.xz"
# For arm64
curl -sSL --fail -o zig.tar.xz "https://ziglang.org/download/0.15.1/zig-aarch64-linux-0.15.1.tar.xz"
# Extract and add zig to path
mkdir -p /usr/local/zig
tar -xf zig.tar.xz -C /usr/local/zig --strip-components=1
export PATH=/usr/local/zig:$PATH
```

Clone repo:
``` bash
git clone https://github.com/tlbdk/zig-code-coverage.git
cd zig-code-coverage
```

Build coverage and print coverage file:
``` bash
zig build coverage
cat zig-out/coverage/cov.xml |grep line-rate
```

Expected output:

``` text
$ zig build coverage
coverage
└─ install generated/
   └─ run /usr/bin/kcov (.) stderr
1/3 main.test.use other module...OK
2/3 main.test.fuzz example...OK
3/3 main.test_0...OK
All 3 tests passed.
1 fuzz tests found.
$ cat zig-out/coverage/cov.xml |grep line-rate
<coverage line-rate="0.714" lines-covered="10" lines-valid="14" branch-rate="1.0" branches-covered="1.0" branches-rate="1.0" complexity="1.0" version="1.9" timestamp="1759229184">
                <package name="test" line-rate="0.714" lines-covered="10" lines-valid="14" branch-rate="1.0" complexity="1.0">
                                <class name="root_zig__0" filename="root.zig" branch-rate="1.0" complexity="1.0" line-rate="0.500">
                                <class name="main_zig__1" filename="main.zig" branch-rate="1.0" complexity="1.0" line-rate="0.800">
```

# Testing with docker

Create builder that allows kcov to run:

``` bash
docker buildx create --name insecure-builder --buildkitd-flags "--allow-insecure-entitlement security.insecure"
```

Build container:

``` bash
docker buildx build  --progress plain  --builder insecure-builder --allow security.insecure .
```


# VSCode setup

settings.json:
``` jsonc
{
    // MacOS
    "lldb-dap.executable-path": "/Library/Developer/CommandLineTools/usr/bin/lldb-dap",
    // Ubuntu 24.04
    "lldb-dap.executable-path": "/usr/bin/lldb-dap-18",
    // Windows 
    "lldb-dap.executable-path": "C:/Program Files/LLVM/bin/lldb-dap.exe",
    "zig.debugAdapter": "lldb-dap",
    "[zig]": {
        "editor.formatOnSave": true,
    },
    "zig.testArgs": [
        "build",
        "test",
        "-Dtest-filter=${filter}"
    ],
     "zig.debugTestArgs": [
        "build",
        "debug-test-unit",
       "-Dtest-filter=${filter}",
    ],
    "zig.buildOnSaveProvider": "zls"
}
```