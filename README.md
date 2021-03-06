# Mapped deployment action

A composite github action used to build and push an image to ECR.
Designed for use alongside [epimorphics/deployment-mapper](https://github.com/epimorphics/deployment-mapper).

   * Creates the ECR repository if it doesn't exist, setting access policy to organization-wide
   * Determines a tag for the image to push
   * Builds the image
   * Pushes it to ECR repository with the given tags

Assumes AWS credentials have been configured and docker has been logged into ECR.

## Inputs

| Input | Description | Required |
|---|---|---|
| `image` | Name of the image to build as generated by deployment mapper | true |
| `region` | AWS region of ECR as extracted by deployment mapper | true |
| `buildArgs` | A semicolon separated list of additional build arguments to be used during docker build | false |

## Example usage

```yaml
name: Mapped deployment
on:
  push: {}

jobs:
  mapped-deploy:
    name: mapped-deployment
    runs-on: ubuntu-18.04
    steps:
    - uses: actions/checkout@v2
    - name: "Check for mapped deployment"
      id: mapper
      uses: epimorphics/deployment-mapper@1.1
      with:
        ref: "${{github.ref}}"

    - name: Configure AWS Credentials
      uses: aws-actions/configure-aws-credentials@v1
      with:
        aws-access-key-id: ${{ secrets.BUILD_EPI_EXPT_AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.BUILD_EPI_EXPT_AWS_SECRET_ACCESS_KEY }}
        aws-region: "${{ steps.mapper.outputs.region }}"
    - name: Login to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v1

    - name: "Build and push image"
      if: steps.mapper.outputs.image != ''
      uses: epimorphics/mapped-deployment-action@1.1
      with:
        image: "${{ steps.mapper.outputs.image }}"
        region: "${{ steps.mapper.outputs.region }}"
        access_key_id: ${{ secrets.BUILD_EPI_EXPT_AWS_ACCESS_KEY_ID }}
        secret_access_key: ${{ secrets.BUILD_EPI_EXPT_AWS_SECRET_ACCESS_KEY }}
```

## Tag choice

The action tags the image with `latest` and with with unique tag based on the git tag and sha:

   * if the head of the git repo matches a git tag then that is used as the image tag
   * otherwise, finds the most recent git tag and creates an image tag based on that, plus number of commits since that tag, plus short sha of commit
   * otherwise, if there is no tag, then uses the short sha of the commit

The first two choices correspond to simply `git describe` and generate tags such as `1.0` and `v0.11-34-gebfad28`.
