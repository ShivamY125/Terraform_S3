
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

# Step 3: Encyption and Enable KMS Key SSE-KMS.

resource "aws_kms_key" "S3_bucket_kms_key" {
  description = "KMS key for S3 Bucket"
  deletion_window_in_days = 7
  tags = {
    name = "KMS key for S3 Bucket"
  }
  
}

resource "aws_kms_alias" "S3_bucket_kms_key_alias" {
  name = "alias/s3_bucket_kms_key_alias"
  target_key_id = aws_kms_key.S3_bucket_kms_key.id
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_bucket_encyption_with_kms_key" {
  bucket = aws_s3_bucket.test_bucket.id # picking this bucket id from step 1.

  rule{
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.S3_bucket_kms_key.arn
      sse_algorithm = "aws:kms"
    }
  }
  
}

# Step 4: Working with IAM Policy for S3 Bucket.
# Allow get object permission to everyone.action.

resource "aws_s3_bucket_public_access_block" "enable_public_access" {
  bucket = aws_s3_bucket.test_bucket.id

  block_public_acls = false
  block_public_policy = false
  ignore_public_acls = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "test_bucket_read_policy" {
  bucket = aws_s3_bucket.test_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.test_bucket.arn}/*"
      }
    ]
  })

  depends_on = [ aws_s3_bucket_public_access_block.enable_public_access ]
}

# Step 5 Versioning.

resource "aws_s3_bucket_versioning" "test_bucket_versioning" {
  bucket = aws_s3_bucket.test_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
  
}

# Lifecycle Rules .
# After 30 days of noncurrent, the object versions are transitioned to Standard_IA for cheaper storage.
# After 60 days move it ot Glacier for long term, arcival stoarge.
# After 90 days non-current object should be deleted.

resource "aws_s3_bucket_lifecycle_configuration" "example" {
  bucket = aws_s3_bucket.test_bucket.id
   
   rule {
     id = "config"

     filter {
       prefix = "config/"
     }

     noncurrent_version_expiration {
       noncurrent_days = 90
     }

     noncurrent_version_transition {
       noncurrent_days = 30
       storage_class = "STANDARD_IA"
     }

     noncurrent_version_transition {
       noncurrent_days = 60
       storage_class = "GLACIER"
     }

     status = "Enabled"


   }
    
    depends_on = [ aws_s3_bucket_versioning.test_bucket_versioning ]

}
