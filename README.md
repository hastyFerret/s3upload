# s3upload
Bash script to upload a single file to Amazon S3. It signs its PUT request using the [AWS Signature Version 4](https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html) process.

## Dependencies
s3upload requires the following packages to be installed:
* openssl
* curl
* hexdump
* plus common UNIX/Linux commands, such as *sed*

It also looks for the following environment variables:
* AWS_ACCESS_KEY_ID
* AWS_SECRET_ACCESS_KEY


It has been tested in a *busybox* environment.

## Usage
`s3upload aws_region bucket_name object_key file_name`

### EXAMPLE
`s3upload us-east-1 my-bucket-name prefix/name.ext ~/name.ext`
