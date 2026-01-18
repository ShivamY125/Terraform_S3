variable "bucket_name" {
   type = string
   description = "Test Bucket"
   default = "test-bucket-s3-"
}

variable "upload_bucket_name" {
   type = string
   description = "Upload Bucket"
   default = "upload-bucket-s3"
}