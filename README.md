# Creating a Support Package for Codefresh On-Premises Environment

## Prerequisities

1. `kubectl config current-context` must be the context of the cluster codefresh on-premises is installed in
2. [Codefresh CLI](https://codefresh-io.github.io/cli/installation/) must be installed and configured with system admin user
3. yq, curl, helm (used to gather information)
4. git (can download a zip version instead)

## Script Usage

This script is to gather information about the Codefresh On-Premises environment.  

### Setup

To begin, you will need to clone the repo, change the directory to this repo, and add execution flag to the script.  Below is the command to do it all in one go.

```bash
git clone https://github.com/codefresh-support/cf-on-premises-support.git && \
cd cf-on-premises-support && \
chmod +x cf-onprem-support-package.sh
```

### Syntax

```bash
./cf-onprem-support-package.sh <Codefresh_Namespace>
```

The argument is the namespace codefresh is installed in. It defaults to `codefresh`

### Example

```bash
./cf-onprem-support-package.sh codefresh-control-plane
```

### Additional information

It's common to use Codefresh Runners as runtimes for Codefresh On-Premises, in case you're using such configuration you need to get additional details following the recommendations from this repository: https://github.com/codefresh-support/hybrid-runner-support
