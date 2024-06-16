# Fritzing Build Scripts

These scripts can be used to quickly build Fritzing on a fresh Windows
installation.

## Getting Started

Open `install-fritzing-build-deps.ps1`, set appropriate values for
`$qtOnlineInstallerEmail` and `$qtOnlineInstallerPw`. Save your changes.

Then, open PowerShell as Administrator, then run:

```
.\install-fritzing-build-deps.ps1
```

Then, open PowerShell as a regular user, then run:

```
.\build-fritzing.ps1
```
