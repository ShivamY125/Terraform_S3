
resource "random_id" "bucket_id" {
    byte_length = 8
}

resource "aws_s3_bucket" "test_bucket" {
  bucket = format("%s-%s", var.bucket_name, random_id.bucket_id.hex)
  tags = {
    Name = "My Bucket"
    Enviornment = "Dev"
  }
}

# Step 2: Upload Images to S3 Bucket.

resource "aws_s3_object" "test_upload_bucket" {
  for_each = fileset("./images", "**")  # this will create a map of all the files present in images folder and run a loop on each file.
  bucket = aws_s3_bucket.test_bucket.id
  key = each.key   # Name of the Object in the S3 Bucket.
#   Each is coming from For Each Loop which we are running on line one in this resource.
  source = "${"./images"}/${each.value}"
  etag = filemd5("${"./images"}/${each.value}") # Etag detects the file change as Hash will also change with that, Terraform uploads the file again.
  server_side_encryption = "AES256"  #AES256 means: AWS-managed encryption

  tags = {
    Name = "My Bucket"
    Enviornment = "Dev"
  }
}

