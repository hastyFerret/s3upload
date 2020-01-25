#!/bin/bash

# show_usage()
show_usage() {
  cat <<END
Usage:
  $0 aws_region bucket_name object_key file_name
Required Environment Variables:
  AWS_ACCESS_KEY_ID
  AWS_SECRET_ACCESS_KEY
END
}

# hexdump()
# String to Hex
hexencode() {
  printf $1 | hexdump -v -e '16/1 "%02x"' | sed 's/ *$//'
}

# hash_hex(file)
# Creates SHA256 hash for content of file
file_hash_hex() {
  cat "$1" | openssl dgst -sha256 | sed 's/^.* //'
}

# hash_hex(msg)
# Creates SHA256 hash for msg
hash_hex() {
  printf "$1" | openssl dgst -sha256 | sed 's/^.* //'
}

# hmac(msg,key)
hmac_hex() {
  printf "$1" | openssl dgst -sha256 -mac HMAC -macopt hexkey:$2 | sed 's/^.* //'
}


# If no args, show usage
if [ "$#" -ne 4 ]; then
  show_usage
  exit 1
fi

AWS_REGION="$1"
BUCKET_NAME="$2"
OBJECT_KEY="$3"
FILE_PATH="$4"

# Useful values
AMZ_DATE=`date -u +%Y%m%dT%H%M%SZ`
YMD_DATE=`date +%Y%m%d`
S3_ENDPOINT="${BUCKET_NAME}.s3.amazonaws.com"
CANNONICAL_URI="/${OBJECT_KEY}"

# Calculate hash for file content
PAYLOAD_HASH=$(file_hash_hex ${FILE_PATH})

# Create Hashed Cannonical Request
SIGNED_HEADERS="content-type;host;x-amz-date"
CANN_REQ="\
PUT\n\
/${OBJECT_KEY}\n\
\n\
content-type:application/octet-stream\n\
host:${S3_ENDPOINT}\n\
x-amz-date:${AMZ_DATE}\n\
\n\
${SIGNED_HEADERS}\n\
${PAYLOAD_HASH}"

HASHED_CANN_REQ=$(hash_hex ${CANN_REQ})

# Create String to Sign
STR_TO_SIGN="\
AWS4-HMAC-SHA256\n\
${AMZ_DATE}\n\
${YMD_DATE}/${AWS_REGION}/s3/aws4_request\n\
${HASHED_CANN_REQ}"

# Create Derived Signing Key
KSEC=$(hexencode "AWS4${AWS_SECRET_ACCESS_KEY}")
KDATE=$(hmac_hex ${YMD_DATE} ${KSEC})
KREGION=$(hmac_hex ${AWS_REGION} ${KDATE})
KSVC=$(hmac_hex "s3" ${KREGION})
KDS=$(hmac_hex "aws4_request" ${KSVC})

# Calculate Signature
SIG=$(hmac_hex "${STR_TO_SIGN}" ${KDS})

# Create Auth Header value
AUTH_VAL="\
AWS4-HMAC-SHA256 \
Credential=${AWS_ACCESS_KEY_ID}/${YMD_DATE}/${AWS_REGION}/s3/aws4_request, \
SignedHeaders=${SIGNED_HEADERS}, \
Signature=${SIG}"

# FINALLY! Upload file
curl -X PUT -T "${FILE_PATH}" \
-H "Authorization: ${AUTH_VAL}" \
-H "Content-Type: application/octet-stream" \
-H "Host: ${S3_ENDPOINT}" \
-H "X-Amz-Date: ${AMZ_DATE}" \
-H "X-Amz-Content-SHA256: ${PAYLOAD_HASH}" \
https://${S3_ENDPOINT}/${OBJECT_KEY}
